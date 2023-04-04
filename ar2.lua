local request = (syn and syn.request) or request or http_request or (http and http.request)
local queueteleport = syn and syn.queue_on_teleport or queue_on_teleport or fluxus and fluxus.queue_on_teleport
local setthreadidentityfunc = syn and syn.set_thread_identity or set_thread_identity or setidentity or setthreadidentity
local getthreadidentityfunc = syn and syn.get_thread_identity or get_thread_identity or getidentity or getthreadidentity
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")
local lplr = Players.LocalPlayer
local entity, GuiLibrary, funcs = engoware.entity, engoware.GuiLibrary, engoware.funcs
local mouse = lplr:GetMouse()

getrenv().PluginManager = function() return {CreatePlugin = function() return {Deactivate = function() end} end} end 

local modules = {
    InteractInterface = require(game:GetService("ReplicatedStorage").Client.Abstracts.Interface.Interact),
    Bullets = require(game:GetService("ReplicatedStorage").Client.Libraries.Bullets),
    Framework = require(game:GetService("ReplicatedFirst").Framework),
    Character = require(game:GetService("ReplicatedStorage").Client.Abstracts.Cameras.Character),
    Cameras = require(game:GetService("ReplicatedStorage").Client.Libraries.Cameras),
    Raycasting = require(game:GetService("ReplicatedStorage").Client.Libraries.Raycasting),
    Creator = require(game:GetService("ReplicatedStorage").Client.Abstracts.Interface.MainMenuClasses.TabClasses.Creator),
    CreatorData = require(game:GetService("ReplicatedStorage").Client.Configs.CreatorData),
    Firearm = require(game:GetService("ReplicatedStorage").Client.Abstracts.ItemInitializers.Firearm),
}

engoware.modules = modules

if not modules.Framework:IsLoaded() then 
    modules.Framework:WaitForLoaded()
end

function funcs:tpBypass(cframe, d)
    if not entity.isAlive then 
        return
    end

    if GuiLibrary.Objects.acdisablerOptionsButton == nil or GuiLibrary.Objects.acdisablerOptionsButton.Enabled == false then
        game:GetService("StarterGui"):SetCore("SendNotification", {Title = "TPBypass", Text = "Teleport started...", Duration = 2})
        entity.character.HumanoidRootPart.Anchored = true
        funcs:bindToHeartbeat("TPBYPASS", function() 
            sethiddenproperty(entity.character.HumanoidRootPart, "NetworkIsSleeping", true)
        end)
        task.wait(.2)
        entity.character.HumanoidRootPart.CFrame = cframe
        game:GetService("StarterGui"):SetCore("SendNotification", {Title = "TPBypass", Text = "Waiting to prevent lagback...", Duration = 6})
        task.wait(d)
        entity.character.HumanoidRootPart.Anchored = false
        funcs:unbindFromHeartbeat("TPBYPASS")
        task.wait(.2)
        local Distance = (entity.character.HumanoidRootPart.CFrame.p - cframe.p).Magnitude
        if Distance > 10 then 
            game:GetService("StarterGui"):SetCore("SendNotification", {Title = "TPBypass", Text = "Teleport failed!", Duration = 2})
        else
            game:GetService("StarterGui"):SetCore("SendNotification", {Title = "TPBypass", Text = "Teleport success!", Duration = 2})
        end

        return not (Distance > 10)
    end

    entity.character.HumanoidRootPart.CFrame = cframe
    return true;
end

function funcs:getAccessories() 
    local t = {}
    for i,v in next, entity.entityList do 
        for i2, v2 in next, v.Character:GetChildren() do 
            if v2:IsA("Accessory") then 
                table.insert(t, v2)
            end
        end
    end
    return t
end

GuiLibrary.utils:removeObject("speedOptionsButton")
GuiLibrary.utils:removeObject("flyOptionsButton")

--[[
local ConnectionsHealth = {}
for i,ent in next, entity.entityList do 
    coroutine.wrap(function() 
        if ConnectionsHealth[ent.Player.Name] then 
            ConnectionsHealth[ent.Player.Name]:Disconnect()
        end
    
        local stats = ent.Character:WaitForChild("Stats", 10)
        ConnectionsHealth[ent.Player.Name] = stats.Health.Base.Changed:Connect(function(health)
            ent.Humanoid.Health = health
        end)
        ent.Humanoid.Health = stats.Health.Base.Value
    end)()
end

entity.entityAddedEvent:Connect(function(ent) 
    if ConnectionsHealth[ent.Player.Name] then 
        ConnectionsHealth[ent.Player.Name]:Disconnect()
    end

    local stats = ent.Character:WaitForChild("Stats", 10)
    ConnectionsHealth[ent.Player.Name] = stats.Health.Base.Changed:Connect(function(health)
        ent.Humanoid.Health = health
    end)
    ent.Humanoid.Health = stats.Health.Base.Value
end)

engoware.UninjectEvent.Event:Connect(function()
    for i,v in next, ConnectionsHealth do 
        v:Disconnect()
    end
end)    
]]

