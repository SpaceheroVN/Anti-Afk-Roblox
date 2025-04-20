--// Services
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")

--// Settings
local afkThreshold = 180
local interventionInterval = 600
local checkInterval = 60
local notificationDuration = 4
local animationTime = 0.5
local iconAssetId = "rbxassetid://117118515787811"

--// State
local lastInputTime = tick()
local lastInterventionTime = tick()
local lastCheckTime = 0
local interventionCounter = 0
local afkWarningCount = 0
local isConsideredAFK = false
local isNotificationShowing = false
local currentTween = nil
local guiElement = nil

--// Positions
local guiSize = UDim2.new(0, 250, 0, 60)
local onScreenPosition = UDim2.new(1, -guiSize.X.Offset - 10, 1, -guiSize.Y.Offset - 10)
local offScreenPosition = UDim2.new(1, 10, 1, -guiSize.Y.Offset - 10)

--// GUI
local function createNotificationGui()
	if guiElement then return guiElement end

	local player = Players.LocalPlayer
	if not player then return nil end
	local playerGui = player:WaitForChild("PlayerGui", 5)
	if not playerGui then return nil end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "AntiAFKStatusGui"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui

	local frame = Instance.new("Frame")
	frame.Name = "NotificationFrame"
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	frame.BackgroundTransparency = 0.2
	frame.BorderSizePixel = 0
	frame.Size = guiSize
	frame.Position = offScreenPosition
	frame.ClipsDescendants = true
	frame.Parent = screenGui

	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
	Instance.new("UIGradient", frame).Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 128, 128))
	}
	Instance.new("UIPadding", frame).PaddingBottom = UDim.new(0, 5)
	Instance.new("UIListLayout", frame).FillDirection = Enum.FillDirection.Horizontal

	local icon = Instance.new("ImageLabel")
	icon.Name = "Icon"
	icon.Image = iconAssetId
	icon.BackgroundTransparency = 1
	icon.Size = UDim2.new(0, 40, 0, 40)
	icon.Parent = frame

	local textFrame = Instance.new("Frame")
	textFrame.Name = "TextFrame"
	textFrame.BackgroundTransparency = 1
	textFrame.Size = UDim2.new(1, -60, 1, 0)
	textFrame.Parent = frame

	Instance.new("UIListLayout", textFrame).FillDirection = Enum.FillDirection.Vertical

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Text = ""
	title.Font = Enum.Font.GothamBold
	title.TextSize = 15
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.BackgroundTransparency = 1
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Size = UDim2.new(1, 0, 0, 20)
	title.Parent = textFrame

	local message = Instance.new("TextLabel")
	message.Name = "Message"
	message.Text = ""
	message.Font = Enum.Font.Gotham
	message.TextSize = 13
	message.TextColor3 = Color3.fromRGB(200, 200, 200)
	message.BackgroundTransparency = 1
	message.TextXAlignment = Enum.TextXAlignment.Left
	message.Size = UDim2.new(1, 0, 0, 18)
	message.Parent = textFrame

	guiElement = screenGui
	return guiElement
end

--// Notification
local function showNotification(title, message)
	if isNotificationShowing or not guiElement then return end
	isNotificationShowing = true

	local frame = guiElement:FindFirstChild("NotificationFrame")
	if not frame then warn("AntiAFK: Frame not found") return end

	local textFrame = frame:FindFirstChild("TextFrame")
	if not textFrame then warn("AntiAFK: TextFrame missing") return end

	local titleLabel = textFrame:FindFirstChild("Title")
	local messageLabel = textFrame:FindFirstChild("Message")
	if not titleLabel or not messageLabel then
		warn("AntiAFK: Missing title/message labels.")
		isNotificationShowing = false
		return
	end

	if currentTween then currentTween:Cancel() end

	titleLabel.Text = title or ""
	messageLabel.Text = message or ""

	frame.Position = offScreenPosition
	local tweenIn = TweenService:Create(frame, TweenInfo.new(animationTime), { Position = onScreenPosition })
	local tweenOut = TweenService:Create(frame, TweenInfo.new(animationTime), { Position = offScreenPosition })

	tweenIn:Play()
	currentTween = tweenIn

	task.delay(notificationDuration + animationTime, function()
		if currentTween == tweenIn then
			tweenOut:Play()
			currentTween = tweenOut
			tweenOut.Completed:Once(function()
				if currentTween == tweenOut then
					currentTween = nil
					isNotificationShowing = false
				end
			end)
		end
	end)
end

--// AFK Action
local function performAntiAFKAction()
	local cam = workspace.CurrentCamera
	if not cam then return end

	local centerX, centerY = cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2

	pcall(function()
		VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 0)
		task.wait(0.05)
		VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, false, game, 0)
	end)

	lastInterventionTime = tick()
	interventionCounter += 1
end

--// Input Handler
local function onInput()
	local now = tick()
	if isConsideredAFK then
		isConsideredAFK = false
		showNotification("Bạn đây rồi♥️", "Tạm dừng kích hoạt.")
	end
	lastInputTime = now
	afkWarningCount = 0
end

--// Input Events
UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and (input.UserInputType == Enum.UserInputType.Keyboard or input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.Touch) then
		onInput()
	end
end)

UserInputService.InputChanged:Connect(function(input, processed)
	if not processed and input.UserInputType == Enum.UserInputType.MouseMovement then
		onInput()
	end
end)

--// Main Loop
local function mainLoop()
	guiElement = createNotificationGui()
	if not guiElement then warn("Không thể tạo GUI") return end

	task.wait(1)
	showNotification("Anti AFK", "Đã được kích hoạt.")

	while task.wait(1) do
		local now = tick()
		local idleTime = now - lastInputTime
		local sinceIntervention = now - lastInterventionTime

		if sinceIntervention >= interventionInterval then
			performAntiAFKAction()
			if isConsideredAFK then
				showNotification("Phát hiện AFK", "Đã thực hiện hành động.")
			end
		end

		if not isConsideredAFK and idleTime >= afkThreshold then
			isConsideredAFK = true
			showNotification("Cảnh báo AFK", "Sắp có hành động can thiệp.")
			lastCheckTime = now
		elseif isConsideredAFK and now - lastCheckTime >= checkInterval then
			showNotification("Bạn còn đó không?", "Chúng tôi vẫn đang can thiệp!")
			lastCheckTime = now
		end
	end
end

coroutine.wrap(mainLoop)()
print("Anti-AFK Script Đang Chạy.")
