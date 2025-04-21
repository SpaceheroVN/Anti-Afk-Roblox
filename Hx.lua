-- Global State
if _G.AntiAFK_Running then
	if _G.AntiAFK_CleanupFunction then
		_G.AntiAFK_CleanupFunction()
	end
end

_G.AntiAFK_Running = true

_G.AntiAFK_CleanupFunction = function()
	print("AntiAFK: Cleaning up old script resources...")
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

-- Services (Cache lại các service thường dùng)
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")

-- Configuration (Hằng số nên được đặt tên rõ ràng và viết hoa toàn bộ)
local AFK_THRESHOLD = 180 -- Thời gian (giây) trước khi coi là AFK
local INTERVENTION_INTERVAL = 600 -- Thời gian (giây) giữa các lần can thiệp
local CHECK_INTERVAL = 60 -- Tần suất (giây) kiểm tra trạng thái AFK
local NOTIFICATION_DURATION = 3 -- Thời gian (giây) hiển thị thông báo
local ANIMATION_TIME = 0.3 -- Thời gian (giây) cho hiệu ứng tween
local ICON_ASSET_ID = "rbxassetid://117118515787811"
local ENABLE_INTERVENTION = true
local SIMULATED_KEY_CODE = Enum.KeyCode.Space

-- State Variables
local lastInputTime = os.clock()
local lastInterventionTime = 0
local lastCheckTime = 0
local interventionCounter = 0
local isConsideredAFK = false
local notificationContainer = nil
local notificationTemplate = nil
local inputBeganConnection = nil
local inputChangedConnection = nil
local player = Players.LocalPlayer
local playerGui = player:FindFirstChild("PlayerGui")
local notificationPool = {}
local MAX_NOTIFICATIONS = 5

local GUI_SIZE = UDim2.new(0, 250, 0, 60)
local NOTIFICATION_ANCHOR_POINT = Vector2.new(1, 1)
local NOTIFICATION_POSITION_OFFSET = UDim2.new(0, -18, 0, -48)
local CONTAINER_SIZE = UDim2.new(0, 300, 0, 200)
local CONTAINER_PADDING = UDim.new(0, 5)
local NOTIFICATION_PADDING = UDim.new(0, 10)
local ICON_SIZE = UDim2.new(0, 40, 0, 40)

