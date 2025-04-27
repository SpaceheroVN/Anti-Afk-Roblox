-- ███████╗ ██████╗██████╗ ██╗██████╗ ████████╗      ██╗  ██╗██╗  ██╗
-- ██╔════╝██╔════╝██╔══██╗██║██╔══██╗╚══██╔══╝      ██║  ██║╚██╗██╔╝
-- ███████╗██║     ██████╔╝██║██████╔╝   ██║         ███████║ ╚███╔╝
-- ╚════██║██║     ██╔══██╗██║██╔═══╝    ██║         ██╔══██║ ██╔██╗
-- ███████║╚██████╗██║  ██║██║██║        ██║         ██║  ██║██╔╝ ██╗
-- ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝╚═╝        ╚═╝         ╚═╝  ╚═╝╚═╝  ╚═╝

-- ⚙️ Khởi tạo và Thiết lập Ban đầu ⚙️
local uniqueScriptName = "CoreActivityMonitor_" .. math.random(10000, 99999)
if _G[uniqueScriptName] then
    if _G[uniqueScriptName].cleanup then
        pcall(_G[uniqueScriptName].cleanup)
        print("Hx: Dọn dẹp phiên bản cũ.")
    end
end

local scriptInstance = { running = true }
_G[uniqueScriptName] = scriptInstance

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

local player = Players.LocalPlayer

-- 🔧 Cấu hình Script 🔧
local afkThreshold = 180 + math.random(-15, 15)
local baseInterventionInterval = 540
local interventionIntervalVariance = 120
local baseCheckInterval = 580
local checkIntervalVariance = 60

local notificationDuration = 4 + math.random() * 2
local animationTime = 0.4 + math.random() * 0.2
local iconAssetId = "rbxassetid://117118515787811"
local enableIntervention = true

local safeKeys = {
    Enum.KeyCode.Space,
    Enum.KeyCode.LeftShift,
}

-- ⚙️ Biến Trạng thái Nội bộ ⚙️
local lastInputTime = os.clock()
local nextInterventionTime = 0
local nextCheckTime = 0
local interventionCounter = 0
local isConsideredAFK = false
local notificationContainer = nil
local notificationTemplate = nil
local inputConnections = {}

local guiSize = UDim2.new(0, 220, 0, 50)

-- 🎨 Tạo và Quản lý GUI Thông báo 🎨
local function createNotificationTemplate()
    local frame = Instance.new("Frame")
    frame.Name = "NotifyFrame_" .. math.random(1000)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 0
    frame.Size = guiSize
    frame.ClipsDescendants = true

    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 6)

    local padding = Instance.new("UIPadding", frame)
    padding.PaddingLeft = UDim.new(0, 8); padding.PaddingRight = UDim.new(0, 8)
    padding.PaddingTop = UDim.new(0, 4); padding.PaddingBottom = UDim.new(0, 4)

    local listLayout = Instance.new("UIListLayout", frame)
    listLayout.FillDirection = Enum.FillDirection.Horizontal
    listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 8)

    local icon = Instance.new("ImageLabel")
    icon.Name = "IconImg"
    icon.Image = iconAssetId
    icon.BackgroundTransparency = 1
    icon.ImageTransparency = 1
    icon.Size = UDim2.new(0, 35, 0, 35)
    icon.LayoutOrder = 1
    icon.Parent = frame

    local textFrame = Instance.new("Frame")
    textFrame.Name = "TxtFrame"
    textFrame.BackgroundTransparency = 1
    textFrame.Size = UDim2.new(1, -45, 1, 0)
    textFrame.LayoutOrder = 2
    textFrame.Parent = frame

    local textListLayout = Instance.new("UIListLayout", textFrame)
    textListLayout.FillDirection = Enum.FillDirection.Vertical
    textListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    textListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    textListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    textListLayout.Padding = UDim.new(0, 2)

    local title = Instance.new("TextLabel")
    title.Name = "TitleLbl"
    title.Text = "Tiêu đề"
    title.Font = Enum.Font.SourceSansSemibold
    title.TextSize = 14
    title.TextColor3 = Color3.fromRGB(240, 240, 240)
    title.BackgroundTransparency = 1
    title.TextTransparency = 1
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Size = UDim2.new(1, 0, 0, 16)
    title.LayoutOrder = 1
    title.Parent = textFrame

    local message = Instance.new("TextLabel")
    message.Name = "MsgLbl"
    message.Text = "Nội dung tin nhắn."
    message.Font = Enum.Font.SourceSans
    message.TextSize = 12
    message.TextColor3 = Color3.fromRGB(180, 180, 180)
    message.BackgroundTransparency = 1
    message.TextTransparency = 1
    message.TextXAlignment = Enum.TextXAlignment.Left
    message.TextWrapped = true
    message.Size = UDim2.new(1, 0, 0, 28)
    message.LayoutOrder = 2
    message.Parent = textFrame

    notificationTemplate = frame
    return notificationTemplate
end

