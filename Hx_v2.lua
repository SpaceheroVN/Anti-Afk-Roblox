--[[
    Script Kết Hợp: Anti-AFK Nâng Cao & Auto Clicker với GUI Thống Nhất
    Người tạo gốc: Script 1 & Script 2
    Người kết hợp & nâng cấp: Gemini AI
    Ngày: 2025-04-24
]]

-- // ============================ CLEANUP SCRIPT CŨ ============================ //
if _G.UnifiedAntiAFK_AutoClicker_Running then
    if _G.UnifiedAntiAFK_AutoClicker_CleanupFunction then
        pcall(_G.UnifiedAntiAFK_AutoClicker_CleanupFunction) -- Gọi hàm dọn dẹp của instance cũ
        warn("UnifiedAFK+Clicker: Đã dừng và dọn dẹp instance cũ.")
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

local player = Players.LocalPlayer
if not player then
    warn("UnifiedAFK+Clicker: Không tìm thấy LocalPlayer! Script sẽ không hoạt động.")
    _G.UnifiedAntiAFK_AutoClicker_Running = false
    return -- Thoát sớm nếu không có người chơi cục bộ
end
local mouse = player:GetMouse()

-- // ============================ CẤU HÌNH ============================ //
local Config = {
    -- Anti-AFK
    AfkThreshold = 180,           -- Thời gian (giây) không hoạt động để coi là AFK
    InterventionInterval = 300,   -- Thời gian (giây) giữa các lần can thiệp khi đang AFK
    CheckInterval = 60,          -- Thời gian (giây) kiểm tra và hiển thị thông báo khi AFK
    EnableIntervention = true,   -- Bật/tắt can thiệp tự động (có thể thay đổi qua GUI)
    SimulatedKeyCode = Enum.KeyCode.Space, -- Phím được mô phỏng để chống AFK

    -- Auto Clicker
    DefaultCPS = 20,             -- Clicks Per Second mặc định
    MinCPS = 1,
    MaxCPS = 50,
    DefaultClickPos = Vector2.new(mouse.X, mouse.Y), -- Vị trí click mặc định (vị trí chuột hiện tại khi script chạy)

    -- GUI & Thông báo
    GuiTitle = "Tiện ích AFK & Clicker",
    NotificationDuration = 5,    -- Thời gian hiển thị thông báo (giây)
    AnimationTime = 0.4,         -- Thời gian hiệu ứng animation (giây)
    IconAntiAFK = "rbxassetid://11711851578", -- Thay bằng ID icon phù hợp
    IconAutoClicker = "rbxassetid://6031067954", -- Thay bằng ID icon phù hợp
    IconFinger = "rbxassetid://16063312452",   -- Icon ngón tay khi chọn vị trí
    GuiWidth = 280,
    GuiHeight = 280,             -- Chiều cao GUI (có thể điều chỉnh tùy vào số lượng control)
    NotificationWidth = 250,
    NotificationHeight = 60,
    NotificationAnchor = Vector2.new(1, 1), -- Vị trí góc neo của container thông báo
    NotificationPosition = UDim2.new(1, -18, 1, -48) -- Vị trí container thông báo
}

-- // ============================ BIẾN TRẠNG THÁI ============================ //
local State = {
    IsConsideredAFK = false,
    AutoClicking = false,
    ChoosingClickPos = false,
    GuiVisible = true,
    LastInputTime = os.clock(),
    LastInterventionTime = 0,
    LastCheckTime = 0,
    InterventionCounter = 0,
    CurrentCPS = Config.DefaultCPS,
    SelectedClickPos = Config.DefaultClickPos,
    Connections = {}, -- Lưu trữ tất cả các kết nối sự kiện để dọn dẹp
    GuiElements = {} -- Lưu trữ các phần tử GUI chính để dọn dẹp
}

local autoClickCoroutine = nil

