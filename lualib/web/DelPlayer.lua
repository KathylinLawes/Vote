local cfg = require "web.config"
local mysqlUtil = require "web.mysql-pool"

local args=ngx.req.get_uri_args(1)

local sql = "delete from Player where id ="..tostring(args["id"])..";"
local ret, res = mysqlUtil:query(sql,cfg.mysql)

if not ret then 
	ngx.log(ngx.ERR, "mysql:delete error: ",res)
	ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    ngx.say("Delete failed!")
    return ngx.exit(ngx.HTTP_OK)
end
