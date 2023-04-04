--[[

    Main.lua - Main file for engoware.
    --[[

    Main.lua - Main file for engoware.
    
    written by: @engo#0320

]]

if not game:IsLoaded() then 
    game.Loaded:Wait()
end

local startTick = tick()

local request = (syn and syn.request) or request or http_request or (http and http.request)
local queueteleport = syn and syn.queue_on_teleport or queue_on_teleport or fluxus and fluxus.queue_on_teleport
local setthreadidentityfunc = syn and syn.set_thread_identity or set_thread_identity or setidentity or setthreadidentity
local getthreadidentityfunc = syn and syn.get_thread_identity or get_thread_identity or getidentity or getthreadidentity
local UIS = game:GetService("UserInputService")
local ts = game:GetService("TweenService")
local Players = game:GetService("Players")
local lplr = Players.LocalPlayer
local entity, GuiLibrary
local override = {
    [6872265039] = "bedwars_lobby",
    [8444591321] = "bedwars",
    [6872274481] = "bedwars",
    [8560631822] = "bedwars",
    [863266079] = "ar2"
}
local funcs = {}; do
    function funcs:require(url, bypass, bypass2)
        if (not url:match("http")) and isfile(url) then
            return readfile(url)
        end

        local newUrl = (bypass and "https://raw.githubusercontent.com/joeengo/" or "https://raw.githubusercontent.com/joeengo/engoware/main/") .. url:gsub("engoware/", ""):gsub("engoware\\", "")
        local response = request({
            Url = bypass2 and url or newUrl,
            Method = "GET",
        })
        if response.StatusCode == 200 then
            return response.Body
        end
    end

    function funcs:getPlaceIdentifier() 
        return tostring(override[game.PlaceId] or game.PlaceId)
    end

    function funcs:getPlaceScript() 
        local placeId = funcs:getPlaceIdentifier()
        local scriptName = (placeId .. ".lua")
        if scriptName then
            local path = "engoware/games/" .. scriptName
            return funcs:require(path) or ""
        end
    end

    function funcs:getUniversalScript()
        return funcs:require("engoware/games/universal.lua")
    end

    function funcs:getPrivateScript() 
        local placeId = funcs:getPlaceIdentifier()
        local scriptName = (placeId .. ".lua")
        if scriptName then
            local path = "engoware/private/" .. scriptName
            return funcs:require(path) or ""
        end
    end

    function funcs:run(code) 
        local func, err = loadstring(code)
        if not typeof(func) == 'function' then
            return warn("Failed to run code, error: " .. tostring(err))
        end
        return func()
    end

    function funcs:wlfind(tab, obj) 
        for i,v in next, tab do
            if v == obj or type(v) == "table" and v.hash == obj then
                return v
            end
        end
    end

    function funcs:connection(...) 
        return GuiLibrary.utils:connection(...)
    end

    function funcs:getObject(objectName, prop, val) 
        for i,v in next, GuiLibrary.Objects do 
            if i == objectName and v[prop] == val then 
                return v
            end
        end
    end

    local loops = {RenderStepped = {}, Heartbeat = {}, Stepped = {}}
    function funcs:bindToStepped(id, callback)
        if not loops.Stepped[id] then 
            loops.Stepped[id] = game:GetService("RunService").Stepped:Connect(callback)
        else
            warn("[engoware] attempt to bindToStepped to an already bound id: " .. tostring(id))
        end
    end

    function funcs:unbindFromStepped(id)
        if loops.Stepped[id] then
            loops.Stepped[id]:Disconnect()
            loops.Stepped[id] = nil
        end
    end

    function funcs:bindToRenderStepped(id, callback)
        if not loops.RenderStepped[id] then 
            loops.RenderStepped[id] = game:GetService("RunService").RenderStepped:Connect(callback)
        else
            warn("[engoware] attempt to bindToRenderStepped to an already bound id: " .. tostring(id))
        end
    end

    function funcs:unbindFromRenderStepped(id)
        if loops.RenderStepped[id] then
            loops.RenderStepped[id]:Disconnect()
            loops.RenderStepped[id] = nil
        end
    end

    function funcs:bindToHeartbeat(id, callback)
        if not loops.Heartbeat[id] then 
            loops.Heartbeat[id] = game:GetService("RunService").Heartbeat:Connect(callback)
        else
            warn("[engoware] attempt to bindToHeartbeat to an already bound id: " .. tostring(id))
        end
    end

    function funcs:unbindFromHeartbeat(id)
        if loops.Heartbeat[id] then
            loops.Heartbeat[id]:Disconnect()
            loops.Heartbeat[id] = nil
        end
    end

    function funcs:isAlive(plr: Player, stateCheck: boolean) 
        if not plr then 
            return entity.isAlive
        end

        local _, ent = entity.getEntityFromPlayer(plr)
        return ((not stateCheck) or ent and ent.Humanoid:GetState() ~= Enum.HumanoidStateType.Dead) and ent
    end 

    function funcs:isTargetable(plr: Player) 
        return funcs:isAlive(plr, true) and (plr.Character) and (not plr.Character:FindFirstChildOfClass("ForceField"))
    end

    function funcs:getClosestEntity(maxDist: number, teamCheck: boolean)
        local maxDist, val = maxDist or 9e9, nil
        if funcs:isAlive() then
            for i,v in next, entity.entityList do 
                if (v.Targetable or not teamCheck) and funcs:isTargetable(v.Player) then 
                    local dist = (lplr.Character.HumanoidRootPart.Position - v.HumanoidRootPart.Position).Magnitude
                    if dist < maxDist then
                        maxDist, val = dist, v
                    end
                end
            end
        end
        return val
    end

    function funcs:getClosestEntityToMouse(maxDist: number, teamCheck: boolean, visCheck: boolean, visTable: table)
        local maxDist, val = maxDist or 9e9, nil
        if funcs:isAlive() then
            for i,v in next, entity.entityList do 
                if (v.Targetable or not teamCheck) and funcs:isTargetable(v.Player) then 
                    local Position, Visible = workspace.CurrentCamera:WorldToViewportPoint(v[visTable.TargetPart].Position)
                    if (not visTable.SkipVisible) and (not Visible) then 
                        continue
                    end

                    local Params = RaycastParams.new()
                    Params.FilterDescendantsInstances = {v.Character, workspace.CurrentCamera, lplr.Character, unpack(visTable.Ignore)}
                    Params.FilterType = Enum.RaycastFilterType.Blacklist
                    local Ray = workspace:Raycast(visTable.Origin, v[visTable.TargetPart].Position - visTable.Origin, Params)
                    local AreVisible = Ray and Ray.Instance == nil or not Ray
                    if visCheck and (not AreVisible) then
                        continue
                    end

                    local dist2 = (entity.character.HumanoidRootPart.Position - v.HumanoidRootPart.Position).Magnitude
                    if visTable.MaxDist and dist2 > (visTable.MaxDist) then
                        continue
                    end

                    if visTable.Checks then
                        for i,check in next, visTable.Checks do 
                            if not check(visTable.Origin, v[visTable.TargetPart].Position - visTable.Origin) then
                                continue
                            end
                        end
                    end

                    local dist = (UIS:GetMouseLocation() - Vector2.new(Position.X, Position.Y)).Magnitude
                    if dist < maxDist then
                        maxDist, val = dist, v
                    end
                end
            end
        end
        return val
    end

    function funcs:getSortedEntities(maxDist: number, maxEntities: number, teamCheck: boolean, sortFunction)
        local maxDist, maxEntities, val = maxDist or 9e9, maxEntities or 9e9, {}
        if not funcs:isAlive() then
            maxDist = 99e99
        end
        
        local selfPos = funcs:isAlive() and entity.character.HumanoidRootPart.Position or Vector3.zero
        for i,v in next, entity.entityList do 
            if (v.Targetable or not teamCheck) and funcs:isTargetable(v.Player) then 
                local dist = (selfPos - v.HumanoidRootPart.Position).Magnitude
                if dist < maxDist then
                    table.insert(val, v)
                end
            end
        end

        local sortFunction = sortFunction or function(ent1, ent2)
            return (selfPos - ent1.HumanoidRootPart.Position).Magnitude < (selfPos - ent2.HumanoidRootPart.Position).Magnitude
        end
        table.sort(val, sortFunction)

        if #val > maxEntities then
            return table.move(val, 1, maxEntities, 1, {})
        end

        return val
    end

    function funcs:getEnemyColor(isEnemy) 
        if isEnemy then
            return Color3.new(1, 0.427450, 0.427450)
        end
        return Color3.new(0.470588, 1, 0.470588)
    end

    function funcs:getColorFromEntity(ent, useTeamColor, useColorTheme) 
        if ent.Team and ent.Team.TeamColor.Color and useTeamColor then
            return ent.Team.TeamColor.Color
        end

        if useColorTheme then 
            return GuiLibrary.utils:getColor()
        end

        return funcs:getEnemyColor(ent.Targetable)
    end

    function funcs:newWorker() 
        local worker = {}
        local tasks = {}
        worker.tasks = tasks
        function worker:add(x) 
            table.insert(tasks, x)
        end
        function worker:clean() 
            for i,v in next, tasks do 
                local typeOf = typeof(v)
                if typeOf == 'Instance' then 
                    v:Destroy()
                elseif typeOf == 'table' then
                    if v.__OBJECT and v.__OBJECT_EXISTS then 
                        v:Remove()
                    end
                elseif typeOf == 'RBXScriptConnection' then
                    if v.Connected then
                        v:Disconnect()
                    end
                elseif typeOf == 'function' then
                    v()
                end
                tasks[i] = nil
            end
        end
        return worker
    end

    function funcs:curve(p0, p1, p2, p3, t)
        local t2 = t * t
        local t3 = t2 * t
        return p0 * (1 - 3 * t + 3 * t2 - t3) + p1 * (3 * t - 6 * t2 + 3 * t3) + p2 * (3 * t2 - 3 * t3) + p3 * t3
    end

    function funcs:lookat(p, smooth) 
        local smooth = smooth + 1
        local targetPos = workspace.CurrentCamera:WorldToScreenPoint(p)
        local mousePos = workspace.CurrentCamera:WorldToScreenPoint(lplr:GetMouse().Hit.p)
        mousemoverel((targetPos.X-mousePos.X) / smooth,( targetPos.Y - mousePos.Y) / smooth)
    end

    local function createAngleInc(Start, DefaultInc, Goal) 
        local i = Start or 0
        return function(Inc) 
            local Inc = Inc or DefaultInc or 1
            i = math.clamp(i + Inc, Start, Goal)
            return i
        end
    end
    
    function funcs:orbit(Self, Target, Radius, Delay, Speed, StopIf)
        local AngleInc = createAngleInc(0, Speed, 360)
        for i = 1, 360 / Speed do
            local Angle = AngleInc(Speed)
            Self.CFrame = CFrame.new(Target.CFrame.p) * CFrame.Angles(0, math.rad(Angle), 0) * CFrame.new(0, 0.1, Radius)
            task.wait(Delay)
            if StopIf and StopIf() then
                return
            end
        end
    end

    function funcs:tweenNumber(start, goal, time, func, _end) 
        local start, goal, time = start or 0, goal or 1, time or 1
        local worker = funcs:newWorker()
        local N = Instance.new("NumberValue")
        N.Parent = engoware.GuiLibrary.ScreenGui
        N.Value = start
        N.Name = "TweeningNumber"
        worker:add(N.Changed:Connect(function(value)
            func(value)
        end))
        local t = ts:Create(N, TweenInfo.new(), {Value = goal})
        t:Play()
        worker:add(t.Completed:Connect(function()
            worker:clean()
            N:Destroy()
            _end()
        end))
    end
end

if not getgenv or (identifyexecutor and identifyexecutor():find("Arceus")) then
    return warn("[engoware] unsupported executor.")
end

if engoware then 
    return warn("[engoware] already loaded.")
end

entity = funcs:run(funcs:require("https://raw.githubusercontent.com/7GrandDadPGN/VapeV4ForRoblox/main/Libraries/entityHandler.lua", true, true))
entity.fullEntityRefresh()
GuiLibrary = funcs:run(funcs:require("engoware/GuiLibrary.lua"))

getgenv().engoware = {}
engoware.UninjectEvent = Instance.new("BindableEvent")
engoware.entity = entity
engoware.GuiLibrary = GuiLibrary
engoware.funcs = funcs
makefolder("engoware")
makefolder("engoware/configs")

local windows = {
    combat = GuiLibrary.CreateWindow({Name = "combat"}),
    exploit = GuiLibrary.CreateWindow({Name = "exploits"}),
    movement = GuiLibrary.CreateWindow({Name = "movement"}),
    utilities = GuiLibrary.CreateWindow({Name = "utilities"}),
    render = GuiLibrary.CreateWindow({Name = "render"}),
    misc = GuiLibrary.CreateWindow({Name = "misc"}),
    other = GuiLibrary.CreateWindow({Name = "other"}),
}

local UninjectButton; UninjectButton = windows.other.CreateOptionsButton({
    Name = "uninject",
    Function = function(callback)
        if callback then
            UninjectButton.Toggle()
            engoware.UninjectEvent:Fire()
        end
    end
})

local guiButton = windows.other.CreateOptionsButton({
    Name = "gui",
    Function = function(callback) 
        GuiLibrary.ClickGUI.Visible = callback
    end,
    Bind = "RightShift",
})
GuiLibrary.ClickGUI.Visible = false

local canScale = guiButton.CreateToggle({
    Name = "canScale",
    Function = function(callback)
        GuiLibrary.canScale = callback
    end,
    Default = true
})

local colorButton; colorButton = windows.other.CreateOptionsButton({
    Name = "colors",
    Function = function(callback)
        if not callback then
            colorButton.Toggle()
        end
    end,
})
if not colorButton.Enabled then
    colorButton.Toggle()
end

local hueSlider
local satSlider
local valSlider
local rainbowSmoothSlider
local rainbowToggle = colorButton.CreateToggle({
    Name = "rainbow",
    Function = function(callback)
        GuiLibrary.Rainbow = callback
        if not callback then
            GuiLibrary.utils:setColorTheme({H = hueSlider.Value / 360, S = satSlider.Value / 100, V = valSlider.Value / 100})
        end
    end,
})

rainbowSmoothSlider = colorButton.CreateSlider({
    Name = "rainbow smoothness",
    Function = function(value)
        GuiLibrary.RainbowSmoothness = value * 75
    end,
    Min = 10,
    Max = 100,
    Default = 23,
})

hueSlider = colorButton.CreateSlider({
    Name = "hue",
    Function = function(value)
        if GuiLibrary.Rainbow then 
            return
        end
        local old = GuiLibrary.utils:getColorTheme(true)
        GuiLibrary.utils:setColorTheme({
            H = value / 360,
            S = old.S,
            V = old.V,
        })
    end,
    Min = 0,
    Max = 360,
    Round = 0,
    Default = 150,
})

satSlider = colorButton.CreateSlider({
    Name = "sat",
    Function = function(value)
        local old = GuiLibrary.utils:getColorTheme(true)
        GuiLibrary.utils:setColorTheme({
            H = old.H,
            S = value / 100,
            V = old.V,
        })
    end,
    Min = 0,
    Max = 100,
    Round = 0,
    Default = 100,
})

valSlider = colorButton.CreateSlider({
    Name = "val",
    Function = function(value)
        local old = GuiLibrary.utils:getColorTheme(true)
        GuiLibrary.utils:setColorTheme({
            H = old.H,
            S = old.S,
            V = value / 100,
        })
    end,
    Min = 0,
    Max = 100,
    Round = 0,
    Default = 100,
})

local arrayListApi = {}
local arrayListWindow = GuiLibrary.CreateCustomWindow({
    Name = "array list",
})
local arrayListToggle = {}

local keyStrokesToggle = {}
local keystrokesAPI = {}
local keyStrokesWindow = GuiLibrary.CreateCustomWindow({Name = "keystrokes"})

local HUDButton = windows.other.CreateOptionsButton({
    Name = "hud",
    Function = function(callback)
        if arrayListToggle.Enabled then
            arrayListWindow.Instance.Visible = callback
        end
        if keyStrokesToggle.Enabled then
            keyStrokesWindow.Instance.Visible = callback
        else
            keyStrokesWindow.Instance.Visible = false
            if keystrokesAPI.Connection then 
                keystrokesAPI.Connection:Disconnect()  
                keystrokesAPI.Connection = nil
            end
            if keystrokesAPI.Connection2 then 
                keystrokesAPI.Connection2:Disconnect()  
                keystrokesAPI.Connection2 = nil
            end
        end
    end,
})
arrayListToggle = HUDButton.CreateToggle({
    Name = "array list",
    Function = function(callback)
        if HUDButton.Enabled then
            arrayListWindow.Instance.Visible = callback
        end
    end,
})

do 
    local ArrayList = arrayListWindow.new("Frame")
    ArrayList.Name = "ArrayList"
    ArrayList.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ArrayList.BackgroundTransparency = 1.000
    ArrayList.Position = UDim2.new(-0.551886797, 0, 0, 0)
    ArrayList.Size = UDim2.new(0, 329, 0, 372)
    arrayListApi.ArrayListInstance = ArrayList
    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.Parent = ArrayList
    UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    local Watermark = Instance.new("TextLabel")
    Watermark.Name = "Watermark"
    Watermark.Parent = ArrayList
    Watermark.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Watermark.BackgroundTransparency = 1.000
    Watermark.Position = UDim2.new(-0.887538016, 0, 0.161490679, 0)
    Watermark.Size = UDim2.new(0, 621, 0.1556832382, 0)
    Watermark.Font = Enum.Font.Code
    Watermark.Text = "engoware"
    Watermark.TextColor3 = GuiLibrary.utils:getColorOfObject(Watermark)
    GuiLibrary.utils:connection(GuiLibrary.ColorUpdate:Connect(function()
        Watermark.TextColor3 = GuiLibrary.utils:getColorOfObject(Watermark)
    end))
    Watermark.TextScaled = true
    Watermark.TextSize = 14.000
    Watermark.TextStrokeTransparency = 0
    Watermark.TextWrapped = true
    Watermark.TextXAlignment = Enum.TextXAlignment.Right
    arrayListApi.Watermark = Watermark
    local WatermarkText = Instance.new("TextLabel")
    WatermarkText.Name = "Watermark"
    WatermarkText.Parent = ArrayList
    WatermarkText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    WatermarkText.BackgroundTransparency = 1.000
    WatermarkText.Position = UDim2.new(-0.887538016, 0, 0.161490679, 0)
    WatermarkText.Size = UDim2.new(0, 621, 0.0856832382, 0)
    WatermarkText.Font = Enum.Font.Code
    WatermarkText.Text = "Custom Text!"
    WatermarkText.TextColor3 = GuiLibrary.utils:getColorOfObject(WatermarkText)
    GuiLibrary.utils:connection(GuiLibrary.ColorUpdate:Connect(function()
        WatermarkText.TextColor3 = GuiLibrary.utils:getColorOfObject(WatermarkText)
    end))
    WatermarkText.TextScaled = true
    WatermarkText.TextSize = 14.000
    WatermarkText.TextStrokeTransparency = 0
    WatermarkText.TextWrapped = true
    WatermarkText.TextXAlignment = Enum.TextXAlignment.Right
    arrayListApi.WatermarkText = WatermarkText

    function arrayListApi.handleEntry(name, enabled, wasKeyDown) 
        arrayListApi.Objects = arrayListApi.Objects or {}
        local ArrayListModule = arrayListApi.Objects[name] or Instance.new("TextLabel")
        ArrayListModule.Name = "ArrayListModule"
        ArrayListModule.Parent = ArrayList
        ArrayListModule.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ArrayListModule.BackgroundTransparency = 1.000
        ArrayListModule.Position = UDim2.new(-0.887538016, 0, 0.161490679, 0)
        ArrayListModule.Size = UDim2.new(0, 621, 0.0656832382, 0)
        ArrayListModule.Font = Enum.Font.Code
        ArrayListModule.Text = name
        ArrayListModule.TextColor3 = GuiLibrary.utils:getColorOfObject(ArrayListModule)
        GuiLibrary.utils:connection(GuiLibrary.ColorUpdate:Connect(function()
            ArrayListModule.TextColor3 = GuiLibrary.utils:getColorOfObject(ArrayListModule)
        end))
        ArrayListModule.TextScaled = true
        ArrayListModule.TextSize = 14.000
        ArrayListModule.TextStrokeTransparency = 0.500
        ArrayListModule.TextWrapped = true
        ArrayListModule.TextXAlignment = Enum.TextXAlignment.Right
        arrayListApi.Objects[name] = ArrayListModule
        if not enabled then 
            ArrayListModule:Destroy()
            arrayListApi.Objects[name] = nil
        end

        local children = ArrayList:GetChildren()
        table.sort(children, function(a,b)
            if not a:IsA("TextLabel") then 
                return false
            end
            if not b:IsA("TextLabel") then 
                return true
            end
            return a.TextBounds.X > b.TextBounds.X
        end)

        for i,v in next, children do 
            if v.Name:find("Watermark") then
                v.LayoutOrder = (v.Name:find("Text") and 2) or 0
                continue
            end
            if v:IsA("TextLabel") then
                v.LayoutOrder = i+2
            end
        end
        
    end

    function arrayListApi.SetScale(scale) 
        ArrayList.Size = UDim2.new(0, 329, 0, 372 * scale)
    end
end

arrayListWindow.CreateSlider({
    Name = "scale",
    Min = 0.5,
    Max = 2,
    Default = 1,
    Round = 1,
    Function = function(value)
        arrayListApi.SetScale(value)
    end,
})
GuiLibrary.ButtonUpdate:Connect(function(name, enabled, wasKeyDown) 
    arrayListApi.handleEntry(name, enabled, wasKeyDown)
end)
arrayListWindow.CreateToggle({
    Name = "watermark", 
    Function = function(callback)
        arrayListApi.Watermark.Visible = callback
    end,
    Default = true
})
local CustomText = arrayListWindow.CreateToggle({
    Name = "custom text",
    Function = function(callback)
        if arrayListApi.WatermarkText.Text ~= "" then
            arrayListApi.WatermarkText.Visible = callback
        else
            arrayListApi.WatermarkText.Visible = false
        end
    end,
})
arrayListWindow.CreateTextbox({
    Name = "custom text",
    Function = function(value)
        arrayListApi.WatermarkText.Text = value
        if value == "" then
            arrayListApi.WatermarkText.Visible = false
        else
            if CustomText.Enabled then 
                arrayListApi.WatermarkText.Visible = true
            end
        end
    end,
})


do 
    local Keystrokes = keyStrokesWindow.new("Frame")
    Keystrokes.Name = "Keystrokes"
    Keystrokes.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Keystrokes.BackgroundTransparency = 1.000
    Keystrokes.Position = UDim2.new(0, 0, 0, 0)
    Keystrokes.Size = UDim2.new(0, 230, 0, 260)
    local KeyW = Instance.new("Frame")
    KeyW.Name = "KeyW"
    KeyW.Parent = Keystrokes
    KeyW.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
    KeyW.BorderSizePixel = 0
    KeyW.BorderColor3 = Color3.fromRGB(0,0,0)
    KeyW.Position = UDim2.new(0.344901353, 0, 0, -0.03)
    KeyW.Size = UDim2.new(0.301369876, 0, 0.26, 0)
    local Text = Instance.new("TextLabel")
    Text.Name = "Text"
    Text.Parent = KeyW
    Text.AnchorPoint = Vector2.new(0.5, 0.5)
    Text.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Text.BackgroundTransparency = 1.000
    Text.Position = UDim2.new(0.5, 0, 0.5, 0)
    Text.Size = UDim2.new(0.600000024, 0, 0.600000024, 0)
    Text.Font = Enum.Font.Code
    Text.Text = "w"
    Text.TextColor3 = Color3.fromRGB(255, 255, 255)
    Text.TextScaled = true
    Text.TextSize = 16.000
    Text.TextWrapped = true
    local KeyS = Instance.new("Frame")
    KeyS.Name = "KeyS"
    KeyS.Parent = Keystrokes
    KeyS.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
    KeyS.BorderSizePixel = 0
    KeyS.BorderColor3 = Color3.fromRGB(0,0,0)
    KeyS.Position = UDim2.new(0.344901383, 0, 0.26, 0)
    KeyS.Size = UDim2.new(0.301369876, 0, 0.266, 0)
    local Text_2 = Instance.new("TextLabel")
    Text_2.Name = "Text"
    Text_2.Parent = KeyS
    Text_2.AnchorPoint = Vector2.new(0.5, 0.5)
    Text_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Text_2.BackgroundTransparency = 1.000
    Text_2.Position = UDim2.new(0.5, 0, 0.5, 0)
    Text_2.Size = UDim2.new(0.600000024, 0, 0.600000024, 0)
    Text_2.Font = Enum.Font.Code
    Text_2.Text = "s"
    Text_2.TextColor3 = Color3.fromRGB(255, 255, 255)
    Text_2.TextScaled = true
    Text_2.TextSize = 16.000
    Text_2.TextWrapped = true
    local KeyD = Instance.new("Frame")
    KeyD.Name = "KeyD"
    KeyD.Parent = Keystrokes
    KeyD.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
    KeyD.BorderSizePixel = 0
    KeyD.BorderColor3 = Color3.fromRGB(0,0,0)
    KeyD.Position = UDim2.new(0.646271288, 0, 0.26, 0)
    KeyD.Size = UDim2.new(0.301369876, 0, 0.266, 0)
    local Text_3 = Instance.new("TextLabel")
    Text_3.Name = "Text"
    Text_3.Parent = KeyD
    Text_3.AnchorPoint = Vector2.new(0.5, 0.5)
    Text_3.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Text_3.BackgroundTransparency = 1.000
    Text_3.Position = UDim2.new(0.5, 0, 0.5, 0)
    Text_3.Size = UDim2.new(0.600000024, 0, 0.600000024, 0)
    Text_3.Font = Enum.Font.Code
    Text_3.Text = "d"
    Text_3.TextColor3 = Color3.fromRGB(255, 255, 255)
    Text_3.TextScaled = true
    Text_3.TextSize = 16.000
    Text_3.TextWrapped = true
    local KeyA = Instance.new("Frame")
    KeyA.Name = "KeyA"
    KeyA.Parent = Keystrokes
    KeyA.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
    KeyA.BorderSizePixel = 0
    KeyA.BorderColor3 = Color3.fromRGB(0,0,0)
    KeyA.Position = UDim2.new(0.0435315035, 0, 0.26, 0)
    KeyA.Size = UDim2.new(0.301369876, 0, 0.266, 0)
    local Text_4 = Instance.new("TextLabel")
    Text_4.Name = "Text"
    Text_4.Parent = KeyA
    Text_4.AnchorPoint = Vector2.new(0.5, 0.5)
    Text_4.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Text_4.BackgroundTransparency = 1.000
    Text_4.Position = UDim2.new(0.5, 0, 0.5, 0)
    Text_4.Size = UDim2.new(0.600000024, 0, 0.600000024, 0)
    Text_4.Font = Enum.Font.Code
    Text_4.Text = "a"
    Text_4.TextColor3 = Color3.fromRGB(255, 255, 255)
    Text_4.TextScaled = true
    Text_4.TextSize = 16.000
    Text_4.TextWrapped = true
    local KeySpace = Instance.new("Frame")
    KeySpace.Name = "KeySpace"
    KeySpace.Parent = Keystrokes
    KeySpace.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
    KeySpace.BorderSizePixel = 0
    KeySpace.BorderColor3 = Color3.fromRGB(0,0,0)
    KeySpace.Position = UDim2.new(0.0433132015, 0, 0.767, 0)
    KeySpace.Size = UDim2.new(0.904328346, 0, 0.19, 0)
    local Text_5 = Instance.new("TextLabel")
    Text_5.Name = "Text"
    Text_5.Parent = KeySpace
    Text_5.AnchorPoint = Vector2.new(0.5, 0.5)
    Text_5.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Text_5.BackgroundTransparency = 1.000
    Text_5.Position = UDim2.new(0.499999374, 0, 0.421568632, 0)
    Text_5.Size = UDim2.new(0.866666317, 0, 0.843137264, 0)
    Text_5.Font = Enum.Font.Code
    Text_5.Text = "space"
    Text_5.TextColor3 = Color3.fromRGB(255, 255, 255)
    Text_5.TextScaled = true
    Text_5.TextSize = 16.000
    Text_5.TextWrapped = true
    Text_5.TextYAlignment = Enum.TextYAlignment.Top
    local LMB = Instance.new("Frame")
    LMB.Name = "lmb"
    LMB.Parent = Keystrokes
    LMB.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
    LMB.BorderSizePixel = 0
    LMB.BorderColor3 = Color3.fromRGB(0,0,0)
    LMB.Position = UDim2.new(0.043, 0, 0.526, 0)
    LMB.Size = UDim2.new(0.453, 0, 0.241, 0)
    local Text_6 = Instance.new("TextLabel")
    Text_6.Name = "Text"
    Text_6.Parent = LMB
    Text_6.AnchorPoint = Vector2.new(0.5, 0.5)
    Text_6.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Text_6.BackgroundTransparency = 1.000
    Text_6.Position = UDim2.new(0.490401864, 0, 0.396265358, 0)
    Text_6.Size = UDim2.new(0.600000024, 0, 0.456367731, 0)
    Text_6.Font = Enum.Font.Code
    Text_6.Text = "lmb"
    Text_6.TextColor3 = Color3.fromRGB(255, 255, 255)
    Text_6.TextScaled = true
    Text_6.TextSize = 16.000
    Text_6.TextWrapped = true
    local CPS = Instance.new("TextLabel")
    CPS.Name = "CPS"
    CPS.Parent = LMB
    CPS.AnchorPoint = Vector2.new(0.5, 0.5)
    CPS.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    CPS.BackgroundTransparency = 1.000
    CPS.Position = UDim2.new(0.490401864, 0, 0.66377002, 0)
    CPS.Size = UDim2.new(0.600000024, 0, 0.272459656, 0)
    CPS.Font = Enum.Font.Code
    CPS.Text = "[0]"
    CPS.TextColor3 = Color3.fromRGB(255, 255, 255)
    CPS.TextScaled = true
    CPS.TextSize = 16.000
    CPS.TextWrapped = true
    local RMB = Instance.new("Frame")
    RMB.Name = "rmb"
    RMB.Parent = Keystrokes
    RMB.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
    RMB.BorderSizePixel = 0
    RMB.BorderColor3 = Color3.fromRGB(0,0,0)
    RMB.Position = UDim2.new(0.495999813, 0, 0.526000023, 0)
    RMB.Size = UDim2.new(0.451641679, 0, 0.240999997, 0)
    local Text_7 = Instance.new("TextLabel")
    Text_7.Name = "Text"
    Text_7.Parent = RMB
    Text_7.AnchorPoint = Vector2.new(0.5, 0.5)
    Text_7.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Text_7.BackgroundTransparency = 1.000
    Text_7.Position = UDim2.new(0.490372986, 0, 0.396265358, 0)
    Text_7.Size = UDim2.new(0.600000024, 0, 0.456367731, 0)
    Text_7.Font = Enum.Font.Code
    Text_7.Text = "rmb"
    Text_7.TextColor3 = Color3.fromRGB(255, 255, 255)
    Text_7.TextScaled = true
    Text_7.TextSize = 16.000
    Text_7.TextWrapped = true
    local CPS_2 = Instance.new("TextLabel")
    CPS_2.Name = "CPS"
    CPS_2.Parent = RMB
    CPS_2.AnchorPoint = Vector2.new(0.5, 0.5)
    CPS_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    CPS_2.BackgroundTransparency = 1.000
    CPS_2.Position = UDim2.new(0.490372986, 0, 0.66377002, 0)
    CPS_2.Size = UDim2.new(0.600000024, 0, 0.272459656, 0)
    CPS_2.Font = Enum.Font.Code
    CPS_2.Text = "[0]"
    CPS_2.TextColor3 = Color3.fromRGB(255, 255, 255)
    CPS_2.TextScaled = true
    CPS_2.TextSize = 16.000
    CPS_2.TextWrapped = true
    keystrokesAPI.Instance = Keystrokes

    local function highlight(inst, state) 
        inst.BackgroundColor3 = state == true and Color3.fromRGB(17, 17, 17) or Color3.fromRGB(51, 51, 51)
    end

    local keystrokes = {
        W = KeyW,
        A = KeyA,
        S = KeyS,
        D = KeyD,
        Space = KeySpace,
        MouseButton1 = LMB,
        MouseButton2 = RMB,
        MouseButton1CPS = CPS,
        MouseButton2CPS = CPS_2
    }

    keystrokesAPI.Objects = keystrokes

    for i,v in next, keystrokes do 
        local label = (v.ClassName:find("Text") and v) or v:FindFirstChild("Text")
        GuiLibrary.utils:connection(GuiLibrary.ColorUpdate:Connect(function()
            label.TextColor3 = GuiLibrary.utils:getColorOfObject(v)
        end))
    end

    local clicks = {
        MouseButton1 = 0,
        MouseButton2 = 0,
    }

    function keystrokesAPI.handleInput(input, down)
        if typeof(keystrokes[input.KeyCode.Name]) == 'Instance' then 
            highlight(keystrokes[input.KeyCode.Name], down)
        elseif typeof(keystrokes[input.UserInputType.Name]) == 'Instance' then 
            highlight(keystrokes[input.UserInputType.Name], down)
            keystrokesAPI.updateCPS()
            if not down then
                clicks[input.UserInputType.Name] += 1
                keystrokesAPI.updateCPS()
                coroutine.wrap(function() 
                    task.wait(1)
                    clicks[input.UserInputType.Name] -= 1
                    keystrokesAPI.updateCPS()
                end)()
            end
        end
    end
    
    function keystrokesAPI.updateCPS() 
        for i,v in next, clicks do 
            local cps = keystrokes[i.."CPS"]
            cps.Text = "["..tostring(v).."]"
        end
    end

    function keystrokesAPI.init() 
        coroutine.wrap(function()
            task.wait(0.01)
            keystrokesAPI.Connection = game:GetService("UserInputService").InputBegan:Connect(function(i) keystrokesAPI.handleInput(i,false) end)
            keystrokesAPI.Connection2 = game:GetService("UserInputService").InputEnded:Connect(function(i) keystrokesAPI.handleInput(i, true) end)
        end)()
    end

end

keyStrokesToggle = HUDButton.CreateToggle({
    Name = "keystrokes",
    Function = function(callback) 
        if HUDButton.Enabled then
            keyStrokesWindow.Instance.Visible = callback
        end

        if callback then 
            keystrokesAPI.init()
        else
            if keystrokesAPI.Connection then 
                keystrokesAPI.Connection:Disconnect()  
                keystrokesAPI.Connection = nil
            end
            if keystrokesAPI.Connection2 then 
                keystrokesAPI.Connection2:Disconnect()  
                keystrokesAPI.Connection2 = nil
            end
        end
    end
})

keyStrokesWindow.CreateSlider({
    Name = "scale",
    Default = 1,
    Min = 0.1,
    Max = 2,
    Round = 1,
    Function = function(value) 
        keystrokesAPI.Instance.Size = UDim2.new(0, 230 * value, 0, 260 * value)
    end
})

keyStrokesWindow.CreateSlider({
    Name = "transparency",
    Default = 0,
    Min = 0,
    Max = 100,
    Round = 0,
    Function = function(value) 
        for i,v in next, keystrokesAPI.Objects do 
            if i:find("CPS") then continue end
            v.Transparency = value / 100
        end
    end
})

local universal = funcs:run(funcs:getUniversalScript())
local gameScript = funcs:run(funcs:getPlaceScript())
local privateScript = funcs:run(funcs:getPrivateScript())
function funcs:saveConfig() 
    if not engoware then 
        return
    end

    local configName = "default"
    local path = "engoware/configs/" .. funcs:getPlaceIdentifier() .. "/"
    local configPath = path .. configName .. ".json"

    local config = {}

    for i,v in next, GuiLibrary.Objects do 
        if v.Type == 'OptionsButton' then 
            config[i] = {Enabled = v.API.Enabled, Bind = v.API.Bind, Type = v.Type, Window = v.Window}
        elseif v.Type == 'Toggle' then
            config[i] = {Enabled = v.API.Enabled, Type = v.Type, OptionsButton = v.OptionsButton, CustomWindow = v.CustomWindow}
        elseif v.Type == 'Slider' then
            config[i] = {Value = v.API.Value, Type = v.Type, OptionsButton = v.OptionsButton, CustomWindow = v.CustomWindow}
        elseif v.Type == 'Dropdown' then
            config[i] = {Value = v.API.Value, Type = v.Type, OptionsButton = v.OptionsButton, CustomWindow = v.CustomWindow}
        elseif v.Type == 'Textbox' then
            config[i] = {Value = v.API.Value, Type = v.Type, OptionsButton = v.OptionsButton, CustomWindow = v.CustomWindow}
        elseif v.Type == 'MultiDropdown' then
            local values = v.API.Values
            for i,v in next, values do 
                v.Instance = nil
                v.SelectedInstance = nil
            end
            config[i] = {Values = values, Type = v.Type, OptionsButton = v.OptionsButton, CustomWindow = v.CustomWindow}
        elseif v.Type == 'Textlist' then
            config[i] = {Values = v.API.Values, Type = v.Type, OptionsButton = v.OptionsButton, CustomWindow = v.CustomWindow}
        elseif v.Type == 'CustomWindow' then
            config[i] = {Position = {X = {Scale = v.Instance.Position.X.Scale, Offset = v.Instance.Position.X.Offset}, Y = {Scale = v.Instance.Position.Y.Scale, Offset = v.Instance.Position.Y.Offset}}, Type = v.Type}
        end
    end

    makefolder(path)
    if isfile(configPath) then 
        delfile(configPath)
    end

    local success, returned = pcall(function() 
        return game:GetService("HttpService"):JSONEncode(config)
    end)

    if success then 
        writefile(configPath, returned)
    else
        warn("[engoware] failed to save config: " .. returned)
    end

    repeat task.wait() until isfile(configPath)
end

function funcs:loadConfig() 
    if not engoware then 
        return
    end

    local configName = "default"
    local path = "engoware/configs/" .. funcs:getPlaceIdentifier() .. "/"
    local configPath = path .. configName .. ".json"

    if not isfile(configPath) then 
        return
    end

    local success, returned = pcall(function() 
        return game:GetService("HttpService"):JSONDecode(readfile(configPath))
    end)

    if not success then 
        return warn("[engoware] failed to load config: " .. returned)
    end
    for i,v in next, returned do 
        local prop = v.Type == 'OptionsButton' and 'Window' or v.CustomWindow and 'CustomWindow' or 'OptionsButton'
        local object = funcs:getObject(i, prop, v[prop])
        if not object then 
            continue 
        end

        if v.Type == 'OptionsButton' then 
            if v.Bind and v.Bind ~= "" then
                object.API.SetBind(v.Bind)
            end
            if v.Enabled then
                object.API.Toggle()
            end
        elseif v.Type == 'Toggle' then
            if v.Enabled ~= object.API.Enabled then
                object.API.Toggle()
            end
        elseif v.Type == 'Slider' then
            object.API.Set(v.Value, true)
        elseif v.Type == 'Dropdown' then
            object.API.SetValue(v.Value)
        elseif v.Type == 'Textbox' then
            object.API.Set(v.Value)
        elseif v.Type == 'MultiDropdown' then
            for i,v in next, v.Values do 
                if v.Enabled then
                    object.API.ToggleValue(v.Value)
                end
            end
        elseif v.Type == 'Textlist' then
            for i,v in next, v.Values do 
                object.API.Add(v)
            end
        elseif v.Type == 'CustomWindow' then
            object.Instance.Position = UDim2.new(v.Position.X.Scale, v.Position.X.Offset, v.Position.Y.Scale, v.Position.Y.Offset)
        end
    end

end
funcs:loadConfig()

local teleportConnection = lplr.OnTeleport:Connect(function(State)
    if State == Enum.TeleportState.Started then
		local stringtp = [[
            if engoware_developer then 
                loadstring(readfile("engoware/Main.lua"))()
            else 
                loadstring(game:HttpGet("https://raw.githubusercontent.com/joeengo/engoware/main/Main.lua", true))() 
            end
        ]]
		queueteleport(stringtp)
        funcs:saveConfig()
    end
end)

local playerRemovingConnection = Players.PlayerRemoving:Connect(function(player)
    if player == lplr then 
        funcs:saveConfig()
    end
end)

coroutine.wrap(function() 
    repeat 
        for i = 1, 50 do 
            task.wait(0.1)
            if not engoware then 
                break
            end
        end
        funcs:saveConfig()
    until not engoware
end)()

engoware.UninjectEvent.Event:Connect(function() 
    funcs:saveConfig()
    getgenv().engoware = nil
    for i,v in next, GuiLibrary.Objects do 
        if v.Type == 'OptionsButton' and v.API.Enabled then 
            v.API.Toggle()
        end
        if v.Type == 'Toggle' and v.API.Enabled then 
            v.API.Toggle()
        end
    end
    teleportConnection:Disconnect()
    playerRemovingConnection:Disconnect()
    for i,v in next, GuiLibrary.Connections do 
        v:Disconnect()
    end
    GuiLibrary.ScreenGui:Destroy()
end)

if engoware_developer then
    print("[engoware] loaded in " .. tostring(tick() - startTick) .. "s.")
end    written by: @engo#0320

]]

