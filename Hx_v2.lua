-- // ============================ CLEANUP SCRIPT CŨ ============================ //
if _G.UnifiedAntiAFK_AutoClicker_Running then
    if _G.UnifiedAntiAFK_AutoClicker_CleanupFunction then
        pcall(_G.UnifiedAntiAFK_AutoClicker_CleanupFunction)
        warn("Hx: Đã dừng và dọn dẹp instance cũ.")
    end
end
_G.UnifiedAntiAFK_AutoClicker_Running = true

-- // ============================ DỊCH VỤ & BIẾN TOÀN CỤC ============================ //
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
if not player then
    warn("Hx: Không tìm thấy LocalPlayer! Script sẽ không hoạt động.")
    _G.UnifiedAntiAFK_AutoClicker_Running = false
    return
end
local mouse = player:GetMouse()

-- // ============================ CẤU HÌNH ============================ //
local Config = {
    -- Anti-AFK
    AfkThreshold = 180,
    InterventionInterval = 300,
    CheckInterval = 60,
    EnableIntervention = true,
    SimulatedKeyCode = Enum.KeyCode.Space,

    DefaultCPS = 20,
    MinCPS = 1,
    MaxCPS = 100, -- Tăng giới hạn nếu cần
    DefaultClickPos = Vector2.new(mouse.X, mouse.Y),
		DefaultAutoClickMode = "Toggle",
		DefaultPlatform = "PC",
		DefaultHotkey = Enum.KeyCode.R,
		MobileButtonClickSize = 60,
		MobileButtonDefaultPos = UDim2.new(1, -80, 1, -80),

    -- GUI & Thông báo
    GuiTitle = "Hx_v2 menu",
    NotificationDuration = 5,
    AnimationTime = 0.3,
    IconAntiAFK = "rbxassetid://117118515787811",
    IconAutoClicker = "rbxassetid://117118515787811",
    IconFinger = "rbxassetid://95151289125969",
		IconToggleButton = "rbxassetid://117118515787811",
		IconMobileClickButton = "rbxassetid://95151289125969",

    GuiWidth = 320,
    GuiHeight = 480,
    ToggleButtonSize = 40,
    NotificationWidth = 250,
    NotificationHeight = 60,
    NotificationAnchor = Vector2.new(1, 1),
    NotificationPosition = UDim2.new(1, -18, 1, -48)
}

-- // ============================ BIẾN TRẠNG THÁI ============================ //
local State = {
    IsConsideredAFK = false,
    AutoClicking = false,
    ChoosingClickPos = false,
		IsBindingHotkey = false, 
		ClickTriggerActive = false,
		MobileButtonIsDragging = false,
    GuiVisible = true,
		MobileButtonLocked = false, 
    LastInputTime = os.clock(),
    LastInterventionTime = 0,
    LastCheckTime = 0,
    InterventionCounter = 0,
    CurrentCPS = Config.DefaultCPS,
    SelectedClickPos = Config.DefaultClickPos,
		AutoClickMode = Config.DefaultAutoClickMode,
		Platform = Config.DefaultPlatform,
		AutoClickHotkey = Config.DefaultHotkey,
    Connections = {},
    GuiElements = { 
			ScreenGui = nil,
			MainFrame = nil,
			ToggleButton = nil,
			AntiAFKStatusLabel = nil,
			AntiAFKToggle = nil,
			AutoClickToggle = nil,
			CPSBox = nil,
			LocateButton = nil,
			FingerIcon = nil,
			MobileClickButton = nil, 
			HotkeyButton = nil,
			MobileButtonCreateButton = nil,
			MobileButtonLockToggle = nil
		}
}

local autoClickCoroutine = nil

-- // ============================ HÀM DỌN DẸP (Cập nhật) ============================ //
local function cleanup()
    print("Hx: Bắt đầu dọn dẹp v3...")
    _G.UnifiedAntiAFK_AutoClicker_Running = false

    if State.AutoClicking then
        State.AutoClicking = false
        print("Hx: Đã yêu cầu dừng Auto Clicker.")
        autoClickCoroutine = nil
    end

		State.IsBindingHotkey = false 
		State.ChoosingClickPos = false

    for name, connection in pairs(State.Connections) do
        if connection and typeof(connection) == "RBXScriptConnection" then
            pcall(function() connection:Disconnect() end)
        end
        State.Connections[name] = nil
    end
    State.Connections = {} 

    if State.GuiElements.ScreenGui and State.GuiElements.ScreenGui.Parent then
        pcall(function() State.GuiElements.ScreenGui:Destroy() end)
        print("Hx: Đã hủy ScreenGui.")
    end
		if State.GuiElements.MobileClickButton and State.GuiElements.MobileClickButton.Parent then
			pcall(function() State.GuiElements.MobileClickButton:Destroy() end)
			print("Hx: Đã hủy MobileClickButton残.")
		end
    State.GuiElements = {}

    print("Hx: Dọn dẹp v3 hoàn tất.")
    _G.UnifiedAntiAFK_AutoClicker_CleanupFunction = nil
end
_G.UnifiedAntiAFK_AutoClicker_CleanupFunction = cleanup

