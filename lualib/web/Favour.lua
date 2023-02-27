local cfg = require "web.config"
local mysqlUtil = require "web.mysql-pool"

local args=ngx.req.get_uri_args(3)

if args["action"]=="1" then
    local value = "(\'"..args["email"].."\',"..tostring(args["id"])..");"
    local sql = "insert into Favour values "..value
    local ret, res = mysqlUtil:query(sql,cfg.mysql)
    if not ret then 
        ngx.log(ngx.ERR, "mysql:insert error: ",res)
        ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
        ngx.say("Favour insert failed!")
        return ngx.exit(ngx.HTTP_OK)
    end

    local sql = "update Player set favour_num = favour_num+1 where id="..tostring(args["id"])..";"
    local ret, res = mysqlUtil:query(sql,cfg.mysql)
    if not ret then 
        ngx.log(ngx.ERR, "mysql:update error: ",res)
        ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
        ngx.say("Favour failed!")
        return ngx.exit(ngx.HTTP_OK)
    end
else 
    local value = "id="..tostring(args["id"]).." and email=\'"..args["email"].."\';"
    local sql = "delete from Favour where "..value;
    local ret, res = mysqlUtil:query(sql,cfg.mysql)
    if not ret then 
        ngx.log(ngx.ERR, "mysql:delete error: ",res)
        ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
        ngx.say("Unfavour delete failed!")
        return ngx.exit(ngx.HTTP_OK)
    end

    local sql = "update Player set favour_num = favour_num-1 where id="..tostring(args["id"])..";"
    local ret, res = mysqlUtil:query(sql,cfg.mysql)
    if not ret then 
        ngx.log(ngx.ERR, "mysql:update error: ",res)
        ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
        ngx.say("Unfavour failed!")
        return ngx.exit(ngx.HTTP_OK)
    end
end
    
