-- ███████╗ ██████╗██████╗ ██╗██████╗ ████████╗     ██╗  ██╗██╗  ██╗
-- ██╔════╝██╔════╝██╔══██╗██║██╔══██╗╚══██╔══╝     ██║  ██║╚██╗██╔╝
-- ███████╗██║     ██████╔╝██║██████╔╝   ██║        ███████║ ╚███╔╝
-- ╚════██║██║     ██╔══██╗██║██╔═══╝    ██║        ██╔══██║ ██╔██╗
-- ███████║╚██████╗██║  ██║██║██║        ██║        ██║  ██║██╔╝ ██╗
-- ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝╚═╝        ╚═╝        ╚═╝  ╚═╝╚═╝  ╚═╝

--===== 🚀 Script Initialization & Reload Check =====--
if _G.UnifiedAntiAFK_AutoClicker_Running then
    if _G.UnifiedAntiAFK_AutoClicker_CleanupFunction then
        pcall(_G.UnifiedAntiAFK_AutoClicker_CleanupFunction)
        warn("Hx: Đã dừng và dọn dẹp instance cũ của script.")
    end
end
_G.UnifiedAntiAFK_AutoClicker_Running = true

--===== 🔌 Services & Global Variables =====--
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local GuiService = game:GetService("GuiService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
if not player then
    warn("Hx: Không tìm thấy LocalPlayer! Script sẽ không hoạt động.")
    _G.UnifiedAntiAFK_AutoClicker_Running = false
    return
end
local mouse = player:GetMouse()

--===== ⚙️ Script Configuration =====--
local Config = {
    AfkThreshold = 180,
    InterventionInterval = 300,
    CheckInterval = 300,
    EnableIntervention = true,

    DefaultCPS = 20,
    MinCPS = 1,
    MaxCPS = 100,
    DefaultClickPos = Vector2.new(mouse.X, mouse.Y),
    DefaultAutoClickMode = "Toggle",
    DefaultPlatform = (UserInputService:GetPlatform() == Enum.Platform.Windows or UserInputService:GetPlatform() == Enum.Platform.OSX) and "PC" or "Mobile",
    DefaultHotkey = Enum.KeyCode.R,
    MobileButtonClickSize = 60,
    MobileButtonDefaultPos = UDim2.new(1, -80, 1, -80),
    ClickTargetMarkerSize = 60,
    ClickTargetCenterDotSize = 8,

    GuiTitle = "Hx_v2",
    NotificationDuration = 4,
    AnimationTime = 0.2,
    IconAntiAFK = "rbxassetid://117118515787811",
    IconAutoClicker = "rbxassetid://117118515787811",
    IconToggleButton = "rbxassetid://117118515787811",
    IconMobileClickButton = "rbxassetid://95151289125969",
    IconLock = "rbxassetid://114181737500273",

    GuiWidth = 330,
    GuiHeight = 300,
    ToggleButtonSize = 40,
    LockButtonSize = 40,
    NotificationWidth = 250,
    NotificationHeight = 60,
    NotificationAnchor = Vector2.new(1, 1),
    NotificationPosition = UDim2.new(1, -18, 1, -48),
    ScrollbarThickness = 6,
    CPSBoxWidth = 80,
    TransparentToggleWidth = 110,
    TransparentBGLevel = 0.2,
    OpaqueBGLevel = 0,

    ColorBackground = Color3.fromRGB(35, 35, 40),
    ColorBorder = Color3.fromRGB(80, 80, 90),
    ColorTextPrimary = Color3.fromRGB(245, 245, 245),
    ColorTextSecondary = Color3.fromRGB(190, 190, 200),
    ColorInputBackground = Color3.fromRGB(50, 50, 55),
    ColorButtonPrimary = Color3.fromRGB(80, 130, 210),
    ColorButtonSecondary = Color3.fromRGB(110, 110, 120),
    ColorToggleOn = Color3.fromRGB(70, 180, 70),
    ColorToggleOff = Color3.fromRGB(200, 70, 70),
    ColorSectionHeader = Color3.fromRGB(170, 200, 255),
    ColorScrollbar = Color3.fromRGB(100, 100, 110),
    ColorToggleCircleBorder = Color3.fromRGB(255, 255, 255),
    ColorClickTargetCenter = Color3.fromRGB(255, 0, 0),
    ColorClickTargetBorder = Color3.fromRGB(255, 255, 255),
}

local TWEEN_INFO_FAST = TweenInfo.new(Config.AnimationTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local TWEEN_INFO_FAST_IN = TweenInfo.new(Config.AnimationTime, Enum.EasingStyle.Sine, Enum.EasingDirection.In)

--===== 📦 State Variables =====--
local State = {
    IsConsideredAFK = false,
    AutoClicking = false,
    ChoosingClickPos = false,
    IsBindingHotkey = false,
    ClickTriggerActive = false,
    MobileButtonIsDragging = false,
    GuiVisible = false,
    IsTransparent = true,
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
        ScreenGui = nil, MainFrame = nil, ScrollingFrame = nil, ContentListLayout = nil,
        GuiToggleButton = nil, TitleBarFrame = nil, TransparentToggle = nil, CircleIndicator = nil, TransparentTextButton = nil,
        MobileClickButton = nil, NotificationContainer = nil,
        ClickTargetMarker = nil, LockButton = nil,
        AntiAFK = { StatusLabel = nil, Toggle = nil },
        AutoClicker = {
            Toggle = nil, ModeGroup = nil, PlatformGroup = nil,
            CpsLocateFrame = nil, CPSBox = nil, LocateButton = nil, HotkeyButton = nil,
            MobileCreateButton = nil, MobileLockToggle = nil
        }
    },
    SliderSupported = false
}
local autoClickCoroutine = nil

--===== 🧹 Cleanup Function =====--
local function cleanup()
    print("Hx: Bắt đầu dọn dẹp v2...")
    if not _G.UnifiedAntiAFK_AutoClicker_Running then return end
    _G.UnifiedAntiAFK_AutoClicker_Running = false

    if State.AutoClicking then
        State.AutoClicking = false
        print("Hx: Đã yêu cầu dừng Auto Clicker trong quá trình dọn dẹp.")
        autoClickCoroutine = nil
    end

    if State.ChoosingClickPos then
       if State.GuiElements.ClickTargetMarker then pcall(function() State.GuiElements.ClickTargetMarker:Destroy() end) end
       if State.GuiElements.LockButton then pcall(function() State.GuiElements.LockButton:Destroy() end) end
       State.ChoosingClickPos = false
    end

    State.IsBindingHotkey = false

    for name, connection in pairs(State.Connections) do
        if connection and typeof(connection) == "RBXScriptConnection" then
            pcall(function() connection:Disconnect() end)
        end
    end
    State.Connections = {}

    if State.GuiElements.ScreenGui and State.GuiElements.ScreenGui.Parent then
        pcall(function() State.GuiElements.ScreenGui:Destroy() end)
        print("Hx: Đã hủy ScreenGui.")
    end

    State.GuiElements = {
        ScreenGui = nil, MainFrame = nil, ScrollingFrame = nil, ContentListLayout = nil,
        GuiToggleButton = nil, TitleBarFrame = nil, TransparentToggle = nil, CircleIndicator = nil, TransparentTextButton = nil,
        MobileClickButton = nil, NotificationContainer = nil,
        ClickTargetMarker = nil, LockButton = nil,
        AntiAFK = { StatusLabel = nil, Toggle = nil },
        AutoClicker = { Toggle = nil, ModeGroup = nil, PlatformGroup = nil, CpsLocateFrame = nil, CPSBox = nil, LocateButton = nil, HotkeyButton = nil, MobileCreateButton = nil, MobileLockToggle = nil }
    }

    print("Hx: Dọn dẹp v2 hoàn tất.")
    _G.UnifiedAntiAFK_AutoClicker_CleanupFunction = nil
end
_G.UnifiedAntiAFK_AutoClicker_CleanupFunction = cleanup


--===== 🔔 Notification System =====--
local notificationTemplate = nil
local function createNotificationTemplate()
	if notificationTemplate then return notificationTemplate end
    local frame = Instance.new("Frame")
    frame.Name = "NotificationFrameTemplate"
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 1
    frame.BorderColor3 = Config.ColorBorder
    frame.Size = UDim2.new(0, Config.NotificationWidth, 0, Config.NotificationHeight)
    frame.ClipsDescendants = true

    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 8)
    local padding = Instance.new("UIPadding", frame)
    padding.PaddingLeft = UDim.new(0, 10); padding.PaddingRight = UDim.new(0, 10)
    padding.PaddingTop = UDim.new(0, 5); padding.PaddingBottom = UDim.new(0, 5)
    local layout = Instance.new("UIListLayout", frame)
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.VerticalAlignment = Enum.VerticalAlignment.Center
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 10)

    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"; icon.Image = Config.IconAntiAFK; icon.BackgroundTransparency = 1
    icon.ImageTransparency = 1; icon.Size = UDim2.new(0, 35, 0, 35); icon.LayoutOrder = 1
    icon.Parent = frame

    local textFrame = Instance.new("Frame")
    textFrame.Name = "TextFrame"; textFrame.BackgroundTransparency = 1
    textFrame.Size = UDim2.new(1, -55, 1, 0); textFrame.LayoutOrder = 2
    textFrame.Parent = frame
    local textLayout = Instance.new("UIListLayout", textFrame)
    textLayout.FillDirection = Enum.FillDirection.Vertical; textLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    textLayout.VerticalAlignment = Enum.VerticalAlignment.Center; textLayout.SortOrder = Enum.SortOrder.LayoutOrder
    textLayout.Padding = UDim.new(0, 2)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"; titleLabel.Text = "Tiêu đề"
    titleLabel.Font = Enum.Font.SourceSansBold
    titleLabel.TextSize = 17
    titleLabel.TextColor3 = Config.ColorTextPrimary; titleLabel.BackgroundTransparency = 1
    titleLabel.TextTransparency = 1; titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Size = UDim2.new(1, 0, 0, 20); titleLabel.LayoutOrder = 1
    titleLabel.Parent = textFrame

    local messageLabel = Instance.new("TextLabel")
    messageLabel.Name = "Message"; messageLabel.Text = "Nội dung tin nhắn."
    messageLabel.Font = Enum.Font.SourceSans
    messageLabel.TextSize = 14
    messageLabel.TextColor3 = Config.ColorTextSecondary; messageLabel.BackgroundTransparency = 1
    messageLabel.TextTransparency = 1; messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.TextWrapped = true; messageLabel.Size = UDim2.new(1, 0, 0.6, 0); messageLabel.LayoutOrder = 2
    messageLabel.Parent = textFrame

    notificationTemplate = frame
    return notificationTemplate
