local cfg = require "web.config"
local mysqlUtil = require "web.mysql-pool"
local json = require "cjson"
local ans = {}

ngx.header['Content-Type'] = 'application/json; charset=utf-8'
local args=ngx.req.get_uri_args(1)

local sql = "select Name from Users where Email = \'"..args["email"].."\';"
local ret, res = mysqlUtil:query(sql,cfg.mysql)

if not ret then 
	ngx.log(ngx.ERR, "mysql:select error: ",res)
	ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    ngx.say("Search name failed!")
    return ngx.exit(ngx.HTTP_OK)
end

ans["name"] = res[1]["Name"]

local sql = "select Player.id as id,Player.name as name,Player.pic as url, \
    Player.location as loaction,Player.owner as owner,Player.favour_num as favour_num\
    from Favour left outer join Player on Favour.id=Player.id \
    where Favour.email = \'"..tostring(args["email"]).."\';"
local ret, res = mysqlUtil:query(sql,cfg.mysql)

if not ret then 
	ngx.log(ngx.ERR, "mysql:select error: ",res)
	ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    ngx.say("Search favorite failed!")
    return ngx.exit(ngx.HTTP_OK)
end
ans["player"] = res

ngx.say(json.encode(ans))
