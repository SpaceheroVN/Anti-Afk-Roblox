-- ✅ Global State & Cleanup
if _G.AntiAFK_Running then
    if _G.AntiAFK_CleanupFunction then
        print("🧹 Đang dọn dẹp script AntiAFK cũ...")
        _G.AntiAFK_CleanupFunction()
    end
end

_G.AntiAFK_Running = true

-- 📦 Services
local Players = game:GetService("Players")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local player = Players.LocalPlayer

-- 🔁 Cleanup
local inputBeganConnection, inputChangedConnection
local notificationContainer
_G.AntiAFK_CleanupFunction = function()
    if inputBeganConnection then inputBeganConnection:Disconnect() end
    if inputChangedConnection then inputChangedConnection:Disconnect() end
    if notificationContainer then notificationContainer:Destroy() end
    inputBeganConnection, inputChangedConnection = nil, nil
    notificationContainer = nil
    print("✅ Script AntiAFK cũ đã được dọn dẹp.")
end

-- 🧱 GUI Container
notificationContainer = Instance.new("ScreenGui")
notificationContainer.Name = "AntiAFK_NotificationGUI"
notificationContainer.ResetOnSpawn = false
notificationContainer.IgnoreGuiInset = true
notificationContainer.Parent = player:WaitForChild("PlayerGui")

-- 🔔 Notification
local function showNotification(message)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 50)
    frame.Position = UDim2.new(1, 100, 1, -60)
    frame.AnchorPoint = Vector2.new(1, 1)
    frame.BackgroundColor3 = Color3.fromRGB(35, 35, 35)
    frame.BackgroundTransparency = 0.05
    frame.BorderSizePixel = 0
    frame.ZIndex = 10
    frame.Parent = notificationContainer

    local corner = Instance.new("UICorner", frame)
    corner.CornerRadius = UDim.new(0, 10)

    local shadow = Instance.new("UIStroke", frame)
    shadow.Thickness = 1
    shadow.Color = Color3.fromRGB(80, 80, 80)
    shadow.Transparency = 0.3

    local label = Instance.new("TextLabel")
    label.Text = message
    label.Font = Enum.Font.GothamMedium
    label.TextSize = 18
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.BackgroundTransparency = 1
    label.Size = UDim2.new(1, -20, 1, 0)
    label.Position = UDim2.new(0, 10, 0, 0)
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = frame

    -- Animate in
    TweenService:Create(frame, TweenInfo.new(0.4, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Position = UDim2.new(1, -20, 1, -60)
    }):Play()

    -- Wait and animate out
    task.delay(4, function()
        local outTween = TweenService:Create(frame, TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
            Position = UDim2.new(1, 100, 1, -60)
        })
        outTween:Play()
        outTween.Completed:Wait()
        frame:Destroy()
    end)
end

-- 👟 Anti-AFK Core
local lastActivity = tick()

local function simulateActivity()
    VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, nil)
    VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, nil)
    showNotification("✅ Đã chống AFK tự động!")
end

-- ⏱️ Heartbeat Checker
RunService.Heartbeat:Connect(function()
    if tick() - lastActivity > 60 then
        simulateActivity()
        lastActivity = tick()
    end
end)

-- 🕹️ Input Tracking
local UIS = game:GetService("UserInputService")
inputBeganConnection = UIS.InputBegan:Connect(function() lastActivity = tick() end)
inputChangedConnection = UIS.InputChanged:Connect(function() lastActivity = tick() end)

-- 🚀 Ready!
print("✅ AntiAFK script đã khởi động.")
showNotification("🚀 Script AntiAFK đã sẵn sàng!")
