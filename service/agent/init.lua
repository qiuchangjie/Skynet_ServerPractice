local skynet = require "skynet"
local service = require "service"

service.client = {}
service.gate = nil

service.resp.client = function(source, cmd, msg)
    service.gate = source
    if service.client[cmd] then
        local ret_msg = service.client[cmd](msg, source)
        if ret_msg then
            skynet.send(source, "lua", "send", service.id, ret_msg)
        end
    else
        skynet.error("service.resp.client fail", cmd)
    end
end

service.init = function()
    -- 在此处加载角色数据
    skynet.sleep(200)
    service.data = {
        coin = 100,
        hp = 200,
    }
end

service.resp.kick = function(source)
    -- 此处保存角色数据
    skynet.sleep(200)
end

service.resp.exit = function(source)
    skynet.exit()
end

-- 测试协议work
service.client.work = function(msg)
    service.data.coin = service.data.coin + 1
    return {"work", service.data.coin}
end

service.start(...)