if not game:IsLoaded() then 
    game.Loaded:Wait()
end

local startTick = tick()

local request = (syn and syn.request) or request or http_request or (http and http.request)
local queueteleport = syn and syn.queue_on_teleport or queue_on_teleport or fluxus and fluxus.queue_on_teleport
local setthreadidentityfunc = syn and syn.set_thread_identity or set_thread_identity or setidentity or setthreadidentity
local getthreadidentityfunc = syn and syn.get_thread_identity or get_thread_identity or getidentity or getthreadidentity
local UIS = game:GetService("UserInputService")
local ts = game:GetService("TweenService")
local Players = game:GetService("Players")
local lplr = Players.LocalPlayer
local entity, GuiLibrary
local override = {
    [6872265039] = "bedwars_lobby",
    [8444591321] = "bedwars",
    [6872274481] = "bedwars",
    [8560631822] = "bedwars",
    [863266079] = "ar2"
}
local funcs = {}; do
    function funcs:require(url, bypass, bypass2)
        if (not url:match("http")) and isfile(url) then
            return readfile(url)
        end

        local newUrl = (bypass and "https://raw.githubusercontent.com/joeengo/" or "https://raw.githubusercontent.com/joeengo/engoware/main/") .. url:gsub("engoware/", ""):gsub("engoware\\", "")
        local response = request({
            Url = bypass2 and url or newUrl,
            Method = "GET",
        })
        if response.StatusCode == 200 then
            return response.Body
        end
    end

    function funcs:getPlaceIdentifier() 
        return tostring(override[game.PlaceId] or game.PlaceId)
    end

    function funcs:getPlaceScript() 
        local placeId = funcs:getPlaceIdentifier()
        local scriptName = (placeId .. ".lua")
        if scriptName then
            local path = "engoware/games/" .. scriptName
            return funcs:require(path) or ""
        end
    end

    function funcs:getUniversalScript()
        return funcs:require("engoware/games/universal.lua")
    end

    function funcs:getPrivateScript() 
        local placeId = funcs:getPlaceIdentifier()
        local scriptName = (placeId .. ".lua")
        if scriptName then
            local path = "engoware/private/" .. scriptName
            return funcs:require(path) or ""
        end
    end

    function funcs:run(code) 
        local func, err = loadstring(code)
        if not typeof(func) == 'function' then
            return warn("Failed to run code, error: " .. tostring(err))
        end
        return func()
    end

    function funcs:wlfind(tab, obj) 
        for i,v in next, tab do
            if v == obj or type(v) == "table" and v.hash == obj then
                return v
            end
        end
    end

    function funcs:connection(...) 
        return GuiLibrary.utils:connection(...)
    end

    function funcs:getObject(objectName, prop, val) 
        for i,v in next, GuiLibrary.Objects do 
            if i == objectName and v[prop] == val then 
                return v
            end
        end
    end

    local loops = {RenderStepped = {}, Heartbeat = {}, Stepped = {}}
    function funcs:bindToStepped(id, callback)
        if not loops.Stepped[id] then 
            loops.Stepped[id] = game:GetService("RunService").Stepped:Connect(callback)
        else
            warn("[engoware] attempt to bindToStepped to an already bound id: " .. tostring(id))
        end
    end

    function funcs:unbindFromStepped(id)
        if loops.Stepped[id] then
            loops.Stepped[id]:Disconnect()
            loops.Stepped[id] = nil
        end
    end

    function funcs:bindToRenderStepped(id, callback)
        if not loops.RenderStepped[id] then 
            loops.RenderStepped[id] = game:GetService("RunService").RenderStepped:Connect(callback)
        else
            warn("[engoware] attempt to bindToRenderStepped to an already bound id: " .. tostring(id))
        end
    end

    function funcs:unbindFromRenderStepped(id)
        if loops.RenderStepped[id] then
            loops.RenderStepped[id]:Disconnect()
            loops.RenderStepped[id] = nil
        end
    end

    function funcs:bindToHeartbeat(id, callback)
        if not loops.Heartbeat[id] then 
            loops.Heartbeat[id] = game:GetService("RunService").Heartbeat:Connect(callback)
        else
            warn("[engoware] attempt to bindToHeartbeat to an already bound id: " .. tostring(id))
        end
    end

    function funcs:unbindFromHeartbeat(id)
        if loops.Heartbeat[id] then
            loops.Heartbeat[id]:Disconnect()
            loops.Heartbeat[id] = nil
        end
    end

    function funcs:isAlive(plr: Player, stateCheck: boolean) 
        if not plr then 
            return entity.isAlive
        end

        local _, ent = entity.getEntityFromPlayer(plr)
        return ((not stateCheck) or ent and ent.Humanoid:GetState() ~= Enum.HumanoidStateType.Dead) and ent
    end 

    function funcs:isTargetable(plr: Player) 
        return funcs:isAlive(plr, true) and (plr.Character) and (not plr.Character:FindFirstChildOfClass("ForceField"))
    end

    function funcs:getClosestEntity(maxDist: number, teamCheck: boolean)
        local maxDist, val = maxDist or 9e9, nil
        if funcs:isAlive() then
            for i,v in next, entity.entityList do 
                if (v.Targetable or not teamCheck) and funcs:isTargetable(v.Player) then 
                    local dist = (lplr.Character.HumanoidRootPart.Position - v.HumanoidRootPart.Position).Magnitude
                    if dist < maxDist then
                        maxDist, val = dist, v
                    end
                end
            end
        end
        return val
    end

    function funcs:getClosestEntityToMouse(maxDist: number, teamCheck: boolean, visCheck: boolean, visTable: table)
        local maxDist, val = maxDist or 9e9, nil
        if funcs:isAlive() then
            for i,v in next, entity.entityList do 
                if (v.Targetable or not teamCheck) and funcs:isTargetable(v.Player) then 
                    local Position, Visible = workspace.CurrentCamera:WorldToViewportPoint(v[visTable.TargetPart].Position)
                    if (not visTable.SkipVisible) and (not Visible) then 
                        continue
                    end

                    local Params = RaycastParams.new()
                    Params.FilterDescendantsInstances = {v.Character, workspace.CurrentCamera, lplr.Character, unpack(visTable.Ignore)}
                    Params.FilterType = Enum.RaycastFilterType.Blacklist
                    local Ray = workspace:Raycast(visTable.Origin, v[visTable.TargetPart].Position - visTable.Origin, Params)
                    local AreVisible = Ray and Ray.Instance == nil or not Ray
                    if visCheck and (not AreVisible) then
                        continue
                    end

                    local dist2 = (entity.character.HumanoidRootPart.Position - v.HumanoidRootPart.Position).Magnitude
                    if visTable.MaxDist and dist2 > (visTable.MaxDist) then
                        continue
                    end

                    if visTable.Checks then
                        for i,check in next, visTable.Checks do 
                            if not check(visTable.Origin, v[visTable.TargetPart].Position - visTable.Origin) then
                                continue
                            end
                        end
                    end

                    local dist = (UIS:GetMouseLocation() - Vector2.new(Position.X, Position.Y)).Magnitude
                    if dist < maxDist then
                        maxDist, val = dist, v
                    end
                end
            end
        end
        return val
    end

    function funcs:getSortedEntities(maxDist: number, maxEntities: number, teamCheck: boolean, sortFunction)
        local maxDist, maxEntities, val = maxDist or 9e9, maxEntities or 9e9, {}
        if not funcs:isAlive() then
            maxDist = 99e99
        end
        
        local selfPos = funcs:isAlive() and entity.character.HumanoidRootPart.Position or Vector3.zero
        for i,v in next, entity.entityList do 
            if (v.Targetable or not teamCheck) and funcs:isTargetable(v.Player) then 
                local dist = (selfPos - v.HumanoidRootPart.Position).Magnitude
                if dist < maxDist then
                    table.insert(val, v)
                end
            end
        end

        local sortFunction = sortFunction or function(ent1, ent2)
            return (selfPos - ent1.HumanoidRootPart.Position).Magnitude < (selfPos - ent2.HumanoidRootPart.Position).Magnitude
        end
        table.sort(val, sortFunction)

        if #val > maxEntities then
            return table.move(val, 1, maxEntities, 1, {})
        end

        return val
    end

    function funcs:getEnemyColor(isEnemy) 
        if isEnemy then
            return Color3.new(1, 0.427450, 0.427450)
        end
        return Color3.new(0.470588, 1, 0.470588)
    end

    function funcs:getColorFromEntity(ent, useTeamColor, useColorTheme) 
        if ent.Team and ent.Team.TeamColor.Color and useTeamColor then
            return ent.Team.TeamColor.Color
        end

        if useColorTheme then 
            return GuiLibrary.utils:getColor()
        end

        return funcs:getEnemyColor(ent.Targetable)
    end

    function funcs:newWorker() 
        local worker = {}
        local tasks = {}
        worker.tasks = tasks
        function worker:add(x) 
            table.insert(tasks, x)
        end
        function worker:clean() 
            for i,v in next, tasks do 
                local typeOf = typeof(v)
                if typeOf == 'Instance' then 
                    v:Destroy()
                elseif typeOf == 'table' then
                    if v.__OBJECT and v.__OBJECT_EXISTS then 
                        v:Remove()
                    end
                elseif typeOf == 'RBXScriptConnection' then
                    if v.Connected then
                        v:Disconnect()
                    end
                elseif typeOf == 'function' then
                    v()
                end
                tasks[i] = nil
            end
        end
        return worker
    end

    function funcs:curve(p0, p1, p2, p3, t)
        local t2 = t * t
        local t3 = t2 * t
        return p0 * (1 - 3 * t + 3 * t2 - t3) + p1 * (3 * t - 6 * t2 + 3 * t3) + p2 * (3 * t2 - 3 * t3) + p3 * t3
    end

    function funcs:lookat(p, smooth) 
        local smooth = smooth + 1
        local targetPos = workspace.CurrentCamera:WorldToScreenPoint(p)
        local mousePos = workspace.CurrentCamera:WorldToScreenPoint(lplr:GetMouse().Hit.p)
        mousemoverel((targetPos.X-mousePos.X) / smooth,( targetPos.Y - mousePos.Y) / smooth)
    end

    local function createAngleInc(Start, DefaultInc, Goal) 
        local i = Start or 0
        return function(Inc) 
            local Inc = Inc or DefaultInc or 1
            i = math.clamp(i + Inc, Start, Goal)
            return i
        end
    end
    
    function funcs:orbit(Self, Target, Radius, Delay, Speed, StopIf)
        local AngleInc = createAngleInc(0, Speed, 360)
        for i = 1, 360 / Speed do
            local Angle = AngleInc(Speed)
            Self.CFrame = CFrame.new(Target.CFrame.p) * CFrame.Angles(0, math.rad(Angle), 0) * CFrame.new(0, 0.1, Radius)
            task.wait(Delay)
            if StopIf and StopIf() then
                return
            end
        end
    end

    function funcs:tweenNumber(start, goal, time, func, _end) 
        local start, goal, time = start or 0, goal or 1, time or 1
        local worker = funcs:newWorker()
        local N = Instance.new("NumberValue")
        N.Parent = engoware.GuiLibrary.ScreenGui
        N.Value = start
        N.Name = "TweeningNumber"
        worker:add(N.Changed:Connect(function(value)
            func(value)
        end))
        local t = ts:Create(N, TweenInfo.new(), {Value = goal})
        t:Play()
        worker:add(t.Completed:Connect(function()
            worker:clean()
            N:Destroy()
            _end()
        end))
    end
