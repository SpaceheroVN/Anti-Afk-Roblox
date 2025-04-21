--// Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

--// Config
local player = Players.LocalPlayer
local simulatedKeyCode = Enum.KeyCode.Space
local iconAssetId = "rbxassetid://117118515787811"
local afkThreshold = 180
local interventionInterval = 600
local checkInterval = 60
local notificationDuration = 5
local animationTime = 0.5
local enableIntervention = true
local guiSize = UDim2.new(0, 250, 0, 60)

--// State
local lastInputTime = os.clock()
local lastInterventionTime = 0
local lastCheckTime = 0
local interventionCounter = 0
local isConsideredAFK = false
local notificationContainer = nil
local notificationTemplate = nil
local inputBeganConnection = nil
local inputChangedConnection = nil

--// Utility
local function disconnectConnection(conn)
    if conn then
        conn:Disconnect()
    end
end

local function cleanupOldButton()
    local playerGui = player:FindFirstChild("PlayerGui")
    if playerGui then
        local oldGui = playerGui:FindFirstChild("ScreenGui")
        if oldGui then
            oldGui:Destroy()
        end
    end
end

--// Notification
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

    local textFrame = Instance.new("Frame")
    textFrame.Name = "TextFrame"
    textFrame.BackgroundTransparency = 1
    textFrame.Size = UDim2.new(1, 0, 1, 0)
    textFrame.LayoutOrder = 2
    textFrame.Parent = frame

    local textListLayout = Instance.new("UIListLayout", textFrame)
    textListLayout.FillDirection = Enum.FillDirection.Horizontal
    textListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    textListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    textListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    textListLayout.Padding = UDim.new(0, 5)

    local title = Instance.new("TextLabel")
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
    title.Parent = textFrame

    local message = Instance.new("TextLabel")
    message.Name = "Message"
    message.Text = "Nội dung tin nhắn."
    message.Font = Enum.Font.Gotham
    message.TextSize = 13
    message.TextColor3 = Color3.fromRGB(200, 200, 200)
    message.BackgroundTransparency = 1
    message.TextTransparency = 1
    message.TextXAlignment = Enum.TextXAlignment.Left
    message.AutomaticSize = Enum.AutomaticSize.X
    message.Size = UDim2.new(0, 0, 1, 0)
    message.Parent = textFrame

    notificationTemplate = frame
    return notificationTemplate
end

local function setupNotificationContainer()
    if notificationContainer and notificationContainer.Parent then return notificationContainer end

    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then
        warn("AntiAFK: Không tìm thấy PlayerGui.")
        return nil
    end

    local oldGui = playerGui:FindFirstChild("AntiAFKContainerGui")
    if oldGui then oldGui:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AntiAFKContainerGui"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 999
    screenGui.Parent = playerGui

    local container = Instance.new("Frame")
    container.Name = "NotificationContainerFrame"
    container.AnchorPoint = Vector2.new(1, 1)
    container.Position = UDim2.new(1, -18, 1, -48)
    container.Size = UDim2.new(0, 300, 0, 200)
    container.BackgroundTransparency = 1
    container.Parent = screenGui

    local layout = Instance.new("UIListLayout", container)
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 5)

    notificationContainer = container
    return container
end

