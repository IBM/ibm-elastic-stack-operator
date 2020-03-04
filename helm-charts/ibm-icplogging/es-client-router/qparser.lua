-- Licensed Materials - Property of IBM
-- 5737-E67
-- @ Copyright IBM Corporation 2016, 2019. All Rights Reserved.
-- US Government Users Restricted Rights - Use, duplication or disclosure restricted by GSA ADP Schedule Contract with IBM Corp.
--
-- this query-parser parses the  request body of elastic "search" queries
-- note: search calls coming in from kibana are multisearch  (_msearch) queries,
-- "_search" calls has one query, while "_msearch" has  multiple queries.
-- although there are several ways to structure the  query..
-- kibana only uses a subset of the ways and follows a standard format.
-- e.g. you can specify the query filters either in the request uri or req body
-- kibana only uses the request body unless forced to do otherwise using the config params.
-- the high-level request body format is as below
-- {index header} \n (query body} \n {index header} \n (query body} \n ...
-- index header -  indicates the indices to search in
-- query header -  standard full text query obj in query DSL
-- with in query header -  the lucene query string is set under "query_string"
-- and the kibana filters are set under "match_phrase"
-- below is an example with all extraneous fields trimmed
-- { "index":[ "audit-*"]}
-- { "query":{
--     "bool":{
--      "must":[
--        {
--          "query_string":{ "analyze_wildcard":true, "query":"kubernetes.namespace: kube-system"}
--        },
--        {
--          "match_phrase":{
--              "kubernetes.container_name":{
--                "query":"router"
--              }
--          }
--        }]}}
--  }
-- https://github.ibm.com/IBMPrivateCloud/roadmap/issues/31646
-- kibana request changed for index. New format for index is not array but string
-- { "index":"audit-*"}

local cjson = require "cjson"
local OPERANDS = { OR=true, AND=true}

local function get_req_objects(reqbody)
    local index_objs = {}
    local query_objs = {}
    if (reqbody ~= nil) then
        for json_obj in string.gmatch(reqbody, "(%b{})") do
            local params = cjson.decode(json_obj)
            if params.index ~= nil then
                table.insert(index_objs, params.index)
            else
                if params.query ~= nil then
                    table.insert(query_objs, params.query)
                end
            end
        end
    end
    return index_objs, query_objs
end

local function get_req_indices(reqbody)
    local indices = {}
    if (reqbody ~= nil) then
        for jsonstr in string.gmatch(reqbody, "(%b{})") do
            local index_obj = cjson.decode(jsonstr).index
            if index_obj ~= nil then
                if type(index_obj) == "string" then
                   ngx.log(ngx.INFO,"index name:", index_obj)
                   table.insert(indices, index_obj)
                else
                    for j,index_name in ipairs(index_obj) do
                        ngx.log(ngx.INFO,"index name:", index_name)
                        table.insert(indices, index_name)
                    end
                end
            end
        end
    end
    return indices
end

local function parse_query_string(query, namespaces)
    _,_,qstring = string.find(query, "\"query_string\":(%b{})")
    ngx.log(ngx.INFO,"qstring", qstring)
    if qstring ~= nil then
        _,_,namespacelist = string.find(qstring, "kubernetes.namespace%s*:%s*(%b())")
        ngx.log(ngx.INFO,"namespacelist", namespacelist)
        if namespacelist ~= nil then
            for namespace in string.gmatch(string.sub(namespacelist,2, -2), "(%S+)") do
                if OPERANDS[namespace] == nil then
                    if(namespace ~= nil) then table.insert(namespaces, namespace) end
                end
            end
        else
            _,_,namespace = string.find(qstring, "kubernetes.namespace%s*:%s*(%S-)%s*\"")
            ngx.log(ngx.INFO,"namespace", namespace)
            if(namespace ~= nil) then table.insert(namespaces, namespace) end
        end
    end
    return namespaces
end

local function parse_match_phrase(query, namespaces)
    --before doing a full parse check if there are any namespaces filters set at all
    if string.find(query, "kubernetes.namespace") ~= nil then
        for mphrase in string.gmatch(query, "\"match_phrase\":(%b{})") do
            ngx.log(ngx.INFO,"mphrase", mphrase)
            local namespace = cjson.decode(mphrase)["kubernetes.namespace"]
            if type(namespace)=='table' then
                namespace = namespace.query
                ngx.log(ngx.INFO,"namespaceq", namespace)
            end
            ngx.log(ngx.INFO,"namespace", namespace)
            if(namespace ~= nil) then table.insert(namespaces, namespace) end
        end
    end
    return namespaces
end

local function get_req_namespaces(reqbody)
    local namespaces = {}
    if reqbody ~= nil then
        for jsonstr in string.gmatch(reqbody, "(%b{})") do
            local query_obj = cjson.decode(jsonstr).query
            if query_obj ~= nil then
                local query = cjson.encode(query_obj)
                ngx.log(ngx.INFO,"query", query)
                -- before doing a full parse, check if any namespaces specified at all
                if string.find(query, "kubernetes.namespace") ~= nil then
                    -- in lucene querystring
                    namespaces = parse_query_string(query, namespaces)
                    -- in query filters
                    namespaces = parse_match_phrase(query, namespaces)
                end
            end
        end
    end
    return namespaces
end

local function add_namespace_filters(reqbody, auth_namespaces)

    -- insert query string if none found
    local modified_reqbody = reqbody:gsub("(\"match_all\"%s*:%s*{%s*})", "\"query_string\":{\"query\":\"*\"}")

    local authnamespaces_str=""
    -- build namespaces filters query string
    for namespace, v in pairs(auth_namespaces) do
        authnamespaces_str = authnamespaces_str.." OR ".."\\\""..namespace.."\\\""
    end
    authnamespaces_str=authnamespaces_str:gsub("^%s*OR", "")
    ngx.log(ngx.INFO, "auth namespace str ", authnamespaces_str)

    -- add filters to query string
    modified_reqbody = modified_reqbody:gsub("(query_string.-\"query\"%s*:%s*\")", "%1 kubernetes.namespace:( "..authnamespaces_str.." ) AND ")
    return modified_reqbody
end

-- Expose interface.
local _M = {}
_M.get_req_namespaces = get_req_namespaces
_M.get_req_indices = get_req_indices
_M.add_namespace_filters = add_namespace_filters
return _M
