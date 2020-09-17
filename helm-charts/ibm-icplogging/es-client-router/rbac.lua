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

local cjson = require "cjson"
local cookiejar = require "resty.cookie"
local http = require "lib.resty.http"
local qparser = require "qparser"

local cluster_domain = os.getenv("CLUSTER_DOMAIN")
local cluster_name = os.getenv("CLUSTER_NAME")

-- NOTE-1: as of now, only ICP external calls are screened for RBAC
-- The below is predicated on the fact all external calls go through auth proxies
-- and "will" come in with an auth header.
-- if there is no auth header, the call is assumed to made from within ICP e.g. filebeat
-- and will be allowed to go through unrestricted

-- NOTE-2: non admin user has access to only search apis,
-- which is enough for "discovering", visualizing,  dashboarding and managing in Kibana UI

local unrestricted_api_uri_pattern_map = { 
    _kibana = "^/.kibana[%d]*/",
    _template = "^/(_template)",
    _mapping = "^/(_mapping)",
    _aliases = "^/(_aliases)"
}

local restricted_api_uri_pattern_map = { 
    _msearch = "^/_msearch",
    _search = "^/[^/]+/(_search)"
}

local api_group_map = { 
    _kibana = "unrestricted",
    _template = "unrestricted",
    _mapping = "unrestricted",
    _aliases = "unrestricted",
    _msearch = "restricted",
    _search = "restricted",
    _unknown = "unauthorized"
}
local audit_index = "audit-"
local role_clusteradmin = '"ClusterAdministrator"'
local role_auditor = '"Auditor"'


local function exit_401(errmsg)
    ngx.status = ngx.HTTP_UNAUTHORIZED
    ngx.header["Content-Type"] = "text/html; charset=UTF-8"
    ngx.header["WWW-Authenticate"] = "oauthjwt"
    if errmsg == nil then
      errmsg = 'Authorization error occured'
    end
    ngx.log(ngx.WARN, "Request Not authorized ", errmsg)
    ngx.say(errmsg)
    return ngx.exit(ngx.HTTP_UNAUTHORIZED)
end

local function get_auth_token()
    local auth_header = ngx.var.http_Authorization
    local token = nil
    if auth_header ~= nil then
        ngx.log(ngx.DEBUG, "Authorization header found,extracting token.")
        _, _, token = string.find(auth_header, "Bearer%s+(.+)")
    end

    return token
end

local function get_user_id(token)
    local httpc = http.new()
    local res, err = httpc:request_uri("https://platform-identity-provider.{{ .Release.Namespace }}.svc."..cluster_domain..":4300/v1/auth/userInfo", {
        method = "POST",
        ssl_verify = false,
        body = "access_token=" .. token,
        headers = {
          ["Content-Type"] = "application/x-www-form-urlencoded",
        }
      })

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
    ngx.log(ngx.DEBUG, "user id ", uid)
    return uid
end

local function get_user_role(token, uid)
    local httpc = http.new()
    -- curl -k --header "Authorization: Bearer ${ACCESS_TOKEN}" https://platform-identity-management.ibm-common-services.svc.cluster.local:4500/identity/api/v1/users/user2/getHighestRole    
    local res, err = httpc:request_uri("https://platform-identity-management.{{ .Release.Namespace }}.svc."..cluster_domain..":4500/identity/api/v1/users/" .. uid .. "/getHighestRole", {
        method = "GET",
        ssl_verify = false,
        headers = {
          ["Content-Type"] = "application/json",
          ["Authorization"] = "Bearer ".. token
        },
        ssl_verify = false
    })
    if not res then
        ngx.log(ngx.ERR, "Failed to request user role due to ",err)
        return nil, exit_401()
    end
    if (res.body == "" or res.body == nil) then
        ngx.log(ngx.ERR, "Empty response body")
        return nil, exit_401()
    end
    local role_id = tostring(res.body)
    ngx.log(ngx.DEBUG, "user role: ", role_id)
    return role_id
end

local function get_user_namespaces(token, uid)
    local httpc = http.new()
    res, err = httpc:request_uri("https://platform-identity-management.{{ .Release.Namespace }}.svc."..cluster_domain..":4500/identity/api/v1/users/" .. uid .. "/getTeamResources", {
        method = "GET",
        ssl_verify = false,
        headers = {
          ["Content-Type"] = "application/json",
          ["Authorization"] = "Bearer ".. token
        },
        query = {
            ["resourceType"] = "namespace"
        },
        ssl_verify = false
    })
    if not res then
        ngx.log(ngx.ERR, "Failed to request user's authorized namespaces due to ",err)
        return nil, exit_401()
    end
    if (res.body == "" or res.body == nil) then
        ngx.log(ngx.ERR, "Empty response body")
        return nil, exit_401()
    end
    local x = tostring(res.body)
    ngx.log(ngx.DEBUG, "namespaces ",x)
    local namespaces = {}
    local num_namespaces = 0
    for i, entry in ipairs(cjson.decode(x)) do
        ngx.log(ngx.DEBUG, "namespaceId ",entry.namespaceId, " crn: ", entry.crn)
        namespaces[entry.namespaceId] = entry.crn
        num_namespaces = num_namespaces + 1
    end
    return num_namespaces, namespaces
