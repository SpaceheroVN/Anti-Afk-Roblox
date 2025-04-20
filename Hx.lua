-- Anti AFK Script with Lag-Reduction Prompt
local UserInputService    = game:GetService("UserInputService")
local Players             = game:GetService("Players")
local RunService          = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService        = game:GetService("TweenService")

-- Core parameters
local afkThreshold         = 180
local interventionInterval = 600
local checkInterval        = 60
local notificationDuration = 5
local animationTime        = 0.5
local iconAssetId          = "rbxassetid://117118515787811"
local enableIntervention   = true

-- Disable intervention if VirtualInputManager unavailable
if not VirtualInputManager or not VirtualInputManager.SendKeyEvent then
    warn("AntiAFK: VirtualInputManager unavailable; disabling automatic intervention.")
    enableIntervention = false
end

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

-- Create notification template
local function createNotificationTemplate()
    if notificationTemplate then return notificationTemplate end
    local frame = Instance.new("Frame")
    frame.Name = "NotificationFrameTemplate"
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Size = guiSize
    frame.ClipsDescendants = true

    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
    local pad = Instance.new("UIPadding", frame)
    pad.PaddingLeft = UDim.new(0,10); pad.PaddingRight = UDim.new(0,10)
    pad.PaddingTop  = UDim.new(0,5);  pad.PaddingBottom = UDim.new(0,5)

    local list = Instance.new("UIListLayout", frame)
    list.FillDirection = Enum.FillDirection.Horizontal
    list.VerticalAlignment = Enum.VerticalAlignment.Center
    list.Padding = UDim.new(0,10)

    local icon = Instance.new("ImageLabel", frame)
    icon.Name = "Icon"; icon.Image = iconAssetId
    icon.BackgroundTransparency = 1; icon.ImageTransparency = 1
    icon.Size = UDim2.new(0,40,0,40); icon.LayoutOrder = 1

    local textFrame = Instance.new("Frame", frame)
    textFrame.Name = "TextFrame"; textFrame.BackgroundTransparency = 1
    textFrame.Size = UDim2.new(1,0,1,0); textFrame.LayoutOrder = 2
    local txtList = Instance.new("UIListLayout", textFrame)
    txtList.FillDirection = Enum.FillDirection.Horizontal
    txtList.HorizontalAlignment = Enum.HorizontalAlignment.Left
    txtList.VerticalAlignment = Enum.VerticalAlignment.Center
    txtList.Padding = UDim.new(0,5)

    local title = Instance.new("TextLabel", textFrame)
    title.Name = "Title"; title.Text = ""; title.Font = Enum.Font.GothamBold
    title.TextSize = 15; title.TextColor3 = Color3.new(1,1,1)
    title.BackgroundTransparency = 1; title.TextTransparency = 1
    title.AutomaticSize = Enum.AutomaticSize.X; title.LayoutOrder = 1

    local msg = Instance.new("TextLabel", textFrame)
    msg.Name = "Message"; msg.Text = ""; msg.Font = Enum.Font.Gotham
    msg.TextSize = 13; msg.TextColor3 = Color3.fromRGB(200,200,200)
    msg.BackgroundTransparency = 1; msg.TextTransparency = 1
    msg.AutomaticSize = Enum.AutomaticSize.X; msg.LayoutOrder = 2

    notificationTemplate = frame
    return frame
end

-- Setup notification container
local function setupNotificationContainer()
    if notificationContainer and notificationContainer.Parent then return notificationContainer end
    local pg = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui",10)
    if not pg then warn("AntiAFK: PlayerGui not found.") return end
    local old = pg:FindFirstChild("AntiAFKContainerGui"); if old then old:Destroy() end

    local sg = Instance.new("ScreenGui", pg)
    sg.Name = "AntiAFKContainerGui"; sg.ResetOnSpawn = false; sg.DisplayOrder = 999
    local cont = Instance.new("Frame", sg)
    cont.Name = "NotificationContainer"; cont.AnchorPoint = Vector2.new(1,1)
    cont.Position = UDim2.new(1,-18,1,-48); cont.Size = UDim2.new(0,300,0,200)
    cont.BackgroundTransparency = 1

    local layout = Instance.new("UIListLayout", cont)
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    layout.Padding = UDim.new(0,5)

    notificationContainer = cont
    return cont