do 
    local Fly = {}
    local AddSpeed = 0
    local LinearVelocity, BodyVelocity
    local SpeedValue, SpeedOptions, SpeedMode = {}, {}, {}
    local Speed = {}; Speed = GuiLibrary.Objects.movementWindow.API.CreateOptionsButton({
        Name = "speed",
        Function = function(callback) 
            if callback then

                funcs:bindToHeartbeat("SpeedBackgroundTasks", function(dt) 
                    if not entity.isAlive then 
                        return
                    end

                    if Fly.Enabled then 
                        return 
                    end

                    if SpeedOptions.Values.bhop.Enabled then 
                        local State = entity.character.Humanoid:GetState()
                        local MoveDirection = entity.character.Humanoid.MoveDirection
                        if State == Enum.HumanoidStateType.Running and MoveDirection ~= Vector3.zero then 
                            entity.character.Humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
                        end
                    end

                    if SpeedOptions.Values.pulse.Enabled then 
                        if AddSpeed > (SpeedValue.Value * 1.5) then
                            AddSpeed = -(SpeedValue.Value * 1.5)
                        else
                            AddSpeed = AddSpeed + 1
                        end
                    end
                end)

                funcs:bindToHeartbeat("Speed", function(dt) 
                    if not entity.isAlive then 
                        return
                    end

                    if Fly.Enabled then 
                        return 
                    end

                    local Speed = SpeedValue.Value + AddSpeed
                    local Humanoid = entity.character.Humanoid
                    local RootPart = entity.character.HumanoidRootPart
                    local MoveDirection = Humanoid.MoveDirection
                    local Velocity = RootPart.Velocity
                    local X, Z = MoveDirection.X * Speed, MoveDirection.Z * Speed

                    if SpeedMode.Value == 'velocity' then 
                        RootPart.Velocity = Vector3.new(X, Velocity.Y, Z)
                    elseif SpeedMode.Value == 'cframe' then
                        local Factor = Speed - Humanoid.WalkSpeed
                        local MoveDirection = (MoveDirection * Factor) * dt
                        local NewCFrame = RootPart.CFrame + Vector3.new(MoveDirection.X, 0, MoveDirection.Z)

                        RootPart.CFrame =  NewCFrame
                    elseif SpeedMode.Value == 'linearvelocity' then
                        LinearVelocity = entity.character.HumanoidRootPart:FindFirstChildOfClass("LinearVelocity") or Instance.new("LinearVelocity", entity.character.HumanoidRootPart)
                        LinearVelocity.VelocityConstraintMode = Enum.VelocityConstraintMode.Line
                        LinearVelocity.Attachment0 = entity.character.HumanoidRootPart:FindFirstChildOfClass("Attachment")
                        LinearVelocity.MaxForce = 9e9
                        LinearVelocity.LineDirection = MoveDirection
                        LinearVelocity.LineVelocity = (MoveDirection.X ~= 0 and MoveDirection.Z) and Speed or 0
                    elseif SpeedMode.Value == 'assemblylinearvelocity' then
                        RootPart.AssemblyLinearVelocity = Vector3.new(X, Velocity.Y, Z)
                    elseif SpeedMode.Value == 'bodyvelocity' then
                        BodyVelocity = entity.character.HumanoidRootPart:FindFirstChildOfClass("BodyVelocity") or Instance.new("BodyVelocity", entity.character.HumanoidRootPart)
                        BodyVelocity.Velocity = Vector3.new(X, 0, Z)
                        BodyVelocity.MaxForce = Vector3.new(9e9, 0, 9e9)
                    end
                end)

            else
                AddSpeed = 0
                funcs:unbindFromHeartbeat("SpeedBackgroundTasks")
                funcs:unbindFromHeartbeat("Speed")
                if LinearVelocity then 
                    LinearVelocity:Destroy()
                    LinearVelocity = nil
                end
                if BodyVelocity then 
                    BodyVelocity:Destroy()
                    BodyVelocity = nil
                end
            end
        end
    })
    SpeedMode = Speed.CreateDropdown({
        Name = "mode",
        List = {"cframe", "velocity", "linearvelocity", "assemblylinearvelocity", "bodyvelocity"},
        Default = "cframe",
        Function = function(value) 
            if Speed.Enabled then 
                Speed.Toggle()
                Speed.Toggle()
            end
        end
    })
    SpeedOptions = Speed.CreateMultiDropdown({
        Name = "options",
        List = {"bhop", "pulse"},
        --Default = {""},
        Function = function(value) 
            if Speed.Enabled then 
                Speed.Toggle()
                Speed.Toggle()
            end
        end
    })
    SpeedValue = Speed.CreateSlider({
        Name = "value",
        Min = 0,
        Max = 30,
        Default = 30,
        Round = 1,
        Function = function(value) 
            if Speed.Enabled then 
                Speed.Toggle()
                Speed.Toggle()
            end
        end
    })

    local Floor
    local FlyFloor = {}
    local FlyMode = {}
    local FlyValue = {}
    local FlyVertical = {}
    local FlyVerticalValue = {}
    local LinearVelocity, AlignPosition
    Fly = GuiLibrary.Objects.movementWindow.API.CreateOptionsButton({
        Name = "fly",
        Function = function(callback) 
            if callback then 
                funcs:bindToHeartbeat("Fly", function(dt) 
                    if not entity.isAlive then 
                        return
                    end

                    local Speed = FlyValue.Value
                    local Humanoid = entity.character.Humanoid
                    if not Humanoid then 
                        return
                    end

                    local RootPart = entity.character.HumanoidRootPart
                    local MoveDirection = Humanoid.MoveDirection
                    local Velocity = RootPart.Velocity
                    local X, Z = MoveDirection.X * Speed, MoveDirection.Z * Speed
                    local FlyVDirection = 0
                    if FlyVertical.Enabled then
                        if UIS:IsKeyDown(Enum.KeyCode.Space) then 
                            FlyVDirection = FlyVerticalValue.Value
                        elseif UIS:IsKeyDown(Enum.KeyCode.LeftShift) or UIS:IsKeyDown(Enum.KeyCode.LeftControl) then
                            FlyVDirection = -FlyVerticalValue.Value
                        end
                    end

                    if FlyMode.Value == 'velocity' then 
                        RootPart.Velocity = Vector3.new(X, FlyVDirection, Z)
                    elseif FlyMode.Value == 'cframe' then
                        local Factor = Speed - Humanoid.WalkSpeed
                        local MoveDirection = (MoveDirection * Factor) * dt
                        local NewCFrame = RootPart.CFrame + Vector3.new(MoveDirection.X, FlyVDirection * dt, MoveDirection.Z)

                        RootPart.Velocity = Vector3.new(Velocity.X, 0, Velocity.Y)
                        RootPart.CFrame =  NewCFrame
                    elseif FlyMode.Value == 'linearvelocity' then
                        LinearVelocity = entity.character.HumanoidRootPart:FindFirstChildOfClass("LinearVelocity") or Instance.new("LinearVelocity", entity.character.HumanoidRootPart)
                        LinearVelocity.Attachment0 = entity.character.HumanoidRootPart:FindFirstChildOfClass("Attachment")
                        LinearVelocity.MaxForce = 9e9
                        LinearVelocity.VectorVelocity = Vector3.new(X, FlyVDirection, Z)
                    elseif FlyMode.Value == 'assemblylinearvelocity' then
                        RootPart.AssemblyLinearVelocity = Vector3.new(X, FlyVDirection, Z)
                    end

                    if FlyFloor.Enabled then 
                        Humanoid:ChangeState(Enum.HumanoidStateType.Freefall)
                        Floor = Floor or Instance.new("Part")
                        Floor.CanQuery = false
                        Floor.Anchored = true
                        Floor.CanCollide = true
                        Floor.Size = Vector3.new(1, 0.1, 1)
                        Floor.CFrame = RootPart.CFrame * CFrame.new(0, -2, 0)
                        Floor.Transparency = 1
                        Floor.Parent = workspace
                    end
                end)
            else
                funcs:unbindFromHeartbeat("Fly")
                if LinearVelocity then 
                    LinearVelocity:Destroy()
                    LinearVelocity = nil
                end
                if AlignPosition then
                    AlignPosition:Destroy()
                    AlignPosition = nil
                end
                if Floor then 
                    Floor:Destroy()
                    Floor = nil
                end
            end
        end,
    })
    FlyMode = Fly.CreateDropdown({
        Name = "mode",
        List = {"cframe", "velocity", "linearvelocity", "assemblylinearvelocity"},
        Default = "cframe",
        Function = function(value) 
            if Fly.Enabled then 
                Fly.Toggle()
                Fly.Toggle()
            end
        end
    })
    FlyValue = Fly.CreateSlider({
        Name = "value",
        Min = 0,
        Max = 30,
        Default = 30,
        Round = 1,
        Function = function(value) 
            if Fly.Enabled then 
                Fly.Toggle()
                Fly.Toggle()
            end
        end
    })
    FlyVertical = Fly.CreateToggle({
        Name = "vertical",
        Default = true,
        Function = function(value) 
            if Fly.Enabled then 
                Fly.Toggle()
                Fly.Toggle()
            end
        end
    })
    FlyVerticalValue = Fly.CreateSlider({
        Name = "vertical value",
        Min = 0,
        Max = 100,
        Default = 20,
        Round = 1,
        Function = function(value) 
            if Fly.Enabled then 
                Fly.Toggle()
                Fly.Toggle()
            end
        end
    })
    FlyFloor = Fly.CreateToggle({
        Name = "platform",
        Default = true,
        Function = function(value) end
    })