end

local function get_user_audit_namespaces(token, namespaces)

    -- build crn map for user later to parse authz response
    local namespaces_crn = {}

    -- build input for authz request
    local input_array = {}
    local input_entry = '{"action":"audit.view","subject":{"id": "","type": ""},"resource":{ "crn":"","attributes":{"serviceName":"","accountId":""}}}'
    for id, crn in pairs(namespaces) do
      namespaces_crn[crn] = id
      local entry = cjson.decode(input_entry)
      entry.resource.crn = crn
      table.insert(input_array, entry)
    end

    -- make the authz call
    local httpc = http.new()
    local req_body = '{"inputArray":'..cjson.encode(input_array)..'}'
    ngx.log(ngx.DEBUG, "req body  ",req_body)

    res, err = httpc:request_uri("https://iam-pdp.{{ .Release.Namespace }}.svc."..cluster_domain..":7998/v1/authz_bulk" , {
        method = "POST",
        ssl_verify = false,
        body = req_body,
        headers = {
          ["Content-Type"] = "application/json",
          ["Authorization"] = "Bearer ".. token
        },
        ssl_verify = false
    })

    if not res then
        ngx.log(ngx.ERR, "Failed to request user's authorized namespaces due to ",err)
        return nil, exit_401()
    end
    if (res.body == "" or res.body == nil) then
        ngx.log(ngx.ERR, "Empty response body")
        return nil, exit_401()
    end
    local resp_data = tostring(res.body)
    ngx.log(ngx.DEBUG, "output ",resp_data)

    -- parse response from authz call
    local num_audit_ns = 0
    local audit_ns = {}

    for i, resp_entry in ipairs(cjson.decode(resp_data).responses) do
        if resp_entry.output.decision == 'Permit' then
            local ns_crn = resp_entry.input.resource.crn
            local ns_id = namespaces_crn[ns_crn]
            if ns_id ~= nil and ns_crn ~= nil then
              audit_ns[ns_id] = ns_crn
              ngx.log(ngx.DEBUG, "added to audit namespaces: ",ns_id, " crn:",ns_crn)
            end
            num_audit_ns = num_audit_ns + 1
        end
    end

    return num_audit_ns, audit_ns
end

local function get_user_app_namespaces(token, user_namespaces)
    local num_app_ns = 0
    local app_ns = {}

    local num_audit_ns, audit_ns = get_user_audit_namespaces(token, user_namespaces)
    for id, crn in pairs(user_namespaces) do
        ngx.log(ngx.DEBUG, "namespace ", id)
        if(audit_ns[id] == nil ) then
            ngx.log(ngx.DEBUG, "No audit access, adding to app access ", id)
            app_ns[id] = crn
            num_app_ns = num_app_ns + 1
        end
    end
    return num_app_ns, app_ns
end

-- sample URIs to extract
-- A. static
-- A1. /.kibana: /.kibana/doc/config%3A6.6.1/_update?refresh=wait_for
--     /.kibana: /.kibana/_search?size=10000&from=0&rest_total_hits_as_int=true
--     /.kibana: /.kibana/_mget
-- A2. /_template?pretty
-- A3. /_mapping?pretty
-- A4. /_aliases?pretty
-- B. dynamic
-- B1. _msearch: /_msearch?rest_total_hits_as_int=true&ignore_throttled=true
-- B2. _search: /index-name/_search: /logstash-*/_search
local function get_api_type(req_uri,req_body)
    local api_type = "_unknown"
    
    for api, pattern in pairs(unrestricted_api_uri_pattern_map) do
        local match = req_uri:match(pattern)
        if match then
            ngx.log(ngx.DEBUG, "unrestricted api=", api, ",uri=", req_uri)
            api_type = api
            break
        end        
    end

    if api_type == "_unknown" then
        for api, pattern in pairs(restricted_api_uri_pattern_map) do
            local match = req_uri:match(pattern)
            if match then
                ngx.log(ngx.DEBUG, "restricted api=", api, ",uri=", req_uri)
                api_type = api
                break
            end        
        end
    end
    
    return api_type
end

-- Given the list of indices found in request body
-- check if requesting audit indices only, app indices only or both
local function get_index_types(req_indices)
    local audit_indices=0
    local app_indices=0

    for i, indexpattern in ipairs(req_indices) do
      if indexpattern:find("^"..audit_index) ~= nil then
        audit_indices = audit_indices + 1
      else
        local mod_indexpattern = indexpattern:gsub("*",".*")
        if audit_index:find(mod_indexpattern) ~= nil then
          audit_indices = audit_indices + 1
        end
        app_indices = app_indices + 1
      end
    end

    local audit_indices_only = false
    if audit_indices > 0 and app_indices == 0 then
      audit_indices_only = true
    end
    local app_indices_only = false
    if app_indices > 0 and audit_indices == 0 then
      app_indices_only = true
    end
    ngx.log(ngx.DEBUG, "audit_indices_only: ",audit_indices_only, " app_indices_only:", app_indices_only)
    return audit_indices_only, app_indices_only
