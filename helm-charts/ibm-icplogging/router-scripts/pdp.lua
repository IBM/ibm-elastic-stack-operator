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