end
local function setupNotificationContainer(parentGui)
	if State.GuiElements.NotificationContainer and State.GuiElements.NotificationContainer.Parent then
        return State.GuiElements.NotificationContainer
    end
    local container = Instance.new("Frame")
    container.Name = "NotificationContainerFrame"
    container.AnchorPoint = Config.NotificationAnchor
    container.Position = Config.NotificationPosition
    container.Size = UDim2.new(0, Config.NotificationWidth + 20, 0, 300)
    container.BackgroundTransparency = 1
    container.Parent = parentGui
    local listLayout = Instance.new("UIListLayout", container)
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    listLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 5)
    State.GuiElements.NotificationContainer = container
    return container
end
local function showNotification(title, message, iconType)
	if not _G.UnifiedAntiAFK_AutoClicker_Running then return end
    pcall(function()
        local container = State.GuiElements.NotificationContainer
        if not container or not container.Parent then
            container = setupNotificationContainer(State.GuiElements.ScreenGui)
        end
        if not container then return end
        local template = notificationTemplate or createNotificationTemplate()
        if not template then return end
        local newNotification = template:Clone()
        if not newNotification then return end
        local icon = newNotification:FindFirstChild("Icon")
        local textFrame = newNotification:FindFirstChild("TextFrame")
        local titleLabel = textFrame and textFrame:FindFirstChild("Title")
        local messageLabel = textFrame and textFrame:FindFirstChild("Message")
        if not (icon and titleLabel and messageLabel) then
            newNotification:Destroy()
            return
        end
        titleLabel.Text = title or "Thông báo"
        messageLabel.Text = message or ""
        if iconType == "AFK" then icon.Image = Config.IconAntiAFK
        elseif iconType == "Clicker" then icon.Image = Config.IconAutoClicker
        else icon.Image = Config.IconAntiAFK end
        newNotification.Name = "Notification_" .. (title or "Default"):gsub("%s+", "")
        newNotification.Parent = container
        local fadeInGoals = { BackgroundTransparency = 0.1, ImageTransparency = 0, TextTransparency = 0 }
        local fadeOutGoals = { BackgroundTransparency = 1, ImageTransparency = 1, TextTransparency = 1 }
        TweenService:Create(newNotification, TWEEN_INFO_FAST, { BackgroundTransparency = fadeInGoals.BackgroundTransparency }):Play()
        TweenService:Create(icon, TWEEN_INFO_FAST, { ImageTransparency = fadeInGoals.ImageTransparency }):Play()
        TweenService:Create(titleLabel, TWEEN_INFO_FAST, { TextTransparency = fadeInGoals.TextTransparency }):Play()
        TweenService:Create(messageLabel, TWEEN_INFO_FAST, { TextTransparency = fadeInGoals.TextTransparency }):Play()
        task.delay(Config.NotificationDuration, function()
            if not newNotification or not newNotification.Parent then return end
            local bgTween = TweenService:Create(newNotification, TWEEN_INFO_FAST_IN, { BackgroundTransparency = fadeOutGoals.BackgroundTransparency })
            local iconTween = TweenService:Create(icon, TWEEN_INFO_FAST_IN, { ImageTransparency = fadeOutGoals.ImageTransparency })
            local titleTween = TweenService:Create(titleLabel, TWEEN_INFO_FAST_IN, { TextTransparency = fadeOutGoals.TextTransparency })
            local messageTween = TweenService:Create(messageLabel, TWEEN_INFO_FAST_IN, { TextTransparency = fadeOutGoals.TextTransparency })
            local connectionId = "NotificationCleanup_" .. newNotification.Name
            if State.Connections[connectionId] then State.Connections[connectionId]:Disconnect() end
            State.Connections[connectionId] = bgTween.Completed:Connect(function()
                if newNotification and newNotification.Parent then pcall(function() newNotification:Destroy() end) end
                if State.Connections[connectionId] then State.Connections[connectionId]:Disconnect(); State.Connections[connectionId] = nil end
            end)
            bgTween:Play(); iconTween:Play(); titleTween:Play(); messageTween:Play()
        end)
    end)
end


--===== 🛋️ Anti-AFK Functions =====--
local function isPositionOverScriptGui(position)
	if not State.GuiElements.ScreenGui then return false end
    local elementsToCheck = { State.GuiElements.MainFrame, State.GuiElements.GuiToggleButton, State.GuiElements.MobileClickButton, State.GuiElements.NotificationContainer }
    if State.ChoosingClickPos then
        table.insert(elementsToCheck, State.GuiElements.ClickTargetMarker)
        table.insert(elementsToCheck, State.GuiElements.LockButton)
    end
    for _, guiObject in ipairs(elementsToCheck) do
        if guiObject and guiObject:IsA("GuiObject") and guiObject.Visible and guiObject.AbsoluteSize.X > 0 then
            local objPos = guiObject.AbsolutePosition; local objSize = guiObject.AbsoluteSize
            if position.X >= objPos.X and position.X <= objPos.X + objSize.X and position.Y >= objPos.Y and position.Y <= objPos.Y + objSize.Y then return true end
        end
    end
    if State.GuiElements.NotificationContainer then
        for _, notification in ipairs(State.GuiElements.NotificationContainer:GetChildren()) do
            if notification:IsA("GuiObject") and notification.Visible and notification.AbsoluteSize.X > 0 then
                local notifPos = notification.AbsolutePosition; local notifSize = notification.AbsoluteSize
                if position.X >= notifPos.X and position.X <= notifPos.X + notifSize.X and position.Y >= notifPos.Y and position.Y <= notifPos.Y + notifSize.Y then return true end
            end
        end
    end
    return false