end


do 
    local Old
    local HitChance;
    local TargetPart;
    local FOV = {};
    local FOVVisualize;
    local FOVCircle = Drawing.new("Circle");
    local FOVFilled;
    local FOVTransparency;
    local FOVSides;
    local FOVThickness;
    local SlientAim = {}; SlientAim = GuiLibrary.Objects.combatWindow.API.CreateOptionsButton({
        Name = "slientaim",
        Function = function(callback) 
            if callback then 
                funcs:bindToRenderStepped("slientaim", function(dt) 
                    if FOVVisualize.Enabled then
                        FOVCircle.Color = GuiLibrary.utils:getColor()
                        FOVCircle.Filled = FOVFilled.Enabled
                        FOVCircle.Transparency = FOVTransparency.Value
                        FOVCircle.Radius = FOV.Value
                        FOVCircle.Position = UIS:GetMouseLocation()
                        FOVCircle.NumSides = FOVSides.Value
                        FOVCircle.Thickness = FOVThickness.Value
                        FOVCircle.Visible = true
                    end
                end)
                Old = debug.getupvalue(modules.Bullets.Fire, 2)
                debug.setupvalue(modules.Bullets.Fire, 2, function(...) 
                    local old = Old(...)
                    local Part = (TargetPart.Value == 'head' and 'Head' or 'RootPart')
                    local nearestEntity = funcs:getClosestEntityToMouse(FOV.Value, false, true, {
                        Ignore = {workspace.Effects, workspace.Sounds, funcs:getAccessories(), workspace.Map:FindFirstChild("Sea")},
                        Origin = workspace.CurrentCamera.CFrame.p,
                        TargetPart = Part,
                    })
                    local HitChanceSuccess = math.random(0, 100) <= HitChance.Value
                    if nearestEntity and HitChanceSuccess then 
                        local new = CFrame.lookAt(workspace.CurrentCamera.CFrame.p, nearestEntity[Part].CFrame.p).LookVector
                        return new
                    end
                    return old
                end)
            else
                if FOVCircle then 
                    FOVCircle.Visible = false
                end
                debug.setupvalue(modules.Bullets.Fire, 2, Old)
                funcs:unbindFromRenderStepped("slientaim")
            end
        end
    })
    TargetPart = SlientAim.CreateDropdown({
        Name = "target part",
        Default = "head",
        List = {"head", "rootpart"},
    })
    HitChance = SlientAim.CreateSlider({
        Name = "hitchance",
        Min = 0,
        Max = 100,
        Default = 100,
        Round = 1,
        Function = function(value) 
        end
    })
    FOV = SlientAim.CreateSlider({
        Name = "fov",
        Min = 0,
        Max = 1200,
        Default = 200,
        Round = 1,
        Function = function(value) 
        end
    })
    FOVVisualize = SlientAim.CreateToggle({
        Name = "visualize fov",
        Default = true,
        Function = function(value) 
            if FOVCircle then 
                FOVCircle.Visible = value
            end
        end
    })
    FOVFilled = SlientAim.CreateToggle({
        Name = "filled fov",
        Default = false,
        Function = function(value) 
        end
    })
    FOVTransparency = SlientAim.CreateSlider({
        Name = "transparency",
        Min = 0,
        Max = 1,
        Default = 0.5,
        Round = 1,
        Function = function(value) 
        end
    })
    FOVSides = SlientAim.CreateSlider({
        Name = "sides",
        Min = 3,
        Max = 50,
        Default = 50,
        Round = 0,
        Function = function(value) 
        end
    })
    FOVThickness = SlientAim.CreateSlider({
        Name = "thickness",
        Min = 0,
        Max = 5,
        Default = 1,
        Round = 1,
        Function = function(value) 
        end
    })
