local request = (syn and syn.request) or request or http_request or (http and http.request)
local queueteleport = syn and syn.queue_on_teleport or queue_on_teleport or fluxus and fluxus.queue_on_teleport
local setthreadidentityfunc = syn and syn.set_thread_identity or set_thread_identity or setidentity or setthreadidentity
local getthreadidentityfunc = syn and syn.get_thread_identity or get_thread_identity or getidentity or getthreadidentity
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local lplr = Players.LocalPlayer
local entity, GuiLibrary, funcs = engoware.entity, engoware.GuiLibrary, engoware.funcs
local mouse = lplr:GetMouse()

function funcs:getRemote(list) 
    for i,v in next, list do if v == 'Client' then return list[i+1]; end end
end

local Flamework = require(game:GetService("ReplicatedStorage").rbxts_include.node_modules["@flamework"].core.out).Flamework
repeat task.wait() until Flamework.isInitialized
local Client, KnitClient = 
require(game:GetService("ReplicatedStorage").TS.remotes).default.Client, 
debug.getupvalue(require(lplr.PlayerScripts.TS.controllers.game["block-break-controller"]).BlockBreakController.onEnable, 1)

local Client_Get, Client_WaitFor = getmetatable(Client).Get, getmetatable(Client).WaitFor

local modules = {
    QueueMeta = require(game:GetService("ReplicatedStorage").TS.game["queue-meta"]).QueueMeta,
}

local remotes = {
    JoinQueueRemote = game:GetService("ReplicatedStorage")["events-@easy-games/lobby:shared/event/lobby-events@getEvents.Events"].joinQueue,
    LeaveQueueRemote = game:GetService("ReplicatedStorage")["events-@easy-games/lobby:shared/event/lobby-events@getEvents.Events"].leaveQueue,
}


function funcs:getQueueTitles() 
    local t = {}
    for i,v in next, modules.QueueMeta do 
        local title = v.title
        if string.lower(i) == 'bedwars_voice_chat' then 
            title = title.." (VC)" 
        end
        if v.rankCategory then
            title = title .. " " .. v.eventText
        end
        t[i] = title
    end
    return t
end

function funcs:getQueueFromTitle(title) 
    for i,v in next, funcs:getQueueTitles() do 
        if title == v then  
            return i
        end
    end
end

do 
    local queueTick
    local AutoQueueDelay, AutoQueueSelection = {}, {}
    local AutoQueue = {}; AutoQueue = GuiLibrary.Objects.utilitiesWindow.API.CreateOptionsButton({
        Name = "autoqueue",
        Function = function(callback) 
            if callback then 

                coroutine.wrap(function() 
                    
                    task.wait(AutoQueueDelay.Value)

                    queueTick = tick()
                    remotes.JoinQueueRemote:FireServer({queueType = funcs:getQueueFromTitle(AutoQueueSelection.Value)})

                    repeat task.wait(.1)
                        if tick() - queueTick > 30 then 
                            remotes.LeaveQueueRemote:FireServer()
                            task.wait(0.5)
                            remotes.JoinQueueRemote:FireServer({queueType = funcs:getQueueFromTitle(AutoQueueSelection.Value)})
                            queueTick = tick()
                        end
                    until not AutoQueue.Enabled

                end)()

            else
                remotes.LeaveQueueRemote:FireServer()
            end
        end,
    })
    AutoQueueSelection = AutoQueue.CreateDropdown({
        Name = "queue",
        List = funcs:getQueueTitles(),
        Function = function(value) 
            if AutoQueue.Enabled then
                AutoQueue.Toggle()
                AutoQueue.Toggle()
            end
        end,
    })
    AutoQueueDelay = AutoQueue.CreateSlider({
        Name = "delay",
        Value = 0,
        Min = 0,
        Max = 30,
        Round = 0,
        Function = function() end
    })

end
