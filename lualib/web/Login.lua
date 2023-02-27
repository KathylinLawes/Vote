local cfg = require "web.config"
local mysqlUtil = require "web.mysql-pool"

function __split(str, reps)
	local r = {}
	if str == nil then return nil end
	string.gsub(str, "[^"..reps.."]+", function(w) table.insert(r, w) end)
	return r
end

ngx.req.read_body()
local args = ngx.req.get_post_args() 

args = __split(args.body,"&")
local email_1 = __split(args[1],"=")
local email_2 = __split(args[2],"=")
local user_email = "\'"..email_1[2].."@"..email_2[2].."\'"
local sql = "select Password from Users where Email = "..user_email..";"

local ret, res = mysqlUtil:query(sql,cfg.mysql)

if not ret then 
	ngx.log(ngx.ERR, "mysql:select error: ",res)
	ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    ngx.say("Please check the infomation!")
    return ngx.exit(ngx.HTTP_OK)
end

if not next(res) then
    ngx.say("User not exist!")
	ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    return ngx.exit(ngx.HTTP_OK)
end 

local pwd = __split(args[3],"=")

if pwd[2] ~= res[1]["Password"] then
	ngx.say("The password is wrong!")
	ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    return ngx.exit(ngx.HTTP_OK)
end