end

do 
    local Worker = funcs:newWorker()
    local DisableZombies = {};
    DisableZombies = GuiLibrary.Objects.exploitsWindow.API.CreateOptionsButton({
        Name = "zombiecollector",
        Function = function(callback) 
            if callback then 
                coroutine.wrap(function()
                    local mobs = workspace:WaitForChild("Zombies"):WaitForChild("Mobs")
                    funcs:bindToRenderStepped("zombiehold", function(dt)
                        for _,v in pairs(mobs:GetChildren()) do
                            if not v.PrimaryPart then 
                                continue
                            end

                            if (not isnetworkowner) or (not isnetworkowner(v.PrimaryPart)) then 
                                continue
                            end
                            
                            v.PrimaryPart.CFrame = entity.character.HumanoidRootPart.CFrame + Vector3.new(0, 7.5, 0)
                            v.PrimaryPart.Velocity = Vector3.zero
                        end
                    end)
                end)()
            else
                funcs:unbindFromRenderStepped("zombiehold")
            end
        end
    })
end

do
    local old
    local AlwaysShoot = {};
    AlwaysShoot = GuiLibrary.Objects.exploitsWindow.API.CreateOptionsButton({
        Name = "alwaysallowshoot",
        Function = function(callback) 
            if callback then 
                old = debug.getupvalue(modules.Firearm, 7)
                debug.setupvalue(modules.Firearm, 7, function(...)
                    return true
                end)
            else
                debug.setupvalue(modules.Firearm, 7, old)
            end
        end
    })
