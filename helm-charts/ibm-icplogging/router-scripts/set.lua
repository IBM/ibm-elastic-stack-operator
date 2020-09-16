-- Licensed Materials - Property of IBM
-- 5737-E67
-- @ Copyright IBM Corporation 2016, 2020. All Rights Reserved.
-- US Government Users Restricted Rights - Use, duplication or disclosure restricted by GSA ADP Schedule Contract with IBM Corp.

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
