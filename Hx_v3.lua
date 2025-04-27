if _G.UnifiedAntiAFK_AutoClicker_Running then
    if _G.UnifiedAntiAFK_AutoClicker_CleanupFunction then
        pcall(_G.UnifiedAntiAFK_AutoClicker_CleanupFunction); print("Hx: Dọn dẹp instance cũ.")
    end
end
_G.UnifiedAntiAFK_AutoClicker_Running = true

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")
local GuiService = game:GetService("GuiService")
local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local Stats = game:GetService("Stats")
local player = Players.LocalPlayer
if not player then print("Hx: Lỗi - Không tìm thấy LocalPlayer."); _G.UnifiedAntiAFK_AutoClicker_Running = false; return end
local mouse = player:GetMouse()

local Fluent, SaveManager, InterfaceManager
local fluentSuccess, fluentError = pcall(function()
    Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
    SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
    InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
end)

if not fluentSuccess or not Fluent or not SaveManager or not InterfaceManager then
    warn("Hx: Không thể tải thư viện Fluent hoặc Addons! Lỗi:", fluentError)
    pcall(cleanup)
    _G.UnifiedAntiAFK_AutoClicker_Running = false
    return
end
print("Hx: Fluent và Addons đã được tải.")

local Config = {
    AfkThreshold = 300,
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
    NotificationDuration = 4,
    AnimationTime = 0.2,
    GuiTitle = "Hx Script Control v2",
    IconAntiAFK = "rbxassetid://117118515787811",
    IconAutoClicker = "rbxassetid://117118515787811",
    IconToggleButton = "rbxassetid://117118515787811",
    IconMobileClickButton = "rbxassetid://95151289125969",
    IconLock = "rbxassetid://114181737500273",
    IconETC = "rbxassetid://117118515787811",
    IconSystem = "rbxassetid://117118515787811",
    LockButtonSize = 40,

    NotificationWidth = 250,
    NotificationHeight = 60,
    NotificationAnchor = Vector2.new(1, 1),
    NotificationPosition = UDim2.new(1, -18, 1, -48),
    ColorBackground = Color3.fromRGB(35, 35, 40),
    ColorBorder = Color3.fromRGB(80, 80, 90),
    ColorTextPrimary = Color3.fromRGB(245, 245, 245),
    ColorTextSecondary = Color3.fromRGB(190, 190, 200),
    ColorClickTargetCenter = Color3.fromRGB(255, 0, 0),
    ColorClickTargetBorder = Color3.fromRGB(255, 255, 255),
}
local TWEEN_INFO_FAST = TweenInfo.new(Config.AnimationTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local TWEEN_INFO_FAST_IN = TweenInfo.new(Config.AnimationTime, Enum.EasingStyle.Sine, Enum.EasingDirection.In)

local State = {
    IsConsideredAFK = false,
    AutoClicking = false,
    ChoosingClickPos = false,
    IsBindingHotkey = false,
    ClickTriggerActive = false,
    MobileButtonIsDragging = false,
    MobileButtonLocked = false,
    LagReduced = false,
    EspEnabled = false,

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
    EspConnections = {},
    HighlightTemplate = nil,
    FluentWindow = nil,
    FluentElements = {},
    MobileClickButtonInstance = nil,
    ClickTargetMarkerInstance = nil,
    ClickLockConfirmButton = nil,
    NotificationContainer = nil,
}
local autoClickCoroutine = nil
local notificationTemplate = nil

local function unlockFPS()
    local unlock_success, unlock_err = pcall(function()
        if not settings then return end; local cs = settings(); if not cs then return end
        local rs = cs.Rendering; if not rs then return end
        local cap_exists, _ = pcall(function() local _ = rs.FpsCap; return true end)
        if not cap_exists then return end;
        local s1, _ = pcall(function() rs.FpsCap = 9999 end); task.wait(0.1)
        local r1, c1 = pcall(function() return rs.FpsCap end)
        if r1 and c1 and c1 > 60 then print("Hx: FPS Unlocked (Method 1)"); return end
        if typeof(Stats.PerformanceStats) == "Instance" then
            pcall(function() Stats.PerformanceStats.ReportFPS = false end); task.wait(0.1)
        end
        local s2, _ = pcall(function() rs.FpsCap = 9999 end); task.wait(0.1)
        local r2, c2 = pcall(function() return rs.FpsCap end)
        if r2 and c2 and c2 > 60 then print("Hx: FPS Unlocked (Method 2)") else print("Hx: Không thể unlock FPS.") end
    end)
    if not unlock_success then print("Hx: Lỗi unlockFPS:", unlock_err) end
end

local function setupNotificationContainer(parent)
    if State.NotificationContainer and State.NotificationContainer.Parent then return State.NotificationContainer end
    if not parent then
        warn("Hx: Parent không hợp lệ để tạo Notification Container.")
        return nil
    end
    local container = Instance.new("Frame")
    container.Name = "HxNotificationContainer"
    container.AnchorPoint = Config.NotificationAnchor
    container.Position = Config.NotificationPosition
    container.Size = UDim2.new(0, Config.NotificationWidth + 20, 0, 300)
    container.BackgroundTransparency = 1
    container.Parent = parent
    local layout = Instance.new("UIListLayout", container)
    layout.FillDirection = Enum.FillDirection.Vertical
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, 5)
    State.NotificationContainer = container
    print("Hx: Notification Container đã được thiết lập.")
    return container
end

local function createNotificationTemplate()
    if notificationTemplate and notificationTemplate.Parent == nil then
         pcall(notificationTemplate.Destroy, notificationTemplate)
         notificationTemplate = nil
    end
    if notificationTemplate then return notificationTemplate end;
    local frame = Instance.new("Frame")
    frame.Name = "NotificationTemplate"
    frame.BackgroundColor3 = Color3.fromRGB(40, 40, 45)
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 1
    frame.BorderColor3 = Config.ColorBorder
    frame.Size = UDim2.new(0, Config.NotificationWidth, 0, Config.NotificationHeight)
    frame.ClipsDescendants = true

    local corner = Instance.new("UICorner", frame); corner.CornerRadius = UDim.new(0, 8)
    local padding = Instance.new("UIPadding", frame); padding.PaddingLeft = UDim.new(0, 10); padding.PaddingRight = UDim.new(0, 10); padding.PaddingTop = UDim.new(0, 5); padding.PaddingBottom = UDim.new(0, 5)
    local layout = Instance.new("UIListLayout", frame); layout.FillDirection = Enum.FillDirection.Horizontal; layout.VerticalAlignment = Enum.VerticalAlignment.Center; layout.SortOrder = Enum.SortOrder.LayoutOrder; layout.Padding = UDim.new(0, 10)

    local icon = Instance.new("ImageLabel"); icon.Name = "Icon"; icon.Image = Config.IconSystem; icon.BackgroundTransparency = 1; icon.ImageTransparency = 1; icon.Size = UDim2.new(0, 35, 0, 35); icon.LayoutOrder = 1; icon.Parent = frame
    local textFrame = Instance.new("Frame"); textFrame.Name = "TextFrame"; textFrame.BackgroundTransparency = 1; textFrame.Size = UDim2.new(1, -55, 1, 0); textFrame.LayoutOrder = 2; textFrame.Parent = frame
    local textLayout = Instance.new("UIListLayout", textFrame); textLayout.FillDirection = Enum.FillDirection.Vertical; textLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left; textLayout.VerticalAlignment = Enum.VerticalAlignment.Center; textLayout.SortOrder = Enum.SortOrder.LayoutOrder; textLayout.Padding = UDim.new(0, 2)
    local titleLabel = Instance.new("TextLabel"); titleLabel.Name = "Title"; titleLabel.Text = "Notification"; titleLabel.Font = Enum.Font.SourceSansBold; titleLabel.TextSize = 17; titleLabel.TextColor3 = Config.ColorTextPrimary; titleLabel.BackgroundTransparency = 1; titleLabel.TextTransparency = 1; titleLabel.TextXAlignment = Enum.TextXAlignment.Left; titleLabel.Size = UDim2.new(1, 0, 0, 20); titleLabel.LayoutOrder = 1; titleLabel.Parent = textFrame
    local messageLabel = Instance.new("TextLabel"); messageLabel.Name = "Message"; messageLabel.Text = "Details here."; messageLabel.Font = Enum.Font.SourceSans; messageLabel.TextSize = 14; messageLabel.TextColor3 = Config.ColorTextSecondary; messageLabel.BackgroundTransparency = 1; messageLabel.TextTransparency = 1; messageLabel.TextXAlignment = Enum.TextXAlignment.Left; messageLabel.TextWrapped = true; messageLabel.Size = UDim2.new(1, 0, 0.6, 0); messageLabel.LayoutOrder = 2; messageLabel.Parent = textFrame

    notificationTemplate = frame
    return frame