end

if not getgenv or (identifyexecutor and identifyexecutor():find("Arceus")) then
    return warn("[engoware] unsupported executor.")
end

if engoware then 
    return warn("[engoware] already loaded.")
end

entity = funcs:run(funcs:require("https://raw.githubusercontent.com/7GrandDadPGN/VapeV4ForRoblox/main/Libraries/entityHandler.lua", true, true))
entity.fullEntityRefresh()
GuiLibrary = funcs:run(funcs:require("engoware/GuiLibrary.lua"))

getgenv().engoware = {}
engoware.UninjectEvent = Instance.new("BindableEvent")
engoware.entity = entity
engoware.GuiLibrary = GuiLibrary
engoware.funcs = funcs
makefolder("engoware")
makefolder("engoware/configs")

local windows = {
    combat = GuiLibrary.CreateWindow({Name = "combat"}),
    exploit = GuiLibrary.CreateWindow({Name = "exploits"}),
    movement = GuiLibrary.CreateWindow({Name = "movement"}),
    utilities = GuiLibrary.CreateWindow({Name = "utilities"}),
    render = GuiLibrary.CreateWindow({Name = "render"}),
    misc = GuiLibrary.CreateWindow({Name = "misc"}),
    other = GuiLibrary.CreateWindow({Name = "other"}),
}