end

do 
    pcall(function()
        debug.setupvalue(modules.Framework.Libraries.Network.Send, 6, function() end)   
    end)

    local BanRemotes = {
        ["Statistic Report"] = true,
        ["Zombie State Resync Attempt"] = true,
        ["Resync Leaderboard"] = true,
        ["Sync Debug Info"] = true,
        ["Resync Character Physics"] = true,
        ["Update Character Position"] = true,
        ["Get Player Stance Speed"] = true,
        ["Force Charcter Save"] = true,
        ["Update Character State"] = true,
        ["Sync Near Chunk Loot"] = true,
        ["Character Config Resync"] = true,
        ["Animator State Desync Check"] = true,
        ["Character Humanoid Update"] = true,
        ["Character Root Update"] = true,
    }

    local NoFall = {};
    NoFall = GuiLibrary.Objects.utilitiesWindow.API.CreateOptionsButton({
        Name = "nofall",
        Function = function(callback) end
    })

    local AntiBan = {};
    AntiBan = GuiLibrary.Objects.utilitiesWindow.API.CreateOptionsButton({
        Name = "antiban",
        Function = function(callback) end
    })

    --[[
    local AlwaysWalk = {};
    AlwaysWalk = GuiLibrary.Objects.utilitiesWindow.API.CreateOptionsButton({
        Name = "alwayswalk",
        Function = function(callback) 
            if callback then 
                local plrs = modules.Framework.Classes.Players
                local plr = plrs and plrs.get()
                if not plr then 
                
                end
                plr.CharacterAdded:Connect(function(char)
                    if not char then 
                        return
                    end

                    local oldmt = getmetatable(char)
                    setmetatable(char, {__newindex = function(t,k,v) 
                        if k == "MoveState" then 
                            rawset(t, k, "Walking")
                            return
                        end
                        t[k] = v
                    end})
                end)
            end
        end
    })]]

    local old = modules.Framework.Libraries.Network.Send
    modules.Framework.Libraries.Network.Send = function(Self, Name, ...)
        if Name == "Set Character State" then
            for i,v in next, ({...})[1] do 
                if v[1] == "Falling" then 
                    if NoFall.Enabled then
                        v[1] = "Walking"
                    end
                end
            end
        end
        if BanRemotes[Name] and AntiBan.Enabled then 
            return
        end
        return old(Self, Name, ...)
    end

    engoware.UninjectEvent.Event:Connect(function() 
        modules.Framework.Libraries.Network.Send = old
    end)
end

do 
    local Worker = funcs:newWorker()
    local NoFog = {};
    NoFog = GuiLibrary.Objects.renderWindow.API.CreateOptionsButton({
        Name = "nofog",
        Function = function(callback) 
            if callback then 
                local OldFogEnd = game:GetService("Lighting").FogEnd
                game:GetService("Lighting").FogEnd = math.huge
                local OldAssets = {}
                for i,v in next, game:GetService("Lighting"):GetChildren() do 
                    OldAssets[i] = v
                    v.Parent = nil
                end

                Worker:add(function() 
                    for i,v in next, OldAssets do 
                        pcall(function()
                            v.Parent = game:GetService("Lighting")
                        end)
                    end
                    game:GetService("Lighting").FogEnd = OldFogEnd
                end)
            else
                Worker:clean()
            end
        end
    })