end

local function showNotification(title, message, iconType)
    if not _G.UnifiedAntiAFK_AutoClicker_Running then return end
    local success, err = pcall(function()
        local container = State.NotificationContainer
        if not container or not container.Parent then
             local fluentGui = State.FluentWindow and State.FluentWindow.Parent
             if not fluentGui then
                 warn("Hx: Không tìm thấy Fluent GUI để đặt container thông báo.")

                 return
             end
             container = setupNotificationContainer(fluentGui)
             if not container then print("Hx: Lỗi không thể tạo container thông báo sau khi tìm thấy Fluent GUI."); return end
        end

        local template = notificationTemplate or createNotificationTemplate()
        if not template then print("Hx: Lỗi không có template thông báo."); return end

        local notification = template:Clone()
        if not notification then return end

        local iconLabel = notification:FindFirstChild("Icon")
        local textFrame = notification:FindFirstChild("TextFrame")
        local titleLabel = textFrame and textFrame:FindFirstChild("Title")
        local messageLabel = textFrame and textFrame:FindFirstChild("Message")

        if not (iconLabel and titleLabel and messageLabel) then
            pcall(notification.Destroy, notification); print("Hx: Lỗi cấu trúc template thông báo nhân bản."); return
        end

        titleLabel.Text = title or "Thông Báo"
        messageLabel.Text = message or ""

        if iconType == "AFK" then iconLabel.Image = Config.IconAntiAFK
        elseif iconType == "Clicker" then iconLabel.Image = Config.IconAutoClicker
        elseif iconType == "ETC" then iconLabel.Image = Config.IconETC
        elseif iconType == "System" then iconLabel.Image = Config.IconSystem
        else iconLabel.Image = Config.IconSystem
        end

        notification.Name = "Notification_" .. (title or "Default"):gsub("%s+", "") .. "_" .. math.random(1,1000)
        notification.Parent = container

        local fadeInGoals = { BackgroundTransparency = 0.1, ImageTransparency = 0, TextTransparency = 0 }
        local fadeOutGoals = { BackgroundTransparency = 1, ImageTransparency = 1, TextTransparency = 1 }

        pcall(function() TweenService:Create(notification, TWEEN_INFO_FAST, { BackgroundTransparency = fadeInGoals.BackgroundTransparency }):Play() end)
        pcall(function() TweenService:Create(iconLabel, TWEEN_INFO_FAST, { ImageTransparency = fadeInGoals.ImageTransparency }):Play() end)
        pcall(function() TweenService:Create(titleLabel, TWEEN_INFO_FAST, { TextTransparency = fadeInGoals.TextTransparency }):Play() end)
        pcall(function() TweenService:Create(messageLabel, TWEEN_INFO_FAST, { TextTransparency = fadeInGoals.TextTransparency }):Play() end)

        task.delay(Config.NotificationDuration, function()
            if not notification or not notification.Parent then return end
            local fadeOutSuccess, fadeOutErr = pcall(function()
                local tweenBg = TweenService:Create(notification, TWEEN_INFO_FAST_IN, { BackgroundTransparency = fadeOutGoals.BackgroundTransparency })
                local tweenIcon = TweenService:Create(iconLabel, TWEEN_INFO_FAST_IN, { ImageTransparency = fadeOutGoals.ImageTransparency })
                local tweenTitle = TweenService:Create(titleLabel, TWEEN_INFO_FAST_IN, { TextTransparency = fadeOutGoals.TextTransparency })
                local tweenMsg = TweenService:Create(messageLabel, TWEEN_INFO_FAST_IN, { TextTransparency = fadeOutGoals.TextTransparency })

                local connectionId = "NotificationCleanup_" .. notification.Name
                if State.Connections[connectionId] then pcall(State.Connections[connectionId].Disconnect, State.Connections[connectionId]) end

                State.Connections[connectionId] = tweenBg.Completed:Connect(function()
                    if notification and notification.Parent then pcall(notification.Destroy, notification) end
                    if State.Connections[connectionId] then pcall(State.Connections[connectionId].Disconnect, State.Connections[connectionId]); State.Connections[connectionId] = nil end
                end)

                tweenBg:Play(); tweenIcon:Play(); tweenTitle:Play(); tweenMsg:Play()
            end)
            if not fadeOutSuccess then
                print("Hx: Lỗi fade out thông báo:", fadeOutErr)
                if notification and notification.Parent then pcall(notification.Destroy, notification) end
            end
        end)
    end)
    if not success then print("Hx: Lỗi showNotification:", err) end
end

local function safeShowNotification(...)
    local success, err = pcall(showNotification, ...)
    if not success then print("Hx: Lỗi safeShowNotification:", err) end
end

