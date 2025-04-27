-- ███████╗ ██████╗██████╗ ██╗██████╗ ████████╗      ██╗  ██╗██╗  ██╗
-- ██╔════╝██╔════╝██╔══██╗██║██╔══██╗╚══██╔══╝      ██║  ██║╚██╗██╔╝
-- ███████╗██║     ██████╔╝██║██████╔╝   ██║         ███████║ ╚███╔╝
-- ╚════██║██║     ██╔══██╗██║██╔═══╝    ██║         ██╔══██║ ██╔██╗
-- ███████║╚██████╗██║  ██║██║██║        ██║         ██║  ██║██╔╝ ██╗
-- ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝╚═╝        ╚═╝         ╚═╝  ╚═╝╚═╝  ╚═╝
if _G.AntiAFK_Running then
    if _G.AntiAFK_CleanupFunction then
        _G.AntiAFK_CleanupFunction()
    end
end

_G.AntiAFK_Running = true

_G.AntiAFK_CleanupFunction = function()
    print("AntiAFK: Dọn dẹp tài nguyên của script cũ...")
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
    print("AntiAFK: Dọn dẹp hoàn tất.")
end

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")

local afkThreshold = 180
local interventionInterval = 600
local checkInterval = 600
local notificationDuration = 5
local animationTime = 0.5
local iconAssetId = "rbxassetid://117118515787811"
local enableIntervention = true
local simulatedKeyCode = Enum.KeyCode.Space

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

local guiSize = UDim2.new(0, 250, 0, 60)

local function createNotificationTemplate()
    if notificationTemplate then
        return notificationTemplate
    end

    local frame = Instance.new("Frame")
    frame.Name = "NotificationFrameTemplate"
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Size = guiSize
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

    local textListLayout = Instance.new("UIListLayout", textFrame)
    textListLayout.FillDirection = Enum.FillDirection.Horizontal
    textListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    textListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    textListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    textListLayout.Padding = UDim.new(0, 5)

    local title = Instance.new("TextLabel")
    title.Name = "Title"
    title.Text = "Tiêu đề" 
    title.Font = Enum.Font.GothamBold
    title.TextSize = 15
    title.TextColor3 = Color3.fromRGB(255, 255, 255)
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
    message.TextWrapped = false
    message.AutomaticSize = Enum.AutomaticSize.X
    message.Size = UDim2.new(0, 0, 1, 0)
    message.Parent = textFrame

    notificationTemplate = frame
    return notificationTemplate
end