end
local function performAntiAFKAction()
	if not Config.EnableIntervention then return end
    local actionType = ""; local success, err = false, "Unknown error"; local guiElements = State.GuiElements
    if State.GuiVisible and guiElements.MainFrame and guiElements.MainFrame.Visible then
        actionType = "Nhảy (Space)"; print("Hx: Thực hiện hành động Anti-AFK ("..actionType..")...")
        success, err = pcall(function()
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game); task.wait(0.05 + math.random() * 0.03); VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        end)
    else
        actionType = "Click giữa màn hình"; print("Hx: Thực hiện hành động Anti-AFK ("..actionType..")...")
        local camera = Workspace.CurrentCamera; if not camera then warn("Hx: Không tìm thấy Camera..."); return end
        local viewportSize = camera.ViewportSize; local centerX = viewportSize.X / 2; local centerY = viewportSize.Y / 2
        success, err = pcall(function()
            VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 0); task.wait(0.05 + math.random() * 0.03); VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, false, game, 0)
        end)
    end
    if not success then warn("Hx: Lỗi khi can thiệp AFK ("..actionType.."):", err); showNotification("Lỗi Anti-AFK", "Không thể mô phỏng hành động ("..actionType..").", "AFK")
    else State.LastInterventionTime = os.clock(); State.InterventionCounter = State.InterventionCounter + 1; print("Hx: Đã thực hiện can thiệp AFK ("..actionType..") lần", State.InterventionCounter) end
end
local function onInputDetected()
	local now = os.clock()
    if State.IsConsideredAFK then
        State.IsConsideredAFK = false; State.LastInterventionTime = 0; State.InterventionCounter = 0
        showNotification("Bạn đã quay lại!", "Đã tạm dừng can thiệp AFK.", "AFK"); print("Hx: Người dùng không còn AFK.")
        if State.GuiElements.AntiAFK.StatusLabel then
            State.GuiElements.AntiAFK.StatusLabel.Text = "Trạng thái AFK: Bình thường"; State.GuiElements.AntiAFK.StatusLabel.TextColor3 = Color3.fromRGB(180, 255, 180)
        end
    end
    State.LastInputTime = now
end

--===== 🖱️ Auto Clicker Functions =====--
local function doAutoClick()
	local clickPos = State.SelectedClickPos
    while State.AutoClicking do
        local currentMousePos = UserInputService:GetMouseLocation()
        local clickPosOverGui = isPositionOverScriptGui(clickPos); local mousePosOverGui = isPositionOverScriptGui(currentMousePos)
        if not State.MobileButtonIsDragging and not clickPosOverGui and not mousePosOverGui then
            local success, err = pcall(function()
                if not State.AutoClicking then return end; VirtualInputManager:SendMouseButtonEvent(clickPos.X, clickPos.Y, 0, true, game, 0)
                if not State.AutoClicking then return end; task.wait(0.01)
                if not State.AutoClicking then return end; VirtualInputManager:SendMouseButtonEvent(clickPos.X, clickPos.Y, 0, false, game, 0)
            end)
            if not success then warn("Hx: Lỗi khi auto click:", err); showNotification("Lỗi Auto Click", "Không thể mô phỏng click. Tự động tắt.", "Clicker"); stopClick(); return end
        end
        if not State.AutoClicking then break end
        local delay = 1 / State.CurrentCPS; if delay <= 0.001 then delay = 0.001 end; task.wait(delay)
    end
    print("Hx: Vòng lặp Auto Click đã dừng."); autoClickCoroutine = nil
end
local function updateAutoClickToggleButtonState()
    local toggleButton = State.GuiElements.AutoClicker.Toggle
    if toggleButton and toggleButton.Parent then
        local isOn = State.AutoClicking
        local label = "Auto Click: " .. (isOn and "ON" or "OFF")
        local targetColor = isOn and Config.ColorToggleOn or Config.ColorToggleOff
        toggleButton.Text = label
        toggleButton.BackgroundColor3 = targetColor
    end
end
local function startClick()
	if State.AutoClicking then return end
    if State.ChoosingClickPos then showNotification("Auto Clicker", "Đang chọn vị trí, không thể bật.", "Clicker"); return end
    if State.IsBindingHotkey then showNotification("Auto Clicker", "Đang đặt hotkey, không thể bật.", "Clicker"); return end
    State.AutoClicking = true; updateAutoClickToggleButtonState()
    showNotification("Auto Clicker", string.format("Đã bật (%.0f CPS)", State.CurrentCPS), "Clicker"); print("Hx: Bắt đầu Auto Click.")
    if autoClickCoroutine and coroutine.status(autoClickCoroutine) ~= "dead" then warn("Hx: Cảnh báo - Coroutine Auto Click cũ chưa dừng hẳn! Status:", coroutine.status(autoClickCoroutine)) end
    autoClickCoroutine = task.spawn(doAutoClick)
end
local function stopClick()
	if not State.AutoClicking then return end
    State.AutoClicking = false; updateAutoClickToggleButtonState()
    showNotification("Auto Clicker", "Đã tắt.", "Clicker"); print("Hx: Đã yêu cầu dừng Auto Click.")
end
local function triggerAutoClick()
	if State.AutoClickMode == "Toggle" then if State.AutoClicking then stopClick() else startClick() end
    elseif State.AutoClickMode == "Hold" then if State.ClickTriggerActive and not State.AutoClicking then startClick() elseif not State.ClickTriggerActive and State.AutoClicking then stopClick() end end
end

local function endClickPositionChoice(cancelled)
    if not State.ChoosingClickPos then return end
    local connections = State.Connections
    local guiElements = State.GuiElements

    if connections.ConfirmClickPos then connections.ConfirmClickPos:Disconnect(); connections.ConfirmClickPos = nil end
    if connections.CancelClickPosKey then connections.CancelClickPosKey:Disconnect(); connections.CancelClickPosKey = nil end

    if guiElements.ClickTargetMarker and guiElements.ClickTargetMarker.Parent then pcall(function() guiElements.ClickTargetMarker:Destroy() end); guiElements.ClickTargetMarker = nil end
    if guiElements.LockButton and guiElements.LockButton.Parent then pcall(function() guiElements.LockButton:Destroy() end); guiElements.LockButton = nil end

    if guiElements.MainFrame then guiElements.MainFrame.Visible = State.GuiVisible end
    if guiElements.GuiToggleButton then guiElements.GuiToggleButton.Visible = true end

    State.ChoosingClickPos = false

    if cancelled then
        showNotification("Chọn vị trí", "Đã hủy chọn vị trí.", "Clicker")
        print("Hx: Đã hủy chọn vị trí.")
    else
        showNotification("Chọn vị trí", string.format("Đã khóa vị trí: (%.0f, %.0f)", State.SelectedClickPos.X, State.SelectedClickPos.Y), "Clicker")
        print("Hx: Đã chọn vị trí click mới:", State.SelectedClickPos)
    end
end

local function confirmClickPosition()
    if not State.ChoosingClickPos then return end
    local guiElements = State.GuiElements
    if not guiElements.ClickTargetMarker or not guiElements.ClickTargetMarker.Parent then
        warn("Hx: Không tìm thấy ClickTargetMarker để xác nhận vị trí.")
        endClickPositionChoice(true)
        return
    end

    local marker = guiElements.ClickTargetMarker
    local pos = marker.AbsolutePosition
    local size = marker.AbsoluteSize
    local centerX = pos.X + size.X / 2
    local centerY = pos.Y + size.Y / 2
    State.SelectedClickPos = Vector2.new(centerX, centerY)

    endClickPositionChoice(false)
end

local function cancelClickPositionChoice()
    if not State.ChoosingClickPos then return end
    endClickPositionChoice(true)
end

