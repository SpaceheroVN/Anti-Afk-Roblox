-- Anti AFK & Lag Reduction Script (Optimized & Concise)

local UIS         = game:GetService("UserInputService")
local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local VIM         = game:GetService("VirtualInputManager")
local TweenSvc    = game:GetService("TweenService")
local player      = Players.LocalPlayer

-- Core parameters
local AFK_THRESHOLD      = 180      -- Thời gian chờ (giây) trước khi xem là AFK
local INTERVAL           = 600      -- Khoảng cách giữa các can thiệp (giây)
local CHECK_INTERVAL     = 60       -- Khoảng cách giữa các lần thông báo trong khi AFK
local NOTIF_DURATION     = 5        -- Thời gian hiển thị thông báo (giây)
local TWEEN_TIME         = 0.5      -- Thời gian hiệu ứng tween
local ICON_ID            = "rbxassetid://117118515787811"
local INTERVENTION_EN    = (VIM and VIM.SendKeyEvent) and true or false
local simulatedKeyCode   = Enum.KeyCode.Space   -- Phím được mô phỏng

-- State variables
local lastInputTime      = os.clock()
local lastIntervention   = 0
local lastCheckTime      = 0
local interventionCount  = 0
local isAFK              = false

-- GUI variables
local notificationContainer, notificationTemplate
local inputBeganConn, inputChangedConn

-- Create Notification Template
local function createTemplate()
    if notificationTemplate then return notificationTemplate end
    local frame = Instance.new("Frame")
    frame.Name, frame.BackgroundColor3, frame.BackgroundTransparency, frame.BorderSizePixel, frame.Size, frame.ClipsDescendants =
        "NotificationFrameTemplate", Color3.fromRGB(30,30,30), 1, 0, UDim2.new(0,250,0,60), true
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0,8)
    local pad = Instance.new("UIPadding", frame)
    pad.PaddingLeft, pad.PaddingRight, pad.PaddingTop, pad.PaddingBottom =
        UDim.new(0,10), UDim.new(0,10), UDim.new(0,5), UDim.new(0,5)
    local lst = Instance.new("UIListLayout", frame)
    lst.FillDirection, lst.VerticalAlignment, lst.Padding =
        Enum.FillDirection.Horizontal, Enum.VerticalAlignment.Center, UDim.new(0,10)
    local icon = Instance.new("ImageLabel", frame)
    icon.Name, icon.Image, icon.BackgroundTransparency, icon.ImageTransparency, icon.Size, icon.LayoutOrder =
        "Icon", ICON_ID, 1, 1, UDim2.new(0,40,0,40), 1
    local txtFrame = Instance.new("Frame", frame)
    txtFrame.Name, txtFrame.BackgroundTransparency, txtFrame.Size, txtFrame.LayoutOrder =
        "TextFrame", 1, UDim2.new(1,0,1,0), 2
    local txtLst = Instance.new("UIListLayout", txtFrame)
    txtLst.FillDirection, txtLst.HorizontalAlignment, txtLst.VerticalAlignment, txtLst.Padding =
        Enum.FillDirection.Horizontal, Enum.HorizontalAlignment.Left, Enum.VerticalAlignment.Center, UDim.new(0,5)
    local title = Instance.new("TextLabel", txtFrame)
    title.Name, title.Text, title.Font, title.TextSize, title.TextColor3, title.BackgroundTransparency, title.TextTransparency, title.AutomaticSize, title.LayoutOrder =
        "Title", "", Enum.Font.GothamBold, 15, Color3.new(1,1,1), 1, 1, Enum.AutomaticSize.X, 1
    local msg = Instance.new("TextLabel", txtFrame)
    msg.Name, msg.Text, msg.Font, msg.TextSize, msg.TextColor3, msg.BackgroundTransparency, msg.TextTransparency, msg.AutomaticSize, msg.LayoutOrder =
        "Message", "", Enum.Font.Gotham, 13, Color3.fromRGB(200,200,200), 1, 1, Enum.AutomaticSize.X, 2
    notificationTemplate = frame
    return frame
