-- Anti AFK Script with Lag-Reduction Prompt
local UserInputService      = game:GetService("UserInputService")
local Players               = game:GetService("Players")
local RunService            = game:GetService("RunService")
local VirtualInputManager   = game:GetService("VirtualInputManager")
local TweenService          = game:GetService("TweenService")

-- Graphics settings service
local successUGS, UserGameSettings = pcall(function()
    return UserSettings():GetService("UserGameSettings")
end)

-- Core parameters
local afkThreshold          = 180
local interventionInterval  = 600
local checkInterval         = 60
local notificationDuration  = 5
local animationTime         = 0.5
local iconAssetId           = "rbxassetid://117118515787811"
local enableIntervention    = true
local simulatedKeyCode      = Enum.KeyCode.Space

-- State vars
local lastInputTime         = os.clock()
local lastInterventionTime  = 0
local lastCheckTime         = 0
local interventionCounter   = 0
local isConsideredAFK       = false

-- GUI vars
local notificationContainer = nil
local notificationTemplate  = nil
local inputBeganConnection  = nil
local inputChangedConnection = nil
local player                = Players.LocalPlayer
local guiSize               = UDim2.new(0, 250, 0, 60)

-- Create notification template once
local function createNotificationTemplate()
    if notificationTemplate then return notificationTemplate end
    local frame = Instance.new("Frame")
    frame.Name = "NotificationFrameTemplate"
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Size = guiSize
    frame.ClipsDescendants = true

    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 8)
    local padding = Instance.new("UIPadding", frame)
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.PaddingTop = UDim.new(0, 5)
    padding.PaddingBottom = UDim.new(0, 5)

    local listLayout = Instance.new("UIListLayout", frame)
    listLayout.FillDirection = Enum.FillDirection.Horizontal
    listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 10)

    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.Image = iconAssetId
    icon.BackgroundTransparency = 1
    icon.ImageTransparency = 1
    icon.Size = UDim2.new(0, 40, 0, 40)
    icon.LayoutOrder = 1
    icon.Parent = frame

    local textFrame = Instance.new("Frame", frame)
    textFrame.Name = "TextFrame"
    textFrame.BackgroundTransparency = 1
    textFrame.Size = UDim2.new(1, 0, 1, 0)
    textFrame.LayoutOrder = 2

    local textListLayout = Instance.new("UIListLayout", textFrame)
    textListLayout.FillDirection = Enum.FillDirection.Horizontal
    textListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    textListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    textListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    textListLayout.Padding = UDim.new(0, 5)

    local title = Instance.new("TextLabel", textFrame)
    title.Name = "Title"
    title.Text = "Title"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 15
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.BackgroundTransparency = 1
    title.TextTransparency = 1
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.AutomaticSize = Enum.AutomaticSize.X
    title.Size = UDim2.new(0, 0, 1, 0)
    title.LayoutOrder = 1

    local message = Instance.new("TextLabel", textFrame)
    message.Name = "Message"
    message.Text = "Message"
    message.Font = Enum.Font.Gotham
    message.TextSize = 13
    message.TextColor3 = Color3.fromRGB(200, 200, 200)
    message.BackgroundTransparency = 1
    message.TextTransparency = 1
    message.TextXAlignment = Enum.TextXAlignment.Left
    message.AutomaticSize = Enum.AutomaticSize.X
    message.Size = UDim2.new(0, 0, 1, 0)
    message.LayoutOrder = 2

    notificationTemplate = frame
    return frame
end

