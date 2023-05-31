local skynet = require "skynet"
local service = require "service"
service.client = {}

service.resp.client = function(source, fd, cmd, msg)
     skynet.error("service.resp.client call " .. fd .. " cmd=" .. cmd .. " msg[1]=" .. msg[1] .. " msg[2]" .. msg[2] .. " msg[3]=" .. tostring(msg[3]))
    if service.client[cmd] then
        local ret_msg = service.client[cmd](fd, msg, source)
        skynet.send(source, "lua", "send_by_fd", fd, ret_msg)
    else
        skynet.error("service.resp.client fail", cmd)
    end
end

service.client.login = function(fd, msg, source)
    local playerid = tonumber(msg[2])
    local pwd = msg[3]
    local gate = source
    local node = skynet.getenv("node")
    skynet.error("login fd=" .. fd)
    -- 校验用户名密码
    if pwd ~= "123" then
        skynet.error("密码错误")
        return {"login", 1, "密码错误"}
    end
    -- 发送给agentmgr
    local isok, agent = skynet.call("agentmgr", "lua", "reqlogin", playerid, node, gate)
    skynet.error("call agentmgr isok=" .. tostring(isok))

    if not isok then
        return {"login", 1, "请求agentmgr失败"}
    end
    -- 回应gate
    local isok = skynet.call(gate, "lua", "confirm_agent", fd, playerid, agent)
    --skynet.error("call condirm_agent isok=" .. tostring(isok))
    if not isok then
        return {"login", 1, "gate注册失败"}
    end
    skynet.error("login succ " .. playerid)
    return {"login", 0, "登陆成功"}
end

service.start(...)

