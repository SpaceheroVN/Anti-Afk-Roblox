--[[
    Script: Anti-AFK và Nút Tối Ưu Tùy Chỉnh
    Mô tả: Phát hiện người chơi AFK, thực hiện hành động mô phỏng để tránh bị kick,
           hiển thị thông báo trạng thái và cung cấp một nút tùy chỉnh trên màn hình.
    Lưu ý: Việc sử dụng VirtualInputManager có thể bị một số trò chơi coi là bất thường.
           Sử dụng có trách nhiệm và tuân thủ Điều khoản dịch vụ của Roblox.
]]

-- Dịch vụ Roblox
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService") -- Thêm GuiService

-- Cấu hình
local afkThreshold = 180 -- Thời gian (giây) không hoạt động để coi là AFK
local interventionInterval = 600 -- Thời gian (giây) giữa các lần can thiệp AFK
local checkInterval = 60 -- Thời gian (giây) giữa các lần kiểm tra và hiển thị thông báo khi AFK
local notificationDuration = 5 -- Thời gian (giây) hiển thị mỗi thông báo
local animationTime = 0.5 -- Thời gian (giây) cho hoạt ảnh mờ dần của thông báo
local iconAssetId = "rbxassetid://17118515787811" -- ID hình ảnh cho icon thông báo (Đảm bảo ID này hợp lệ)
local enableIntervention = true -- Bật/tắt chức năng can thiệp AFK tự động
local simulatedKeyCode = Enum.KeyCode.Space -- Phím được mô phỏng nhấn khi AFK

-- Biến trạng thái
local lastInputTime = os.clock()
local lastInterventionTime = 0
local lastCheckTime = 0
local interventionCounter = 0
local isConsideredAFK = false
local notificationContainer = nil
local notificationTemplate = nil
local inputBeganConnection = nil
local inputChangedConnection = nil
local runServiceConnection = nil -- Kết nối cho vòng lặp chính
local player = Players.LocalPlayer
local mainGui = nil -- ScreenGui chính cho script này
local customButtonFrame = nil -- Frame cho nút tùy chỉnh
local customButtonTitle = nil -- TextLabel cho nút tùy chỉnh

-- Kích thước GUI thông báo
local notificationGuiSize = UDim2.new(0, 250, 0, 60)

-- Hàm trợ giúp: Ngắt kết nối an toàn
local function disconnectConnection(connection)
    if connection and connection.Connected then
        connection:Disconnect()
    end
    return nil -- Trả về nil để có thể gán lại biến
end