-- // ============================ HỆ THỐNG THÔNG BÁO (Giữ nguyên) ============================ //
local notificationContainer = nil
local notificationTemplate = nil
local function createNotificationTemplate()
    if notificationTemplate then return notificationTemplate end
    local frame = Instance.new("Frame")
    frame.Name = "NotificationFrameTemplate"
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Size = UDim2.new(0, Config.NotificationWidth, 0, Config.NotificationHeight)
    frame.ClipsDescendants = true
    local corner = Instance.new("UICorner", frame); corner.CornerRadius = UDim.new(0, 8)
    local padding = Instance.new("UIPadding", frame); padding.PaddingLeft = UDim.new(0, 10); padding.PaddingRight = UDim.new(0, 10); padding.PaddingTop = UDim.new(0, 5); padding.PaddingBottom = UDim.new(0, 5)
    local listLayout = Instance.new("UIListLayout", frame); listLayout.FillDirection = Enum.FillDirection.Horizontal; listLayout.VerticalAlignment = Enum.VerticalAlignment.Center; listLayout.SortOrder = Enum.SortOrder.LayoutOrder; listLayout.Padding = UDim.new(0, 10)
    local icon = Instance.new("ImageLabel"); icon.Name = "Icon"; icon.Image = Config.IconAntiAFK; icon.BackgroundTransparency = 1; icon.ImageTransparency = 1; icon.Size = UDim2.new(0, 40, 0, 40); icon.LayoutOrder = 1; icon.Parent = frame
    local textFrame = Instance.new("Frame"); textFrame.Name = "TextFrame"; textFrame.BackgroundTransparency = 1; textFrame.Size = UDim2.new(1, -60, 1, 0); textFrame.LayoutOrder = 2; textFrame.Parent = frame
    local textListLayout = Instance.new("UIListLayout", textFrame); textListLayout.FillDirection = Enum.FillDirection.Vertical; textListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left; textListLayout.VerticalAlignment = Enum.VerticalAlignment.Center; textListLayout.SortOrder = Enum.SortOrder.LayoutOrder; textListLayout.Padding = UDim.new(0, 2)
    local title = Instance.new("TextLabel"); title.Name = "Title"; title.Text = "Tiêu đề"; title.Font = Enum.Font.GothamBold; title.TextSize = 15; title.TextColor3 = Color3.fromRGB(255, 255, 255); title.BackgroundTransparency = 1; title.TextTransparency = 1; title.TextXAlignment = Enum.TextXAlignment.Left; title.Size = UDim2.new(1, 0, 0, 18); title.LayoutOrder = 1; title.Parent = textFrame
    local message = Instance.new("TextLabel"); message.Name = "Message"; message.Text = "Nội dung tin nhắn."; message.Font = Enum.Font.Gotham; message.TextSize = 13; message.TextColor3 = Color3.fromRGB(200, 200, 200); message.BackgroundTransparency = 1; message.TextTransparency = 1; message.TextXAlignment = Enum.TextXAlignment.Left; message.TextWrapped = true; message.Size = UDim2.new(1, 0, 0.6, 0); message.LayoutOrder = 2; message.Parent = textFrame
    notificationTemplate = frame
    return notificationTemplate
end
local function setupNotificationContainer(parentGui)
    if notificationContainer and notificationContainer.Parent then return notificationContainer end
    local container = Instance.new("Frame")
    container.Name = "NotificationContainerFrame"; container.AnchorPoint = Config.NotificationAnchor; container.Position = Config.NotificationPosition; container.Size = UDim2.new(0, Config.NotificationWidth + 20, 0, 300); container.BackgroundTransparency = 1; container.Parent = parentGui
    local listLayout = Instance.new("UIListLayout", container); listLayout.FillDirection = Enum.FillDirection.Vertical; listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right; listLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom; listLayout.SortOrder = Enum.SortOrder.LayoutOrder; listLayout.Padding = UDim.new(0, 5)
    notificationContainer = container
    return notificationContainer
