local skynet = require "skynet"
local runconfig = require "runconfig"
skynet.start(function()
    --初始化
    skynet.error("start main")
    -- skynet.error(runconfig.agentmgr.node)
    skynet.newservice("gateway", "gateway", 1)
    --退出自身
    skynet.exit()
end)