local function reduceLag()
    print("Hx: Bắt đầu giảm lag...")
    local lag_reduce_success, lag_reduce_err = pcall(function()
        local count = 0
        if settings and settings() then pcall(function() settings().Rendering.QualityLevel = Enum.QualityLevel.Level01; count = count + 1 end) end
        if Lighting then
            pcall(function() Lighting.GlobalShadows = false; count = count + 1 end)
            pcall(function() Lighting.FogEnd = 100000; count = count + 1 end)
            pcall(function() Lighting.Brightness = 0; count = count + 1 end)
            pcall(function() Lighting.EnvironmentDiffuseScale = 0; count = count + 1 end)
            pcall(function() Lighting.EnvironmentSpecularScale = 0; count = count + 1 end)
            for _, v in pairs(Lighting:GetChildren()) do if v and v:IsA("PostEffect") then pcall(function() v.Enabled = false end); count = count + 1 end end
            local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere"); if atmosphere then pcall(function() atmosphere.Enabled = false end); count = count + 1 end
            local clouds = Lighting:FindFirstChildOfClass("Clouds"); if clouds then pcall(function() clouds.Enabled = false end); count = count + 1 end
            local sky = Lighting:FindFirstChildOfClass("Sky"); if sky then pcall(function() sky.CelestialBodiesShown = false end); count = count + 1 end
        end
        local terrain = Workspace:FindFirstChild("Terrain")
        if terrain then
            pcall(function() terrain.WaterWaveSize = 0; count = count + 1 end); pcall(function() terrain.WaterWaveSpeed = 0; count = count + 1 end)
            pcall(function() terrain.WaterReflectance = 0; count = count + 1 end); pcall(function() terrain.WaterTransparency = 1; count = count + 1 end)
            pcall(function() terrain.Decoration = false; count = count + 1 end)
        end
        safeShowNotification("Giảm Lag", "Đã áp dụng " .. count .. " cài đặt giảm lag.", "ETC")
        State.LagReduced = true
        if State.FluentElements.ReduceLagButton then
             State.FluentElements.ReduceLagButton:SetTitle("Lag Đã Giảm (Khởi động lại để hoàn tác)")
        end
    end)
    if not lag_reduce_success then print("Hx: Lỗi reduceLag:", lag_reduce_err); safeShowNotification("Lỗi Giảm Lag", "Có lỗi xảy ra.", "ETC") end
end

local function createHighlightTemplateEsp()
    if State.HighlightTemplate then return State.HighlightTemplate end
    local ht = Instance.new("Highlight")
    ht.Name = "Hx_ESP_Highlight"
    ht.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    ht.FillTransparency = 0.7
    ht.OutlineTransparency = 0
    ht.FillColor = Color3.fromRGB(255, 0, 0)
    ht.OutlineColor = Color3.fromRGB(255, 255, 255)
    ht.Enabled = true
    State.HighlightTemplate = ht
    return ht
end

local function removeHighlightFromCharacter(character)
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if hrp then
        local highlight = hrp:FindFirstChild("Hx_ESP_Highlight")
        if highlight then pcall(highlight.Destroy, highlight) end
    end
    if State.EspConnections[character] then
        if State.EspConnections[character].DiedConnection then
            pcall(State.EspConnections[character].DiedConnection.Disconnect, State.EspConnections[character].DiedConnection)
        end
        State.EspConnections[character] = nil
    end
end

local function addHighlightToCharacter(character)
    if not State.EspEnabled or not character then return end
    local template = createHighlightTemplateEsp()
    if not template then return end
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)
    if not humanoidRootPart then return end

    if humanoidRootPart:FindFirstChild(template.Name) then return end

    local highlightClone = template:Clone()
    highlightClone.Adornee = character
    highlightClone.Parent = humanoidRootPart
    highlightClone.Enabled = State.EspEnabled

    State.EspConnections[character] = State.EspConnections[character] or {}
    State.EspConnections[character].HighlightInstance = highlightClone

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if humanoid then
        if State.EspConnections[character] and State.EspConnections[character].DiedConnection then
             pcall(State.EspConnections[character].DiedConnection.Disconnect, State.EspConnections[character].DiedConnection)
        end
        State.EspConnections[character].DiedConnection = humanoid.Died:Connect(function()
            if highlightClone and highlightClone.Parent then
                pcall(highlightClone.Destroy, highlightClone)
            end
             if State.EspConnections[character] and State.EspConnections[character].DiedConnection then
                 pcall(State.EspConnections[character].DiedConnection.Disconnect, State.EspConnections[character].DiedConnection)
                 State.EspConnections[character].DiedConnection = nil
             end
        end)
    end
end

local function onEspCharacterAdded(character)
    task.defer(addHighlightToCharacter, character)
end

local function onEspPlayerAdded(plr)
    if plr == player then return end
    if not State.EspEnabled then return end

    if State.EspConnections[plr] and State.EspConnections[plr].CharacterAddedConnection then
        pcall(State.EspConnections[plr].CharacterAddedConnection.Disconnect, State.EspConnections[plr].CharacterAddedConnection)
    end

    State.EspConnections[plr] = State.EspConnections[plr] or {}
    State.EspConnections[plr].CharacterAddedConnection = plr.CharacterAdded:Connect(onEspCharacterAdded)

    if plr.Character then
        onEspCharacterAdded(plr.Character)
    end
end

local function onEspPlayerRemoving(plr)
    if State.EspConnections[plr] then
        if State.EspConnections[plr].CharacterAddedConnection then
            pcall(State.EspConnections[plr].CharacterAddedConnection.Disconnect, State.EspConnections[plr].CharacterAddedConnection)
        end
        if plr.Character then
            removeHighlightFromCharacter(plr.Character)
        end
        State.EspConnections[plr] = nil
    end
end

local function enableEsp()
    if State.EspEnabled then return end
    State.EspEnabled = true
    createHighlightTemplateEsp()

    if State.Connections.EspPlayerAdded then pcall(State.Connections.EspPlayerAdded.Disconnect, State.Connections.EspPlayerAdded) end
    if State.Connections.EspPlayerRemoving then pcall(State.Connections.EspPlayerRemoving.Disconnect, State.Connections.EspPlayerRemoving) end

    State.Connections.EspPlayerAdded = Players.PlayerAdded:Connect(onEspPlayerAdded)
    State.Connections.EspPlayerRemoving = Players.PlayerRemoving:Connect(onEspPlayerRemoving)

    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= player then
             onEspPlayerAdded(p)
        end
    end

    safeShowNotification("ESP Player", "Đã Bật", "ETC")
    if State.FluentElements.EspToggle then
        State.FluentElements.EspToggle:SetValue(true)
    end
end

local function disableEsp()
    if not State.EspEnabled then return end
    State.EspEnabled = false

    if State.Connections.EspPlayerAdded then pcall(State.Connections.EspPlayerAdded.Disconnect, State.Connections.EspPlayerAdded); State.Connections.EspPlayerAdded = nil end
    if State.Connections.EspPlayerRemoving then pcall(State.Connections.EspPlayerRemoving.Disconnect, State.Connections.EspPlayerRemoving); State.Connections.EspPlayerRemoving = nil end

    for obj, data in pairs(State.EspConnections) do
        if typeof(obj) == "Instance" then
            if obj:IsA("Player") then
                 if data.CharacterAddedConnection then pcall(data.CharacterAddedConnection.Disconnect, data.CharacterAddedConnection) end
                 if obj.Character then removeHighlightFromCharacter(obj.Character) end
            elseif obj:IsA("Model") and obj:FindFirstChild("Humanoid") then
                 removeHighlightFromCharacter(obj)
            end
        end
    end
    State.EspConnections = {}

    safeShowNotification("ESP Player", "Đã Tắt", "ETC")
    if State.FluentElements.EspToggle then
        State.FluentElements.EspToggle:SetValue(false)
    end
end

local function toggleEsp()
    if State.EspEnabled then
        disableEsp()
    else
        enableEsp()
    end
end

