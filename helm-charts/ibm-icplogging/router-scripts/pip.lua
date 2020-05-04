local PIP = {}
PIP.__index = PIP

function PIP.new(old_obj)
    local new_obj = old_obj or {}
    setmetatable(new_obj, PIP)
    return new_obj
end

local cjson = require "cjson"
local http = require "lib.resty.http"

function PIP:query_user_id(token)
    local httpc = http.new()
    local res, err = httpc:request_uri(
        "https://platform-identity-provider.ibm-common-services.svc."..self.cluster_domain..":4300/v1/auth/userInfo", --NoPrivateIAMEndpoints, see https://travis.ibm.com/IBMPrivateCloud/ibm-cs-logging-bundle/builds/30644319#L660
        {
            method = "POST",
            ssl_verify = false,
            body = "access_token=" .. token,
            headers = {
                ["Content-Type"] = "application/x-www-form-urlencoded",
           }
        }
    )

    if not res then
        ngx.log(ngx.ERR, "Failed to request userinfo=",err)
        return exit_401()
    end
    ngx.log(ngx.DEBUG, "Response status =",res.status)

    if (res.body == "" or res.body == nil) then
        ngx.log(ngx.ERR, "Empty response body=",err)
        return exit_401()
    end

    local x = tostring(res.body)
    local uid= cjson.decode(x).sub
    ngx.log(ngx.INFO, "user id=", uid)

    return uid
end

return PIP
