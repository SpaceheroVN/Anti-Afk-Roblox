local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")

local afkThreshold = 10
local interventionInterval = 600
local checkInterval = 30
local notificationDuration = 4
local animationTime = 0.3 -- Giảm thời gian animation cho cảm giác nhanh hơn
local iconAssetId = "rbxassetid://137888597" -- Icon dấu chấm than cách điệu (thay đổi tùy thích)

local lastInputTime = tick()
local isConsideredAFK = false
local lastInterventionTime = tick()
local lastCheckTime = 0
local guiElement = nil
local currentTween = nil
local isNotificationShowing = false
local afkWarningCount = 0

local guiPadding = 15
local iconSize = 36
local guiCornerRadius = 8
local shadowOffset = 2

local backgroundColor = Color3.fromRGB(45, 45, 45)
local textColorTitle = Color3.fromRGB(230, 230, 230)
local textColorMessage = Color3.fromRGB(180, 180, 180)
local shadowColor = Color3.fromRGB(20, 20, 20)

local function createNotificationGui()
    if guiElement then return guiElement end

    local player = Players.LocalPlayer
    if not player then return nil end
    local playerGui = player:WaitForChild("PlayerGui")
    if not playerGui then return nil end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AntiAFKStatusGui"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui

    -- Tạo bóng đổ (tùy chọn)
    local shadow = Instance.new("Frame")
    shadow.Name = "Shadow"
    shadow.BackgroundColor3 = shadowColor
    shadow.BackgroundTransparency = 0.5
    shadow.BorderSizePixel = 0
    shadow.Size = UDim2.new(0, 250 + shadowOffset, 0, 60 + shadowOffset)
    shadow.Position = UDim2.new(1, -250 - guiPadding + shadowOffset, 1, -60 - guiPadding + shadowOffset)
    shadow.AnchorPoint = Vector2.new(1, 1)
    shadow.ClipsDescendants = true
    shadow.Parent = screenGui

    local shadowCorner = Instance.new("UICorner")
    shadowCorner.CornerRadius = UDim.new(0, guiCornerRadius)
    shadowCorner.Parent = shadow

    local notificationFrame = Instance.new("Frame")
    notificationFrame.Name = "NotificationFrame"
    notificationFrame.BackgroundColor3 = backgroundColor
    notificationFrame.BackgroundTransparency = 0
    notificationFrame.BorderSizePixel = 0
    notificationFrame.Size = UDim2.new(0, 250, 0, 60)
    notificationFrame.Position = UDim2.new(1, -250 - guiPadding, 1, -60 - guiPadding)
    notificationFrame.AnchorPoint = Vector2.new(1, 1)
    notificationFrame.ClipsDescendants = true
    notificationFrame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, guiCornerRadius)
    corner.Parent = notificationFrame

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, guiPadding)
    padding.PaddingRight = UDim.new(0, guiPadding)
    padding.PaddingTop = UDim.new(0, guiPadding / 2)
    padding.PaddingBottom = UDim.new(0, guiPadding / 2)
    padding.Parent = notificationFrame

    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.Image = iconAssetId
    icon.BackgroundTransparency = 1
    icon.Size = UDim2.new(0, iconSize, 0, iconSize)
    icon.Position = UDim2.new(0, guiPadding / 2, 0.5, -iconSize / 2)
    icon.Parent = notificationFrame

    local textFrame = Instance.new("Frame")
    textFrame.Name = "TextFrame"
    textFrame.BackgroundTransparency = 1
    textFrame.Size = UDim2.new(1, -iconSize - 2 * guiPadding, 1, 0)
    textFrame.Position = UDim2.new(0, iconSize + 1.5 * guiPadding, 0, 0)
    textFrame.Parent = notificationFrame

    local textListLayout = Instance.new("UIListLayout")
    textListLayout.FillDirection = Enum.FillDirection.Vertical
    textListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    textListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    textListLayout.Padding = UDim.new(0, 2)
    textListLayout.Parent = textFrame

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextSize = 16
    titleLabel.TextColor3 = textColorTitle
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Size = UDim2.new(1, 0, 0, 18)
    titleLabel.Parent = textFrame

    local messageLabel = Instance.new("TextLabel")
    messageLabel.Name = "Message"
    messageLabel.Font = Enum.Font.SourceSans
    messageLabel.TextSize = 14
    messageLabel.TextColor3 = textColorMessage
    messageLabel.BackgroundTransparency = 1
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.Size = UDim2.new(1, 0, 0, 16)
    messageLabel.Parent = textFrame

    guiElement = screenGui
    return guiElement
