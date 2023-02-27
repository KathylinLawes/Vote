local mail = require "resty.mail"
local mysqlUtil = require "web.mysql-pool"
local cfg = require "web.config"

local mailer, err = mail.new({
    host = "smtp.qq.com",
    port = 587,
    starttls = true,
    username = "416048886@qq.com",
    password = "eruxnqpbndsabghd",
})

if err then
    ngx.log(ngx.ERR, "mail.new error: ", err)
    ngx.say("Failed to send the verification code. Please try again later!")
    return ngx.exit(ngx.HTTP_INTERNAL_SERVER_ERROR)
end

local code = "";
math.randomseed(os.time())
for i = 1, 6 do
    code = code..tostring(math.floor(math.random(0,9)))
end

ngx.req.read_body()
local args = ngx.req.get_post_args()
local user_email = args.body

local value = "(".."\'"..user_email.."\'"..",\'"..code.."\')"
local sql = "insert into VerifyCode values"..value.." on duplicate key update code = ".."\'"..code.."\'"..";"
local ret, res = mysqlUtil:query(sql, cfg.mysql)
ngx.say(sql)
if not ret then 
    ngx.log(ngx.ERR, "mysql:insert error: ",res)
    ngx.say("Failed to send the verification code. Please check your email!")
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    return ngx.exit(ngx.HTTP_OK)
end

local ok, err = mailer:send({
    from = "<416048886@qq.com>",
    to = {user_email},
    subject = "Verify code",
    text = code,
})

if err then
    ngx.log(ngx.ERR, "mailer:send error: ", err)
    ngx.say("Failed to send the verification code. Please check your email!")
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    return ngx.exit(ngx.HTTP_OK)
end