end 

do 
    local NoRecoil = {};
    NoRecoil = GuiLibrary.Objects.combatWindow.API.CreateOptionsButton({
        Name = "norecoil",
        Function = function(callback) end
    })
    --[[local OldFunc = debug.getupvalue(debug.getupvalue(modules.Character, 1), 4)
    debug.setupvalue(debug.getupvalue(modules.Character, 1), 4, function(data, ...) 
        local oldResult = OldFunc(data, ...)
        if NoRecoil.Enabled then 
            return CFrame.new()
        end
        return oldResult
    end)]]
    local Old = debug.getupvalue(modules.Bullets.Fire, 10)
    debug.setupvalue(modules.Bullets.Fire, 10, function(data, ...) 
        local oldResult = Old(data, ...)
        if NoRecoil.Enabled then 
            oldResult[1] = Vector2.zero
            for i = 2, 5 do 
                oldResult[i] = 0
            end
        end
        return oldResult
    end)

    engoware.UninjectEvent.Event:Connect(function() 
        debug.setupvalue(modules.Bullets.Fire, 10, Old)
    end)
end

do 
    local LastAttack = 0;
    local Killaura = {};
    Killaura = GuiLibrary.Objects.combatWindow.API.CreateOptionsButton({
        Name = "killaura",
        Function = function(callback) 
            if callback then 
                coroutine.wrap(function() 
					repeat task.wait()
						local char = modules.Framework.Classes.Players and modules.Framework.Classes.Players.get()
						if char then 
							local knife = char.Character and char.Character.Inventory.Equipment.Melee
							if knife then 
								local plr = funcs:getClosestEntity(15, false)
								if plr then 
									if not knife.Animating then
										local clock = os.clock()
										local allowed = false
										if knife.ComboAfter <= clock and clock <= knife.ComboLimit then
											knife.ComboIndex = knife.ComboIndex + 1
											if #knife.AttackConfig < knife.ComboIndex then
												knife.ComboIndex = 1
											end
											allowed = true
										elseif knife.ComboAfter < clock then
											knife.ComboIndex = 1
											allowed = true
										end
										if allowed then
											local knifeconfig = knife.AttackConfig[knife.ComboIndex]
											local anim = modules.Framework.Libraries.Resources:Search("ReplicatedStorage.Assets.Animations." .. knifeconfig.Animation) 
											local animdelay = 0
											if anim then
												local animlength = anim:GetAttribute("Length")
												if animlength then
													animdelay = animlength / (knifeconfig.PlaybackSpeedMod and 1)
												end
											end
											knife.Animating = true
											knife.ComboAfter = os.clock() + animdelay - 0.1
											knife.ComboLimit = knife.ComboAfter + 0.2
											modules.Framework.Libraries.Network:Send("Melee Swing", knife.Id, knife.ComboIndex)
											task.delay(animdelay, function()
												knife.Animating = false
											end)
										end
									else
										modules.Framework.Libraries.Network:Send("Melee Hit Register", knife.Id, plr.Head, "Flesh")
									end
								end
							end
                        end
					until (not Killaura.Enabled)
                end)()
            end
        end
    })
end

