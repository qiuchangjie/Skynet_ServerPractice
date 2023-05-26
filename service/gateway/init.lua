local skynet = require "skynet"
local service = require "service"
local socket = require "skynet.socket"
local runconfig = require "runconfig"

conns = {} -- [fd] = conn
players = {} -- [playerid] = gateplayer

-- 连接类
function conn()
    local m = {
        fd = nil,
        playerid = nil,
    }
    return m
end

-- 玩家类
function gateplayer()
    local m = {
        playerid = nil,
        agent = nil,
        conn = nil,
    }
    return m
end

local process_buff = function(fd, readbuff)
end

local disconnect = function(fd)
end

-- 每一条连接接收数据处理
-- 协议格式 cmd, arg1, arg2, ...#
local recv_loop = function(fd)
    socket.start(fd)
    skynet.error("socket connected " .. fd)
    local readbuff = ""
    while true do
        local recvstr = socket.read(fd)
        if recvstr then
            readbuff = readbuff .. recvstr
            readbuff = process_buff(fd, readbuff)
        else
            skynet.error("socket close " .. fd)
            disconnect(fd)
            socket.close(fd)
            return
        end
    end

end

local connect = function(fd, addr)
    print("connect from " .. addr .. " " .. fd)
    local connobj = conn()
    conns[fd] = connobj
    connobj.fd = fd
    skynet.fork(recv_loop, fd)
end

function service.init()
    skynet.error("[start]" .. service.name .. " " .. service.id)
    local node = skynet.getenv("node")
    local nodecfg = runconfig[node]
    local port = nodecfg.gateway[service.id].port

    local listenfd = socket.listen("0.0.0.0", port)
    skynet.error("Listen socket : ", "0.0.0.0", port)
    socket.start(listenfd, connect)
end

service.start(...)

