local skynet = require "skynet"
local service = require "service"

local balls = {} -- [playerid] = ball

-- 球
function ball()
    local m = {
        playerid = nil,
        node = nil,
        agent = nil,
        x = math.random(0, 100),
        y = math.random(0, 100),
        size = 2,
        speedx = 0,
        speedy = 0,
    }
    return m
end

-- 球列表
local function balllist_msg()
    local msg = { "balllist" }
    for i, v in pairs(balls) do
        table.insert(msg, v.playerid)
        table.insert(msg, v.x)
        table.insert(msg, v.y)
        table.insert(msg, v.size)
    end
    return msg
end


local foods = {} -- [id] = food
local food_maxid = 0
local food_count = 0

-- 食物
function food()
    local m = {
        id = nil,
        x = math.random(0, 100),
        y = math.random(0, 100),
    }
    return m
end

-- 食物列表
local function foodlist_msg()
    local msg = { "foodlist" }
    for i, v in pairs(foods) do
        table.insert(msg, v.id)
        table.insert(msg, v.x)
        table.insert(msg, v.y)
    end
    return msg
end

-- 广播
local function broadcast(msg)
    for i, v in pairs(balls) do
        service.send(v.node, v.agent, "send", msg)
    end
end

-- 位置更新
local function ball_update(frame)
    for i, v in pairs(balls) do
        v.x = v.x + v.speedx * 0.2
        v.y = v.y + v.speedy * 0.2
        if v.speedx ~= 0 or v.speedy ~= 0 then
            local msg = { "move", v.playerid, v.x, v.y }
            broadcast(msg)
        end
    end
end

-- 生成食物
local function food_update(frame)
    if food_count > 50 then
        return
    end
    if math.random(1, 100) < 98 then
        return
    end
    food_maxid = food_maxid + 1
    food_count = food_count + 1
    local f = food()
    f.id = food_maxid
    foods[f.id] = f
    local msg = { "addfood", f.id, f.x, f.y }
    broadcast(msg)
end

-- 吞下食物
local function eat_update(frame)
    for pid, b in pairs(balls) do
        for fid, f in pairs(foods) do
            if (b.x - f.x) ^ 2 + (b.y - f.y) ^ 2 < b.size ^ 2 then
                b.size = b.size + 1
                food_count = food_count - 1
                local msg = { "eat", b.playerid, fid, b.size }
                broadcast(msg)
                foods[fid] = nil
            end
        end
    end
end

-- 主循环
local function update(frame)
    food_update(frame)
    ball_update(frame)
    eat_update(frame)
    -- 碰撞略
    -- 分裂略
end

-- 进入
service.resp.enter = function(source, playerid, node, agent)
    if balls[playerid] then -- 已经在战斗中
        return false
    end
    local b = ball()
    b.playerid = playerid
    b.node = node
    b.agent = agent
    -- 广播
    local entermsg = { "enter", playerid, b.x, b.y, b.size }
    broadcast(entermsg)
    -- 记录
    balls[playerid] = b
    -- 回应
    local ret_msg = { "enter", 0, "进入成功" }
    service.send(b.node, b.agent, "send", ret_msg)
    -- 发送战场信息
    service.send(b.node, b.agent, "send", balllist_msg())
    service.send(b.node, b.agent, "send", foodlist_msg())
    skynet.error("enter 成功 playerid=" .. playerid)
    return true
end

-- 退出
service.resp.leave = function(source, playerid)
    if not balls[playerid] then
        return false
    end
    balls[playerid] = nil
    local leavemsg = { "leave", playerid }
    broadcast(leavemsg)
end

-- 改变速度
service.resp.shift = function(source, playerid, x, y)
    local b = balls[playerid]
    if not b then
        return false
    end
    b.speedx = x
    b.speedy = y
    return true
end

service.init = function()
    skynet.fork(function()
        -- 保持帧率执行
        local stime = skynet.now()
        local frame = 0
        while true do
            frame = frame + 1
            local isok, err = pcall(update, frame)
            if not isok then
                skynet.error(err)
            end
            local etime = skynet.now()
            local waittime = frame * 20 - (etime - stime)
            if waittime <= 0 then
                waittime = 2
            end
            skynet.sleep(waittime)
        end
    end)
end

service.start(...)