local function setupNotificationContainer()
    if notificationContainer and notificationContainer.Parent then
        return notificationContainer
    end

    local oldGui = CoreGui:FindFirstChild("ActivityMonitor_GUI")
    if oldGui then
        oldGui:Destroy()
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "ActivityMonitor_GUI"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.DisplayOrder = 9999
    screenGui.Parent = CoreGui

    local container = Instance.new("Frame")
    container.Name = "NotifyContainer"
    container.AnchorPoint = Vector2.new(1, 1)
    container.Position = UDim2.new(1, -15, 1, -40)
    container.Size = UDim2.new(0, 250, 0, 300)
    container.BackgroundTransparency = 1
    container.Parent = screenGui

    local listLayout = Instance.new("UIListLayout", container)
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    listLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 4)

    notificationContainer = container
    return notificationContainer
end

local function showNotification(title, message)
    if not notificationContainer or not notificationContainer.Parent then
        if not setupNotificationContainer() then
            print("Hx: Không thể tạo container thông báo.")
            return
        end
    end
    if not notificationTemplate then
        if not createNotificationTemplate() then
            print("Hx: Không thể tạo template thông báo.")
            return
        end
    end

    local newFrame = notificationTemplate:Clone()
    if not newFrame then return end

    local icon = newFrame:FindFirstChild("IconImg")
    local textFrame = newFrame:FindFirstChild("TxtFrame")
    local titleLabel = textFrame and textFrame:FindFirstChild("TitleLbl")
    local messageLabel = textFrame and textFrame:FindFirstChild("MsgLbl")

    if not (icon and titleLabel and messageLabel) then
        warn("Hx: Cấu trúc frame thông báo lỗi.")
        newFrame:Destroy()
        return
    end

    titleLabel.Text = title or "Hệ thống"
    messageLabel.Text = message or "..."
    newFrame.Name = "NotifyInstance_" .. math.random(1000)

    newFrame.Parent = notificationContainer

    local currentAnimationTime = animationTime + math.random() * 0.1 - 0.05
    local tweenInfoAppear = TweenInfo.new(currentAnimationTime, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
    local fadeInTweenFrame = TweenService:Create(newFrame, tweenInfoAppear, { BackgroundTransparency = 0.25 })
    local fadeInTweenIcon = TweenService:Create(icon, tweenInfoAppear, { ImageTransparency = 0 })
    local fadeInTweenTitle = TweenService:Create(titleLabel, tweenInfoAppear, { TextTransparency = 0 })
    local fadeInTweenMessage = TweenService:Create(messageLabel, tweenInfoAppear, { TextTransparency = 0 })

    fadeInTweenFrame:Play()
    fadeInTweenIcon:Play()
    fadeInTweenTitle:Play()
    fadeInTweenMessage:Play()

    task.delay(notificationDuration, function()
        if not newFrame or not newFrame.Parent then return end

        local currentDisappearTime = animationTime + math.random() * 0.1 - 0.05
        local tweenInfoDisappear = TweenInfo.new(currentDisappearTime, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
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

-- 🚀 Hành động Chống AFK 🚀
local function performAntiAFKAction()
    if not enableIntervention then return end

    local actionType = math.random(1, 10)

    local success = false
    local errMessage = "Không có hành động nào được thực hiện"

    if actionType <= 8 or not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        local randomKey = safeKeys[math.random(#safeKeys)]
        local pressDuration = 0.06 + math.random() * 0.08

        success, errMessage = pcall(function()
            VirtualInputManager:SendKeyEvent(true, randomKey, false, game)
            task.wait(pressDuration)
            VirtualInputManager:SendKeyEvent(false, randomKey, false, game)
        end)
        if success then
            errMessage = string.format("Mô phỏng nhấn phím %s trong %.3fs", tostring(randomKey), pressDuration)
        else
             errMessage = "Lỗi mô phỏng phím: " .. tostring(errMessage)
        end

    else
        local deltaX = math.random(-2, 2)
        local deltaY = math.random(-2, 2)
        if deltaX == 0 and deltaY == 0 then deltaX = 1 end

        success, errMessage = pcall(function()
            VirtualInputManager:SendMouseMoveEvent(deltaX, deltaY)
        end)
         if success then
            errMessage = string.format("Mô phỏng di chuyển chuột (%d, %d)", deltaX, deltaY)
        else
             errMessage = "Lỗi mô phỏng chuột: " .. tostring(errMessage)
        end
    end

    if not success then
        warn("Hx: Không thể thực hiện hành động. Lỗi: ", errMessage)
    else
        interventionCounter = interventionCounter + 1
        print(string.format("System: Hành động %d. %s", interventionCounter, errMessage))
    end
end

-- 🖱️ Xử lý Input Người dùng 🖱️
local function onInputDetected()
    local now = os.clock()
    if isConsideredAFK then
        isConsideredAFK = false
        interventionCounter = 0
        showNotification("Trạng thái", "Người dùng hoạt động trở lại.")
        print("System: Phát hiện hoạt động người dùng.")
    end
    lastInputTime = now
end

-- 🧹 Dọn dẹp Tài nguyên 🧹
local function cleanup()
    print("Hx: Bắt đầu dọn dẹp...")
    for i, conn in ipairs(inputConnections) do
        if conn and typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
        end
    end
    inputConnections = {}

    if notificationContainer and notificationContainer.Parent then
        local gui = notificationContainer.Parent
        if gui then
            gui:Destroy()
        end
    end
    notificationContainer = nil
    notificationTemplate = nil

    if _G[uniqueScriptName] then
        _G[uniqueScriptName] = nil
    end

    print("Hx: Dọn dẹp hoàn tất.")
end
scriptInstance.cleanup = cleanup

-- ▶️ Vòng lặp Chính và Thực thi ▶️
local function mainLoop()
    notificationContainer = setupNotificationContainer()
    if not notificationContainer then
        warn("Hx: Không thể khởi tạo GUI. Sẽ không hiển thị thông báo.")
    end
    notificationTemplate = createNotificationTemplate()

    local inputTypesToMonitor = {
        Enum.UserInputType.Keyboard,
        Enum.UserInputType.MouseButton1, Enum.UserInputType.MouseButton2, Enum.UserInputType.MouseButton3,
        Enum.UserInputType.Touch,
        Enum.UserInputType.MouseMovement, Enum.UserInputType.MouseWheel,
        Enum.UserInputType.Gamepad1, Enum.UserInputType.Gamepad2, Enum.UserInputType.Gamepad3, Enum.UserInputType.Gamepad4,
        Enum.UserInputType.Gamepad5, Enum.UserInputType.Gamepad6, Enum.UserInputType.Gamepad7, Enum.UserInputType.Gamepad8,
    }
    for _, inputType in ipairs(inputTypesToMonitor) do
        table.insert(inputConnections, UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
            if gameProcessedEvent then return end
            if input.UserInputType == inputType then onInputDetected() end
        end))
        table.insert(inputConnections, UserInputService.InputChanged:Connect(function(input, gameProcessedEvent)
             if gameProcessedEvent then return end
             if input.UserInputType == inputType then onInputDetected() end
        end))
    end
     table.insert(inputConnections, UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
         if gameProcessedEvent then return end
         local type = input.UserInputType
         if type == Enum.UserInputType.Keyboard or type.Name:find("MouseButton") or type == Enum.UserInputType.Touch then
             onInputDetected()
         end
     end))

    task.wait(2 + math.random())
    showNotification("Hx", "Trình anti afk đã được bật.")
    print("Hx Script đã khởi chạy.")
    lastInputTime = os.clock()

    while scriptInstance.running do
        local loopWait = 0.5 + math.random() * 0.2
        task.wait(loopWait)
        local now = os.clock()
        local idleTime = now - lastInputTime

        if isConsideredAFK then
            if enableIntervention and now >= nextInterventionTime then
                performAntiAFKAction()
                nextInterventionTime = now + baseInterventionInterval + math.random(-interventionIntervalVariance / 2, interventionIntervalVariance / 2)
                nextCheckTime = now + baseCheckInterval + math.random(-checkIntervalVariance/2, checkIntervalVariance/2)
            end

            if now >= nextCheckTime then
                 local timeToNextAction = enableIntervention and math.max(0, nextInterventionTime - now) or -1
                 local msg = "Trạng thái không hoạt động."
                 if timeToNextAction >= 0 then
                    msg = string.format("Hành động tiếp theo sau ~%.0f giây.", timeToNextAction)
                 elseif not enableIntervention then
                     msg = "Chế độ can thiệp tự động đang tắt."
                 end
                 showNotification("Không hoạt động", msg)
                 nextCheckTime = now + baseCheckInterval + math.random(-checkIntervalVariance/2, checkIntervalVariance/2)
            end
        else
            if idleTime >= afkThreshold then
                isConsideredAFK = true
                interventionCounter = 0
                nextInterventionTime = now + baseInterventionInterval + math.random(-interventionIntervalVariance / 2, interventionIntervalVariance / 2)
                nextCheckTime = now + baseCheckInterval + math.random(-checkIntervalVariance/2, checkIntervalVariance/2)

                local msg = ""
                if enableIntervention then
                     msg = string.format("Sẽ can thiệp sau ~%.0f giây nếu không có hoạt động.", nextInterventionTime - now)
                else
                     msg = "Phát hiện không hoạt động (Can thiệp tự động tắt)."
                end
                showNotification("Phát hiện AFK", msg)
                print("System: Người dùng được coi là không hoạt động (AFK).")
                lastInputTime = now
            end
        end
    end
    print("Hx: Vòng lặp chính đã dừng.")
end

-- 🚦 Khởi chạy và Xử lý Thoát 🚦
local mainThread = task.spawn(mainLoop)

if player then
    local playerRemovingConn = Players.PlayerRemoving:Connect(function(leavingPlayer)
        if leavingPlayer == player then
            print("Hx: Người chơi cục bộ đang rời đi. Thực hiện dọn dẹp...")
            scriptInstance.running = false
            task.wait(0.1)
            cleanup()
            if playerRemovingConn then
                 playerRemovingConn:Disconnect()
            end
        end
    end)
else
    warn("Hx: Không tìm thấy LocalPlayer khi thiết lập listener PlayerRemoving.")
end

scriptInstance.cleanup = cleanup
