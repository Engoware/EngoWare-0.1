local request = (syn and syn.request) or request or http_request or (http and http.request)
local queueteleport = syn and syn.queue_on_teleport or queue_on_teleport or fluxus and fluxus.queue_on_teleport
local setthreadidentityfunc = syn and syn.set_thread_identity or set_thread_identity or setidentity or setthreadidentity
local getthreadidentityfunc = syn and syn.get_thread_identity or get_thread_identity or getidentity or getthreadidentity
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local lplr = Players.LocalPlayer
local entity, GuiLibrary, funcs = engoware.entity, engoware.GuiLibrary, engoware.funcs
local mouse = lplr:GetMouse()
local remotes, modules = {}, {}
local Hitboxes = {}
local whitelist = {};
local shalib = loadstring(funcs:require("lib/sha.lua"))()
whitelist = game:GetService("HttpService"):JSONDecode((funcs:require("https://github.com/7GrandDadPGN/whitelists/blob/main/whitelist2.json?raw=true", true, true)))

function funcs:getRemote(list) 
    for i,v in next, list do if v == 'Client' then return list[i+1]; end end
end

local Flamework = require(game:GetService("ReplicatedStorage").rbxts_include.node_modules["@flamework"].core.out).Flamework
repeat task.wait() until Flamework.isInitialized
local Client, KnitClient = 
require(game:GetService("ReplicatedStorage").TS.remotes).default.Client, 
debug.getupvalue(require(lplr.PlayerScripts.TS.controllers.game["block-break-controller"]).BlockBreakController.onEnable, 1)

local Client_Get, Client_WaitFor = getmetatable(Client).Get, getmetatable(Client).WaitFor

getmetatable(Client).Get = function(self, RemoteName)
    if RemoteName == remotes.SwordRemote then 
        local old = Client_Get(self, RemoteName)
        return {
            SendToServer = function(self, tab) 
                if Hitboxes.Enabled then 
                    pcall(function()
                        local mag = (tab.validate.selfPosition.value - tab.validate.targetPosition.value).magnitude
                        local newres = modules.HashVector(tab.validate.selfPosition.value + (mag > 14.4 and (CFrame.lookAt(tab.validate.selfPosition.value, tab.validate.targetPosition.value).LookVector * 4) or Vector3.new(0, 0, 0)))
                        tab.validate.selfPosition = newres
                    end)
                end
                local suc, plr = pcall(function() return Players:GetPlayerFromCharacter(tab.entityInstance) end)
                if suc and plr then
                    local playerattackable = funcs:isWhitelisted(plr)
                    if not playerattackable then 
                        return nil
                    end
                end
                return old:SendToServer(tab)
            end,
            instance = old.instance,
        }
    end
    return Client_Get(self, RemoteName)
end

engoware.UninjectEvent.Event:Connect(function() 
    getmetatable(Client).Get = Client_Get
    getmetatable(Client).WaitFor = Client_WaitFor
end)

modules = {
    Client = Client,

    BlockEngine = require(game:GetService("ReplicatedStorage")["rbxts_include"]["node_modules"]["@easy-games"]["block-engine"].out).BlockEngine,
    BlockBreaker = KnitClient.Controllers.BlockBreakController.blockBreaker,
    Maid = require(game:GetService("ReplicatedStorage")["rbxts_include"]["node_modules"].maid.Maid),

    QueueService = require(game:GetService("ReplicatedStorage")["rbxts_include"]["node_modules"]["@easy-games"].lobby.out.server.services["queue-service"]).QueueService,
    QueueMeta = require(game:GetService("ReplicatedStorage").TS.game["queue-meta"]).QueueMeta,
    ClientStore = require(lplr.PlayerScripts.TS.ui.store).ClientStore,

    AnimationUtil =  debug.getupvalue(require(game:GetService("ReplicatedStorage")["rbxts_include"]["node_modules"]["@easy-games"]["block-engine"].out.client["break"]["block-breaker"]).BlockBreaker.hitBlock, 6),
    BlockAnimationId = require(game:GetService("ReplicatedStorage")["rbxts_include"]["node_modules"]["@easy-games"]["block-engine"].out.shared.animation["animation-id"]).AnimationId,
    ViewmodelController = KnitClient.Controllers.ViewmodelController,

    BedwarsArmor = require(game:GetService("ReplicatedStorage").TS.games.bedwars["bedwars-armor-set"]).BedWarsArmor,
    BedwarsArmorSet = require(game:GetService("ReplicatedStorage").TS.games.bedwars["bedwars-armor-set"]).BedwarsArmorSet,

    SwordController = KnitClient.Controllers.SwordController,
    BedwarsSwords = require(game:GetService("ReplicatedStorage").TS.games.bedwars["bedwars-swords"]).BedwarsSwords,
    CombatConstant = require(game:GetService("ReplicatedStorage").TS.combat["combat-constant"]).CombatConstant,

    KnockbackUtil = require(game:GetService("ReplicatedStorage").TS.damage["knockback-util"]).KnockbackUtil,
    KnockbackConstant = debug.getupvalue(require(game:GetService("ReplicatedStorage").TS.damage["knockback-util"]).KnockbackUtil.calculateKnockbackVelocity, 1),

    SprintController = require(lplr.PlayerScripts.TS.controllers.global.sprint["sprint-controller"]).SprintController,

    IntentoryUtil = require(game:GetService("ReplicatedStorage").TS.inventory["inventory-util"]).InventoryUtil,
    GetInventory = function(plr) 
        if not plr then 
            return {items = {}, armor = {}}
        end

        local suc, ret = pcall(function() 
            return require(game:GetService("ReplicatedStorage").TS.inventory["inventory-util"]).InventoryUtil.getInventory(plr)
        end)

        if not suc then 
            return {items = {}, armor = {}}
        end

        if plr.Character and plr.Character:FindFirstChild("InventoryFolder") then 
            local invFolder = plr.Character:FindFirstChild("InventoryFolder").Value
            if not invFolder then return ret end
            for i,v in next, ret do 
                for i2, v2 in next, v do 
                    if typeof(v2) == 'table' and v2.itemType then
                        v2.instance = invFolder:FindFirstChild(v2.itemType)
                    end
                end
                if typeof(v) == 'table' and v.itemType then
                    v.instance = invFolder:FindFirstChild(v.itemType)
                end
            end
        end

        return ret
    end,

    GetItemMeta = require(game:GetService("ReplicatedStorage").TS.item["item-meta"]).getItemMeta,
    ItemMeta = debug.getupvalue(require(game:GetService("ReplicatedStorage").TS.item["item-meta"]).getItemMeta, 1),
    ItemDropController = require(lplr.PlayerScripts.TS.controllers.global["item-drop"]["item-drop-controller"]).ItemDropController,

    HashVector = function(vec) 
        return {value = vec}
    end
}
remotes = {
    SwordRemote = funcs:getRemote(debug.getconstants(modules.SwordController.attackEntity)),
    FallRemote = game:GetService("ReplicatedStorage").rbxts_include.node_modules.net.out._NetManaged.GroundHit,
    DamageBlock = game:GetService("ReplicatedStorage")["rbxts_include"]["node_modules"].net.out["_NetManaged"].DamageBlock,
    ItemDropRemote = funcs:getRemote(debug.getconstants(modules.ItemDropController.dropItemInHand)),
    ItemPickupRemote = funcs:getRemote(debug.getconstants(modules.ItemDropController.checkForPickup)),
    PaintRemote = funcs:getRemote(debug.getconstants(KnitClient.Controllers.PaintShotgunController.fire))
}
engoware.modules = modules
engoware.remotes = remotes

