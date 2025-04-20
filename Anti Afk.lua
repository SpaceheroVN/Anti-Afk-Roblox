--[[
	Anti-AFK Script
	Mô tả: Tự động phát hiện người chơi AFK và thực hiện hành động (nhấn Space)
	         để tránh bị kick, đồng thời hiển thị thông báo trên màn hình.
	Lưu ý: Đặt Script này vào StarterPlayerScripts.
	       !!! NHỚ THAY ID iconAssetId BÊN DƯỚI !!!
]]

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService") -- Thêm GuiService để lấy kích thước inset

-- // Cấu hình //
local afkThreshold = 180 -- Thời gian không hoạt động để coi là AFK (giây)
local interventionInterval = 600 -- Thời gian giữa các lần can thiệp khi đang AFK (giây)
local checkInterval = 60 -- Thời gian giữa các lần kiểm tra và thông báo khi đang AFK (giây)
local notificationDuration = 5 -- Thời gian hiển thị thông báo (giây)
local animationTime = 0.4 -- Thời gian cho hiệu ứng tween (giây)
local iconAssetId = "rbxassetid://117118515787811" -- !!! THAY ID NÀY BẰNG ID ICON CỦA BẠN !!!
local enableIntervention = true -- Đặt thành false để chỉ cảnh báo AFK mà không nhấn phím Space
local simulatedKeyCode = Enum.KeyCode.Space -- Phím được mô phỏng

-- // Biến trạng thái //
local lastInputTime = os.clock()
local lastInterventionTime = 0
local lastCheckTime = 0
local interventionCounter = 0
local isConsideredAFK = false
local notificationContainer = nil
local notificationTemplate = nil
local inputBeganConnection = nil
local inputChangedConnection = nil
local player = Players.LocalPlayer -- LocalPlayer luôn tồn tại trong LocalScript ở vị trí chuẩn

local guiSize = UDim2.new(0, 250, 0, 60)
local guiPaddingBottom = 10 -- Khoảng cách từ cạnh dưới màn hình

-- // Hàm tạo Template Thông báo (Chỉ chạy 1 lần) //
local function createNotificationTemplate()
	if notificationTemplate then return notificationTemplate end

	local frame = Instance.new("Frame")
	frame.Name = "NotificationFrameTemplate"
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	frame.BackgroundTransparency = 1 -- Bắt đầu trong suốt hoàn toàn
	frame.BorderSizePixel = 0
	frame.Size = guiSize
	frame.ClipsDescendants = true
	-- Không đặt Parent ở đây

	local corner = Instance.new("UICorner", frame)
	corner.CornerRadius = UDim.new(0, 8)

	-- Không cần gradient nếu BackgroundTransparency = 1 ban đầu
	-- local gradient = Instance.new("UIGradient", frame) ...

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
	icon.ImageTransparency = 1 -- Bắt đầu trong suốt
	icon.Size = UDim2.new(0, 40, 0, 40)
	icon.LayoutOrder = 1
	icon.Parent = frame

	local textFrame = Instance.new("Frame")
	textFrame.Name = "TextFrame"
	textFrame.BackgroundTransparency = 1
	textFrame.Size = UDim2.fromScale(1, 1) -- Sử dụng Scale để tự điều chỉnh
	textFrame.SizeConstraint = Enum.SizeConstraint.RelativeYY -- Cho phép chiều rộng tự do
	textFrame.LayoutOrder = 2
	textFrame.Parent = frame

	local textListLayout = Instance.new("UIListLayout", textFrame)
	textListLayout.FillDirection = Enum.FillDirection.Vertical
	textListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	textListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	textListLayout.Padding = UDim.new(0, 2)

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Text = "Tiêu đề" -- Placeholder
	title.Font = Enum.Font.GothamBold
	title.TextSize = 15
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.BackgroundTransparency = 1
	title.TextTransparency = 1 -- Bắt đầu trong suốt
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Size = UDim2.new(1, 0, 0, 18) -- Chiều cao cố định cho tiêu đề
	title.LayoutOrder = 1
	title.Parent = textFrame

	local message = Instance.new("TextLabel")
	message.Name = "Message"
	message.Text = "Nội dung tin nhắn." -- Placeholder
	message.Font = Enum.Font.Gotham
	message.TextSize = 13
	message.TextColor3 = Color3.fromRGB(200, 200, 200)
	message.BackgroundTransparency = 1
	message.TextTransparency = 1 -- Bắt đầu trong suốt
	message.TextXAlignment = Enum.TextXAlignment.Left
	message.TextWrapped = true
	message.Size = UDim2.new(1, 0, 1, -title.Size.Y.Offset - textListLayout.Padding.Offset) -- Tự động tính chiều cao còn lại
	message.LayoutOrder = 2
	message.Parent = textFrame

	notificationTemplate = frame
	return notificationTemplate