do 
    local function formatEntityList(t) 
        local x = {}
            for i,v in next, t do
                x[#x+1] = v.Player.Name
            end
        return x
    end

    local RetryDelay = {};
    local Delay = {};
    local Offset = {};
    local Tick = 0
    local Player = {};
    local Click = {};
    Click = GuiLibrary.Objects.exploitsWindow.API.CreateOptionsButton({
        Name = "playertp",
        Function = function(callback) 
            if callback then 

                if Tick - tick() > 0 then
                    Click.Toggle()
                    return game:GetService("StarterGui"):SetCore("SendNotification", {Title = "TPBypass", Text = ("Teleport is delayed!\nplease wait %ss"):format(tostring(math.round(Tick-tick()))), Duration = 2})
                end

                local ind, ent = entity.getEntityFromPlayer(Players:FindFirstChild(Player.Value or ""))
                if ent then
                    coroutine.wrap(function()
                        local Success = funcs:tpBypass(ent.HumanoidRootPart.CFrame + Vector3.new(0, Offset.Value, 0), Delay.Value)
                        if Success == false then 
                            task.wait(RetryDelay.Value)
                            game:GetService("StarterGui"):SetCore("SendNotification", {Title = "TPBypass", Text = "Attemping to retry teleport", Duration = 2})
                            local Success2 = funcs:tpBypass(ent.HumanoidRootPart.CFrame + Vector3.new(0, Offset.Value, 0), Delay.Value * 2)
                            if Success2 == false then 
                                Tick = tick() + 30
                                game:GetService("StarterGui"):SetCore("SendNotification", {Title = "TPBypass", Text = "Teleport failed!\nplease wait 30 seconds before retrying", Duration = 2})
                            end
                        end
                    end)()
                end

                Click.Toggle()
            end
        end
    })
    Player = Click.CreateDropdown({
        Name = "player",
        List = formatEntityList(entity.entityList),
        Function = function(value) 
            
        end
    })
    Offset = Click.CreateSlider({
        Name = "offset",
        Min = -25,
        Max = 25,
        Default = 0,
        Function = function(value) 
            
        end
    })
    Delay = Click.CreateSlider({
        Name = "wait delay",
        Min = 5,
        Max = 10,
        Default = 6,
        Function = function(value) 
            
        end
    })
    RetryDelay = Click.CreateSlider({
        Name = "retry delay",
        Min = 1,
        Max = 10,
        Default = 3,
        Function = function(value) 
            
        end
    })
    local Connection = entity.entityAddedEvent:Connect(function() 
        Player.SetList(formatEntityList(entity.entityList))
    end)
    local Connection2 = entity.entityRemovedEvent:Connect(function() 
        Player.SetList(formatEntityList(entity.entityList))
    end)
    local Connection3 = entity.entityUpdatedEvent:Connect(function(payer) 
        Player.SetList(formatEntityList(entity.entityList))
    end)
    engoware.UninjectEvent.Event:Connect(function() 
        Connection:Disconnect()
        Connection2:Disconnect()
        Connection3:Disconnect()
    end)
end


do
    local AimbotFOV
    local TargetPart = {};
    local AimbotSpeed = {};
    local AimbotMode = {};
    local Aimbot = {};
    local AimbotInstant = {}

    local function canAimbot() 
        if not Aimbot.Enabled then 
            return false;
        end

        if AimbotMode.Value == 'toggle' then 
            return true;
        end

        if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then 
            return true;
        end

        return false;
    end
    
    Aimbot = GuiLibrary.Objects.combatWindow.API.CreateOptionsButton({
        Name = "aimbot",
        Function = function(callback) 
            if callback then 
                coroutine.wrap(function()
                    repeat
                        game:GetService("RunService").Stepped:Wait()

                        local mousePos = UIS:GetMouseLocation()
                        local guiObjs = lplr.PlayerGui:GetGuiObjectsAtPosition(mousePos.X, mousePos.Y)
                        if guiObjs or #guiObjs > 0 then 
                            continue;
                        end
                        if UIS:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) or not (AimbotMode.Value == 'hold') then 
                            local Part = (TargetPart.Value == 'head' and 'Head' or 'RootPart')
                            local nearestEntity = funcs:getClosestEntityToMouse(AimbotFOV.Value, false, true, {
                                Ignore = {workspace.Effects, workspace.Sounds, funcs:getAccessories(), workspace.Map:FindFirstChild("Sea")},  
                                Origin = workspace.CurrentCamera.CFrame.p,
                                TargetPart = Part,
                            })
                            if not nearestEntity then
                                continue
                            end

                            if not canAimbot() then 
                                continue
                            end

                            funcs:lookat(nearestEntity[Part].CFrame.p, AimbotSpeed.Value)
                        end
                    until (not Aimbot.Enabled)
                end)()
            end
        end,
    })
    AimbotFOV = Aimbot.CreateSlider({
        Name = "fov",
        Min = 0,
        Max = 1200,
        Default = 1200,
        Round = 0,
        Function = function(value) end
    })
    AimbotMode = Aimbot.CreateDropdown({
        Name = "mode",
        List = {
            'hold',
            'toggle',
        },
        Default = 'hold',
        Function = function(value) end
    })
    TargetPart = Aimbot.CreateDropdown({
        Name = "targetpart",
        List = {
            'head',
            'rootpart',
        },
        Function = function(value) end
    })
    AimbotSpeed = Aimbot.CreateSlider({
        Name = "smoothness",
        Min = 1,
        Max = 50,
        Default = 5,
        Round = 0,
        Function = function(value) end
    })
    AimbotInstant = Aimbot.CreateToggle({
        Name = "instant",
        Function = function(value) end
    })
end

