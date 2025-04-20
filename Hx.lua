local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

local notificationContainer = nil
local notificationTemplate = nil
local animationTime = 0.5
local notificationDuration = 5
local promptContainerName = "PromptContainerGui"

local function setupNotificationContainer()
    if notificationContainer and notificationContainer.Parent then
        return notificationContainer
    end

    local playerGui = player:WaitForChild("PlayerGui", 20)
    if not playerGui then
        warn("Không tìm thấy PlayerGui cho " .. player.Name)
        return nil
    end

    local oldGui = playerGui:FindFirstChild(promptContainerName)
    if oldGui then
        oldGui:Destroy()
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = promptContainerName
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

    local listLayout = Instance.new("UIListLayout", container)
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    listLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 5)

    notificationContainer = container
    return notificationContainer
end

local function createNotificationTemplate(size)
    local frame = Instance.new("Frame")
    frame.Name = "NotificationFrameTemplate"
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Size = size or UDim2.new(0, 250, 0, 60)
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
    icon.BackgroundTransparency = 1
    icon.Size = UDim2.new(0, 40, 0, 40)
    icon.LayoutOrder = 1
    icon.Parent = frame

    local textFrame = Instance.new("Frame")
    textFrame.Name = "TextFrame"
    textFrame.BackgroundTransparency = 1
    textFrame.Size = UDim2.new(1, 0, 1, 0)
    textFrame.LayoutOrder = 2
    textFrame.Parent = frame

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 15
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.BackgroundTransparency = 1
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.AutomaticSize = Enum.AutomaticSize.X
    title.Size = UDim2.new(0, 0, 1, 0)
    title.Parent = textFrame

    local message = Instance.new("TextLabel")
    message.Name = "Message"
    message.Font = Enum.Font.Gotham
    message.TextSize = 13
    message.TextColor3 = Color3.fromRGB(200, 200, 200)
    message.BackgroundTransparency = 1
    message.TextXAlignment = Enum.TextXAlignment.Left
    message.TextWrapped = false
    message.AutomaticSize = Enum.AutomaticSize.X
    message.Size = UDim2.new(0, 0, 1, 0)
    message.Parent = textFrame

    return frame
end

local function showNotification(title, message, size)
    local frame = createNotificationTemplate(size)
    frame.Name = "Notification_" .. title
    frame.Parent = notificationContainer

    local icon = frame:FindFirstChild("Icon")
    local textFrame = frame:FindFirstChild("TextFrame")
    local titleLabel = textFrame and textFrame:FindFirstChild("Title")
    local messageLabel = textFrame and textFrame:FindFirstChild("Message")

    if titleLabel then
        titleLabel.Text = title or "Thông báo"
    end
    if messageLabel then
        messageLabel.Text = message or ""
    end

    local tweenInfo = TweenInfo.new(animationTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
    TweenService:Create(frame, tweenInfo, { BackgroundTransparency = 0.2 }):Play()

    task.delay(notificationDuration, function()
        if frame and frame.Parent then
            TweenService:Create(frame, tweenInfo, { BackgroundTransparency = 1 }):Play()
            frame:Destroy()
        end
    end)
end

local function showPromptNotification(title, message, onYes, onNo)
    local frame = createNotificationTemplate(UDim2.new(0, 300, 0, 100))
    frame.Name = "PromptNotification_" .. title
    frame.Parent = notificationContainer

    local icon = frame:FindFirstChild("Icon")
    local textFrame = frame:FindFirstChild("TextFrame")
    local titleLabel = textFrame and textFrame:FindFirstChild("Title")
    local messageLabel = textFrame and textFrame:FindFirstChild("Message")

    if titleLabel then
        titleLabel.Text = title or "Thông báo"
    end
    if messageLabel then
        messageLabel.Text = message or ""
    end

    local yesButton = Instance.new("TextButton")
    yesButton.Name = "YesButton"
    yesButton.Text = "Có"
    yesButton.Font = Enum.Font.GothamBold
    yesButton.TextSize = 14
    yesButton.TextColor3 = Color3.new(1, 1, 1)
    yesButton.BackgroundColor3 = Color3.fromRGB(0, 170, 0)
    yesButton.Size = UDim2.new(0.4, 0, 0.3, 0)
    yesButton.Position = UDim2.new(0.05, 0, 0.7, 0)
    yesButton.Parent = frame

    local noButton = Instance.new("TextButton")
    noButton.Name = "NoButton"
    noButton.Text = "Không"
    noButton.Font = Enum.Font.GothamBold
    noButton.TextSize = 14
    noButton.TextColor3 = Color3.new(1, 1, 1)
    noButton.BackgroundColor3 = Color3.fromRGB(170, 0, 0)
    noButton.Size = UDim2.new(0.4, 0, 0.3, 0)
    noButton.Position = UDim2.new(0.55, 0, 0.7, 0)
    noButton.Parent = frame

    yesButton.MouseButton1Click:Connect(function()
        if onYes then onYes() end
        frame:Destroy()
    end)

    noButton.MouseButton1Click:Connect(function()
        if onNo then onNo() end
        frame:Destroy()
    end)
end

setupNotificationContainer()

-- Example Notifications:
showNotification("Thông báo", "Chào mừng bạn!", nil)
showPromptNotification(
    "Bạn có muốn giảm lag?",
    "Chọn nút bên dưới để tiếp tục.",
    function()
        print("Đã giảm hiệu ứng và đồ họa!")
    end,
    function()
        print("Người dùng từ chối!")
    end
)
