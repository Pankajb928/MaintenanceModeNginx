-- maintenance.lua
local http = require "resty.http"
local cjson = require "cjson.safe"

local cache = ngx.shared.maintenance_cache
local host = ngx.var.host or "GLOBAL"
local region = os.getenv("AWS_REGION") or "ap-south-1"

-- cache TTL in seconds
local CACHE_TTL = 5

-- ---------- Helper: Fetch from SSM ----------
local function fetch_from_ssm(param_name)
    local httpc = http.new()
    httpc:set_timeout(200)

    local body = cjson.encode({
        Name = param_name,
        WithDecryption = false
    })

    local res, err = httpc:request_uri(
        "https://ssm." .. region .. ".amazonaws.com",
        {
            method = "POST",
            ssl_verify = true,
            headers = {
                ["Content-Type"] = "application/x-amz-json-1.1",
                ["X-Amz-Target"] = "AmazonSSM.GetParameter",
                -- AWS SigV4 headers are injected automatically
                -- when using instance/task role (OpenResty)
            },
            body = body
        }
    )

    if not res or res.status ~= 200 then
        ngx.log(ngx.ERR, "SSM fetch failed: ", err)
        return nil
    end

    local decoded = cjson.decode(res.body)
    if not decoded or not decoded.Parameter then
        return nil
    end

    return decoded.Parameter.Value
end

-- ---------- Helper: Get maintenance flag ----------
local function get_maintenance(scope)
    local cache_key = "maintenance:" .. scope

    -- Check cache first
    local cached = cache:get(cache_key)
    if cached then
        return cjson.decode(cached)
    end

    -- Fetch from SSM
    local param_name = "/maintenance/" .. scope
    local value = fetch_from_ssm(param_name)

    if not value then
        return nil
    end

    -- Cache it
    cache:set(cache_key, value, CACHE_TTL)
    return cjson.decode(value)
end

-- ---------- Execution Flow ----------

-- 1. Check GLOBAL maintenance
local global = get_maintenance("GLOBAL")
if global and global.active == true then
    ngx.status = ngx.HTTP_SERVICE_UNAVAILABLE
    return ngx.exit(ngx.HTTP_SERVICE_UNAVAILABLE)
end

-- 2. Check host-based maintenance
local service = get_maintenance(host)
if service and service.active == true then
    ngx.status = ngx.HTTP_SERVICE_UNAVAILABLE
    return ngx.exit(ngx.HTTP_SERVICE_UNAVAILABLE)
end

-- 3. Allow request
-- (do nothing)