end
local function showNotification(title, message, iconType)
	pcall(function()
	    if not notificationContainer or not notificationContainer.Parent then
	        if State.GuiElements.ScreenGui and State.GuiElements.ScreenGui.Parent then
	            if not setupNotificationContainer(State.GuiElements.ScreenGui) then return end
	        else return end
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
	    if not (icon and titleLabel and messageLabel) then newFrame:Destroy(); return end
	    titleLabel.Text = title or "Thông báo"
	    messageLabel.Text = message or ""
	    if iconType == "AFK" then icon.Image = Config.IconAntiAFK
	    elseif iconType == "Clicker" then icon.Image = Config.IconAutoClicker
	    else icon.Image = Config.IconAntiAFK end
	    newFrame.Name = "Notification_" .. (title or "Default"):gsub("%s+", "")
	    newFrame.Parent = notificationContainer
	    local tweenInfoAppear = TweenInfo.new(Config.AnimationTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	    local fadeInTweenFrame = TweenService:Create(newFrame, tweenInfoAppear, { BackgroundTransparency = 0.2 })
	    local fadeInTweenIcon = TweenService:Create(icon, tweenInfoAppear, { ImageTransparency = 0 })
	    local fadeInTweenTitle = TweenService:Create(titleLabel, tweenInfoAppear, { TextTransparency = 0 })
	    local fadeInTweenMessage = TweenService:Create(messageLabel, tweenInfoAppear, { TextTransparency = 0 })
	    fadeInTweenFrame:Play(); fadeInTweenIcon:Play(); fadeInTweenTitle:Play(); fadeInTweenMessage:Play()
	    task.delay(Config.NotificationDuration, function()
	        if not newFrame or not newFrame.Parent then return end
	        local tweenInfoDisappear = TweenInfo.new(Config.AnimationTime, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
	        local fadeOutTweenFrame = TweenService:Create(newFrame, tweenInfoDisappear, { BackgroundTransparency = 1 })
	        local fadeOutTweenIcon = TweenService:Create(icon, tweenInfoDisappear, { ImageTransparency = 1 })
	        local fadeOutTweenTitle = TweenService:Create(titleLabel, tweenInfoDisappear, { TextTransparency = 1 })
	        local fadeOutTweenMessage = TweenService:Create(messageLabel, tweenInfoDisappear, { TextTransparency = 1 })
	        fadeOutTweenFrame:Play(); fadeOutTweenIcon:Play(); fadeOutTweenTitle:Play(); fadeOutTweenMessage:Play()
	        fadeOutTweenFrame.Completed:Connect(function()
	            if newFrame and newFrame.Parent then pcall(function() newFrame:Destroy() end) end
	        end)
	    end)
	end)
end

-- // ============================ CHỨC NĂNG CỐT LÕI (Cập nhật) ============================ //
local function isPositionOverScriptGui(position)
    if not State.GuiElements.ScreenGui then return false end
    local guiObjects = {
        State.GuiElements.MainFrame,
        State.GuiElements.ToggleButton,
        State.GuiElements.MobileClickButton 
    }
    for _, guiObject in ipairs(guiObjects) do
        if guiObject and guiObject:IsA("GuiObject") and guiObject.Visible and guiObject.AbsoluteSize.X > 0 then -- Chỉ kiểm tra object đang hiển thị và có kích thước
            local absPos = guiObject.AbsolutePosition
            local absSize = guiObject.AbsoluteSize
            if position.X >= absPos.X and position.X <= absPos.X + absSize.X and
               position.Y >= absPos.Y and position.Y <= absPos.Y + absSize.Y then
               return true 
            end
        end
    end
    return false 
end


local function performAntiAFKAction()
		if not Config.EnableIntervention then return end
    local success, err = pcall(function()
        VirtualInputManager:SendKeyEvent(true, Config.SimulatedKeyCode, false, game)
        task.wait(0.05 + math.random() * 0.05)
        VirtualInputManager:SendKeyEvent(false, Config.SimulatedKeyCode, false, game)
    end)
    if not success then
        warn("Hx: Lỗi khi can thiệp AFK:", err)
        showNotification("Lỗi Anti-AFK", "Không thể mô phỏng phím.", "AFK")
    else
        State.LastInterventionTime = os.clock()
        State.InterventionCounter = State.InterventionCounter + 1
    end
end

local function onInputDetected()
		local now = os.clock()
    if State.IsConsideredAFK then
        State.IsConsideredAFK = false
        State.LastInterventionTime = 0
        State.InterventionCounter = 0
        showNotification("Bạn đã quay lại!", "Đã tạm dừng can thiệp AFK.", "AFK")
        print("Hx: Người dùng không còn AFK.")
        if State.GuiElements.AntiAFKStatusLabel then
             State.GuiElements.AntiAFKStatusLabel.Text = "Trạng thái AFK: Bình thường"
             State.GuiElements.AntiAFKStatusLabel.TextColor3 = Color3.fromRGB(180, 255, 180)
        end
    end
    State.LastInputTime = now
end

local function doAutoClick()
    while State.AutoClicking do
				local clickPos = State.SelectedClickPos
				local currentMousePos = UserInputService:GetMouseLocation() 

				if State.MobileButtonIsDragging or isPositionOverScriptGui(currentMousePos) or isPositionOverScriptGui(clickPos) then
				else
	        local success, err = pcall(function()
	            if not State.AutoClicking then return end
	            VirtualInputManager:SendMouseButtonEvent(clickPos.X, clickPos.Y, 0, true, game, 0)
	            if not State.AutoClicking then return end
	            VirtualInputManager:SendMouseButtonEvent(clickPos.X, clickPos.Y, 0, false, game, 0)
	        end)
	        if not success then
	            warn("Hx: Lỗi khi auto click:", err)
	            showNotification("Lỗi Auto Click", "Không thể mô phỏng click.", "Clicker")
	            State.AutoClicking = false
	            if State.GuiElements.AutoClickToggle then
	                 State.GuiElements.AutoClickToggle.Text = "Auto Click: OFF"
	                 State.GuiElements.AutoClickToggle.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	            end
	            break
	        end
				end 

        if not State.AutoClicking then break end
				local waitTime = 1 / State.CurrentCPS
        task.wait(waitTime)
    end
    print("Hx: Vòng lặp Auto Click đã dừng.")
    autoClickCoroutine = nil
end

local function startClick()
    if State.AutoClicking then return end
    if State.ChoosingClickPos then
        showNotification("Auto Clicker", "Đang chọn vị trí, không thể bật.", "Clicker")
        return
    end

    State.AutoClicking = true
    if State.GuiElements.AutoClickToggle then
        State.GuiElements.AutoClickToggle.Text = "Auto Click: ON"
        State.GuiElements.AutoClickToggle.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
    end
    showNotification("Auto Clicker", string.format("Đã bật (%.0f CPS)", State.CurrentCPS), "Clicker")
    print("Hx: Bắt đầu Auto Click.")
    if not autoClickCoroutine or coroutine.status(autoClickCoroutine) == "dead" then
        autoClickCoroutine = task.spawn(doAutoClick)
    end
end

local function stopClick()
    if not State.AutoClicking then return end

    State.AutoClicking = false
    if State.GuiElements.AutoClickToggle then
        State.GuiElements.AutoClickToggle.Text = "Auto Click: OFF"
        State.GuiElements.AutoClickToggle.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    end
    showNotification("Auto Clicker", "Đã tắt.", "Clicker")
    print("Hx: Đã yêu cầu dừng Auto Click.")
end

local function triggerAutoClick()
	if State.AutoClickMode == "Toggle" then
		if State.AutoClicking then
			stopClick()
		else
			startClick()
		end
	elseif State.AutoClickMode == "Hold" then
		if State.ClickTriggerActive and not State.AutoClicking then
			startClick()
		elseif not State.ClickTriggerActive and State.AutoClicking then
			stopClick()
		end
	end
end

local function startChoosingClickPos()
		if State.ChoosingClickPos then return end
    if State.AutoClicking then stopClick() end 

    State.ChoosingClickPos = true
		if State.GuiElements.MainFrame then State.GuiElements.MainFrame.Visible = false end
		if State.GuiElements.FingerIcon then
			State.GuiElements.FingerIcon.Image = Config.IconFinger
	    State.GuiElements.FingerIcon.Visible = true
			State.GuiElements.FingerIcon.Position = UDim2.fromOffset(mouse.X - 20, mouse.Y - 20)
		end
    showNotification("Chọn vị trí", "Click 2 lần để xác định vị trí mới.", "Clicker")
    print("Hx: Bắt đầu chọn vị trí click.")

    local clickCount = 0
    if State.Connections.MouseClickChoose then State.Connections.MouseClickChoose:Disconnect(); State.Connections.MouseClickChoose = nil end
    if State.Connections.MouseMoveChoose then State.Connections.MouseMoveChoose:Disconnect(); State.Connections.MouseMoveChoose = nil end

		State.Connections.MouseMoveChoose = RunService.RenderStepped:Connect(function()
			if State.ChoosingClickPos and State.GuiElements.FingerIcon and State.GuiElements.FingerIcon.Visible then
				local mPos = UserInputService:GetMouseLocation()
				State.GuiElements.FingerIcon.Position = UDim2.fromOffset(mPos.X - 20, mPos.Y - 20)
			end
		end)

    State.Connections.MouseClickChoose = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        if gameProcessedEvent then return end
				if not State.ChoosingClickPos then return end 
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
	        clickCount = clickCount + 1
	        if clickCount == 1 then
	            showNotification("Chọn vị trí", "Click lần nữa để xác nhận.", "Clicker")
	        elseif clickCount >= 2 then
							local finalPos = UserInputService:GetMouseLocation()
	            State.SelectedClickPos = finalPos 

	            if State.Connections.MouseClickChoose then State.Connections.MouseClickChoose:Disconnect(); State.Connections.MouseClickChoose = nil end
							if State.Connections.MouseMoveChoose then State.Connections.MouseMoveChoose:Disconnect(); State.Connections.MouseMoveChoose = nil end

	            if State.GuiElements.FingerIcon then State.GuiElements.FingerIcon.Visible = false end
	            if State.GuiElements.MainFrame then State.GuiElements.MainFrame.Visible = State.GuiVisible end
	            State.ChoosingClickPos = false 
	            showNotification("Chọn vị trí", string.format("Đã chọn: (%.0f, %.0f)", State.SelectedClickPos.X, State.SelectedClickPos.Y), "Clicker")
	            print("Hx: Đã chọn vị trí click mới:", State.SelectedClickPos)
	        end
				end
    end)
end

local function startBindingHotkey()
	if State.IsBindingHotkey then return end
	State.IsBindingHotkey = true
	if State.GuiElements.HotkeyButton then
		State.GuiElements.HotkeyButton.Text = "Nhấn phím..." 
		State.GuiElements.HotkeyButton.BackgroundColor3 = Color3.fromRGB(200, 150, 50) 
	end
	showNotification("Đặt Hotkey", "Nhấn phím bất kỳ để đặt làm hotkey.", "Clicker")

	if State.Connections.HotkeyBinding then State.Connections.HotkeyBinding:Disconnect(); State.Connections.HotkeyBinding = nil end

	State.Connections.HotkeyBinding = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if gameProcessedEvent then return end 
		if not State.IsBindingHotkey then return end 

		if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
			State.AutoClickHotkey = input.KeyCode 
			State.IsBindingHotkey = false 

			if State.GuiElements.HotkeyButton then
				State.GuiElements.HotkeyButton.Text = "Hotkey: " .. input.KeyCode.Name
				State.GuiElements.HotkeyButton.BackgroundColor3 = Color3.fromRGB(60, 100, 180) 
			end
			showNotification("Đặt Hotkey", "Đã đặt hotkey thành: " .. input.KeyCode.Name, "Clicker")
			print("Hx: Hotkey được đặt thành:", input.KeyCode.Name)

			if State.Connections.HotkeyBinding then State.Connections.HotkeyBinding:Disconnect(); State.Connections.HotkeyBinding = nil end

			connectHotkeyListener()
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
			showNotification("Đặt Hotkey", "Vui lòng nhấn một phím trên bàn phím.", "Clicker")
		end
	end)