local UninjectButton; UninjectButton = windows.other.CreateOptionsButton({
    Name = "uninject",
    Function = function(callback)
        if callback then
            UninjectButton.Toggle()
            engoware.UninjectEvent:Fire()
        end
    end
})

local guiButton = windows.other.CreateOptionsButton({
    Name = "gui",
    Function = function(callback) 
        GuiLibrary.ClickGUI.Visible = callback
    end,
    Bind = "RightShift",
})
GuiLibrary.ClickGUI.Visible = false

local canScale = guiButton.CreateToggle({
    Name = "canScale",
    Function = function(callback)
        GuiLibrary.canScale = callback
    end,
    Default = true
})

local colorButton; colorButton = windows.other.CreateOptionsButton({
    Name = "colors",
    Function = function(callback)
        if not callback then
            colorButton.Toggle()
        end
    end,
})
if not colorButton.Enabled then
    colorButton.Toggle()
end

local hueSlider
local satSlider
local valSlider
local rainbowSmoothSlider
local rainbowToggle = colorButton.CreateToggle({
    Name = "rainbow",
    Function = function(callback)
        GuiLibrary.Rainbow = callback
        if not callback then
            GuiLibrary.utils:setColorTheme({H = hueSlider.Value / 360, S = satSlider.Value / 100, V = valSlider.Value / 100})
        end
    end,
})

