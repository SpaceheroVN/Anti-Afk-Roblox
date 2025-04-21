-- ✅ Global State & Cleanup
if _G.AntiAFK_Running then
    if _G.AntiAFK_CleanupFunction then
        print("🧹 Đang dọn dẹp script AntiAFK cũ...")
        _G.AntiAFK_CleanupFunction()
    end
end

_G.AntiAFK_Running = true

-- 🔄 Cleanup Function
_G.AntiAFK_CleanupFunction = function()
    if inputBeganConnection then inputBeganConnection:Disconnect() end
    if inputChangedConnection then inputChangedConnection:Disconnect() end
    if notificationContainer and notificationContainer.Parent then
        notificationContainer:Destroy()
    end
    inputBeganConnection = nil
    inputChangedConnection = nil
    notificationContainer = nil
    notificationTemplate = nil
    notificationPool = {}
    print("✅ Script AntiAFK cũ đã được dọn dẹp.")
end

-- 📦 Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")

-- ⚙️ Config
local AFK_THRESHOLD = 180
local INTERVENTION_INTERVAL = 600
local CHECK_INTERVAL = 60
local SIMULATED_KEY_CODE = Enum.KeyCode.Space
local ENABLE_INTERVENTION = true
local NOTIFICATION_DURATION = 3
local MAX_NOTIFICATIONS = 5
local ANIMATION_TIME = 0.3
local ICON_ASSET_ID = "rbxassetid://117118515787811"

-- 📊 State
local lastInputTime = os.clock()
local lastInterventionTime = 0
local lastCheckTime = 0
local isAFK = false
local notificationContainer, notificationTemplate = nil, nil
local inputBeganConnection, inputChangedConnection = nil, nil
local player = Players.LocalPlayer
local playerGui = player:FindFirstChild("PlayerGui")
local notificationPool = {}

-- 🎨 GUI constants
local GUI_SIZE = UDim2.new(0, 250, 0, 60)
local CONTAINER_SIZE = UDim2.new(0, 300, 0, 200)
local ICON_SIZE = UDim2.new(0, 40, 0, 40)
local ANCHOR_POINT = Vector2.new(1, 1)
local POSITION_OFFSET_HIDDEN = UDim2.new(1, GUI_SIZE.X.Offset + 20, 1, POSITION_OFFSET.Y.Offset)
local POSITION_OFFSET_VISIBLE = UDim2.new(1, POSITION_OFFSET.X.Offset, 1, POSITION_OFFSET.Y.Offset)

-- 📐 GUI Factory
local function createTemplate()
    if notificationTemplate then return notificationTemplate end

    local frame = Instance.new("Frame")
    frame.Name = "NotificationFrame"
    frame.Size = GUI_SIZE
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30) -- Nền đậm hơn
    frame.BackgroundTransparency = 0.6 -- Ít trong suốt hơn
    frame.BorderColor3 = Color3.fromRGB(80, 80, 80)

    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 6)
    local padding = Instance.new("UIPadding", frame)
    padding.PaddingTop = UDim.new(0, 6)
    padding.PaddingBottom = UDim.new(0, 6)
    padding.PaddingLeft = UDim.new(0, 10)
    padding.PaddingRight = UDim.new(0, 10)

    local layout = Instance.new("UIListLayout", frame)
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 6)

    local icon = Instance.new("ImageLabel", frame)
    icon.Name = "Icon"
    icon.Image = ICON_ASSET_ID
    icon.Size = ICON_SIZE
    icon.BackgroundTransparency = 1
    icon.ImageTransparency = 1

    local textLabel = Instance.new("TextLabel", frame)
    textLabel.Name = "Text"
    textLabel.Size = UDim2.new(1, -50, 1, 0)
    textLabel.BackgroundTransparency = 1
    textLabel.TextColor3 = Color3.fromRGB(230, 230, 230)
    textLabel.TextTransparency = 1
    textLabel.TextXAlignment = Enum.TextXAlignment.Left
    textLabel.Font = Enum.Font.GothamBold -- Chữ đậm hơn
    textLabel.TextSize = 14
    textLabel.TextWrapped = true

    notificationTemplate = frame
    return frame
end

local function setupContainer()
    if notificationContainer and notificationContainer.Parent then return notificationContainer end

    if not playerGui then return nil end
    local oldGui = playerGui:FindFirstChild("AntiAFKGui")
    if oldGui then oldGui:Destroy() end

    local screenGui = Instance.new("ScreenGui", playerGui)
    screenGui.Name = "AntiAFKGui"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

    local container = Instance.new("Frame", screenGui)
    container.Size = CONTAINER_SIZE
    container.AnchorPoint = ANCHOR_POINT
    container.Position = UDim2.new(1, POSITION_OFFSET.X.Offset, 1, POSITION_OFFSET.Y.Offset)
    container.BackgroundTransparency = 1

    local layout = Instance.new("UIListLayout", container)
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 8)

    notificationContainer = container
    return container
