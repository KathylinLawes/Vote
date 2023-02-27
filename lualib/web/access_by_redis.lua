# Lua
local function close_redis(red)
    if not red then
        return
    end
    -- 释放连接(连接池实现)，毫秒
    local pool_max_idle_time = 10000 
    -- 连接池大小
    local pool_size = 100 
    local ok, err = red:set_keepalive(pool_max_idle_time, pool_size)
    local log = ngx_log
    if not ok then
        log(ngx_ERR, "set redis keepalive error : ", err)
    end
end

-- 连接redis
local redis = require('resty.redis')
local red = redis.new()
red:set_timeout(1000)

local ip = "172.17.0.1"
local port = "6379" 
local ok, err = red:connect(ip,port)
if not ok then
    return close_redis(red)
end
red:auth('123456')
red:select('0')

local clientIP = ngx.req.get_headers()["X-Real-IP"]
if clientIP == nil then
   clientIP = ngx.req.get_headers()["x_forwarded_for"]
end
if clientIP == nil then
   clientIP = ngx.var.remote_addr
end

local incrKey = "user:"..clientIP..":freq"
local blockKey = "user:"..clientIP..":block"

local is_block,err = red:get(blockKey) -- check if ip is blocked
if tonumber(is_block) == 1 then
    ngx.exit(403)
    close_redis(red)
end

inc  = red:incr(incrKey)

if inc < 5 then
   inc = red:expire(incrKey,1)
end
-- 每秒5次以上访问即视为非法，会阻止1分钟的访问
if inc > 5 then
    --设置block 为 True 为1
    red:set(blockKey,1) 
    red:expire(blockKey,60)
end

close_redis(red)