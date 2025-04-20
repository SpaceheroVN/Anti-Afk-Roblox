local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")

local afkThreshold = 180
local interventionInterval = 600
local checkInterval = 60
local notificationDuration = 5
local animationTime = 0.4
local iconAssetId = "rbxassetid://117118515787811" -- !!! NHỚ THAY ID NÀY !!!

local lastInputTime = os.clock()
local lastInterventionTime = 0
local lastCheckTime = 0
local interventionCounter = 0
local isConsideredAFK = false
local notificationContainer = nil
local notificationTemplate = nil
local inputBeganConnection = nil
local inputChangedConnection = nil

local guiSize = UDim2.new(0, 250, 0, 60)

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

	local gradient = Instance.new("UIGradient", frame)
	gradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 255, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 128, 128))
	}
	gradient.Rotation = 90
	gradient.Transparency = NumberSequence.new(1)

	local padding = Instance.new("UIPadding", frame)
	padding.PaddingLeft = UDim.new(0, 5)
	padding.PaddingRight = UDim.new(0, 5)
	padding.PaddingTop = UDim.new(0, 5)
	padding.PaddingBottom = UDim.new(0, 5)

	local listLayout = Instance.new("UIListLayout", frame)
	listLayout.FillDirection = Enum.FillDirection.Horizontal
	listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 5)

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
	textFrame.Size = UDim2.new(1, -50, 1, 0)
	textFrame.LayoutOrder = 2
	textFrame.Parent = frame

	local textListLayout = Instance.new("UIListLayout", textFrame)
	textListLayout.FillDirection = Enum.FillDirection.Vertical
	textListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	textListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	textListLayout.Padding = UDim.new(0, 2)

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Text = ""
	title.Font = Enum.Font.GothamBold
	title.TextSize = 15
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.BackgroundTransparency = 1
	title.TextTransparency = 1
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Size = UDim2.new(1, 0, 0, 20)
	title.LayoutOrder = 1
	title.Parent = textFrame

	local message = Instance.new("TextLabel")
	message.Name = "Message"
	message.Text = ""
	message.Font = Enum.Font.Gotham
	message.TextSize = 13
	message.TextColor3 = Color3.fromRGB(200, 200, 200)
	message.BackgroundTransparency = 1
	message.TextTransparency = 1
	message.TextXAlignment = Enum.TextXAlignment.Left
	message.TextWrapped = true
	message.Size = UDim2.new(1, 0, 1, -22)
	message.LayoutOrder = 2
	message.Parent = textFrame

	notificationTemplate = frame
	return notificationTemplate
end

local function setupNotificationContainer()
	if notificationContainer and notificationContainer.Parent then return notificationContainer end

	local player = Players.LocalPlayer or Players.PlayerAdded:Wait()
	local playerGui = player:WaitForChild("PlayerGui", 10)
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

	local listLayout = Instance.new("UIListLayout", screenGui)
	listLayout.FillDirection = Enum.FillDirection.Vertical
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	listLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 5)

	local paddingFrame = Instance.new("Frame", screenGui)
	paddingFrame.Name = "PaddingBottom"
	paddingFrame.BackgroundTransparency = 1
	paddingFrame.Size = UDim2.new(0, guiSize.X.Offset, 0, 10)
	paddingFrame.LayoutOrder = 9999

	notificationContainer = screenGui
	return notificationContainer
end