function funcs:getSword() 
    local highest, returning = -9e9, nil
    for i,v in next, modules.GetInventory(lplr).items do 
        local power = table.find(modules.BedwarsSwords, v.itemType)
        if not power then continue end
        if power > highest then 
            returning = v
            highest = power
        end
    end
    return returning
end

function funcs:getTool(blockMeta) 
    local highest, returning = -9e9, nil
    for i,v in next, modules.GetInventory(lplr).items do 
        local itemMeta = modules.GetItemMeta(v.itemType)
        local power = itemMeta.breakBlock and itemMeta.breakBlock[blockMeta.block.breakType] or 0
        if not power then continue end
        if power > highest then 
            returning = {item = v, meta = itemMeta}
            highest = power
        end
    end
    return returning.item, returning.meta
end

function funcs:isUncovered(block) 
    local amt = 0
    local normals = Enum.NormalId:GetEnumItems()
    for i,v in next, normals do 
        local pos = block.Position + (Vector3.FromNormalId(v) * 3 )
        if modules.BlockEngine:getStore():getBlockAt(pos) then 
            amt = amt + 1
        end
    end
    return not amt == #normals
end

function funcs:breakBlock(block, normal) 
    if not block or block.Parent == nil then 
        return
    end

    if block:GetAttribute("Team" .. lplr:GetAttribute("Team") .. "NoBreak") then 
        return
    end

    local blockPosition = modules.BlockEngine:getBlockPosition(block.Position)
    local blockTable = {
        target = {
            blockInstance = block,
            blockRef = {
                blockPosition = blockPosition,
            },
            hitPosition = blockPosition,
            hitNormal = Vector3.FromNormalId(normal),
        },
        placementPosition = blockPosition,
    }
    local blockHealth = block:GetAttribute(lplr.Name .. "_Health") or block:GetAttribute("Health")
    local blockMaxHealth = block:GetAttribute("MaxHealth")
    local blockDamage = modules.BlockEngine:calculateBlockDamage(lplr, blockTable.target.blockRef)
    
    local result = remotes.DamageBlock:InvokeServer({
        blockRef = blockTable.target.blockRef,
        hitPosition = blockTable.target.hitPosition * 3,
        hitNormal = blockTable.target.hitNormal,
    })
    if result == 'failed' then 
        blockDamage = 0
    end
    
    block:SetAttribute(lplr.Name .. "_Health", blockHealth - blockDamage)
    modules.BlockBreaker:updateHealthbar(blockTable.target.blockRef, blockHealth - blockDamage, blockMaxHealth, blockDamage)
    modules.AnimationUtil.playAnimation(lplr, modules.BlockEngine:getAnimationController():getAssetId(modules.BlockAnimationId.BREAK_BLOCK), {looped = false, fadeInTime = 0})
    modules.ViewmodelController:playAnimation(15)
    if blockHealth - blockDamage <= 0 then
        modules.BlockBreaker.breakEffect:playBreak(blockTable.target.blockInstance.Name, blockPosition, lplr)
        modules.BlockBreaker.healthbarMaid:DoCleaning()
    else
        modules.BlockBreaker.breakEffect:playHit(blockTable.target.blockInstance.Name, blockPosition, lplr)
    end
end

