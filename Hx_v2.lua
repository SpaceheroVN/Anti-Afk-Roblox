-- Dịch vụ
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")

-- Biến cấu hình
local afkThreshold = 180
local interventionInterval = 600
local checkInterval = 60
local notificationDuration = 5
local animationTime = 0.5
local iconAssetId = "rbxassetid://117118515787811"
local enableIntervention = true
local simulatedKeyCode = Enum.KeyCode.Space

-- Trạng thái
local lastInputTime = os.clock()
local lastInterventionTime = 0
local lastCheckTime = 0
local interventionCounter = 0
local isConsideredAFK = false

-- Tài nguyên GUI
local notificationContainer = nil
local notificationTemplate = nil
local inputBeganConnection = nil
local inputChangedConnection = nil
local player = Players.LocalPlayer
local guiSize = UDim2.new(0, 250, 0, 60)

-- Hàm hỗ trợ
local function disconnectConnection(conn)
    if conn then
        pcall(function() conn:Disconnect() end)
    end
end

local function cleanupOldButton()
    local playerGui = player:FindFirstChild("PlayerGui")
    if playerGui then
        local oldGui = playerGui:FindFirstChild("ScreenGui")
        if oldGui then oldGui:Destroy() end
    end
end

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

    local layout = Instance.new("UIListLayout", frame)
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 10)

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

    local textLayout = Instance.new("UIListLayout", textFrame)
    textLayout.FillDirection = Enum.FillDirection.Horizontal
    textLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    textLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    textLayout.SortOrder = Enum.SortOrder.LayoutOrder
    textLayout.Padding = UDim.new(0, 5)

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Text = "Tiêu đề"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 15
    title.TextColor3 = Color3.new(1, 1, 1)
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
    return frame
end

local function setupNotificationContainer()
    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then return nil end

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

    local listLayout = Instance.new("UIListLayout", container)
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    listLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 5)

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
    if not newFrame then return end

    local icon = newFrame:FindFirstChild("Icon")
    local textFrame = newFrame:FindFirstChild("TextFrame")
    local titleLabel = textFrame and textFrame:FindFirstChild("Title")
    local messageLabel = textFrame and textFrame:FindFirstChild("Message")

    if not (icon and titleLabel and messageLabel) then
        newFrame:Destroy()
        return
    end

    titleLabel.Text = title or "Thông báo"
    messageLabel.Text = message or ""
    newFrame.Name = "Notification_" .. (title or "Default")
    newFrame.Parent = notificationContainer

    local appearTween = TweenInfo.new(animationTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
    TweenService:Create(newFrame, appearTween, { BackgroundTransparency = 0.2 }):Play()
    TweenService:Create(icon, appearTween, { ImageTransparency = 0 }):Play()
    TweenService:Create(titleLabel, appearTween, { TextTransparency = 0 }):Play()
    TweenService:Create(messageLabel, appearTween, { TextTransparency = 0 }):Play()

    task.delay(notificationDuration, function()
        if not newFrame or not newFrame.Parent then return end
        local disappearTween = TweenInfo.new(animationTime, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
        TweenService:Create(newFrame, disappearTween, { BackgroundTransparency = 1 }):Play()
        TweenService:Create(icon, disappearTween, { ImageTransparency = 1 }):Play()
        TweenService:Create(titleLabel, disappearTween, { TextTransparency = 1 }):Play()
        TweenService:Create(messageLabel, disappearTween, { TextTransparency = 1 }):Play()
        task.delay(animationTime, function()
            if newFrame and newFrame.Parent then newFrame:Destroy() end
        end)
    end)
end

-- AntiAFK Script by someone, chỉnh sửa tối ưu
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer

-- GUI setup
local screenGui = Instance.new("ScreenGui", player:WaitForChild("PlayerGui"))
screenGui.Name = "AntiAFK_GUI"

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.Size = UDim2.new(0, 300, 0, 120)
mainFrame.Position = UDim2.new(0.5, -150, 0, 50)
mainFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
mainFrame.BorderSizePixel = 0
mainFrame.Active = true
mainFrame.Draggable = true

local uiCorner = Instance.new("UICorner", mainFrame)
uiCorner.CornerRadius = UDim.new(0, 12)

local title = Instance.new("TextLabel", mainFrame)
title.Size = UDim2.new(1, 0, 0, 30)
title.Text = "Anti AFK Script"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamSemibold
title.TextSize = 16

local logBox = Instance.new("TextLabel", mainFrame)
logBox.Position = UDim2.new(0, 0, 0, 30)
logBox.Size = UDim2.new(1, 0, 0, 60)
logBox.TextColor3 = Color3.fromRGB(200, 200, 200)
logBox.BackgroundTransparency = 1
logBox.TextWrapped = true
logBox.TextYAlignment = Enum.TextYAlignment.Top
logBox.Text = "Đang khởi động..."
logBox.Font = Enum.Font.Code
logBox.TextSize = 14

local optimizeButton = Instance.new("TextButton", mainFrame)
optimizeButton.Position = UDim2.new(0.5, -60, 1, -25)
optimizeButton.Size = UDim2.new(0, 120, 0, 20)
optimizeButton.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
optimizeButton.Text = "Tối ưu"
optimizeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
optimizeButton.Font = Enum.Font.Gotham
optimizeButton.TextSize = 14

Instance.new("UICorner", optimizeButton).CornerRadius = UDim.new(0, 6)

-- Logging
local function log(msg)
	logBox.Text = msg
end

-- AntiAFK logic
local lastInput = tick()
UserInputService.InputBegan:Connect(function()
	lastInput = tick()
end)

RunService.RenderStepped:Connect(function()
	if tick() - lastInput > 60 then
		VirtualInputManager = game:GetService("VirtualInputManager")
		VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
		VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
		lastInput = tick()
		log("Đã phát hiện AFK. Đã gửi tín hiệu hoạt động.")
	end
end)

-- Optimize button behavior
optimizeButton.MouseButton1Click:Connect(function()
	mainFrame.Visible = false

	for _, v in pairs(game:GetDescendants()) do
		if v:IsA("Texture") or v:IsA("Decal") then
			v:Destroy()
		elseif v:IsA("ParticleEmitter") or v:IsA("Trail") then
			v.Enabled = false
		end
	end

	-- Không log gì ở đây như yêu cầu
end)

-- Bắt đầu
log("Anti AFK đã khởi động.")
