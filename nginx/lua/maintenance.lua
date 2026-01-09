local redis = require "resty.redis"
local cjson = require "cjson.safe"

-- 0. Determine Scope
local scope = ngx.var.maintenance_scope or "GLOBAL"
local cache_key = "maintenance:" .. scope

-- Helper function to serve maintenance page
local function serve_maintenance_page(scope, message)
    ngx.status = ngx.HTTP_SERVICE_UNAVAILABLE
    ngx.header.content_type = "text/html"
    
    -- Determine filename based on scope
    local filename = "admin.html" -- Default
    if scope == "LEARNER" then
        filename = "learner.html"
    elseif scope == "ADMIN_PORTAL" then
        filename = "admin.html"
    end

    -- Try to read the file
    local file_path = "/var/www/maintenance/" .. filename
    local f = io.open(file_path, "r")
    
    if f then
        local content = f:read("*all")
        f:close()
        
        -- DYNAMIC INJECTION
        -- Usage: {{MESSAGE}} will be replaced by the Redis 'message' value
        local dynamic_msg = message or "Maintenance in progress."
        content = string.gsub(content, "{{MESSAGE}}", dynamic_msg)
        
        ngx.say(content)
    else
        -- Fallback if file not found
        ngx.say("<h1>System Maintenance</h1><p>" .. (message or "We are upgrading the system.") .. "</p>")
        ngx.log(ngx.ERR, "Failed to open maintenance file: " .. file_path)
    end
    
    -- Exit correctly (0 = OK/Stop processing, allowing response to be sent)
    return ngx.exit(0)
end

-- 1. Check Local Cache First (Fast path)
local cache = ngx.shared.maintenance_cache
local cached = cache:get(scope)

if cached then
    local rule = cjson.decode(cached)
    if rule and rule.active then
        return serve_maintenance_page(scope, rule.message)
    end
    return
end

-- 2. Connect to Redis (Slow path)
local red = redis:new()
red:set_timeout(50) 
local ok, err = red:connect("redis", 6379)

if not ok then
    ngx.log(ngx.ERR, "failed to connect to redis: ", err)
    return
end

-- 3. Get the key
local res, err = red:get(cache_key)

if not res or res == ngx.null then
    cache:set(scope, '{"active":false}', 5)
    return
end

-- 4. Cache and Evaluate
cache:set(scope, res, 5)

local rule = cjson.decode(res)
if rule and rule.active then
    return serve_maintenance_page(scope, rule.message)
end

red:set_keepalive(10000, 10)
