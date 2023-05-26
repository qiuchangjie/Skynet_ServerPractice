local skynet = require "skynet"
local cluster = require "skynet.cluster"

local M = {
    -- 类型和id
    name    = "",
    id      = "",
    -- 回调函数
    eixt    = nil,
    init    = nil,
    -- 分发方法
    resp = {},
}

function init()
    skynet.dispatch("lua", dispatch)
    if M.init then
        M.init()
    end
end

function M.start(name, id, ...)
    M.name = name
    M.id = tonumber(id)
    skynet.start(init)
end

function M.call(node, srv, ...)
    local mynode = skynet.getenv("node")
    if node == mynode then
        return skynet.call(srv, "lua", ...)
    else
        return cluster.call(node, srv, ...)
    end
end

function M.send(node, srv, ...)
    local mynode = skynet.getenv("node")
    if node == mynode then
        return skynet.send(srv, "lua", ...)
    else
        return cluster.send(node, srv, ...)
    end
end

return M
