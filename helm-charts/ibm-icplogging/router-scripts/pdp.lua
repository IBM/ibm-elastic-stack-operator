-- Licensed Materials - Property of IBM
-- 5737-E67
-- @ Copyright IBM Corporation 2016, 2020. All Rights Reserved.
-- US Government Users Restricted Rights - Use, duplication or disclosure restricted by GSA ADP Schedule Contract with IBM Corp.

local PDP = {}
PDP.__index = PDP

function PDP.new(old_obj)
    local new_obj = old_obj or {} 
    setmetatable(new_obj, PDP)
    return new_obj
end

local cjson = require "cjson"
local http = require "lib.resty.http"

return PDP
