local request = (syn and syn.request) or request or http_request or (http and http.request)
local UIS = game:GetService("UserInputService")
local setthreadidentityfunc = syn and syn.set_thread_identity or set_thread_identity or setidentity or setthreadidentity
local getthreadidentityfunc = syn and syn.get_thread_identity or get_thread_identity or getidentity or getthreadidentity
local GuiLibrary = {}
local utils = {}; GuiLibrary.utils = utils do
    function utils:require(url, bypass)
        if isfile(url) then
            return readfile(url)
        end

        local newUrl = (bypass and "https://raw.githubusercontent.com/joeengo/" or "https://raw.githubusercontent.com/joeengo/engoware/main/") .. url:gsub("engoware/", ""):gsub("engoware\\", "")
        local response = request({
            Url = newUrl,
            Method = "GET",
        })
        if response.StatusCode == 200 then
            return response.Body
        end
    end

    function utils:getColorOfObject(object)
        if utils:isRainbow() then
            local yPos = object.AbsolutePosition.Y
            return utils:getRainbow(yPos)
        end
        return utils:getColorTheme()
    end

    function utils:getColor()
        if utils:isRainbow() then
            return utils:getRainbow()
        end
        return utils:getColorTheme()
    end

    function utils:getColorTheme(table)
        local color = GuiLibrary.ColorTheme or {H = 0, S = 1, V = 1}
        return table and color or Color3.fromHSV(color.H, color.S, color.V)
    end

    function utils:setColorTheme(color)
        local typeOf = typeof(color)
        GuiLibrary.ColorTheme = GuiLibrary.ColorTheme or {}

        if typeOf == "table" then
            GuiLibrary.ColorTheme = color
        else
            local h,s,v = (color):ToHSV()
            GuiLibrary.ColorTheme.H = h
            GuiLibrary.ColorTheme.S = s
            GuiLibrary.ColorTheme.V = v
        end
        if GuiLibrary.ColorUpdate then
            GuiLibrary.ColorUpdate:Fire()
        end
    end

    function utils:isRainbow()
        return GuiLibrary.Rainbow or false
    end

    function utils:getRainbow(yPos)
        if utils:isRainbow() then
            local yPos = yPos or 0
            if yPos < 0 then
                yPos = -yPos
            end
            local color = utils:getColorTheme(true).H
            local calculatedColor = color + (yPos / (GuiLibrary.RainbowSmoothness or 1750))
            while (calculatedColor > 1) do
                calculatedColor = calculatedColor - 1
            end
            return Color3.fromHSV(calculatedColor, GuiLibrary.ColorTheme.S, GuiLibrary.ColorTheme.V)
        end
        return Color3.new(0,0,0)
    end

    function utils:connection(connection)
        GuiLibrary.Connections = GuiLibrary.Connections or {}
        GuiLibrary.Connections[#GuiLibrary.Connections + 1] = connection
    end

    function utils:addObject(name, object) 
        GuiLibrary.Objects = GuiLibrary.Objects or {}
        GuiLibrary.Objects[name] = object
    end
    
    function utils:removeObject(name) 
        local function remove(t)
            for i,v in next, t do 
                local typeOf = typeof(v)
                if typeOf == 'Instance' then 
                    v:Destroy()
                elseif typeOf == 'RBXScriptConnection' then
                    if v.Connected then 
                        v:Disconnect()
                    end
                elseif typeOf == 'table' then 
                    remove(v)
                end
            end
        end
        
        if GuiLibrary.Objects[name] then
            remove(GuiLibrary.Objects[name])
            GuiLibrary.Objects[name] = nil
        end
    end

    function utils:getNextWindowPosition() 
        if GuiLibrary.WindowX then 
            GuiLibrary.WindowX = GuiLibrary.WindowX + 220
        else
            GuiLibrary.WindowX = 150
        end
        return GuiLibrary.WindowX
    end

    function utils:dragify(gui, dragpart)
        coroutine.wrap(function()
            local dragging
            local dragInput
            local dragStart = Vector3.new(0,0,0)
            local startPos
            local function update(input)
                local delta = input.Position - dragStart
                local Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + (delta.X), startPos.Y.Scale, startPos.Y.Offset + (delta.Y))
                game:GetService("TweenService"):Create(gui, TweenInfo.new(.20), {Position = Position}):Play()
            end
            dragpart.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch and dragging == false then
                    dragStart = input.Position
                    local delta = (input.Position - dragStart)
                    if delta.Y <= 30 then
                        dragging = GuiLibrary.ClickGUI.Visible
                        startPos = gui.Position
                        input.Changed:Connect(function()
                            if input.UserInputState == Enum.UserInputState.End then
                                dragging = false
                            end
                        end)
                    end
                end
            end)
            dragpart.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                    dragInput = input
                end
            end)
            UIS.InputChanged:Connect(function(input)
                if input == dragInput and dragging then
                    update(input)
                end
            end)
        end)()
    end

    function utils:updateScale(UIScale) 
        if GuiLibrary.canScale then
            local ViewportSize = workspace.CurrentCamera.ViewportSize
            local X = ViewportSize.X / 1920
            local Y = ViewportSize.Y / 1080
            UIScale.Scale = math.clamp(X, 0.3, 2)
        else
            UIScale.Scale = 1
        end
    end
end

coroutine.wrap(function()
    repeat task.wait()
        if utils:isRainbow() then
            local old = GuiLibrary.ColorTheme or {}
            local hue = old.H or 0
            if hue >= 1 then
                hue = 0
            end
            utils:setColorTheme({
                H = (hue) + 0.001,
                S = old.S or 1,
                V = old.V or 1
            })
        end
    until false
end)()

local SignalLib = loadstring(utils:require("roblox/main/SignalLib.lua", true))()
local ColorUpdate, ButtonUpdate = SignalLib.new(), SignalLib.new()
GuiLibrary.ColorUpdate = ColorUpdate
GuiLibrary.ButtonUpdate = ButtonUpdate

local ScreenGui = Instance.new("ScreenGui")
local ClickGUI = Instance.new("Frame")
local UIScale = Instance.new("UIScale")
ScreenGui.Name = "engoware"
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ClickGUI.Name = "ClickGUI"
ClickGUI.Parent = ScreenGui
ClickGUI.BackgroundTransparency = 1
ClickGUI.Size = UDim2.new(1, 0, 1, 0)
UIScale.Parent = ScreenGui
if gethui and (not KRNL_LOADED) then
    ScreenGui.Parent = gethui()
else
    ScreenGui.Parent = game:GetService("CoreGui").RobloxGui
end
if syn and not gethui then
    syn.protect_gui(ScreenGui)
end

utils:updateScale(UIScale)
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
    utils:updateScale(UIScale)
end)