local function cleanup()
    print("Hx: Bắt đầu dọn dẹp...")
    if not _G.UnifiedAntiAFK_AutoClicker_Running then return end
    _G.UnifiedAntiAFK_AutoClicker_Running = false

    if State.AutoClicking then State.AutoClicking = false; autoClickCoroutine = nil; print("Hx: Đã dừng AutoClick coroutine.") end
    if State.ChoosingClickPos then endClickPositionChoice(true); print("Hx: Đã hủy chọn vị trí.") end
    if State.IsBindingHotkey then
        if State.Connections.HotkeyBinding then pcall(State.Connections.HotkeyBinding.Disconnect, State.Connections.HotkeyBinding) end
        State.IsBindingHotkey = false
        print("Hx: Đã hủy đặt hotkey.")
    end

    if State.EspEnabled then disableEsp(); print("Hx: Đã tắt ESP.") end
    State.LagReduced = false

    if State.MobileClickButtonInstance and State.MobileClickButtonInstance.Parent then pcall(State.MobileClickButtonInstance.Destroy, State.MobileClickButtonInstance); print("Hx: Đã xóa MobileClickButton.") end
    State.MobileClickButtonInstance = nil
    if State.ClickTargetMarkerInstance and State.ClickTargetMarkerInstance.Parent then pcall(State.ClickTargetMarkerInstance.Destroy, State.ClickTargetMarkerInstance); print("Hx: Đã xóa ClickTargetMarker.") end
    State.ClickTargetMarkerInstance = nil
    if State.ClickLockConfirmButton and State.ClickLockConfirmButton.Parent then pcall(State.ClickLockConfirmButton.Destroy, State.ClickLockConfirmButton); print("Hx: Đã xóa LockButton.") end
    State.ClickLockConfirmButton = nil
    if State.NotificationContainer and State.NotificationContainer.Parent then pcall(State.NotificationContainer.Destroy, State.NotificationContainer); print("Hx: Đã xóa NotificationContainer.") end
    State.NotificationContainer = nil
    if notificationTemplate then pcall(notificationTemplate.Destroy, notificationTemplate); notificationTemplate = nil; print("Hx: Đã xóa Notification Template.") end

    local disconnectedCount = 0
    for id, connection in pairs(State.Connections) do
        if connection and typeof(connection) == "RBXScriptConnection" then
            local success, err = pcall(connection.Disconnect, connection)
            if success then disconnectedCount = disconnectedCount + 1 else print("Hx: Lỗi disconnect connection '"..tostring(id).."':", err) end
        end
    end
    print("Hx: Đã ngắt " .. disconnectedCount .. " kết nối sự kiện.")
    State.Connections = {}

    if State.FluentWindow then
        pcall(State.FluentWindow.Destroy, State.FluentWindow)
        State.FluentWindow = nil
        print("Hx: Đã hủy cửa sổ Fluent.")
    end

    State.HighlightTemplate = nil
    State.FluentElements = {}
    State.EspConnections = {}

    print("Hx: Dọn dẹp hoàn tất.")
    _G.UnifiedAntiAFK_AutoClicker_CleanupFunction = nil
end
_G.UnifiedAntiAFK_AutoClicker_CleanupFunction = cleanup

local function isPositionOverFluentGui(position)
    if not State.FluentWindow or not State.FluentWindow.Enabled then return false end

    local guiToCheck = {}
    if State.FluentWindow.Parent then
        for _, child in ipairs(State.FluentWindow.Parent:GetChildren()) do
            if child:IsA("GuiObject") and child.Name ~= "HxNotificationContainer" then
                table.insert(guiToCheck, child)
            end
        end
    end
    if State.NotificationContainer and State.NotificationContainer.Parent then
        for _, child in ipairs(State.NotificationContainer:GetChildren()) do
            if child:IsA("GuiObject") then table.insert(guiToCheck, child) end
        end
    end
    if State.MobileClickButtonInstance and State.MobileClickButtonInstance.Parent then table.insert(guiToCheck, State.MobileClickButtonInstance) end
    if State.ChoosingClickPos then
        if State.ClickTargetMarkerInstance and State.ClickTargetMarkerInstance.Parent then table.insert(guiToCheck, State.ClickTargetMarkerInstance) end
        if State.ClickLockConfirmButton and State.ClickLockConfirmButton.Parent then table.insert(guiToCheck, State.ClickLockConfirmButton) end
    end

    for _, guiObject in ipairs(guiToCheck) do
        if guiObject.Visible and guiObject.AbsoluteSize.X > 0 and guiObject.AbsoluteSize.Y > 0 then
            local guiPos = guiObject.AbsolutePosition
            local guiSize = guiObject.AbsoluteSize
            if position.X >= guiPos.X and position.X <= guiPos.X + guiSize.X and
               position.Y >= guiPos.Y and position.Y <= guiPos.Y + guiSize.Y then
                return true
            end
        end
    end

    return false
end

local function performAntiAFKAction()
    if not Config.EnableIntervention then return end
    local actionType, success, errMsg = "", false, "?"
    local isGuiVisible = State.FluentWindow and State.FluentWindow.Enabled

    if isGuiVisible then
        actionType = "Jump"
        success, errMsg = pcall(function()
            VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game)
            task.wait(0.06)
            VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
        end)
    else
        actionType = "Click"
        local cam = Workspace.CurrentCamera
        if not cam then print("Hx: Lỗi AntiAFK - Không tìm thấy Camera."); return end
        local viewport = cam.ViewportSize
        local centerX, centerY = viewport.X / 2, viewport.Y / 2
        success, errMsg = pcall(function()
            VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, true, game, 0)
            task.wait(0.06)
            VirtualInputManager:SendMouseButtonEvent(centerX, centerY, 0, false, game, 0)
        end)
    end

    if not success then
        print("Hx: Lỗi AntiAFK Action (" .. actionType .. "):", errMsg)
        safeShowNotification("Lỗi Anti-AFK", "Không thể thực hiện hành động.", "AFK")
    else
        print("Hx: Thực hiện AntiAFK Action: " .. actionType)
        State.LastInterventionTime = os.clock()
        State.InterventionCounter = State.InterventionCounter + 1
    end
end

local function updateAFKStatusDisplay()
    local statusText
    local descriptionText = ""
    if not Config.EnableIntervention then
        statusText = "Anti-AFK: Đã Tắt"
        descriptionText = "Hệ thống chống AFK đang tắt."
    elseif State.IsConsideredAFK then
        statusText = "Anti-AFK: Đang AFK"
        local timeToNextAction = math.max(0, Config.InterventionInterval - (os.clock() - State.LastInterventionTime))
        descriptionText = string.format("Hành động tiếp theo sau ~%.0fs", timeToNextAction)
    else
        statusText = "Anti-AFK: Hoạt Động"
        descriptionText = string.format("Sẽ kích hoạt sau %d giây không hoạt động.", Config.AfkThreshold)
    end

    if State.FluentElements.AntiAFKToggle then
        print("Hx AFK Status:", statusText, "-", descriptionText)
    else
        print("Hx AFK Status:", statusText, "-", descriptionText)
    end
end

local function onInputDetected()
    local now = os.clock()
    if State.IsConsideredAFK then
        State.IsConsideredAFK = false
        State.LastInterventionTime = 0
        State.InterventionCounter = 0
        if Config.EnableIntervention then
            safeShowNotification("Anti-AFK", "Bạn đã quay lại!", "AFK")
        end
        updateAFKStatusDisplay()
    end
    State.LastInputTime = now
end

