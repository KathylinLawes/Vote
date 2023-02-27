local mysql = require "resty.mysql"
local mysql_pool = {}

function mysql_pool:get_connect(cfg)
    if ngx.ctx[mysql_pool] then
        return true, ngx.ctx[mysql_pool]
    end
    local client, errmsg = mysql:new()
    if not client then
        return false, "mysql.socket_failed: "..(errmsg or "nil")
    end

    client:set_timeout(10000)

    local options = {
        host = cfg.HOST,
        port = cfg.PORT,
        user = cfg.USER,
        password = cfg.PASSWORD,
        database = cfg.DATABASE
    }

    local res,errmsg = client:connect(options)

    if not res then
        return false, "mysql can't connect"..(errmsg or "nil")
    end

    ngx.ctx[mysql_pool]=client
    return true,ngx.ctx[mysql_pool]
end

function mysql_pool:close()
    if ngx.ctx[mysql_pool] then
        ngx.ctx[mysql_pool]:set_keepalive(60000,80)
        ngx.ctx[mysql_pool] = nil
    end
end

function mysql_pool:query(sql, flag)
    local ret, client = self:get_connect(flag)
    if not ret then
        return ret, client
    end

    local res, errmsg = client:query(sql)
    while errmsg == "again" do
        res, errmsg = client:read_result()
    end

    self:close()

    if not res then
        errmsg = "mysql query failed:"..(errmsg or "nil")
        return false, errmsg
    end

    return true, res
end

return mysql_pool