GuiLibrary.UIScale = UIScale
GuiLibrary.ClickGUI = ClickGUI
GuiLibrary.ScreenGui = ScreenGui
function GuiLibrary.CreateWindow(args)
    local windowapi = {Expanded = true}
    local windowname = args.Name .. "Window"
    local nextPos = utils:getNextWindowPosition()
    local WindowTopBar = Instance.new("TextButton", ClickGUI)
    WindowTopBar.Name = args.Name.."WindowTopBar"
    WindowTopBar.BackgroundColor3 = Color3.fromRGB(16, 16, 16)
    WindowTopBar.BorderSizePixel = 0
    WindowTopBar.Position = UDim2.new(0, nextPos, 0.05, 0)
    WindowTopBar.Size = UDim2.new(0, 203, 0, 33)
    WindowTopBar.AutoButtonColor = false
    WindowTopBar.Font = Enum.Font.Code
    WindowTopBar.Text = ""
    WindowTopBar.TextColor3 = Color3.fromRGB(255, 255, 255)
    WindowTopBar.TextSize = 14.000
    WindowTopBar.Modal = true
    local Name = Instance.new("TextLabel")
    Name.Name = "Name"
    Name.Parent = WindowTopBar
    Name.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Name.BackgroundTransparency = 1.000
    Name.Position = UDim2.new(0.049261082, 0, 0, 0)
    Name.Size = UDim2.new(-0.024630541, 162, 1, 0)
    Name.ZIndex = 2
    Name.Font = Enum.Font.Code
    Name.Text = args.Name
    Name.TextColor3 = Color3.fromRGB(255, 255, 255)
    Name.TextSize = 14.000
    Name.TextXAlignment = Enum.TextXAlignment.Left
    local Expand = Instance.new("ImageButton")
    Expand.Name = "Expand"
    Expand.Parent = WindowTopBar
    Expand.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Expand.BackgroundTransparency = 1.000
    Expand.BorderSizePixel = 0
    Expand.Position = UDim2.new(0.857073903, 0, 0.211999997, 0)
    Expand.Rotation = 180
    Expand.Size = UDim2.new(0, 19, 0, 19)
    Expand.ZIndex = 2
    Expand.Image = "http://www.roblox.com/asset/?id=6031094679"
    Expand.ScaleType = Enum.ScaleType.Fit
    local Window = Instance.new("Frame")
    Window.Name = "Window"
    Window.Parent = WindowTopBar
    Window.BackgroundColor3 = Color3.fromRGB(24, 24, 24)
    Window.BackgroundTransparency = 0.100
    Window.BorderSizePixel = 0
    Window.Position = UDim2.new(0, 0, 0, 33)
    Window.Size = UDim2.new(0, 203, 0, 396)
    local ModuleContainer = Instance.new("Frame")
    ModuleContainer.Name = "ModuleContainer"
    ModuleContainer.Parent = Window
    ModuleContainer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ModuleContainer.BackgroundTransparency = 1.000
    ModuleContainer.BorderSizePixel = 0
    ModuleContainer.Size = UDim2.new(0, 203, 0.990886092, 0)
    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.Padding = UDim.new(0, 0)
    UIListLayout.Parent = ModuleContainer
    UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

    function windowapi.Update() 
        local size = UIListLayout.AbsoluteContentSize
        ModuleContainer.Size = UDim2.new(0, 203, 0, size.Y / UIScale.Scale)
        Window.Size = UDim2.new(0, 203, 0, size.Y / UIScale.Scale)
    end

    utils:connection(UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(windowapi.Update))

    windowapi.Update()

    function windowapi.Expand()
        if windowapi.Expanded then
            Window.Visible = false
            windowapi.Expanded = false
            Expand.Rotation = 0
            ModuleContainer.Visible = false
        else
            Window.Visible = true
            windowapi.Expanded = true
            Expand.Rotation = 180
            ModuleContainer.Visible = true
        end
        windowapi.Update()
    end

    Expand.MouseButton1Click:Connect(windowapi.Expand)

    function windowapi.CreateOptionsButton(args)
        local buttonapi = {Expanded = false, Enabled = false, Recording = false}
        local optionsbuttonname = args.Name .. "OptionsButton"
        local Module = Instance.new("TextButton")
        Module.Name = optionsbuttonname.."Module"
        Module.Parent = ModuleContainer
        Module.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
        Module.BackgroundTransparency = 0.300
        Module.BorderSizePixel = 0
        Module.Size = UDim2.new(0, 203, 0, 28)
        Module.Font = Enum.Font.Code
        Module.Text = ""
        Module.TextColor3 = Color3.fromRGB(255, 255, 255)
        Module.TextSize = 14.000
        buttonapi.Instance = Module
        local Name_2 = Instance.new("TextLabel")
        Name_2.Name = "Name"
        Name_2.Parent = Module
        Name_2.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
        Name_2.BackgroundTransparency = 1.000
        Name_2.BorderSizePixel = 0
        Name_2.Position = UDim2.new(0.0495019183, 0, 0, 0)
        Name_2.Size = UDim2.new(-0.0887388065, 182, 1, 0)
        Name_2.Font = Enum.Font.Code
        Name_2.Text = args.Name
        Name_2.TextColor3 = Color3.fromRGB(255, 255, 255)
        Name_2.TextSize = 14.000
        Name_2.TextXAlignment = Enum.TextXAlignment.Left
        local ModuleChildrenContainer = Instance.new("Frame")
        ModuleChildrenContainer.Name = "ModuleChildrenContainer"
        ModuleChildrenContainer.Parent = ModuleContainer
        ModuleChildrenContainer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ModuleChildrenContainer.BackgroundTransparency = 1.000
        ModuleChildrenContainer.BorderSizePixel = 0
        ModuleChildrenContainer.Position = UDim2.new(0, 0, 0, 27)
        ModuleChildrenContainer.Size = UDim2.new(0, 203, 0, 368)
        ModuleChildrenContainer.Visible = false
        local UIListLayout_2 = Instance.new("UIListLayout")
        UIListLayout_2.Parent = ModuleChildrenContainer
        UIListLayout_2.HorizontalAlignment = Enum.HorizontalAlignment.Center
        UIListLayout_2.SortOrder = Enum.SortOrder.LayoutOrder
        UIListLayout_2.Padding = UDim.new(0, 4)
        local Bind = Instance.new("TextButton")
        Bind.Name = "Bind"
        Bind.Parent = ModuleChildrenContainer
        Bind.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
        Bind.BackgroundTransparency = 0.300
        Bind.BorderColor3 = Color3.fromRGB(100, 100, 100)
        Bind.BorderSizePixel = 0
        Bind.LayoutOrder = 2
        Bind.Size = UDim2.new(0, 184, 0, 22)
        Bind.Font = Enum.Font.SourceSans
        Bind.Text = ""
        Bind.TextColor3 = Color3.fromRGB(0, 0, 0)
        Bind.TextSize = 14.000
        utils:connection(Bind.MouseEnter:Connect(function()
            Bind.BorderSizePixel = 1
        end))
        utils:connection(Bind.MouseLeave:Connect(function()
            Bind.BorderSizePixel = 0
        end))
        Bind.AutoButtonColor = false
        local Name_3 = Instance.new("TextLabel")
        Name_3.Name = "Name"
        Name_3.Parent = Bind
        Name_3.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
        Name_3.BackgroundTransparency = 1.000
        Name_3.BorderSizePixel = 0
        Name_3.Position = UDim2.new(0.0440070182, 0, 0.227272734, 0)
        Name_3.Size = UDim2.new(0.046920944, 140, 0.5, 0)
        Name_3.Font = Enum.Font.Code
        Name_3.Text = "bind: none"
        Name_3.TextColor3 = Color3.fromRGB(255, 255, 255)
        Name_3.TextSize = 14.000
        Name_3.TextXAlignment = Enum.TextXAlignment.Left
        utils:connection(Bind.MouseButton1Click:Connect(function() 
            if GuiLibrary.IsRecording then 
                return 
            end

            buttonapi.Recording = not buttonapi.Recording
            if buttonapi.Recording then 
                GuiLibrary.IsRecording = true
                Name_3.Text = "press a key..."
            end
        end))
        local ModuleOptionsContainer = Instance.new("Frame")
        ModuleOptionsContainer.Name = "ModuleOptionsContainer"
        ModuleOptionsContainer.Parent = ModuleChildrenContainer
        ModuleOptionsContainer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        ModuleOptionsContainer.BackgroundTransparency = 1.000
        ModuleOptionsContainer.BorderSizePixel = 0
        ModuleOptionsContainer.LayoutOrder = 1
        ModuleOptionsContainer.Size = UDim2.new(0, 203, 0, 334)
        local UIListLayout_3 = Instance.new("UIListLayout")
        UIListLayout_3.Parent = ModuleOptionsContainer
        UIListLayout_3.HorizontalAlignment = Enum.HorizontalAlignment.Center
        UIListLayout_3.SortOrder = Enum.SortOrder.LayoutOrder
        UIListLayout_3.Padding = UDim.new(0, 4)

        function buttonapi.SetBind(key) 
            buttonapi.Recording = false
            GuiLibrary.IsRecording = false
            if key then
                buttonapi.Bind = key
            else
                buttonapi.Bind = nil
            end
            Name_3.Text = "bind: "..(buttonapi.Bind and buttonapi.Bind:lower() or "none")
        end

        local bind = args.Bind or args.DefaultBind
        if bind then 
            buttonapi.SetBind(bind)
        end

        function buttonapi.Update() 
            local size2 = UIListLayout_2.AbsoluteContentSize
            ModuleChildrenContainer.Size = UDim2.new(0, 203, 0, (size2.Y + (8 * UIScale.Scale)) / UIScale.Scale )
            local size = UIListLayout_3.AbsoluteContentSize
            ModuleOptionsContainer.Size = UDim2.new(0, 203, 0, size.Y / UIScale.Scale)
        end
        utils:connection(UIListLayout_3:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(buttonapi.Update))
        utils:connection(UIListLayout_2:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(buttonapi.Update))

        utils:connection(ColorUpdate:Connect(function()
            if buttonapi.Enabled then
                Module.BackgroundColor3 = utils:getColorOfObject(Module)
            else
                Module.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
            end
        end))

        function buttonapi.Toggle(wasKeyDown)
            if buttonapi.Enabled then
                buttonapi.Enabled = false
                Module.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
            else
                buttonapi.Enabled = true
                Module.BackgroundColor3 = utils:getColorOfObject(Module)
            end
            ButtonUpdate:Fire(args.Name, buttonapi.Enabled, wasKeyDown)
            if args.Function then
                args.Function(buttonapi.Enabled, wasKeyDown)
            end
        end

        function buttonapi.Expand()
            if buttonapi.Expanded then
                buttonapi.Expanded = false
                ModuleChildrenContainer.Visible = false
            else
                buttonapi.Expanded = true
                ModuleChildrenContainer.Visible = true
            end
            windowapi.Update()
        end

        utils:connection(Module.MouseButton1Click:Connect(buttonapi.Toggle))
        utils:connection(Module.MouseButton2Click:Connect(buttonapi.Expand))

        -- OPTIONS --

        function buttonapi.CreateToggle(args) 
            local toggleapi = {Enabled = false}
            local Toggle = Instance.new("TextButton")
            Toggle.Name = "Toggle"
            Toggle.Parent = ModuleOptionsContainer
            Toggle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Toggle.BackgroundTransparency = 1.000
            Toggle.BorderSizePixel = 0
            Toggle.Position = UDim2.new(0, 0, 2.75755095, 0)
            Toggle.Size = UDim2.new(0, 203, 0, 24)
            Toggle.Text = ""
            Toggle.AutoButtonColor = false
            toggleapi.Instance = Toggle
            local Name_7 = Instance.new("TextLabel")
            Name_7.Name = "Name"
            Name_7.Parent = Toggle
            Name_7.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
            Name_7.BackgroundTransparency = 1.000
            Name_7.BorderSizePixel = 0
            Name_7.Position = UDim2.new(0.0495016165, 0, 0, 0)
            Name_7.Size = UDim2.new(-0.197113186, 182, 1, 0)
            Name_7.Font = Enum.Font.Code
            Name_7.Text = args.Name
            Name_7.TextColor3 = Color3.fromRGB(255, 255, 255)
            Name_7.TextSize = 14.000
            Name_7.TextXAlignment = Enum.TextXAlignment.Left
            local Toggle_2 = Instance.new("TextButton")
            Toggle_2.Name = "Toggle"
            Toggle_2.Parent = Toggle
            Toggle_2.AnchorPoint = Vector2.new(0, 0.5)
            Toggle_2.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
            Toggle_2.BackgroundTransparency = 0.300
            Toggle_2.BorderSizePixel = 0
            Toggle_2.Position = UDim2.new(0, 170, 0, 14)
            Toggle_2.Size = UDim2.new(0, 21, 0, 10)
            Toggle_2.Text = ""
            Toggle_2.BorderColor3 = Color3.fromRGB(100, 100, 100)
            Toggle_2.AutoButtonColor = false
            local ToggleButton = Instance.new("TextButton")
            ToggleButton.Name = "ToggleButton"
            ToggleButton.Parent = Toggle_2
            ToggleButton.AnchorPoint = Vector2.new(0, 0.5)
            ToggleButton.BackgroundColor3 = Color3.fromRGB(2, 255, 137)
            ToggleButton.BorderSizePixel = 0
            ToggleButton.Position = UDim2.new(-0.2, 0, 0.5, 0)
            ToggleButton.Size = UDim2.new(0, 10, 0, 12)
            ToggleButton.Font = Enum.Font.Code
            ToggleButton.Text = ""
            ToggleButton.TextColor3 = Color3.fromRGB(0, 0, 0)
            ToggleButton.TextSize = 14.000
            utils:connection(ColorUpdate:Connect(function()
                ToggleButton.BackgroundColor3 = utils:getColorOfObject(ToggleButton)
            end))

            function toggleapi.Toggle(skipTween) 
                if toggleapi.Enabled then 
                    toggleapi.Enabled = false
                    if not skipTween then
                        ToggleButton:TweenPosition(UDim2.fromScale(-0.2, 0.5), "Out", "Quad", 0.2, true)
                    else
                        ToggleButton.Position = UDim2.fromScale(-0.2, 0.5)
                    end
                else
                    toggleapi.Enabled = true
                    if not skipTween then
                        ToggleButton:TweenPosition(UDim2.fromScale(0.6, 0.5), "Out", "Quad", 0.2, true)
                    else
                        ToggleButton.Position = UDim2.fromScale(0.6, 0.5)
                    end
                end
                if args.Function then
                    args.Function(toggleapi.Enabled)
                end
            end
            utils:connection(ToggleButton.MouseButton1Click:Connect(toggleapi.Toggle))
            utils:connection(Toggle_2.MouseButton1Click:Connect(toggleapi.Toggle))
            utils:connection(Toggle.MouseButton1Click:Connect(toggleapi.Toggle))

            utils:connection(Toggle.MouseEnter:Connect(function()
                Toggle_2.BorderSizePixel = 1
            end))

            utils:connection(Toggle.MouseLeave:Connect(function()
                Toggle_2.BorderSizePixel = 0
            end))

            if (args.Default) and (toggleapi.Enabled ~= args.Default) then 
                --print("[Module] " .. args.Name .. " is being enabled by default")
                toggleapi.Toggle(true)
            end

            utils:addObject(args.Name .. "Toggle" .. "_" .. optionsbuttonname , {Name = args.Name, Instance = Toggle, Type = "Toggle", OptionsButton = optionsbuttonname, API = toggleapi, args = args})

            return toggleapi
        end

        function buttonapi.CreateSlider(args) 
            local sliderapi = {}
            local min, max, default, round = args.Min, args.Max, (args.Default or args.Min), (args.Round or 1)
            
            local function getValueText(value)
                if math.floor(value) == value then 
                    return tostring(value) .. ".0"
                end
                return tostring(value)
            end  
            
            local Slider = Instance.new("Frame")
            Slider.Name = "Slider"
            Slider.Parent = ModuleOptionsContainer
            Slider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Slider.BackgroundTransparency = 1.000
            Slider.BorderSizePixel = 0
            Slider.Position = UDim2.new(0, 0, 0.945145488, 0)
            Slider.Size = UDim2.new(0, 203, 0, 39)
            sliderapi.Instance = Slider
            local Name_6 = Instance.new("TextLabel")
            Name_6.Name = "Name"
            Name_6.Parent = Slider
            Name_6.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
            Name_6.BackgroundTransparency = 1.000
            Name_6.BorderSizePixel = 0
            Name_6.Position = UDim2.new(0.0495016165, 0, 0, 0)
            Name_6.Size = UDim2.new(0, 140, 0.5, 0)
            Name_6.Font = Enum.Font.Code
            Name_6.Text = args.Name
            Name_6.TextColor3 = Color3.fromRGB(255, 255, 255)
            Name_6.TextSize = 14.000
            Name_6.TextXAlignment = Enum.TextXAlignment.Left
            local Value = Instance.new("TextBox")   
            Value.Name = "Value"
            Value.Parent = Name_6
            Value.AnchorPoint = Vector2.new(0, 0.5)
            Value.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Value.BackgroundTransparency = 1.000
            Value.Position = UDim2.new(1.01400006, 0, 0.5, 0)
            Value.Size = UDim2.new(0, 39, 0, 14)
            Value.Font = Enum.Font.Code
            Value.PlaceholderText = "val"
            Value.Text = getValueText(default)
            Value.TextColor3 = Color3.fromRGB(255, 255, 255)
            Value.TextSize = 13.000
            Value.TextXAlignment = Enum.TextXAlignment.Right
            local ValueLine = Instance.new("Frame")
            ValueLine.Name = "ValueLine"
            ValueLine.Parent = Value
            ValueLine.AnchorPoint = Vector2.new(1, 0)
            ValueLine.BackgroundColor3 = Color3.fromRGB(195, 195, 195)
            ValueLine.BackgroundTransparency = 0.300
            ValueLine.BorderSizePixel = 0
            ValueLine.BorderColor3 = Color3.fromRGB(158, 158, 158)
            ValueLine.Position = UDim2.new(1, 0, 1, 0)
            ValueLine.Size = UDim2.new(.75, 0, 0, 1)
            ValueLine.Visible = false
            local SliderBack = Instance.new("Frame")
            SliderBack.Name = "SliderBack"
            SliderBack.Parent = Slider
            SliderBack.AnchorPoint = Vector2.new(0.5, 0.5)
            SliderBack.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
            SliderBack.BackgroundTransparency = 0.300
            SliderBack.BorderSizePixel = 0
            SliderBack.BorderColor3 = Color3.fromRGB(100, 100, 100)
            SliderBack.Position = UDim2.new(0.5, 0, 0.699999988, 0)
            SliderBack.Size = UDim2.new(0, 182, 0, 5)
            local SliderFill = Instance.new("Frame")
            SliderFill.Name = "SliderFill"
            SliderFill.Parent = SliderBack
            SliderFill.AnchorPoint = Vector2.new(0, 0.5)
            SliderFill.BackgroundColor3 = Color3.fromRGB(2, 255, 137)
            SliderFill.BorderSizePixel = 0
            SliderFill.Position = UDim2.new(0, 0, 0.5, 0)
            SliderFill.Size = UDim2.new(0, 50, 1, 0)
            utils:connection(ColorUpdate:Connect(function()
                SliderFill.BackgroundColor3 = utils:getColorOfObject(SliderFill)
            end))

            utils:connection(Slider.MouseEnter:Connect(function()
                SliderBack.BorderSizePixel = 1
                SliderBack.BackgroundColor3 = Color3.fromRGB(23, 23, 23)
            end))

            utils:connection(Slider.MouseLeave:Connect(function()
                SliderBack.BorderSizePixel = 0
                SliderBack.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
            end))

            utils:connection(Value.MouseEnter:Connect(function() 
                ValueLine.Visible = true
            end))

            utils:connection(Value.MouseLeave:Connect(function() 
                if not Value:IsFocused() then
                    ValueLine.Visible = false
                end
            end))
            
            utils:connection(Value.Focused:Connect(function() 
                ValueLine.Visible = true
            end))

            utils:connection(Value.FocusLost:Connect(function() 
                ValueLine.Visible = false
                local parsed = tonumber(Value.Text)
                if parsed then 
                    sliderapi.Set(parsed, true)
                else
                    Value.Text = getValueText(sliderapi.Value)
                end
            end))
          
            local function slide(input)
                local sizeX = math.clamp((input.Position.X - SliderBack.AbsolutePosition.X) / SliderBack.AbsoluteSize.X, 0, 1)
                SliderFill.Size = UDim2.new(sizeX, 0, 1, 0)
                local value = math.round(((( (max - min) * sizeX ) + min) * (10 ^ round))) / (10 ^ round)
                sliderapi.Value = value
                Value.Text = getValueText(value)
                if args.OnInputEnded then
                    return
                end
                if args.Function then
                    args.Function(value)
                end
            end

            local isSliding
            utils:connection(Slider.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    isSliding = true
                    slide(input)
                end
            end))

            utils:connection(Slider.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    if args.OnInputEnded then
                        if args.Function then
                            args.Function(sliderapi.Value)
                        end
                    end
                    isSliding = false
                end
            end))

            utils:connection(UIS.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement then
                    if isSliding then
                        slide(input)
                    end
                end
            end))

            function sliderapi.Set(value, useOverMax)
                local value = not useOverMax and math.floor((math.clamp(value, min, max) * (10^round))+0.5)/(10^round) or 
                math.clamp(value, (args.RealMin or -math.huge), (args.RealMax or math.huge))
                local sizeValue = math.floor((math.clamp(value, min, max) * (10^round))+0.5)/(10^round)
                sliderapi.Value = value
                SliderFill.Size = UDim2.new((sizeValue - min) / (max - min), 0, 1, 0)
                Value.Text = getValueText(value)
                if args.Function then
                    args.Function(value)
                end
            end
            sliderapi.Set(default)

            utils:addObject(args.Name .. "Slider" .. "_" .. optionsbuttonname, {Name = args.Name, Instance = Slider, Type = "Slider", OptionsButton = optionsbuttonname, API = sliderapi, args = args})

            return sliderapi
        end

        function buttonapi.CreateTextbox(args)
            local boxapi = {}
            local Textbox = Instance.new("Frame")
            Textbox.Name = "Textbox"
            Textbox.Parent = ModuleOptionsContainer
            Textbox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Textbox.BackgroundTransparency = 1.000
            Textbox.BorderSizePixel = 0
            Textbox.AnchorPoint = Vector2.new(0, 0.5)
            Textbox.Position = UDim2.new(0, 0, 0.5, 0)
            Textbox.Size = UDim2.new(0, 203, 0, 30)
            boxapi.Instance = Textbox
            local Textbox_2 = Instance.new("Frame")
            Textbox_2.Name = "Textbox"
            Textbox_2.Parent = Textbox
            Textbox_2.AnchorPoint = Vector2.new(0.5, 0.5)
            Textbox_2.BackgroundColor3 = Color3.fromRGB(17, 17, 17) 
            Textbox_2.BackgroundTransparency = 0.300
            Textbox_2.BorderColor3 = Color3.fromRGB(100, 100, 100)
            Textbox_2.Position = UDim2.new(0.5, 0, 0.5, 0)
            Textbox_2.Size = UDim2.new(0, 184, 0, 22)
            Textbox_2.BorderSizePixel = 0
            local TextBoxValue = Instance.new("TextBox")
            TextBoxValue.Name = "TextBoxValue"
            TextBoxValue.Parent = Textbox_2
            TextBoxValue.AnchorPoint = Vector2.new(0.5, 0.5)
            TextBoxValue.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
            TextBoxValue.BackgroundTransparency = 1.000
            TextBoxValue.BorderSizePixel = 0
            TextBoxValue.Position = UDim2.new(0.521894395, 0, 0.5, 0)
            TextBoxValue.Size = UDim2.new(0.955993056, 0, 1, 0)
            TextBoxValue.ClearTextOnFocus = false
            TextBoxValue.Font = Enum.Font.Code
            TextBoxValue.PlaceholderColor3 = Color3.fromRGB(113, 113, 113)
            TextBoxValue.PlaceholderText = args.Name
            TextBoxValue.Text = (args.Default or "")
            TextBoxValue.TextColor3 = Color3.fromRGB(255, 255, 255)
            TextBoxValue.TextSize = 14.000
            TextBoxValue.TextXAlignment = Enum.TextXAlignment.Left

            utils:connection(Textbox_2.MouseEnter:Connect(function()
                Textbox_2.BorderSizePixel = 1
            end))

            utils:connection(Textbox_2.MouseLeave:Connect(function()
                Textbox_2.BorderSizePixel = 0
            end))

            function boxapi.Set(value) 
                local value = value or args.Default or ""
                boxapi.Value = value
                TextBoxValue.Text = value
                if args.Function then
                    args.Function(value)
                end
            end

            utils:connection(TextBoxValue.FocusLost:Connect(function()
                local text = TextBoxValue.Text
                if text then
                    boxapi.Set(text)
                end
            end))
            utils:addObject(args.Name .. "Textbox" .. "_" .. optionsbuttonname, {Name = args.Name, Instance = Textbox, Type = "Textbox", OptionsButton = optionsbuttonname, API = boxapi, args = args})
            return boxapi
        end
        buttonapi.CreateTextBox = buttonapi.CreateTextbox

        function buttonapi.CreateDropdown(args) 
            local dropdownapi = {Values = {}, Expanded = false}
            local Dropdown = Instance.new("Frame")
            Dropdown.Name = "Dropdown"
            Dropdown.Parent = ModuleOptionsContainer
            Dropdown.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Dropdown.BackgroundTransparency = 1.000
            Dropdown.BorderSizePixel = 0
            Dropdown.Position = UDim2.new(0, 0, 0.592544496, 0)
            Dropdown.Size = UDim2.new(0, 203, 0, 28)
            dropdownapi.Instance = Dropdown
            local DropdownBack = Instance.new("Frame")
            DropdownBack.Name = "DropdownBack"
            DropdownBack.Parent = Dropdown
            DropdownBack.AnchorPoint = Vector2.new(0.5, 0.5)
            DropdownBack.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
            DropdownBack.BackgroundTransparency = 0.300
            DropdownBack.BorderSizePixel = 0
            DropdownBack.Position = UDim2.new(0.5, 0, 0, 15)
            DropdownBack.Size = UDim2.new(0, 184, 0, 22)
            DropdownBack.BorderColor3 = Color3.fromRGB(100, 100, 100)
            DropdownBack.BorderMode = Enum.BorderMode.Outline
            local Name_4 = Instance.new("TextLabel")
            Name_4.Name = "Name"
            Name_4.Parent = DropdownBack
            Name_4.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
            Name_4.BackgroundTransparency = 1.000
            Name_4.BorderSizePixel = 0
            Name_4.Position = UDim2.new(0.0440070182, 0, 0.227272734, 0)
            Name_4.Size = UDim2.new(0.046920944, 140, 0.5, 0)
            Name_4.Font = Enum.Font.Code
            Name_4.Text = args.Name
            Name_4.TextColor3 = Color3.fromRGB(255, 255, 255)
            Name_4.TextSize = 14.000
            Name_4.TextXAlignment = Enum.TextXAlignment.Left
            Name_4.TextTruncate = Enum.TextTruncate.AtEnd
            local Expand_2 = Instance.new("ImageButton")
            Expand_2.Name = "Expand"
            Expand_2.Parent = DropdownBack
            Expand_2.AnchorPoint = Vector2.new(0, 0.5)
            Expand_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Expand_2.BackgroundTransparency = 1.000
            Expand_2.BorderSizePixel = 0
            Expand_2.Position = UDim2.new(0.889967024, 0, 0.5, 0)
            Expand_2.Rotation = 0
            Expand_2.Size = UDim2.new(0, 19, 0, 19)
            Expand_2.ZIndex = 2
            Expand_2.Image = "http://www.roblox.com/asset/?id=6031094679"
            Expand_2.ScaleType = Enum.ScaleType.Fit
            local DropdownValues = Instance.new("Frame")
            DropdownValues.Name = "DropdownValues"
            DropdownValues.Parent = Dropdown
            DropdownValues.AnchorPoint = Vector2.new(0.5, 0.5)
            DropdownValues.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
            DropdownValues.BackgroundTransparency = 1.000
            DropdownValues.BorderSizePixel = 0
            DropdownValues.Position = UDim2.new(0.5, 0, 0, 37)
            DropdownValues.Size = UDim2.new(0, 184, 0, 22)
            DropdownValues.Visible = false
            local UIListLayout_4 = Instance.new("UIListLayout")
            UIListLayout_4.Parent = DropdownValues
            UIListLayout_4.HorizontalAlignment = Enum.HorizontalAlignment.Center
            UIListLayout_4.SortOrder = Enum.SortOrder.LayoutOrder

            utils:connection(DropdownBack.MouseEnter:Connect(function()
                DropdownBack.BorderSizePixel = 1
                DropdownBack.ZIndex = 9
            end))

            utils:connection(DropdownBack.MouseLeave:Connect(function()
                DropdownBack.BorderSizePixel = 0
                DropdownBack.ZIndex = 1
            end))

            function dropdownapi.Update() 
                local size = UIListLayout_4.AbsoluteContentSize.Y
                if DropdownValues.Visible then
                    Dropdown.Size = UDim2.new(0, 203, 0, ((28 * UIScale.Scale) + size) / UIScale.Scale)
                else
                    Dropdown.Size = UDim2.new(0, 203, 0, 28)
                end
            end

            utils:connection(UIListLayout_4:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(dropdownapi.Update))

            function dropdownapi.SetValue(value)
                for i,v in next, dropdownapi.Values do
                    if v.Value == value then
                        if dropdownapi.Expanded then
                            --dropdownapi.Expand()
                        end
                        dropdownapi.Value = value
                        v.SelectedInstance.Visible = true
                        Name_4.Text = args.Name .. " - " .. tostring(value)
                        if args.Function then
                            args.Function(value)
                        end
                    else
                        v.SelectedInstance.Visible = false
                    end
                end
            end

            local function newValue(value)
                local valueapi = {}
                valueapi.Value = value
                local DropdownValue = Instance.new("TextButton")
                DropdownValue.Name = tostring(value).."DropdownValue"
                DropdownValue.Parent = DropdownValues
                DropdownValue.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
                DropdownValue.BackgroundTransparency = 0.300
                DropdownValue.BorderColor3 = Color3.fromRGB(100, 100, 100)
                DropdownValue.BorderMode = Enum.BorderMode.Outline
                DropdownValue.BorderSizePixel = 0
                DropdownValue.Size = UDim2.new(0, 184, 0, 22)
                DropdownValue.Font = Enum.Font.SourceSans
                DropdownValue.Text = ""
                DropdownValue.TextColor3 = Color3.fromRGB(0, 0, 0)
                DropdownValue.TextSize = 14.000
                DropdownValue.MouseButton1Click:Connect(function()
                    dropdownapi.SetValue(value)
                end)
                utils:connection(DropdownValue.MouseEnter:Connect(function()
                    DropdownValue.BorderSizePixel = 1
                    DropdownValue.ZIndex = 9
                end))
                utils:connection(DropdownValue.MouseLeave:Connect(function()
                    DropdownValue.BorderSizePixel = 0
                    DropdownValue.ZIndex = 1
                end))
                local Name_5 = Instance.new("TextLabel")
                Name_5.Name = "Name"
                Name_5.Parent = DropdownValue
                Name_5.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
                Name_5.BackgroundTransparency = 1.000
                Name_5.BorderSizePixel = 0
                Name_5.Position = UDim2.new(0.0440070182, 0, 0.227272734, 0)
                Name_5.Size = UDim2.new(0.046920944, 140, 0.5, 0)
                Name_5.Font = Enum.Font.Code
                Name_5.Text = tostring(value)
                Name_5.TextColor3 = Color3.fromRGB(255, 255, 255)
                Name_5.TextSize = 14.000
                Name_5.TextXAlignment = Enum.TextXAlignment.Left
                local Selected = Instance.new("Frame")
                Selected.Name = "Selected"
                Selected.Parent = DropdownValue
                Selected.AnchorPoint = Vector2.new(0, 0.5)
                Selected.BackgroundColor3 = Color3.fromRGB(2, 255, 137)
                Selected.Visible = false
                Selected.BorderSizePixel = 0
                Selected.Position = UDim2.new(0, 0, 0.5, 0)
                Selected.Size = UDim2.new(0, 2, 1, 0)
                utils:connection(ColorUpdate:Connect(function()
                    Selected.BackgroundColor3 = utils:getColorOfObject(Selected)
                end))
                valueapi.SelectedInstance = Selected
                valueapi.Instance = DropdownValue
                return valueapi
            end

            function dropdownapi.Expand() 
                if dropdownapi.Expanded then 
                    dropdownapi.Expanded = false
                    DropdownValues.Visible = false
                    Expand_2.Rotation = 0
                    --DropdownBack.BorderSizePixel = 1
                else
                    --DropdownBack.BorderSizePixel = 0
                    Expand_2.Rotation = 180
                    dropdownapi.Expanded = true
                    DropdownValues.Visible = true
                end
                dropdownapi.Update() 
            end
            utils:connection(Expand_2.MouseButton1Click:Connect(dropdownapi.Expand))

            for i,v in next, args.List do 
                dropdownapi.Values[#dropdownapi.Values+1] = newValue(v)
            end

            if args.Default then
                dropdownapi.SetValue(args.Default)
            end

            function dropdownapi.SetList(list)
                for i,v in next, dropdownapi.Values do
                    v.Instance:Destroy()
                    dropdownapi.Values[i] = nil
                end
                dropdownapi.Values = {}
                for i,v in next, list do 
                    dropdownapi.Values[#dropdownapi.Values+1] = newValue(v)
                end
            end

            utils:addObject(args.Name .. "Dropdown" .. "_" .. optionsbuttonname, {Name = args.Name, Instance = Dropdown, Type = "Dropdown", OptionsButton = optionsbuttonname, API = dropdownapi, args = args})

            return dropdownapi
        end



        function buttonapi.CreateMultiDropdown(args) 
            local dropdownapi = {Values = {}, Expanded = false}

            local MultiDropdown = Instance.new("Frame")
            MultiDropdown.Name = "MultiDropdown"
            MultiDropdown.Parent = ModuleOptionsContainer
            MultiDropdown.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            MultiDropdown.BackgroundTransparency = 1.000
            MultiDropdown.BorderSizePixel = 0
            MultiDropdown.Position = UDim2.new(0, 0, 0.769933522, 0)
            MultiDropdown.Size = UDim2.new(0, 203, 0, 72)
            dropdownapi.Instance = MultiDropdown
            local MultiDropdownBack = Instance.new("Frame")
            MultiDropdownBack.Name = "MultiDropdownBack"
            MultiDropdownBack.Parent = MultiDropdown
            MultiDropdownBack.AnchorPoint = Vector2.new(0.5, 0.5)
            MultiDropdownBack.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
            MultiDropdownBack.BackgroundTransparency = 0.300
            MultiDropdownBack.BorderSizePixel = 0
            MultiDropdownBack.Position = UDim2.new(0.5, 0, 0, 15)
            MultiDropdownBack.Size = UDim2.new(0, 184, 0, 22)
            MultiDropdownBack.BorderColor3 = Color3.fromRGB(100, 100, 100)
            local Name_8 = Instance.new("TextLabel")
            Name_8.Name = "Name"
            Name_8.Parent = MultiDropdownBack
            Name_8.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
            Name_8.BackgroundTransparency = 1.000
            Name_8.BorderSizePixel = 0
            Name_8.Position = UDim2.new(0.0440070182, 0, 0.227272734, 0)
            Name_8.Size = UDim2.new(0.046920944, 140, 0.5, 0)
            Name_8.Font = Enum.Font.Code
            Name_8.Text = args.Name
            Name_8.TextColor3 = Color3.fromRGB(255, 255, 255)
            Name_8.TextSize = 14.000
            Name_8.TextXAlignment = Enum.TextXAlignment.Left
            Name_8.TextTruncate = Enum.TextTruncate.AtEnd
            local Expand_3 = Instance.new("ImageButton")
            Expand_3.Name = "Expand"
            Expand_3.Parent = MultiDropdownBack
            Expand_3.AnchorPoint = Vector2.new(0, 0.5)
            Expand_3.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Expand_3.BackgroundTransparency = 1.000
            Expand_3.BorderSizePixel = 0
            Expand_3.Position = UDim2.new(0.889967024, 0, 0.5, 0)
            Expand_3.Rotation = 0
            Expand_3.Size = UDim2.new(0, 19, 0, 19)
            Expand_3.ZIndex = 2
            Expand_3.Image = "http://www.roblox.com/asset/?id=6031094679"
            Expand_3.ScaleType = Enum.ScaleType.Fit
            local MultiDropdownValues = Instance.new("Frame")
            MultiDropdownValues.Name = "MultiDropdownValues"
            MultiDropdownValues.Parent = MultiDropdown
            MultiDropdownValues.AnchorPoint = Vector2.new(0.5, 0.5)
            MultiDropdownValues.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
            MultiDropdownValues.BackgroundTransparency = 1.000
            MultiDropdownValues.BorderSizePixel = 0
            MultiDropdownValues.Position = UDim2.new(0.5, 0, 0, 37)
            MultiDropdownValues.Size = UDim2.new(0, 184, 0, 22)
            MultiDropdownValues.Visible = false
            local UIListLayout_6 = Instance.new("UIListLayout")
            UIListLayout_6.Parent = MultiDropdownValues
            UIListLayout_6.HorizontalAlignment = Enum.HorizontalAlignment.Center
            UIListLayout_6.SortOrder = Enum.SortOrder.LayoutOrder

            
            function dropdownapi.Update() 
                local size = UIListLayout_6.AbsoluteContentSize.Y
                if MultiDropdownValues.Visible then
                    MultiDropdown.Size = UDim2.new(0, 203, 0, ((28 * UIScale.Scale) + size) / UIScale.Scale)
                else
                    MultiDropdown.Size = UDim2.new(0, 203, 0, 28)
                end
            end

            utils:connection(UIListLayout_6:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(dropdownapi.Update))

            utils:connection(MultiDropdownBack.MouseEnter:Connect(function()
                MultiDropdownBack.BorderSizePixel = 1
                MultiDropdownBack.ZIndex = 9
            end))

            utils:connection(MultiDropdownBack.MouseLeave:Connect(function()
                MultiDropdownBack.BorderSizePixel = 0
                MultiDropdownBack.ZIndex = 1
            end))

            function dropdownapi.ToggleValue(value)
                for i,v in next, dropdownapi.Values do
                    if v.Value == value then
                        v.Toggle()
                        --dropdownapi.Expand()
                        local tab = {}
                        local string_tab = {}
                        for i,v in next, dropdownapi.Values do 
                            if v.Enabled then 
                                tab[#tab+1] = v.Value
                                string_tab[#string_tab+1] = tostring(v.Value)
                            end
                        end
                        Name_8.Text = args.Name .. (#string_tab~=0 and (" - " .. table.concat(string_tab, ", ")) or "")
                        if args.Function then
                            args.Function(tab)
                        end
                    end
                end
            end

            local function newValue(value)
                local valueapi = {Enabled = false}
                valueapi.Value = value
                local MultiDropdownValue = Instance.new("TextButton")
                MultiDropdownValue.Name = "MultiDropdownValue"
                MultiDropdownValue.Parent = MultiDropdownValues
                MultiDropdownValue.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
                MultiDropdownValue.BackgroundTransparency = 0.300
                MultiDropdownValue.BorderColor3 = Color3.fromRGB(100, 100, 100)
                MultiDropdownValue.BorderSizePixel = 0
                MultiDropdownValue.Size = UDim2.new(0, 184, 0, 22)
                MultiDropdownValue.Font = Enum.Font.SourceSans
                MultiDropdownValue.Text = ""
                MultiDropdownValue.TextColor3 = Color3.fromRGB(0, 0, 0)
                MultiDropdownValue.TextSize = 14.000
                utils:connection(MultiDropdownValue.MouseEnter:Connect(function()
                    MultiDropdownValue.BorderSizePixel = 1
                    MultiDropdownValue.ZIndex = 9
                end))
                utils:connection(MultiDropdownValue.MouseLeave:Connect(function()
                    MultiDropdownValue.BorderSizePixel = 0
                    MultiDropdownValue.ZIndex = 1
                end))
                local Name_9 = Instance.new("TextLabel")
                Name_9.Name = "Name"
                Name_9.Parent = MultiDropdownValue
                Name_9.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
                Name_9.BackgroundTransparency = 1.000
                Name_9.BorderSizePixel = 0
                Name_9.Position = UDim2.new(0.0440070182, 0, 0.227272734, 0)
                Name_9.Size = UDim2.new(0.046920944, 140, 0.5, 0)
                Name_9.Font = Enum.Font.Code
                Name_9.Text = tostring(value)
                Name_9.TextColor3 = Color3.fromRGB(255, 255, 255)
                Name_9.TextSize = 14.000
                Name_9.TextXAlignment = Enum.TextXAlignment.Left
                local Selected = Instance.new("Frame")
                Selected.Name = "Selected"
                Selected.Parent = MultiDropdownValue
                Selected.AnchorPoint = Vector2.new(0, 0.5)
                Selected.BackgroundColor3 = Color3.fromRGB(2, 255, 137)
                Selected.Visible = false
                Selected.BorderSizePixel = 0
                Selected.Position = UDim2.new(0, 0, 0.5, 0)
                Selected.Size = UDim2.new(0, 2, 1, 0)

                utils:connection(ColorUpdate:Connect(function()
                    Selected.BackgroundColor3 = utils:getColorOfObject(Selected)
                end))
                
                function valueapi.Toggle() 
                    if valueapi.Enabled then
                        valueapi.Enabled = false
                        Selected.Visible = false
                    else
                        valueapi.Enabled = true
                        Selected.Visible = true
                    end
                end

                MultiDropdownValue.MouseButton1Click:Connect(function()
                    dropdownapi.ToggleValue(value)
                end)

                valueapi.SelectedInstance = Selected
                valueapi.Instance = MultiDropdownValue
                return valueapi
            end
            for i,v in next, args.List do 
                dropdownapi.Values[tostring(v)] = newValue(v)
            end

            for i,v in next, (args.Default or {}) do 
                dropdownapi.ToggleValue(v)
            end

            function dropdownapi.SetList(list)
                for i,v in next, dropdownapi.Values do
                    v.Instance:Destroy()
                    dropdownapi.Values[i] = nil
                end
                dropdownapi.Values = {}
                for i,v in next, list do 
                    dropdownapi.Values[tostring(v)] = newValue(v)
                end
            end

            function dropdownapi.Expand() 
                if dropdownapi.Expanded then 
                    dropdownapi.Expanded = false
                    MultiDropdownValues.Visible = false
                    Expand_3.Rotation = 0
                else
                    Expand_3.Rotation = 180
                    dropdownapi.Expanded = true
                    MultiDropdownValues.Visible = true
                end
                dropdownapi.Update() 
            end

            dropdownapi.Update()
            utils:connection(Expand_3.MouseButton1Click:Connect(dropdownapi.Expand))
            utils:addObject(args.Name .. "MultiDropdown" .. "_" .. optionsbuttonname, {Name = args.Name, Instance = MultiDropdown, Type = "MultiDropdown", OptionsButton = optionsbuttonname, API = dropdownapi, args = args})

            return dropdownapi
        end
        
        function buttonapi.CreateTextlist(args) 
            local listapi = {Values = {}}

            local Textlist = Instance.new("Frame")
            Textlist.Name = "Textlist"
            Textlist.Parent = ModuleOptionsContainer
            Textlist.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Textlist.BackgroundTransparency = 1.000
            Textlist.BorderSizePixel = 0
            Textlist.Position = UDim2.new(0, 0, 0.0896368474, 0)
            Textlist.Size = UDim2.new(0, 203, 0, 57)
            listapi.Instance = Textlist
            local TextlistEnter = Instance.new("Frame")
            TextlistEnter.Name = "TextlistEnter"
            TextlistEnter.Parent = Textlist
            TextlistEnter.AnchorPoint = Vector2.new(0.5, 0.5)
            TextlistEnter.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
            TextlistEnter.BackgroundTransparency = 0.300
            TextlistEnter.BorderSizePixel = 0
            TextlistEnter.BorderColor3 = Color3.fromRGB(100, 100, 100)
            TextlistEnter.Position = UDim2.new(0.5, 0, 0, 15)
            TextlistEnter.Size = UDim2.new(0, 184, 0, 22)
            local TextlistBoxEnter = Instance.new("TextBox")
            TextlistBoxEnter.Name = "TextlistBoxEnter"
            TextlistBoxEnter.Parent = TextlistEnter
            TextlistBoxEnter.AnchorPoint = Vector2.new(0.5, 0.5)
            TextlistBoxEnter.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
            TextlistBoxEnter.BackgroundTransparency = 1.000
            TextlistBoxEnter.BorderSizePixel = 0
            TextlistBoxEnter.Position = UDim2.new(0.446677178, 0, 0.5, 0)
            TextlistBoxEnter.Size = UDim2.new(0.805558681, 0, 1, 0)
            TextlistBoxEnter.ClearTextOnFocus = false
            TextlistBoxEnter.Font = Enum.Font.Code
            TextlistBoxEnter.PlaceholderColor3 = Color3.fromRGB(165, 165, 165)
            TextlistBoxEnter.PlaceholderText = args.Name
            TextlistBoxEnter.Text = ""
            TextlistBoxEnter.TextColor3 = Color3.fromRGB(255, 255, 255)
            TextlistBoxEnter.TextSize = 14.000
            TextlistBoxEnter.TextXAlignment = Enum.TextXAlignment.Left
            utils:connection(TextlistEnter.MouseEnter:Connect(function()
                TextlistEnter.BorderSizePixel = 1
                TextlistEnter.ZIndex = 9
            end))
            utils:connection(TextlistEnter.MouseLeave:Connect(function()
                TextlistEnter.BorderSizePixel = 0
                TextlistEnter.ZIndex = 1
            end))
            local Add = Instance.new("TextButton")
            Add.Name = "Add"
            Add.Parent = TextlistEnter
            Add.AnchorPoint = Vector2.new(0, 0.5)
            Add.BackgroundColor3 = Color3.fromRGB(2, 255, 137)
            Add.BackgroundTransparency = 1.000
            Add.BorderSizePixel = 0
            Add.Position = UDim2.new(0.899999976, 0, 0.5, 0)
            Add.Size = UDim2.new(0, 13, 0, 14)
            Add.Font = Enum.Font.Code
            Add.Text = "+"
            Add.TextColor3 = Color3.fromRGB(170, 170, 170)
            Add.TextSize = 19.000
            utils:connection(Add.MouseEnter:Connect(function()
                Add.TextColor3 = Color3.fromRGB(255,255,255)
            end))
            utils:connection(Add.MouseLeave:Connect(function()
                Add.TextColor3 = Color3.fromRGB(170, 170, 170)
            end))
            local TextlistValues = Instance.new("Frame")
            TextlistValues.Name = "TextlistValues"
            TextlistValues.Parent = Textlist
            TextlistValues.AnchorPoint = Vector2.new(0.5, 0.5)
            TextlistValues.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
            TextlistValues.BackgroundTransparency = 1.000
            TextlistValues.BorderSizePixel = 0
            TextlistValues.Position = UDim2.new(0.5, 0, 0, 37)
            TextlistValues.Size = UDim2.new(0, 184, 0, 22)
            local UIListLayout = Instance.new("UIListLayout")
            UIListLayout.Parent = TextlistValues
            UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
            UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
            
            UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                --TextlistValues.Size = UDim2.new(0, 184, 0, UIListLayout.AbsoluteContentSize.Y + 22)
                Textlist.Size = UDim2.new(0, 203, 0, (UIListLayout.AbsoluteContentSize.Y + (37 * UIScale.Scale)) / UIScale.Scale)
            end)
            Textlist.Size = UDim2.new(0, 203, 0, (UIListLayout.AbsoluteContentSize.Y + (37 * UIScale.Scale)) / UIScale.Scale)

            local function addValue(value) 
                local valueapi = {}
                valueapi.value = value
                local TextlistValue = Instance.new("TextButton")
                TextlistValue.Name = "TextlistValue"
                TextlistValue.Parent = TextlistValues
                TextlistValue.AnchorPoint = Vector2.new(0.5, 0.5)
                TextlistValue.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
                TextlistValue.BackgroundTransparency = 0.300
                TextlistValue.BorderSizePixel = 0
                TextlistValue.Position = UDim2.new(0.5, 0, 0.5, 0)
                TextlistValue.Size = UDim2.new(0, 184, 0, 22)
                TextlistValue.Text = ""
                TextlistValue.BorderColor3 = Color3.fromRGB(100, 100, 100)
                local TextlistBoxEnter_2 = Instance.new("TextLabel")
                TextlistBoxEnter_2.Name = "TextlistBoxEnter"
                TextlistBoxEnter_2.Parent = TextlistValue
                TextlistBoxEnter_2.AnchorPoint = Vector2.new(0.5, 0.5)
                TextlistBoxEnter_2.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
                TextlistBoxEnter_2.BackgroundTransparency = 1.000
                TextlistBoxEnter_2.BorderSizePixel = 0
                TextlistBoxEnter_2.Position = UDim2.new(0.446677178, 0, 0.5, 0)
                TextlistBoxEnter_2.Size = UDim2.new(0.805558681, 0, 1, 0)
                TextlistBoxEnter_2.Font = Enum.Font.Code
                TextlistBoxEnter_2.Text = value
                TextlistBoxEnter_2.TextColor3 = Color3.fromRGB(255, 255, 255)
                TextlistBoxEnter_2.TextSize = 14.000
                TextlistBoxEnter_2.TextXAlignment = Enum.TextXAlignment.Left
                utils:connection(TextlistValue.MouseEnter:Connect(function()
                    TextlistValue.BorderSizePixel = 1
                    TextlistValue.ZIndex = 9
                end))
                utils:connection(TextlistValue.MouseLeave:Connect(function()
                    TextlistValue.BorderSizePixel = 0
                    TextlistValue.ZIndex = 1
                end))
                local Remove = Instance.new("TextButton")
                Remove.Name = "Remove"
                Remove.Parent = TextlistValue
                Remove.AnchorPoint = Vector2.new(0, 0.5)
                Remove.BackgroundColor3 = Color3.fromRGB(2, 255, 137)
                Remove.BackgroundTransparency = 1.000
                Remove.BorderSizePixel = 0
                Remove.Position = UDim2.new(0.899999858, 0, 0.431818187, 0)
                Remove.Size = UDim2.new(0, 13, 0, 11)
                Remove.Font = Enum.Font.Jura
                Remove.Text = "x"
                Remove.TextColor3 = Color3.fromRGB(170, 170, 170)
                Remove.TextSize = 18.000
                valueapi.Instance = TextlistValue

                utils:connection(Remove.MouseEnter:Connect(function()
                    Remove.TextColor3 = Color3.fromRGB(255,255,255)
                end))
                utils:connection(Remove.MouseLeave:Connect(function()
                    Remove.TextColor3 = Color3.fromRGB(170, 170, 170)
                end))

                function valueapi.Remove()
                    listapi.Values[valueapi.value] = nil
                    TextlistValue:Destroy()
                end

                utils:connection(Remove.MouseButton1Click:Connect(function()
                    valueapi.Remove()
                end))

                utils:connection(TextlistValue.MouseButton1Click:Connect(function()
                    valueapi.Remove()
                end))

                return valueapi
            end

            function listapi.Add(value)
                if listapi.Values[value] then
                    return
                end
                addValue(value)
                listapi.Values[value] = value
                if args.Function then
                    args.Function(listapi.Values)
                end
            end

            if args.Default then
                for i, v in next, args.Default do
                    listapi.Add(v)
                end
            end

            Add.MouseButton1Click:Connect(function() 
                local value = TextlistBoxEnter.Text
                if value == "" then
                    return
                end
                listapi.Add(value)
                TextlistBoxEnter.Text = ""
            end)
            utils:addObject(args.Name .. "Textlist" .. "_" .. optionsbuttonname, {Name = args.Name, Instance = Textlist, Type = "Textlist", OptionsButton = optionsbuttonname, API = listapi, args = args})
            
            return listapi
        end

        utils:addObject(optionsbuttonname, {Name = optionsbuttonname, Instance = Module, Type = "OptionsButton", Window = windowname , API = buttonapi, args = args})

        return buttonapi
    end

    utils:addObject(windowname, {Name = windowname, Instance = Window, Type = "Window" , API = windowapi, args = args})

    return windowapi
end





-- CUSTOM WINDOW BELOW




function GuiLibrary.CreateCustomWindow(args) 
    local windowapi = {}
    local customwindowname = args.Name .. "CustomWindow"
    local CustomWindow = Instance.new("Frame")
    CustomWindow.Name = "CustomWindow"
    CustomWindow.Parent = ScreenGui
    CustomWindow.BackgroundTransparency = 1.000
    CustomWindow.Position = UDim2.new(0.5, 0, 0.5, 0)
    CustomWindow.AnchorPoint = Vector2.new(0.5, 0.5)
    CustomWindow.Size = UDim2.new(0, 218, 0, 237)
    CustomWindow.Visible = false
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Parent = CustomWindow
    TopBar.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
    TopBar.BorderSizePixel = 0
    TopBar.Position = UDim2.new(0.141509429, 0, 0, 0)
    TopBar.Size = UDim2.new(1, 0, 0, 35)
    utils:dragify(CustomWindow, TopBar)
    local Name = Instance.new("TextLabel")
    Name.Name = "Name"
    Name.Parent = TopBar
    Name.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Name.BackgroundTransparency = 1.000
    Name.Position = UDim2.new(0.0495019183, 0, 0, 0)
    Name.Size = UDim2.new(0, 174, 0, 35)
    Name.Font = Enum.Font.Code
    Name.Text = args.Name
    Name.TextColor3 = Color3.fromRGB(255, 255, 255)
    Name.TextSize = 14.000
    Name.TextXAlignment = Enum.TextXAlignment.Left
    local dehaze = Instance.new("ImageButton")
    dehaze.Name = "dehaze"
    dehaze.Parent = TopBar
    dehaze.BackgroundTransparency = 1.000
    dehaze.LayoutOrder = 6
    dehaze.Position = UDim2.new(0.839622617, 0, 0.128581421, 0)
    dehaze.Size = UDim2.new(0, 25, 0, 25)
    dehaze.ZIndex = 2
    dehaze.Image = "rbxassetid://3926305904"
    dehaze.ImageRectOffset = Vector2.new(84, 644)
    dehaze.ImageRectSize = Vector2.new(36, 36)
    local Children = Instance.new("Frame")
    Children.Name = "Children"
    Children.Parent = CustomWindow
    Children.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    Children.BackgroundTransparency = 1.000
    Children.Position = UDim2.new(0, 0, 0.147679329, 0)
    Children.Size = UDim2.new(0, 212, 0, 241)
    Children.LayoutOrder = 99
    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.Parent = CustomWindow
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    local Settings = Instance.new("Frame")
    Settings.Name = "Settings"
    Settings.Parent = CustomWindow
    Settings.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
    Settings.BorderSizePixel = 0
    Settings.Position = UDim2.new(0, 0, 0.147679329, 0)
    Settings.Size = UDim2.new(1, 0, -0.839662433, 241)
    Settings.BackgroundTransparency = 0.100
    Settings.Visible = false
    local ModuleContainer = Instance.new("Frame")
    ModuleContainer.Name = "ModuleContainer"
    ModuleContainer.Parent = Settings
    ModuleContainer.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    ModuleContainer.BackgroundTransparency = 1.000
    ModuleContainer.BorderSizePixel = 0
    ModuleContainer.Size = UDim2.new(0, 203, 0.990886092, 0)
    local ModuleOptionsContainer = ModuleContainer -- I was getting confused with custom windows using a different variable, so i just made it the same.
    local UIListLayout = Instance.new("UIListLayout")
    UIListLayout.Padding = UDim.new(0, 0)
    UIListLayout.Parent = ModuleContainer
    UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder

    TopBar.Visible = GuiLibrary.ClickGUI.Visible
    utils:connection(GuiLibrary.ClickGUI:GetPropertyChangedSignal("Visible"):Connect(function()
        TopBar.Visible = GuiLibrary.ClickGUI.Visible
        if windowapi.Expanded then 
            windowapi.Expand()
        end
    end))

    function windowapi.Update() 
        local size = UIListLayout.AbsoluteContentSize
        ModuleContainer.Size = UDim2.new(1, 0, 0, size.Y / UIScale.Scale)
        Settings.Size = UDim2.new(1, 0, 0, (size.Y + (6 * UIScale.Scale)) / UIScale.Scale)
    end

    utils:connection(UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(windowapi.Update))

    windowapi.Update()

    function windowapi.Expand()
        if windowapi.Expanded then
            Children.Visible = true
            Settings.Visible = false
            windowapi.Expanded = false
            ModuleContainer.Visible = false
        else    
            --Children.Visible = false
            Settings.Visible = true
            windowapi.Expanded = true
            ModuleContainer.Visible = true
        end
        windowapi.Update()
    end

    dehaze.MouseButton1Click:Connect(windowapi.Expand)
    dehaze.MouseButton2Click:Connect(windowapi.Expand)

    windowapi.Instance = CustomWindow

    function windowapi.new(class) 
        local instance = Instance.new(class)
        instance.Parent = Children
        return instance
    end

    function windowapi.CreateToggle(args) 
        local toggleapi = {Enabled = args.Default or false}
        local Toggle = Instance.new("TextButton")
        Toggle.Name = "Toggle"
        Toggle.Parent = ModuleOptionsContainer
        Toggle.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Toggle.BackgroundTransparency = 1.000
        Toggle.BorderSizePixel = 0
        Toggle.Position = UDim2.new(0, 0, 2.75755095, 0)
        Toggle.Size = UDim2.new(0, 203, 0, 24)
        Toggle.Text = ""
        Toggle.AutoButtonColor = false
        toggleapi.Instance = Toggle
        local Name_7 = Instance.new("TextLabel")
        Name_7.Name = "Name"
        Name_7.Parent = Toggle
        Name_7.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
        Name_7.BackgroundTransparency = 1.000
        Name_7.BorderSizePixel = 0
        Name_7.Position = UDim2.new(0.0495016165, 0, 0, 0)
        Name_7.Size = UDim2.new(-0.197113186, 182, 1, 0)
        Name_7.Font = Enum.Font.Code
        Name_7.Text = args.Name
        Name_7.TextColor3 = Color3.fromRGB(255, 255, 255)
        Name_7.TextSize = 14.000
        Name_7.TextXAlignment = Enum.TextXAlignment.Left
        local Toggle_2 = Instance.new("TextButton")
        Toggle_2.Name = "Toggle"
        Toggle_2.Parent = Toggle
        Toggle_2.AnchorPoint = Vector2.new(0, 0.5)
        Toggle_2.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
        Toggle_2.BackgroundTransparency = 0.300
        Toggle_2.BorderSizePixel = 0
        Toggle_2.Position = UDim2.new(0, 170, 0, 14)
        Toggle_2.Size = UDim2.new(0, 21, 0, 10)
        Toggle_2.Text = ""
        Toggle_2.BorderColor3 = Color3.fromRGB(100, 100, 100)
        Toggle_2.AutoButtonColor = false
        local ToggleButton = Instance.new("TextButton")
        ToggleButton.Name = "ToggleButton"
        ToggleButton.Parent = Toggle_2
        ToggleButton.AnchorPoint = Vector2.new(0, 0.5)
        ToggleButton.BackgroundColor3 = Color3.fromRGB(2, 255, 137)
        ToggleButton.BorderSizePixel = 0
        ToggleButton.Position = UDim2.new(-0.2, 0, 0.5, 0)
        ToggleButton.Size = UDim2.new(0, 10, 0, 12)
        ToggleButton.Font = Enum.Font.Code
        ToggleButton.Text = ""
        ToggleButton.TextColor3 = Color3.fromRGB(0, 0, 0)
        ToggleButton.TextSize = 14.000
        utils:connection(ColorUpdate:Connect(function()
            ToggleButton.BackgroundColor3 = utils:getColorOfObject(ToggleButton)
        end))

        function toggleapi.Toggle() 
            if toggleapi.Enabled then 
                toggleapi.Enabled = false
                ToggleButton:TweenPosition(UDim2.fromScale(-0.2, 0.5), "Out", "Quad", 0.2, true)
            else
                toggleapi.Enabled = true
                ToggleButton:TweenPosition(UDim2.fromScale(0.6, 0.5), "Out", "Quad", 0.2, true)
            end
            if args.Function then
                args.Function(toggleapi.Enabled)
            end
        end
        utils:connection(ToggleButton.MouseButton1Click:Connect(toggleapi.Toggle))
        utils:connection(Toggle_2.MouseButton1Click:Connect(toggleapi.Toggle))
        utils:connection(Toggle.MouseButton1Click:Connect(toggleapi.Toggle))

        utils:connection(Toggle.MouseEnter:Connect(function()
            Toggle_2.BorderSizePixel = 1
        end))

        utils:connection(Toggle.MouseLeave:Connect(function()
            Toggle_2.BorderSizePixel = 0
        end))

        if (args.Default == true) then 
            toggleapi.Toggle()
        end

        utils:addObject(args.Name .. "Toggle" .. "_" .. customwindowname , {Name = args.Name, Instance = Toggle, Type = "Toggle", CustomWindow = customwindowname, API = toggleapi, args = args})

        return toggleapi
    end

    function windowapi.CreateSlider(args) 
        local sliderapi = {}
        local min, max, default, round = args.Min, args.Max, (args.Default or args.Min), (args.Round or 1)
            
        local function getValueText(value)
            if math.floor(value) == value then 
                return tostring(value) .. ".0"
            end
            return tostring(value)
        end  
        
        local Slider = Instance.new("Frame")
        Slider.Name = "Slider"
        Slider.Parent = ModuleOptionsContainer
        Slider.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Slider.BackgroundTransparency = 1.000
        Slider.BorderSizePixel = 0
        Slider.Position = UDim2.new(0, 0, 0.945145488, 0)
        Slider.Size = UDim2.new(0, 203, 0, 39)
        sliderapi.Instance = Slider
        local Name_6 = Instance.new("TextLabel")
        Name_6.Name = "Name"
        Name_6.Parent = Slider
        Name_6.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
        Name_6.BackgroundTransparency = 1.000
        Name_6.BorderSizePixel = 0
        Name_6.Position = UDim2.new(0.0495016165, 0, 0, 0)
        Name_6.Size = UDim2.new(0, 140, 0.5, 0)
        Name_6.Font = Enum.Font.Code
        Name_6.Text = args.Name
        Name_6.TextColor3 = Color3.fromRGB(255, 255, 255)
        Name_6.TextSize = 14.000
        Name_6.TextXAlignment = Enum.TextXAlignment.Left
        local Value = Instance.new("TextBox")   
        Value.Name = "Value"
        Value.Parent = Name_6
        Value.AnchorPoint = Vector2.new(0, 0.5)
        Value.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Value.BackgroundTransparency = 1.000
        Value.Position = UDim2.new(1.01400006, 0, 0.5, 0)
        Value.Size = UDim2.new(0, 39, 0, 14)
        Value.Font = Enum.Font.Code
        Value.PlaceholderText = "val"
        Value.Text = getValueText(default)
        Value.TextColor3 = Color3.fromRGB(255, 255, 255)
        Value.TextSize = 13.000
        Value.TextXAlignment = Enum.TextXAlignment.Right
        local ValueLine = Instance.new("Frame")
        ValueLine.Name = "ValueLine"
        ValueLine.Parent = Value
        ValueLine.AnchorPoint = Vector2.new(1, 0)
        ValueLine.BackgroundColor3 = Color3.fromRGB(195, 195, 195)
        ValueLine.BackgroundTransparency = 0.300
        ValueLine.BorderSizePixel = 0
        ValueLine.BorderColor3 = Color3.fromRGB(158, 158, 158)
        ValueLine.Position = UDim2.new(1, 0, 1, 0)
        ValueLine.Size = UDim2.new(.75, 0, 0, 1)
        ValueLine.Visible = false
        local SliderBack = Instance.new("Frame")
        SliderBack.Name = "SliderBack"
        SliderBack.Parent = Slider
        SliderBack.AnchorPoint = Vector2.new(0.5, 0.5)
        SliderBack.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
        SliderBack.BackgroundTransparency = 0.300
        SliderBack.BorderSizePixel = 0
        SliderBack.BorderColor3 = Color3.fromRGB(100, 100, 100)
        SliderBack.Position = UDim2.new(0.5, 0, 0.699999988, 0)
        SliderBack.Size = UDim2.new(0, 182, 0, 5)
        local SliderFill = Instance.new("Frame")
        SliderFill.Name = "SliderFill"
        SliderFill.Parent = SliderBack
        SliderFill.AnchorPoint = Vector2.new(0, 0.5)
        SliderFill.BackgroundColor3 = Color3.fromRGB(2, 255, 137)
        SliderFill.BorderSizePixel = 0
        SliderFill.Position = UDim2.new(0, 0, 0.5, 0)
        SliderFill.Size = UDim2.new(0, 50, 1, 0)
        utils:connection(ColorUpdate:Connect(function()
            SliderFill.BackgroundColor3 = utils:getColorOfObject(SliderFill)
        end))

        utils:connection(Slider.MouseEnter:Connect(function()
            SliderBack.BorderSizePixel = 1
            SliderBack.BackgroundColor3 = Color3.fromRGB(23, 23, 23)
        end))

        utils:connection(Slider.MouseLeave:Connect(function()
            SliderBack.BorderSizePixel = 0
            SliderBack.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
        end))

        utils:connection(Value.MouseEnter:Connect(function() 
            ValueLine.Visible = true
        end))

        utils:connection(Value.MouseLeave:Connect(function() 
            if not Value:IsFocused() then
                ValueLine.Visible = false
            end
        end))
        
        utils:connection(Value.Focused:Connect(function() 
            ValueLine.Visible = true
        end))

        utils:connection(Value.FocusLost:Connect(function() 
            ValueLine.Visible = false
            local parsed = tonumber(Value.Text)
            if parsed then 
                sliderapi.Set(parsed, true)
            else
                Value.Text = getValueText(sliderapi.Value)
            end
        end))
        
        local function slide(input)
            local sizeX = math.clamp((input.Position.X - SliderBack.AbsolutePosition.X) / SliderBack.AbsoluteSize.X, 0, 1)
            SliderFill.Size = UDim2.new(sizeX, 0, 1, 0)
            local value = math.round(((( (max - min) * sizeX ) + min) * (10 ^ round))) / (10 ^ round)
            sliderapi.Value = value
            Value.Text = getValueText(value)
            if args.OnInputEnded then
                return
            end
            if args.Function then
                args.Function(value)
            end
        end

        local isSliding
        utils:connection(Slider.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                isSliding = true
                slide(input)
            end
        end))

        utils:connection(Slider.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                if args.OnInputEnded then
                    if args.Function then
                        args.Function(sliderapi.Value)
                    end
                end
                isSliding = false
            end
        end))

        utils:connection(UIS.InputChanged:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement then
                if isSliding then
                    slide(input)
                end
            end
        end))

        function sliderapi.Set(value, useOverMax)
            local value = not useOverMax and math.floor((math.clamp(value, min, max) * (10^round))+0.5)/(10^round) or 
            math.clamp(value, (args.RealMin or -math.huge), (args.RealMax or math.huge))
            local sizeValue = math.floor((math.clamp(value, min, max) * (10^round))+0.5)/(10^round)
            sliderapi.Value = value
            SliderFill.Size = UDim2.new((sizeValue - min) / (max - min), 0, 1, 0)
            Value.Text = getValueText(value)
            if args.Function then
                args.Function(value)
            end
        end
        sliderapi.Set(default)

        utils:addObject(args.Name .. "Slider" .. "_" .. customwindowname, {Name = args.Name, Instance = Slider, Type = "Slider", CustomWindow = customwindowname, API = sliderapi, args = args})

        return sliderapi
    end

    function windowapi.CreateTextbox(args)
        local boxapi = {}
        local Textbox = Instance.new("Frame")
        Textbox.Name = "Textbox"
        Textbox.Parent = ModuleContainer
        Textbox.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Textbox.BackgroundTransparency = 1.000
        Textbox.BorderSizePixel = 0
        Textbox.AnchorPoint = Vector2.new(0, 0.5)
        Textbox.Position = UDim2.new(0, 0, 0.5, 0)
        Textbox.Size = UDim2.new(0, 203, 0, 30)
        boxapi.Instance = Textbox
        local Textbox_2 = Instance.new("Frame")
        Textbox_2.Name = "Textbox"
        Textbox_2.Parent = Textbox
        Textbox_2.AnchorPoint = Vector2.new(0.5, 0.5)
        Textbox_2.BackgroundColor3 = Color3.fromRGB(17, 17, 17) 
        Textbox_2.BackgroundTransparency = 0.300
        Textbox_2.BorderColor3 = Color3.fromRGB(100, 100, 100)
        Textbox_2.Position = UDim2.new(0.5, 0, 0.5, 0)
        Textbox_2.Size = UDim2.new(0, 184, 0, 22)
        Textbox_2.BorderSizePixel = 0
        local TextBoxValue = Instance.new("TextBox")
        TextBoxValue.Name = "TextBoxValue"
        TextBoxValue.Parent = Textbox_2
        TextBoxValue.AnchorPoint = Vector2.new(0.5, 0.5)
        TextBoxValue.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
        TextBoxValue.BackgroundTransparency = 1.000
        TextBoxValue.BorderSizePixel = 0
        TextBoxValue.Position = UDim2.new(0.521894395, 0, 0.5, 0)
        TextBoxValue.Size = UDim2.new(0.955993056, 0, 1, 0)
        TextBoxValue.ClearTextOnFocus = false
        TextBoxValue.Font = Enum.Font.Code
        TextBoxValue.PlaceholderColor3 = Color3.fromRGB(113, 113, 113)
        TextBoxValue.PlaceholderText = args.Name
        TextBoxValue.Text = (args.Default or "")
        TextBoxValue.TextColor3 = Color3.fromRGB(255, 255, 255)
        TextBoxValue.TextSize = 14.000
        TextBoxValue.TextXAlignment = Enum.TextXAlignment.Left

        utils:connection(Textbox_2.MouseEnter:Connect(function()
            Textbox_2.BorderSizePixel = 1
        end))

        utils:connection(Textbox_2.MouseLeave:Connect(function()
            Textbox_2.BorderSizePixel = 0
        end))

        function boxapi.Set(value) 
            local value = value or args.Default or ""
            boxapi.Value = value
            TextBoxValue.Text = value
            if args.Function then
                args.Function(value)
            end
        end

        utils:connection(TextBoxValue.FocusLost:Connect(function()
            local text = TextBoxValue.Text
            if text then
                boxapi.Set(text)
            end
        end))
        utils:addObject(args.Name .. "Textbox" .. "_" .. customwindowname, {Name = args.Name, Instance = Textbox, Type = "Textbox", CustomWindow = customwindowname, API = boxapi, args = args})
        return boxapi
    end
    windowapi.CreateTextBox = windowapi.CreateTextbox

    function windowapi.CreateDropdown(args) 
        local dropdownapi = {Values = {}, Expanded = false}
        local Dropdown = Instance.new("Frame")
        Dropdown.Name = "Dropdown"
        Dropdown.Parent = ModuleOptionsContainer
        Dropdown.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Dropdown.BackgroundTransparency = 1.000
        Dropdown.BorderSizePixel = 0
        Dropdown.Position = UDim2.new(0, 0, 0.592544496, 0)
        Dropdown.Size = UDim2.new(0, 203, 0, 28)
        dropdownapi.Instance = Dropdown
        local DropdownBack = Instance.new("Frame")
        DropdownBack.Name = "DropdownBack"
        DropdownBack.Parent = Dropdown
        DropdownBack.AnchorPoint = Vector2.new(0.5, 0.5)
        DropdownBack.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
        DropdownBack.BackgroundTransparency = 0.300
        DropdownBack.BorderSizePixel = 0
        DropdownBack.Position = UDim2.new(0.5, 0, 0, 15)
        DropdownBack.Size = UDim2.new(0, 184, 0, 22)
        DropdownBack.BorderColor3 = Color3.fromRGB(100, 100, 100)
        DropdownBack.BorderMode = Enum.BorderMode.Outline
        local Name_4 = Instance.new("TextLabel")
        Name_4.Name = "Name"
        Name_4.Parent = DropdownBack
        Name_4.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
        Name_4.BackgroundTransparency = 1.000
        Name_4.BorderSizePixel = 0
        Name_4.Position = UDim2.new(0.0440070182, 0, 0.227272734, 0)
        Name_4.Size = UDim2.new(0.046920944, 140, 0.5, 0)
        Name_4.Font = Enum.Font.Code
        Name_4.Text = args.Name
        Name_4.TextColor3 = Color3.fromRGB(255, 255, 255)
        Name_4.TextSize = 14.000
        Name_4.TextXAlignment = Enum.TextXAlignment.Left
        Name_4.TextTruncate = Enum.TextTruncate.AtEnd
        local Expand_2 = Instance.new("ImageButton")
        Expand_2.Name = "Expand"
        Expand_2.Parent = DropdownBack
        Expand_2.AnchorPoint = Vector2.new(0, 0.5)
        Expand_2.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Expand_2.BackgroundTransparency = 1.000
        Expand_2.BorderSizePixel = 0
        Expand_2.Position = UDim2.new(0.889967024, 0, 0.5, 0)
        Expand_2.Rotation = 0
        Expand_2.Size = UDim2.new(0, 19, 0, 19)
        Expand_2.ZIndex = 2
        Expand_2.Image = "http://www.roblox.com/asset/?id=6031094679"
        Expand_2.ScaleType = Enum.ScaleType.Fit
        local DropdownValues = Instance.new("Frame")
        DropdownValues.Name = "DropdownValues"
        DropdownValues.Parent = Dropdown
        DropdownValues.AnchorPoint = Vector2.new(0.5, 0.5)
        DropdownValues.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
        DropdownValues.BackgroundTransparency = 1.000
        DropdownValues.BorderSizePixel = 0
        DropdownValues.Position = UDim2.new(0.5, 0, 0, 37)
        DropdownValues.Size = UDim2.new(0, 184, 0, 22)
        DropdownValues.Visible = false
        local UIListLayout_4 = Instance.new("UIListLayout")
        UIListLayout_4.Parent = DropdownValues
        UIListLayout_4.HorizontalAlignment = Enum.HorizontalAlignment.Center
        UIListLayout_4.SortOrder = Enum.SortOrder.LayoutOrder

        utils:connection(DropdownBack.MouseEnter:Connect(function()
            DropdownBack.BorderSizePixel = 1
            DropdownBack.ZIndex = 9
        end))

        utils:connection(DropdownBack.MouseLeave:Connect(function()
            DropdownBack.BorderSizePixel = 0
            DropdownBack.ZIndex = 1
        end))

        function dropdownapi.Update() 
            local size = UIListLayout_4.AbsoluteContentSize.Y
            if DropdownValues.Visible then
                Dropdown.Size = UDim2.new(0, 203, 0, ((28 * UIScale.Scale) + size) / UIScale.Scale)
            else
                Dropdown.Size = UDim2.new(0, 203, 0, 28)
            end
        end

        utils:connection(UIListLayout_4:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(dropdownapi.Update))

        function dropdownapi.SetValue(value)
            for i,v in next, dropdownapi.Values do
                if v.Value == value then
                    if dropdownapi.Expanded then
                        --dropdownapi.Expand()
                    end
                    dropdownapi.Value = value
                    v.SelectedInstance.Visible = true
                    Name_4.Text = args.Name .. " - " .. tostring(value)
                    if args.Function then
                        args.Function(value)
                    end
                else
                    v.SelectedInstance.Visible = false
                end
            end
        end

        local function newValue(value)
            local valueapi = {}
            valueapi.Value = value
            local DropdownValue = Instance.new("TextButton")
            DropdownValue.Name = tostring(value).."DropdownValue"
            DropdownValue.Parent = DropdownValues
            DropdownValue.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
            DropdownValue.BackgroundTransparency = 0.300
            DropdownValue.BorderColor3 = Color3.fromRGB(100, 100, 100)
            DropdownValue.BorderMode = Enum.BorderMode.Outline
            DropdownValue.BorderSizePixel = 0
            DropdownValue.Size = UDim2.new(0, 184, 0, 22)
            DropdownValue.Font = Enum.Font.SourceSans
            DropdownValue.Text = ""
            DropdownValue.TextColor3 = Color3.fromRGB(0, 0, 0)
            DropdownValue.TextSize = 14.000
            DropdownValue.MouseButton1Click:Connect(function()
                dropdownapi.SetValue(value)
            end)
            utils:connection(DropdownValue.MouseEnter:Connect(function()
                DropdownValue.BorderSizePixel = 1
                DropdownValue.ZIndex = 9
            end))
            utils:connection(DropdownValue.MouseLeave:Connect(function()
                DropdownValue.BorderSizePixel = 0
                DropdownValue.ZIndex = 1
            end))
            local Name_5 = Instance.new("TextLabel")
            Name_5.Name = "Name"
            Name_5.Parent = DropdownValue
            Name_5.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
            Name_5.BackgroundTransparency = 1.000
            Name_5.BorderSizePixel = 0
            Name_5.Position = UDim2.new(0.0440070182, 0, 0.227272734, 0)
            Name_5.Size = UDim2.new(0.046920944, 140, 0.5, 0)
            Name_5.Font = Enum.Font.Code
            Name_5.Text = tostring(value)
            Name_5.TextColor3 = Color3.fromRGB(255, 255, 255)
            Name_5.TextSize = 14.000
            Name_5.TextXAlignment = Enum.TextXAlignment.Left
            local Selected = Instance.new("Frame")
            Selected.Name = "Selected"
            Selected.Parent = DropdownValue
            Selected.AnchorPoint = Vector2.new(0, 0.5)
            Selected.BackgroundColor3 = Color3.fromRGB(2, 255, 137)
            Selected.Visible = false
            Selected.BorderSizePixel = 0
            Selected.Position = UDim2.new(0, 0, 0.5, 0)
            Selected.Size = UDim2.new(0, 2, 1, 0)
            utils:connection(ColorUpdate:Connect(function()
                Selected.BackgroundColor3 = utils:getColorOfObject(Selected)
            end))
            valueapi.SelectedInstance = Selected
            valueapi.Instance = DropdownValue
            return valueapi
        end

        function dropdownapi.Expand() 
            if dropdownapi.Expanded then 
                dropdownapi.Expanded = false
                DropdownValues.Visible = false
                Expand_2.Rotation = 0
                --DropdownBack.BorderSizePixel = 1
            else
                --DropdownBack.BorderSizePixel = 0
                Expand_2.Rotation = 180
                dropdownapi.Expanded = true
                DropdownValues.Visible = true
            end
            dropdownapi.Update() 
        end
        utils:connection(Expand_2.MouseButton1Click:Connect(dropdownapi.Expand))

        for i,v in next, args.List do 
            dropdownapi.Values[#dropdownapi.Values+1] = newValue(v)
        end

        if args.Default then
            dropdownapi.SetValue(args.Default)
        end

        function dropdownapi.SetList(list)
            for i,v in next, dropdownapi.Values do
                v.Instance:Destroy()
                dropdownapi.Values[i] = nil
            end
            dropdownapi.Values = {}
            for i,v in next, list do 
                dropdownapi.Values[#dropdownapi.Values+1] = newValue(v)
            end
        end

        utils:addObject(args.Name .. "Dropdown" .. "_" .. customwindowname, {Name = args.Name, Instance = Dropdown, Type = "Dropdown", CustomWindow = customwindowname, API = dropdownapi, args = args})

        return dropdownapi
    end


    function windowapi.CreateMultiDropdown(args) 
        local dropdownapi = {Values = {}, Expanded = false}

        local MultiDropdown = Instance.new("Frame")
        MultiDropdown.Name = "MultiDropdown"
        MultiDropdown.Parent = ModuleOptionsContainer
        MultiDropdown.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        MultiDropdown.BackgroundTransparency = 1.000
        MultiDropdown.BorderSizePixel = 0
        MultiDropdown.Position = UDim2.new(0, 0, 0.769933522, 0)
        MultiDropdown.Size = UDim2.new(0, 203, 0, 72)
        dropdownapi.Instance = MultiDropdown
        local MultiDropdownBack = Instance.new("Frame")
        MultiDropdownBack.Name = "MultiDropdownBack"
        MultiDropdownBack.Parent = MultiDropdown
        MultiDropdownBack.AnchorPoint = Vector2.new(0.5, 0.5)
        MultiDropdownBack.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
        MultiDropdownBack.BackgroundTransparency = 0.300
        MultiDropdownBack.BorderSizePixel = 0
        MultiDropdownBack.Position = UDim2.new(0.5, 0, 0, 15)
        MultiDropdownBack.Size = UDim2.new(0, 184, 0, 22)
        MultiDropdownBack.BorderColor3 = Color3.fromRGB(100, 100, 100)
        local Name_8 = Instance.new("TextLabel")
        Name_8.Name = "Name"
        Name_8.Parent = MultiDropdownBack
        Name_8.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
        Name_8.BackgroundTransparency = 1.000
        Name_8.BorderSizePixel = 0
        Name_8.Position = UDim2.new(0.0440070182, 0, 0.227272734, 0)
        Name_8.Size = UDim2.new(0.046920944, 140, 0.5, 0)
        Name_8.Font = Enum.Font.Code
        Name_8.Text = args.Name
        Name_8.TextColor3 = Color3.fromRGB(255, 255, 255)
        Name_8.TextSize = 14.000
        Name_8.TextXAlignment = Enum.TextXAlignment.Left
        Name_8.TextTruncate = Enum.TextTruncate.AtEnd
        local Expand_3 = Instance.new("ImageButton")
        Expand_3.Name = "Expand"
        Expand_3.Parent = MultiDropdownBack
        Expand_3.AnchorPoint = Vector2.new(0, 0.5)
        Expand_3.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Expand_3.BackgroundTransparency = 1.000
        Expand_3.BorderSizePixel = 0
        Expand_3.Position = UDim2.new(0.889967024, 0, 0.5, 0)
        Expand_3.Rotation = 0
        Expand_3.Size = UDim2.new(0, 19, 0, 19)
        Expand_3.ZIndex = 2
        Expand_3.Image = "http://www.roblox.com/asset/?id=6031094679"
        Expand_3.ScaleType = Enum.ScaleType.Fit
        local MultiDropdownValues = Instance.new("Frame")
        MultiDropdownValues.Name = "MultiDropdownValues"
        MultiDropdownValues.Parent = MultiDropdown
        MultiDropdownValues.AnchorPoint = Vector2.new(0.5, 0.5)
        MultiDropdownValues.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
        MultiDropdownValues.BackgroundTransparency = 1.000
        MultiDropdownValues.BorderSizePixel = 0
        MultiDropdownValues.Position = UDim2.new(0.5, 0, 0, 37)
        MultiDropdownValues.Size = UDim2.new(0, 184, 0, 22)
        MultiDropdownValues.Visible = false
        local UIListLayout_6 = Instance.new("UIListLayout")
        UIListLayout_6.Parent = MultiDropdownValues
        UIListLayout_6.HorizontalAlignment = Enum.HorizontalAlignment.Center
        UIListLayout_6.SortOrder = Enum.SortOrder.LayoutOrder

        
        function dropdownapi.Update() 
            local size = UIListLayout_6.AbsoluteContentSize.Y
            if MultiDropdownValues.Visible then
                MultiDropdown.Size = UDim2.new(0, 203, 0, ((28 * UIScale.Scale) + size) / UIScale.Scale)
            else
                MultiDropdown.Size = UDim2.new(0, 203, 0, 28)
            end
        end

        utils:connection(UIListLayout_6:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(dropdownapi.Update))

        utils:connection(MultiDropdownBack.MouseEnter:Connect(function()
            MultiDropdownBack.BorderSizePixel = 1
            MultiDropdownBack.ZIndex = 9
        end))

        utils:connection(MultiDropdownBack.MouseLeave:Connect(function()
            MultiDropdownBack.BorderSizePixel = 0
            MultiDropdownBack.ZIndex = 1
        end))

        function dropdownapi.ToggleValue(value)
            for i,v in next, dropdownapi.Values do
                if v.Value == value then
                    v.Toggle()
                    --dropdownapi.Expand()
                    local tab = {}
                    local string_tab = {}
                    for i,v in next, dropdownapi.Values do 
                        if v.Enabled then 
                            tab[#tab+1] = v.Value
                            string_tab[#string_tab+1] = tostring(v.Value)
                        end
                    end
                    Name_8.Text = args.Name .. (#string_tab~=0 and (" - " .. table.concat(string_tab, ", ")) or "")
                    if args.Function then
                        args.Function(tab)
                    end
                end
            end
        end

        local function newValue(value)
            local valueapi = {Enabled = false}
            valueapi.Value = value
            local MultiDropdownValue = Instance.new("TextButton")
            MultiDropdownValue.Name = "MultiDropdownValue"
            MultiDropdownValue.Parent = MultiDropdownValues
            MultiDropdownValue.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
            MultiDropdownValue.BackgroundTransparency = 0.300
            MultiDropdownValue.BorderColor3 = Color3.fromRGB(100, 100, 100)
            MultiDropdownValue.BorderSizePixel = 0
            MultiDropdownValue.Size = UDim2.new(0, 184, 0, 22)
            MultiDropdownValue.Font = Enum.Font.SourceSans
            MultiDropdownValue.Text = ""
            MultiDropdownValue.TextColor3 = Color3.fromRGB(0, 0, 0)
            MultiDropdownValue.TextSize = 14.000
            utils:connection(MultiDropdownValue.MouseEnter:Connect(function()
                MultiDropdownValue.BorderSizePixel = 1
                MultiDropdownValue.ZIndex = 9
            end))
            utils:connection(MultiDropdownValue.MouseLeave:Connect(function()
                MultiDropdownValue.BorderSizePixel = 0
                MultiDropdownValue.ZIndex = 1
            end))
            local Name_9 = Instance.new("TextLabel")
            Name_9.Name = "Name"
            Name_9.Parent = MultiDropdownValue
            Name_9.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
            Name_9.BackgroundTransparency = 1.000
            Name_9.BorderSizePixel = 0
            Name_9.Position = UDim2.new(0.0440070182, 0, 0.227272734, 0)
            Name_9.Size = UDim2.new(0.046920944, 140, 0.5, 0)
            Name_9.Font = Enum.Font.Code
            Name_9.Text = tostring(value)
            Name_9.TextColor3 = Color3.fromRGB(255, 255, 255)
            Name_9.TextSize = 14.000
            Name_9.TextXAlignment = Enum.TextXAlignment.Left
            local Selected = Instance.new("Frame")
            Selected.Name = "Selected"
            Selected.Parent = MultiDropdownValue
            Selected.AnchorPoint = Vector2.new(0, 0.5)
            Selected.BackgroundColor3 = Color3.fromRGB(2, 255, 137)
            Selected.Visible = false
            Selected.BorderSizePixel = 0
            Selected.Position = UDim2.new(0, 0, 0.5, 0)
            Selected.Size = UDim2.new(0, 2, 1, 0)

            utils:connection(ColorUpdate:Connect(function()
                Selected.BackgroundColor3 = utils:getColorOfObject(Selected)
            end))
            
            function valueapi.Toggle() 
                if valueapi.Enabled then
                    valueapi.Enabled = false
                    Selected.Visible = false
                else
                    valueapi.Enabled = true
                    Selected.Visible = true
                end
            end

            MultiDropdownValue.MouseButton1Click:Connect(function()
                dropdownapi.ToggleValue(value)
            end)

            valueapi.SelectedInstance = Selected
            valueapi.Instance = MultiDropdownValue
            return valueapi
        end
        for i,v in next, args.List do 
            dropdownapi.Values[tostring(v)] = newValue(v)
        end

        for i,v in next, (args.Default or {}) do 
            dropdownapi.ToggleValue(v)
        end

        function dropdownapi.SetList(list)
            for i,v in next, dropdownapi.Values do
                v.Instance:Destroy()
                dropdownapi.Values[i] = nil
            end
            dropdownapi.Values = {}
            for i,v in next, list do 
                dropdownapi.Values[tostring(v)] = newValue(v)
            end
        end

        function dropdownapi.Expand() 
            if dropdownapi.Expanded then 
                dropdownapi.Expanded = false
                MultiDropdownValues.Visible = false
                Expand_3.Rotation = 0
            else
                Expand_3.Rotation = 180
                dropdownapi.Expanded = true
                MultiDropdownValues.Visible = true
            end
            dropdownapi.Update() 
        end

        dropdownapi.Update()
        utils:connection(Expand_3.MouseButton1Click:Connect(dropdownapi.Expand))
        utils:addObject(args.Name .. "MultiDropdown" .. "_" .. customwindowname, {Name = args.Name, Instance = MultiDropdown, Type = "MultiDropdown", CustomWindow = customwindowname, API = dropdownapi, args = args})

        return dropdownapi
    end

    function windowapi.CreateTextlist(args) 
        local listapi = {Values = {}}

        local Textlist = Instance.new("Frame")
        Textlist.Name = "Textlist"
        Textlist.Parent = ModuleOptionsContainer
        Textlist.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        Textlist.BackgroundTransparency = 1.000
        Textlist.BorderSizePixel = 0
        Textlist.Position = UDim2.new(0, 0, 0.0896368474, 0)
        Textlist.Size = UDim2.new(0, 203, 0, 57)
        listapi.Instance = Textlist
        local TextlistEnter = Instance.new("Frame")
        TextlistEnter.Name = "TextlistEnter"
        TextlistEnter.Parent = Textlist
        TextlistEnter.AnchorPoint = Vector2.new(0.5, 0.5)
        TextlistEnter.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
        TextlistEnter.BackgroundTransparency = 0.300
        TextlistEnter.BorderSizePixel = 0
        TextlistEnter.BorderColor3 = Color3.fromRGB(100, 100, 100)
        TextlistEnter.Position = UDim2.new(0.5, 0, 0, 15)
        TextlistEnter.Size = UDim2.new(0, 184, 0, 22)
        local TextlistBoxEnter = Instance.new("TextBox")
        TextlistBoxEnter.Name = "TextlistBoxEnter"
        TextlistBoxEnter.Parent = TextlistEnter
        TextlistBoxEnter.AnchorPoint = Vector2.new(0.5, 0.5)
        TextlistBoxEnter.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
        TextlistBoxEnter.BackgroundTransparency = 1.000
        TextlistBoxEnter.BorderSizePixel = 0
        TextlistBoxEnter.Position = UDim2.new(0.446677178, 0, 0.5, 0)
        TextlistBoxEnter.Size = UDim2.new(0.805558681, 0, 1, 0)
        TextlistBoxEnter.ClearTextOnFocus = false
        TextlistBoxEnter.Font = Enum.Font.Code
        TextlistBoxEnter.PlaceholderColor3 = Color3.fromRGB(165, 165, 165)
        TextlistBoxEnter.PlaceholderText = args.Name
        TextlistBoxEnter.Text = ""
        TextlistBoxEnter.TextColor3 = Color3.fromRGB(255, 255, 255)
        TextlistBoxEnter.TextSize = 14.000
        TextlistBoxEnter.TextXAlignment = Enum.TextXAlignment.Left
        utils:connection(TextlistEnter.MouseEnter:Connect(function()
            TextlistEnter.BorderSizePixel = 1
            TextlistEnter.ZIndex = 9
        end))
        utils:connection(TextlistEnter.MouseLeave:Connect(function()
            TextlistEnter.BorderSizePixel = 0
            TextlistEnter.ZIndex = 1
        end))
        local Add = Instance.new("TextButton")
        Add.Name = "Add"
        Add.Parent = TextlistEnter
        Add.AnchorPoint = Vector2.new(0, 0.5)
        Add.BackgroundColor3 = Color3.fromRGB(2, 255, 137)
        Add.BackgroundTransparency = 1.000
        Add.BorderSizePixel = 0
        Add.Position = UDim2.new(0.899999976, 0, 0.5, 0)
        Add.Size = UDim2.new(0, 13, 0, 14)
        Add.Font = Enum.Font.Code
        Add.Text = "+"
        Add.TextColor3 = Color3.fromRGB(170, 170, 170)
        Add.TextSize = 19.000
        utils:connection(Add.MouseEnter:Connect(function()
            Add.TextColor3 = Color3.fromRGB(255,255,255)
        end))
        utils:connection(Add.MouseLeave:Connect(function()
            Add.TextColor3 = Color3.fromRGB(170, 170, 170)
        end))
        local TextlistValues = Instance.new("Frame")
        TextlistValues.Name = "TextlistValues"
        TextlistValues.Parent = Textlist
        TextlistValues.AnchorPoint = Vector2.new(0.5, 0.5)
        TextlistValues.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
        TextlistValues.BackgroundTransparency = 1.000
        TextlistValues.BorderSizePixel = 0
        TextlistValues.Position = UDim2.new(0.5, 0, 0, 37)
        TextlistValues.Size = UDim2.new(0, 184, 0, 22)
        local UIListLayout = Instance.new("UIListLayout")
        UIListLayout.Parent = TextlistValues
        UIListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
        UIListLayout.SortOrder = Enum.SortOrder.LayoutOrder
        
        UIListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            --TextlistValues.Size = UDim2.new(0, 184, 0, UIListLayout.AbsoluteContentSize.Y + 22)
            Textlist.Size = UDim2.new(0, 203, 0, (UIListLayout.AbsoluteContentSize.Y + (37 * UIScale.Scale)) / UIScale.Scale)
        end)
        Textlist.Size = UDim2.new(0, 203, 0, (UIListLayout.AbsoluteContentSize.Y + (37 * UIScale.Scale)) / UIScale.Scale)

        local function addValue(value) 
            local valueapi = {}
            valueapi.value = value
            local TextlistValue = Instance.new("TextButton")
            TextlistValue.Name = "TextlistValue"
            TextlistValue.Parent = TextlistValues
            TextlistValue.AnchorPoint = Vector2.new(0.5, 0.5)
            TextlistValue.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
            TextlistValue.BackgroundTransparency = 0.300
            TextlistValue.BorderSizePixel = 0
            TextlistValue.Position = UDim2.new(0.5, 0, 0.5, 0)
            TextlistValue.Size = UDim2.new(0, 184, 0, 22)
            TextlistValue.Text = ""
            TextlistValue.BorderColor3 = Color3.fromRGB(100, 100, 100)
            local TextlistBoxEnter_2 = Instance.new("TextLabel")
            TextlistBoxEnter_2.Name = "TextlistBoxEnter"
            TextlistBoxEnter_2.Parent = TextlistValue
            TextlistBoxEnter_2.AnchorPoint = Vector2.new(0.5, 0.5)
            TextlistBoxEnter_2.BackgroundColor3 = Color3.fromRGB(17, 17, 17)
            TextlistBoxEnter_2.BackgroundTransparency = 1.000
            TextlistBoxEnter_2.BorderSizePixel = 0
            TextlistBoxEnter_2.Position = UDim2.new(0.446677178, 0, 0.5, 0)
            TextlistBoxEnter_2.Size = UDim2.new(0.805558681, 0, 1, 0)
            TextlistBoxEnter_2.Font = Enum.Font.Code
            TextlistBoxEnter_2.Text = value
            TextlistBoxEnter_2.TextColor3 = Color3.fromRGB(255, 255, 255)
            TextlistBoxEnter_2.TextSize = 14.000
            TextlistBoxEnter_2.TextXAlignment = Enum.TextXAlignment.Left
            utils:connection(TextlistValue.MouseEnter:Connect(function()
                TextlistValue.BorderSizePixel = 1
                TextlistValue.ZIndex = 9
            end))
            utils:connection(TextlistValue.MouseLeave:Connect(function()
                TextlistValue.BorderSizePixel = 0
                TextlistValue.ZIndex = 1
            end))
            local Remove = Instance.new("TextButton")
            Remove.Name = "Remove"
            Remove.Parent = TextlistValue
            Remove.AnchorPoint = Vector2.new(0, 0.5)
            Remove.BackgroundColor3 = Color3.fromRGB(2, 255, 137)
            Remove.BackgroundTransparency = 1.000
            Remove.BorderSizePixel = 0
            Remove.Position = UDim2.new(0.899999858, 0, 0.431818187, 0)
            Remove.Size = UDim2.new(0, 13, 0, 11)
            Remove.Font = Enum.Font.Jura
            Remove.Text = "x"
            Remove.TextColor3 = Color3.fromRGB(170, 170, 170)
            Remove.TextSize = 18.000
            valueapi.Instance = TextlistValue

            utils:connection(Remove.MouseEnter:Connect(function()
                Remove.TextColor3 = Color3.fromRGB(255,255,255)
            end))
            utils:connection(Remove.MouseLeave:Connect(function()
                Remove.TextColor3 = Color3.fromRGB(170, 170, 170)
            end))

            function valueapi.Remove()
                listapi.Values[valueapi.value] = nil
                TextlistValue:Destroy()
            end

            utils:connection(Remove.MouseButton1Click:Connect(function()
                valueapi.Remove()
            end))

            utils:connection(TextlistValue.MouseButton1Click:Connect(function()
                valueapi.Remove()
            end))

            return valueapi
        end

        function listapi.Add(value)
            if listapi.Values[value] then
                return
            end
            addValue(value)
            listapi.Values[value] = value
            if args.Function then
                args.Function(listapi.Values)
            end
        end

        if args.Default then
            for i, v in next, args.Default do
                listapi.Add(v)
            end
        end

        Add.MouseButton1Click:Connect(function() 
            local value = TextlistBoxEnter.Text
            if value == "" then
                return
            end
            listapi.Add(value)
            TextlistBoxEnter.Text = ""
        end)
    end
    
    utils:addObject(args.Name .. "CustomWindow", {Name = args.Name, Instance = CustomWindow, Type = "CustomWindow", API = windowapi, args = args})
    return windowapi
end

utils:connection(UIS.InputBegan:Connect(function(input)
    if UIS:GetFocusedTextBox() then 
        return 
    end

    if input.KeyCode == Enum.KeyCode.Unknown then
        return
    end
    
    local key = input.KeyCode.Name
    if key == 'Backspace' or key == 'Delete' or key == 'Escape' then
        key = nil
    end
    if GuiLibrary.Objects then
        for i,v in next, GuiLibrary.Objects do 
            if GuiLibrary.IsRecording then
                if v.Type == 'OptionsButton' and v.API.Recording then
                    GuiLibrary.IsRecording = false
                    v.API.Recording = false
                    v.API.SetBind(key)
                    return
                end
            else
                if v.Type == 'OptionsButton' and v.API.Bind == (key or "") then
                    v.API.Toggle(true)
                end
            end
        end
    end
end))

return GuiLibrary