local function doAutoClick()
    local clickPos = State.SelectedClickPos
    while State.AutoClicking do
        local mousePos = UserInputService:GetMouseLocation()

        local isClickPosOverGui = isPositionOverFluentGui(clickPos)
        local isMousePosOverGui = isPositionOverFluentGui(mousePos)

        if not State.MobileButtonIsDragging and not isClickPosOverGui and not isMousePosOverGui then
            local success, err = pcall(function()
                if not State.AutoClicking then return end
                VirtualInputManager:SendMouseButtonEvent(clickPos.X, clickPos.Y, 0, true, game, 0)
                if not State.AutoClicking then return end
                task.wait(0.01)
                if not State.AutoClicking then return end
                VirtualInputManager:SendMouseButtonEvent(clickPos.X, clickPos.Y, 0, false, game, 0)
            end)
            if not success then
                print("Hx: Lỗi AutoClick SendMouseButtonEvent:", err)
                safeShowNotification("Lỗi Auto Click", "Đã dừng do lỗi.", "Clicker")
                stopClick()
                return
            end
        end

        if not State.AutoClicking then break end

        local delay = 1 / State.CurrentCPS
        if delay <= 0.001 then delay = 0.001 end
        task.wait(delay)
    end
    autoClickCoroutine = nil
    print("Hx: AutoClick coroutine kết thúc.")
end

local function startClick()
    if State.AutoClicking or State.ChoosingClickPos or State.IsBindingHotkey then return end
    State.AutoClicking = true
    safeShowNotification("Auto Clicker", string.format("Đã Bật (%.0f CPS)", State.CurrentCPS), "Clicker")
    if State.FluentElements.AutoClickToggle then State.FluentElements.AutoClickToggle:SetValue(true) end
    if autoClickCoroutine then task.cancel(autoClickCoroutine); autoClickCoroutine = nil end
    autoClickCoroutine = task.spawn(doAutoClick)
    print("Hx: AutoClick coroutine đã bắt đầu.")
end

local function stopClick()
    if not State.AutoClicking then return end
    State.AutoClicking = false
    safeShowNotification("Auto Clicker", "Đã Tắt", "Clicker")
    if State.FluentElements.AutoClickToggle then State.FluentElements.AutoClickToggle:SetValue(false) end
    print("Hx: AutoClick đã được yêu cầu dừng.")
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

local function endClickPositionChoice(cancelled)
    if not State.ChoosingClickPos then return end
    local connections = State.Connections

    if connections.ConfirmClickPos then pcall(connections.ConfirmClickPos.Disconnect, connections.ConfirmClickPos); connections.ConfirmClickPos = nil end
    if connections.CancelClickPosKey then pcall(connections.CancelClickPosKey.Disconnect, connections.CancelClickPosKey); connections.CancelClickPosKey = nil end

    if State.ClickTargetMarkerInstance and State.ClickTargetMarkerInstance.Parent then pcall(State.ClickTargetMarkerInstance.Destroy, State.ClickTargetMarkerInstance); State.ClickTargetMarkerInstance = nil end
    if State.ClickLockConfirmButton and State.ClickLockConfirmButton.Parent then pcall(State.ClickLockConfirmButton.Destroy, State.ClickLockConfirmButton); State.ClickLockConfirmButton = nil end

    State.ChoosingClickPos = false
    if cancelled then
        safeShowNotification("Chọn Vị Trí", "Đã hủy.", "Clicker")
    else
        safeShowNotification("Chọn Vị Trí", string.format("Đã khóa tại (%.0f, %.0f)", State.SelectedClickPos.X, State.SelectedClickPos.Y), "Clicker")
    end
    print("Hx: Kết thúc chọn vị trí click.", cancelled and "(Hủy)" or "(Xác nhận)")
end

local function confirmClickPosition()
    if not State.ChoosingClickPos then return end
    local marker = State.ClickTargetMarkerInstance
    if not marker or not marker.Parent then
        print("Hx: Lỗi xác nhận vị trí - Không tìm thấy marker.")
        endClickPositionChoice(true)
        return
    end
    local markerPos = marker.AbsolutePosition
    local markerSize = marker.AbsoluteSize
    State.SelectedClickPos = Vector2.new(markerPos.X + markerSize.X / 2, markerPos.Y + markerSize.Y / 2)
    endClickPositionChoice(false)
end

local function cancelClickPositionChoice()
    if State.ChoosingClickPos then
        endClickPositionChoice(true)
    end
end

local function startChoosingClickPos()
    if State.ChoosingClickPos or State.IsBindingHotkey then return end
    if State.AutoClicking then stopClick() end

    local screenGui = State.FluentWindow and State.FluentWindow.Parent
    if not screenGui then print("Hx: Lỗi - Không tìm thấy ScreenGui để đặt marker."); return end

    State.ChoosingClickPos = true

    local marker = Instance.new("Frame")
    marker.Name = "HxClickTargetMarker"
    marker.Size = UDim2.fromOffset(Config.ClickTargetMarkerSize, Config.ClickTargetMarkerSize)
    marker.Position = UDim2.new(0.5, -Config.ClickTargetMarkerSize / 2, 0.5, -Config.ClickTargetMarkerSize / 2)
    marker.AnchorPoint = Vector2.new(0, 0)
    marker.BackgroundColor3 = Config.ColorBorder
    marker.BackgroundTransparency = 0.5
    marker.BorderSizePixel = 1
    marker.BorderColor3 = Config.ColorClickTargetBorder
    marker.Active = true
    marker.Draggable = true
    marker.Parent = screenGui
    marker.ZIndex = 20
    Instance.new("UICorner", marker).CornerRadius = UDim.new(0.5, 0)
    State.ClickTargetMarkerInstance = marker

    local dot = Instance.new("Frame")
    dot.Name = "CenterDot"
    dot.Size = UDim2.fromOffset(Config.ClickTargetCenterDotSize, Config.ClickTargetCenterDotSize)
    dot.Position = UDim2.new(0.5, 0, 0.5, 0)
    dot.AnchorPoint = Vector2.new(0.5, 0.5)
    dot.BackgroundColor3 = Config.ColorClickTargetCenter
    dot.BorderSizePixel = 0
    dot.Parent = marker
    Instance.new("UICorner", dot).CornerRadius = UDim.new(0.5, 0)

    local guiInsetY = GuiService:GetGuiInset().Y
    local lockButton = Instance.new("ImageButton")
    lockButton.Name = "HxClickLockConfirmButton"
    lockButton.Size = UDim2.fromOffset(Config.LockButtonSize, Config.LockButtonSize)
    lockButton.Position = UDim2.new(0.5, -Config.LockButtonSize / 2, 0, guiInsetY + 15)
    lockButton.AnchorPoint = Vector2.new(0, 0)
    lockButton.Image = Config.IconLock
    lockButton.BackgroundColor3 = Config.ColorBackground
    lockButton.BackgroundTransparency = 0.5
    lockButton.BorderSizePixel = 1
    lockButton.BorderColor3 = Config.ColorBorder
    lockButton.Parent = screenGui
    lockButton.ZIndex = 21
    Instance.new("UICorner", lockButton).CornerRadius = UDim.new(0, 6)
    State.ClickLockConfirmButton = lockButton

    local connections = State.Connections
    if connections.ConfirmClickPos then pcall(connections.ConfirmClickPos.Disconnect, connections.ConfirmClickPos) end
    connections.ConfirmClickPos = lockButton.MouseButton1Click:Connect(confirmClickPosition)

    if connections.CancelClickPosKey then pcall(connections.CancelClickPosKey.Disconnect, connections.CancelClickPosKey) end
    connections.CancelClickPosKey = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        if State.ChoosingClickPos and not gameProcessedEvent and input.KeyCode == Enum.KeyCode.Escape then
            cancelClickPositionChoice()
        end
    end)

    safeShowNotification("Chọn Vị Trí", "Kéo hình tròn đến vị trí mong muốn, nhấn nút 🔒 để xác nhận (hoặc Esc để hủy).", "Clicker")
    print("Hx: Bắt đầu chọn vị trí click.")
