local cfg = require "web.config"
local mysqlUtil = require "web.mysql-pool"
local json = require "cjson"

local args=ngx.req.get_uri_args(1)
ngx.header['Content-Type'] = 'application/json; charset=utf-8'

local sql = "select Player.id as id,Player.name as name,Player.pic as url,Player.owner as owner,\
    Player.location as location, Player.favour_num as favour_num, Favour.id as iffavour from Player \
    left outer join Favour on Favour.id=Player.id and Favour.email =\'"..tostring(args["email"]).."\';"
local ret, res = mysqlUtil:query(sql,cfg.mysql)

if not ret then 
	ngx.log(ngx.ERR, "mysql:select error: ",res)
	ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    ngx.say("Please check the infomation!")
    return ngx.exit(ngx.HTTP_OK)
end

ngx.say(json.encode(res))