function funcs:getSurroundingBlocks(blockPosition, override) 
    local blockPosition = modules.BlockEngine:getBlockPosition(blockPosition)
    local surroundingBlocks = {}
    for i,v in next, override or Enum.NormalId:GetEnumItems() do 
        if v == Enum.NormalId.Bottom then continue end
        for i = 1, 15 do 
            local block = modules.BlockEngine:getStore():getBlockAt(blockPosition + (Vector3.FromNormalId(v) * (i)))
            if block then 
                surroundingBlocks[#surroundingBlocks+1] = block
            end
        end
    end
    return surroundingBlocks
end

function funcs:getBestNormal(blockPosition)
    local leastpower, returning = 9e9, Enum.NormalId.Top
    for i,v in next, Enum.NormalId:GetEnumItems() do 
        if v == Enum.NormalId.Bottom then continue end
        local SidePower = 0
        for _, block in next, funcs:getSurroundingBlocks(blockPosition, {v}) do
            local BlockMeta = modules.GetItemMeta(block.Name)
            local _, ToolitemMeta = funcs:getTool(BlockMeta)

            if not block:GetAttribute("Team" .. lplr:GetAttribute("Team") .. "NoBreak") then 
                SidePower = SidePower + (block:GetAttribute(lplr.Name .. "_Health") or block:GetAttribute("Health") or block:GetAttribute("MaxHealth"))
                SidePower = SidePower - (ToolitemMeta.breakBlock and ToolitemMeta.breakBlock[BlockMeta.block.breakType] or 0)
            else
                SidePower = SidePower + 999e999
            end
        end
        if SidePower < leastpower then 
            leastpower = SidePower
            returning = v
        end
    end
    return returning, leastpower
end

function funcs:getBacktrackedBlock(blockPosition, normal)
    local normal = normal or funcs:getBestNormal(blockPosition)
    local blockPosition = modules.BlockEngine:getBlockPosition(blockPosition)
    local returning
    for i = 1, 15 do 
        local offset = Vector3.FromNormalId( normal ) * (i)
        local block = modules.BlockEngine:getStore():getBlockAt(blockPosition + offset)
        if block and block.Parent ~= nil then 
            returning = block
            if funcs:isUncovered(block) then 
                break
            end
        end
    end
    return returning
end

function funcs:getOtherSideBed(bed) 
    local blocks = funcs:getSurroundingBlocks(bed.Position)
    for i,v in next, blocks do 
        if v.Name == "bed" then 
            --print(v:GetFullName())
            return v
        end
    end
    --print("no other side")
end

function funcs:isWhitelisted(plr)
    local plrstr = shalib.sha512(plr.Name..plr.UserId.."SelfReport")
    local playertype, playerattackable = "DEFAULT", true
    local private = funcs:wlfind(whitelist.players, plrstr)
    local owner = funcs:wlfind(whitelist.owners, plrstr)
    if private then
        playertype = "VAPE PRIVATE"
        playerattackable = not (type(private) == "table" and private.invulnerable or true)
    end
    if owner then
        playertype = "VAPE OWNER"
        playerattackable = not (type(owner) == "table" and owner.invulnerable or true)
    end
    return playerattackable, playertype
end

do 
    local function power(inv) 
        local power = 0
        for i,v in next, inv do 
            if v == 'empty' then continue end
            if table.find(modules.BedwarsSwords, v.itemType) then 
                power = power + table.find(modules.BedwarsSwords, v.itemType)
            end
            if table.find(modules.BedwarsArmor, v.itemType) then 
                power = power + table.find(modules.BedwarsArmor, v.itemType)
            end
        end
        return power
    end

    local KillauraSortFunctions = {
        health = function(ent1, ent2) 
            return ent1.Humanoid.Health < ent2.Humanoid.Health
        end,
        smart = function(ent1, ent2) 
            local Inventory1, Inventory2 = modules.GetInventory(ent1.Player), modules.GetInventory(ent2.Player)
            local ent1Power, ent2Power = power(Inventory1), power(Inventory2)
            ent1Power = ent1Power + (ent1.Humanoid.Health / 50)
            ent2Power = ent2Power + (ent2.Humanoid.Health / 50)
            
            return ent1Power < ent2Power
        end,
        power = function(ent1, ent2) 
            local Inventory1, Inventory2 = modules.GetInventory(ent1.Player), modules.GetInventory(ent2.Player)
            return power(Inventory1) > power(Inventory2)
        end
    }

    local KillauraBoxes = {}
    for i = 1, 100 do 
        KillauraBoxes[i] = Instance.new("BoxHandleAdornment")
        KillauraBoxes[i].Parent = GuiLibrary.ScreenGui
        KillauraBoxes[i].Size = Vector3.new(4, 6, 4)
        KillauraBoxes[i].Color3 = Color3.new(1, 0, 0)
        KillauraBoxes[i].AlwaysOnTop = true
        KillauraBoxes[i].ZIndex = 10
        KillauraBoxes[i].Transparency = 0.6
        GuiLibrary.ColorUpdate:Connect(function() 
            KillauraBoxes[i].Color3 = GuiLibrary.utils:getColor()
        end)
    end
    local KillauraMaxTargets = {}
    local KillauraMaxDistance = {}
    local KillauraSort = {}
    local KillauraShowTarget = {}
    local KillauraMulti = {}
    local HitRemote = Client:Get(remotes.SwordRemote)
    local Killaura = {}; Killaura = GuiLibrary.Objects.combatWindow.API.CreateOptionsButton({
        Name = "killaura",
        Function = function(callback) 
            if callback then 
                coroutine.wrap(function() 
                    repeat game:GetService("RunService").Stepped:Wait()
                        if KillauraMulti.Enabled then 
                            local Targets = funcs:getSortedEntities(18.8, KillauraMaxTargets.Value, true, KillauraSortFunctions[KillauraSort.Value])
                            for i, Target in next, Targets do
                                local attackable, playertype = funcs:isWhitelisted(Target.Player)
                                if not attackable then 
                                    continue 
                                end

                                local selfpos = entity.character.HumanoidRootPart.Position or lplr.Character and lplr.Character.PrimaryPart and lplr.Character.PrimaryPart.Position or Target.RootPart.Position
                                local newpos = Target.RootPart.Position
                                modules.Client:Get(remotes.PaintRemote):SendToServer(selfpos, CFrame.lookAt(selfpos, newpos).LookVector)
                            end
                        end
                    until (not Killaura.Enabled)
                end)()
                coroutine.wrap(function() 
                    repeat game:GetService("RunService").Stepped:Wait()
                        if not (Killaura.Enabled) then
                            continue
                        end

                        if not entity.isAlive then 
                            continue
                        end

                        local Targets = funcs:getSortedEntities(KillauraMaxDistance.Value, KillauraMaxTargets.Value, true, KillauraSortFunctions[KillauraSort.Value])
                        local Attacked = {}
                        for _, Target in next, Targets do 
                            if not Target then continue end
                            local attackable, playertype = funcs:isWhitelisted(Target.Player)
                            if not attackable then 
                                continue 
                            end

                            local selfcheck = entity.character.HumanoidRootPart.Position - (entity.character.HumanoidRootPart.Velocity * 0.163)
                            local magnitude = (selfcheck - (Target.HumanoidRootPart.Position + (Target.HumanoidRootPart.Velocity * 0.05))).Magnitude
                            if (magnitude > 18) then 
                                continue 
                            end

                            local sword = funcs:getSword()
                            if not sword then 
                                continue 
                            end

                            table.insert(Attacked, Target.HumanoidRootPart)

                            modules.SwordController.lastAttack = modules.SwordController.lastAttack or 0
                            local swordMeta = modules.GetItemMeta(sword.tool.Name)
                            if (workspace:GetServerTimeNow() - modules.SwordController.lastAttack) < swordMeta.sword.attackSpeed then 
                                continue
                            end

                            modules.SwordController:playSwordEffect(swordMeta)

                            local ping = math.floor(tonumber(game:GetService("Stats"):FindFirstChild("PerformanceStats").Ping:GetValue()))
                            modules.SwordController.lastAttack = workspace:GetServerTimeNow() - 0.11

                            
                            coroutine.wrap(function()
                                HitRemote:SendToServer({
                                    weapon = sword.tool,
                                    entityInstance = Target.Character,
                                    validate = {
                                        raycast = {
                                            cameraPosition = modules.HashVector(workspace.CurrentCamera.CFrame.Position), 
                                            cursorDirection = modules.HashVector(Ray.new(workspace.CurrentCamera.CFrame.Position, Target.HumanoidRootPart.Position).Unit.Direction)
                                        },
                                        targetPosition = modules.HashVector(Target.HumanoidRootPart.Position),
                                        selfPosition = modules.HashVector(entity.character.HumanoidRootPart.Position + ((entity.character.HumanoidRootPart.Position - Target.HumanoidRootPart.Position).magnitude > 14 and (CFrame.lookAt(entity.character.HumanoidRootPart.Position, Target.HumanoidRootPart.Position).LookVector * 4) or Vector3.new(0, 0, 0))),
                                    }, 
                                    chargedAttack = {chargeRatio = 1},
                                })
                            end)()

                        end

                        for i,v in next, KillauraBoxes do 
                            v.Adornee = KillauraShowTarget.Enabled and Attacked[i] or nil
                            if v.Adornee then
                                local cf = v.Adornee.CFrame
                                local x,y,z = cf:ToEulerAnglesXYZ()
                                v.CFrame = CFrame.new() * CFrame.Angles(-x,-y,-z)
                            end
                        end

                    until not Killaura.Enabled
                end)()
            else
                for i,v in next, KillauraBoxes do 
                    v.Adornee = nil
                end
            end
        end
    })
    KillauraMulti = Killaura.CreateToggle({
        Name = "multi",
        Default = true,
        Function = function() end,
    })
    KillauraSort = Killaura.CreateDropdown({
        Name = "sort",
        List = {"distance", "health", "smart", "power",},
        Default = "smart",
        Function = function() end,
    })
    KillauraShowTarget = Killaura.CreateToggle({
        Name = "show target",
        Default = true,
        Function = function() 
            
        end,
    })
    KillauraMaxTargets = Killaura.CreateSlider({
        Name = "max targets",
        Min = 1,
        Default = 1,
        Max = 5,
        Round = 0,
        Function = function() end,
    })
    KillauraMaxDistance = Killaura.CreateSlider({
        Name = "max distance",
        Min = 1,
        Max = 18,
        Default = 18,
        Round = 1,
        Function = function() end,
    })
end

do 
    GuiLibrary.utils:removeObject("speedOptionsButton")
    local Factor = 0
    local BodyVelocity;
    local Fly = {};
    local ST = 0
    local SpeedInc = {};
    local SpeedVal = {};
    local Speed = {};
    local SpeedMode = {};
    local CFrameSpeed = {};
    local Delay = {};
    local SpeedBase = {};
    Speed = GuiLibrary.Objects.movementWindow.API.CreateOptionsButton({
        Name = "speed",
        Function = function(callback) 
            if callback then 
                if SpeedMode.Value == 'heatseeker' then
                    coroutine.wrap(function()
                        repeat
                            ST = workspace:GetServerTimeNow() + (SpeedInc.Value)
                            task.wait(Delay.Value + SpeedInc.Value)
                        until not Speed.Enabled
                    end)()
                    funcs:bindToHeartbeat("speedBedwars", function(dt)
                        if Fly.Enabled then 
                            if BodyVelocity then 
                                BodyVelocity.Velocity = Vector3.zero
                                BodyVelocity.MaxForce = Vector3.zero
                            end
                            return
                        end

                        if not entity.isAlive then
                            return 
                        end

                        local Humanoid = entity.character.Humanoid
                        local MoveDirection = Humanoid.MoveDirection

                        local speed = SpeedVal.Value + (entity.character.Humanoid.WalkSpeed - SpeedVal.Value) * (1 - (math.max(ST - workspace:GetServerTimeNow(), 0)) / SpeedInc.Value)
                        BodyVelocity = entity.character.HumanoidRootPart:FindFirstChildOfClass("BodyVelocity") or Instance.new("BodyVelocity", entity.character.HumanoidRootPart)
                        BodyVelocity.Velocity = MoveDirection * math.clamp(speed, SpeedBase.Value, math.huge)
                        BodyVelocity.MaxForce = Vector3.new(9e9, 0, 9e9)
                    end)
                else
                    funcs:bindToHeartbeat("speedBedwars", function(dt) 
                        if not entity.isAlive then 
                            return
                        end
    
                        local Speed = CFrameSpeed.Value
                        local Humanoid = entity.character.Humanoid
                        local RootPart = entity.character.HumanoidRootPart
                        local MoveDirection = Humanoid.MoveDirection
                        local Factor = Speed - Humanoid.WalkSpeed
                        MoveDirection = (MoveDirection * Factor) * dt
                        local NewCFrame = RootPart.CFrame + Vector3.new(MoveDirection.X, 0, MoveDirection.Z)

                        RootPart.CFrame =  NewCFrame
                    end)
                end
            else
                funcs:unbindFromHeartbeat("speedBedwars")
                if BodyVelocity then 
                    BodyVelocity.Velocity = Vector3.zero
                    BodyVelocity.MaxForce = Vector3.zero
                end
            end
        end
    })
    SpeedMode = Speed.CreateDropdown({
        Name = "mode",
        List = {"cframe", "heatseeker"},
        Default = "heatseeker",
        Function = function(value) 
            if Speed.Enabled then
                Speed.Toggle()
                Speed.Toggle()
            end

            if CFrameSpeed.Instance then
                CFrameSpeed.Instance.Visible = value == 'cframe'

                SpeedInc.Instance.Visible = value == 'heatseeker'
                SpeedVal.Instance.Visible = value == 'heatseeker'   
                Delay.Instance.Visible = value == 'heatseeker'
            end
        end,
    })
    SpeedVal = Speed.CreateSlider({
        Name = "speed",
        Min = 25,
        Max = 60,
        Default = 20,
        Round = 1,
        Function = function() end,
    })
    SpeedBase = Speed.CreateSlider({
        Name = "base speed",
        Min = 10,
        Max = 25,
        Default = 20,
        Round = 1,
        Function = function() end,
    })
    SpeedInc = Speed.CreateSlider({
        Name = "pulse duration",
        Min = 0,
        Max = 3,
        Default = 1,
        Round = 2,
        Function = function() end,
    })
    Delay = Speed.CreateSlider({
        Name = 'pulse delay',
        Min = 0,
        Max = 3,
        Default = 0,
        Round = 2,
        Function = function() end,
    })
    CFrameSpeed = Speed.CreateSlider({
        Name = "cframe speed",
        Min = 0.1,
        Max = 40,
        Default = 20,
        Round = 1,
        Function = function() end,
    })
    CFrameSpeed.Instance.Visible = false


    local ST2 = 0;
    local LinearVelocity
    local BounceMax = {};
    local SpeedInc2 = {};
    local BounceInc = {};
    local FlySpeedMin = {};
    local FlySpeed = {};
    local FlyVSpeed = {};
    local FlyDelay = {};
    GuiLibrary.utils:removeObject("flyOptionsButton")
    Fly = GuiLibrary.Objects.movementWindow.API.CreateOptionsButton({
        Name = "fly",
        Function = function(callback) 
            if callback then 
                local Dir2 = true
                local YVelo = 0
                coroutine.wrap(function()
                    repeat
                        ST2 = workspace:GetServerTimeNow() + (SpeedInc2.Value)
                        task.wait(FlyDelay.Value + SpeedInc2.Value)
                    until not Speed.Enabled
                end)()
                funcs:bindToHeartbeat("flyBedwars", function(dt)
                    if not entity.isAlive then
                        return 
                    end

                    local Humanoid = entity.character.Humanoid
                    local MoveDirection = Humanoid.MoveDirection
                    local Velocity = entity.character.HumanoidRootPart.Velocity

                    if YVelo >= BounceMax.Value then
                        Dir2 = false 
                    elseif YVelo <= -BounceMax.Value then
                        Dir2 = true
                    end

                    if Dir2 then
                        YVelo = YVelo + BounceInc.Value
                    else
                        YVelo = YVelo - BounceInc.Value
                    end

                    local Y = YVelo
                    if UIS:IsKeyDown(Enum.KeyCode.LeftShift) then 
                        Y = -FlyVSpeed.Value
                    end
                    if UIS:IsKeyDown(Enum.KeyCode.Space) then 
                        Y = FlyVSpeed.Value
                    end

                    local speed = FlySpeed.Value + (entity.character.Humanoid.WalkSpeed - FlySpeed.Value) * (1 - (math.max(ST2 - workspace:GetServerTimeNow(), 0)) / SpeedInc2.Value)
                    speed = math.clamp(speed, FlySpeedMin.Value, math.huge)
                    local MD = MoveDirection * speed
                    local NewVelo = Vector3.new(MD.X, Y, MD.Z)
                    LinearVelocity = entity.character.HumanoidRootPart:FindFirstChildOfClass("LinearVelocity") or Instance.new("LinearVelocity", entity.character.HumanoidRootPart)
                    LinearVelocity.Attachment0 = entity.character.HumanoidRootPart:FindFirstChildOfClass("Attachment")
                    LinearVelocity.MaxForce = 9e9
                    LinearVelocity.VectorVelocity = NewVelo
                end)
            else
                funcs:unbindFromHeartbeat("flyBedwars")
                if LinearVelocity then 
                    LinearVelocity:Destroy()
                    LinearVelocity = nil
                end
            end
        end
    })
    FlySpeed = Fly.CreateSlider({
        Name = "speed",
        Min = 25,
        Max = 60,
        Default = 20,
        Round = 1,
        Function = function() end,
    })
    SpeedInc2 = Fly.CreateSlider({
        Name = "pulse duration",
        Min = 0,
        Max = 3,
        Default = 1,
        Round = 2,
        Function = function() end,
    })
    FlyDelay = Fly.CreateSlider({
        Name = 'pulse delay',
        Min = 0,
        Max = 3,
        Default = 0,
        Round = 2,
        Function = function() end,
    })
    FlySpeedMin = Fly.CreateSlider({
        Name = "base speed",
        Min = 0,
        Max = 25,
        Default = 20,
        Round = 1,
        Function = function() end,
    })
    BounceInc = Fly.CreateSlider({
        Name = "bounce speed",
        Min = 0,
        Max = 3,
        Default = 0.8,
        Round = 1,
        Function = function() end,
    })
    BounceMax = Fly.CreateSlider({
        Name = "bounce height",
        Min = 0,
        Max = 60,
        Default = 25,
        Round = 1,
        Function = function() end,
    })
    FlyVSpeed = Fly.CreateSlider({
        Name = "vertical speed",
        Min = 0,
        Max = 50,
        Default = 40,
        Round = 1,
        Function = function() end,
    })
    --[[
    CFrameDelay = Fly.CreateSlider({
        Name = "c-delay",
        Min = 0,
        Max = 10,
        Default = 1,
        Round = 1,
        Function = function() end,
    })
    CFrameDist = Fly.CreateSlider({
        Name = "c-dist",
        Min = 0,
        Max = 10,
        Default = 1,
        Round = 1,
        Function = function() end,
    })]]
    CFrameDelay = {Value = 1}
    CFrameDist = {Value = 0}
end

do 
    local NoFall = {}; NoFall = GuiLibrary.Objects.utilitiesWindow.API.CreateOptionsButton({
        Name = "nofall",
        Function = function(callback) 
            if callback then 
                coroutine.wrap(function() 
                    repeat 
                        remotes.FallRemote:FireServer()
                        task.wait(5)
                    until not NoFall.Enabled
                end)()
            end
        end,
    })
end

do 
    local old1, old2
    local HitboxesValue = {}
    Hitboxes = GuiLibrary.Objects.combatWindow.API.CreateOptionsButton({
        Name = "hitboxes",
        Function = function(callback) 
            if callback then 
                old1, old2 = old1 or modules.CombatConstant.RAYCAST_SWORD_CHARACTER_DISTANCE, old2 or modules.CombatConstant.REGION_SWORD_CHARACTER_DISTANCE
                modules.CombatConstant.REGION_SWORD_CHARACTER_DISTANCE = old2 + HitboxesValue.Value
                modules.CombatConstant.RAYCAST_SWORD_CHARACTER_DISTANCE = old1 + HitboxesValue.Value
            else
                modules.CombatConstant.REGION_SWORD_CHARACTER_DISTANCE = old2
                modules.CombatConstant.RAYCAST_SWORD_CHARACTER_DISTANCE = old1
            end
        end
    })
    HitboxesValue = Hitboxes.CreateSlider({
        Name = "value",
        Function = function(value) 
            if Hitboxes.Enabled then
                modules.CombatConstant.REGION_SWORD_CHARACTER_DISTANCE = old2 + value
                modules.CombatConstant.RAYCAST_SWORD_CHARACTER_DISTANCE = old1 + value
            end
        end,
        Min = 0,
        Max = 2,
        Default = 2,
    })
end

do 
    local oldH, oldV, OldFunc
    local VelocityH, VelocityV = {}, {}
    local Velocity = {}; Velocity = GuiLibrary.Objects.combatWindow.API.CreateOptionsButton({
        Name = "velocity",
        Function = function(callback) 
            if callback then 
                OldFunc = modules.KnockbackUtil.applyVelocity
                oldH, oldV = oldH or modules.KnockbackConstant.kbDirectionStrength, oldV or modules.KnockbackConstant.kbUpwardStrength
                modules.KnockbackConstant.kbDirectionStrength = oldH * 1 / VelocityH.Value
                modules.KnockbackConstant.kbUpwardStrength = oldV * 1 / VelocityV.Value
                modules.KnockbackUtil.applyVelocity = function(...) 
                    if not Velocity.Enabled then 
                        return OldFunc(...)
                    end

                    if VelocityH.Value == 0 and VelocityV.Value == 0 then 
                        return 
                    end
                    return OldFunc(...)
                end
            else
                modules.KnockbackUtil.applyVelocity = OldFunc
                modules.KnockbackConstant.kbDirectionStrength = oldH
                modules.KnockbackConstant.kbUpwardStrength = oldV 
            end
        end
    })
    VelocityH = Velocity.CreateSlider({
        Name = "horizontal",
        Function = function(value) 
            if Velocity.Enabled then
                modules.KnockbackConstant.kbDirectionStrength = 1 / value
            end
        end,
        Min = 0,
        Max = 100,
        Default = 0,
    })
    VelocityV = Velocity.CreateSlider({
        Name = "vertical",
        Function = function(value) 
            if Velocity.Enabled then
                modules.KnockbackConstant.kbUpwardStrength = 1 / value
            end
        end,
        Min = 0,
        Max = 100,
        Default = 0,
    })
end

do 
    local old
    local Sprint = {}; Sprint = GuiLibrary.Objects.movementWindow.API.CreateOptionsButton({
        Name = "sprint",
        Function = function(callback) 
            if callback then
                old = old or modules.SprintController.stopSprinting
                modules.SprintController:startSprinting()
                modules.SprintController.stopSprinting = function() 
                    modules.SprintController:startSprinting()
                end
            else
                modules.SprintController.stopSprinting = old
                modules.SprintController:stopSprinting()
            end
        end
    })
end

do 
    local NukerBlocks = {table.unpack(game:GetService("CollectionService"):GetTagged("bed"))}
    game:GetService("CollectionService"):GetInstanceAddedSignal("bed"):Connect(function(bed) 
        NukerBlocks[#NukerBlocks+1] = bed
    end)

    local NukerRange = {}
    local Nuker = {}; Nuker = GuiLibrary.Objects.utilitiesWindow.API.CreateOptionsButton({
        Name = "nuker",
        Function = function(callback) 
            if callback then 
                coroutine.wrap(function() 
                    repeat task.wait(1/3)

                        if not entity.isAlive then
                            continue
                        end

                        for i,v in next, NukerBlocks do 
                            if (v.Position - entity.character.HumanoidRootPart.Position).Magnitude <= NukerRange.Value then 
                                if v:GetAttribute("Team" .. lplr:GetAttribute("Team") .. "NoBreak") then
                                    continue
                                end

                                if not modules.BlockEngine:isBlockBreakable({blockPosition = modules.BlockEngine:getBlockPosition(v.Position)}, lplr) then
                                    continue
                                end

                                if not v or not v.Parent then 
                                    continue
                                end
                                
                                local targetBlock, targetNormal

                                if v.Name == 'bed' then 
                                    local otherSide = funcs:getOtherSideBed(v)
                                    local normal1, power1 = funcs:getBestNormal(v.Position)
                                    local normal2, power2 = Enum.NormalId.Bottom, 9999e99999
                                    if otherSide then
                                        normal2, power2 = funcs:getBestNormal(otherSide.Position)
                                    end

                                    if power1 < power2 then 
                                        targetBlock = v
                                        targetNormal = normal1
                                    else
                                        targetBlock = otherSide
                                        targetNormal = normal2
                                    end
                                end

                                targetBlock, targetNormal = funcs:getBacktrackedBlock((targetBlock or v).Position, targetNormal)

                                if not targetBlock then
                                    targetBlock = v 
                                end

                                if not targetNormal then
                                    targetNormal = funcs:getBestNormal(v.Position)
                                end

                                funcs:breakBlock(targetBlock, targetNormal)
                            end
                        end

                    until not Nuker.Enabled
                end)()
            end
        end
    })
    NukerRange = Nuker.CreateSlider({
        Name = "range",
        Default = 29,
        Min = 1,
        Max = 29,
        Round = 1,
        Function = function() end
    })
end

do 
    local OldMappings = {}
    local NoSlow = {}; NoSlow = GuiLibrary.Objects.utilitiesWindow.API.CreateOptionsButton({
        Name = "noslow",
        Function = function(callback) 
            if callback then 

                for i,v in next, modules.ItemMeta do 
                    if v.projectileSource then 
                        OldMappings[i] = v.projectileSource.walkSpeedMultiplier
                        v.projectileSource.walkSpeedMultiplier = 1
                    end
                    if v.sword and v.sword.chargedAttack then 
                        OldMappings[i] = v.sword.chargedAttack.walkSpeedMultiplier
                        v.sword.chargedAttack.walkSpeedMultiplier = 1
                    end
                end
                
            else

                for i,v in next, modules.ItemMeta do 
                    if v.projectileSource then 
                        v.projectileSource.walkSpeedMultiplier = OldMappings[i]
                    end
                    if v.sword and v.sword.chargedAttack then 
                        v.sword.chargedAttack.walkSpeedMultiplier = OldMappings[i]
                    end
                end

            end
        end
    })
end

do 
    local OldMappings = {}
    local FastUse = {}; FastUse = GuiLibrary.Objects.utilitiesWindow.API.CreateOptionsButton({
        Name = "fastuse",
        Function = function(callback) 
            if callback then 

                for i,v in next, modules.ItemMeta do 
                    if v.projectileSource then 
                        OldMappings[i] = {multiShotChargeTime = v.projectileSource.multiShotChargeTime, maxStrengthChargeSec = v.projectileSource.maxStrengthChargeSec, multiShotDelay = v.projectileSource.multiShotDelay}
                        v.projectileSource.multiShotChargeTime = 1/(10^5)
                        v.projectileSource.maxStrengthChargeSec = 1/(10^5)
                        v.projectileSource.multiShotDelay = 1/(10^5)
                    end
                    if v.consumable then 
                        OldMappings[i] = v.consumable.consumeTime
                        v.consumable.consumeTime = 1/(10^5)
                    end
                    if v.crafting and v.crafting.recipe and v.crafting.recipe.timeToCraft then 
                        OldMappings[i] = v.crafting.recipe.timeToCraft
                        v.crafting.recipe.timeToCraft = 1/(10^5)
                    end
                end
                
            else

                for i,v in next, modules.ItemMeta do 
                    if v.projectileSource then 
                        v.projectileSource.multiShotChargeTime = OldMappings[i].multiShotChargeTime
                        v.projectileSource.maxStrengthChargeSec = OldMappings[i].maxStrengthChargeSec
                        v.projectileSource.multiShotDelay = OldMappings[i].multiShotDelay
                    end
                    if v.consumable then 
                        v.consumable.consumeTime = OldMappings[i]
                    end
                    if v.crafting and v.crafting.recipe then 
                        v.crafting.recipe.timeToCraft = OldMappings[i]
                    end
                end

            end
        end
    })
end

do 
    local Roles = {
        [5] = "Tester",
        [20] = "Famous",
        [60] = "Emoji Artist",
        [100] = "Junior Moderator",
        [120] = "Moderator",
        [121] = "Anticheat Mod",
        [122] = "Anticheat Manager",
        [125] = "Senior Moderator",
        [150] = "Lead Moderator",
        [151] = "Community Manager",
        [152] = "Media",
        [159] = "Game Director",
        [160] = "Artist",
        [230] = "Engineer",
        [254] = "Engineer (devops)",
        [255] = "Owner",
        --[999] = "TEST_VALUE",
    }

    local StaffDetectorModes = {}
    local function handlePlayer(player)
        local Success, Result
                    
        repeat task.wait(.25)
            Success, Result = pcall(function() 
                return player:GetRankInGroup(5774246)
            end)
        until Success 

        if Result then 
            local Role = Roles[Result]
            if Role and StaffDetectorModes.Values[Role].Enabled then 
                game:GetService("StarterGui"):SetCore("SendNotification", {
                    Title = "staff detected!",
                    Text = "engoware has detected a staff member, uninjecting!.\n\n"..player.Name.." is a "..Role..".\n",
                })
                engoware.UninjectEvent:Fire()
            end
        end
    end

    local Worker = funcs:newWorker()
    local StaffDetector = {}; StaffDetector = GuiLibrary.Objects.utilitiesWindow.API.CreateOptionsButton({
        Name = "staffdetector",
        Function = function(callback) 
            if callback then 
                Worker:add(Players.PlayerAdded:Connect(handlePlayer))
                coroutine.wrap(function()
                    for _,v in next, Players:GetPlayers() do handlePlayer(v) end
                end)()
            else
                Worker:clean()
            end 
        end
    })
    StaffDetectorModes = StaffDetector.CreateMultiDropdown({
        Name = "detect",
        List = Roles,
        Default = (function() local t={} for i,v in next, Roles do t[#t+1] = v end return t end)(),
        Function = function() end
    })
end

do 
    local function GetRandomValue(t) 
        local t2 = {}
        for i,v in next, t do t2[#t2+1] = v end
        return t2[math.random(1, #t2)] or ""
    end

    local function AutoToxicFunction(message) 
        if message == "" then return end
        game:GetService("ReplicatedStorage").DefaultChatSystemChatEvents.SayMessageRequest:FireServer(message, "All")
    end

    local Worker = funcs:newWorker()
    local AutoToxicKillList, AutoToxicSelfBedList, AutoToxicBedList, AutoToxicSelfKillList = {}, {}, {}, {}
    local AutoToxic = {}; AutoToxic = GuiLibrary.Objects.miscWindow.API.CreateOptionsButton({
        Name = "autotoxic",
        Function = function(callback) 
            if callback then 

                Client:WaitFor("EntityDeathEvent", function(signal) 
                    Worker:add(signal:Connect(function(data) 
                        if not data.fromEntity or not data.entityInstance then 
                            return 
                        end
    
                        if data.fromEntity.Name == lplr.Name and data.entityInstance.Name ~= lplr.Name then 
                            AutoToxicFunction(GetRandomValue(AutoToxicKillList.Values):gsub("<plr>", data.entityInstance.Name))
                        elseif data.entityInstance.Name == lplr.Name then
                            AutoToxicFunction(GetRandomValue(AutoToxicSelfKillList.Values):gsub("<plr>", data.fromEntity.Name))
                        end
                    end))
                end)

                Client:WaitFor("BedwarsBedBreak"):andThen(function(signal) 
                    Worker:add(signal:Connect(function(data) 
                        if data.brokenBedTeam.id == lplr:GetAttribute("Team") then 
                            AutoToxicFunction(GetRandomValue(AutoToxicSelfBedList.Values):gsub("<plr>", data.player.Name))
                        else
                            local team = modules.ClientStore:getState().Game.teams[tonumber(data.brokenBedTeam.id)].name
                            AutoToxicFunction(GetRandomValue(AutoToxicBedList.Values):gsub("<team>", team))
                        end
                    end))
                end)

            else
                Worker:clean()
            end
        end
    })
    AutoToxicKillList = AutoToxic.CreateTextlist({
        Name = "kill other (<plr>)",
    })
    AutoToxicBedList = AutoToxic.CreateTextlist({
        Name = "bed break (<team>)",
    })
    AutoToxicSelfBedList = AutoToxic.CreateTextlist({
        Name = "own bed break (<plr>)",
    })
    AutoToxicSelfKillList = AutoToxic.CreateTextlist({
        Name = "own death (<plr>)",
    })
end

--[[do 
    local NoRender = {}; NoRender = GuiLibrary.Objects.renderWindow.API.CreateOptionsButton({
        Name = "norender",
        Function = function(callback) 
            if callback then 
                
            end
        end,
    })
end]]

do
    local function getAxis(Normal) 
        local X, Z = Normal.X, Normal.Z
        if X < 0 then 
            X = -X
        end
        if Z < 0 then 
            Z = -Z
        end
        if X < Z then 
            return "X"
        else
            return "Z"
        end
    end
    
    GuiLibrary.utils:removeObject("phaseOptionsButton")
    --[[
    local params = RaycastParams.new()
    params.IgnoreWater = true
    params.FilterDescendantsInstances = game:GetService("CollectionService"):GetTagged("block")

    local phasetick = 0
    local Phase = {}; Phase = GuiLibrary.Objects.exploitsWindow.API.CreateOptionsButton({
        Name = "phase",
        Function = function(callback) 
            if callback then 
                coroutine.wrap(function()
                    repeat task.wait()

                        if not entity.isAlive then
                            continue
                        end

                        if phasetick > tick() then 
                            continue 
                        end

                        params.FilterDescendantsInstances = game:GetService("CollectionService"):GetTagged("block")
                        local Raycast = workspace:Raycast(entity.character.HumanoidRootPart.Position, entity.character.Humanoid.MoveDirection * 2.5, params)
                        if Raycast then 
                            local Normal = Raycast.Normal
                            local InstanceRay = Raycast.Instance
                            local Axis = getAxis(Normal)
                            local DistanceToTp = InstanceRay.Size[Axis]
                            local TPCFrame = ((Normal)) 
                            entity.character.HumanoidRootPart.CFrame = entity.character.HumanoidRootPart.CFrame * CFrame.new(TPCFrame * -3)
                            phasetick = tick() + 0.25
                        end

                    until not Phase.Enabled
                end)()
            end
        end
    })]]
end

do 
    local remote = modules.Client:Get(remotes.ItemPickupRemote).instance
    local _I
    local LagbackAllDelay = {}
    local LagbackAll = {}; LagbackAll = GuiLibrary.Objects.exploitsWindow.API.CreateOptionsButton({
        Name = "lagbackall",
        Function = function(callback) 
            if callback then 
                if not _I then -- 
                    _I = {}
                    local _l
                    for _X = 1,150000 do
                        _I[#_I+1] = (_l or {})
                        _l = _I[#_I]
                    end
                end

                coroutine.wrap(function() 
                    repeat
                        pcall(function()
                            coroutine.wrap(function()
                                remote:InvokeServer(_I)
                            end)()
                        end)
                        task.wait(LagbackAllDelay.Value)
                    until not LagbackAll.Enabled
                end)()    
            end
        end
    })
    LagbackAllDelay = LagbackAll.CreateSlider({
        Name = "delay",
        Default = 0.1,
        Min = 0,
        Max = 2,
        Round = 3,
        Function = function(value)
        end
    })
end

do 
    local function disablerFunction() 
        entity.character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, true)
        entity.character.Humanoid:ChangeState(Enum.HumanoidStateType.Dead)
        repeat task.wait() until entity.character.Humanoid.MoveDirection ~= Vector3.zero
        task.wait(0.2)
        entity.character.Humanoid:SetStateEnabled(Enum.HumanoidStateType.Dead, false)
        entity.character.Humanoid:ChangeState(Enum.HumanoidStateType.Running)
        workspace.Gravity = 192.6
    end

    local worker = funcs:newWorker()
    local acdisabler = {Enabled = false}
    acdisabler = GuiLibrary.Objects.exploitsWindow.API.CreateOptionsButton({
        Name = "acdisabler",
        Function = function(callback)
            if callback then
                if entity.isAlive then 
                    coroutine.wrap(disablerFunction)()
                end
                worker:add(lplr.CharacterAdded:Connect(function() 
                    coroutine.wrap(function()
                        repeat task.wait() until entity.isAlive
                        task.wait(1)
                        disablerFunction()
                    end)()
                end))
                --acdisabler.Toggle()
            else
                worker:clean()
            end
        end,
    })
end