local function showNotification(title, message)
    if not notificationContainer or not notificationContainer.Parent then
        if not setupNotificationContainer() then return end
    end
    if not notificationTemplate then
        if not createNotificationTemplate() then return end
    end

    local newFrame = notificationTemplate:Clone()
    newFrame.Name = "Notification_" .. (title or "Default")
    newFrame.TextFrame.Title.Text = title or "Thông báo"
    newFrame.TextFrame.Message.Text = message or ""

    newFrame.Parent = notificationContainer

    local tweenIn = TweenInfo.new(animationTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
    TweenService:Create(newFrame, tweenIn, { BackgroundTransparency = 0.2 }):Play()
    TweenService:Create(newFrame.Icon, tweenIn, { ImageTransparency = 0 }):Play()
    TweenService:Create(newFrame.TextFrame.Title, tweenIn, { TextTransparency = 0 }):Play()
    TweenService:Create(newFrame.TextFrame.Message, tweenIn, { TextTransparency = 0 }):Play()

    task.delay(notificationDuration, function()
        if newFrame and newFrame.Parent then
            local tweenOut = TweenInfo.new(animationTime, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
            TweenService:Create(newFrame, tweenOut, { BackgroundTransparency = 1 }):Play()
            TweenService:Create(newFrame.Icon, tweenOut, { ImageTransparency = 1 }):Play()
            TweenService:Create(newFrame.TextFrame.Title, tweenOut, { TextTransparency = 1 }):Play()
            TweenService:Create(newFrame.TextFrame.Message, tweenOut, { TextTransparency = 1 }):Play()

            task.delay(animationTime, function()
                if newFrame and newFrame.Parent then newFrame:Destroy() end
            end)
        end
    end)
end

--// AFK Detection
local function onInput()
    local now = os.clock()
    if isConsideredAFK then
        isConsideredAFK = false
        lastInterventionTime = 0
        interventionCounter = 0
        showNotification("Bạn đã quay lại!", "Đã tạm dừng can thiệp AFK.")
    end
    lastInputTime = now
end

local function performAntiAFKAction()
    if not enableIntervention then return end

    local success, err = pcall(function()
        VirtualInputManager:SendKeyEvent(true, simulatedKeyCode, false, game)
        task.wait(0.05 + math.random() * 0.05)
        VirtualInputManager:SendKeyEvent(false, simulatedKeyCode, false, game)
    end)

    if success then
        lastInterventionTime = os.clock()
        interventionCounter += 1
    else
        warn("AntiAFK: Lỗi mô phỏng phím:", err)
    end
end

--// GUI Button
local function createCustomButton()
    local button = Instance.new("Frame")
    button.Name = "CustomButton"
    button.Size = UDim2.new(0, 120, 0, 40)
    button.Position = UDim2.new(1, -20, 1, -50)
    button.AnchorPoint = Vector2.new(1, 1)
    button.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    button.BackgroundTransparency = 0.5
    button.ClipsDescendants = true

    Instance.new("UICorner", button).CornerRadius = UDim.new(0, 8)
    local stroke = Instance.new("UIStroke", button)
    stroke.Color = Color3.fromRGB(50, 50, 50)
    stroke.Thickness = 2
    stroke.Transparency = 0.3

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Text = "Tối ưu"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.BackgroundTransparency = 1
    title.Size = UDim2.new(1, 0, 1, 0)
    title.TextXAlignment = Enum.TextXAlignment.Center
    title.TextYAlignment = Enum.TextYAlignment.Center
    title.Parent = button

    local gui = player:WaitForChild("PlayerGui")
    local screenGui = gui:FindFirstChild("ScreenGui") or Instance.new("ScreenGui", gui)
    button.Parent = screenGui

    return button, title
end

local function setupButtonInteraction(button, title)
    local hoverInfo = TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)

    button.MouseEnter:Connect(function()
        TweenService:Create(button, hoverInfo, { BackgroundTransparency = 0.3 }):Play()
        TweenService:Create(button.UIStroke, hoverInfo, { Transparency = 0 }):Play()
    end)

    button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 then
            TweenService:Create(title, hoverInfo, { TextColor3 = Color3.fromRGB(255, 255, 0) }):Play()
            showNotification("Đang tiến hành", "Xin vui lòng chờ")
            task.wait(1)
            TweenService:Create(title, hoverInfo, { TextColor3 = Color3.fromRGB(0, 255, 0) }):Play()
            showNotification("Tối ưu thành công", "Chúc chơi vui vẻ")
        end
    end)
end

--// Main
local function main()
    notificationContainer = setupNotificationContainer()
    notificationTemplate = createNotificationTemplate()

    inputBeganConnection = UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.UserInputType.Name:match("Keyboard") or input.UserInputType.Name:match("Mouse") or input.UserInputType.Name == "Touch" then
            onInput()
        end
    end)

    inputChangedConnection = UserInputService.InputChanged:Connect(function(input, gp)
        if gp then return end
        if input.UserInputType.Name:match("Mouse") or input.UserInputType.Name:match("Gamepad") then
            onInput()
        end
    end)

    task.wait(3)
    showNotification("Anti AFK", "Đã được kích hoạt.")

    while true do
        task.wait(0.5)
        local now = os.clock()
        local idleTime = now - lastInputTime

        if isConsideredAFK then
            if now - lastInterventionTime >= interventionInterval then
                performAntiAFKAction()
            end
            if now - lastCheckTime >= checkInterval then
                showNotification("Vẫn đang AFK...", "Can thiệp tiếp theo sau ~" .. math.floor(interventionInterval - (now - lastInterventionTime)) .. " giây.")
                lastCheckTime = now
            end
        elseif idleTime >= afkThreshold then
            isConsideredAFK = true
            lastInterventionTime = now
            lastCheckTime = now
            interventionCounter = 0
            showNotification("Cảnh báo AFK!", "Sẽ can thiệp sau ~" .. interventionInterval .. " giây nếu không hoạt động.")
        end
    end
end

--// Startup
local button, title = createCustomButton()
if button then setupButtonInteraction(button, title) end

local thread = coroutine.create(main)
local success, err = coroutine.resume(thread)
if not success then warn("AntiAFK lỗi khởi tạo:", err) end

if player then
    player.CharacterRemoving:Connect(function() end)
    Players.PlayerRemoving:Connect(function(leaving)
        if leaving == player then
            disconnectConnection(inputBeganConnection)
            disconnectConnection(inputChangedConnection)
            if notificationContainer then notificationContainer:Destroy() end
        end
    end)
end