end

-- // Hàm tạo Container chứa Thông báo (Chỉ chạy 1 lần) //
local function setupNotificationContainer()
	if notificationContainer and notificationContainer.Parent then return notificationContainer end

	-- Player đã được gán ở đầu script
	local playerGui = player:WaitForChild("PlayerGui", 20) -- Tăng thời gian chờ một chút
	if not playerGui then
		warn("AntiAFK: Không tìm thấy PlayerGui cho " .. player.Name .. ". Script sẽ không hiển thị thông báo.")
		return nil
	end

	-- Xóa container cũ nếu tồn tại
	local oldGui = playerGui:FindFirstChild("AntiAFKContainerGui")
	if oldGui then oldGui:Destroy() end

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "AntiAFKContainerGui"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.DisplayOrder = 999 -- Đảm bảo hiển thị trên cùng
	screenGui.IgnoreGuiInset = true -- Để tính toán vị trí từ cạnh màn hình chính xác hơn
	screenGui.Parent = playerGui

	local listLayout = Instance.new("UIListLayout", screenGui)
	listLayout.FillDirection = Enum.FillDirection.Vertical
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	listLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 5) -- Khoảng cách giữa các thông báo

	-- Padding từ cạnh màn hình (tính cả phần bị che bởi TopBar nếu có)
	local inset = GuiService:GetGuiInset()
	screenGui.Padding = UDim.new(0, 10, 0, guiPaddingBottom + inset.Y) -- Padding phải và dưới

	notificationContainer = screenGui
	return notificationContainer
end

