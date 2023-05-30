local skynet = require "skynet"
local service = require "service"

STATUS = {
    LOGIN = 2,
    GAME = 3,
    LOGOUT = 4,
}

-- 玩家列表
local players = {}

-- 玩家类
function mgrplayer()
    local m = {
        playerid = nil,     -- 玩家id
        node = nil,         -- 该玩家对应gateway和agent所在的节点
        agent = nil,        -- 该玩家对应agent服务的id
        status = nil,       -- 状态，例如“登录中”
        gate = nil,         -- 该玩家对应gateway的id
    }
    return m
end

service.resp.reqlogin = function(source, playerid, node, gate)
    skynet.error("reqlogin playerid=" .. playerid)
    local mplayer = players[playerid]
    if mplayer and mplayer.status == STATUS.LOGOUT then
        skynet.error("reqlogin fail, at status LOGOUT " .. playerid)
        return false, mplayer.agent
    end
    if mplayer and mplayer.status == STATUS.LOGIN then
        skynet.error("reqlogin fail, at status LOGIN " .. playerid)
        return false, mplayer.agent
    end
    -- 在线，顶替
    if mplayer then
        local pnode = mplayer.node
        local pagent = mplayer.agent
        local pgate = mplayer.gate
        mplayer.status = STATUS.LOGOUT
        service.call(pnode, pagent, "kick")
        service.send(pnode, pagent, "exit")
        service.send(pnode, pgate, "send", playerid, {"kick", "顶替下线"})
        service.call(pnode, pgate, "kick", playerid)
    end
    -- 上线
    local player = mgrplayer()
    player.playerid = playerid
    player.node = node
    player.gate = gate
    player.agent = nil
    player.status = STATUS.LOGIN
    players[playerid] = player
    local agent = service.call(node, "nodemgr", "newservice", "agent", "agent", playerid)
    player.agent = agent
    player.status = STATUS.GAME
    return true, agent
end

service.resp.reqkick = function(source, playerid, reason)
    local mplayer = players[playerid]
    if not mplayer then
        return false
    end
    if mplayer.status == STATUS.GAME then
        return false
    end
    local pnode = mplayer.node
    local pagent = mplayer.agent
    local pgate = mplayer.gate
    mplayer.status = STATUS.LOGOUT
    service.call(pnode, pagent, "kick")
    service.send(pnode, pagent, "exit")
    service.send(pnode, pgate, "kick", playerid)
    return true
end

service.start(...)
