if _G.AntiAFK_Running then
    if _G.AntiAFK_CleanupFunction then
        _G.AntiAFK_CleanupFunction()
    end
end

_G.AntiAFK_Running = true

_G.AntiAFK_CleanupFunction = function()
    print("AntiAFK: Dọn dẹp tài nguyên của script cũ...")
    if inputBeganConnection then
        inputBeganConnection:Disconnect()
        inputBeganConnection = nil
    end
    if inputChangedConnection then
        inputChangedConnection:Disconnect()
        inputChangedConnection = nil
    end
    if notificationContainer and notificationContainer.Parent then
        notificationContainer:Destroy()
    end
    notificationContainer = nil
    notificationTemplate = nil
end

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")

local CONFIG = {
    afkThreshold = 180,
    interventionInterval = 600,
    checkInterval = 60,
    notificationDuration = 5,
    animationTime = 0.5,
    iconAssetId = "rbxassetid://117118515787811",
    enableIntervention = true,
    simulatedKeyCode = Enum.KeyCode.Space,
    guiSize = UDim2.new(0, 250, 0, 60)
}

local state = {
    lastInputTime = os.clock(),
    lastInterventionTime = 0,
    lastCheckTime = 0,
    interventionCounter = 0,
    isConsideredAFK = false,
    notificationContainer = nil,
    notificationTemplate = nil,
    inputBeganConnection = nil,
    inputChangedConnection = nil
}

local player = Players.LocalPlayer

local function createNotificationTemplate()
    if state.notificationTemplate then return state.notificationTemplate end

    local frame = Instance.new("Frame")
    frame.Name = "NotificationFrameTemplate"
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Size = CONFIG.guiSize
    frame.ClipsDescendants = true

    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 8)

    local padding = Instance.new("UIPadding", frame)
    padding.PaddingLeft, padding.PaddingRight = UDim.new(0, 10), UDim.new(0, 10)
    padding.PaddingTop, padding.PaddingBottom = UDim.new(0, 5), UDim.new(0, 5)

    local listLayout = Instance.new("UIListLayout", frame)
    listLayout.FillDirection = Enum.FillDirection.Horizontal
    listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 10)

    local icon = Instance.new("ImageLabel", frame)
    icon.Name = "Icon"
    icon.Image = CONFIG.iconAssetId
    icon.BackgroundTransparency = 1
    icon.ImageTransparency = 1
    icon.Size = UDim2.new(0, 40, 0, 40)
    icon.LayoutOrder = 1

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
    title.Text = "Tiêu đề"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 15
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.BackgroundTransparency = 1
    title.TextTransparency = 1
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.AutomaticSize = Enum.AutomaticSize.X
    title.Size = UDim2.new(0, 0, 1, 0)

    local message = Instance.new("TextLabel", textFrame)
    message.Name = "Message"
    message.Text = "Nội dung tin nhắn."
    message.Font = Enum.Font.Gotham
    message.TextSize = 13
    message.TextColor3 = Color3.fromRGB(200, 200, 200)
    message.BackgroundTransparency = 1
    message.TextTransparency = 1
    message.TextXAlignment = Enum.TextXAlignment.Left
    message.TextWrapped = false
    message.AutomaticSize = Enum.AutomaticSize.X
    message.Size = UDim2.new(0, 0, 1, 0)

    state.notificationTemplate = frame
    return state.notificationTemplate
end

local function setupNotificationContainer()
    if state.notificationContainer and state.notificationContainer.Parent then
        return state.notificationContainer
    end

    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then
        warn("AntiAFK: Không tìm thấy PlayerGui.")
        return nil
    end

    local oldGui = playerGui:FindFirstChild("AntiAFKContainerGui")
    if oldGui then oldGui:Destroy() end

    local screenGui = Instance.new("ScreenGui", playerGui)
    screenGui.Name = "AntiAFKContainerGui"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 999

    local container = Instance.new("Frame", screenGui)
    container.Name = "NotificationContainerFrame"
    container.AnchorPoint = Vector2.new(1, 1)
    container.Position = UDim2.new(1, -18, 1, -48)
    container.Size = UDim2.new(0, 300, 0, 200)
    container.BackgroundTransparency = 1

    local listLayout = Instance.new("UIListLayout", container)
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    listLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 5)

    state.notificationContainer = container
    return state.notificationContainer