-- // ============================ HÀM DỌN DẸP ============================ //
local function cleanup()
    print("UnifiedAFK+Clicker: Bắt đầu dọn dẹp...")

    -- Ngừng Auto Clicker nếu đang chạy
    if State.AutoClicking then
        State.AutoClicking = false -- Dừng vòng lặp trong coroutine
        if autoClickCoroutine and coroutine.status(autoClickCoroutine) ~= "dead" then
            -- Không thể trực tiếp "kill" coroutine, đặt cờ AutoClicking = false là đủ
             print("UnifiedAFK+Clicker: Đã yêu cầu dừng Auto Clicker.")
        end
        autoClickCoroutine = nil
    end

    -- Ngắt kết nối tất cả các sự kiện đã lưu
    for name, connection in pairs(State.Connections) do
        if connection then
            connection:Disconnect()
            print("UnifiedAFK+Clicker: Đã ngắt kết nối '" .. name .. "'")
        end
        State.Connections[name] = nil
    end

    -- Hủy các phần tử GUI đã tạo
    if State.GuiElements.ScreenGui and State.GuiElements.ScreenGui.Parent then
        State.GuiElements.ScreenGui:Destroy()
        print("UnifiedAFK+Clicker: Đã hủy ScreenGui.")
    end
    State.GuiElements = {} -- Xóa bảng tham chiếu

    -- Reset trạng thái (tùy chọn, nhưng tốt cho việc dọn dẹp hoàn toàn)
    State.IsConsideredAFK = false
    State.ChoosingClickPos = false
    State.LastInputTime = os.clock()
    -- ... các trạng thái khác nếu cần

    print("UnifiedAFK+Clicker: Dọn dẹp hoàn tất.")
    _G.UnifiedAntiAFK_AutoClicker_Running = false -- Đánh dấu script này không còn chạy
    _G.UnifiedAntiAFK_AutoClicker_CleanupFunction = nil -- Xóa tham chiếu đến chính nó
end
_G.UnifiedAntiAFK_AutoClicker_CleanupFunction = cleanup -- Lưu hàm dọn dẹp vào global để instance mới có thể gọi

-- // ============================ HỆ THỐNG THÔNG BÁO (Từ Script 1, đã điều chỉnh) ============================ //
local notificationContainer = nil
local notificationTemplate = nil

local function createNotificationTemplate()
    if notificationTemplate then return notificationTemplate end

    local frame = Instance.new("Frame")
    frame.Name = "NotificationFrameTemplate"
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BackgroundTransparency = 1 -- Bắt đầu trong suốt
    frame.BorderSizePixel = 0
    frame.Size = UDim2.new(0, Config.NotificationWidth, 0, Config.NotificationHeight)
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
    icon.Image = Config.IconAntiAFK -- Icon mặc định, sẽ thay đổi nếu cần
    icon.BackgroundTransparency = 1
    icon.ImageTransparency = 1 -- Bắt đầu trong suốt
    icon.Size = UDim2.new(0, 40, 0, 40)
    icon.LayoutOrder = 1
    icon.Parent = frame

    local textFrame = Instance.new("Frame")
    textFrame.Name = "TextFrame"
    textFrame.BackgroundTransparency = 1
    textFrame.Size = UDim2.new(1, -60, 1, 0) -- Chiếm phần còn lại trừ icon và padding
    textFrame.LayoutOrder = 2
    textFrame.Parent = frame

    local textListLayout = Instance.new("UIListLayout", textFrame)
    textListLayout.FillDirection = Enum.FillDirection.Vertical -- Title trên Message dưới
    textListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    textListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    textListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    textListLayout.Padding = UDim.new(0, 2)

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Text = "Tiêu đề"
    title.Font = Enum.Font.GothamBold
    title.TextSize = 15
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
    title.BackgroundTransparency = 1
    title.TextTransparency = 1 -- Bắt đầu trong suốt
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Size = UDim2.new(1, 0, 0, 18) -- Kích thước cố định chiều cao
    title.LayoutOrder = 1
    title.Parent = textFrame

    local message = Instance.new("TextLabel")
    message.Name = "Message"
    message.Text = "Nội dung tin nhắn."
    message.Font = Enum.Font.Gotham
    message.TextSize = 13
    message.TextColor3 = Color3.fromRGB(200, 200, 200)
    message.BackgroundTransparency = 1
    message.TextTransparency = 1 -- Bắt đầu trong suốt
    message.TextXAlignment = Enum.TextXAlignment.Left
    message.TextWrapped = true -- Cho phép xuống dòng
    message.Size = UDim2.new(1, 0, 0.6, 0) -- Chiếm phần còn lại
    message.LayoutOrder = 2
    message.Parent = textFrame

    notificationTemplate = frame
    return notificationTemplate
end

local function setupNotificationContainer(parentGui)
    if notificationContainer and notificationContainer.Parent then return notificationContainer end

    local container = Instance.new("Frame")
    container.Name = "NotificationContainerFrame"
    container.AnchorPoint = Config.NotificationAnchor
    container.Position = Config.NotificationPosition
    container.Size = UDim2.new(0, Config.NotificationWidth + 20, 0, 300) -- Rộng hơn chút, cao để chứa nhiều notif
    container.BackgroundTransparency = 1
    container.Parent = parentGui

    local listLayout = Instance.new("UIListLayout", container)
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    listLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 5)

    notificationContainer = container
    return notificationContainer
end