rainbowSmoothSlider = colorButton.CreateSlider({
    Name = "rainbow smoothness",
    Function = function(value)
        GuiLibrary.RainbowSmoothness = value * 75
    end,
    Min = 10,
    Max = 100,
    Default = 23,
})

hueSlider = colorButton.CreateSlider({
    Name = "hue",
    Function = function(value)
        if GuiLibrary.Rainbow then 
            return
        end
        local old = GuiLibrary.utils:getColorTheme(true)
        GuiLibrary.utils:setColorTheme({
            H = value / 360,
            S = old.S,
            V = old.V,
        })
    end,
    Min = 0,
    Max = 360,
    Round = 0,
    Default = 150,
})

satSlider = colorButton.CreateSlider({
    Name = "sat",
    Function = function(value)
        local old = GuiLibrary.utils:getColorTheme(true)
        GuiLibrary.utils:setColorTheme({
            H = old.H,
            S = value / 100,
            V = old.V,
        })
    end,
    Min = 0,
    Max = 100,
    Round = 0,
    Default = 100,
})

valSlider = colorButton.CreateSlider({
    Name = "val",
    Function = function(value)
        local old = GuiLibrary.utils:getColorTheme(true)
        GuiLibrary.utils:setColorTheme({
            H = old.H,
            S = old.S,
            V = value / 100,
        })
    end,
    Min = 0,
    Max = 100,
    Round = 0,
    Default = 100,
})