end

local function showNotification(title, message)
    local container = setupNotificationContainer()
    if not container then return end

    local template = createNotificationTemplate()
    if not template then return end

    local newFrame = template:Clone()
    if not newFrame then return end

    newFrame.Name = "Notification_" .. (title or "Default")
    newFrame.Parent = container

    local icon = newFrame:FindFirstChild("Icon")
    local textFrame = newFrame:FindFirstChild("TextFrame")
    local titleLabel = textFrame and textFrame:FindFirstChild("Title")
    local messageLabel = textFrame and textFrame:FindFirstChild("Message")

    if titleLabel then titleLabel.Text = title or "Thông báo" end
    if messageLabel then messageLabel.Text = message or "" end

    local button = Instance.new("TextButton", newFrame)
    button.Name = "ActionButton"
    button.Text = "Đóng"
    button.Font = Enum.Font.GothamBold
    button.TextSize = 14
    button.TextColor3 = Color3.fromRGB(255, 255, 255)
    button.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    button.BackgroundTransparency = 1
    button.Size = UDim2.new(0, 80, 0, 30)
    button.Position = UDim2.new(1, -90, 1, -40)
    button.AnchorPoint = Vector2.new(1, 1)

    local buttonCorner = Instance.new("UICorner", button)
    buttonCorner.CornerRadius = UDim.new(0, 8)

    local tweenInfo = TweenInfo.new(CONFIG.animationTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
    TweenService:Create(newFrame, tweenInfo, { BackgroundTransparency = 0.2 }):Play()
    if icon then TweenService:Create(icon, tweenInfo, { ImageTransparency = 0 }):Play() end
    if titleLabel then TweenService:Create(titleLabel, tweenInfo, { TextTransparency = 0 }):Play() end
    if messageLabel then TweenService:Create(messageLabel, tweenInfo, { TextTransparency = 0 }):Play() end
    TweenService:Create(button, tweenInfo, { BackgroundTransparency = 0.2 }):Play()

    button.MouseButton1Click:Connect(function()
        if newFrame and newFrame.Parent then
            TweenService:Create(newFrame, tweenInfo, { BackgroundTransparency = 1 }):Play()
            task.wait(CONFIG.animationTime)
            newFrame:Destroy()
        end
    end)

    task.delay(CONFIG.notificationDuration + 5, function()
        if newFrame and newFrame.Parent then
            TweenService:Create(newFrame, tweenInfo, { BackgroundTransparency = 1 }):Play()
            newFrame:Destroy()
        end
    end)
end

local function performAntiAFKAction()
    if not CONFIG.enableIntervention then return end

    local success, err = pcall(function()
        VirtualInputManager:SendKeyEvent(true, CONFIG.simulatedKeyCode, false, game)
        task.wait(0.05 + math.random() * 0.05)
        VirtualInputManager:SendKeyEvent(false, CONFIG.simulatedKeyCode, false, game)
    end)
    if not success then
        warn("AntiAFK: Lỗi khi thực hiện hành động: ", err)
    else
        state.lastInterventionTime = os.clock()
        state.interventionCounter += 1
    end
end

local function main()
    setupNotificationContainer()
    showNotification("Anti AFK", "Đã kích hoạt.")

    while true do
        task.wait(0.5)
        local idleTime = os.clock() - state.lastInputTime

        if state.isConsideredAFK then
            if os.clock() - state.lastInterventionTime >= CONFIG.interventionInterval then
                performAntiAFKAction()
            end
        elseif idleTime >= CONFIG.afkThreshold then
            state.isConsideredAFK = true
            showNotification("Cảnh báo AFK", "Bạn đang AFK!")
        end
    end
end

coroutine.wrap(main)()