local function startChoosingClickPos()
	if State.ChoosingClickPos or State.IsBindingHotkey then return end; if State.AutoClicking then stopClick() end
    local guiElements = State.GuiElements; local connections = State.Connections

    State.ChoosingClickPos = true
    if guiElements.MainFrame then guiElements.MainFrame.Visible = false end
    if guiElements.GuiToggleButton then guiElements.GuiToggleButton.Visible = false end

    local marker = Instance.new("Frame")
    marker.Name = "ClickTargetMarker"
    marker.Size = UDim2.fromOffset(Config.ClickTargetMarkerSize, Config.ClickTargetMarkerSize)
    marker.Position = UDim2.new(0.5, 0, 0.5, 0)
    marker.AnchorPoint = Vector2.new(0.5, 0.5)
    marker.BackgroundColor3 = Config.ColorBorder
    marker.BackgroundTransparency = 0.5
    marker.BorderSizePixel = 1
    marker.BorderColor3 = Config.ColorClickTargetBorder
    marker.Active = true
    marker.Draggable = true
    marker.Parent = guiElements.ScreenGui
    marker.ZIndex = 20
    Instance.new("UICorner", marker).CornerRadius = UDim.new(0.5, 0)
    guiElements.ClickTargetMarker = marker

    local centerDot = Instance.new("Frame")
    centerDot.Name = "CenterDot"
    centerDot.Size = UDim2.fromOffset(Config.ClickTargetCenterDotSize, Config.ClickTargetCenterDotSize)
    centerDot.Position = UDim2.new(0.5, 0, 0.5, 0)
    centerDot.AnchorPoint = Vector2.new(0.5, 0.5)
    centerDot.BackgroundColor3 = Config.ColorClickTargetCenter
    centerDot.BorderSizePixel = 0
    centerDot.Parent = marker
    Instance.new("UICorner", centerDot).CornerRadius = UDim.new(0.5, 0)

    local topInset = GuiService:GetGuiInset().Y
    local lockButton = Instance.new("ImageButton")
    lockButton.Name = "LockButton"
    lockButton.Size = UDim2.fromOffset(Config.LockButtonSize, Config.LockButtonSize)
    lockButton.Position = UDim2.new(0.5, 0, 0, topInset + 15)
    lockButton.AnchorPoint = Vector2.new(0.5, 0)
    lockButton.Image = Config.IconLock
    lockButton.BackgroundColor3 = Config.ColorBackground
    lockButton.BackgroundTransparency = 0.5
    lockButton.BorderSizePixel = 1
    lockButton.BorderColor3 = Config.ColorBorder
    lockButton.Parent = guiElements.ScreenGui
    lockButton.ZIndex = 21
    Instance.new("UICorner", lockButton).CornerRadius = UDim.new(0, 6)
    guiElements.LockButton = lockButton

    if connections.ConfirmClickPos then connections.ConfirmClickPos:Disconnect() end
    connections.ConfirmClickPos = lockButton.MouseButton1Click:Connect(confirmClickPosition)

    if connections.CancelClickPosKey then connections.CancelClickPosKey:Disconnect() end
    connections.CancelClickPosKey = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        if not State.ChoosingClickPos or gameProcessedEvent then return end
        if input.KeyCode == Enum.KeyCode.Escape then
            cancelClickPositionChoice()
        end
    end)

    showNotification("Chọn vị trí", "Kéo hình tròn đến vị trí mong muốn, nhấn nút khóa (🔒) để xác nhận hoặc ESC để hủy.", "Clicker")
    print("Hx: Bắt đầu chọn vị trí click (Kéo & Khóa).")
end

local function startBindingHotkey()
	if State.IsBindingHotkey or State.ChoosingClickPos then return end; if State.AutoClicking then stopClick() end
    State.IsBindingHotkey = true
    local hotkeyButton = State.GuiElements.AutoClicker.HotkeyButton
    local originalText = hotkeyButton and hotkeyButton.Text or ""
    local originalColor = hotkeyButton and hotkeyButton.BackgroundColor3 or Config.ColorButtonPrimary
    if hotkeyButton then
        hotkeyButton.BackgroundColor3 = Color3.fromRGB(200, 150, 50)
        hotkeyButton.Text = "Nhấn phím..."
    end
    showNotification("Đặt Hotkey", "Nhấn phím bất kỳ (Esc để hủy).", "Clicker"); print("Hx: Bắt đầu đặt hotkey.")
    local connections = State.Connections; if connections.HotkeyBinding then connections.HotkeyBinding:Disconnect(); connections.HotkeyBinding = nil end
    local function endBinding(cancelled, newKey)
        if not State.IsBindingHotkey then return end
        if connections.HotkeyBinding then connections.HotkeyBinding:Disconnect(); connections.HotkeyBinding = nil end
        State.IsBindingHotkey = false
        if hotkeyButton then
            hotkeyButton.BackgroundColor3 = originalColor
        end
        if cancelled then
            if hotkeyButton then hotkeyButton.Text = originalText end
            showNotification("Đặt Hotkey", "Đã hủy đặt hotkey.", "Clicker"); print("Hx: Đã hủy đặt hotkey.")
        else
            if newKey then
                State.AutoClickHotkey = newKey
                if hotkeyButton then hotkeyButton.Text = "Hotkey: " .. newKey.Name end
                showNotification("Đặt Hotkey", "Đã đặt hotkey thành: " .. newKey.Name, "Clicker"); print("Hx: Hotkey được đặt thành:", newKey.Name)
                connectHotkeyListener()
            else
                if hotkeyButton then hotkeyButton.Text = originalText end
                warn("Hx: endBinding called without cancellation but no new key provided.")
            end
        end
    end
    connections.HotkeyBinding = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        if not State.IsBindingHotkey or gameProcessedEvent then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            if input.KeyCode == Enum.KeyCode.Escape then endBinding(true, nil)
            elseif input.KeyCode ~= Enum.KeyCode.Unknown then endBinding(false, input.KeyCode) end
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then showNotification("Đặt Hotkey", "Vui lòng nhấn một phím (không phải chuột).", "Clicker") end
    end)
end
local function connectHotkeyListener()
	local connections = State.Connections
    if connections.HotkeyInputBegan then connections.HotkeyInputBegan:Disconnect(); connections.HotkeyInputBegan = nil end
    if connections.HotkeyInputEnded then connections.HotkeyInputEnded:Disconnect(); connections.HotkeyInputEnded = nil end
    if State.Platform ~= "PC" or not State.AutoClickHotkey or State.AutoClickHotkey == Enum.KeyCode.Unknown then return end
    print("Hx: Đang kết nối trình nghe cho hotkey:", State.AutoClickHotkey.Name)
    connections.HotkeyInputBegan = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        if gameProcessedEvent or State.IsBindingHotkey or State.ChoosingClickPos or State.Platform ~= "PC" or input.KeyCode ~= State.AutoClickHotkey then return end
        if UserInputService:GetFocusedTextBox() then print("Hx: Hotkey bị bỏ qua do đang focus TextBox."); return end
        State.ClickTriggerActive = true; triggerAutoClick()
    end)
    connections.HotkeyInputEnded = UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
        if State.Platform ~= "PC" or input.KeyCode ~= State.AutoClickHotkey then return end
        State.ClickTriggerActive = false; if State.AutoClickMode == "Hold" then triggerAutoClick() end
    end)
end

