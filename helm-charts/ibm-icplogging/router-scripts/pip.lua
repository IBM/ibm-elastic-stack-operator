-- 
-- Copyright 2020 IBM Corporation
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
-- http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

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
        "https://platform-identity-provider.{{ .Release.Namespace }}.svc."..self.cluster_domain..":4300/v1/auth/userInfo", 
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