end

local function connectHotkeyListener()
	if State.Connections.HotkeyInputBegan then State.Connections.HotkeyInputBegan:Disconnect(); State.Connections.HotkeyInputBegan = nil end
	if State.Connections.HotkeyInputEnded then State.Connections.HotkeyInputEnded:Disconnect(); State.Connections.HotkeyInputEnded = nil end

	if State.Platform ~= "PC" then return end

	State.Connections.HotkeyInputBegan = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if gameProcessedEvent or State.Platform ~= "PC" or State.IsBindingHotkey then return end 
		if input.KeyCode == State.AutoClickHotkey then
			State.ClickTriggerActive = true
			triggerAutoClick() 
		end
	end)

	State.Connections.HotkeyInputEnded = UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
		if gameProcessedEvent or State.Platform ~= "PC" then return end
		if input.KeyCode == State.AutoClickHotkey then
			State.ClickTriggerActive = false
			if State.AutoClickMode == "Hold" then 
				triggerAutoClick()
			end
		end
	end)
	print("Hx: Đã kết nối trình nghe cho hotkey:", State.AutoClickHotkey.Name)
end


local function createOrShowMobileButton()
	if State.GuiElements.MobileClickButton and State.GuiElements.MobileClickButton.Parent then
		State.GuiElements.MobileClickButton.Visible = true
		print("Hx: Hiển thị lại nút Mobile đã có.")
	else
		local button = Instance.new("ImageButton")
		button.Name = "MobileClickButton"
		button.Size = UDim2.fromOffset(Config.MobileButtonClickSize, Config.MobileButtonClickSize)
		button.Position = Config.MobileButtonDefaultPos
		button.Image = Config.IconMobileClickButton
		button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
		button.BackgroundTransparency = 0.4
		button.Active = true
		button.Draggable = not State.MobileButtonLocked 
		button.Selectable = true
		button.ZIndex = 15 
		button.Parent = State.GuiElements.ScreenGui 

		local corner = Instance.new("UICorner", button)
		corner.CornerRadius = UDim.new(0.5, 0) 

		State.GuiElements.MobileClickButton = button
		print("Hx: Đã tạo nút Mobile mới.")

		connectMobileButtonListeners(button)
	end
	if State.GuiElements.MobileClickButton then
		State.GuiElements.MobileClickButton.Draggable = not State.MobileButtonLocked
	end