local function connectMobileButtonListeners(mobileButton)
	local connections = State.Connections
    if connections.MobileButtonInputBegan then connections.MobileButtonInputBegan:Disconnect(); connections.MobileButtonInputBegan = nil end
    if connections.MobileButtonInputEnded then connections.MobileButtonInputEnded:Disconnect(); connections.MobileButtonInputEnded = nil end
    if connections.MobileButtonDragBegan then connections.MobileButtonDragBegan:Disconnect(); connections.MobileButtonDragBegan = nil end
    if connections.MobileButtonDragEnded then connections.MobileButtonDragEnded:Disconnect(); connections.MobileButtonDragEnded = nil end
    connections.MobileButtonInputBegan = mobileButton.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            task.wait(); if not State.MobileButtonIsDragging then State.ClickTriggerActive = true; triggerAutoClick() end
        end
    end)
    connections.MobileButtonInputEnded = mobileButton.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
            State.ClickTriggerActive = false; if State.AutoClickMode == "Hold" then triggerAutoClick() end
            if State.MobileButtonIsDragging then State.MobileButtonIsDragging = false; print("Hx: Kết thúc kéo nút Mobile (từ InputEnded).") end
        end
    end)
    connections.MobileButtonDragBegan = mobileButton.DragBegan:Connect(function()
        if not State.MobileButtonLocked then
            State.MobileButtonIsDragging = true
            mobileButton.BackgroundTransparency = 0.3
            if State.AutoClicking and State.AutoClickMode == "Hold" then stopClick() end
            print("Hx: Bắt đầu kéo nút Mobile.")
        else print("Hx: Nút Mobile bị khóa, không thể kéo.") end
    end)
    connections.MobileButtonDragEnded = mobileButton.DragStopped:Connect(function()
        if State.MobileButtonIsDragging then State.MobileButtonIsDragging = false; mobileButton.BackgroundTransparency = 0.4; print("Hx: Kết thúc kéo nút Mobile (từ DragStopped).") end
    end)
end

local function createOrShowMobileButton()
	local guiElements = State.GuiElements
    if guiElements.MobileClickButton and guiElements.MobileClickButton.Parent then
        guiElements.MobileClickButton.Visible = true
        guiElements.MobileClickButton.Draggable = not State.MobileButtonLocked
        print("Hx: Hiển thị lại nút Mobile đã có.")
        connectMobileButtonListeners(guiElements.MobileClickButton)
    else
        local screenGui = guiElements.ScreenGui; if not screenGui or not screenGui.Parent then warn("Hx: Không thể tạo nút Mobile vì ScreenGui không tồn tại."); return end
        local mobileButton = Instance.new("ImageButton")
        mobileButton.Name = "MobileClickButton"; mobileButton.Size = UDim2.fromOffset(Config.MobileButtonClickSize, Config.MobileButtonClickSize)
        mobileButton.Position = Config.MobileButtonDefaultPos; mobileButton.Image = Config.IconMobileClickButton
        mobileButton.BackgroundColor3 = Color3.fromRGB(255, 255, 255); mobileButton.BackgroundTransparency = 0.4
        mobileButton.Active = true; mobileButton.Draggable = not State.MobileButtonLocked
        mobileButton.Selectable = true; mobileButton.ZIndex = 15; mobileButton.Parent = screenGui
        local corner = Instance.new("UICorner", mobileButton); corner.CornerRadius = UDim.new(0.5, 0)
        guiElements.MobileClickButton = mobileButton; print("Hx: Đã tạo nút Mobile mới.")
        connectMobileButtonListeners(mobileButton)
    end
end

local function hideOrDestroyMobileButton()
	local guiElements = State.GuiElements; local connections = State.Connections
    if guiElements.MobileClickButton and guiElements.MobileClickButton.Parent then
        if connections.MobileButtonInputBegan then connections.MobileButtonInputBegan:Disconnect(); connections.MobileButtonInputBegan = nil end
        if connections.MobileButtonInputEnded then connections.MobileButtonInputEnded:Disconnect(); connections.MobileButtonInputEnded = nil end
        if connections.MobileButtonDragBegan then connections.MobileButtonDragBegan:Disconnect(); connections.MobileButtonDragBegan = nil end
        if connections.MobileButtonDragEnded then connections.MobileButtonDragEnded:Disconnect(); connections.MobileButtonDragEnded = nil end
        guiElements.MobileClickButton:Destroy(); guiElements.MobileClickButton = nil; print("Hx: Đã hủy nút Mobile.")
    end
end
local function updatePlatformUI()
	local isPC = (State.Platform == "PC"); local acElements = State.GuiElements.AutoClicker; local guiElements = State.GuiElements
    if acElements.HotkeyButton then acElements.HotkeyButton.Visible = isPC end
    if acElements.MobileCreateButton then acElements.MobileCreateButton.Visible = not isPC end
    if acElements.MobileLockToggle then acElements.MobileLockToggle.Visible = not isPC end
    if isPC then hideOrDestroyMobileButton(); connectHotkeyListener()
    else local connections = State.Connections
        if connections.HotkeyInputBegan then connections.HotkeyInputBegan:Disconnect(); connections.HotkeyInputBegan = nil end
        if connections.HotkeyInputEnded then connections.HotkeyInputEnded:Disconnect(); connections.HotkeyInputEnded = nil end
        if guiElements.MobileClickButton and guiElements.MobileClickButton.Parent then
            guiElements.MobileClickButton.Visible = true; guiElements.MobileClickButton.Draggable = not State.MobileButtonLocked
            connectMobileButtonListeners(guiElements.MobileClickButton)
        end
    end
    print("Hx: Cập nhật UI cho platform:", State.Platform)
end


--===== 🔧 UI Helper Functions =====--
local function createGuiElement(className, properties)
	local element = Instance.new(className); for prop, value in pairs(properties) do pcall(function() element[prop] = value end) end; return element
end

local function createToggle(name, label, order, parent, initialState, callback)
    local toggleButton = createGuiElement("TextButton", {
        Name = name, Size = UDim2.new(1, 0, 0, 30), Text = label .. (initialState and ": ON" or ": OFF"),
        Font = Enum.Font.SourceSansSemibold, TextSize = 15, TextColor3 = Config.ColorTextPrimary,
        BackgroundColor3 = initialState and Config.ColorToggleOn or Config.ColorToggleOff,
        LayoutOrder = order, Parent = parent, AutoButtonColor = false
    })
    createGuiElement("UICorner", { CornerRadius = UDim.new(0, 5), Parent = toggleButton })

    local connName = name .. "_Click"
    if State.Connections[connName] then State.Connections[connName]:Disconnect() end
    State.Connections[connName] = toggleButton.MouseButton1Click:Connect(function()
        if callback then
            local newState = callback()
            local newLabel = label .. (newState and ": ON" or ": OFF")
            local newColor = newState and Config.ColorToggleOn or Config.ColorToggleOff
            toggleButton.Text = newLabel
            toggleButton.BackgroundColor3 = newColor
        end
    end)
    return toggleButton
end