local function setupNotificationContainer()
    if notificationContainer and notificationContainer.Parent then
        return notificationContainer
    end

    local playerGui = player:FindFirstChild("PlayerGui")
    if not playerGui then
        warn("AntiAFK: Không tìm thấy PlayerGui cho " .. (player and player.Name or "Người chơi không xác định"))
        return nil
    end

    local oldGui = playerGui:FindFirstChild("AntiAFKContainerGui")
    if oldGui then
        oldGui:Destroy()
    end

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
    return notificationContainer
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

    local newFrame = notificationTemplate:Clone()
    if not newFrame then
        warn("AntiAFK: Không thể clone template thông báo.")
        return
    end

    local icon = newFrame:FindFirstChild("Icon")
    local textFrame = newFrame:FindFirstChild("TextFrame")
    local titleLabel = textFrame and textFrame:FindFirstChild("Title")
    local messageLabel = textFrame and textFrame:FindFirstChild("Message")

    if not (icon and titleLabel and messageLabel) then
        warn("AntiAFK: Frame thông báo được clone bị lỗi cấu trúc.")
        newFrame:Destroy()
        return
    end

    titleLabel.Text = title or "Thông báo"
    messageLabel.Text = message or ""
    newFrame.Name = "Notification_" .. (title or "Default")

    newFrame.Parent = notificationContainer

    local tweenInfoAppear = TweenInfo.new(animationTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
    local fadeInTweenFrame = TweenService:Create(newFrame, tweenInfoAppear, { BackgroundTransparency = 0.2 })
    local fadeInTweenIcon = TweenService:Create(icon, tweenInfoAppear, { ImageTransparency = 0 })
    local fadeInTweenTitle = TweenService:Create(titleLabel, tweenInfoAppear, { TextTransparency = 0 })
    local fadeInTweenMessage = TweenService:Create(messageLabel, tweenInfoAppear, { TextTransparency = 0 })
    
    fadeInTweenFrame:Play()
    fadeInTweenIcon:Play()
    fadeInTweenTitle:Play()
    fadeInTweenMessage:Play()

    task.delay(notificationDuration, function()
        if not newFrame or not newFrame.Parent then
            return
        end

        local tweenInfoDisappear = TweenInfo.new(animationTime, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
        local fadeOutTweenFrame = TweenService:Create(newFrame, tweenInfoDisappear, { BackgroundTransparency = 1 })
        local fadeOutTweenIcon = TweenService:Create(icon, tweenInfoDisappear, { ImageTransparency = 1 })
        local fadeOutTweenTitle = TweenService:Create(titleLabel, tweenInfoDisappear, { TextTransparency = 1 })
        local fadeOutTweenMessage = TweenService:Create(messageLabel, tweenInfoDisappear, { TextTransparency = 1 })

        fadeOutTweenFrame:Play()
        fadeOutTweenIcon:Play()
        fadeOutTweenTitle:Play()
        fadeOutTweenMessage:Play()

        fadeOutTweenFrame.Completed:Connect(function()
            if newFrame and newFrame.Parent then
                newFrame:Destroy()
            end
        end)
    end)
end

local function performAntiAFKAction()
    if not enableIntervention then
        return
    end

    local success, err = pcall(function()
        VirtualInputManager:SendKeyEvent(true, simulatedKeyCode, false, game)
        task.wait(0.05 + math.random() * 0.05)
        VirtualInputManager:SendKeyEvent(false, simulatedKeyCode, false, game)
    end)
    if not success then
        warn("AntiAFK: Không thể mô phỏng nhấn phím " .. tostring(simulatedKeyCode) .. ". Lỗi:", err)
    else
        lastInterventionTime = os.clock()
        interventionCounter = interventionCounter + 1
        print(string.format("AntiAFK: Đã thực hiện can thiệp lần %d (nhấn %s)", interventionCounter, tostring(simulatedKeyCode)))
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

local function main()
    notificationContainer = setupNotificationContainer()
    if not notificationContainer then
        warn("AntiAFK: Không thể khởi tạo container GUI. Script sẽ không hiển thị thông báo.")
        return
    end
    notificationTemplate = createNotificationTemplate()
    if not notificationTemplate then
        warn("AntiAFK: Không thể tạo template GUI. Script sẽ không hiển thị thông báo.")
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
           input.UserInputType.Name:find("Gamepad") then
            onInput()
        end
    end)

    task.wait(3)
    showNotification("Anti AFK", "Đã được kích hoạt.")
    print("Anti-AFK Script đã khởi chạy.")

    while true do
        task.wait(0.5)
        local now = os.clock()
        local idleTime = now - lastInputTime

        if isConsideredAFK then
            local timeSinceLastIntervention = now - lastInterventionTime
            local timeSinceLastCheck = now - lastCheckTime

            if timeSinceLastIntervention >= interventionInterval then
                performAntiAFKAction()
            end

            if timeSinceLastCheck >= checkInterval then
                local nextInterventionIn = math.max(0, interventionInterval - timeSinceLastIntervention)
                local msg = string.format("Can thiệp tiếp theo sau ~%.0f giây.", nextInterventionIn)
                if not enableIntervention then
                    msg = "Chế độ can thiệp đang tắt."
                end
                showNotification("Vẫn đang AFK...", msg)
                lastCheckTime = now
            end
        else
            if idleTime >= afkThreshold then
                isConsideredAFK = true
                lastInterventionTime = now
                lastCheckTime = now
                interventionCounter = 0
                local msg = string.format("Sẽ can thiệp sau ~%.0f giây nếu không hoạt động.", interventionInterval)
                if not enableIntervention then
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
    player.CharacterRemoving:Connect(function() end)
    Players.PlayerRemoving:Connect(function(leavingPlayer)
        if leavingPlayer == player then
            cleanup()
            if coroutine.status(mainThread) == "suspended" or coroutine.status(mainThread) == "running" then
                print("AntiAFK: Đã yêu cầu dừng vòng lặp chính.")
            end
        end
    end)
else
    warn("AntiAFK: Không tìm thấy LocalPlayer khi thiết lập PlayerRemoving listener.")
end