-- Setup container for stacking notifications
local function setupNotificationContainer()
    if notificationContainer and notificationContainer.Parent then return notificationContainer end
    local playerGui = player:WaitForChild("PlayerGui", 20)
    if not playerGui then warn("AntiAFK: No PlayerGui.") return end
    local old = playerGui:FindFirstChild("AntiAFKContainerGui")
    if old then old:Destroy() end

    local screenGui = Instance.new("ScreenGui", playerGui)
    screenGui.Name = "AntiAFKContainerGui"
    screenGui.ResetOnSpawn = false
    screenGui.DisplayOrder = 999

    local container = Instance.new("Frame", screenGui)
    container.Name = "NotificationContainer"
    container.AnchorPoint = Vector2.new(1,1)
    container.Position = UDim2.new(1,-18,1,-48)
    container.Size = UDim2.new(0, 300, 0, 200)
    container.BackgroundTransparency = 1

    local layout = Instance.new("UIListLayout", container)
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0,5)

    notificationContainer = container
    return container
end

-- Display a basic notification
local function showNotification(titleText, messageText)
    if not notificationContainer or not notificationContainer.Parent then setupNotificationContainer() end
    if not notificationTemplate then createNotificationTemplate() end

    local frame = notificationTemplate:Clone()
    frame.Name = "Notification_"..titleText
    frame.Parent = notificationContainer
    frame.BackgroundTransparency = 1

    -- set texts
    local icon = frame:FindFirstChild("Icon")
    local txt = frame:FindFirstChild("TextFrame")
    if txt then
        txt.Title.Text = titleText
        txt.Message.Text = messageText
    end

    -- animate in
    TweenService:Create(frame, TweenInfo.new(animationTime), {BackgroundTransparency = 0.2}):Play()
    if icon then TweenService:Create(icon, TweenInfo.new(animationTime), {ImageTransparency = 0}):Play() end
    for _, child in ipairs(txt and txt:GetChildren() or {}) do
        if child:IsA("TextLabel") then
            TweenService:Create(child, TweenInfo.new(animationTime), {TextTransparency = 0}):Play()
        end
    end

    -- auto remove after duration
    task.delay(notificationDuration, function()
        if frame and frame.Parent then
            local t = TweenInfo.new(animationTime)
            TweenService:Create(frame, t, {BackgroundTransparency = 1}):Play()
            if icon then TweenService:Create(icon, t, {ImageTransparency = 1}):Play() end
            for _, child in ipairs(txt and txt:GetChildren() or {}) do
                if child:IsA("TextLabel") then
                    TweenService:Create(child, t, {TextTransparency = 1}):Play()
                end
            end
            TweenService:Create(frame, t, {}).Completed:Connect(function()
                frame:Destroy()
            end)
        end
    end)
end

-- Simulate a key to prevent AFK
local function performAntiAFKAction()
    if not enableIntervention then return end
    local ok, err = pcall(function()
        VirtualInputManager:SendKeyEvent(true, simulatedKeyCode, false, game)
        task.wait(0.05 + math.random()*0.05)
        VirtualInputManager:SendKeyEvent(false, simulatedKeyCode, false, game)
    end)
    if ok then
        lastInterventionTime = os.clock()
        interventionCounter = interventionCounter + 1
        print("AntiAFK: Intervention #"..interventionCounter)
    else
        warn("AntiAFK: Simulation failed:", err)
    end
end

-- Reset AFK state on input
local function onInput()
    if isConsideredAFK then
        isConsideredAFK = false
        lastInterventionTime = 0
        interventionCounter = 0
        showNotification("Bạn đã quay lại!", "Đã tạm dừng can thiệp AFK.")
        print("AntiAFK: Back from AFK.")
    end
    lastInputTime = os.clock()
end

-- Cleanup on exit
local function cleanup()
    if inputBeganConnection then inputBeganConnection:Disconnect() end
    if inputChangedConnection then inputChangedConnection:Disconnect() end
    if notificationContainer and notificationContainer.Parent then notificationContainer:Destroy() end
    notificationContainer = nil
    notificationTemplate = nil
end

