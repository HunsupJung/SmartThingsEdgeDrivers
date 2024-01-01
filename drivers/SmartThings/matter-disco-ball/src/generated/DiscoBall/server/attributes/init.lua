-- Copyright 2022 SmartThings
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

-- DO NOT EDIT: this code is automatically generated by ZCL Advanced Platform generator.

local attr_mt = {}
attr_mt.__attr_cache = {}
attr_mt.__index = function(self, key)
  if attr_mt.__attr_cache[key] == nil then
    local req_loc = string.format("generated.DiscoBall.server.attributes.%s", key)
    local raw_def = require(req_loc)
    local cluster = rawget(self, "_cluster")
    raw_def:set_parent_cluster(cluster)
    attr_mt.__attr_cache[key] = raw_def
  end
  return attr_mt.__attr_cache[key]
end

--- @class generated.DiscoBallServerAttributes
---
--- @field public Run generated.DiscoBall.server.attributes.Run
--- @field public Rotate generated.DiscoBall.server.attributes.Rotate
--- @field public Speed generated.DiscoBall.server.attributes.Speed
--- @field public Axis generated.DiscoBall.server.attributes.Axis
--- @field public WobbleSpeed generated.DiscoBall.server.attributes.WobbleSpeed
--- @field public Pattern generated.DiscoBall.server.attributes.Pattern
--- @field public Name generated.DiscoBall.server.attributes.Name
--- @field public WobbleSupport generated.DiscoBall.server.attributes.WobbleSupport
--- @field public WobbleSetting generated.DiscoBall.server.attributes.WobbleSetting
--- @field public AcceptedCommandList generated.DiscoBall.server.attributes.AcceptedCommandList
--- @field public EventList generated.DiscoBall.server.attributes.EventList
--- @field public AttributeList generated.DiscoBall.server.attributes.AttributeList
local DiscoBallServerAttributes = {}

function DiscoBallServerAttributes:set_parent_cluster(cluster)
  self._cluster = cluster
  return self
end

setmetatable(DiscoBallServerAttributes, attr_mt)

return DiscoBallServerAttributes

