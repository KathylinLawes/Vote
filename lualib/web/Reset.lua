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
local sql = "select * from Users where Email = "..user_email..";"

local ret, res = mysqlUtil:query(sql,cfg.mysql)

if not ret then 
	ngx.log(ngx.ERR, "mysql:insert error: ",res)
    ngx.say("The email is wrong.")
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    return ngx.exit(ngx.HTTP_OK)
end

if not next(res) then
    ngx.say("User not exist!")
	ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    return ngx.exit(ngx.HTTP_OK)
end 

local sql = "select code from VerifyCode where Email = "..user_email..";"
local ret, res = mysqlUtil:query(sql,cfg.mysql)
if not ret then 
	ngx.log(ngx.ERR, "mysql:insert error: ",res)
	ngx.say("Email is wrong.")
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    return ngx.exit(ngx.HTTP_OK)
end

if next(res) == nil then
	ngx.say("Please send the verify code!")
	ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    return ngx.exit(ngx.HTTP_OK)
end

local code = __split(args[3],"=")

if code[2] ~= res[1]["code"] then
	ngx.say("The verify code is wrong!")
	ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    return ngx.exit(ngx.HTTP_OK)
end

local pwd = __split(args[4],"=")
local sql = "update Users set Password = \'"..pwd[2].."\'".." where email = "..user_email..";"
local ret, res = mysqlUtil:query(sql,cfg.mysql)

if not ret then 
	ngx.log(ngx.ERR, "mysql:insert error: ",res)
	ngx.say("Please check the infomation.")
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    return ngx.exit(ngx.HTTP_OK)
end