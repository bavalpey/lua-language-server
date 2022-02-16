local util   = require 'utility'
local guide  = require 'parser.guide'
local global = require 'vm.node.global'

---@class vm.state
local m = {}
---@type table<string, vm.node.global>
m.globals = util.defaultTable(global)
---@type table<uri, table<string, boolean>>
m.globalSubs = util.defaultTable(function ()
    return {}
end)
---@type table<uri, parser.object[]>
m.literals = util.multiTable(2)
---@type table<parser.object, table<parser.object, boolean>>
m.literalSubs = util.multiTable(2, function ()
    return setmetatable({}, util.MODE_K)
end)

---@param name   string
---@param uri    uri
---@param source parser.object
---@return vm.node.global
function m.declareGlobal(name, uri, source)
    m.globalSubs[uri][name] = true
    local node = m.globals[name]
    node:addSet(uri, source)
    return node
end

---@param name string
---@param uri? uri
---@return vm.node.global
function m.getGlobal(name, uri)
    if uri then
        m.globalSubs[uri][name] = true
    end
    return m.globals[name]
end

---@param uri    uri
---@param source parser.object
function m.declareLiteral(uri, source)
    local literals = m.literals[uri]
    literals[#literals+1] = source
end

---@param literal parser.object
---@param source  parser.object
function m.subscribeLiteral(literal, source)
    m.literalSubs[literal][source] = true
end

---@param uri uri
function m.dropUri(uri)
    local globalSub = m.globalSubs[uri]
    m.globalSubs[uri] = nil
    for name in pairs(globalSub) do
        m.globals[name]:dropUri(uri)
    end
    local literals = m.literals[uri]
    m.literals[uri] = nil
    for _, literal in ipairs(literals) do
        local literalSubs = m.literalSubs[literal]
        m.literalSubs[literal] = nil
        for source in pairs(literalSubs) do
            source._compiled = nil
        end
    end
end

return m