do 
    local Old = {}
    local FireRateMult = {};
    local FireRate = {};
    FireRate = GuiLibrary.Objects.combatWindow.API.CreateOptionsButton({
        Name = "firerate",
        Function = function(callback) 
            if callback then 
                for _, Folder in next, game:GetService("ReplicatedStorage").ItemData:GetChildren() do 
                    for _, Module in next, Folder:GetChildren() do 
                        if Module:IsA("ModuleScript") then 
                            local Name = Module.Name
                            local Module = require(Module)
                            if Module.FireConfig and Module.FireConfig.FireRate then 
                                Old[Name] = Module.FireConfig.FireRate
                                setreadonly(Module.FireConfig, false)
                                Module.FireConfig.FireRate = Old[Name] * (FireRateMult.Value)
                                setreadonly(Module.FireConfig, true)
                            end
                        end
                    end
                end
            else
                for _, Folder in next, game:GetService("ReplicatedStorage").ItemData:GetChildren() do 
                    for _, Module in next, Folder:GetChildren() do 
                        if Module:IsA("ModuleScript") then 
                            local Name = Module.Name
                            local Module = require(Module)
                            if Module.FireConfig and Module.FireConfig.FireRate then 
                                setreadonly(Module.FireConfig, false)
                                Module.FireConfig.FireRate = Old[Name]
                                setreadonly(Module.FireConfig, true)
                            end
                        end
                    end
                end
            end 
        end
    })
    FireRateMult = FireRate.CreateSlider({
        Name = "mult",
        Min = 1,
        Max = 5,
        Default = 1,
        Round = 3,
        Function = function(value)
            if FireRate.Enabled then
                FireRate.Toggle()
                FireRate.Toggle()
            end
        end
    })
end

do 
    local BotFOV={}
    local Triggerbot={};
    Triggerbot = GuiLibrary.Objects.combatWindow.API.CreateOptionsButton({
        Name = "triggerbot",
        Function = function(callback)   
            if callback then 
                coroutine.wrap(function()
                    repeat
                        task.wait()

                        local char = modules.Framework.Classes.Players and modules.Framework.Classes.Players.get()
                        if not char or not char.Character then 
                            continue
                        end

                        char = char.Character
                        if not char.Instance then 
                            continue
                        end

                        local itemtab = char.EquippedItem
                        if not itemtab or not itemtab.Type == 'Firearm' or not itemtab.Attachments or not itemtab.Attachments.Ammo then 
                            continue
                        end

                        if itemtab.Attachments.Ammo.WorkingAmount <= 0 then 
                            itemtab:OnReload(char)
                            continue
                        end

                        local item = char.Instance:FindFirstChild("Equipped") and char.Instance:FindFirstChild("Equipped"):FindFirstChild(char.EquippedItem.Name)
                        local cam = modules.Cameras:GetCamera("Character")
                        if not cam then 
                            continue
                        end

                        local muzzlePos = item:FindFirstChild("Muzzle") and item:FindFirstChild("Muzzle").CFrame.p or workspace.CurrentCamera.CFrame.p

                        local dist = itemtab.FireConfig.DamageFallOff.StartsAt
                        if dist <= 0 then
                            dist = itemtab.FireConfig.DamageFallOff.LowestAt * itemtab.FireConfig.DamageFallOff.FinalMod
                        end

                        local nearestEntity = funcs:getClosestEntityToMouse(BotFOV.Value, false, true, {
                            Ignore = {workspace.Effects, workspace.Sounds, funcs:getAccessories(), workspace.Map:FindFirstChild("Sea")},  
                            Origin = workspace.CurrentCamera.CFrame.p,
                            TargetPart = "Head",
                            MaxDist = dist,
                            SkipVisible = false,
                            Checks = {function(ori, dir) 
                                local castLocalBullet = debug.getupvalue(modules.Bullets.Fire, 4)
                                local hitPart, hitPos, hitNormal, rayTable, distance = castLocalBullet(char, itemtab, muzzlePos, dir)
                                if modules.Raycasting:IsHitCharacter(hitPart) then 
                                    return true
                                end
                            end}
                        })
                        
                        if not nearestEntity then
                            continue
                        end

                        local Inputting = 0
                        itemtab:OnUse(setmetatable({}, {__index = function(t, k)
                            if k == "UseItemInput" then
                                Inputting = Inputting + 1
                                return Inputting < 3
                            end
                            return char[k] 
                        end}))
                        --modules.Bullets:Fire(char, cam, itemtab, muzzlePos, CFrame.lookAt(workspace.CurrentCamera.CFrame.p, nearestEntity.RootPart.CFrame.p).LookVector)
                        --itemtab.Attachments.Ammo.WorkingAmount = itemtab.Attachments.Ammo.WorkingAmount - 1
                    until (not Triggerbot.Enabled)
                end)()
            end
        end,
    })
    BotFOV = Triggerbot.CreateSlider({
        Name = "fov",
        Min = 0,
        Max = 1200,
        Default = 1200,
        Round = 0,
        Function = function(value) end
    })
end