local function createRadioGroup(groupName, options, initialSelection, order, parent, callback)
    local frame = createGuiElement("Frame", { Name = groupName .. "GroupFrame", Size = UDim2.new(1, 0, 0, 30), BackgroundTransparency = 1, LayoutOrder = order, Parent = parent })
    local listLayout = createGuiElement("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8), Parent = frame })
    local buttons = {}; local currentSelection = initialSelection; local numOptions = #options
    local totalPadding = (numOptions - 1) * listLayout.Padding.Offset; local availableWidth = Config.GuiWidth - 20 - totalPadding; local buttonWidth = math.max(50, availableWidth / numOptions)

    local function updateButtonsVisuals()
        for option, button in pairs(buttons) do
            local isSelected = (option == currentSelection)
            local targetColor = isSelected and Config.ColorButtonPrimary or Config.ColorButtonSecondary
            local textColor = isSelected and Config.ColorTextPrimary or Config.ColorTextSecondary
            button.BackgroundColor3 = targetColor
            button.TextColor3 = textColor
        end
    end

    for i, optionName in ipairs(options) do
        local button = createGuiElement("TextButton", { Name = groupName .. optionName:gsub("%s+", ""), Size = UDim2.new(0, buttonWidth, 1, 0), Text = optionName, Font = Enum.Font.SourceSansSemibold, TextSize = 14, LayoutOrder = i, Parent = frame, AutoButtonColor = false })
        createGuiElement("UICorner", { CornerRadius = UDim.new(0, 5), Parent = button })
        buttons[optionName] = button

        local connName = button.Name .. "_Click"
        if State.Connections[connName] then State.Connections[connName]:Disconnect() end
        State.Connections[connName] = button.MouseButton1Click:Connect(function()
            if currentSelection ~= optionName then currentSelection = optionName; if callback then callback(currentSelection) end; updateButtonsVisuals() end
        end)
    end
    updateButtonsVisuals()
    return frame, buttons
end
local function updateCPSPlaceholder()
	local cpsBox = State.GuiElements.AutoClicker.CPSBox
    if cpsBox then if cpsBox:IsFocused() then cpsBox.PlaceholderText = "Nhập CPS..." else cpsBox.PlaceholderText = string.format("CPS: %d", State.CurrentCPS) end end
end


--===== 🎨 GUI Creation =====--
local function createGUI()
    local oldGui = CoreGui:FindFirstChild("Hx_v2_GUI"); if oldGui then pcall(cleanup); print("Hx: Đã hủy GUI cũ và dọn dẹp trước khi tạo mới.") end
    local guiElements = State.GuiElements; local connections = State.Connections
    local screenGui = createGuiElement("ScreenGui", { Name = "Hx_v2_GUI", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, DisplayOrder = 1003, IgnoreGuiInset = true, Parent = CoreGui }); guiElements.ScreenGui = screenGui
    setupNotificationContainer(screenGui); createNotificationTemplate()
    local topInset = GuiService:GetGuiInset().Y
    local guiToggleButton = createGuiElement("ImageButton", { Name = "GuiToggleButton", Size = UDim2.fromOffset(Config.ToggleButtonSize, Config.ToggleButtonSize), Position = UDim2.new(0.5, 0, 0, topInset + 15), AnchorPoint = Vector2.new(0.5, 0), Image = Config.IconToggleButton, BackgroundColor3 = Config.ColorBackground, BackgroundTransparency = 0.2, BorderSizePixel = 1, BorderColor3 = Config.ColorBorder, Active = true, Draggable = true, Selectable = true, Parent = screenGui, ZIndex = 10 })
    createGuiElement("UICorner", { CornerRadius = UDim.new(0, 6), Parent = guiToggleButton }); guiElements.GuiToggleButton = guiToggleButton
    local mainFrame = createGuiElement("Frame", { Name = "MainFrame", Size = UDim2.fromOffset(Config.GuiWidth, Config.GuiHeight), Position = UDim2.new(0.5, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundColor3 = Config.ColorBackground, BackgroundTransparency = State.IsTransparent and Config.TransparentBGLevel or Config.OpaqueBGLevel, BorderColor3 = Config.ColorBorder, BorderSizePixel = 1, Active = true, Draggable = true, ClipsDescendants = true, Visible = State.GuiVisible, Parent = screenGui, ZIndex = 5 })
    createGuiElement("UICorner", { CornerRadius = UDim.new(0, 8), Parent = mainFrame }); guiElements.MainFrame = mainFrame
    local titleBarFrame = createGuiElement("Frame", { Name = "TitleBarFrame", Size = UDim2.new(1, -20, 0, 35), Position = UDim2.new(0, 10, 0, 5), BackgroundTransparency = 1, Parent = mainFrame, }); guiElements.TitleBarFrame = titleBarFrame
    local titleBarLayout = createGuiElement("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 10) }); titleBarLayout.Parent = titleBarFrame
    local titleLabel = createGuiElement("TextLabel", { Name = "Title", Size = UDim2.new(1, -(Config.TransparentToggleWidth + titleBarLayout.Padding.Offset), 1, 0), Text = Config.GuiTitle, Font = Enum.Font.SourceSansBold, TextSize = 20, TextColor3 = Config.ColorTextPrimary, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Left, LayoutOrder = 1, Parent = titleBarFrame })
    local transparentToggle = createGuiElement("Frame", { Name = "TransparentToggle", Size = UDim2.new(0, Config.TransparentToggleWidth, 1, 0), BackgroundTransparency = 1, LayoutOrder = 2, Parent = titleBarFrame, }); guiElements.TransparentToggle = transparentToggle
    local transparentLayout = createGuiElement("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, SortOrder = Enum.SortOrder.LayoutOrder, VerticalAlignment = Enum.VerticalAlignment.Center, HorizontalAlignment = Enum.HorizontalAlignment.Right, Padding = UDim.new(0, 5), Parent = transparentToggle })
    local transparentTextButton = createGuiElement("TextButton", { Name = "TransparentTextButton", Size = UDim2.new(0, 85, 1, 0), Text = "Transparent", Font = Enum.Font.SourceSans, TextSize = 15, TextColor3 = Config.ColorTextSecondary, BackgroundTransparency = 1, TextXAlignment = Enum.TextXAlignment.Right, LayoutOrder = 1, Parent = transparentToggle, AutoButtonColor = false, Active = true, Selectable = true }); guiElements.TransparentTextButton = transparentTextButton
    local circleIndicator = createGuiElement("Frame", { Name = "CircleIndicator", Size = UDim2.fromOffset(16, 16), BackgroundColor3 = Config.ColorToggleOn, BackgroundTransparency = State.IsTransparent and 0 or 1, LayoutOrder = 2, Parent = transparentToggle })
    createGuiElement("UICorner", {CornerRadius = UDim.new(0.5, 0)}).Parent = circleIndicator; createGuiElement("UIStroke", { Thickness = 1.5, Color = Config.ColorToggleCircleBorder, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }).Parent = circleIndicator; guiElements.CircleIndicator = circleIndicator
    local scrollingFrame = createGuiElement("ScrollingFrame", { Name = "ScrollingFrame", Size = UDim2.new(1, 0, 1, -(titleBarFrame.AbsoluteSize.Y + 10)), Position = UDim2.new(0, 0, 0, titleBarFrame.AbsoluteSize.Y + 5), BackgroundTransparency = 1, BorderSizePixel = 0, CanvasSize = UDim2.new(0, 0, 0, 0), ScrollBarImageColor3 = Config.ColorScrollbar, ScrollBarThickness = Config.ScrollbarThickness, ScrollingDirection = Enum.ScrollingDirection.Y, Parent = mainFrame }); guiElements.ScrollingFrame = scrollingFrame
    local contentListLayout = createGuiElement("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, HorizontalAlignment = Enum.HorizontalAlignment.Center, FillDirection = Enum.FillDirection.Vertical, Parent = scrollingFrame }); guiElements.ContentListLayout = contentListLayout
    createGuiElement("UIPadding", { PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 10), PaddingRight = UDim.new(0, 10), Parent = scrollingFrame })
    local contentSizeConnName = "ContentSizeChanged"; if connections[contentSizeConnName] then connections[contentSizeConnName]:Disconnect() end
    connections[contentSizeConnName] = contentListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, contentListLayout.AbsoluteContentSize.Y + 5) end)
    local contentParent = scrollingFrame; local layoutOrder = 0
    layoutOrder=layoutOrder+1; createGuiElement("TextLabel",{Name="AntiAFKSectionHeader",Size=UDim2.new(1,0,0,22),Text="───═══[ 🛋️ Anti-AFK 🛋️ ]═══───",Font=Enum.Font.SourceSansBold,TextSize=17,TextColor3=Config.ColorSectionHeader,BackgroundTransparency=1,LayoutOrder=layoutOrder,Parent=contentParent})
    layoutOrder=layoutOrder+1; local afkStatusLabel=createGuiElement("TextLabel",{Name="AntiAFKStatus",Size=UDim2.new(1,0,0,20),Text="Trạng thái AFK: Bình thường",Font=Enum.Font.SourceSans,TextSize=14,TextColor3=Color3.fromRGB(180,255,180),BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=layoutOrder,Parent=contentParent});guiElements.AntiAFK.StatusLabel=afkStatusLabel
    layoutOrder=layoutOrder+1; local afkInterventionToggle=createToggle("AntiAFKToggle","Can thiệp AFK",layoutOrder,contentParent,Config.EnableIntervention,function() Config.EnableIntervention=not Config.EnableIntervention; local status=Config.EnableIntervention and"BẬT"or"TẮT"; showNotification("Anti-AFK","Can thiệp tự động đã "..status,"AFK"); print("Hx: Can thiệp AFK được đặt thành:",Config.EnableIntervention); return Config.EnableIntervention end); guiElements.AntiAFK.Toggle=afkInterventionToggle
    layoutOrder=layoutOrder+1; createGuiElement("TextLabel",{Name="AutoClickerSectionHeader",Size=UDim2.new(1,0,0,22),Text="───═══[ 🖱️ Auto Clicker 🖱️ ]═══───",Font=Enum.Font.SourceSansBold,TextSize=17,TextColor3=Config.ColorSectionHeader,BackgroundTransparency=1,LayoutOrder=layoutOrder,Parent=contentParent})
    layoutOrder=layoutOrder+1; local autoClickToggle=createToggle("AutoClickToggle","Auto Click",layoutOrder,contentParent,State.AutoClicking,function() triggerAutoClick(); return State.AutoClicking end); guiElements.AutoClicker.Toggle=autoClickToggle
    layoutOrder=layoutOrder+1; createGuiElement("TextLabel",{Name="ModeLabel",Size=UDim2.new(1,0,0,18),Text="Chế độ Click:",Font=Enum.Font.SourceSans,TextSize=13,TextColor3=Config.ColorTextSecondary,BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=layoutOrder,Parent=contentParent})
    layoutOrder=layoutOrder+1; local modeGroup,_ = createRadioGroup("ClickMode",{"Toggle","Hold"},State.AutoClickMode,layoutOrder,contentParent,function(newMode) State.AutoClickMode=newMode; print("Hx: Chế độ click đổi thành:",newMode); if State.AutoClicking and newMode=="Hold"then stopClick() end; updateAutoClickToggleButtonState() end); guiElements.AutoClicker.ModeGroup=modeGroup
    layoutOrder=layoutOrder+1; createGuiElement("TextLabel",{Name="PlatformLabel",Size=UDim2.new(1,0,0,18),Text="Nền tảng:",Font=Enum.Font.SourceSans,TextSize=13,TextColor3=Config.ColorTextSecondary,BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=layoutOrder,Parent=contentParent})
    layoutOrder=layoutOrder+1; local platformGroup,_ = createRadioGroup("Platform",{"PC","Mobile"},State.Platform,layoutOrder,contentParent,function(newPlatform) if State.Platform~=newPlatform then State.Platform=newPlatform; print("Hx: Nền tảng đổi thành:",newPlatform); updatePlatformUI() end end); guiElements.AutoClicker.PlatformGroup=platformGroup
    layoutOrder=layoutOrder+1
    local hotkeyButton=createGuiElement("TextButton",{Name="HotkeyButton",Size=UDim2.new(1,0,0,32),Text="Hotkey: "..State.AutoClickHotkey.Name,Font=Enum.Font.SourceSansBold,TextSize=15,TextColor3=Config.ColorTextPrimary,BackgroundColor3=Config.ColorButtonPrimary,LayoutOrder=layoutOrder,Visible=(State.Platform=="PC"),Parent=contentParent}); createGuiElement("UICorner",{CornerRadius=UDim.new(0,5),Parent=hotkeyButton}); guiElements.AutoClicker.HotkeyButton=hotkeyButton; connections.HotkeyButtonClick=hotkeyButton.MouseButton1Click:Connect(startBindingHotkey)
    local mobileCreateButton=createGuiElement("TextButton",{Name="MobileButtonCreateButton",Size=UDim2.new(1,0,0,32),Text="Tạo/Hiện nút nhấn Mobile",Font=Enum.Font.SourceSansBold,TextSize=15,TextColor3=Config.ColorTextPrimary,BackgroundColor3=Config.ColorButtonPrimary,LayoutOrder=layoutOrder,Visible=(State.Platform=="Mobile"),Parent=contentParent}); createGuiElement("UICorner",{CornerRadius=UDim.new(0,5),Parent=mobileCreateButton}); guiElements.AutoClicker.MobileCreateButton=mobileCreateButton; connections.MobileCreateClick=mobileCreateButton.MouseButton1Click:Connect(createOrShowMobileButton)
    layoutOrder=layoutOrder+1; local mobileLockToggle=createToggle("MobileButtonLockToggle","Khóa vị trí nút",layoutOrder,contentParent,State.MobileButtonLocked,function() State.MobileButtonLocked=not State.MobileButtonLocked; if guiElements.MobileClickButton then guiElements.MobileClickButton.Draggable=not State.MobileButtonLocked end; showNotification("Nút Mobile",State.MobileButtonLocked and"Đã khóa vị trí."or"Đã mở khóa vị trí.","Clicker"); print("Hx: Khóa vị trí nút Mobile:",State.MobileButtonLocked); return State.MobileButtonLocked end); mobileLockToggle.Visible=(State.Platform=="Mobile"); guiElements.AutoClicker.MobileLockToggle=mobileLockToggle
    layoutOrder = layoutOrder + 1
    local cpsLocateFrame = createGuiElement("Frame", { Name = "CpsLocateFrame", Size = UDim2.new(1, 0, 0, 35), BackgroundTransparency = 1, LayoutOrder = layoutOrder, Parent = contentParent }); guiElements.AutoClicker.CpsLocateFrame = cpsLocateFrame
    local cpsLocateLayout = createGuiElement("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, VerticalAlignment = Enum.VerticalAlignment.Center, HorizontalAlignment = Enum.HorizontalAlignment.Left, SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8), Parent = cpsLocateFrame })
    local cpsBox = createGuiElement("TextBox", { Name = "CPSBox", Size = UDim2.new(0, Config.CPSBoxWidth, 1, 0), Text = "", Font = Enum.Font.SourceSans, TextSize = 15, TextColor3 = Config.ColorTextPrimary, BackgroundColor3 = Config.ColorInputBackground, PlaceholderColor3 = Config.ColorTextSecondary, ClearTextOnFocus = true, TextXAlignment = Enum.TextXAlignment.Center, LayoutOrder = 1, Parent = cpsLocateFrame })
    createGuiElement("UICorner", { CornerRadius = UDim.new(0, 5), Parent = cpsBox }); guiElements.AutoClicker.CPSBox = cpsBox; updateCPSPlaceholder()
    local locateButton = createGuiElement("TextButton", { Name = "LocateButton", Size = UDim2.new(1, -(Config.CPSBoxWidth + cpsLocateLayout.Padding.Offset), 1, 0), Text = "Chọn vị trí", Font = Enum.Font.SourceSansBold, TextSize = 15, TextColor3 = Config.ColorTextPrimary, BackgroundColor3 = Config.ColorButtonPrimary, LayoutOrder = 2, Parent = cpsLocateFrame })
    createGuiElement("UICorner", { CornerRadius = UDim.new(0, 5), Parent = locateButton }); guiElements.AutoClicker.LocateButton = locateButton; connections.LocateButtonClick = locateButton.MouseButton1Click:Connect(startChoosingClickPos) -- Connects to the new function
    layoutOrder = layoutOrder + 1
    local bottomPaddingFrame = createGuiElement("Frame", { Name = "BottomPaddingFrame", Size = UDim2.new(1, 0, 0, 10), BackgroundTransparency = 1, BorderSizePixel = 0, LayoutOrder = layoutOrder, Parent = contentParent })

    local function validateAndSetCPS(inputText, source)
        local number = tonumber(inputText); if number then number = math.floor(math.clamp(number, Config.MinCPS, Config.MaxCPS) + 0.5); if State.CurrentCPS ~= number then State.CurrentCPS = number; print("Hx: CPS được đặt thành:", State.CurrentCPS, "từ", source); if source == "TextBox" then showNotification("Auto Clicker", string.format("Đã đặt CPS thành %d", State.CurrentCPS), "Clicker") end; updateCPSPlaceholder() end; return true, number
        else if source == "TextBox" and inputText ~= "" then showNotification("Lỗi CPS", "Vui lòng nhập một số hợp lệ.", "Clicker") end; updateCPSPlaceholder(); return false, nil end
    end
    local cpsBoxFocusLostConnName = "CPSBoxFocusLost"; if connections[cpsBoxFocusLostConnName] then connections[cpsBoxFocusLostConnName]:Disconnect() end
    connections[cpsBoxFocusLostConnName] = cpsBox.FocusLost:Connect(function(enterPressed) local text = cpsBox.Text; if text ~= "" then validateAndSetCPS(text, "TextBox") end; cpsBox.Text = ""; updateCPSPlaceholder(); if enterPressed then cpsBox:ReleaseFocus() end end)
    local cpsBoxFocusedConnName = "CPSBoxFocused"; if connections[cpsBoxFocusedConnName] then connections[cpsBoxFocusedConnName]:Disconnect() end
    connections[cpsBoxFocusedConnName] = cpsBox.Focused:Connect(function() updateCPSPlaceholder() end)
    local transTextBtnClickConnName = "TransparentTextButtonClick"; if connections[transTextBtnClickConnName] then connections[transTextBtnClickConnName]:Disconnect() end
    connections[transTextBtnClickConnName] = transparentTextButton.MouseButton1Click:Connect(function()
        State.IsTransparent = not State.IsTransparent; local circle = guiElements.CircleIndicator
        if circle then TweenService:Create(circle, TWEEN_INFO_FAST, { BackgroundTransparency = State.IsTransparent and 0 or 1 }):Play() else warn("Hx: Không tìm thấy CircleIndicator!") end
        local targetBgTrans = State.IsTransparent and Config.TransparentBGLevel or Config.OpaqueBGLevel; TweenService:Create(mainFrame, TWEEN_INFO_FAST, { BackgroundTransparency = targetBgTrans }):Play()
        print("Hx: Chế độ trong suốt:", State.IsTransparent)
    end)
    local guiToggleBtnClickConnName = "GuiToggleButtonClick"; if connections[guiToggleBtnClickConnName] then connections[guiToggleBtnClickConnName]:Disconnect() end
    connections[guiToggleBtnClickConnName] = guiToggleButton.MouseButton1Click:Connect(function()
        State.GuiVisible = not State.GuiVisible; mainFrame.Visible = State.GuiVisible; print("Hx: GUI visibility toggled to", State.GuiVisible)
        if not State.GuiVisible then if State.ChoosingClickPos then cancelClickPositionChoice() end; if State.IsBindingHotkey then print("Hx: GUI ẩn khi đang đặt hotkey.") end end -- Cancel choosing pos if GUI is hidden
    end)
    connectHotkeyListener(); updatePlatformUI(); task.wait(0.1); if contentListLayout and scrollingFrame then contentListLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Fire() end
    print("Hx: GUI v2 (Updated Click Chooser) đã được tạo và kết nối sự kiện.")
end

--===== 🔄 Initialization & Main Loop =====--
local function initialize()
    pcall(createGUI)
    if not State.GuiElements.ScreenGui then warn("Hx: Không thể tạo GUI, script sẽ không hoạt động đúng."); cleanup(); _G.UnifiedAntiAFK_AutoClicker_Running = false; return end
    local connections = State.Connections
    local globalInputBeganConnName = "GlobalInputBegan"; if connections[globalInputBeganConnName] then connections[globalInputBeganConnName]:Disconnect() end
    connections[globalInputBeganConnName] = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        if gameProcessedEvent or State.IsBindingHotkey or State.ChoosingClickPos then return end -- Ignore input if choosing position (except ESC handled elsewhere)
        if State.Platform=="PC" and input.UserInputType==Enum.UserInputType.Keyboard and input.KeyCode==State.AutoClickHotkey then return end
        if UserInputService:GetFocusedTextBox() then return end
        if input.UserInputType==Enum.UserInputType.Keyboard or input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.MouseButton2 or input.UserInputType==Enum.UserInputType.Touch then onInputDetected() end
    end)
    local globalInputChangedConnName = "GlobalInputChanged"; if connections[globalInputChangedConnName] then connections[globalInputChangedConnName]:Disconnect() end
    connections[globalInputChangedConnName] = UserInputService.InputChanged:Connect(function(input, gameProcessedEvent)
        if gameProcessedEvent or State.IsBindingHotkey or State.ChoosingClickPos then return end
        if input.UserInputType==Enum.UserInputType.MouseMovement or input.UserInputType==Enum.UserInputType.MouseWheel or input.UserInputType==Enum.UserInputType.Gamepad1 or input.UserInputType==Enum.UserInputType.Gamepad2 or input.UserInputType==Enum.UserInputType.Gamepad3 or input.UserInputType==Enum.UserInputType.Gamepad4 or input.UserInputType==Enum.UserInputType.Gamepad5 or input.UserInputType==Enum.UserInputType.Gamepad6 or input.UserInputType==Enum.UserInputType.Gamepad7 or input.UserInputType==Enum.UserInputType.Gamepad8 then onInputDetected() end
    end)
    if player then
        local charRemovingConnName = "CharacterRemoving"; if connections[charRemovingConnName] then connections[charRemovingConnName]:Disconnect() end
        connections[charRemovingConnName] = player.CharacterRemoving:Connect(function(character) print("Hx: Nhân vật đang bị xóa. Script vẫn chạy.") end)
    end
    local playerRemovingConnName = "PlayerRemoving"; if connections[playerRemovingConnName] then connections[playerRemovingConnName]:Disconnect() end
    connections[playerRemovingConnName] = Players.PlayerRemoving:Connect(function(removedPlayer) if removedPlayer == player then print("Hx: Người chơi rời đi, dọn dẹp script."); cleanup() end end)
    task.wait(1); showNotification(Config.GuiTitle, "Đã kích hoạt!", "AFK"); print("Hx: Script v2 (Updated Click Chooser) đã khởi chạy thành công.")
    while _G.UnifiedAntiAFK_AutoClicker_Running do
        local currentTime = os.clock(); local timeSinceLastInput = currentTime - State.LastInputTime
        if Config.EnableIntervention then
            if State.IsConsideredAFK then
                local timeSinceLastIntervention = currentTime - State.LastInterventionTime; local timeSinceLastCheck = currentTime - State.LastCheckTime
                if timeSinceLastIntervention >= Config.InterventionInterval then performAntiAFKAction(); State.LastCheckTime = currentTime
                elseif timeSinceLastCheck >= Config.CheckInterval then local timeToNextIntervention = math.max(0, Config.InterventionInterval - timeSinceLastIntervention); local message = string.format("Can thiệp tiếp theo sau ~%.0f giây.", timeToNextIntervention); showNotification("Vẫn đang AFK...", message, "AFK"); State.LastCheckTime = currentTime end
            else
                if timeSinceLastInput >= Config.AfkThreshold then
                    State.IsConsideredAFK = true; State.LastInterventionTime = currentTime; State.LastCheckTime = currentTime; State.InterventionCounter = 0
                    local message = string.format("Sẽ can thiệp sau ~%.0f giây.", Config.InterventionInterval); showNotification("Cảnh báo AFK!", message, "AFK"); print("Hx: Người dùng được coi là AFK.")
                    if State.GuiElements.AntiAFK.StatusLabel then State.GuiElements.AntiAFK.StatusLabel.Text = "Trạng thái AFK: Đang AFK"; State.GuiElements.AntiAFK.StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 80) end
                end
            end
        else
            if State.IsConsideredAFK then
                State.IsConsideredAFK = false; showNotification("Anti-AFK Tắt", "Can thiệp AFK đã bị tắt trong cài đặt.", "AFK"); print("Hx: Can thiệp AFK tắt, reset trạng thái AFK.")
                if State.GuiElements.AntiAFK.StatusLabel then State.GuiElements.AntiAFK.StatusLabel.Text = "Trạng thái AFK: Bình thường (Đã tắt)"; State.GuiElements.AntiAFK.StatusLabel.TextColor3 = Color3.fromRGB(180, 255, 180) end
            end
        end
        task.wait(1)
    end
    print("Hx: Vòng lặp chính đã kết thúc.")
end

--===== ▶️ Script Execution =====--
task.spawn(function()
    local success, err = pcall(initialize)
    if not success then warn("Hx Lỗi Khởi Tạo Nghiêm Trọng v2:", err); if err then warn(debug.traceback()) end; pcall(cleanup); _G.UnifiedAntiAFK_AutoClicker_Running = false end
end)
