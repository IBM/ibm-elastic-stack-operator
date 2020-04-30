-- Licensed Materials - Property of IBM
-- 5737-E67
-- @ Copyright IBM Corporation 2016, 2019. All Rights Reserved.
-- US Government Users Restricted Rights - Use, duplication or disclosure restricted by GSA ADP Schedule Contract with IBM Corp.

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

local non_admin_authorized_apis = { _msearch=true,  mget=true, _search=true }
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
    local res, err = httpc:request_uri("https://platform-identity-management.{{ .Release.Namespace }}.svc."..cluster_domain..":4500/identity/api/v1/users/" .. uid .. "/getHighestRoleForCRN", {
        method = "GET",
        ssl_verify = false,
        headers = {
          ["Content-Type"] = "application/json",
          ["Authorization"] = "Bearer ".. token
        },
        query = {
            ["crn"] = "crn:v1:icp:private:k8:"..cluster_name..":n/{{ .Release.Namespace }}:::"
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
    ngx.log(ngx.DEBUG, "user role ", role_id)
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

-- given the req uri and req_body
-- categorize the request has unauthorized, authorized
-- or unrestricted (pass through with no further validation/filtering)
local function get_api_type(req_uri,req_body)
    local api_type = "unauthorized"
    local _,_,trimmed_uri = string.find(req_uri,"/?([^/]*)")

    -- kibana internal requests pass through unrestricted
    if trimmed_uri:find("%.kibana") ~= nil then
        api_type = "unrestricted"
    elseif req_body and req_body:find("%.kibana") ~= nil then
        api_type = "unrestricted"
    elseif non_admin_authorized_apis[trimmed_uri] == true then
        api_type = "authorized"
    end

    ngx.log(ngx.DEBUG, "api_type ",api_type)
    return api_type
end

-- Given the list of indices found in request body
-- check if requesting audit indices only, app indices only or both
local function get_index_types(req_indices)
    local audit_indices=0
    local app_indices=0

    for i, indexpattern in ipairs(req_indices) do
      if  indexpattern:find("^"..audit_index) ~= nil then
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

    local token, err = get_auth_token()
    if token ~= nil then
        local uid, err = get_user_id(token)
        if err ~= nil then
            return err
        end

        local role_id, err = get_user_role(token, uid)
        if err ~= nil then
            return err
        end

        -- Cluster Admin has unrestricted access to all
        -- go through rbac process only if non-admin

        if (role_id ~= role_clusteradmin ) then
            -- validate access to requested api,indices,namespaces

            local req_uri = ngx.var.request_uri
            ngx.log(ngx.DEBUG, " request_uri: ", req_uri)

            ngx.req.read_body()
            local req_body = ngx.req.get_body_data()
            ngx.log(ngx.DEBUG,"request body",req_body)

            -- validate if requested api is authorized
            -- some calls like kibana internal can go through unrestricted
            local api_type = get_api_type(req_uri, req_body)
            if api_type == 'unrestricted' then
                return
            end

            -- If search api, parse and validate access to indices and namespaces
            if req_uri:find("search") ~= nil then

                -- get all user namespaces
                local num_user_ns, user_ns, err = get_user_namespaces(token, uid)
                if err ~= nil then
                    return err
                end

                if num_user_ns == 0 then
                    return exit_401("User not authorized to any namespaces")
                end

                -- authorized namespaces for log index
                local authorized_namespaces;
                local req_indices = qparser.get_req_indices(req_body)
                local audit_indices_only, app_indices_only = get_index_types(req_indices)

                if audit_indices_only == true then
                    local num_audit_ns, audit_ns = get_user_audit_namespaces(token, user_ns)
                    if num_audit_ns > 0 then
                        authorized_namespaces = audit_ns
                    else
                        return exit_401("User not authorized to view audit logs of any namespace")
                    end

                elseif app_indices_only == true then
                    -- auditors do not have access to app logs, filter out ns with audit access
                    local num_app_ns, app_ns = get_user_app_namespaces(token, user_ns)
                    if num_app_ns > 0 then
                        authorized_namespaces = app_ns
                    else
                        return exit_401("User not authorized to view app logs of any namespace")
                    end
                else
                    -- current limitation is that search index has to match either  audit or app logs, not match both
                    -- i.e.  either 'audit-*' or 'logstash-*' are valid, while '*' is not
                    return exit_401("Search index has to match either audit or app log, not both ")
                end

                -- if there are any namespace filters specified in the request
                -- check if  user has access to those namespaces
                local req_namespaces= qparser.get_req_namespaces(req_body)
                if #req_namespaces > 0 then
                    for i, name in ipairs(req_namespaces) do
                        ngx.log(ngx.DEBUG,"namespace ", "'"..name.."'")
                        if(authorized_namespaces[name] == nil ) then
                            return exit_401("User not authorized for namespace : "..name)
                        end
                    end
                end
                -- rewrite query with a namespace filter that includes all authorized namespaces
                ngx.log(ngx.NOTICE, "Rewriting query with namespace filters")
                local modified_reqbody = qparser.add_namespace_filters(req_body,authorized_namespaces)
                ngx.req.set_body_data(modified_reqbody)
                ngx.log(ngx.DEBUG, "updated reqbody ", ngx.req.get_body_data())
            end
        end
    end
end

-- Expose interface.
local _M = {}
_M.validate_and_rewrite_query = validate_and_rewrite_query
return _M