local function showNotification(title, message, iconType)
    if not notificationContainer or not notificationContainer.Parent then
        warn("UnifiedAFK+Clicker: Container thông báo không hợp lệ.")
        -- Cố gắng tạo lại nếu có GUI chính
        if State.GuiElements.ScreenGui and State.GuiElements.ScreenGui.Parent then
             if not setupNotificationContainer(State.GuiElements.ScreenGui) then
                 warn("UnifiedAFK+Clicker: Không thể tạo lại container thông báo.")
                 return
             end
        else
            warn("UnifiedAFK+Clicker: Không có ScreenGui để gắn container thông báo.")
            return
        end
    end
    if not notificationTemplate then
        warn("UnifiedAFK+Clicker: Template thông báo chưa được tạo.")
        if not createNotificationTemplate() then
             warn("UnifiedAFK+Clicker: Không thể tạo template thông báo.")
            return
        end
    end

    local newFrame = notificationTemplate:Clone()
    if not newFrame then warn("UnifiedAFK+Clicker: Không thể clone template thông báo."); return end

    local icon = newFrame:FindFirstChild("Icon")
    local textFrame = newFrame:FindFirstChild("TextFrame")
    local titleLabel = textFrame and textFrame:FindFirstChild("Title")
    local messageLabel = textFrame and textFrame:FindFirstChild("Message")

    if not (icon and titleLabel and messageLabel) then
        warn("UnifiedAFK+Clicker: Frame thông báo được clone bị lỗi cấu trúc.")
        newFrame:Destroy()
        return
    end

    -- Đặt nội dung và icon
    titleLabel.Text = title or "Thông báo"
    messageLabel.Text = message or ""
    if iconType == "AFK" then
        icon.Image = Config.IconAntiAFK
    elseif iconType == "Clicker" then
        icon.Image = Config.IconAutoClicker
    else
        icon.Image = Config.IconAntiAFK -- Mặc định
    end
    newFrame.Name = "Notification_" .. (title or "Default"):gsub("%s+", "") -- Tên không có khoảng trắng

    newFrame.Parent = notificationContainer

    -- Animation xuất hiện
    local tweenInfoAppear = TweenInfo.new(Config.AnimationTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
    local fadeInTweenFrame = TweenService:Create(newFrame, tweenInfoAppear, { BackgroundTransparency = 0.2 })
    local fadeInTweenIcon = TweenService:Create(icon, tweenInfoAppear, { ImageTransparency = 0 })
    local fadeInTweenTitle = TweenService:Create(titleLabel, tweenInfoAppear, { TextTransparency = 0 })
    local fadeInTweenMessage = TweenService:Create(messageLabel, tweenInfoAppear, { TextTransparency = 0 })

    fadeInTweenFrame:Play()
    fadeInTweenIcon:Play()
    fadeInTweenTitle:Play()
    fadeInTweenMessage:Play()

    -- Tự động biến mất sau thời gian
    task.delay(Config.NotificationDuration, function()
        if not newFrame or not newFrame.Parent then return end -- Kiểm tra xem frame còn tồn tại không

        local tweenInfoDisappear = TweenInfo.new(Config.AnimationTime, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
        local fadeOutProperties = { BackgroundTransparency = 1, ImageTransparency = 1, TextTransparency = 1 }
        local fadeOutTweenFrame = TweenService:Create(newFrame, tweenInfoDisappear, { BackgroundTransparency = 1 })
        local fadeOutTweenIcon = TweenService:Create(icon, tweenInfoDisappear, { ImageTransparency = 1 })
        local fadeOutTweenTitle = TweenService:Create(titleLabel, tweenInfoDisappear, { TextTransparency = 1 })
        local fadeOutTweenMessage = TweenService:Create(messageLabel, tweenInfoDisappear, { TextTransparency = 1 })

        fadeOutTweenFrame:Play()
        fadeOutTweenIcon:Play()
        fadeOutTweenTitle:Play()
        fadeOutTweenMessage:Play()

        -- Đợi animation hoàn thành rồi hủy
        fadeOutTweenFrame.Completed:Connect(function()
            if newFrame and newFrame.Parent then
                newFrame:Destroy()
            end
        end)
    end)
end

-- // ============================ LOGIC ANTI-AFK ============================ //
local function performAntiAFKAction()
    if not Config.EnableIntervention then return end

    local success, err = pcall(function()
        VirtualInputManager:SendKeyEvent(true, Config.SimulatedKeyCode, false, game)
        task.wait(0.05 + math.random() * 0.05) -- Chờ một khoảng ngẫu nhiên nhỏ
        VirtualInputManager:SendKeyEvent(false, Config.SimulatedKeyCode, false, game)
    end)
    if not success then
        warn("UnifiedAFK+Clicker: Lỗi khi can thiệp AFK:", err)
        showNotification("Lỗi Anti-AFK", "Không thể mô phỏng phím.", "AFK")
    else
        State.LastInterventionTime = os.clock()
        State.InterventionCounter = State.InterventionCounter + 1
        print(string.format("UnifiedAFK+Clicker: Đã can thiệp AFK lần %d (nhấn %s)", State.InterventionCounter, tostring(Config.SimulatedKeyCode)))
        -- Không hiển thị thông báo mỗi lần can thiệp để tránh spam, thông báo checkInterval là đủ
    end
end

local function onInputDetected()
    local now = os.clock()
    if State.IsConsideredAFK then
        State.IsConsideredAFK = false
        State.LastInterventionTime = 0 -- Reset thời gian can thiệp
        State.InterventionCounter = 0 -- Reset bộ đếm
        showNotification("Bạn đã quay lại!", "Đã tạm dừng can thiệp AFK.", "AFK")
        print("UnifiedAFK+Clicker: Người dùng không còn AFK.")
        -- Cập nhật trạng thái AFK trên GUI nếu có
        if State.GuiElements.AntiAFKStatusLabel then
             State.GuiElements.AntiAFKStatusLabel.Text = "Trạng thái AFK: Bình thường"
             State.GuiElements.AntiAFKStatusLabel.TextColor3 = Color3.fromRGB(180, 255, 180) -- Màu xanh lá cây nhạt
        end
    end
    State.LastInputTime = now
end

-- // ============================ LOGIC AUTO CLICKER ============================ //
local function doAutoClick()
    while State.AutoClicking do
        local success, err = pcall(function()
            VirtualInputManager:SendMouseButtonEvent(
                State.SelectedClickPos.X, State.SelectedClickPos.Y,
                0, true, game, 0 -- 0 là nút chuột trái, true là nhấn xuống
            )
            -- Không cần chờ quá lâu giữa nhấn và nhả cho click nhanh
            VirtualInputManager:SendMouseButtonEvent(
                State.SelectedClickPos.X, State.SelectedClickPos.Y,
                0, false, game, 0 -- false là nhả ra
            )
        end)
        if not success then
            warn("UnifiedAFK+Clicker: Lỗi khi auto click:", err)
            showNotification("Lỗi Auto Click", "Không thể mô phỏng click.", "Clicker")
            State.AutoClicking = false -- Dừng lại nếu có lỗi
            -- Cập nhật GUI
             if State.GuiElements.AutoClickToggle then
                 State.GuiElements.AutoClickToggle.Text = "Auto Click: OFF"
                 State.GuiElements.AutoClickToggle.BackgroundColor3 = Color3.fromRGB(200, 50, 50) -- Màu đỏ
             end
            break -- Thoát khỏi vòng lặp
        end
        task.wait(1 / State.CurrentCPS) -- Chờ dựa trên CPS
    end
    print("UnifiedAFK+Clicker: Vòng lặp Auto Click đã dừng.")
end

local function startClick()
    if State.AutoClicking then return end -- Đã chạy rồi
    if State.ChoosingClickPos then
         showNotification("Auto Clicker", "Đang chọn vị trí, không thể bật.", "Clicker")
        return
    end

    State.AutoClicking = true
    -- Cập nhật GUI
    if State.GuiElements.AutoClickToggle then
        State.GuiElements.AutoClickToggle.Text = "Auto Click: ON"
        State.GuiElements.AutoClickToggle.BackgroundColor3 = Color3.fromRGB(50, 200, 50) -- Màu xanh
    end
    showNotification("Auto Clicker", string.format("Đã bật (%.0f CPS)", State.CurrentCPS), "Clicker")
    print("UnifiedAFK+Clicker: Bắt đầu Auto Click.")
    -- Chạy vòng lặp click trong một coroutine riêng biệt
    autoClickCoroutine = task.spawn(doAutoClick)
end

local function stopClick()
    if not State.AutoClicking then return end -- Đã tắt rồi

    State.AutoClicking = false
    -- Cập nhật GUI
    if State.GuiElements.AutoClickToggle then
        State.GuiElements.AutoClickToggle.Text = "Auto Click: OFF"
        State.GuiElements.AutoClickToggle.BackgroundColor3 = Color3.fromRGB(200, 50, 50) -- Màu đỏ
    end
    showNotification("Auto Clicker", "Đã tắt.", "Clicker")
    print("UnifiedAFK+Clicker: Đã dừng Auto Click.")
    -- Coroutine sẽ tự kết thúc khi State.AutoClicking là false
end

local function startChoosingClickPos()
    if State.ChoosingClickPos then return end -- Đang chọn rồi
    if State.AutoClicking then stopClick() end -- Tắt auto click nếu đang chạy

    State.ChoosingClickPos = true
    State.GuiElements.MainFrame.Visible = false -- Ẩn GUI chính
    State.GuiElements.FingerIcon.Visible = true -- Hiện icon ngón tay
    showNotification("Chọn vị trí", "Click 2 lần để xác định vị trí mới.", "Clicker")
    print("UnifiedAFK+Clicker: Bắt đầu chọn vị trí click.")

    local clickCount = 0
    -- Ngắt kết nối cũ nếu có (tránh lỗi double connection)
    if State.Connections.MouseClickChoose then
        State.Connections.MouseClickChoose:Disconnect()
        State.Connections.MouseClickChoose = nil
    end

    State.Connections.MouseClickChoose = mouse.Button1Down:Connect(function()
        clickCount = clickCount + 1
        State.GuiElements.FingerIcon.Position = UDim2.fromOffset(mouse.X - 20, mouse.Y - 20) -- Di chuyển icon theo chuột

        if clickCount == 1 then
             showNotification("Chọn vị trí", "Click lần nữa để xác nhận.", "Clicker")
        elseif clickCount >= 2 then
            State.SelectedClickPos = Vector2.new(mouse.X, mouse.Y) -- Lưu vị trí mới
            if State.Connections.MouseClickChoose then
                State.Connections.MouseClickChoose:Disconnect() -- Ngắt kết nối ngay
                State.Connections.MouseClickChoose = nil
            end

            State.GuiElements.FingerIcon.Visible = false -- Ẩn icon ngón tay
            State.GuiElements.MainFrame.Visible = true -- Hiện lại GUI chính
            State.ChoosingClickPos = false -- Kết thúc chế độ chọn
            showNotification("Chọn vị trí", string.format("Đã chọn: (%.0f, %.0f)", State.SelectedClickPos.X, State.SelectedClickPos.Y), "Clicker")
            print("UnifiedAFK+Clicker: Đã chọn vị trí click mới:", State.SelectedClickPos)
        end
    end)
end

-- // ============================ KHỞI TẠO GUI ============================ //
local function createGUI()
    -- Hủy GUI cũ nếu tồn tại
    local oldGui = CoreGui:FindFirstChild("UnifiedAFKClickerGui")
    if oldGui then oldGui:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "UnifiedAFKClickerGui"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 1000 -- Ưu tiên hiển thị trên cùng
    screenGui.Parent = CoreGui
    State.GuiElements.ScreenGui = screenGui

    -- Tạo container thông báo trước
    notificationContainer = setupNotificationContainer(screenGui)
    if not notificationContainer then
        warn("UnifiedAFK+Clicker: Không thể tạo container thông báo!")
    end
    -- Tạo template thông báo
    notificationTemplate = createNotificationTemplate()
    if not notificationTemplate then
         warn("UnifiedAFK+Clicker: Không thể tạo template thông báo!")
    end

    -- Frame chính có thể kéo thả
    local frame = Instance.new("Frame")
    frame.Name = "MainFrame"
    frame.Size = UDim2.fromOffset(Config.GuiWidth, Config.GuiHeight)
    frame.Position = UDim2.fromOffset(100, 100) -- Vị trí ban đầu
    frame.BackgroundColor3 = Color3.fromRGB(35, 35, 40)
    frame.BorderColor3 = Color3.fromRGB(80, 80, 90)
    frame.BorderSizePixel = 1
    frame.Active = true -- Cho phép kéo thả
    frame.Draggable = true
    frame.ClipsDescendants = true
    frame.Parent = screenGui
    State.GuiElements.MainFrame = frame

    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 6)

    local listLayout = Instance.new("UIListLayout", frame)
    listLayout.Padding = UDim.new(0, 8)
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    listLayout.FillDirection = Enum.FillDirection.Vertical

    local padding = Instance.new("UIPadding", frame)
    padding.PaddingTop = UDim.new(0, 10)
    padding.PaddingBottom = UDim.new(0, 10)
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)

    -- Title
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, 0, 0, 25)
    titleLabel.Text = Config.GuiTitle
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 16
    titleLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
    titleLabel.BackgroundTransparency = 1
    titleLabel.LayoutOrder = 1
    titleLabel.Parent = frame

    -- === Phần Anti-AFK ===
    local antiAFKSectionLabel = Instance.new("TextLabel")
    antiAFKSectionLabel.Name = "AntiAFKSection"
    antiAFKSectionLabel.Size = UDim2.new(1, 0, 0, 20)
    antiAFKSectionLabel.Text = "--- Anti-AFK ---"
    antiAFKSectionLabel.Font = Enum.Font.GothamMedium
    antiAFKSectionLabel.TextSize = 14
    antiAFKSectionLabel.TextColor3 = Color3.fromRGB(150, 180, 255)
    antiAFKSectionLabel.BackgroundTransparency = 1
    antiAFKSectionLabel.LayoutOrder = 2
    antiAFKSectionLabel.Parent = frame

    local antiAFKStatusLabel = Instance.new("TextLabel")
    antiAFKStatusLabel.Name = "AntiAFKStatus"
    antiAFKStatusLabel.Size = UDim2.new(1, 0, 0, 20)
    antiAFKStatusLabel.Text = "Trạng thái AFK: Bình thường"
    antiAFKStatusLabel.Font = Enum.Font.Gotham
    antiAFKStatusLabel.TextSize = 13
    antiAFKStatusLabel.TextColor3 = Color3.fromRGB(180, 255, 180)
    antiAFKStatusLabel.BackgroundTransparency = 1
    antiAFKStatusLabel.TextXAlignment = Enum.TextXAlignment.Left
    antiAFKStatusLabel.LayoutOrder = 3
    antiAFKStatusLabel.Parent = frame
    State.GuiElements.AntiAFKStatusLabel = antiAFKStatusLabel

    local antiAFKToggle = Instance.new("TextButton")
    antiAFKToggle.Name = "AntiAFKToggle"
    antiAFKToggle.Size = UDim2.new(1, -10, 0, 30) -- Hẹp hơn frame một chút
    antiAFKToggle.Text = "Can thiệp AFK: " .. (Config.EnableIntervention and "BẬT" or "TẮT")
    antiAFKToggle.Font = Enum.Font.GothamBold
    antiAFKToggle.TextSize = 14
    antiAFKToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    antiAFKToggle.BackgroundColor3 = Config.EnableIntervention and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(150, 50, 50)
    antiAFKToggle.LayoutOrder = 4
    antiAFKToggle.Parent = frame
    State.GuiElements.AntiAFKToggle = antiAFKToggle

    local cornerToggleAFK = Instance.new("UICorner", antiAFKToggle)
    cornerToggleAFK.CornerRadius = UDim.new(0, 4)

    -- === Phần Auto Clicker ===
    local autoClickerSectionLabel = Instance.new("TextLabel")
    autoClickerSectionLabel.Name = "AutoClickerSection"
    autoClickerSectionLabel.Size = UDim2.new(1, 0, 0, 20)
    autoClickerSectionLabel.Text = "--- Auto Clicker ---"
    autoClickerSectionLabel.Font = Enum.Font.GothamMedium
    autoClickerSectionLabel.TextSize = 14
    autoClickerSectionLabel.TextColor3 = Color3.fromRGB(255, 180, 150)
    autoClickerSectionLabel.BackgroundTransparency = 1
    autoClickerSectionLabel.LayoutOrder = 5
    autoClickerSectionLabel.Parent = frame

    local autoClickToggle = Instance.new("TextButton")
    autoClickToggle.Name = "AutoClickToggle"
    autoClickToggle.Size = UDim2.new(1, -10, 0, 30)
    autoClickToggle.Text = "Auto Click: OFF"
    autoClickToggle.Font = Enum.Font.GothamBold
    autoClickToggle.TextSize = 14
    autoClickToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
    autoClickToggle.BackgroundColor3 = Color3.fromRGB(200, 50, 50) -- Màu đỏ mặc định là OFF
    autoClickToggle.LayoutOrder = 6
    autoClickToggle.Parent = frame
    State.GuiElements.AutoClickToggle = autoClickToggle

    local cornerToggleClick = Instance.new("UICorner", autoClickToggle)
    cornerToggleClick.CornerRadius = UDim.new(0, 4)

    local cpsBox = Instance.new("TextBox")
    cpsBox.Name = "CPSBox"
    cpsBox.Size = UDim2.new(1, -10, 0, 30)
    cpsBox.PlaceholderText = string.format("CPS (hiện tại: %d)", State.CurrentCPS)
    cpsBox.Text = "" -- Để trống ban đầu, dùng placeholder
    cpsBox.Font = Enum.Font.Gotham
    cpsBox.TextSize = 14
    cpsBox.TextColor3 = Color3.fromRGB(240, 240, 240)
    cpsBox.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    cpsBox.ClearTextOnFocus = true
    cpsBox.TextXAlignment = Enum.TextXAlignment.Left
    cpsBox.LayoutOrder = 7
    cpsBox.Parent = frame
    State.GuiElements.CPSBox = cpsBox

    local cornerCpsBox = Instance.new("UICorner", cpsBox)
    cornerCpsBox.CornerRadius = UDim.new(0, 4)

    local locateBtn = Instance.new("TextButton")
    locateBtn.Name = "LocateButton"
    locateBtn.Size = UDim2.new(1, -10, 0, 30)
    locateBtn.Text = "Chọn vị trí Click"
    locateBtn.Font = Enum.Font.GothamBold
    locateBtn.TextSize = 14
    locateBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    locateBtn.BackgroundColor3 = Color3.fromRGB(60, 100, 180) -- Màu xanh dương
    locateBtn.LayoutOrder = 8
    locateBtn.Parent = frame
    State.GuiElements.LocateButton = locateBtn

    local cornerLocate = Instance.new("UICorner", locateBtn)
    cornerLocate.CornerRadius = UDim.new(0, 4)

    -- Icon ngón tay (ẩn ban đầu)
    local fingerIcon = Instance.new("ImageLabel")
    fingerIcon.Name = "FingerIcon"
    fingerIcon.Image = Config.IconFinger
    fingerIcon.Size = UDim2.fromOffset(40, 40)
    fingerIcon.BackgroundTransparency = 1
    fingerIcon.Visible = false -- Ẩn ban đầu
    fingerIcon.ZIndex = 10 -- Hiển thị trên cùng khi visible
    fingerIcon.Parent = screenGui -- Gắn vào ScreenGui để không bị ẩn cùng MainFrame
    State.GuiElements.FingerIcon = fingerIcon

    -- // ================== KẾT NỐI SỰ KIỆN GUI ================== //
    -- Toggle Can thiệp AFK
    State.Connections.AntiAFKToggleClick = antiAFKToggle.MouseButton1Click:Connect(function()
        Config.EnableIntervention = not Config.EnableIntervention
        local statusText = Config.EnableIntervention and "BẬT" or "TẮT"
        antiAFKToggle.Text = "Can thiệp AFK: " .. statusText
        antiAFKToggle.BackgroundColor3 = Config.EnableIntervention and Color3.fromRGB(50, 150, 50) or Color3.fromRGB(150, 50, 50)
        showNotification("Anti-AFK", "Can thiệp tự động đã " .. statusText, "AFK")
        print("UnifiedAFK+Clicker: Can thiệp AFK được đặt thành:", statusText)
    end)

    -- Toggle Auto Clicker
    State.Connections.AutoClickToggleClick = autoClickToggle.MouseButton1Click:Connect(function()
        if State.AutoClicking then
            stopClick()
        else
            startClick()
        end
    end)

    -- Nhập CPS
    State.Connections.CPSBoxFocusLost = cpsBox.FocusLost:Connect(function(enterPressed)
        local text = cpsBox.Text
        local num = tonumber(text)
        if num and num >= Config.MinCPS and num <= Config.MaxCPS then
            State.CurrentCPS = math.floor(num) -- Làm tròn xuống
            cpsBox.PlaceholderText = string.format("CPS (hiện tại: %d)", State.CurrentCPS)
            cpsBox.Text = "" -- Xóa text sau khi nhập hợp lệ
            showNotification("Auto Clicker", string.format("Đã đặt CPS thành %d", State.CurrentCPS), "Clicker")
            print("UnifiedAFK+Clicker: CPS được đặt thành:", State.CurrentCPS)
        else
            if text ~= "" then -- Chỉ hiển thị lỗi nếu người dùng đã nhập gì đó
                 showNotification("Lỗi CPS", string.format("Nhập số từ %d đến %d", Config.MinCPS, Config.MaxCPS), "Clicker")
            end
            cpsBox.Text = "" -- Xóa text không hợp lệ
            cpsBox.PlaceholderText = string.format("CPS (hiện tại: %d)", State.CurrentCPS) -- Reset placeholder
        end
    end)

    -- Nút chọn vị trí
    State.Connections.LocateButtonClick = locateBtn.MouseButton1Click:Connect(startChoosingClickPos)

     print("UnifiedAFK+Clicker: GUI đã được tạo và kết nối sự kiện.")