end

-- Setup Notification Container
local function setupContainer()
    if notificationContainer and notificationContainer.Parent then return notificationContainer end
    local pg = player:FindFirstChild("PlayerGui") or player:WaitForChild("PlayerGui",10)
    if not pg then warn("PlayerGui not found.") return end
    local old = pg:FindFirstChild("AntiAFKContainerGui")
    if old then old:Destroy() end
    local sg = Instance.new("ScreenGui", pg)
    sg.Name, sg.ResetOnSpawn, sg.DisplayOrder = "AntiAFKContainerGui", false, 999
    local cont = Instance.new("Frame", sg)
    cont.Name, cont.AnchorPoint, cont.Position, cont.Size, cont.BackgroundTransparency =
        "NotificationContainer", Vector2.new(1,1), UDim2.new(1,-18,1,-48), UDim2.new(0,300,0,200), 1
    local lay = Instance.new("UIListLayout", cont)
    lay.FillDirection, lay.HorizontalAlignment, lay.VerticalAlignment, lay.Padding =
        Enum.FillDirection.Vertical, Enum.HorizontalAlignment.Right, Enum.VerticalAlignment.Bottom, UDim.new(0,5)
    notificationContainer = cont
    return cont
end

-- Show Notification
local function showNotification(titleText, msgText)
    local cont = setupContainer() or return
    local tmpl = createTemplate() or return
    local frame = tmpl:Clone()
    frame.Name = "Notification_"..titleText
    frame.Parent = cont
    local tf = frame:FindFirstChild("TextFrame")
    if tf then
        tf.Title.Text, tf.Message.Text = titleText, msgText
    end
    local tweenIn = TweenInfo.new(TWEEN_TIME)
    TweenSvc:Create(frame, tweenIn, {BackgroundTransparency = 0.2}):Play()
    local icon = frame:FindFirstChild("Icon")
    if icon then TweenSvc:Create(icon, tweenIn, {ImageTransparency = 0}):Play() end
    for _, child in ipairs(tf:GetChildren()) do
        if child:IsA("TextLabel") then TweenSvc:Create(child, tweenIn, {TextTransparency = 0}):Play() end
    end
    task.delay(NOTIF_DURATION, function()
        local tweenOut = TweenInfo.new(TWEEN_TIME)
        TweenSvc:Create(frame, tweenOut, {BackgroundTransparency = 1}):Play()
        if icon then TweenSvc:Create(icon, tweenOut, {ImageTransparency = 1}):Play() end
        for _, child in ipairs(tf:GetChildren()) do
            if child:IsA("TextLabel") then TweenSvc:Create(child, tweenOut, {TextTransparency = 1}):Play() end
        end
        TweenSvc:Create(frame, tweenOut, {}):Completed:Connect(function() frame:Destroy() end)
    end)
end

-- Perform Anti-AFK key event
local function performAction()
    if not INTERVENTION_EN then return end
    local ok, err = pcall(function()
        VIM:SendKeyEvent(true, simulatedKeyCode, false, game)
        task.wait(0.05 + math.random()*0.05)
        VIM:SendKeyEvent(false, simulatedKeyCode, false, game)
    end)
    if ok then
        lastIntervention = os.clock()
        interventionCount = interventionCount + 1
        print("Intervention #" .. interventionCount)
    else
        warn("Simulation error: ", err)
    end
end

-- User input handler
local function onInput()
    if isAFK then
        isAFK = false
        lastIntervention, interventionCount = 0, 0
        showNotification("Bạn đã quay lại!", "Đã tạm dừng can thiệp AFK.")
    end
    lastInputTime = os.clock()
end

-- Cleanup connections and UI
local function cleanup()
    if inputBeganConn then inputBeganConn:Disconnect() end
    if inputChangedConn then inputChangedConn:Disconnect() end
    if notificationContainer and notificationContainer.Parent then notificationContainer:Destroy() end
    notificationContainer, notificationTemplate = nil, nil