-- // Hàm hiển thị thông báo //
local function showNotification(title, message)
	if not notificationContainer or not notificationContainer.Parent then
		warn("AntiAFK: Container thông báo không hợp lệ hoặc đã bị xóa.")
		-- Thử tạo lại nếu cần
		if not setupNotificationContainer() then
			warn("AntiAFK: Không thể tạo lại container thông báo.")
			return -- Không thể hiển thị nếu container không tồn tại
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
	newFrame.Parent = nil -- Thêm dòng này cho chắc chắn

	local icon = newFrame:FindFirstChild("Icon")
	local textFrame = newFrame:FindFirstChild("TextFrame")
	local titleLabel = textFrame and textFrame:FindFirstChild("Title")
	local messageLabel = textFrame and textFrame:FindFirstChild("Message")

	if not (icon and titleLabel and messageLabel) then
		warn("AntiAFK: Frame thông báo được clone bị lỗi cấu trúc.")
		newFrame:Destroy() -- Dọn dẹp frame lỗi
		return
	end

	-- Cập nhật nội dung
	titleLabel.Text = title or "Thông báo"
	messageLabel.Text = message or ""
	newFrame.Name = "Notification_" .. (title or "Default")

	-- Đặt parent sau khi đã cấu hình xong
	newFrame.Parent = notificationContainer

	-- Tween xuất hiện
	local tweenInfoAppear = TweenInfo.new(animationTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local targetTransparency = 0.2 -- Độ mờ của nền
	local appearGoals = {
		BackgroundTransparency = targetTransparency,
		ImageTransparency = 0,
		TextTransparency = 0,
	}

	local fadeInTweenFrame = TweenService:Create(newFrame, tweenInfoAppear, { BackgroundTransparency = appearGoals.BackgroundTransparency })
	local fadeInTweenIcon = TweenService:Create(icon, tweenInfoAppear, { ImageTransparency = appearGoals.ImageTransparency })
	local fadeInTweenTitle = TweenService:Create(titleLabel, tweenInfoAppear, { TextTransparency = appearGoals.TextTransparency })
	local fadeInTweenMessage = TweenService:Create(messageLabel, tweenInfoAppear, { TextTransparency = appearGoals.TextTransparency })

	fadeInTweenFrame:Play()
	fadeInTweenIcon:Play()
	fadeInTweenTitle:Play()
	fadeInTweenMessage:Play()

	-- Lên lịch trình tự hủy và tween biến mất
	local fadeOutDelay = task.delay(notificationDuration, function()
		-- Đảm bảo frame vẫn còn tồn tại trước khi tween biến mất
		if not newFrame or not newFrame.Parent then return end

		local tweenInfoDisappear = TweenInfo.new(animationTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In) -- Dùng EasingDirection.In cho biến mất
		local disappearGoals = {
			BackgroundTransparency = 1,
			ImageTransparency = 1,
			TextTransparency = 1,
		}
		local fadeOutTweenFrame = TweenService:Create(newFrame, tweenInfoDisappear, { BackgroundTransparency = disappearGoals.BackgroundTransparency })
		local fadeOutTweenIcon = TweenService:Create(icon, tweenInfoDisappear, { ImageTransparency = disappearGoals.ImageTransparency })
		local fadeOutTweenTitle = TweenService:Create(titleLabel, tweenInfoDisappear, { TextTransparency = disappearGoals.TextTransparency })
		local fadeOutTweenMessage = TweenService:Create(messageLabel, tweenInfoDisappear, { TextTransparency = disappearGoals.TextTransparency })

		-- Chạy đồng thời các tween biến mất
		fadeOutTweenFrame:Play()
		fadeOutTweenIcon:Play()
		fadeOutTweenTitle:Play()
		fadeOutTweenMessage:Play()

		-- Đợi tween chính (frame) hoàn thành rồi mới hủy
		fadeOutTweenFrame.Completed:Once(function()
			if newFrame and newFrame.Parent then
				newFrame:Destroy()
			end
		end)
	end)

	-- Có thể lưu lại `fadeOutDelay` nếu cần cancel (ví dụ: người dùng click vào thông báo)
end

-- // Hàm thực hiện hành động chống AFK //
local function performAntiAFKAction()
	if not enableIntervention then return end -- Kiểm tra nếu can thiệp được bật

	local success, err = pcall(function()
		-- Nhấn phím xuống
		VirtualInputManager:SendKeyEvent(true, simulatedKeyCode, false, game)
		-- Đợi một khoảng ngắn
		task.wait(0.05 + math.random() * 0.05) -- Thêm chút ngẫu nhiên để tránh bị phát hiện quá máy móc
		-- Nhả phím ra
		VirtualInputManager:SendKeyEvent(false, simulatedKeyCode, false, game)
	end)

	if not success then
		warn("AntiAFK: Không thể mô phỏng nhấn phím " .. tostring(simulatedKeyCode) .. ". Lỗi:", err)
	else
		lastInterventionTime = os.clock()
		interventionCounter += 1
		print(string.format("AntiAFK: Đã thực hiện can thiệp lần %d (nhấn %s)", interventionCounter, tostring(simulatedKeyCode)))
	end
end

-- // Hàm xử lý khi có Input từ người dùng //
local function onInput()
	local now = os.clock()
	-- Chỉ thực hiện hành động nếu trước đó đang bị coi là AFK
	if isConsideredAFK then
		isConsideredAFK = false
		lastInterventionTime = 0 -- Reset bộ đếm thời gian can thiệp
		interventionCounter = 0 -- Reset số lần can thiệp
		showNotification("Bạn đã quay lại!", "Đã tạm dừng can thiệp AFK.")
		print("AntiAFK: Người dùng không còn AFK.")
	end
	-- Luôn cập nhật thời gian input cuối cùng
	lastInputTime = now
end

-- // Hàm dọn dẹp tài nguyên khi Script dừng hoặc Player rời đi //
local function cleanup()
	print("AntiAFK: Dọn dẹp tài nguyên...")
	-- Ngắt kết nối các sự kiện
	if inputBeganConnection then
		inputBeganConnection:Disconnect()
		inputBeganConnection = nil
	end
	if inputChangedConnection then
		inputChangedConnection:Disconnect()
		inputChangedConnection = nil
	end
	-- Hủy GUI
	if notificationContainer and notificationContainer.Parent then
		notificationContainer:Destroy()
	end
	notificationContainer = nil
	notificationTemplate = nil -- Không cần hủy template vì nó không có Parent
end

-- // Hàm chính chạy logic //
local function main()
	-- Khởi tạo GUI
	notificationContainer = setupNotificationContainer()
	if not notificationContainer then
		warn("AntiAFK: Không thể khởi tạo container GUI. Script sẽ không hiển thị thông báo.")
		-- Vẫn có thể chạy logic AFK nền nếu muốn, nhưng thông báo sẽ không hoạt động.
		-- Để đơn giản, ta dừng ở đây nếu GUI lỗi.
		return
	end
	notificationTemplate = createNotificationTemplate()
	if not notificationTemplate then
	    warn("AntiAFK: Không thể tạo template GUI. Script sẽ không hiển thị thông báo.")
		return
	end

	-- Kết nối sự kiện Input
	inputBeganConnection = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if gameProcessedEvent then return end -- Bỏ qua nếu input đã được game/GUI xử lý
		-- Chỉ quan tâm đến các loại input chính
		if input.UserInputType == Enum.UserInputType.Keyboard or
		   input.UserInputType == Enum.UserInputType.MouseButton1 or
		   input.UserInputType == Enum.UserInputType.MouseButton2 or
		   input.UserInputType == Enum.UserInputType.Touch then
			onInput()
		end
	end)

	inputChangedConnection = UserInputService.InputChanged:Connect(function(input, gameProcessedEvent)
		if gameProcessedEvent then return end -- Bỏ qua nếu input đã được game/GUI xử lý
		-- Quan tâm đến di chuyển chuột, lăn chuột, gamepad
		if input.UserInputType == Enum.UserInputType.MouseMovement or
		   input.UserInputType == Enum.UserInputType.MouseWheel or
		   input.UserInputType.Name:find("Gamepad") then -- Bắt tất cả các loại Gamepad
			onInput()
		end
	end)

	-- Chờ một chút để game load xong rồi mới thông báo
	task.wait(3)
	showNotification("Anti AFK", "Đã được kích hoạt.")
	print("Anti-AFK Script đã khởi chạy và đang theo dõi input.")

	-- Vòng lặp chính để kiểm tra AFK
	while true do
		local waitTime = task.wait(1) -- Kiểm tra mỗi giây
		local now = os.clock()
		local idleTime = now - lastInputTime

		if isConsideredAFK then
			-- Đã bị coi là AFK
			local timeSinceLastIntervention = now - lastInterventionTime
			local timeSinceLastCheck = now - lastCheckTime

			-- Đến lúc can thiệp chưa?
			if timeSinceLastIntervention >= interventionInterval then
				performAntiAFKAction()
				-- lastInterventionTime sẽ được cập nhật bên trong performAntiAFKAction nếu thành công
			end

			-- Đến lúc hiển thị thông báo nhắc nhở chưa?
			if timeSinceLastCheck >= checkInterval then
				local nextInterventionIn = math.max(0, interventionInterval - timeSinceLastIntervention)
				local message = string.format("Can thiệp tiếp theo sau ~%.0f giây.", nextInterventionIn)
				if not enableIntervention then
					message = "Chế độ can thiệp đang tắt."
				end
				showNotification("Vẫn đang AFK...", message)
				lastCheckTime = now
			end

		else
			-- Chưa bị coi là AFK, kiểm tra xem đủ thời gian AFK chưa
			if idleTime >= afkThreshold then
				isConsideredAFK = true
				lastInterventionTime = now -- Bắt đầu đếm giờ từ lúc bị coi là AFK
				lastCheckTime = now
				interventionCounter = 0 -- Reset bộ đếm khi bắt đầu một chu kỳ AFK mới
				local message = string.format("Sẽ can thiệp sau ~%.0f giây nếu không hoạt động.", interventionInterval)
				if not enableIntervention then
					message = "Bạn hiện đang AFK (can thiệp tự động đang tắt)."
				end
				showNotification("Cảnh báo AFK!", message)
				print("AntiAFK: Người dùng được coi là AFK.")
				-- Thực hiện hành động ngay lập tức khi phát hiện AFK lần đầu tiên? (Tùy chọn)
				-- performAntiAFKAction()
			end
		end
	end
