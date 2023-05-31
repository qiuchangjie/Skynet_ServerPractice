local skynet = require "skynet"
local service = require "service"
local runconfig = require "runconfig"
local mynode = skynet.getenv("node")

service.client = {}
service.snode = nil -- scene_node
service.sname = nil -- scene_id

-- 尽量选择同节点下的服务
local function random_scene()
    -- 选择node
    local nodes = {}
    for i, v in pairs(runconfig.scene) do
        table.insert(nodes, i)
        if runconfig.scene[mynode] then
            table.insert(nodes, mynode)
        end
    end
    local idx = 1 -- math.random(1, #nodes)
    local scenenode = nodes[idx]

    -- 具体场景
    local scenelist = runconfig.scene[scenenode]
    idx = math.random(1, #scenelist)
    local sceneid = scenelist[idx]
    return scenenode, sceneid
end

service.client.enter = function(msg)
    if service.sname then
        return {"enter", 1, "已经在场景中"}
    end
    local snode, sid = random_scene()
    local sname = "scene" .. sid
    skynet.error("snode=" .. snode .. ", sid=" .. sid .. ", sname=" .. sname)
    local isok = service.call(snode, sname, "enter", service.id, mynode, skynet.self())
    if not isok then
        return { "enter", 1, "进入场景失败"}
    end
    service.snode = snode
    service.sname = sname
    return nil
end

-- 改变方向
service.client.shift = function(msg)
    if not service.sname then
        return
    end
    local x = msg[2] or 0
    local y = msg[3] or 0
    service.call(service.snode, service.sname, "shift", service.id, x, y)
end

service.leave_scene = function()
    -- 不在场景中
    if not service.sname then
        return
    end
    service.call(service.snode, service.sname, "leave", service.id)
    service.snode = nil
    service.sname = nil
end