end

local function showNotification(title, message)
    if isNotificationShowing or not guiElement then return end
    isNotificationShowing = true

    local frame = guiElement:FindFirstChild("NotificationFrame")
    local titleLabel = frame and frame:FindFirstChild("TextFrame"):FindFirstChild("Title")
    local messageLabel = frame and frame:FindFirstChild("TextFrame"):FindFirstChild("Message")

    if not (frame and titleLabel and messageLabel) then
        warn("AntiAFK: Không tìm thấy các thành phần GUI!")
        isNotificationShowing = false
        return
    end

    if currentTween then
        currentTween:Cancel()
        currentTween = nil
    end

    titleLabel.Text = title
    messageLabel.Text = message

    frame.Position = UDim2.new(1, -250 - guiPadding, 1, -60 - guiPadding) -- Vị trí ban đầu
    local onScreenPosition = UDim2.new(1, -250 - guiPadding, 1, -60 - guiPadding) -- Vị trí cuối cùng (trượt từ phải xuống)
    local offScreenPosition = UDim2.new(1, -guiPadding, 1, -60 - guiPadding) -- Vị trí trượt ra

    -- Animation trượt vào
    local tweenInfoIn = TweenInfo.new(animationTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tweenIn = TweenService:Create(frame, tweenInfoIn, { Position = onScreenPosition })

    local tweenInfoOut = TweenInfo.new(animationTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
    local tweenOut = TweenService:Create(frame, tweenInfoOut, { Position = offScreenPosition })

    tweenIn:Play()
    currentTween = tweenIn

    task.delay(notificationDuration + animationTime, function()
        if currentTween == tweenIn then
            tweenOut:Play()
            currentTween = tweenOut
            tweenOut.Completed:Connect(function()
                if currentTween == tweenOut then
                    currentTween = nil
                    isNotificationShowing = false
                end
            end)
        end
    end)
end

local function performAntiAFKAction()
    print("AntiAFK: Performing action (simulating mouse click).")
    local viewportSize = workspace.CurrentCamera.ViewportSize
    local centerX = viewportSize.X / 2
    local centerY = viewportSize.Y / 2

    VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game)
    task.wait(0.05)
    VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, false, game)

    lastInterventionTime = tick()
end

local function onInput()
    local now = tick()
    if isConsideredAFK then
        isConsideredAFK = false
        showNotification("Chào mừng trở lại!", "Bạn đã hết AFK.")
    end
    lastInputTime = now
    afkWarningCount = 0
end

UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if gameProcessedEvent then return end
    if input.UserInputType == Enum.UserInputType.Keyboard or input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.Touch then
        onInput()
    end
end)
UserInputService.InputChanged:Connect(function(input, gameProcessedEvent)
     if gameProcessedEvent then return end
     if input.UserInputType == Enum.UserInputType.MouseMovement then
        onInput()
     end
end)

local function mainLoop()
    guiElement = createNotificationGui()
    if not guiElement then
        warn("AntiAFK: Không thể tạo GUI thông báo!")
        return
    end

    task.wait(1)
    showNotification("Anti AFK", "Đã được kích hoạt.")

    while task.wait(1) do
        local now = tick()
        local timeSinceLastInput = now - lastInputTime
        local timeSinceLastIntervention = now - lastInterventionTime

        if timeSinceLastIntervention >= interventionInterval then
            performAntiAFKAction()
            if isConsideredAFK then
                 showNotification("Phát hiện AFK", "Đã thực hiện hành động❤️")
                 lastCheckTime = now
                 afkWarningCount = 0
            end
        end

        if not isConsideredAFK and timeSinceLastInput >= afkThreshold then
            isConsideredAFK = true
            print("AntiAFK: Người chơi có dấu hiệu AFK.")
            if timeSinceLastIntervention > 1 then
                 showNotification("Cảnh báo AFK", "Sắp có hành động can thiệp!")
            end
            lastCheckTime = now
            afkWarningCount = 0
        end

        if isConsideredAFK then
            if now - lastCheckTime >= checkInterval then
                if not isNotificationShowing then
                    afkWarningCount += 1
                    showNotification("Bạn còn đó không?", "Chúng tôi vẫn đang can thiệp!")
                    lastCheckTime = now
                end
            end
        end
    end
end

coroutine.wrap(mainLoop)()
print("Anti-AFK Script Đang Chạy.")
