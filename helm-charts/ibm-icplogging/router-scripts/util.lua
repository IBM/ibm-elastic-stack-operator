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

local Util = {}

local function to_string(obj)
    local s = ""

    if obj then
        s = "{"
        for k, v in pairs(obj) do
            s = s .. k .. "=" .. v .. ","
        end

        s = s .. "}"
    else
        s = "nil"
    end

    return s
end


local function keys_to_string(obj)
    local s = "{"

    for k, _ in pairs(obj) do
        s = s .. k .. ","
    end

    s = s .. "}"

    return s
end

Util.to_string = to_string
Util.keys_to_string = keys_to_string

return Util