local arrayListApi = {}
local arrayListWindow = GuiLibrary.CreateCustomWindow({
    Name = "array list",
})
local arrayListToggle = {}

local keyStrokesToggle = {}
local keystrokesAPI = {}
local keyStrokesWindow = GuiLibrary.CreateCustomWindow({Name = "keystrokes"})

local HUDButton = windows.other.CreateOptionsButton({
    Name = "hud",
    Function = function(callback)
        if arrayListToggle.Enabled then
            arrayListWindow.Instance.Visible = callback
        end
        if keyStrokesToggle.Enabled then
            keyStrokesWindow.Instance.Visible = callback
        else
            keyStrokesWindow.Instance.Visible = false
            if keystrokesAPI.Connection then 
                keystrokesAPI.Connection:Disconnect()  
                keystrokesAPI.Connection = nil
            end
            if keystrokesAPI.Connection2 then 
                keystrokesAPI.Connection2:Disconnect()  
                keystrokesAPI.Connection2 = nil
            end
        end
    end,
})
arrayListToggle = HUDButton.CreateToggle({
    Name = "array list",
    Function = function(callback)
        if HUDButton.Enabled then
            arrayListWindow.Instance.Visible = callback
        end
    end,
})

do 
    local ArrayList = arrayListWindow.new("Frame")
    ArrayList.Name = "ArrayList"
    ArrayList.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ArrayList.BackgroundTransparency = 1.000
    ArrayList.Position = UDim2.new(-0.551886797, 0, 0, 0)
    ArrayList.Size = UDim2.new(0, 329, 0, 372)
    arrayListApi.ArrayListInstance = ArrayList
    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.Parent = ArrayList
    UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    local Watermark = Instance.new("TextLabel")
    Watermark.Name = "Watermark"
    Watermark.Parent = ArrayList
    Watermark.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Watermark.BackgroundTransparency = 1.000
    Watermark.Position = UDim2.new(-0.887538016, 0, 0.161490679, 0)
    Watermark.Size = UDim2.new(0, 621, 0.1556832382, 0)
    Watermark.Font = Enum.Font.Code
    Watermark.Text = "engoware"
    Watermark.TextColor3 = GuiLibrary.utils:getColorOfObject(Watermark)
    GuiLibrary.utils:connection(GuiLibrary.ColorUpdate:Connect(function()
        Watermark.TextColor3 = GuiLibrary.utils:getColorOfObject(Watermark)
    end))
    Watermark.TextScaled = true
    Watermark.TextSize = 14.000
    Watermark.TextStrokeTransparency = 0
    Watermark.TextWrapped = true
    Watermark.TextXAlignment = Enum.TextXAlignment.Right
    arrayListApi.Watermark = Watermark
    local WatermarkText = Instance.new("TextLabel")
    WatermarkText.Name = "Watermark"
    WatermarkText.Parent = ArrayList
    WatermarkText.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    WatermarkText.BackgroundTransparency = 1.000
    WatermarkText.Position = UDim2.new(-0.887538016, 0, 0.161490679, 0)
    WatermarkText.Size = UDim2.new(0, 621, 0.0856832382, 0)
    WatermarkText.Font = Enum.Font.Code
    WatermarkText.Text = "Custom Text!"
    WatermarkText.TextColor3 = GuiLibrary.utils:getColorOfObject(WatermarkText)
    GuiLibrary.utils:connection(GuiLibrary.ColorUpdate:Connect(function()
        WatermarkText.TextColor3 = GuiLibrary.utils:getColorOfObject(WatermarkText)
    end))
    WatermarkText.TextScaled = true
    WatermarkText.TextSize = 14.000
    WatermarkText.TextStrokeTransparency = 0
    WatermarkText.TextWrapped = true
    WatermarkText.TextXAlignment = Enum.TextXAlignment.Right
    arrayListApi.WatermarkText = WatermarkText

    function arrayListApi.handleEntry(name, enabled, wasKeyDown) 
        arrayListApi.Objects = arrayListApi.Objects or {}
        local ArrayListModule = arrayListApi.Objects[name] or Instance.new("TextLabel")
        ArrayListModule.Name = "ArrayListModule"
        ArrayListModule.Parent = ArrayList
        ArrayListModule.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ArrayListModule.BackgroundTransparency = 1.000
        ArrayListModule.Position = UDim2.new(-0.887538016, 0, 0.161490679, 0)
        ArrayListModule.Size = UDim2.new(0, 621, 0.0656832382, 0)
        ArrayListModule.Font = Enum.Font.Code
        ArrayListModule.Text = name
        ArrayListModule.TextColor3 = GuiLibrary.utils:getColorOfObject(ArrayListModule)
        GuiLibrary.utils:connection(GuiLibrary.ColorUpdate:Connect(function()
            ArrayListModule.TextColor3 = GuiLibrary.utils:getColorOfObject(ArrayListModule)
        end))
        ArrayListModule.TextScaled = true
        ArrayListModule.TextSize = 14.000
        ArrayListModule.TextStrokeTransparency = 0.500
        ArrayListModule.TextWrapped = true
        ArrayListModule.TextXAlignment = Enum.TextXAlignment.Right
        arrayListApi.Objects[name] = ArrayListModule
        if not enabled then 
            ArrayListModule:Destroy()
            arrayListApi.Objects[name] = nil
        end

        local children = ArrayList:GetChildren()
        table.sort(children, function(a,b)
            if not a:IsA("TextLabel") then 
                return false
            end
            if not b:IsA("TextLabel") then 
                return true
            end
            return a.TextBounds.X > b.TextBounds.X
        end)

        for i,v in next, children do 
            if v.Name:find("Watermark") then
                v.LayoutOrder = (v.Name:find("Text") and 2) or 0
                continue
            end
            if v:IsA("TextLabel") then
                v.LayoutOrder = i+2
            end
        end
        
    end

    function arrayListApi.SetScale(scale) 
        ArrayList.Size = UDim2.new(0, 329, 0, 372 * scale)
    end
