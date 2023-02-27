local upload = require "resty.upload"
local cjson = require "cjson"
local cfg = require "web.config"
local mysqlUtil = require "web.mysql-pool"

function __split(str, reps)
	local r = {}
	if str == nil then return nil end
	string.gsub(str, "[^"..reps.."]+", function(w) table.insert(r, w) end)
	return r
end

function __trim(s)
    return (s:gsub("^%s*(.-)%s*$", "%1"))
end

function parseMultipart(form)
    local choose = 1
    local file
    local args = {}
    local param
    while true do
        local typ, res, err = form:read()
        if typ == "header" then
            if res[1] == "Content-Disposition" then
                local kvlist = __split(res[2],';')
                kvlist[2] = __trim(kvlist[2])
                param = __split(kvlist[2],'"')[2]
                if param ~= "photo" then
                    choose = 2
                else
                    kvlist[3] = __trim(kvlist[3])
                    local mime = __split(kvlist[3],".")[2]
                    local tmp = os.date("%Y%m%d%H%M%S")
                    local filename = "/usr/local/openresty/nginx/html/img/"..tmp.."."..string.sub(mime,1,string.len(mime)-1)
                    args["url"]="./img/"..tmp.."."..string.sub(mime,1,string.len(mime)-1)
                    file = io.open(filename,"w+")
                end
            end
        elseif typ == "eof" then
            break
        elseif typ == "partend" then
            if file then
                file:close()
                file = nil
            end
        elseif typ == "body" then
            if choose == 1 then
                file:write(res)
            else
                args[param]=res
            end
        end
    end
    return args
end

local chunk_size = 4096 -- should be set to 4096 or 8192
                        -- for real-world settings
local form, err = upload:new(chunk_size)
ngx.say(ngx.var.http_content_type)
if not form then
    ngx.log(ngx.ERR, "failed to new upload: ", err)
    ngx.exit(500)
end

form:set_timeout(1000) -- 1 sec

local args = parseMultipart(form)
ngx.say(args["name"])

local sql = "select * from Player where name = \'"..args["name"].."\';"

local ret, res = mysqlUtil:query(sql,cfg.mysql)

if not ret then 
	ngx.log(ngx.ERR, "mysql:insert error: ",res)
	ngx.say("Please check the name!")
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    return ngx.exit(ngx.HTTP_OK)
end

if next(res) then
    ngx.say("The Player already exists!")
	ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    return ngx.exit(ngx.HTTP_OK)
end 

local values = "(\'"..args["name"].."\',\'"..args["url"].."\',\'"..args["location"].."\',\'"..args["user"].."\')"
local sql = "insert into Player(name,pic,location,owner) values"..values..";"
ngx.say(sql)
local ret, res = mysqlUtil:query(sql,cfg.mysql)

if not ret then 
    ngx.say("Add player failed!Please check the infomation.")
	ngx.log(ngx.ERR, "mysql:insert error: ",res)
    ngx.status = ngx.HTTP_INTERNAL_SERVER_ERROR
    return ngx.exit(ngx.HTTP_OK)
end