-- Hàm tạo mẫu thông báo (chỉ tạo một lần)
local function createNotificationTemplate()
    if notificationTemplate then
        return notificationTemplate
    end

    -- Frame chính
    local frame = Instance.new("Frame")
    frame.Name = "NotificationFrameTemplate"
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BackgroundTransparency = 1 -- Bắt đầu trong suốt hoàn toàn
    frame.BorderSizePixel = 0
    frame.Size = notificationGuiSize
    frame.ClipsDescendants = true

    -- Bo góc
    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 8)

    -- Đệm bên trong
    local padding = Instance.new("UIPadding", frame)
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)
    padding.PaddingTop = UDim.new(0, 5)
    padding.PaddingBottom = UDim.new(0, 5)

    -- Sắp xếp ngang (Icon | Khung chữ)
    local listLayout = Instance.new("UIListLayout", frame)
    listLayout.FillDirection = Enum.FillDirection.Horizontal
    listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 10)

    -- Icon
    local icon = Instance.new("ImageLabel")
    icon.Name = "Icon"
    icon.Image = iconAssetId
    icon.BackgroundTransparency = 1
    icon.ImageTransparency = 1 -- Bắt đầu trong suốt
    icon.Size = UDim2.new(0, 40, 0, 40)
    icon.LayoutOrder = 1
    icon.Parent = frame

    -- Khung chứa chữ (Tiêu đề và Nội dung)
    local textFrame = Instance.new("Frame")
    textFrame.Name = "TextFrame"
    textFrame.BackgroundTransparency = 1
    textFrame.Size = UDim2.new(1, -60, 1, 0) -- Kích thước tương đối trừ đi icon và padding
    textFrame.LayoutOrder = 2
    textFrame.Parent = frame

    -- Sắp xếp dọc cho chữ
    local textListLayout = Instance.new("UIListLayout", textFrame)
    textListLayout.FillDirection = Enum.FillDirection.Vertical
    textListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    textListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    textListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    textListLayout.Padding = UDim.new(0, 2) -- Khoảng cách nhỏ giữa tiêu đề và nội dung

    -- Tiêu đề
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

    -- Nội dung
    local message = Instance.new("TextLabel")
    message.Name = "Message"
    message.Text = "Nội dung tin nhắn."
    message.Font = Enum.Font.Gotham
    message.TextSize = 13
    message.TextColor3 = Color3.fromRGB(200, 200, 200)
    message.BackgroundTransparency = 1
    message.TextTransparency = 1 -- Bắt đầu trong suốt
    message.TextXAlignment = Enum.TextXAlignment.Left
    message.TextWrapped = true -- Cho phép xuống dòng nếu cần
    message.Size = UDim2.new(1, 0, 0, 30) -- Kích thước cố định chiều cao, cho phép 2 dòng
    message.LayoutOrder = 2
    message.Parent = textFrame

    notificationTemplate = frame
    return notificationTemplate
end

-- Hàm thiết lập ScreenGui và container cho thông báo
local function setupNotificationContainer(playerGui)
    if not playerGui then return nil end

    -- Tạo ScreenGui chính nếu chưa có
    if not mainGui or not mainGui.Parent then
        mainGui = Instance.new("ScreenGui")
        mainGui.Name = "AntiAFK_CustomUI"
        mainGui.ResetOnSpawn = false
        mainGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        mainGui.DisplayOrder = 999 -- Hiển thị trên cùng
        mainGui.Parent = playerGui
    end

    -- Tạo container chứa thông báo nếu chưa có
    if not notificationContainer or not notificationContainer.Parent then
        notificationContainer = Instance.new("Frame")
        notificationContainer.Name = "NotificationContainerFrame"
        notificationContainer.AnchorPoint = Vector2.new(1, 1) -- Góc trên bên phải
        notificationContainer.Position = UDim2.new(1, -10, 1, -10) -- Vị trí góc trên bên phải, có đệm
        notificationContainer.Size = UDim2.new(0, notificationGuiSize.X.Offset + 20, 0, 300) -- Kích thước đủ chứa nhiều thông báo
        notificationContainer.BackgroundTransparency = 1
        notificationContainer.Parent = mainGui

        -- Sắp xếp thông báo dọc từ dưới lên
        local listLayout = Instance.new("UIListLayout", notificationContainer)
        listLayout.FillDirection = Enum.FillDirection.Vertical
        listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
        listLayout.VerticalAlignment = Enum.VerticalAlignment.Top -- Thông báo mới xuất hiện ở trên
        listLayout.SortOrder = Enum.SortOrder.LayoutOrder
        listLayout.Padding = UDim.new(0, 5)
    end

    return notificationContainer
end