end

-- Apply low graphics settings to reduce lag
local function applyLowGraphics()
    local ok, UGS = pcall(function() return UserSettings():GetService("UserGameSettings") end)
    if ok and UGS then
        if UGS.SetVisualSettingsOverride then
            UGS:SetVisualSettingsOverride(Enum.SavedQualitySetting.QualityLevel1)
        elseif UGS.SetQualityLevel then
            UGS:SetQualityLevel(Enum.SavedQualitySetting.QualityLevel1, true)
        end
    end
    if game.Lighting then
        game.Lighting.GlobalShadows = false
        game.Lighting.FogEnd = 0
    end
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then obj.Enabled = false end
    end
    showNotification("Đang giảm lag...", "Thành công!!!!")
end

-- Display lag reduction prompt with Yes/No options
local function showLagPrompt()
    local cont = setupContainer() or return
    local tmpl = createTemplate() or return
    local frame = tmpl:Clone()
    frame.Name = "LagOptionPrompt"
    frame.Size = UDim2.new(0,300,0,100)
    frame.Parent = cont
    local tf = frame:FindFirstChild("TextFrame")
    if tf then
        tf.Title.Text = "Bạn có muốn giảm lag không?"
        tf.Message.Text = ""
    end
    local btnCon = Instance.new("Frame", frame)
    btnCon.Name = "BtnContainer"
    btnCon.BackgroundTransparency = 1
    btnCon.Size = UDim2.new(1,0,0,30)
    btnCon.Position = UDim2.new(0,0,1,-35)
    local lay = Instance.new("UIListLayout", btnCon)
    lay.FillDirection = Enum.FillDirection.Horizontal
    lay.HorizontalAlignment = Enum.HorizontalAlignment.Center
    lay.Padding = UDim.new(0,10)
    local function createButton(text, color, callback)
        local btn = Instance.new("TextButton", btnCon)
        btn.Text = text
        btn.Size = UDim2.new(0,100,1,-10)
        btn.Font = Enum.Font.GothamBold
        btn.TextSize = 14
        btn.BackgroundColor3 = color
        btn.TextColor3 = Color3.new(1,1,1)
        btn.MouseButton1Click:Connect(function() frame:Destroy(); callback() end)
    end
    createButton("Có", Color3.fromRGB(50,200,50), applyLowGraphics)
    createButton("Không", Color3.fromRGB(200,50,50), function() end)
end

-- Input connections
inputBeganConn = UIS.InputBegan:Connect(function(i, gp)
    if not gp and (i.UserInputType == Enum.UserInputType.Keyboard or i.UserInputType == Enum.UserInputType.MouseButton1) then onInput() end
end)
inputChangedConn = UIS.InputChanged:Connect(function(i, gp)
    if not gp and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.MouseWheel) then onInput() end
end)

-- Initial notifications (sau 3 giây)
task.delay(3, function()
    showNotification("Anti AFK", "Đã được kích hoạt.")
    showLagPrompt()
end)

-- Continuous AFK monitoring using Heartbeat
RunService.Heartbeat:Connect(function()
    local now = os.clock()
    local idle = now - lastInputTime
    if isAFK then
        if now - lastIntervention >= INTERVAL then
            performAction()
        end
        if now - lastCheckTime >= CHECK_INTERVAL then
            showNotification("Vẫn đang AFK...", string.format("Can thiệp sau ~%.0f giây.", INTERVAL - (now - lastIntervention)))
            lastCheckTime = now
        end
    elseif idle >= AFK_THRESHOLD then
        isAFK = true
        lastIntervention, lastCheckTime, interventionCount = now, now, 0
        showNotification("Cảnh báo AFK!", string.format("Sẽ can thiệp sau ~%.0f giây.", INTERVAL))
        print("AFK detected.")
    end
end)

-- Cleanup on player removal
Players.PlayerRemoving:Connect(function(p) if p == player then cleanup() end end)