end

local function startBindingHotkey()
    if State.IsBindingHotkey or State.ChoosingClickPos then return end
    if State.AutoClicking then stopClick() end

    State.IsBindingHotkey = true
    local hotkeyButton = State.FluentElements.HotkeyButton
    local originalTitle = hotkeyButton and hotkeyButton.Title or ("Hotkey (" .. State.AutoClickHotkey.Name .. ")")

    if hotkeyButton then hotkeyButton:SetTitle("Nhấn Phím...") end
    safeShowNotification("Đặt Hotkey", "Nhấn phím mong muốn để đặt hotkey (Nhấn '.' để hủy).", "Clicker")

    local connections = State.Connections
    if connections.HotkeyBinding then pcall(connections.HotkeyBinding.Disconnect, connections.HotkeyBinding); connections.HotkeyBinding = nil end

    local function endBinding(cancelled, newKey)
        if not State.IsBindingHotkey then return end
        if connections.HotkeyBinding then pcall(connections.HotkeyBinding.Disconnect, connections.HotkeyBinding); connections.HotkeyBinding = nil end
        State.IsBindingHotkey = false

        if cancelled then
            if hotkeyButton then hotkeyButton:SetTitle(originalTitle) end
            safeShowNotification("Đặt Hotkey", "Đã hủy.", "Clicker")
        else
            if newKey then
                State.AutoClickHotkey = newKey
                local newTitle = "Hotkey (" .. newKey.Name .. ")"
                if hotkeyButton then hotkeyButton:SetTitle(newTitle) end
                safeShowNotification("Đặt Hotkey", "Đã đặt thành: " .. newKey.Name, "Clicker")
                connectHotkeyListener()
            else
                 if hotkeyButton then hotkeyButton:SetTitle(originalTitle) end
                 safeShowNotification("Đặt Hotkey", "Lỗi không xác định.", "Clicker")
            end
        end
        if hotkeyButton then hotkeyButton.Visible = false; task.wait(); hotkeyButton.Visible = true end
    end

    connections.HotkeyBinding = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        if not State.IsBindingHotkey or gameProcessedEvent then return end

        if input.UserInputType == Enum.UserInputType.Keyboard then
            if input.KeyCode == Enum.KeyCode.Period then
                endBinding(true)
            elseif input.KeyCode ~= Enum.KeyCode.Unknown then
                endBinding(false, input.KeyCode)
            end
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
            safeShowNotification("Đặt Hotkey", "Vui lòng nhấn một phím trên bàn phím.", "Clicker")
        end
    end)
    print("Hx: Đang chờ nhấn phím để đặt hotkey...")
end

local function connectHotkeyListener()
    local connections = State.Connections
    if connections.HotkeyInputBegan then pcall(connections.HotkeyInputBegan.Disconnect, connections.HotkeyInputBegan); connections.HotkeyInputBegan = nil end
    if connections.HotkeyInputEnded then pcall(connections.HotkeyInputEnded.Disconnect, connections.HotkeyInputEnded); connections.HotkeyInputEnded = nil end

    if State.Platform ~= "PC" or not State.AutoClickHotkey or State.AutoClickHotkey == Enum.KeyCode.Unknown then
        print("Hx: Hotkey listener không được kết nối (Platform: " .. State.Platform .. ", Hotkey: " .. tostring(State.AutoClickHotkey) .. ")")
        return
    end

    print("Hx: Kết nối hotkey listener cho phím:", State.AutoClickHotkey.Name)

    connections.HotkeyInputBegan = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
        if gameProcessedEvent or State.IsBindingHotkey or State.ChoosingClickPos or State.Platform ~= "PC" or input.KeyCode ~= State.AutoClickHotkey then return end
        local focused = pcall(function() return UserInputService:GetFocusedTextBox() end)
        if focused then return end

        State.ClickTriggerActive = true
        triggerAutoClick()
    end)

    connections.HotkeyInputEnded = UserInputService.InputEnded:Connect(function(input, gameProcessedEvent)
        if State.Platform ~= "PC" or input.KeyCode ~= State.AutoClickHotkey then return end

        State.ClickTriggerActive = false
        if State.AutoClickMode == "Hold" then
            triggerAutoClick()
        end
    end)
end

local function connectMobileButtonListeners(button)
    local connections = State.Connections
    local buttonId = button.Name

    if connections["MobileButtonInputBegan_" .. buttonId] then pcall(connections["MobileButtonInputBegan_" .. buttonId].Disconnect, connections["MobileButtonInputBegan_" .. buttonId]) end
    if connections["MobileButtonInputEnded_" .. buttonId] then pcall(connections["MobileButtonInputEnded_" .. buttonId].Disconnect, connections["MobileButtonInputEnded_" .. buttonId]) end
    if connections["MobileButtonDragged_" .. buttonId] then pcall(connections["MobileButtonDragged_" .. buttonId].Disconnect, connections["MobileButtonDragged_" .. buttonId]) end

    local dragStartPos
    local buttonStartPos

    connections["MobileButtonInputBegan_" .. buttonId] = button.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
             if not State.MobileButtonLocked then
                 State.MobileButtonIsDragging = true
                 dragStartPos = input.Position
                 buttonStartPos = button.Position
                 button.BackgroundTransparency = 0.1
             else
                 State.ClickTriggerActive = true
                 triggerAutoClick()
             end
        end
    end)

    connections["MobileButtonInputEnded_" .. buttonId] = button.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 then
             if State.MobileButtonIsDragging then
                 State.MobileButtonIsDragging = false
                 button.BackgroundTransparency = 0.4
             end
             local wasActive = State.ClickTriggerActive
             State.ClickTriggerActive = false
             if State.AutoClickMode == "Hold" and State.MobileButtonLocked and wasActive then
                 triggerAutoClick()
             end
        end
    end)

    connections["MobileButtonDragged_" .. buttonId] = button.InputChanged:Connect(function(input)
        if State.MobileButtonIsDragging and (input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseMovement) then
             local delta = input.Position - dragStartPos
             button.Position = UDim2.new(buttonStartPos.X.Scale, buttonStartPos.X.Offset + delta.X, buttonStartPos.Y.Scale, buttonStartPos.Y.Offset + delta.Y)
        end
    end)
    print("Hx: Đã kết nối listener cho nút Mobile.")
end

