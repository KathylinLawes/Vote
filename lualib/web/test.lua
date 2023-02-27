ngx.req.read_body()

local args = ngx.req.get_post_args()
ngx.say(args.body)
-- ngx.say(args.email_1)