-- Utility Functions (Tối ưu hóa việc tạo template và container)
local function createNotificationTemplate()
	if notificationTemplate then return notificationTemplate end

	notificationTemplate = Instance.new("Frame")
	local frame = notificationTemplate
	frame.Name = "NotificationFrameTemplate"
	frame.BackgroundColor3 = Color3.fromRGB(40, 40, 40) -- Màu nền tối hơn
	frame.BackgroundTransparency = 0.8 -- Thêm độ trong suốt nhẹ
	frame.BorderSizePixel = 1
	frame.BorderColor3 = Color3.fromRGB(80, 80, 80) -- Viền mỏng
	frame.Size = GUI_SIZE
	frame.ClipsDescendants = true

	local corner = Instance.new("UICorner", frame)
	corner.CornerRadius = UDim.new(0, 6) -- Góc bo tròn nhẹ hơn

	local padding = Instance.new("UIPadding", frame)
	padding.PaddingLeft = NOTIFICATION_PADDING
	padding.PaddingRight = NOTIFICATION_PADDING
	padding.PaddingTop = UDim.new(0, 8) -- Tăng padding top
	padding.PaddingBottom = UDim.new(0, 8) -- Tăng padding bottom

	local listLayoutHorizontal = Instance.new("UIListLayout", frame) -- Layout ngang cho icon và textFrame
	listLayoutHorizontal.FillDirection = Enum.FillDirection.Horizontal
	listLayoutHorizontal.VerticalAlignment = Enum.VerticalAlignment.Center
	listLayoutHorizontal.SortOrder = Enum.SortOrder.LayoutOrder
	listLayoutHorizontal.Padding = UDim.new(0, 8) -- Giảm padding giữa các element

	local icon = Instance.new("ImageLabel", frame)
	icon.Name = "Icon"
	icon.Image = ICON_ASSET_ID
	icon.BackgroundTransparency = 1
	icon.ImageTransparency = 1
	icon.Size = ICON_SIZE
	icon.LayoutOrder = 1

	local textFrame = Instance.new("Frame", frame)
	textFrame.Name = "TextFrame"
	textFrame.BackgroundTransparency = 1
	textFrame.Size = UDim2.new(1, 0, 1, 0)
	textFrame.LayoutOrder = 2

	local listLayoutVertical = Instance.new("UIListLayout", textFrame) -- Layout dọc cho title và message
	listLayoutVertical.FillDirection = Enum.FillDirection.Vertical
	listLayoutVertical.HorizontalAlignment = Enum.HorizontalAlignment.Left
	listLayoutVertical.VerticalAlignment = Enum.VerticalAlignment.Top
	listLayoutVertical.SortOrder = Enum.SortOrder.LayoutOrder
	listLayoutVertical.Padding = UDim.new(0, 2)

	local title = Instance.new("TextLabel", textFrame)
	title.Name = "Title"
	title.Text = "Title"
	title.Font = Enum.Font.GothamBold
	title.TextSize = 16 -- Tăng kích thước tiêu đề
	title.TextColor3 = Color3.fromRGB(230, 230, 230) -- Màu chữ sáng hơn
	title.BackgroundTransparency = 1
	title.TextTransparency = 1
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Size = UDim2.new(1, 0, 0, 0)
	title.AutomaticSize = Enum.AutomaticSize.Y -- Cho phép tự động điều chỉnh chiều cao

	local message = Instance.new("TextLabel", textFrame)
	message.Name = "Message"
	message.Text = "Message Content"
	message.Font = Enum.Font.Gotham
	message.TextSize = 14 -- Tăng kích thước tin nhắn
	message.TextColor3 = Color3.fromRGB(200, 200, 200)
	message.BackgroundTransparency = 1
	message.TextTransparency = 1
	message.TextXAlignment = Enum.TextXAlignment.Left
	message.Size = UDim2.new(1, 0, 0, 0)
	message.AutomaticSize = Enum.AutomaticSize.Y -- Cho phép tự động điều chỉnh chiều cao

	return notificationTemplate
end

local function setupNotificationContainer()
	if notificationContainer and notificationContainer.Parent then return notificationContainer end

	if not playerGui then
		warn("AntiAFK: PlayerGui not found for " .. (player and player.Name or "Unknown Player"))
		return nil
	end

	local oldGui = playerGui:FindFirstChild("AntiAFKContainerGui")
	if oldGui then oldGui:Destroy() end

	local screenGui = Instance.new("ScreenGui", playerGui)
	screenGui.Name = "AntiAFKContainerGui"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

	notificationContainer = Instance.new("Frame", screenGui)
	local container = notificationContainer
	container.Name = "NotificationContainerFrame"
	container.AnchorPoint = NOTIFICATION_ANCHOR_POINT
	container.Position = UDim2.new(1, NOTIFICATION_POSITION_OFFSET.X.Offset, 1, NOTIFICATION_POSITION_OFFSET.Y.Offset)
	container.Size = CONTAINER_SIZE
	container.BackgroundTransparency = 1

	local listLayout = Instance.new("UIListLayout", container)
	listLayout.FillDirection = Enum.FillDirection.Vertical
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	listLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = CONTAINER_PADDING

	return notificationContainer
end

local function createNotificationObject()
	local newFrame = notificationTemplate:Clone()
	newFrame.Visible = false
	newFrame.Parent = notificationContainer
	return newFrame
end

local function getAvailableNotification()
	for _, notification in ipairs(notificationPool) do
		if not notification.Visible then
			return notification
		end
	end
	if #notificationPool < MAX_NOTIFICATIONS then
		local newNotification = createNotificationObject()
		table.insert(notificationPool, newNotification)
		return newNotification
	end
	return nil
end