local function createOrShowMobileButton()
    local screenGui = State.FluentWindow and State.FluentWindow.Parent
    if not screenGui then print("Hx: Lỗi tạo nút Mobile - Không tìm thấy ScreenGui."); return end

    if State.MobileClickButtonInstance and State.MobileClickButtonInstance.Parent then
        State.MobileClickButtonInstance.Visible = true
        State.MobileClickButtonInstance.Draggable = false
        print("Hx: Đã hiển thị nút Mobile hiện có.")
    else
        local button = Instance.new("ImageButton")
        button.Name = "HxMobileClickButton"
        button.Size = UDim2.fromOffset(Config.MobileButtonClickSize, Config.MobileButtonClickSize)
        button.Position = Config.MobileButtonDefaultPos
        button.Image = Config.IconMobileClickButton
        button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
        button.BackgroundTransparency = 0.4
        button.Active = true
        button.Selectable = true
        button.Draggable = false
        button.ZIndex = 15
        button.Parent = screenGui
        Instance.new("UICorner", button).CornerRadius = UDim.new(0.5, 0)
        State.MobileClickButtonInstance = button
        connectMobileButtonListeners(button)
        print("Hx: Đã tạo nút Mobile mới.")
    end
     if State.MobileClickButtonInstance then connectMobileButtonListeners(State.MobileClickButtonInstance) end
end

local function hideOrDestroyMobileButton()
    if State.MobileClickButtonInstance and State.MobileClickButtonInstance.Parent then
        local connections = State.Connections
        local buttonId = State.MobileClickButtonInstance.Name
        if connections["MobileButtonInputBegan_" .. buttonId] then pcall(connections["MobileButtonInputBegan_" .. buttonId].Disconnect, connections["MobileButtonInputBegan_" .. buttonId]); connections["MobileButtonInputBegan_" .. buttonId]=nil end
        if connections["MobileButtonInputEnded_" .. buttonId] then pcall(connections["MobileButtonInputEnded_" .. buttonId].Disconnect, connections["MobileButtonInputEnded_" .. buttonId]); connections["MobileButtonInputEnded_" .. buttonId]=nil end
        if connections["MobileButtonDragged_" .. buttonId] then pcall(connections["MobileButtonDragged_" .. buttonId].Disconnect, connections["MobileButtonDragged_" .. buttonId]); connections["MobileButtonDragged_" .. buttonId]=nil end

        pcall(State.MobileClickButtonInstance.Destroy, State.MobileClickButtonInstance)
        State.MobileClickButtonInstance = nil
        print("Hx: Đã hủy nút Mobile.")
    end
end

local function updatePlatformUI()
    local isPC = (State.Platform == "PC")
    print("Hx: Cập nhật UI cho Platform:", State.Platform)

    if State.FluentElements.HotkeyButton then State.FluentElements.HotkeyButton.Visible = isPC end
    if State.FluentElements.PC_Section then State.FluentElements.PC_Section.Visible = isPC end

    if State.FluentElements.MobileCreateButton then State.FluentElements.MobileCreateButton.Visible = not isPC end
    if State.FluentElements.MobileLockButton then State.FluentElements.MobileLockButton.Visible = not isPC end
    if State.FluentElements.MobileSection then State.FluentElements.MobileSection.Visible = not isPC end

    if isPC then
        hideOrDestroyMobileButton()
        connectHotkeyListener()
    else
        local connections = State.Connections
        if connections.HotkeyInputBegan then pcall(connections.HotkeyInputBegan.Disconnect, connections.HotkeyInputBegan); connections.HotkeyInputBegan = nil end
        if connections.HotkeyInputEnded then pcall(connections.HotkeyInputEnded.Disconnect, connections.HotkeyInputEnded); connections.HotkeyInputEnded = nil end
        print("Hx: Đã ngắt kết nối hotkey listener cho Mobile.")
    end
end