end

-- // ============================ KHỞI CHẠY CHÍNH & VÒNG LẶP ============================ //
local function initialize()
    createGUI()

    -- Kết nối sự kiện Input để phát hiện hoạt động
    State.Connections.InputBegan = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        if gameProcessedEvent then return end -- Bỏ qua input đã được game xử lý (ví dụ: chat)
        -- Chỉ coi các input này là "hoạt động"
        if input.UserInputType == Enum.UserInputType.Keyboard or
           input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.MouseButton2 or
           input.UserInputType == Enum.UserInputType.Touch then
            onInputDetected()
        end
    end)

    State.Connections.InputChanged = UserInputService.InputChanged:Connect(function(input, gameProcessedEvent)
        if gameProcessedEvent then return end
        -- Coi việc di chuyển chuột/bánh xe/gamepad là hoạt động
        if input.UserInputType == Enum.UserInputType.MouseMovement or
           input.UserInputType == Enum.UserInputType.MouseWheel or
           input.UserInputType.Name:find("Gamepad") then
            onInputDetected()
        end
    end)

    -- Kết nối sự kiện rời game / reset nhân vật
    State.Connections.CharacterRemoving = player.CharacterRemoving:Connect(function()
        print("UnifiedAFK+Clicker: Nhân vật đang bị xóa, dừng tạm thời một số hoạt động nếu cần.")
        -- Có thể muốn dừng Auto Clicker ở đây nếu cần
        -- stopClick()
    end)

    State.Connections.PlayerRemoving = Players.PlayerRemoving:Connect(function(leavingPlayer)
        if leavingPlayer == player then
            print("UnifiedAFK+Clicker: Người chơi cục bộ đang rời đi, thực hiện dọn dẹp.")
            cleanup() -- Gọi hàm dọn dẹp chính
        end
    end)

    -- Thông báo khởi động
    task.wait(1) -- Chờ một chút để GUI load xong
    showNotification(Config.GuiTitle, "Đã kích hoạt!", "AFK")
    print("UnifiedAFK+Clicker: Script đã khởi chạy thành công.")

    -- Vòng lặp chính kiểm tra AFK (chạy song song với Auto Clicker)
    while _G.UnifiedAntiAFK_AutoClicker_Running do -- Kiểm tra cờ global để dừng vòng lặp nếu cleanup được gọi
        task.wait(1) -- Kiểm tra mỗi giây là đủ
        local now = os.clock()
        local idleTime = now - State.LastInputTime

        -- Xử lý logic AFK
        if not State.IsConsideredAFK then
            if idleTime >= Config.AfkThreshold then
                -- Người dùng vừa mới bị coi là AFK
                State.IsConsideredAFK = true
                State.LastInterventionTime = now -- Bắt đầu tính thời gian can thiệp từ bây giờ
                State.LastCheckTime = now
                State.InterventionCounter = 0
                local msg = string.format("Sẽ can thiệp sau ~%.0f giây.", Config.InterventionInterval)
                if not Config.EnableIntervention then
                    msg = "Can thiệp tự động đang tắt."
                end
                 showNotification("Cảnh báo AFK!", msg, "AFK")
                 print("UnifiedAFK+Clicker: Người dùng được coi là AFK.")
                 -- Cập nhật trạng thái AFK trên GUI
                if State.GuiElements.AntiAFKStatusLabel then
                     State.GuiElements.AntiAFKStatusLabel.Text = "Trạng thái AFK: Đang AFK"
                     State.GuiElements.AntiAFKStatusLabel.TextColor3 = Color3.fromRGB(255, 200, 80) -- Màu vàng cam
                end
            end
        else
            -- Người dùng đang trong trạng thái AFK
            local timeSinceLastIntervention = now - State.LastInterventionTime
            local timeSinceLastCheck = now - State.LastCheckTime

            -- Thực hiện can thiệp nếu đủ thời gian và được bật
            if Config.EnableIntervention and timeSinceLastIntervention >= Config.InterventionInterval then
                performAntiAFKAction()
                -- LastInterventionTime sẽ được cập nhật trong performAntiAFKAction
            end

            -- Hiển thị thông báo định kỳ về trạng thái AFK
            if timeSinceLastCheck >= Config.CheckInterval then
                local nextInterventionIn = Config.EnableIntervention and math.max(0, Config.InterventionInterval - timeSinceLastIntervention) or 0
                local msg = Config.EnableIntervention and string.format("Can thiệp tiếp theo sau ~%.0f giây.", nextInterventionIn) or "Can thiệp tự động đang tắt."
                showNotification("Vẫn đang AFK...", msg, "AFK")
                State.LastCheckTime = now -- Reset thời gian kiểm tra
            end
        end

        -- Có thể thêm các kiểm tra trạng thái khác ở đây nếu cần
    end
    print("UnifiedAFK+Clicker: Vòng lặp chính đã kết thúc.")
end

-- // ============================ BẮT ĐẦU THỰC THI ============================ //
-- Sử dụng pcall để bắt lỗi khởi tạo tổng thể
local success, err = pcall(initialize)
if not success then
    warn("UnifiedAFK+Clicker Lỗi Khởi Tạo Nghiêm Trọng:", err)
    cleanup() -- Cố gắng dọn dẹp nếu có lỗi khởi tạo
    _G.UnifiedAntiAFK_AutoClicker_Running = false -- Đảm bảo cờ được đặt thành false
end

--[[
Lưu ý:
- Thay thế các giá trị `rbxassetid://...` trong Config bằng ID ảnh bạn muốn sử dụng.
- Script này sử dụng `VirtualInputManager`, yêu cầu quyền đặc biệt trong một số môi trường thực thi (executor).
- GUI có thể cần điều chỉnh thêm về vị trí, kích thước, màu sắc cho phù hợp với sở thích của bạn.
- Đã thêm cơ chế kiểm tra `_G.UnifiedAntiAFK_AutoClicker_Running` trong vòng lặp chính để dừng lại một cách an toàn khi hàm `cleanup` được gọi.
]]