end

-- Show basic notification
local function showNotification(titleText, messageText)
    setupNotificationContainer(); createNotificationTemplate()
    local cont = notificationContainer; local tmp = notificationTemplate
    if not cont or not tmp then warn("AntiAFK: Cannot show notification, missing container or template.") return end

    local ok, frame = pcall(function() return tmp:Clone() end)
    if not ok or not frame then warn("AntiAFK: Failed to clone template.") return end
    frame.Name = "Notification_"..titleText; frame.Parent = cont

    local tf = frame:FindFirstChild("TextFrame")
    if tf then tf.Title.Text = titleText; tf.Message.Text = messageText end
    local icon = frame:FindFirstChild("Icon")

    local tweenIn = TweenInfo.new(animationTime)
    TweenService:Create(frame, tweenIn, {BackgroundTransparency = 0.2}):Play()
    if icon then TweenService:Create(icon, tweenIn, {ImageTransparency = 0}):Play() end
    for _, child in ipairs(tf and tf:GetChildren() or {}) do
        if child:IsA("TextLabel") then
            TweenService:Create(child, tweenIn, {TextTransparency = 0}):Play()
        end
    end

    task.delay(notificationDuration, function()
        if frame and frame.Parent then
            local tweenOut = TweenInfo.new(animationTime)
            TweenService:Create(frame, tweenOut, {BackgroundTransparency = 1}):Play()
            if icon then TweenService:Create(icon, tweenOut, {ImageTransparency = 1}):Play() end
            for _, child in ipairs(tf and tf:GetChildren() or {}) do
                if child:IsA("TextLabel") then
                    TweenService:Create(child, tweenOut, {TextTransparency = 1}):Play()
                end
            end
            -- destroy after tween
            TweenService:Create(frame, tweenOut, {}):Completed:Connect(function()
                if frame then frame:Destroy() end
            end)
        end
    end)
end

-- Simulate key press
local function performAntiAFKAction()
    if not enableIntervention then return end
    local ok, err = pcall(function()
        VirtualInputManager:SendKeyEvent(true, simulatedKeyCode, false, game)
        task.wait(0.05 + math.random()*0.05)
        VirtualInputManager:SendKeyEvent(false, simulatedKeyCode, false, game)
    end)
    if ok then
        lastInterventionTime = os.clock(); interventionCounter += 1
        print("AntiAFK: Intervention #"..interventionCounter)
    else
        warn("AntiAFK: Simulation failed:", err)
    end
end

-- Handle user input
local function onInput()
    if isConsideredAFK then
        isConsideredAFK = false; lastInterventionTime = 0; interventionCounter = 0
        showNotification("Bạn đã quay lại!","Đã tạm dừng can thiệp AFK.")
    end
    lastInputTime = os.clock()
end

-- Cleanup
local function cleanup()
    if inputBeganConnection then inputBeganConnection:Disconnect() end
    if inputChangedConnection then inputChangedConnection:Disconnect() end
    if notificationContainer and notificationContainer.Parent then notificationContainer:Destroy() end
    notificationContainer = nil; notificationTemplate = nil
end

-- Apply lowest graphics
local function applyLowGraphics()
    local okGS, UGS = pcall(function() return UserSettings():GetService("UserGameSettings") end)
    if okGS and UGS then
        if UGS.SetVisualSettingsOverride then
            UGS:SetVisualSettingsOverride(Enum.SavedQualitySetting.QualityLevel1)
        elseif UGS.SetQualityLevel then
            UGS:SetQualityLevel(Enum.SavedQualitySetting.QualityLevel1, true)
        end
    end
    if game.Lighting then game.Lighting.GlobalShadows = false; game.Lighting.FogEnd = 0 end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then obj.Enabled = false end
    end
    showNotification("Đang giảm lag...","Thành công!!!!")