end

local function connectMobileButtonListeners(button)
	if State.Connections.MobileButtonInputBegan then State.Connections.MobileButtonInputBegan:Disconnect(); State.Connections.MobileButtonInputBegan = nil end
	if State.Connections.MobileButtonInputEnded then State.Connections.MobileButtonInputEnded:Disconnect(); State.Connections.MobileButtonInputEnded = nil end
	if State.Connections.MobileButtonDragBegan then State.Connections.MobileButtonDragBegan:Disconnect(); State.Connections.MobileButtonDragBegan = nil end
	if State.Connections.MobileButtonDragEnded then State.Connections.MobileButtonDragEnded:Disconnect(); State.Connections.MobileButtonDragEnded = nil end

	State.Connections.MobileButtonInputBegan = button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			if not State.MobileButtonIsDragging then
				State.ClickTriggerActive = true
				triggerAutoClick()
			end
		end
	end)

	State.Connections.MobileButtonInputEnded = button.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
			State.ClickTriggerActive = false
			if State.AutoClickMode == "Hold" then 
				triggerAutoClick()
			end
		end
	end)

	State.Connections.MobileButtonDragBegan = button.DragBegan:Connect(function()
		State.MobileButtonIsDragging = true
		if State.AutoClicking and State.AutoClickMode == "Hold" then
			stopClick()
		end
		print("Hx: Bắt đầu kéo nút Mobile.")
	end)

	State.Connections.MobileButtonDragEnded = button.DragStopped:Connect(function()
		State.MobileButtonIsDragging = false
		print("Hx: Kết thúc kéo nút Mobile.")
	end)
end

local function hideOrDestroyMobileButton()
	if State.GuiElements.MobileClickButton and State.GuiElements.MobileClickButton.Parent then
		State.GuiElements.MobileClickButton.Visible = false
		print("Hx: Đã ẩn nút Mobile.")
	end
end

local function updatePlatformUI()
	local isPC = (State.Platform == "PC")
	if State.GuiElements.HotkeyButton then State.GuiElements.HotkeyButton.Visible = isPC end
	if State.GuiElements.MobileButtonCreateButton then State.GuiElements.MobileButtonCreateButton.Visible = not isPC end
	if State.GuiElements.MobileButtonLockToggle then State.GuiElements.MobileButtonLockToggle.Visible = not isPC end

	if isPC then
		hideOrDestroyMobileButton()
		if State.Connections.MobileButtonInputBegan then State.Connections.MobileButtonInputBegan:Disconnect(); State.Connections.MobileButtonInputBegan = nil end
		if State.Connections.MobileButtonInputEnded then State.Connections.MobileButtonInputEnded:Disconnect(); State.Connections.MobileButtonInputEnded = nil end
		if State.Connections.MobileButtonDragBegan then State.Connections.MobileButtonDragBegan:Disconnect(); State.Connections.MobileButtonDragBegan = nil end
		if State.Connections.MobileButtonDragEnded then State.Connections.MobileButtonDragEnded:Disconnect(); State.Connections.MobileButtonDragEnded = nil end
		connectHotkeyListener()
	else
		if State.Connections.HotkeyInputBegan then State.Connections.HotkeyInputBegan:Disconnect(); State.Connections.HotkeyInputBegan = nil end
		if State.Connections.HotkeyInputEnded then State.Connections.HotkeyInputEnded:Disconnect(); State.Connections.HotkeyInputEnded = nil end
		if State.GuiElements.MobileClickButton and State.GuiElements.MobileClickButton.Parent then
			State.GuiElements.MobileClickButton.Visible = true
		end
	end
	print("Hx: Cập nhật UI cho platform:", State.Platform)
end


-- // ============================ TẠO GUI (Cập nhật lớn) ============================ //
local function createGuiElement(class, properties)
    local element = Instance.new(class)
    for prop, value in pairs(properties) do
        pcall(function() element[prop] = value end) 
    end
    return element
end

local function createToggle(name, text, order, parent, initialState, onToggle)
	local button = createGuiElement("TextButton", {
			Name = name,
			Size = UDim2.new(1, -10, 0, 30),
			Text = text .. (initialState and ": ON" or ": OFF"),
			Font = Enum.Font.GothamBold,
			TextSize = 14,
			TextColor3 = Color3.fromRGB(255, 255, 255),
			BackgroundColor3 = initialState and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(150, 50, 50),
			LayoutOrder = order,
			Parent = parent
	})
	createGuiElement("UICorner", { CornerRadius = UDim.new(0, 4), Parent = button })
	if onToggle then
			State.Connections[name .. "Click"] = button.MouseButton1Click:Connect(function()
					local newState = onToggle() 
					button.Text = text .. (newState and ": ON" or ": OFF")
					button.BackgroundColor3 = newState and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(150, 50, 50)
			end)
	end
	return button
end