-- Hàm hiển thị thông báo với hoạt ảnh
local function showNotification(title, message)
    -- Đảm bảo container và template đã sẵn sàng
    local playerGui = player and player:FindFirstChild("PlayerGui")
    if not setupNotificationContainer(playerGui) then
        warn("AntiAFK: Không thể thiết lập container thông báo.")
        return
    end
    if not createNotificationTemplate() then
        warn("AntiAFK: Không thể tạo template thông báo.")
        return
    end
    if not notificationContainer or not notificationContainer.Parent then
        warn("AntiAFK: Container thông báo không hợp lệ.")
        return
    end
     if not notificationTemplate then
        warn("AntiAFK: Template thông báo không hợp lệ.")
        return
    end


    local newFrame = notificationTemplate:Clone()
    if not newFrame then
        warn("AntiAFK: Không thể clone template thông báo.")
        return
    end

    -- Tìm các thành phần con một cách an toàn
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
    newFrame.Name = "Notification_" .. (title or "Default") .. "_" .. math.random(1, 1000) -- Tên duy nhất

    -- Đặt frame vào container
    newFrame.Parent = notificationContainer
    newFrame.LayoutOrder = -tick() -- Hiển thị thông báo mới nhất lên trên cùng (nếu VerticalAlignment là Top)

    -- Hoạt ảnh xuất hiện
    local tweenInfoAppear = TweenInfo.new(animationTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
    local fadeInTweenFrame = TweenService:Create(newFrame, tweenInfoAppear, { BackgroundTransparency = 0.2 })
    local fadeInTweenIcon = TweenService:Create(icon, tweenInfoAppear, { ImageTransparency = 0 })
    local fadeInTweenTitle = TweenService:Create(titleLabel, tweenInfoAppear, { TextTransparency = 0 })
    local fadeInTweenMessage = TweenService:Create(messageLabel, tweenInfoAppear, { TextTransparency = 0 })

    fadeInTweenFrame:Play()
    fadeInTweenIcon:Play()
    fadeInTweenTitle:Play()
    fadeInTweenMessage:Play()

    -- Lên lịch xóa bỏ và hoạt ảnh biến mất
    task.delay(notificationDuration, function()
        -- Kiểm tra lại xem frame còn tồn tại không trước khi thực hiện tween
        if not newFrame or not newFrame.Parent then
            return
        end

        local tweenInfoDisappear = TweenInfo.new(animationTime, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
        local fadeOutTweenFrame = TweenService:Create(newFrame, tweenInfoDisappear, { BackgroundTransparency = 1 })
        local fadeOutTweenIcon = TweenService:Create(icon, tweenInfoDisappear, { ImageTransparency = 1 })
        local fadeOutTweenTitle = TweenService:Create(titleLabel, tweenInfoDisappear, { TextTransparency = 1 })
        local fadeOutTweenMessage = TweenService:Create(messageLabel, tweenInfoDisappear, { TextTransparency = 1 })

        -- Kết nối sự kiện Completed *trước* khi Play
        local completedConnection
        completedConnection = fadeOutTweenFrame.Completed:Connect(function()
            if newFrame and newFrame.Parent then
                newFrame:Destroy() -- Xóa frame khi hoàn thành
            end
            completedConnection:Disconnect() -- Ngắt kết nối chính nó
        end)

        fadeOutTweenFrame:Play()
        fadeOutTweenIcon:Play()
        fadeOutTweenTitle:Play()
        fadeOutTweenMessage:Play()
    end)
end

-- Hàm thực hiện hành động chống AFK
local function performAntiAFKAction()
    if not enableIntervention then
        return
    end

    -- Sử dụng pcall để bắt lỗi tiềm ẩn với VirtualInputManager
    local success, err = pcall(function()
        VirtualInputManager:SendKeyEvent(true, simulatedKeyCode, false, game) -- Nhấn phím xuống
        task.wait(math.random(50, 100) / 1000) -- Đợi một khoảng thời gian ngẫu nhiên rất nhỏ (0.05 - 0.1 giây)
        VirtualInputManager:SendKeyEvent(false, simulatedKeyCode, false, game) -- Nhả phím ra
    end)

    if not success then
        warn("AntiAFK: Không thể mô phỏng nhấn phím " .. tostring(simulatedKeyCode) .. ". Lỗi:", err)
        -- Có thể hiển thị thông báo lỗi cho người dùng ở đây nếu cần
        -- showNotification("Lỗi AntiAFK", "Không thể mô phỏng phím.")
    else
        lastInterventionTime = os.clock()
        interventionCounter = interventionCounter + 1
        -- Không in ra console mỗi lần để tránh spam, thay vào đó có thể hiển thị thông báo
         if interventionCounter % 5 == 1 then -- Chỉ hiện thông báo sau mỗi 5 lần can thiệp hoặc lần đầu
             showNotification("Anti AFK", string.format("Đã can thiệp lần %d", interventionCounter))
         end
        print(string.format("AntiAFK Debug: Đã thực hiện can thiệp lần %d (nhấn %s)", interventionCounter, tostring(simulatedKeyCode)))
    end
end

-- Hàm xử lý khi có input từ người dùng
local function onInput()
    local now = os.clock()
    -- Nếu người dùng đang bị coi là AFK và có input mới
    if isConsideredAFK then
        isConsideredAFK = false
        lastInterventionTime = 0 -- Reset thời gian can thiệp cuối
        interventionCounter = 0 -- Reset bộ đếm can thiệp
        showNotification("Bạn đã quay lại!", "Đã tạm dừng can thiệp AFK.")
        print("AntiAFK: Người dùng không còn AFK.")
    end
    -- Cập nhật thời gian input cuối cùng
    lastInputTime = now
end

-- Hàm tạo nút tùy chỉnh
local function createCustomButton(parentGui)
    if not parentGui then return nil, nil end
    if customButtonFrame and customButtonFrame.Parent then return customButtonFrame, customButtonTitle end -- Trả về nếu đã tồn tại

    customButtonFrame = Instance.new("ImageButton") -- Sử dụng ImageButton để dễ dàng tùy chỉnh hơn
    customButtonFrame.Name = "CustomOptimizeButton"
    customButtonFrame.Size = UDim2.new(0, 100, 0, 35) -- Kích thước nhỏ gọn hơn
    customButtonFrame.Position = UDim2.new(0, 10, 0, 10) -- Đặt ở góc trên bên trái (có thể thay đổi)
    customButtonFrame.AnchorPoint = Vector2.new(0, 0)
    customButtonFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45) -- Màu nền tối hơn
    customButtonFrame.BackgroundTransparency = 0.3
    customButtonFrame.AutoButtonColor = false -- Tắt hiệu ứng mặc định
    customButtonFrame.ClipsDescendants = true
    customButtonFrame.ZIndex = 2 -- Đảm bảo nút ở trên các phần tử khác trong Gui này

    -- Bo góc
    local corner = Instance.new("UICorner", customButtonFrame)
    corner.CornerRadius = UDim.new(0, 6)

    -- Viền
    local border = Instance.new("UIStroke", customButtonFrame)
    border.Color = Color3.fromRGB(80, 80, 80)
    border.Thickness = 1
    border.Transparency = 0.5

    -- Tiêu đề nút
    customButtonTitle = Instance.new("TextLabel")
    customButtonTitle.Name = "Title"
    customButtonTitle.Text = "Tối ưu"
    customButtonTitle.Font = Enum.Font.GothamSemibold -- Font khác một chút
    customButtonTitle.TextSize = 14
    customButtonTitle.TextColor3 = Color3.fromRGB(220, 220, 220) -- Màu chữ xám trắng
    customButtonTitle.BackgroundTransparency = 1
    customButtonTitle.Size = UDim2.new(1, 0, 1, 0)
    customButtonTitle.ZIndex = 3
    customButtonTitle.Parent = customButtonFrame

    -- Đặt nút vào ScreenGui chính
    customButtonFrame.Parent = parentGui

    return customButtonFrame, customButtonTitle
end

-- Hàm thiết lập tương tác cho nút tùy chỉnh
local function setupButtonInteraction(buttonFrame, title)
    if not buttonFrame or not title then return end

    local border = buttonFrame:FindFirstChildOfClass("UIStroke")
    local originalBgColor = buttonFrame.BackgroundColor3
    local originalBorderTransparency = border and border.Transparency or 0.5
    local originalTextColor = title.TextColor3

    local hoverColor = Color3.fromRGB(65, 65, 65)
    local clickColor = Color3.fromRGB(85, 85, 85)
    local successColor = Color3.fromRGB(0, 255, 127) -- Xanh lá cây sáng
    local processingColor = Color3.fromRGB(255, 191, 0) -- Vàng hổ phách

    local tweenInfoFast = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local tweenInfoSlow = TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

    local isProcessing = false -- Cờ để ngăn chặn click liên tục

    -- Hiệu ứng Hover
    buttonFrame.MouseEnter:Connect(function()
        if isProcessing then return end
        TweenService:Create(buttonFrame, tweenInfoFast, { BackgroundColor3 = hoverColor }):Play()
        if border then
            TweenService:Create(border, tweenInfoFast, { Transparency = 0.2 }):Play()
        end
    end)

    buttonFrame.MouseLeave:Connect(function()
        if isProcessing then return end
        TweenService:Create(buttonFrame, tweenInfoFast, { BackgroundColor3 = originalBgColor }):Play()
        if border then
            TweenService:Create(border, tweenInfoFast, { Transparency = originalBorderTransparency }):Play()
        end
    end)

    -- Hiệu ứng Click và xử lý logic
    buttonFrame.MouseButton1Click:Connect(function()
        if isProcessing then return end -- Ngăn click khi đang xử lý
        isProcessing = true

        -- Hiệu ứng nhấn xuống
        TweenService:Create(buttonFrame, tweenInfoFast, { BackgroundColor3 = clickColor }):Play()
        TweenService:Create(title, tweenInfoFast, { TextColor3 = processingColor }):Play()
        title.Text = "Đang..." -- Thay đổi chữ

        showNotification("Đang tối ưu...", "Vui lòng chờ trong giây lát.")

        -- === BẮT ĐẦU LOGIC TỐI ƯU HÓA ===
        -- [[
            Phần này là nơi bạn đặt mã nguồn thực sự để "tối ưu hóa".
            Ví dụ:
            - Giảm cài đặt đồ họa: game.Players.LocalPlayer.PlayerScripts.GraphicsQuality.Value = 1
            - Xóa các hiệu ứng không cần thiết (nếu có thể truy cập)
            - Chạy garbage collection: game:GetService("RunService"):Set3dRenderingEnabled(false); task.wait(); game:GetService("RunService"):Set3dRenderingEnabled(true) -- Kỹ thuật cũ, không chắc hiệu quả
            - Tắt bóng đổ, ánh sáng,... (nếu có API)
            LƯU Ý: Khả năng truy cập và thay đổi các cài đặt này phụ thuộc vào quyền của script (LocalScript)
                   và cấu trúc của trò chơi. Nhiều cài đặt đồ họa không thể thay đổi trực tiếp từ LocalScript thông thường.
        ]]
        print("AntiAFK Debug: Bắt đầu quá trình tối ưu hóa giả lập...")
        task.wait(1.5) -- Giả lập thời gian xử lý
        print("AntiAFK Debug: Kết thúc quá trình tối ưu hóa giả lập.")
        -- === KẾT THÚC LOGIC TỐI ƯU HÓA ===

        -- Hiệu ứng hoàn thành
        TweenService:Create(title, tweenInfoSlow, { TextColor3 = successColor }):Play()
        title.Text = "Xong!" -- Thông báo hoàn thành

        showNotification("Tối ưu Thành Công!", "Chúc bạn chơi game vui vẻ.")

        -- Quay lại trạng thái bình thường sau một lúc
        task.wait(1.5)
        TweenService:Create(title, tweenInfoSlow, { TextColor3 = originalTextColor }):Play()
        TweenService:Create(buttonFrame, tweenInfoSlow, { BackgroundColor3 = originalBgColor }):Play()
        if border then
            TweenService:Create(border, tweenInfoSlow, { Transparency = originalBorderTransparency }):Play()
        end
        title.Text = "Tối ưu" -- Đặt lại chữ ban đầu
        isProcessing = false -- Cho phép click lại
    end)
end

-- Hàm dọn dẹp tài nguyên khi script dừng hoặc người chơi rời đi
local function cleanup()
    print("AntiAFK: Dọn dẹp tài nguyên...")
    -- Ngắt kết nối các sự kiện
    inputBeganConnection = disconnectConnection(inputBeganConnection)
    inputChangedConnection = disconnectConnection(inputChangedConnection)
    runServiceConnection = disconnectConnection(runServiceConnection) -- Ngắt kết nối vòng lặp chính

    -- Xóa GUI đã tạo
    if mainGui and mainGui.Parent then
        mainGui:Destroy()
    end

    -- Reset biến
    mainGui = nil
    notificationContainer = nil
    notificationTemplate = nil
    customButtonFrame = nil
    customButtonTitle = nil
    player = nil -- Quan trọng: giải phóng tham chiếu đến player

    print("AntiAFK: Đã dọn dẹp xong.")
end

-- Hàm chính khởi tạo và chạy script
local function main()
    if not player then
        warn("AntiAFK: Không tìm thấy LocalPlayer khi khởi tạo.")
        return
    end

    local playerGui = player:WaitForChild("PlayerGui", 10) -- Chờ PlayerGui tối đa 10 giây
    if not playerGui then
        warn("AntiAFK: Không tìm thấy PlayerGui cho " .. player.Name .. ". Script sẽ không hoạt động.")
        return
    end

    -- Thiết lập container thông báo và template
    if not setupNotificationContainer(playerGui) then return end -- Thoát nếu không tạo được GUI
    if not createNotificationTemplate() then return end

    -- Tạo và thiết lập nút tùy chỉnh
    local button, title = createCustomButton(mainGui) -- Đặt nút vào mainGui
    if button and title then
        setupButtonInteraction(button, title)
    else
        warn("AntiAFK: Không thể tạo nút tùy chỉnh.")
    end

    -- Kết nối các sự kiện input
    inputBeganConnection = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        if gameProcessedEvent then return end -- Bỏ qua input đã được game xử lý (vd: gõ chat)
        -- Chỉ theo dõi các input chính thể hiện sự hoạt động
        if input.UserInputType == Enum.UserInputType.Keyboard or
           input.UserInputType == Enum.UserInputType.MouseButton1 or
           input.UserInputType == Enum.UserInputType.MouseButton2 or
           input.UserInputType == Enum.UserInputType.Touch then
            onInput()
        end
    end)

    inputChangedConnection = UserInputService.InputChanged:Connect(function(input, gameProcessedEvent)
        if gameProcessedEvent then return end
        -- Theo dõi di chuyển chuột, cuộn chuột và input từ gamepad
        if input.UserInputType == Enum.UserInputType.MouseMovement or
           input.UserInputType == Enum.UserInputType.MouseWheel or
           input.UserInputType == Enum.UserInputType.Gamepad1 or -- Thêm gamepad
           input.UserInputType == Enum.UserInputType.Gamepad2 or
           input.UserInputType == Enum.UserInputType.Gamepad3 or
           input.UserInputType == Enum.UserInputType.Gamepad4 or
           input.UserInputType == Enum.UserInputType.Gamepad5 or
           input.UserInputType == Enum.UserInputType.Gamepad6 or
           input.UserInputType == Enum.UserInputType.Gamepad7 or
           input.UserInputType == Enum.UserInputType.Gamepad8 then
            onInput()
        end
    end)

    -- Hiển thị thông báo chào mừng sau một khoảng trễ ngắn
    task.wait(2)
    showNotification("Anti AFK", "Đã được kích hoạt.")
    print("Anti-AFK Script đã khởi chạy và đang theo dõi input.")

    -- Vòng lặp chính để kiểm tra AFK (kết nối với Heartbeat để tối ưu hơn wait())
    runServiceConnection = RunService.Heartbeat:Connect(function(deltaTime)
        -- Kiểm tra xem player còn tồn tại không (phòng trường hợp bị destroy bất ngờ)
        if not player or not player.Parent then
            cleanup() -- Dọn dẹp nếu player không còn hợp lệ
            return
        end

        local now = os.clock()
        local idleTime = now - lastInputTime

        -- Xử lý logic khi đang bị coi là AFK
        if isConsideredAFK then
            local timeSinceLastIntervention = now - lastInterventionTime
            local timeSinceLastCheck = now - lastCheckTime

            -- Thực hiện can thiệp nếu đủ thời gian
            if enableIntervention and timeSinceLastIntervention >= interventionInterval then
                performAntiAFKAction()
                lastCheckTime = now -- Reset thời gian kiểm tra sau khi can thiệp
            -- Nếu không can thiệp, vẫn kiểm tra định kỳ để thông báo
            elseif timeSinceLastCheck >= checkInterval then
                local nextInterventionIn = math.max(0, interventionInterval - timeSinceLastIntervention)
                local msg
                if enableIntervention then
                    msg = string.format("Can thiệp tiếp theo sau ~%.0f giây.", nextInterventionIn)
                else
                    msg = "Chế độ can thiệp đang tắt."
                end
                showNotification("Vẫn đang AFK...", msg)
                lastCheckTime = now
            end
        -- Xử lý logic khi không bị coi là AFK
        else
            -- Nếu thời gian không hoạt động vượt ngưỡng
            if idleTime >= afkThreshold then
                isConsideredAFK = true
                -- Không reset lastInterventionTime ngay lập tức, đợi đến lần can thiệp đầu tiên
                lastCheckTime = now -- Đặt thời gian kiểm tra đầu tiên
                interventionCounter = 0 -- Reset bộ đếm khi bắt đầu AFK
                local msg
                if enableIntervention then
                    msg = string.format("Sẽ can thiệp sau ~%.0f giây.", interventionInterval)
                else
                    msg = "Bạn hiện đang AFK (can thiệp tự động tắt)."
                end
                showNotification("Cảnh báo AFK!", msg)
                print("AntiAFK: Người dùng được coi là AFK.")
                -- Thực hiện can thiệp ngay lập tức nếu interventionInterval = 0 (không khuyến khích)
                if enableIntervention and interventionInterval <= 0 then
                     performAntiAFKAction()
                else
                    -- Đặt lastInterventionTime là thời điểm bắt đầu AFK để tính đúng cho lần can thiệp đầu
                    lastInterventionTime = now
                end
            end
        end
    end)
end

-- --- Khởi chạy và Dọn dẹp ---

-- Chờ character load để đảm bảo PlayerGui sẵn sàng (tùy chọn nhưng an toàn hơn)
if player and not player.Character then
    player.CharacterAdded:Wait()
end
task.wait(1) -- Đợi thêm một chút để mọi thứ ổn định

-- Chạy hàm main trong một coroutine để không block các script khác
local mainThread = coroutine.create(main)
local success, err = coroutine.resume(mainThread)
if not success then
    warn("AntiAFK Lỗi Khởi Tạo:", err, debug.traceback())
    cleanup() -- Dọn dẹp nếu khởi tạo lỗi
end

-- Thiết lập dọn dẹp khi người chơi rời đi
if player then
    -- Sử dụng AncestryChanged thay vì PlayerRemoving để bắt cả trường hợp bị kick/lỗi
    player.AncestryChanged:Connect(function(_, parent)
        if not parent then -- Nếu player bị xóa khỏi Players service
            cleanup()
            -- Không cần cố gắng dừng coroutine ở đây, ngắt kết nối Heartbeat là đủ
        end
    end)
else
    warn("AntiAFK: Không tìm thấy LocalPlayer khi thiết lập listener dọn dẹp.")
end
