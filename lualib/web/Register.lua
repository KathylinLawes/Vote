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
local email_1 = __split(args[3],"=")
local email_2 = __split(args[4],"=")
local user_email = "\'"..email_1[2].."@"..email_2[2].."\'"
local sql = "select * from Users where Email = "..user_email..";"

local ret, res = mysqlUtil:query(sql,cfg.mysql)

if not ret then 
	ngx.log(ngx.ERR, "mysql:insert error: ",res)
	ngx.say("Email is wrong.")
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    return ngx.exit(ngx.HTTP_OK)
end

if next(res) then
    ngx.say("User already exists!")
	ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    return ngx.exit(ngx.HTTP_OK)
end 

local sql = "select code from VerifyCode where email = "..user_email..";"
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

local code = __split(args[5],"=")

if code[2] ~= res[1]["code"] then
	ngx.say("The verify code is wrong!")
	ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    return ngx.exit(ngx.HTTP_OK)
end

local name = __split(args[1],"=")
local pwd = __split(args[2],"=")
local value = "("..user_email..",".."\'"..name[2].."\'"..",".."\'"..pwd[2].."\'"..")"
local sql = "insert into Users values"..value..";"

local ret, res = mysqlUtil:query(sql,cfg.mysql)

if not ret then 
    ngx.say("Register failed!Please check the infomation.")
	ngx.log(ngx.ERR, "mysql:insert error: ",res)
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    return ngx.exit(ngx.HTTP_OK)
end