local function createRadioGroup(namePrefix, options, defaultOption, order, parent, onSelected)
	local groupFrame = createGuiElement("Frame", {
		Name = namePrefix .. "GroupFrame",
		Size = UDim2.new(1, -10, 0, 30),
		BackgroundTransparency = 1,
		LayoutOrder = order,
		Parent = parent
	})
	local listLayout = createGuiElement("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		HorizontalAlignment = Enum.HorizontalAlignment.Center,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 5),
		Parent = groupFrame
	})

	local buttons = {}
	local currentSelection = defaultOption

	local function updateButtons()
		for option, button in pairs(buttons) do
			if option == currentSelection then
				button.BackgroundColor3 = Color3.fromRGB(60, 100, 180) 
				button.TextColor3 = Color3.fromRGB(255, 255, 255)
			else
				button.BackgroundColor3 = Color3.fromRGB(80, 80, 90) 
				button.TextColor3 = Color3.fromRGB(200, 200, 200)
			end
		end
	end

	for i, optionName in ipairs(options) do
		local button = createGuiElement("TextButton", {
			Name = namePrefix .. optionName:gsub("%s+", ""), 
			Size = UDim2.new(0, (Config.GuiWidth - 30 - (table.getn(options)-1)*5) / table.getn(options) , 1, 0), 
			Text = optionName,
			Font = Enum.Font.GothamMedium,
			TextSize = 13,
			LayoutOrder = i,
			Parent = groupFrame
		})
		createGuiElement("UICorner", { CornerRadius = UDim.new(0, 4), Parent = button })
		buttons[optionName] = button

		State.Connections[button.Name .. "Click"] = button.MouseButton1Click:Connect(function()
			if currentSelection ~= optionName then
				currentSelection = optionName
				updateButtons()
				if onSelected then
					onSelected(currentSelection)
				end
			end
		end)
	end

	updateButtons() 
	return groupFrame, buttons
end


