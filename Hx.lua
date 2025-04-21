-- ✅ Global State & Cleanup
if _G.AntiAFK_Running then
    if _G.AntiAFK_CleanupFunction then
        print("🧹 Dọn dẹp AntiAFK cũ...")
        _G.AntiAFK_CleanupFunction()
    end
end

_G.AntiAFK_Running = true

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

-- ⏱ Durations & Animation
local NOTIFICATION_DURATION = 3
local MAX_NOTIFICATIONS = 5
local ANIMATION_TIME = 0.35

-- 📐 GUI Style
local GUI_SIZE = UDim2.new(0, 280, 0, 60)
local ICON_SIZE = UDim2.new(0, 36, 0, 36)
local CONTAINER_SIZE = UDim2.new(0, 320, 1, -100)
local ICON_ASSET_ID = "rbxassetid://117118515787811"
local ANCHOR_POINT = Vector2.new(1, 1)
local POSITION_VISIBLE = UDim2.new(1, -20, 1, -20)
local POSITION_HIDDEN = UDim2.new(1, 340, 1, -20)

-- 📊 State
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local lastInputTime = os.clock()
local lastInterventionTime = 0
local lastCheckTime = 0
local isAFK = false
local notificationContainer, notificationTemplate = nil, nil
local notificationPool = {}
local inputBeganConnection, inputChangedConnection = nil, nil

-- 🧹 Cleanup Function
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
    print("✅ AntiAFK đã được dọn sạch.")
end

-- 🎨 Notification GUI
local function createTemplate()
    if notificationTemplate then return notificationTemplate end

    local frame = Instance.new("Frame")
    frame.Name = "NotificationFrame"
    frame.Size = GUI_SIZE
    frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    frame.BackgroundTransparency = 0.15
    frame.BorderSizePixel = 0
    frame.ClipsDescendants = true
    frame.ZIndex = 10

    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

    local shadow = Instance.new("ImageLabel", frame)
    shadow.Name = "Shadow"
    shadow.Image = "rbxassetid://1316045217"
    shadow.Size = UDim2.new(1, 20, 1, 20)
    shadow.Position = UDim2.new(0, -10, 0, -10)
    shadow.BackgroundTransparency = 1
    shadow.ImageTransparency = 0.8
    shadow.ZIndex = 9

    local layout = Instance.new("UIListLayout", frame)
    layout.FillDirection = Enum.FillDirection.Horizontal
    layout.Padding = UDim.new(0, 8)
    layout.VerticalAlignment = Enum.VerticalAlignment.Center

    local padding = Instance.new("UIPadding", frame)
    padding.PaddingLeft = UDim.new(0, 12)
    padding.PaddingRight = UDim.new(0, 12)
    padding.PaddingTop = UDim.new(0, 8)
    padding.PaddingBottom = UDim.new(0, 8)

    local icon = Instance.new("ImageLabel", frame)
    icon.Name = "Icon"
    icon.Size = ICON_SIZE
    icon.BackgroundTransparency = 1
    icon.Image = ICON_ASSET_ID
    icon.ImageTransparency = 1

    local text = Instance.new("TextLabel", frame)
    text.Name = "Text"
    text.Size = UDim2.new(1, -50, 1, 0)
    text.BackgroundTransparency = 1
    text.Text = ""
    text.TextColor3 = Color3.fromRGB(240, 240, 240)
    text.Font = Enum.Font.GothamSemibold
    text.TextSize = 15
    text.TextXAlignment = Enum.TextXAlignment.Left
    text.TextWrapped = true
    text.TextTransparency = 1

    notificationTemplate = frame
    return frame
end

local function setupContainer()
    if notificationContainer and notificationContainer.Parent then return notificationContainer end

    local oldGui = playerGui:FindFirstChild("AntiAFKGui")
    if oldGui then oldGui:Destroy() end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "AntiAFKGui"
    screenGui.ResetOnSpawn = false
    screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    screenGui.Parent = playerGui

    local container = Instance.new("Frame")
    container.Name = "NotificationContainer"
    container.Size = CONTAINER_SIZE
    container.Position = POSITION_VISIBLE
    container.AnchorPoint = ANCHOR_POINT
    container.BackgroundTransparency = 1
    container.Parent = screenGui

    local layout = Instance.new("UIListLayout", container)
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    layout.Padding = UDim.new(0, 8)

    notificationContainer = container
    return container
end

local function showNotification(message)
    local template = createTemplate()
    local container = setupContainer()
    if not (template and container) then return end

    local note
    for _, n in ipairs(notificationPool) do
        if not n.Visible then
            note = n
            break
        end
    end

    if not note and #notificationPool < MAX_NOTIFICATIONS then
        note = template:Clone()
        note.Parent = container
        table.insert(notificationPool, note)
    end

    if not note then return end

    local icon = note:FindFirstChild("Icon")
    local text = note:FindFirstChild("Text")

    note.Visible = true
    note.Position = POSITION_HIDDEN
    text.Text = message
    icon.ImageTransparency = 1
    text.TextTransparency = 1

    local tweenIn = TweenInfo.new(ANIMATION_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
    TweenService:Create(note, tweenIn, { Position = POSITION_VISIBLE }):Play()
    TweenService:Create(icon, tweenIn, { ImageTransparency = 0 }):Play()
    TweenService:Create(text, tweenIn, { TextTransparency = 0 }):Play()

    task.delay(NOTIFICATION_DURATION, function()
        if note and note.Parent then
            local tweenOut = TweenInfo.new(ANIMATION_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
            TweenService:Create(note, tweenOut, { Position = POSITION_HIDDEN }):Play()
            TweenService:Create(icon, tweenOut, { ImageTransparency = 1 }):Play()
            TweenService:Create(text, tweenOut, { TextTransparency = 1 }):Play()
            task.delay(ANIMATION_TIME, function()
                if note then note.Visible = false end
            end)
        end
    end)
end

-- 🧠 Core Logic
local function handleInput()
    if isAFK then
        isAFK = false
        lastInterventionTime = 0
        showNotification("👋 Bạn đã quay lại!")
        print("AntiAFK: Quay lại từ AFK.")
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
        print("AntiAFK: Mô phỏng phím", SIMULATED_KEY_CODE.Name)
    else
        warn("AntiAFK: Lỗi mô phỏng:", err)
    end
end

-- 🔁 Main
local function main()
    showNotification("✅ AntiAFK đang hoạt động...")
    print("AntiAFK: Bắt đầu theo dõi input.")

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
                    and string.format("💤 AFK - Sẽ can thiệp sau %.0f giây.", INTERVENTION_INTERVAL - (now - lastInterventionTime))
                    or "AFK - Tự động can thiệp đang tắt."
                showNotification(msg)
                lastCheckTime = now
            end
        else
            if now - lastInputTime >= AFK_THRESHOLD then
                isAFK = true
                lastInterventionTime = now
                lastCheckTime = now
                showNotification("⚠️ Bạn đang AFK! Can thiệp sau 10 phút.")
                print("AntiAFK: Chuyển sang chế độ AFK.")
            end
        end
    end
end

-- 🚀 Khởi chạy
local thread = coroutine.create(main)
local ok, err = coroutine.resume(thread)
if not ok then warn("AntiAFK lỗi:", err) end

-- 🧹 Cleanup khi rời game
Players.PlayerRemoving:Connect(function(plr)
    if plr == player then
        _G.AntiAFK_CleanupFunction()
        print("AntiAFK: Người chơi rời - đã dọn.")
    end
end)