local function initialize()
    print("Hx: Bắt đầu initialize...")
    local initSuccess, initErr = pcall(function()

        unlockFPS()

        State.FluentWindow = Fluent:CreateWindow({
            Title = Config.GuiTitle,
            SubTitle = "Anti-AFK & AutoClicker",
            TabWidth = 160,
            Size = UDim2.fromOffset(550, 480),
            Acrylic = true,
            Theme = "Dark",
            MinimizeKey = Enum.KeyCode.RightControl
        })
        if not State.FluentWindow then error("Không thể tạo cửa sổ Fluent.") end

        if State.FluentWindow.Parent then State.FluentWindow.Parent.DisplayOrder = 1005 end

         if State.FluentWindow.Parent then
              setupNotificationContainer(State.FluentWindow.Parent)
              createNotificationTemplate()
         else
              warn("Hx: Không tìm thấy Fluent ScreenGui để đặt container thông báo.")
         end

        local Tabs = {
            AutoClicker = State.FluentWindow:AddTab({ Title = "Auto Clicker", Icon = "mouse" }),
            AntiAFK = State.FluentWindow:AddTab({ Title = "Anti-AFK", Icon = "timer" }),
            ESP = State.FluentWindow:AddTab({ Title = "ESP", Icon = "eye" }),
            Misc = State.FluentWindow:AddTab({ Title = "Khác", Icon = "settings" }),
            Config = State.FluentWindow:AddTab({ Title = "Lưu/Tải", Icon = "save" })
        }
        State.FluentElements.Tabs = Tabs

        do
            local AC_Section = Tabs.AutoClicker:AddSection("Điều Khiển Chính")
            State.FluentElements.AutoClickToggle = AC_Section:AddToggle("ACToggle", { Title = "Bật/Tắt Auto Click", Default = State.AutoClicking })
            State.FluentElements.AutoClickToggle:OnChanged(function(value)
                if State.AutoClicking ~= value then
                    State.AutoClicking = value
                    if value then startClick() else stopClick() end
                end
            end)

            State.FluentElements.ACModeDropdown = AC_Section:AddDropdown("ACMode", { Title = "Chế độ Click", Values = {"Toggle", "Hold"}, Default = State.AutoClickMode })
            State.FluentElements.ACModeDropdown:OnChanged(function(value)
                if State.AutoClickMode ~= value then
                    State.AutoClickMode = value
                    if State.AutoClicking then stopClick() end
                    State.ClickTriggerActive = false
                    print("Hx: Chế độ AutoClick đổi thành:", State.AutoClickMode)
                end
            end)

            State.FluentElements.CPS_Slider = AC_Section:AddSlider("ACCps", { Title = "Clicks Per Second (CPS)", Default = State.CurrentCPS, Min = Config.MinCPS, Max = Config.MaxCPS, Rounding = 0, Suffix = " CPS" })
            State.FluentElements.CPS_Slider:OnChanged(function(value)
                 if State.CurrentCPS ~= value then
                      State.CurrentCPS = value
                 end
            end)

            State.FluentElements.LocateButton = AC_Section:AddButton({ Title = "Chọn Vị Trí Click", Callback = startChoosingClickPos })

            local PC_Section = Tabs.AutoClicker:AddSection("Cài Đặt PC")
            State.FluentElements.PC_Section = PC_Section
            State.FluentElements.HotkeyButton = PC_Section:AddButton({ Id = "HotkeyButton", Title = "Hotkey (" .. State.AutoClickHotkey.Name .. ")", Callback = startBindingHotkey })

            local Mobile_Section = Tabs.AutoClicker:AddSection("Cài Đặt Mobile")
            State.FluentElements.MobileSection = Mobile_Section
            State.FluentElements.MobileCreateButton = Mobile_Section:AddButton({ Title = "Tạo/Hiện Nút Mobile", Callback = createOrShowMobileButton })
            State.FluentElements.MobileLockButton = Mobile_Section:AddToggle("MobileLock", { Title = "Khóa Vị Trí Nút", Default = State.MobileButtonLocked })
            State.FluentElements.MobileLockButton:OnChanged(function(value)
                 if State.MobileButtonLocked ~= value then
                      State.MobileButtonLocked = value
                      if State.MobileClickButtonInstance then
                           State.MobileClickButtonInstance.Draggable = false
                      end
                      local status = value and "Khóa (Sẵn sàng click)" or "Mở Khóa (Di chuyển)"
                      safeShowNotification("Nút Mobile", status, "Clicker")
                      if not value and State.AutoClicking then
                           stopClick()
                           safeShowNotification("Auto Clicker", "Đã tắt do mở khóa nút Mobile.", "Clicker")
                      end
                 end
            end)

             local Platform_Section = Tabs.AutoClicker:AddSection("Nền Tảng")
             State.FluentElements.PlatformDropdown = Platform_Section:AddDropdown("PlatformSelect", { Title = "Chọn Nền Tảng", Values = {"PC", "Mobile"}, Default = State.Platform })
             State.FluentElements.PlatformDropdown:OnChanged(function(value)
                  if State.Platform ~= value then
                        State.Platform = value
                        updatePlatformUI()
                  end
             end)
        end

        do
            local AFK_Section = Tabs.AntiAFK:AddSection("Cài Đặt Anti-AFK")
            State.FluentElements.AntiAFKToggle = AFK_Section:AddToggle("AntiAFKEnable", { Title = "Bật/Tắt Can Thiệp AFK", Default = Config.EnableIntervention })
            State.FluentElements.AntiAFKToggle:OnChanged(function(value)
                if Config.EnableIntervention ~= value then
                    Config.EnableIntervention = value
                    local status = value and "Bật" or "Tắt"
                    safeShowNotification("Anti-AFK", "Can thiệp tự động: " .. status, "AFK")
                    if not value and State.IsConsideredAFK then
                         State.IsConsideredAFK = false
                    end
                     updateAFKStatusDisplay()
                end
            end)
             updateAFKStatusDisplay()
        end

        do
            local ESP_Section = Tabs.ESP:AddSection("Player ESP")
            State.FluentElements.EspToggle = ESP_Section:AddToggle("EspEnable", { Title = "Bật/Tắt ESP", Default = State.EspEnabled })
            State.FluentElements.EspToggle:OnChanged(function(value)
                 if State.EspEnabled ~= value then
                      toggleEsp()
                 end
            end)
        end

        do
            local Misc_Section = Tabs.Misc:AddSection("Chức Năng Khác")
            State.FluentElements.ReduceLagButton = Misc_Section:AddButton({ Id="ReduceLagButton", Title = "Giảm Lag (1 lần)", Callback = function()
                 if not State.LagReduced then
                      reduceLag()
                 else
                      safeShowNotification("Giảm Lag", "Đã áp dụng. Khởi động lại script để hoàn tác.", "ETC")
                 end
            end})
        end

        do
            SaveManager:SetLibrary(Fluent)
            InterfaceManager:SetLibrary(Fluent)
            SaveManager:IgnoreThemeSettings()
            SaveManager:SetIgnoreIndexes({})

            local folderName = "HxScriptConfig_Fluent_v2"
            InterfaceManager:SetFolder(folderName)
            SaveManager:SetFolder(folderName .. "/configs")

            InterfaceManager:BuildInterfaceSection(Tabs.Config)
            SaveManager:BuildConfigSection(Tabs.Config)
        end

        State.FluentWindow:SelectTab(1)
        updatePlatformUI()
        connectHotkeyListener()

        local connections = State.Connections
        connections.InputBegan = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
            local focused = pcall(function() return UserInputService:GetFocusedTextBox() end)
            if focused or gameProcessedEvent or State.IsBindingHotkey or State.ChoosingClickPos then return end
            if State.Platform == "PC" and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == State.AutoClickHotkey then return end
            if input.UserInputType == Enum.UserInputType.Keyboard or input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.Touch then
                 onInputDetected()
            end
        end)

        connections.InputChanged = UserInputService.InputChanged:Connect(function(input, gameProcessedEvent)
            local focused = pcall(function() return UserInputService:GetFocusedTextBox() end)
            if focused or gameProcessedEvent or State.IsBindingHotkey or State.ChoosingClickPos then return end
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.MouseWheel or string.find(tostring(input.UserInputType), "Gamepad") then
                 onInputDetected()
            end
        end)

        if player then
             connections.CharacterRemoving = player.CharacterRemoving:Connect(function(character)
                  print("Hx: Nhân vật đang bị xóa.")
             end)
        end

        connections.PlayerRemoving = Players.PlayerRemoving:Connect(function(removedPlayer)
            if removedPlayer == player then
                print("Hx: Người chơi cục bộ rời đi, bắt đầu dọn dẹp...")
                cleanup()
            end
        end)

        task.wait(0.5)
        safeShowNotification(Config.GuiTitle, "Đã kích hoạt!", "System")
        print("Hx: Script đã khởi chạy với GUI Fluent.")
        print("Hx: Bắt đầu vòng lặp chính...")

        while _G.UnifiedAntiAFK_AutoClicker_Running do
            local loopSuccess, loopErr = pcall(function()
                 local currentTime = os.clock()
                 local timeSinceLastInput = currentTime - State.LastInputTime

                 if Config.EnableIntervention then
                      if State.IsConsideredAFK then
                           local timeSinceLastIntervention = currentTime - State.LastInterventionTime
                           local timeSinceLastCheck = currentTime - State.LastCheckTime

                           if timeSinceLastIntervention >= Config.InterventionInterval then
                                performAntiAFKAction()
                                State.LastCheckTime = currentTime
                           elseif timeSinceLastCheck >= Config.CheckInterval then
                                updateAFKStatusDisplay()
                                State.LastCheckTime = currentTime
                           end
                      else
                           if timeSinceLastInput >= Config.AfkThreshold then
                                State.IsConsideredAFK = true
                                State.LastInterventionTime = currentTime
                                State.LastCheckTime = currentTime
                                State.InterventionCounter = 0
                                local msg = string.format("Sẽ can thiệp sau ~%.0fs.", Config.InterventionInterval)
                                safeShowNotification("Cảnh Báo AFK!", msg, "AFK")
                                updateAFKStatusDisplay()
                           end
                      end
                 else
                      if State.IsConsideredAFK then
                           State.IsConsideredAFK = false
                           updateAFKStatusDisplay()
                      end
                 end
            end)
            if not loopSuccess then print("Hx: Lỗi trong vòng lặp chính:", loopErr) end
            task.wait(1)
        end
        print("Hx: Vòng lặp chính kết thúc.")

    end)

    if not initSuccess then
        print("Hx LỖI KHỞI TẠO NGHIÊM TRỌNG:", initErr)
        if initErr then print(debug.traceback()) end
        pcall(cleanup)
        _G.UnifiedAntiAFK_AutoClicker_Running = false
    end
end

task.spawn(initialize)