local function createGUI()
    local oldGui = CoreGui:FindFirstChild("UnifiedAFKClickerGui_v3")
    if oldGui then pcall(function() oldGui:Destroy() end) end

    local screenGui = createGuiElement("ScreenGui", {
        Name = "Hx_v2 menuv2",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        DisplayOrder = 1002,
        Parent = CoreGui
    })
    State.GuiElements.ScreenGui = screenGui
		createGuiElement("UIScale", { Parent = screenGui })

    notificationContainer = setupNotificationContainer(screenGui)
    notificationTemplate = createNotificationTemplate()

    local toggleButton = createGuiElement("ImageButton", {
        Name = "GuiToggleButton",
        Size = UDim2.fromOffset(Config.ToggleButtonSize, Config.ToggleButtonSize),
        Position = UDim2.new(0.5, -Config.ToggleButtonSize / 2, 0, 10),
        Image = Config.IconToggleButton, 
        BackgroundColor3 = Color3.fromRGB(50, 50, 55), BackgroundTransparency = 0.3,
        BorderSizePixel = 1, BorderColor3 = Color3.fromRGB(80, 80, 90),
        Active = true, Draggable = true, Selectable = true, Parent = screenGui, ZIndex = 5
    })
    createGuiElement("UICorner", { CornerRadius = UDim.new(0, 6), Parent = toggleButton })
    State.GuiElements.ToggleButton = toggleButton

    local frame = createGuiElement("Frame", {
        Name = "MainFrame",
        Size = UDim2.fromOffset(Config.GuiWidth, Config.GuiHeight),
        Position = UDim2.fromOffset(100, 150),
        BackgroundColor3 = Color3.fromRGB(35, 35, 40), BorderColor3 = Color3.fromRGB(80, 80, 90), BorderSizePixel = 1,
        Active = true, Draggable = true, ClipsDescendants = true, Visible = State.GuiVisible, Parent = screenGui, ZIndex = 2
    })
    createGuiElement("UICorner", { CornerRadius = UDim.new(0, 6), Parent = frame })
    State.GuiElements.MainFrame = frame

    local listLayout = createGuiElement("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center, FillDirection = Enum.FillDirection.Vertical, Parent = frame })
    createGuiElement("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = frame })

    createGuiElement("TextLabel", { Name = "Title", Size = UDim2.new(1, 0, 0, 25), Text = Config.GuiTitle, Font = Enum.Font.GothamBold, TextSize = 16, TextColor3 = Color3.fromRGB(230, 230, 230), BackgroundTransparency = 1, LayoutOrder = 1, Parent = frame })

    local currentLayoutOrder = 1
    createGuiElement("TextLabel", { Name = "AntiAFKSection", Size = UDim2.new(1, 0, 0, 20), Text = "--- Anti-AFK ---", Font = Enum.Font.GothamMedium, TextSize = 14, TextColor3 = Color3.fromRGB(150, 180, 255), BackgroundTransparency = 1, LayoutOrder = currentLayoutOrder + 1, Parent = frame })
    local antiAFKStatusLabel = createGuiElement("TextLabel", { Name = "AntiAFKStatus", Size = UDim2.new(1, 0, 0, 20), Text = "Trạng thái AFK: Bình thường", Font = Enum.Font.Gotham, TextSize = 13, TextColor3 = Color3.fromRGB(180, 255, 180), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = currentLayoutOrder + 2, Parent = frame })
    State.GuiElements.AntiAFKStatusLabel = antiAFKStatusLabel
    local antiAFKToggle = createToggle("AntiAFKToggle", "Can thiệp AFK", currentLayoutOrder + 3, frame, Config.EnableIntervention,
        function()
            Config.EnableIntervention = not Config.EnableIntervention
            local statusText = Config.EnableIntervention and "BẬT" or "TẮT"
            showNotification("Anti-AFK", "Can thiệp tự động đã " .. statusText, "AFK")
            print("Hx: Can thiệp AFK được đặt thành:", Config.EnableIntervention)
            return Config.EnableIntervention 
        end
    )
    State.GuiElements.AntiAFKToggle = antiAFKToggle
    currentLayoutOrder = currentLayoutOrder + 3

    createGuiElement("TextLabel", { Name = "AutoClickerSection", Size = UDim2.new(1, 0, 0, 20), Text = "--- Auto Clicker ---", Font = Enum.Font.GothamMedium, TextSize = 14, TextColor3 = Color3.fromRGB(255, 180, 150), BackgroundTransparency = 1, LayoutOrder = currentLayoutOrder + 1, Parent = frame })
    currentLayoutOrder = currentLayoutOrder + 1

		local autoClickToggle = createToggle("AutoClickToggle", "Auto Click", currentLayoutOrder + 1, frame, State.AutoClicking,
				function()
						if State.AutoClicking then stopClick() else startClick() end
						return State.AutoClicking 
				end
		)
		State.GuiElements.AutoClickToggle = autoClickToggle
		currentLayoutOrder = currentLayoutOrder + 1

		createGuiElement("TextLabel", { Name = "ModeLabel", Size = UDim2.new(1, -10, 0, 15), Text = "Chế độ:", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Color3.fromRGB(200, 200, 200), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = currentLayoutOrder + 1, Parent = frame })
		local modeGroup, modeButtons = createRadioGroup("ClickMode", {"Toggle", "Hold"}, State.AutoClickMode, currentLayoutOrder + 2, frame,
				function(selectedMode)
						State.AutoClickMode = selectedMode
						print("Hx: Chế độ click đổi thành:", selectedMode)
						if State.AutoClicking and selectedMode == "Hold" then
								stopClick()
						end
				end
		)
		currentLayoutOrder = currentLayoutOrder + 2

		createGuiElement("TextLabel", { Name = "PlatformLabel", Size = UDim2.new(1, -10, 0, 15), Text = "Nền tảng:", Font = Enum.Font.Gotham, TextSize = 12, TextColor3 = Color3.fromRGB(200, 200, 200), BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = currentLayoutOrder + 1, Parent = frame })
		local platformGroup, platformButtons = createRadioGroup("Platform", {"PC", "Mobile"}, State.Platform, currentLayoutOrder + 2, frame,
				function(selectedPlatform)
						State.Platform = selectedPlatform
						print("Hx: Nền tảng đổi thành:", selectedPlatform)
						updatePlatformUI() 
				end
		)
		currentLayoutOrder = currentLayoutOrder + 2

		local hotkeyButton = createGuiElement("TextButton", {
				Name = "HotkeyButton",
				Size = UDim2.new(1, -10, 0, 30),
				Text = "Hotkey: " .. State.AutoClickHotkey.Name,
				Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundColor3 = Color3.fromRGB(60, 100, 180),
				LayoutOrder = currentLayoutOrder + 1,
				Visible = (State.Platform == "PC"), 
				Parent = frame
		})
		createGuiElement("UICorner", { CornerRadius = UDim.new(0, 4), Parent = hotkeyButton })
		State.GuiElements.HotkeyButton = hotkeyButton
		State.Connections.HotkeyButtonClick = hotkeyButton.MouseButton1Click:Connect(startBindingHotkey)

		local mobileCreateButton = createGuiElement("TextButton", {
				Name = "MobileButtonCreateButton",
				Size = UDim2.new(1, -10, 0, 30),
				Text = "Tạo/Hiện nút nhấn Mobile",
				Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundColor3 = Color3.fromRGB(60, 180, 100), 
				LayoutOrder = currentLayoutOrder + 1, 
				Visible = (State.Platform == "Mobile"), 
				Parent = frame
		})
		createGuiElement("UICorner", { CornerRadius = UDim.new(0, 4), Parent = mobileCreateButton })
		State.GuiElements.MobileButtonCreateButton = mobileCreateButton
		State.Connections.MobileCreateClick = mobileCreateButton.MouseButton1Click:Connect(createOrShowMobileButton)

		local mobileLockToggle = createToggle("MobileButtonLockToggle", "Khóa vị trí nút", currentLayoutOrder + 2, frame, State.MobileButtonLocked,
				function()
						State.MobileButtonLocked = not State.MobileButtonLocked
						if State.GuiElements.MobileClickButton then
								State.GuiElements.MobileClickButton.Draggable = not State.MobileButtonLocked
						end
						showNotification("Nút Mobile", State.MobileButtonLocked and "Đã khóa vị trí." or "Đã mở khóa vị trí.", "Clicker")
						print("Hx: Khóa vị trí nút Mobile:", State.MobileButtonLocked)
						return State.MobileButtonLocked
				end
		)
		mobileLockToggle.Visible = (State.Platform == "Mobile") 
		State.GuiElements.MobileButtonLockToggle = mobileLockToggle
		currentLayoutOrder = currentLayoutOrder + 2 


    local cpsBox = createGuiElement("TextBox", {
        Name = "CPSBox", Size = UDim2.new(1, -10, 0, 30),
        PlaceholderText = string.format("CPS (hiện tại: %d)", State.CurrentCPS), Text = "",
        Font = Enum.Font.Gotham, TextSize = 14, TextColor3 = Color3.fromRGB(240, 240, 240),
        BackgroundColor3 = Color3.fromRGB(50, 50, 55), ClearTextOnFocus = true,
        TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = currentLayoutOrder + 1, Parent = frame
    })
    createGuiElement("UICorner", { CornerRadius = UDim.new(0, 4), Parent = cpsBox })
    State.GuiElements.CPSBox = cpsBox
    currentLayoutOrder = currentLayoutOrder + 1

    local locateBtn = createGuiElement("TextButton", {
				Name = "LocateButton", Size = UDim2.new(1, -10, 0, 30), Text = "Chọn vị trí Click",
				Font = Enum.Font.GothamBold, TextSize = 14, TextColor3 = Color3.fromRGB(255, 255, 255),
				BackgroundColor3 = Color3.fromRGB(60, 100, 180), LayoutOrder = currentLayoutOrder + 1, Parent = frame
		})
		createGuiElement("UICorner", { CornerRadius = UDim.new(0, 4), Parent = locateBtn })
    State.GuiElements.LocateButton = locateBtn
		State.Connections.LocateButtonClick = locateBtn.MouseButton1Click:Connect(startChoosingClickPos)
		currentLayoutOrder = currentLayoutOrder + 1


    local fingerIcon = createGuiElement("ImageLabel", { Name = "FingerIcon", Image = Config.IconFinger, Size = UDim2.fromOffset(40, 40), BackgroundTransparency = 1, Visible = false, ZIndex = 10, Parent = screenGui })
    State.GuiElements.FingerIcon = fingerIcon

    State.Connections.CPSBoxFocusLost = cpsBox.FocusLost:Connect(function(enterPressed)
        local text = cpsBox.Text
        local num = tonumber(text)
        if num and num >= Config.MinCPS and num <= Config.MaxCPS then
            State.CurrentCPS = math.floor(num)
            cpsBox.PlaceholderText = string.format("CPS (hiện tại: %d)", State.CurrentCPS)
            cpsBox.Text = ""
            showNotification("Auto Clicker", string.format("Đã đặt CPS thành %d", State.CurrentCPS), "Clicker")
            print("Hx: CPS được đặt thành:", State.CurrentCPS)
        else
            if text ~= "" then showNotification("Lỗi CPS", string.format("Nhập số từ %d đến %d", Config.MinCPS, Config.MaxCPS), "Clicker") end
            cpsBox.Text = ""
            cpsBox.PlaceholderText = string.format("CPS (hiện tại: %d)", State.CurrentCPS)
        end
    end)

    State.Connections.GuiToggleButtonClick = toggleButton.MouseButton1Click:Connect(function()
        State.GuiVisible = not State.GuiVisible
        frame.Visible = State.GuiVisible
        print("Hx: GUI visibility toggled to", State.GuiVisible)
    end)

		connectHotkeyListener()

    print("Hx: GUI v3 đã được tạo và kết nối sự kiện.")
end

-- // ============================ KHỞI TẠO & VÒNG LẶP CHÍNH (Cập nhật Fix Lỗi) ============================ //
local function initialize()
    createGUI()

    State.Connections.GlobalInputBegan = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        if gameProcessedEvent or State.IsBindingHotkey or (State.Platform == "PC" and input.KeyCode == State.AutoClickHotkey) then return end

        if input.UserInputType == Enum.UserInputType.Keyboard or
            input.UserInputType == Enum.UserInputType.MouseButton1 or
            input.UserInputType == Enum.UserInputType.MouseButton2 or
            input.UserInputType == Enum.UserInputType.Touch then
            onInputDetected()
        end
    end)
    State.Connections.GlobalInputChanged = UserInputService.InputChanged:Connect(function(input, gameProcessedEvent)
        if gameProcessedEvent then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or
            input.UserInputType == Enum.UserInputType.MouseWheel or
            input.UserInputType.Name:find("Gamepad") then
            onInputDetected()
        end
    end)

    if player then
        State.Connections.CharacterRemoving = player.CharacterRemoving:Connect(function() print("Hx: Nhân vật đang bị xóa.") end)
    end
    State.Connections.PlayerRemoving = Players.PlayerRemoving:Connect(function(leavingPlayer) if leavingPlayer == player then print("Hx: Người chơi rời đi, dọn dẹp."); cleanup() end end)

    task.wait(1)
    showNotification(Config.GuiTitle, "Đã kích hoạt!", "AFK")
    print("Hx: Script v3 đã khởi chạy thành công.")

    while _G.UnifiedAntiAFK_AutoClicker_Running do
        local now = os.clock()
        local idleTime = now - State.LastInputTime

        if State.IsConsideredAFK then
            local timeSinceLastIntervention = now - State.LastInterventionTime
            local timeSinceLastCheck = now - State.LastCheckTime

            if Config.EnableIntervention and timeSinceLastIntervention >= Config.InterventionInterval then
                performAntiAFKAction()
            end

            if timeSinceLastCheck >= Config.CheckInterval then
								local msg = "Can thiệp tự động đang tắt."
								if Config.EnableIntervention then
                		local nextInterventionIn = math.max(0, Config.InterventionInterval - timeSinceLastIntervention)
										if type(nextInterventionIn) == "number" then
											msg = string.format("Can thiệp tiếp theo sau ~%.0f giây.", nextInterventionIn)
										else
											msg = "Đang tính thời gian can thiệp..."
											warn("Hx: nextInterventionIn không phải là số:", nextInterventionIn)
										end
								end
                showNotification("Vẫn đang AFK...", msg, "AFK")
                State.LastCheckTime = now
            end
        else
            if idleTime >= Config.AfkThreshold then
                State.IsConsideredAFK = true
                State.LastInterventionTime = now
                State.LastCheckTime = now
                State.InterventionCounter = 0
                local msg = Config.EnableIntervention and string.format("Sẽ can thiệp sau ~%.0f giây.", Config.InterventionInterval) or "Can thiệp tự động đang tắt."
                showNotification("Cảnh báo AFK!", msg, "AFK")
                print("Hx: Người dùng được coi là AFK.")
                if State.GuiElements.AntiAFKStatusLabel then
                    State.GuiElements.AntiAFKStatusLabel.Text = "Trạng thái AFK: Đang AFK"
                    State.GuiElements.AntiAFKStatusLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
                end
            end
        end

        task.wait(1)
    end
    print("Hx: Vòng lặp chính đã kết thúc do cờ global.")
end

-- // ============================ CHẠY SCRIPT ============================ //
local success, err = pcall(initialize)
if not success then
    warn("Hx Lỗi Khởi Tạo Nghiêm Trọng v3:", err)
    if err then debug.traceback(err) end
    cleanup()
    _G.UnifiedAntiAFK_AutoClicker_Running = false
end