end

arrayListWindow.CreateSlider({
    Name = "scale",
    Min = 0.5,
    Max = 2,
    Default = 1,
    Round = 1,
    Function = function(value)
        arrayListApi.SetScale(value)
    end,
})
GuiLibrary.ButtonUpdate:Connect(function(name, enabled, wasKeyDown) 
    arrayListApi.handleEntry(name, enabled, wasKeyDown)
end)
arrayListWindow.CreateToggle({
    Name = "watermark", 
    Function = function(callback)
        arrayListApi.Watermark.Visible = callback
    end,
    Default = true
})
local CustomText = arrayListWindow.CreateToggle({
    Name = "custom text",
    Function = function(callback)
        if arrayListApi.WatermarkText.Text ~= "" then
            arrayListApi.WatermarkText.Visible = callback
        else
            arrayListApi.WatermarkText.Visible = false
        end
    end,
})
arrayListWindow.CreateTextbox({
    Name = "custom text",
    Function = function(value)
        arrayListApi.WatermarkText.Text = value
        if value == "" then
            arrayListApi.WatermarkText.Visible = false
        else
            if CustomText.Enabled then 
                arrayListApi.WatermarkText.Visible = true
            end
        end
    end,
})

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
    local Keystrokes = keyStrokesWindow.new("Frame")
    Keystrokes.Name = "Keystrokes"
    Keystrokes.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Keystrokes.BackgroundTransparency = 1.000
    Keystrokes.Position = UDim2.new(0, 0, 0, 0)
    Keystrokes.Size = UDim2.new(0, 230, 0, 260)
    local KeyW = Instance.new("Frame")
    KeyW.Name = "KeyW"
    KeyW.Parent = Keystrokes
    KeyW.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
    KeyW.BorderSizePixel = 0
    KeyW.BorderColor3 = Color3.fromRGB(0,0,0)
    KeyW.Position = UDim2.new(0.344901353, 0, 0, -0.03)
    KeyW.Size = UDim2.new(0.301369876, 0, 0.26, 0)
    local Text = Instance.new("TextLabel")
    Text.Name = "Text"
    Text.Parent = KeyW
    Text.AnchorPoint = Vector2.new(0.5, 0.5)
    Text.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Text.BackgroundTransparency = 1.000
    Text.Position = UDim2.new(0.5, 0, 0.5, 0)
    Text.Size = UDim2.new(0.600000024, 0, 0.600000024, 0)
    Text.Font = Enum.Font.Code
    Text.Text = "w"
    Text.TextColor3 = Color3.fromRGB(255, 255, 255)
    Text.TextScaled = true
    Text.TextSize = 16.000
    Text.TextWrapped = true
    local KeyS = Instance.new("Frame")
    KeyS.Name = "KeyS"
    KeyS.Parent = Keystrokes
    KeyS.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
    KeyS.BorderSizePixel = 0
    KeyS.BorderColor3 = Color3.fromRGB(0,0,0)
    KeyS.Position = UDim2.new(0.344901383, 0, 0.26, 0)
    KeyS.Size = UDim2.new(0.301369876, 0, 0.266, 0)
    local Text_2 = Instance.new("TextLabel")
    Text_2.Name = "Text"
    Text_2.Parent = KeyS
    Text_2.AnchorPoint = Vector2.new(0.5, 0.5)
    Text_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Text_2.BackgroundTransparency = 1.000
    Text_2.Position = UDim2.new(0.5, 0, 0.5, 0)
    Text_2.Size = UDim2.new(0.600000024, 0, 0.600000024, 0)
    Text_2.Font = Enum.Font.Code
    Text_2.Text = "s"
    Text_2.TextColor3 = Color3.fromRGB(255, 255, 255)
    Text_2.TextScaled = true
    Text_2.TextSize = 16.000
    Text_2.TextWrapped = true
    local KeyD = Instance.new("Frame")
    KeyD.Name = "KeyD"
    KeyD.Parent = Keystrokes
    KeyD.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
    KeyD.BorderSizePixel = 0
    KeyD.BorderColor3 = Color3.fromRGB(0,0,0)
    KeyD.Position = UDim2.new(0.646271288, 0, 0.26, 0)
    KeyD.Size = UDim2.new(0.301369876, 0, 0.266, 0)
    local Text_3 = Instance.new("TextLabel")
    Text_3.Name = "Text"
    Text_3.Parent = KeyD
    Text_3.AnchorPoint = Vector2.new(0.5, 0.5)
    Text_3.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Text_3.BackgroundTransparency = 1.000
    Text_3.Position = UDim2.new(0.5, 0, 0.5, 0)
    Text_3.Size = UDim2.new(0.600000024, 0, 0.600000024, 0)
    Text_3.Font = Enum.Font.Code
    Text_3.Text = "d"
    Text_3.TextColor3 = Color3.fromRGB(255, 255, 255)
    Text_3.TextScaled = true
    Text_3.TextSize = 16.000
    Text_3.TextWrapped = true
    local KeyA = Instance.new("Frame")
    KeyA.Name = "KeyA"
    KeyA.Parent = Keystrokes
    KeyA.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
    KeyA.BorderSizePixel = 0
    KeyA.BorderColor3 = Color3.fromRGB(0,0,0)
    KeyA.Position = UDim2.new(0.0435315035, 0, 0.26, 0)
    KeyA.Size = UDim2.new(0.301369876, 0, 0.266, 0)
    local Text_4 = Instance.new("TextLabel")
    Text_4.Name = "Text"
    Text_4.Parent = KeyA
    Text_4.AnchorPoint = Vector2.new(0.5, 0.5)
    Text_4.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Text_4.BackgroundTransparency = 1.000
    Text_4.Position = UDim2.new(0.5, 0, 0.5, 0)
    Text_4.Size = UDim2.new(0.600000024, 0, 0.600000024, 0)
    Text_4.Font = Enum.Font.Code
    Text_4.Text = "a"
    Text_4.TextColor3 = Color3.fromRGB(255, 255, 255)
    Text_4.TextScaled = true
    Text_4.TextSize = 16.000
    Text_4.TextWrapped = true
    local KeySpace = Instance.new("Frame")
    KeySpace.Name = "KeySpace"
    KeySpace.Parent = Keystrokes
    KeySpace.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
    KeySpace.BorderSizePixel = 0
    KeySpace.BorderColor3 = Color3.fromRGB(0,0,0)
    KeySpace.Position = UDim2.new(0.0433132015, 0, 0.767, 0)
    KeySpace.Size = UDim2.new(0.904328346, 0, 0.19, 0)
    local Text_5 = Instance.new("TextLabel")
    Text_5.Name = "Text"
    Text_5.Parent = KeySpace
    Text_5.AnchorPoint = Vector2.new(0.5, 0.5)
    Text_5.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Text_5.BackgroundTransparency = 1.000
    Text_5.Position = UDim2.new(0.499999374, 0, 0.421568632, 0)
    Text_5.Size = UDim2.new(0.866666317, 0, 0.843137264, 0)
    Text_5.Font = Enum.Font.Code
    Text_5.Text = "space"
    Text_5.TextColor3 = Color3.fromRGB(255, 255, 255)
    Text_5.TextScaled = true
    Text_5.TextSize = 16.000
    Text_5.TextWrapped = true
    Text_5.TextYAlignment = Enum.TextYAlignment.Top
    local LMB = Instance.new("Frame")
    LMB.Name = "lmb"
    LMB.Parent = Keystrokes
    LMB.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
    LMB.BorderSizePixel = 0
    LMB.BorderColor3 = Color3.fromRGB(0,0,0)
    LMB.Position = UDim2.new(0.043, 0, 0.526, 0)
    LMB.Size = UDim2.new(0.453, 0, 0.241, 0)
    local Text_6 = Instance.new("TextLabel")
    Text_6.Name = "Text"
    Text_6.Parent = LMB
    Text_6.AnchorPoint = Vector2.new(0.5, 0.5)
    Text_6.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Text_6.BackgroundTransparency = 1.000
    Text_6.Position = UDim2.new(0.490401864, 0, 0.396265358, 0)
    Text_6.Size = UDim2.new(0.600000024, 0, 0.456367731, 0)
    Text_6.Font = Enum.Font.Code
    Text_6.Text = "lmb"
    Text_6.TextColor3 = Color3.fromRGB(255, 255, 255)
    Text_6.TextScaled = true
    Text_6.TextSize = 16.000
    Text_6.TextWrapped = true
    local CPS = Instance.new("TextLabel")
    CPS.Name = "CPS"
    CPS.Parent = LMB
    CPS.AnchorPoint = Vector2.new(0.5, 0.5)
    CPS.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    CPS.BackgroundTransparency = 1.000
    CPS.Position = UDim2.new(0.490401864, 0, 0.66377002, 0)
    CPS.Size = UDim2.new(0.600000024, 0, 0.272459656, 0)
    CPS.Font = Enum.Font.Code
    CPS.Text = "[0]"
    CPS.TextColor3 = Color3.fromRGB(255, 255, 255)
    CPS.TextScaled = true
    CPS.TextSize = 16.000
    CPS.TextWrapped = true
    local RMB = Instance.new("Frame")
    RMB.Name = "rmb"
    RMB.Parent = Keystrokes
    RMB.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
    RMB.BorderSizePixel = 0
    RMB.BorderColor3 = Color3.fromRGB(0,0,0)
    RMB.Position = UDim2.new(0.495999813, 0, 0.526000023, 0)
    RMB.Size = UDim2.new(0.451641679, 0, 0.240999997, 0)
    local Text_7 = Instance.new("TextLabel")
    Text_7.Name = "Text"
    Text_7.Parent = RMB
    Text_7.AnchorPoint = Vector2.new(0.5, 0.5)
    Text_7.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Text_7.BackgroundTransparency = 1.000
    Text_7.Position = UDim2.new(0.490372986, 0, 0.396265358, 0)
    Text_7.Size = UDim2.new(0.600000024, 0, 0.456367731, 0)
    Text_7.Font = Enum.Font.Code
    Text_7.Text = "rmb"
    Text_7.TextColor3 = Color3.fromRGB(255, 255, 255)
    Text_7.TextScaled = true
    Text_7.TextSize = 16.000
    Text_7.TextWrapped = true
    local CPS_2 = Instance.new("TextLabel")
    CPS_2.Name = "CPS"
    CPS_2.Parent = RMB
    CPS_2.AnchorPoint = Vector2.new(0.5, 0.5)
    CPS_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    CPS_2.BackgroundTransparency = 1.000
    CPS_2.Position = UDim2.new(0.490372986, 0, 0.66377002, 0)
    CPS_2.Size = UDim2.new(0.600000024, 0, 0.272459656, 0)
    CPS_2.Font = Enum.Font.Code
    CPS_2.Text = "[0]"
    CPS_2.TextColor3 = Color3.fromRGB(255, 255, 255)
    CPS_2.TextScaled = true
    CPS_2.TextSize = 16.000
    CPS_2.TextWrapped = true
    keystrokesAPI.Instance = Keystrokes

    local function highlight(inst, state) 
        inst.BackgroundColor3 = state == true and Color3.fromRGB(17, 17, 17) or Color3.fromRGB(51, 51, 51)
    end

    local keystrokes = {
        W = KeyW,
        A = KeyA,
        S = KeyS,
        D = KeyD,
        Space = KeySpace,
        MouseButton1 = LMB,
        MouseButton2 = RMB,
        MouseButton1CPS = CPS,
        MouseButton2CPS = CPS_2
    }

    keystrokesAPI.Objects = keystrokes

    for i,v in next, keystrokes do 
        local label = (v.ClassName:find("Text") and v) or v:FindFirstChild("Text")
        GuiLibrary.utils:connection(GuiLibrary.ColorUpdate:Connect(function()
            label.TextColor3 = GuiLibrary.utils:getColorOfObject(v)
        end))
    end

    local clicks = {
        MouseButton1 = 0,
        MouseButton2 = 0,
    }

    function keystrokesAPI.handleInput(input, down)
        if typeof(keystrokes[input.KeyCode.Name]) == 'Instance' then 
            highlight(keystrokes[input.KeyCode.Name], down)
        elseif typeof(keystrokes[input.UserInputType.Name]) == 'Instance' then 
            highlight(keystrokes[input.UserInputType.Name], down)
            keystrokesAPI.updateCPS()
            if not down then
                clicks[input.UserInputType.Name] += 1
                keystrokesAPI.updateCPS()
                coroutine.wrap(function() 
                    task.wait(1)
                    clicks[input.UserInputType.Name] -= 1
                    keystrokesAPI.updateCPS()
                end)()
            end
        end
    end
    
    function keystrokesAPI.updateCPS() 
        for i,v in next, clicks do 
            local cps = keystrokes[i.."CPS"]
            cps.Text = "["..tostring(v).."]"
        end
    end

    function keystrokesAPI.init() 
        coroutine.wrap(function()
            task.wait(0.01)
            keystrokesAPI.Connection = game:GetService("UserInputService").InputBegan:Connect(function(i) keystrokesAPI.handleInput(i,false) end)
            keystrokesAPI.Connection2 = game:GetService("UserInputService").InputEnded:Connect(function(i) keystrokesAPI.handleInput(i, true) end)
        end)()
    end

