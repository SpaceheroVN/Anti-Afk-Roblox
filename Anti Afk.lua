local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")

local afkThreshold = 10 -- time noti
local interventionInterval = 600 -- run
local checkInterval = 30 -- noti
local notificationDuration = 4 -- time print noti
local animationTime = 0.5 -- animation
local iconAssetId = "rbxassetid://117118515787811" -- logo

local lastInputTime = tick()
local isConsideredAFK = false
local lastInterventionTime = tick()
local lastCheckTime = 0
local guiElement = nil
local currentTween = nil -- ql animation

local guiSize = UDim2.new(0, 250, 0, 60)
local onScreenPosition = UDim2.new(1, -guiSize.X.Offset - 10, 1, -guiSize.Y.Offset - 10)
local offScreenPosition = UDim2.new(1, 10, 1, -guiSize.Y.Offset - 10)

local function createNotificationGui()
    if guiElement and guiElement.Parent then return end

    local player = Players.LocalPlayer
    local playerGui = player:WaitForChild("PlayerGui")

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AntiAFKStatusGui"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local notificationFrame = Instance.new("Frame")
    notificationFrame.Name = "NotificationFrame"
    notificationFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    notificationFrame.BackgroundTransparency = 0.2
    notificationFrame.BorderSizePixel = 0
    notificationFrame.Size = guiSize
    notificationFrame.Position = offScreenPosition
    notificationFrame.ClipsDescendants = true
    notificationFrame.Parent = screenGui

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 6)
    corner.Parent = notificationFrame

    local listLayout = Instance.new("UIListLayout")
    listLayout.FillDirection = Enum.FillDirection.Horizontal
    listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 10)
    listLayout.Parent = notificationFrame

    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.PaddingTop = UDim.new(0, 5)
    padding.PaddingBottom = UDim.new(0, 5)
    padding.Parent = notificationFrame

    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.LayoutOrder = 1
    icon.Image = iconAssetId
    icon.BackgroundTransparency = 1
    icon.Size = UDim2.new(0, 40, 0, 40)
    icon.Parent = notificationFrame

    local textFrame = Instance.new("Frame")
    textFrame.Name = "TextFrame"
    textFrame.LayoutOrder = 2
    textFrame.BackgroundTransparency = 1

    textFrame.Size = UDim2.new(1, -60, 1, 0) 
    textFrame.Parent = notificationFrame

    local textListLayout = Instance.new("UIListLayout")
    textListLayout.FillDirection = Enum.FillDirection.Vertical
    textListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    textListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    textListLayout.Padding = UDim.new(0, 2) 
    textListLayout.Parent = textFrame

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.LayoutOrder = 1
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextSize = 16
    titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    titleLabel.BackgroundTransparency = 1
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Size = UDim2.new(1, 0, 0, 18)
    titleLabel.Parent = textFrame

    local messageLabel = Instance.new("TextLabel")
    messageLabel.Name = "Message"
    messageLabel.LayoutOrder = 2
    messageLabel.Font = Enum.Font.SourceSans
    messageLabel.TextSize = 14
    messageLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
    messageLabel.BackgroundTransparency = 1
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.Size = UDim2.new(1, 0, 0, 16)
    messageLabel.Parent = textFrame

    guiElement = screenGui
    guiElement.Parent = playerGui
end

    if not guiElement then createNotificationGui() end
    if not guiElement or not guiElement.Parent then return end

    local frame = guiElement:FindFirstChild("NotificationFrame")
    local titleLabel = frame and frame:FindFirstChild("TextFrame"):FindFirstChild("Title")
    local messageLabel = frame and frame:FindFirstChild("TextFrame"):FindFirstChild("Message")

    if not (frame and titleLabel and messageLabel) then
        warn("AntiAFK: Không tìm thấy các thành phần GUI!")
        return
    end

    if currentTween then
        currentTween:Cancel()
        currentTween = nil
    end

    titleLabel.Text = title
    messageLabel.Text = message

    frame.Position = offScreenPosition

    -- Tạo animation trượt vào
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

    VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game) -- 0 là MouseButton1
    task.wait(0.05)
    VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, false, game)

    lastInterventionTime = tick()
end

local function onInput()
    local now = tick()
    if isConsideredAFK then
        isConsideredAFK = false
        showNotification("There you are ♥️", "Proceed with pausing.") -- Thời gian hiển thị mặc định
    end
    lastInputTime = now
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
    createNotificationGui()
    task.wait(1)
    showNotification("Anti afk: On!", "is test")

    while task.wait(1) do
        local now = tick()
        local timeSinceLastInput = now - lastInputTime
        local timeSinceLastIntervention = now - lastInterventionTime

        if timeSinceLastIntervention >= interventionInterval then
            performAntiAFKAction()
            if isConsideredAFK then
                 showNotification("Player detected to be AFK.", "Intervention initiated!!")
                 lastCheckTime = now
            end
        end

        if not isConsideredAFK and timeSinceLastInput >= afkThreshold then
            isConsideredAFK = true
            print("AntiAFK: Player potentially AFK based on input timeout.")
            if timeSinceLastIntervention > 1 then
                 showNotification("Player detected to be AFK.", "Intervention initiated!!")
            end
            lastCheckTime = now
        end

        if isConsideredAFK then
            if now - lastCheckTime >= checkInterval then
                if not currentTween or currentTween.PlaybackState ~= Enum.PlaybackState.Playing then
                     showNotification("Have you returned?", "")
                     lastCheckTime = now
                end
            end
        end
    end
end

coroutine.wrap(mainLoop)()
print("Anti-AFK Script Running.")