end

-- Show lag prompt
local function showLagOptionNotification()
    setupNotificationContainer(); createNotificationTemplate()
    local cont = notificationContainer; local tmp = notificationTemplate
    if not cont or not tmp then warn("AntiAFK: Cannot show lag prompt.") return end
    local ok, frame = pcall(function() return tmp:Clone() end)
    if not ok or not frame then warn("AntiAFK: Failed to clone template for lag prompt.") return end
    frame.Name = "LagOptionPrompt"; frame.Size = UDim2.new(0,300,0,100); frame.Parent = cont

    local tf = frame:FindFirstChild("TextFrame")
    if tf then tf.Title.Text = "Bạn có muốn giảm lag không?"; tf.Message.Text = "" end

    local btnCon = Instance.new("Frame", frame)
    btnCon.Name = "BtnContainer"; btnCon.BackgroundTransparency=1
    btnCon.Size = UDim2.new(1,0,0,30); btnCon.Position=UDim2.new(0,0,1,-35)
    local lay=Instance.new("UIListLayout",btnCon)
    lay.FillDirection=Enum.FillDirection.Horizontal; lay.HorizontalAlignment=Enum.HorizontalAlignment.Center; lay.Padding=UDim.new(0,10)

    local yes=Instance.new("TextButton",btnCon)
    yes.Text="Có"; yes.Size=UDim2.new(0,100,1,-10); yes.Font=Enum.Font.GothamBold; yes.TextSize=14
    yes.BackgroundColor3=Color3.fromRGB(50,200,50); yes.TextColor3=Color3.new(1,1,1)
    yes.MouseButton1Click:Connect(function() frame:Destroy(); applyLowGraphics() end)

    local no=yes:Clone(); no.Name="No"; no.Text="Không"; no.Parent=btnCon; no.BackgroundColor3=Color3.fromRGB(200,50,50)
    no.MouseButton1Click:Connect(function() frame:Destroy() end)
end

-- Main
local function main()
    setupNotificationContainer(); createNotificationTemplate()
    inputBeganConnection = UserInputService.InputBegan:Connect(function(i, gp) if not gp and (i.UserInputType==Enum.UserInputType.Keyboard or i.UserInputType==Enum.UserInputType.MouseButton1) then onInput() end end)
    inputChangedConnection = UserInputService.InputChanged:Connect(function(i, gp) if not gp and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.MouseWheel) then onInput() end end)
    task.wait(3)
    showNotification("Anti AFK","Đã được kích hoạt.")
    showLagOptionNotification()
    while true do
        task.wait(0.5)
        local now = os.clock(); local idle = now - lastInputTime
        if isConsideredAFK then
            if now - lastInterventionTime >= interventionInterval then performAntiAFKAction() end
            if now - lastCheckTime >= checkInterval then showNotification("Vẫn đang AFK...",string.format("Can thiệp sau ~%.0f giây.",interventionInterval - (now - lastInterventionTime))); lastCheckTime=now end
        elseif idle >= afkThreshold then
            isConsideredAFK=true; lastInterventionTime=now; lastCheckTime=now; interventionCounter=0
            showNotification("Cảnh báo AFK!",string.format("Sẽ can thiệp sau ~%.0f giây.",interventionInterval)); print("AntiAFK: AFK detected.")
        end
    end
end

-- Start with error capture
local thread = coroutine.create(main)
local ok, err = coroutine.resume(thread)
if not ok then warn("AntiAFK Lỗi Khởi Tạo:", err) end
Players.PlayerRemoving:Connect(function(p) if p==player then cleanup() end end)