end

-- // Khởi chạy và Xử lý Dọn dẹp //

-- Chạy hàm chính trong một coroutine để không block các script khác và bắt lỗi khởi tạo
local mainThread = coroutine.create(main)
local success, err = coroutine.resume(mainThread)
if not success then
	warn("AntiAFK Lỗi Khởi Tạo:", err)
end

-- Kết nối sự kiện PlayerRemoving để dọn dẹp
-- Giả định player đã được gán ở đầu script
if player then
	player.CharacterRemoving:Connect(function()
		-- Có thể thêm logic reset hoặc tạm dừng tại đây nếu cần khi nhân vật chết/respawn
		-- Ví dụ: isConsideredAFK = false
	end)

	-- Quan trọng: Dọn dẹp khi người chơi thực sự rời game
	Players.PlayerRemoving:Connect(function(leavingPlayer)
		if leavingPlayer == player then
			cleanup()
			-- Dừng vòng lặp chính nếu coroutine đang chạy
			if coroutine.status(mainThread) == "suspended" or coroutine.status(mainThread) == "running" then
				-- Lưu ý: Không có cách trực tiếp để "dừng" một coroutine từ bên ngoài
				-- nếu nó đang trong `task.wait()`. Cách tốt nhất là `cleanup()` sẽ
				-- hủy các đối tượng và ngắt kết nối, làm cho các lần lặp tiếp theo
				-- bị lỗi hoặc không làm gì cả, và coroutine sẽ kết thúc tự nhiên.
				-- Hoặc có thể dùng một biến cờ `isRunning = false` để vòng lặp `while` kiểm tra.
				print("AntiAFK: Đã yêu cầu dừng vòng lặp chính.")
			end
		end
	end)
else
	warn("AntiAFK: Không tìm thấy LocalPlayer khi thiết lập PlayerRemoving listener.")
end
