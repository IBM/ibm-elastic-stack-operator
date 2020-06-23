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

local Set = {}
Set.__index = Set

function Set:refreshItemFlags()
  local flags = {}

  for _, v in ipairs(self) do
    flags[v] = true 
  end

  self.itemFlags = flags
end

function Set.new(old_obj)
    local set = old_obj or {} 
    setmetatable(set, Set)

    return set
end

function Set.fromTableKeys(t)
  local set = old_obj or {} 
  setmetatable(set, Set)

  local n=0
  
  for k, _ in pairs(t) do
    n = n + 1
    set[n] = k
  end

  return set
end

function Set:contains(otherSet)
  local r = true
  self:refreshItemFlags()

  for _, v in ipairs(otherSet) do
    if (not self.itemFlags[v]) then
      r = false
      break
    end
  end

  return r
end

function Set:containsAny(otherSet)
  local r = false
  self:refreshItemFlags()

  for _, v in ipairs(otherSet) do
    if self.itemFlags[v] then
      r = true
      break
    end
  end

  return r
end

return Set
