-- 
-- Copyright 2020 IBM Corporation

-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at

-- http:#www.apache.org/licenses/LICENSE-2.0

-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

-- top level function that validates if the requesting user have access
-- to this kibana instance
local Util = require "rbac.util"
local PIP = require "rbac.pip"
local PIM = require "rbac.pim"
local PDP = require "rbac.pdp"
local Set = require "rbac.set"
local CookieJar = require "resty.cookie"

local Constants = {
    CLUSTER_ADMIN='"ClusterAdministrator"',
    UNAUTHORIZED_MSG = "request not authorized"
}

local function extract_auth_token()
    local token = nil

    local auth_header = ngx.var.http_Authorization

    if auth_header ~= nil then
        ngx.log(ngx.DEBUG, "Authorization header found, extracting token.")
        _, _, token = string.find(auth_header, "Bearer%s+(.+)")
    else
        ngx.log(ngx.DEBUG, "Authorization header not found, checking cookie")

        local cookie, err = CookieJar:new()
        token = cookie:get("cfc-access-token-cookie")

        if token == nil then
            ngx.log(ngx.ERR, "cfc-access-token-cookie not found.")
        end
    end

    return token
end

local function extract_router_api_key()
    local h, err = ngx.req.get_headers()

    if err ~= nil then
        ngx.log(ngx.ERR, err)
        return nil
    end

    local k = h["router-api-key"]
    ngx.log(ngx.DEBUG, "router_api_key=", k)

    return k
end

local function exit_401(errmsg)
    ngx.status = ngx.HTTP_UNAUTHORIZED
    ngx.header["Content-Type"] = "text/html; charset=UTF-8"
    ngx.header["WWW-Authenticate"] = "oauthjwt"

    if errmsg ~= nil then
        ngx.log(ngx.ERR, errmsg)
    end

    ngx.log(ngx.WARN, Constants.UNAUTHORIZED_MSG, errmsg)
    ngx.say(Constants.UNAUTHORIZED_MSG)

    return ngx.exit(ngx.HTTP_UNAUTHORIZED)
end

-- main function
local function validate_or_exit()
    -- 1. find user auth token from request
    local token, err = extract_auth_token()

    if token == nil then
        ngx.log(ngx.INFO, "anonymous user denied")
        return exit_401()
    end

    -- 2. load current user id
    local cluster_domain = os.getenv("CLUSTER_DOMAIN")
    local cluster_name = os.getenv("CLUSTER_NAME")

    pip = PIP.new{cluster_domain = cluster_domain}
    pim = PIM.new{cluster_domain = cluster_domain, cluster_name = cluster_name}
    pdp = PDP.new{cluster_domain = cluster_domain}

    local uid, err = pip:query_user_id(token)

    if err ~= nil then
        ngx.log(ngx.ERR, err)
        return err
    end

    -- 3. grant permission if client api key matches
    local required_key = os.getenv("CLIENT_API_KEY")
    local provided_key = extract_router_api_key()

    if required_key == provided_key then
        ngx.log(ngx.INFO, "granting access. reason=router-api-key, uid=", uid)
        return
    end

    -- 4. load current user's role
    local role_id, err = pim:query_user_role(token, uid)

    if err ~= nil then
        ngx.log(ngx.ERR, err)
        return err
    end

    -- 5. if cluster admin, grant access
    if (role_id == Constants.CLUSTER_ADMIN ) then
        ngx.log(ngx.INFO, "granting access. reason=cadmin, uid=", uid, ",role=", role_id)
    else
        -- 6. check namespace permission for non cluster admins
        -- 6a. load required namespaces by kibana
        ngx.log(ngx.INFO, "checking namespace permission. uid=", uid, ",role=", role_id)
        local arr_text = os.getenv("AUTHORIZED_NAMESPACES")
        ngx.log(ngx.DEBUG, "env var AUTHORIZED_NAMESPACES=", arr_text)
        local authorized_ns = {}

        if arr_text then
            arr_text = string.gsub(arr_text, "%[", "{")
            arr_text = string.gsub(arr_text, "%]", "}")
            local arr_func, err = load("return " .. arr_text)

            if err ~= nil then
                ngx.log(ngx.ERR, err)
                return err
            end

            authorized_ns = arr_func()
        end

        ngx.log(ngx.INFO, "kibana authorized namespaces=", Util.to_string(authorized_ns))

        -- 6b. load authorized namespaces
        local allowed = false

        if authorized_ns==nil or #authorized_ns == 0 then
            -- grant deny if no namespace access authorized
            ngx.log(ngx.INFO, "kibana has 0 authorized namespaces")
            allowed = false
        else
            -- 6c. load granted namespaces by platform identity manager
            local num_granted_ns, granted_ns, err = pim:query_user_namespaces(token, uid)
            ngx.log(ngx.INFO, "platform identity manager granted namespaces=",
                Util.keys_to_string(granted_ns))

            if err ~= nil then
                ngx.log(ngx.ERR, err)
                return err
            end

            if num_granted_ns == 0 then
                return exit_401()
            end

            -- 6d. compare required and granted namespaces
            local authorized_ns_set = Set.new(authorized_ns)
            local granted_ns_set = Set.fromTableKeys(granted_ns)
            allowed = granted_ns_set:containsAny(authorized_ns_set)

            ngx.log(ngx.INFO, "access allowed:", allowed, ",uid=", uid, ",role=", role_id)
        end

        if not allowed then
            return exit_401()
        end
    end
end

-- expose interface
local _M = {}
_M.validate_or_exit = validate_or_exit
return _M