end

-- 🔔 Notification System
local function showNotification(message)
    local template = createTemplate()
    local container = setupContainer()
    if not (template and container) then return end

    local note = nil
    for _, n in ipairs(notificationPool) do
        if not n.Visible then note = n break end
    end
    if not note and #notificationPool < MAX_NOTIFICATIONS then
        note = template:Clone()
        note.Parent = container
        table.insert(notificationPool, note)
    end
    if not note then return end

    local icon = note:FindFirstChild("Icon")
    local textLabel = note:FindFirstChild("Text")
    if not (icon and textLabel) then return end

    note.Visible = true
    note.Position = POSITION_OFFSET_HIDDEN -- Bắt đầu từ vị trí ẩn bên phải
    icon.ImageTransparency = 1
    textLabel.TextTransparency = 1
    textLabel.Text = message

    local tweenIn = TweenInfo.new(ANIMATION_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
    TweenService:Create(note, tweenIn, { Position = POSITION_OFFSET_VISIBLE }):Play() -- Trượt từ phải sang trái
    TweenService:Create(icon, tweenIn, { ImageTransparency = 0 }):Play()
    TweenService:Create(textLabel, tweenIn, { TextTransparency = 0 }):Play()

    task.delay(NOTIFICATION_DURATION, function()
        if note and note.Parent then
            local tweenOut = TweenInfo.new(ANIMATION_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
            TweenService:Create(note, tweenOut, { Position = POSITION_OFFSET_HIDDEN }):Play() -- Trượt về bên phải để ẩn
            TweenService:Create(icon, tweenOut, { ImageTransparency = 1 }):Play()
            TweenService:Create(textLabel, tweenOut, { TextTransparency = 1 }):Play()
            task.delay(ANIMATION_TIME, function()
                if note then note.Visible = false end
            end)
        end
    end)
end
-- 🧠 Core
local function handleInput()
    if isAFK then
        isAFK = false
        lastInterventionTime = 0
        showNotification("👋 Bạn đã quay lại!")
        print("AntiAFK: Đã thoát trạng thái AFK.")
    end
    lastInputTime = os.clock()
end

local function simulateKeyPress()
    if not ENABLE_INTERVENTION then return end
    local ok, err = pcall(function()
        VirtualInputManager:SendKeyEvent(true, SIMULATED_KEY_CODE, false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, SIMULATED_KEY_CODE, false, game)
    end)
    if ok then
        lastInterventionTime = os.clock()
        print("AntiAFK: Đã mô phỏng phím", SIMULATED_KEY_CODE.Name)
    else
        warn("AntiAFK: Lỗi mô phỏng phím:", err)
    end
end

-- 🔁 Main
local function main()
    showNotification("✅ AntiAFK đang hoạt động...")
    print("AntiAFK script đang theo dõi input...")

    inputBeganConnection = UserInputService.InputBegan:Connect(function(input, gp)
        if not gp then handleInput() end
    end)
    inputChangedConnection = UserInputService.InputChanged:Connect(function(input, gp)
        if not gp then handleInput() end
    end)

    while true do
        task.wait(1)
        local now = os.clock()

        if isAFK then
            if now - lastInterventionTime >= INTERVENTION_INTERVAL then
                simulateKeyPress()
            end
            if now - lastCheckTime >= CHECK_INTERVAL then
                local msg = ENABLE_INTERVENTION
                    and string.format("💤 AFK - Can thiệp sau %.0f giây.", INTERVENTION_INTERVAL - (now - lastInterventionTime))
                    or "AFK - Can thiệp tự động đang tắt."
                showNotification(msg)
                lastCheckTime = now
            end
        else
            if now - lastInputTime >= AFK_THRESHOLD then
                isAFK = true
                lastInterventionTime = now
                lastCheckTime = now
                showNotification("⚠️ Bạn đang AFK! Can thiệp sẽ bắt đầu sau 10 phút.")
                print("AntiAFK: Bắt đầu theo dõi trạng thái AFK.")
            end
        end
    end
end

-- 🚀 Khởi chạy
local thread = coroutine.create(main)
local ok, err = coroutine.resume(thread)
if not ok then warn("AntiAFK Lỗi khởi động:", err) end

-- 🧹 Cleanup khi người chơi rời
Players.PlayerRemoving:Connect(function(plr)
    if plr == player then
        _G.AntiAFK_CleanupFunction()
        print("AntiAFK: Người chơi rời - đã cleanup script.")
    end
end)