-- Apply lowest graphics settings
local function applyLowGraphics()
    if successUGS then
        if UserGameSettings.SetVisualSettingsOverride then
            UserGameSettings:SetVisualSettingsOverride(Enum.SavedQualitySetting.QualityLevel1)
        elseif UserGameSettings.SetQualityLevel then
            UserGameSettings:SetQualityLevel(Enum.SavedQualitySetting.QualityLevel1, true)
        end
    end
    -- Lighting tweaks
    if game.Lighting then
        game.Lighting.GlobalShadows = false
        game.Lighting.FogEnd = 0
    end
    -- Disable heavy effects
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
            obj.Enabled = false
        end
    end
    showNotification("Đang giảm lag...", "Thành công!!!!")
end

-- Show prompt with two buttons
local function showLagOptionNotification()
    if not notificationContainer or not notificationContainer.Parent then setupNotificationContainer() end
    if not notificationTemplate then createNotificationTemplate() end

    local frame = notificationTemplate:Clone()
    frame.Name = "LagOptionPrompt"
    frame.Size = UDim2.new(0, 300, 0, 100)
    frame.Parent = notificationContainer

    local textFrame = frame:FindFirstChild("TextFrame")
    if textFrame then
        textFrame.Title.Text = "Bạn có muốn giảm lag không?"
        textFrame.Message.Text = ""
    end

    -- Buttons
    local btnContainer = Instance.new("Frame", frame)
    btnContainer.Name = "BtnContainer"
    btnContainer.BackgroundTransparency = 1
    btnContainer.Size = UDim2.new(1,0,0,30)
    btnContainer.Position = UDim2.new(0,0,1,-35)
    local layout = Instance.new("UIListLayout", btnContainer)
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.Padding = UDim.new(0,10)

    local yesBtn = Instance.new("TextButton", btnContainer)
    yesBtn.Name = "Yes"
    yesBtn.Text = "Có"
    yesBtn.Font = Enum.Font.GothamBold
    yesBtn.TextSize = 14
    yesBtn.Size = UDim2.new(0,100,1,-10)
    yesBtn.BackgroundColor3 = Color3.fromRGB(50,200,50)
    yesBtn.TextColor3 = Color3.new(1,1,1)
    yesBtn.MouseButton1Click:Connect(function()
        frame:Destroy()
        applyLowGraphics()
    end)

    local noBtn = yesBtn:Clone()
    noBtn.Name = "No"
    noBtn.Text = "Không"
    noBtn.BackgroundColor3 = Color3.fromRGB(200,50,50)
    noBtn.Parent = btnContainer
    noBtn.MouseButton1Click:Connect(function()
        frame:Destroy()
    end)
end

-- Main loop
local function main()
    setupNotificationContainer()
    createNotificationTemplate()

    inputBeganConnection = UserInputService.InputBegan:Connect(function(input, gp)
        if not gp and (input.UserInputType==Enum.UserInputType.Keyboard or input.UserInputType==Enum.UserInputType.MouseButton1) then
            onInput()
        end
    end)
    inputChangedConnection = UserInputService.InputChanged:Connect(function(input, gp)
        if not gp and (input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.MouseWheel) then
            onInput()
        end
    end)

    task.wait(3)
    showNotification("Anti AFK", "Đã được kích hoạt.")
    showLagOptionNotification()

    while true do
        task.wait(0.5)
        local now = os.clock()
        local idle = now - lastInputTime
        if isConsideredAFK then
            if now - lastInterventionTime >= interventionInterval then performAntiAFKAction() end
            if now - lastCheckTime >= checkInterval then
                showNotification("Vẫn đang AFK...", string.format("Can thiệp sau ~%.0f giây.", interventionInterval - (now - lastInterventionTime)))
                lastCheckTime = now
            end
        elseif idle >= afkThreshold then
            isConsideredAFK = true
            lastInterventionTime = now
            lastCheckTime = now
            interventionCounter = 0
            showNotification("Cảnh báo AFK!", string.format("Sẽ can thiệp sau ~%.0f giây.", interventionInterval))
            print("AntiAFK: AFK detected.")
        end
    end
end

-- Start
coroutine.wrap(main)()
Players.PlayerRemoving:Connect(function(p)
    if p==player then cleanup() end
end)