local function showNotification(title, message)
	if not notificationContainer or not notificationContainer.Parent then
		warn("AntiAFK: Container thông báo không hợp lệ hoặc đã bị xóa.")
		if not setupNotificationContainer() then
			warn("AntiAFK: Không thể tạo lại container thông báo.")
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

	local notificationObject = getAvailableNotification()

	if notificationObject then
		local icon = notificationObject:FindFirstChild("Icon")
		local textFrame = notificationObject:FindFirstChild("TextFrame")
		local titleLabel = textFrame and textFrame:FindFirstChild("Title")
		local messageLabel = textFrame and textFrame:FindFirstChild("Message")

	if notificationObject then
		local icon = notificationObject:FindFirstChild("Icon")
		local textFrame = notificationObject:FindFirstChild("TextFrame")
		local titleLabel = textFrame and textFrame:FindFirstChild("Title")
		local messageLabel = textFrame and textFrame:FindFirstChild("Message")

		if not (icon and titleLabel and messageLabel) then
			warn("AntiAFK: Frame thông báo từ pool bị lỗi cấu trúc.")
			notificationObject:Destroy()
			return
		end

		titleLabel.Text = title or "Thông báo"
		messageLabel.Text = message or ""
		notificationObject.Name = "Notification_" .. (title or "Default")
		notificationObject.Visible = true
		notificationObject.BackgroundTransparency = 1 -- Đặt lại độ trong suốt khi hiển thị
		icon.ImageTransparency = 1
		titleLabel.TextTransparency = 1
		messageLabel.TextTransparency = 1

		local tweenInfoAppear = TweenInfo.new(ANIMATION_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
		local tweenPropertiesAppear = { BackgroundTransparency = 0.2, ImageTransparency = 0, TextTransparency = 0 } -- Giảm độ trong suốt nền

		TweenService:Create(notificationObject, tweenInfoAppear, { BackgroundTransparency = tweenPropertiesAppear.BackgroundTransparency }):Play()
		TweenService:Create(icon, tweenInfoAppear, { ImageTransparency = tweenPropertiesAppear.ImageTransparency }):Play()
		TweenService:Create(titleLabel, tweenInfoAppear, { TextTransparency = tweenPropertiesAppear.TextTransparency }):Play()
		TweenService:Create(messageLabel, tweenInfoAppear, { TextTransparency = tweenPropertiesAppear.TextTransparency }):Play()

		task.delay(NOTIFICATION_DURATION, function()
			if notificationObject and notificationObject.Parent then
				local tweenInfoDisappear = TweenInfo.new(ANIMATION_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
				local tweenPropertiesDisappear = { BackgroundTransparency = 1, ImageTransparency = 1, TextTransparency = 1 }

				local fadeOutTweenFrame = TweenService:Create(notificationObject, tweenInfoDisappear, { BackgroundTransparency = tweenPropertiesDisappear.BackgroundTransparency })
				local fadeOutTweenIcon = TweenService:Create(icon, tweenInfoDisappear, { ImageTransparency = tweenPropertiesDisappear.ImageTransparency })
				local fadeOutTweenTitle = TweenService:Create(titleLabel, tweenInfoDisappear, { TextTransparency = tweenPropertiesDisappear.TextTransparency })
				local fadeOutTweenMessage = TweenService:Create(messageLabel, tweenInfoDisappear, { TextTransparency = tweenPropertiesDisappear.TextTransparency })

				fadeOutTweenFrame:Play()
				fadeOutTweenIcon:Play()
				fadeOutTweenTitle:Play()
				fadeOutTweenMessage:Play()

				fadeOutTweenFrame.Completed:Connect(function()
					if notificationObject and notificationObject.Parent then
						notificationObject.Visible = false
					end
				end)
			end
		end)
	else
		warn("AntiAFK: Không thể hiển thị thông báo mới (đạt giới hạn pool).")
	end
end

local function performAntiAFKAction()
	if not ENABLE_INTERVENTION then
		return
	end

	local success, err = pcall(function()
		VirtualInputManager:SendKeyEvent(true, SIMULATED_KEY_CODE, false, game)
		task.wait(0.05 + math.random() * 0.05)
		VirtualInputManager:SendKeyEvent(false, SIMULATED_KEY_CODE, false, game)
	end)
	if not success then
		warn("AntiAFK: Không thể mô phỏng nhấn phím " .. tostring(SIMULATED_KEY_CODE) .. ". Lỗi:", err)
	else
		lastInterventionTime = os.clock()
		interventionCounter = interventionCounter + 1
		print(string.format("AntiAFK: Đã thực hiện can thiệp lần %d (nhấn %s)", interventionCounter, tostring(SIMULATED_KEY_CODE)))
	end
end

local function onInput()
	local now = os.clock()
	if isConsideredAFK then
		isConsideredAFK = false
		lastInterventionTime = 0
		interventionCounter = 0
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
	if notificationContainer and notificationContainer.Parent then
		notificationContainer:Destroy()
	end
	notificationContainer = nil
	notificationTemplate = nil
end

-- Main Functionality
local function main()
	-- 1. Setup notification container
	notificationContainer = setupNotificationContainer()
	if not notificationContainer then
		warn("AntiAFK: Không thể khởi tạo container GUI. Script sẽ không hiển thị thông báo.")
		return
	end

	-- 2. Setup notification template
	notificationTemplate = createNotificationTemplate()
	if not notificationTemplate then
		warn("AntiAFK: Không thể tạo template GUI. Script sẽ không hiển thị thông báo.")
		return
	end

	-- Initialize notification pool
	for _ = 1, MAX_NOTIFICATIONS do
		local notification = createNotificationObject()
		table.insert(notificationPool, notification)
	end

	-- 3. Connect to Input Events
	local function handleInput(input, gameProcessedEvent)
		if gameProcessedEvent then return end
		local inputType = input.UserInputType
		if inputType == Enum.UserInputType.Keyboard or
			inputType == Enum.UserInputType.MouseButton1 or
			inputType == Enum.UserInputType.MouseButton2 or
			inputType == Enum.UserInputType.Touch or
			inputType == Enum.UserInputType.MouseMovement or
			inputType == Enum.UserInputType.MouseWheel or
			tostring(inputType):find("Gamepad") then
			onInput()
		end
	end

	inputBeganConnection = UserInputService.InputBegan:Connect(handleInput)
	inputChangedConnection = UserInputService.InputChanged:Connect(handleInput)

	-- 4. Notify the user that the script is active
	task.wait(3)
	showNotification("Anti AFK", "Đã được kích hoạt.")
	print("Anti-AFK Script đã khởi chạy và đang theo dõi input.")

	-- 5. Main loop to monitor AFK state
	while true do
		task.wait(0.5)
		local now = os.clock()
		local idleTime = now - lastInputTime

		if isConsideredAFK then
			local timeSinceLastIntervention = now - lastInterventionTime
			local timeSinceLastCheck = now - lastCheckTime

			if timeSinceLastIntervention >= INTERVENTION_INTERVAL then
				performAntiAFKAction()
			end

			if timeSinceLastCheck >= CHECK_INTERVAL then
				local nextInterventionIn = math.max(0, INTERVENTION_INTERVAL - timeSinceLastIntervention)
				local msg = string.format("Can thiệp tiếp theo sau ~%.0f giây.", nextInterventionIn)
				if not ENABLE_INTERVENTION then
					msg = "Chế độ can thiệp đang tắt."
				end
				showNotification("Vẫn đang AFK...", msg)
				lastCheckTime = now
			end
		else
			if idleTime >= AFK_THRESHOLD then
				isConsideredAFK = true
				lastInterventionTime = now
				lastCheckTime = now
				interventionCounter = 0
				local msg = string.format("Sẽ can thiệp sau ~%.0f giây nếu không hoạt động.", INTERVENTION_INTERVAL)
				if not ENABLE_INTERVENTION then
					msg = "Bạn hiện đang AFK (can thiệp tự động đang tắt)."
				end
				showNotification("Cảnh báo AFK!", msg)
				print("AntiAFK: Người dùng được coi là AFK.")
			end
		end
	end
end

local mainThread = coroutine.create(main)
local success, err = coroutine.resume(mainThread)
if not success then
	warn("AntiAFK Lỗi Khởi Tạo:", err)
end

if player then
	player.CharacterRemoving:Connect(function() end) -- Không cần làm gì khi character bị remove
	Players.PlayerRemoving:Connect(function(leavingPlayer)
		if leavingPlayer == player then
			cleanup()
			if coroutine.status(mainThread) == "suspended" or coroutine.status(mainThread) == "running" then
				-- Không cần coroutine.yield() ở đây vì player đang rời đi, script sẽ bị dừng
				print("AntiAFK: Đã yêu cầu dừng vòng lặp chính (do người chơi rời đi).")
			end
		end
	end)
else
	warn("AntiAFK: Không tìm thấy LocalPlayer khi thiết lập PlayerRemoving listener.")
end