local function showNotification(title, message)
	if not notificationContainer or not notificationContainer.Parent then
		warn("AntiAFK: Container thông báo không hợp lệ.")
		if not setupNotificationContainer() then
			warn("AntiAFK: Không thể tạo container thông báo.")
			return
		end
	end

	if not notificationTemplate then
		warn("AntiAFK: Template thông báo chưa được tạo.")
		if not createNotificationTemplate() then
			warn("AntiAFK: Không thể tạo template thông báo.")
			return
		end
	end

	local newFrame = notificationTemplate:Clone()

	local icon = newFrame:FindFirstChild("Icon")
	local textFrame = newFrame:FindFirstChild("TextFrame")
	local titleLabel = textFrame and textFrame:FindFirstChild("Title")
	local messageLabel = textFrame and textFrame:FindFirstChild("Message")
	
	if not (icon and titleLabel and messageLabel) then
		warn("AntiAFK: Frame thông báo được clone bị lỗi.")
		newFrame:Destroy()
		return
	end

	titleLabel.Text = title or "Thông báo"
	messageLabel.Text = message or ""
	newFrame.Name = "Notification_" .. (title or "Default")

	newFrame.Parent = notificationContainer

	local tweenInfo = TweenInfo.new(animationTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local targetTransparency = 0.2
	local fadeInGoals = {
		BackgroundTransparency = targetTransparency,
		ImageTransparency = 0,
		TextTransparency = 0,
	}

	local fadeInTweenFrame = TweenService:Create(newFrame, tweenInfo, { BackgroundTransparency = fadeInGoals.BackgroundTransparency })
	local fadeInTweenIcon = icon and TweenService:Create(icon, tweenInfo, { ImageTransparency = fadeInGoals.ImageTransparency })
	local fadeInTweenTitle = titleLabel and TweenService:Create(titleLabel, tweenInfo, { TextTransparency = fadeInGoals.TextTransparency })
	local fadeInTweenMessage = messageLabel and TweenService:Create(messageLabel, tweenInfo, { TextTransparency = fadeInGoals.TextTransparency })

	fadeInTweenFrame:Play()
	if fadeInTweenIcon then fadeInTweenIcon:Play() end
	if fadeInTweenTitle then fadeInTweenTitle:Play() end
	if fadeInTweenMessage then fadeInTweenMessage:Play() end

	local fadeOutDelay = task.delay(notificationDuration, function()
		local fadeOutGoals = {
			BackgroundTransparency = 1,
			ImageTransparency = 1,
			TextTransparency = 1,
		}
		local fadeOutTweenFrame = TweenService:Create(newFrame, tweenInfo, { BackgroundTransparency = fadeOutGoals.BackgroundTransparency })
		local fadeOutTweenIcon = icon and TweenService:Create(icon, tweenInfo, { ImageTransparency = fadeOutGoals.ImageTransparency })
		local fadeOutTweenTitle = titleLabel and TweenService:Create(titleLabel, tweenInfo, { TextTransparency = fadeOutGoals.TextTransparency })
		local fadeOutTweenMessage = messageLabel and TweenService:Create(messageLabel, tweenInfo, { TextTransparency = fadeOutGoals.TextTransparency })

		fadeOutTweenFrame:Play()
		if fadeOutTweenIcon then fadeOutTweenIcon:Play() end
		if fadeOutTweenTitle then fadeOutTweenTitle:Play() end
		if fadeOutTweenMessage then fadeOutTweenMessage:Play() end

		fadeOutTweenFrame.Completed:Once(function()
			if newFrame and newFrame.Parent then
				newFrame:Destroy()
			end
		end)
	end)
end

local function performAntiAFKAction()
	local success = pcall(function()
		VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
		task.wait(0.05)
		VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
	end)

	if not success then
		warn("AntiAFK: Không thể mô phỏng nhấn phím Space.")
	else
		lastInterventionTime = os.clock()
		interventionCounter += 1
		print("AntiAFK: Đã thực hiện hành động can thiệp lần", interventionCounter)
	end
end

local function onInput()
	local now = os.clock()
	if isConsideredAFK then
		isConsideredAFK = false
		lastInterventionTime = 0
		showNotification("Bạn đã quay lại!", "Đã tạm dừng can thiệp AFK.")
		print("AntiAFK: Người dùng không còn AFK.")
	end
	lastInputTime = now
end

local function cleanup()
	print("AntiAFK: Dọn dẹp tài nguyên...")
	if inputBeganConnection then
		inputBeganConnection:Disconnect()
		inputBeganConnection = nil
	end
	if inputChangedConnection then
		inputChangedConnection:Disconnect()
		inputChangedConnection = nil
	end
	if notificationContainer then
		notificationContainer:Destroy()
		notificationContainer = nil
	end
end

local function main()
	notificationContainer = setupNotificationContainer()
	if not notificationContainer then
		warn("AntiAFK: Không thể khởi tạo container GUI. Script sẽ không hoạt động.")
		return
	end
	notificationTemplate = createNotificationTemplate()
	if not notificationTemplate then
	    warn("AntiAFK: Không thể tạo template GUI. Script sẽ không hoạt động.")
		return
	end

	inputBeganConnection = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if gameProcessedEvent then return end
		if input.UserInputType == Enum.UserInputType.Keyboard or
		   input.UserInputType == Enum.UserInputType.MouseButton1 or
		   input.UserInputType == Enum.UserInputType.MouseButton2 or
		   input.UserInputType == Enum.UserInputType.Touch then
			onInput()
		end
	end)

	inputChangedConnection = UserInputService.InputChanged:Connect(function(input, gameProcessedEvent)
		if gameProcessedEvent then return end
		if input.UserInputType == Enum.UserInputType.MouseMovement or
		   input.UserInputType == Enum.UserInputType.MouseWheel or
		   input.UserInputType == Enum.UserInputType.Gamepad1 or
		   input.UserInputType == Enum.UserInputType.Gamepad2 then
			onInput()
		end
	end)

	task.wait(2)
	showNotification("Anti AFK", "Đã được kích hoạt.")
	print("Anti-AFK Script đã khởi chạy và đang theo dõi.")

	while true do
		local waitTime = task.wait(1)
		local now = os.clock()
		local idleTime = now - lastInputTime

		if isConsideredAFK then
			local timeSinceLastIntervention = now - lastInterventionTime
			local timeSinceLastCheck = now - lastCheckTime

			if timeSinceLastIntervention >= interventionInterval then
				performAntiAFKAction()
			end

			if timeSinceLastCheck >= checkInterval then
				showNotification("Vẫn đang AFK...", string.format("Can thiệp tiếp theo sau ~%.0f giây.", math.max(0, interventionInterval - timeSinceLastIntervention)))
				lastCheckTime = now
			end

		else
			if idleTime >= afkThreshold then
				isConsideredAFK = true
				lastInterventionTime = now
				lastCheckTime = now
				showNotification("Cảnh báo AFK!", string.format("Sẽ can thiệp sau ~%.0f giây nếu không hoạt động.", interventionInterval))
				print("AntiAFK: Người dùng được coi là AFK.")
			end
		end
	end
end

local mainThread = coroutine.create(main)
local success, err = coroutine.resume(mainThread)
if not success then
	warn("AntiAFK Error:", err)
end

local player = Players.LocalPlayer
if player then
	Players.PlayerRemoving:Connect(function(leavingPlayer)
		if leavingPlayer == player then
			cleanup()
		end
	end)
else
	local playerAddedConn
	playerAddedConn = Players.PlayerAdded:Connect(function(addedPlayer)
		if addedPlayer == Players.LocalPlayer then
			player = addedPlayer
			Players.PlayerRemoving:Connect(function(leavingPlayer)
				if leavingPlayer == player then
					cleanup()
				end
			end)
			if playerAddedConn then
				playerAddedConn:Disconnect()
			end
		end
	end)
end