end

keyStrokesToggle = HUDButton.CreateToggle({
    Name = "keystrokes",
    Function = function(callback) 
        if HUDButton.Enabled then
            keyStrokesWindow.Instance.Visible = callback
        end

        if callback then 
            keystrokesAPI.init()
        else
            if keystrokesAPI.Connection then 
                keystrokesAPI.Connection:Disconnect()  
                keystrokesAPI.Connection = nil
            end
            if keystrokesAPI.Connection2 then 
                keystrokesAPI.Connection2:Disconnect()  
                keystrokesAPI.Connection2 = nil
            end
        end
    end
})

keyStrokesWindow.CreateSlider({
    Name = "scale",
    Default = 1,
    Min = 0.1,
    Max = 2,
    Round = 1,
    Function = function(value) 
        keystrokesAPI.Instance.Size = UDim2.new(0, 230 * value, 0, 260 * value)
    end
})

keyStrokesWindow.CreateSlider({
    Name = "transparency",
    Default = 0,
    Min = 0,
    Max = 100,
    Round = 0,
    Function = function(value) 
        for i,v in next, keystrokesAPI.Objects do 
            if i:find("CPS") then continue end
            v.Transparency = value / 100
        end
    end
})

local universal = funcs:run(funcs:getUniversalScript())
local gameScript = funcs:run(funcs:getPlaceScript())
local privateScript = funcs:run(funcs:getPrivateScript())
function funcs:saveConfig() 
    if not engoware then 
        return
    end

    local configName = "default"
    local path = "engoware/configs/" .. funcs:getPlaceIdentifier() .. "/"
    local configPath = path .. configName .. ".json"

    local config = {}

    for i,v in next, GuiLibrary.Objects do 
        if v.Type == 'OptionsButton' then 
            config[i] = {Enabled = v.API.Enabled, Bind = v.API.Bind, Type = v.Type, Window = v.Window}
        elseif v.Type == 'Toggle' then
            config[i] = {Enabled = v.API.Enabled, Type = v.Type, OptionsButton = v.OptionsButton, CustomWindow = v.CustomWindow}
        elseif v.Type == 'Slider' then
            config[i] = {Value = v.API.Value, Type = v.Type, OptionsButton = v.OptionsButton, CustomWindow = v.CustomWindow}
        elseif v.Type == 'Dropdown' then
            config[i] = {Value = v.API.Value, Type = v.Type, OptionsButton = v.OptionsButton, CustomWindow = v.CustomWindow}
        elseif v.Type == 'Textbox' then
            config[i] = {Value = v.API.Value, Type = v.Type, OptionsButton = v.OptionsButton, CustomWindow = v.CustomWindow}
        elseif v.Type == 'MultiDropdown' then
            local values = v.API.Values
            for i,v in next, values do 
                v.Instance = nil
                v.SelectedInstance = nil
            end
            config[i] = {Values = values, Type = v.Type, OptionsButton = v.OptionsButton, CustomWindow = v.CustomWindow}
        elseif v.Type == 'Textlist' then
            config[i] = {Values = v.API.Values, Type = v.Type, OptionsButton = v.OptionsButton, CustomWindow = v.CustomWindow}
        elseif v.Type == 'CustomWindow' then
            config[i] = {Position = {X = {Scale = v.Instance.Position.X.Scale, Offset = v.Instance.Position.X.Offset}, Y = {Scale = v.Instance.Position.Y.Scale, Offset = v.Instance.Position.Y.Offset}}, Type = v.Type}
        end
    end

    makefolder(path)
    if isfile(configPath) then 
        delfile(configPath)
    end

    local success, returned = pcall(function() 
        return game:GetService("HttpService"):JSONEncode(config)
    end)

    if success then 
        writefile(configPath, returned)
    else
        warn("[engoware] failed to save config: " .. returned)
    end

    repeat task.wait() until isfile(configPath)
end

function funcs:loadConfig() 
    if not engoware then 
        return
    end

    local configName = "default"
    local path = "engoware/configs/" .. funcs:getPlaceIdentifier() .. "/"
    local configPath = path .. configName .. ".json"

    if not isfile(configPath) then 
        return
    end

    local success, returned = pcall(function() 
        return game:GetService("HttpService"):JSONDecode(readfile(configPath))
    end)

    if not success then 
        return warn("[engoware] failed to load config: " .. returned)
    end
    for i,v in next, returned do 
        local prop = v.Type == 'OptionsButton' and 'Window' or v.CustomWindow and 'CustomWindow' or 'OptionsButton'
        local object = funcs:getObject(i, prop, v[prop])
        if not object then 
            continue 
        end

        if v.Type == 'OptionsButton' then 
            if v.Bind and v.Bind ~= "" then
                object.API.SetBind(v.Bind)
            end
            if v.Enabled then
                object.API.Toggle()
            end
        elseif v.Type == 'Toggle' then
            if v.Enabled ~= object.API.Enabled then
                object.API.Toggle()
            end
        elseif v.Type == 'Slider' then
            object.API.Set(v.Value, true)
        elseif v.Type == 'Dropdown' then
            object.API.SetValue(v.Value)
        elseif v.Type == 'Textbox' then
            object.API.Set(v.Value)
        elseif v.Type == 'MultiDropdown' then
            for i,v in next, v.Values do 
                if v.Enabled then
                    object.API.ToggleValue(v.Value)
                end
            end
        elseif v.Type == 'Textlist' then
            for i,v in next, v.Values do 
                object.API.Add(v)
            end
        elseif v.Type == 'CustomWindow' then
            object.Instance.Position = UDim2.new(v.Position.X.Scale, v.Position.X.Offset, v.Position.Y.Scale, v.Position.Y.Offset)
        end
    end

end
funcs:loadConfig()

local teleportConnection = lplr.OnTeleport:Connect(function(State)
    if State == Enum.TeleportState.Started then
		local stringtp = [[
            if engoware_developer then 
                loadstring(readfile("engoware/Main.lua"))()
            else 
                loadstring(game:HttpGet("https://raw.githubusercontent.com/joeengo/engoware/main/Main.lua", true))() 
            end
        ]]
		queueteleport(stringtp)
        funcs:saveConfig()
    end
end)

local playerRemovingConnection = Players.PlayerRemoving:Connect(function(player)
    if player == lplr then 
        funcs:saveConfig()
    end
end)

coroutine.wrap(function() 
    repeat 
        for i = 1, 50 do 
            task.wait(0.1)
            if not engoware then 
                break
            end
        end
        funcs:saveConfig()
    until not engoware
end)()

engoware.UninjectEvent.Event:Connect(function() 
    funcs:saveConfig()
    getgenv().engoware = nil
    for i,v in next, GuiLibrary.Objects do 
        if v.Type == 'OptionsButton' and v.API.Enabled then 
            v.API.Toggle()
        end
        if v.Type == 'Toggle' and v.API.Enabled then 
            v.API.Toggle()
        end
    end
    teleportConnection:Disconnect()
    playerRemovingConnection:Disconnect()
    for i,v in next, GuiLibrary.Connections do 
        v:Disconnect()
    end
    GuiLibrary.ScreenGui:Destroy()
end)

if engoware_developer then
    print("[engoware] loaded in " .. tostring(tick() - startTick) .. "s.")
end
