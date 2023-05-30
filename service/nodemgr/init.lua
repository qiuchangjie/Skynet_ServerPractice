local skynet = require "skynet"
local service = require "service"

service.resp.newservice = function(source, name, ...)
    local srv = skynet.newservice(name, ...)
    return srv
end

service.start(...)