end

local function log_certs()
    ngx.log(ngx.DEBUG, "DN=", ngx.var.ssl_client_s_dn, ",cert_authorized=", ngx.var.cert_authorized)
end

-- this is the top level function that  validates if  incoming request
-- is authorized and if necessary rewrites the req query to filter resp data
local function validate_and_rewrite_query()
    -- cert logging is disabled to reduce log volume
    -- log_certs()

    ngx.log(ngx.INFO, "1. looking for user auth token from request")
    local token, err = get_auth_token()

    if token ~= nil then
        ngx.log(ngx.INFO, "2. load current user id")
        local uid, err = get_user_id(token)
        if err ~= nil then
            return err
        end

        ngx.log(ngx.INFO, "3. query role for uid ", uid)
        local role_id, err = get_user_role(token, uid)
        if err ~= nil then
            return err
        end

        -- Cluster Admin has unrestricted access to all
        -- go through rbac process only if non-admin
        if (role_id ~= role_clusteradmin ) then
            local req_uri = ngx.var.request_uri
            ngx.log(ngx.DEBUG, " request_uri: ", req_uri)

            ngx.req.read_body()
            local req_body = ngx.req.get_body_data()
            ngx.log(ngx.DEBUG,"request body",req_body)

            ngx.log(ngx.INFO, "4. trim role access to role_id:", role_id)
            -- validate if requested api is authorized
            -- some calls like kibana internal can go through unrestricted
            ngx.log(ngx.INFO, "4a. detecting api type and permission group for ", req_uri)
            local api_type = get_api_type(req_uri, req_body)
            local api_group = api_group_map[api_type]
            ngx.log(ngx.INFO, "api_type: ", api_type, ",api_group: ", api_group)

            if api_group == 'unrestricted' then
                return
            end

            if api_group == 'unauthorized' then
                return exit_401()
            end

            ngx.log(ngx.INFO, 
                "5. making sure auditor can only see audit logs, and other roles for non-audit logs")
            local req_indices = qparser.get_req_indices(req_body)
            local audit_indices_only, app_indices_only = get_index_types(req_indices)
            ngx.log(ngx.INFO, "audit_indices_only: ", audit_indices_only,
                ",app_indices_only: ", app_indices_only, ",role_id: ", role_id)
            
            if (role_id ~= role_auditor and true == audit_indices_only) then
                ngx.log(ngx.INFO, "access to audit log denied for role_id: ", role_id, ",uid:", uid)
                local modified_reqbody = qparser.add_blank_filters(req_body)
                ngx.req.set_body_data(modified_reqbody)
                ngx.log(ngx.INFO, "updated reqbody with blank filter ", ngx.req.get_body_data())
            end

            if (role_id == role_auditor and true == app_indices_only) then
                ngx.log(ngx.INFO, "access to app log denied for role_id: ", role_id, ",uid:", uid)
                local modified_reqbody = qparser.add_blank_filters(req_body)
                ngx.req.set_body_data(modified_reqbody)
                ngx.log(ngx.INFO, "updated reqbody with blank filter ", ngx.req.get_body_data())
            end

            ngx.log(ngx.INFO, "6. trim namespace access to uid:", uid)
            -- If search api, parse and validate access to indices and namespaces
            if api_type == "_msearch" or api_type == "_search" then
                ngx.log(ngx.INFO, "6a. querying entitled app and audit log namespaces for ", uid)
                -- get all user namespaces
                local num_user_ns, user_ns, err = get_user_namespaces(token, uid)
                if err ~= nil then
                    return err
                end

                -- authorized namespaces for log index
                local authorized_namespaces = {}

                if audit_indices_only == true then
                    local num_audit_ns, audit_ns = get_user_audit_namespaces(token, user_ns)
                    if num_audit_ns > 0 then
                        authorized_namespaces = audit_ns
                    end
                elseif app_indices_only == true then
                    -- auditors do not have access to app logs, filter out ns with audit access
                    local num_app_ns, app_ns = get_user_app_namespaces(token, user_ns)
                    if num_app_ns > 0 then
                        authorized_namespaces = app_ns
                    end
                else
                    -- current limitation is that search index has to match either  audit or app logs, not match both
                    -- i.e.  either 'audit-*' or 'logstash-*' are valid, while '*' is not
                    ngx.log(ngx.ERR, "Search index has to match either audit or app log, not both ")
                end

                -- rewrite query with a namespace filter that includes all authorized namespaces
                ngx.log(ngx.INFO, "6b. rewriting query with namespace filters")
                if next(authorized_namespaces) then
                    local modified_reqbody = qparser.add_namespace_filters(req_body, authorized_namespaces)
                    ngx.req.set_body_data(modified_reqbody)
                    ngx.log(ngx.INFO, "updated reqbody with namespace filter", ngx.req.get_body_data())
                else
                    ngx.log(ngx.INFO, "Not rewriting query since authorized_namespaces is empty")
                end                
            end
        end
    end
end

-- Expose interface.
local _M = {}
_M.validate_and_rewrite_query = validate_and_rewrite_query
return _M
