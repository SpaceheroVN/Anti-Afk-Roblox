-- this is beta hx_v3 not release
--[[
    Hx v3.0.0 GUI Script (Refactored for Clarity)
    Script tạo GUI bằng Fluent, tích hợp các chức năng:
    - FPS Unlocker
    - Lag Reducer
    - ESP Player
    - Anti-AFK
    - Auto Clicker (Switch/Hold, PC/Mobile, Click Point, Keybind)
    - Save/Load Settings (Single file config)
    - Instance Cleanup
]]

-- =========================================================================
--                            INSTANCE CLEANUP CHECK
-- =========================================================================
if _G.HxV3_RunningInstance then
    if _G.HxV3_CleanupFunction then
        print("Hx: Phát hiện instance cũ đang chạy. Thực hiện dọn dẹp...")
        local success, err = pcall(_G.HxV3_CleanupFunction)
        if not success then warn("Hx: Lỗi khi dọn dẹp instance cũ:", err) end
    else
        warn("Hx: Phát hiện instance cũ nhưng không tìm thấy hàm dọn dẹp.")
    end
end
_G.HxV3_RunningInstance = true
_G.HxV3_CleanupFunction = nil -- Sẽ được gán lại ở cuối

-- =========================================================================
--                            LIBRARIES & SERVICES
-- =========================================================================
print("Hx: Loading libraries...")
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

if not Fluent or not SaveManager or not InterfaceManager then
    warn("Hx FATAL: Không thể tải thư viện Fluent hoặc Addons! Script không thể tiếp tục.")
    _G.HxV3_RunningInstance = false -- Đánh dấu không chạy được
    return -- Dừng script hoàn toàn
end
print("Hx: Libraries loaded.")

-- Services
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local GuiService = game:GetService("GuiService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage") -- Thêm để require VIM

local VirtualInputManager = nil -- Sẽ require sau

-- =========================================================================
--                            CONFIGURATION & STATE
-- =========================================================================

-- ----- Fixed Configuration -----
local HxConfig = {
    EnableIntervention = true,
    AFKTimeoutSeconds = 180,
    AFKInterventionInterval = 30,
    ClickTargetMarkerSize = 30,
    ClickTargetCenterDotSize = 6,
    LockButtonSize = 40,
    MobileButtonClickSize = 60,
    IconLock = "rbxassetid://6614140577", -- Placeholder Lock Icon ID
    IconMobileClickButton = "rbxassetid://6709113759", -- Placeholder Mobile Button Icon ID
    -- Colors (Lấy từ theme Fluent sẽ tốt hơn, tạm dùng màu cố định)
    ColorBorder = Color3.fromRGB(80, 80, 80),
    ColorClickTargetBorder = Color3.fromRGB(255, 255, 255),
    ColorClickTargetCenter = Color3.fromRGB(255, 0, 0),
    ColorBackground = Color3.fromRGB(40, 40, 40),
    ColorTextPrimary = Color3.fromRGB(255, 255, 255),
    ColorTextSecondary = Color3.fromRGB(180, 180, 180),
    ColorToggleOn = Color3.fromRGB(0, 180, 0),
    ColorToggleOff = Color3.fromRGB(180, 0, 0),
}

-- ----- Player & Platform -----
local player = Players.LocalPlayer
local isMobile = UserInputService.TouchEnabled
local currentPlatform = isMobile and "Mobile" or "Pc"

-- ----- Persistent Settings (Saved to File) -----
local CONFIG_FILENAME = "hx_settings"
local HxSettings = {
    -- Auto Click
    AutoClick_CPS = 10,
    AutoClick_Mode = "Switch",
    AutoClick_Platform = currentPlatform, -- Mặc định theo platform hiện tại
    AutoClick_Bind = Enum.KeyCode.F,
    SelectedClickPos = Vector2.new(UserInputService:GetMouseLocation().X, UserInputService:GetMouseLocation().Y),
    IsMobileButtonCreated = false,
    MobileButtonPosition = UDim2.fromScale(0.2, 0.8),
    IsMobileButtonLocked = false,
    -- Misc
    ESP_Enabled = false,
    -- Setting
    AutoSave_Enabled = false,
}

-- ----- Runtime State (Not Saved) -----
local antiAfkActive = true         -- Anti-AFK on/off state
local autoClickActive = false      -- Auto Clicker on/off state
local isChoosingClickPos = false   -- Currently selecting click position?
local isBindingHotkey = false      -- Currently binding a hotkey?
local clickTriggerActive = false   -- Is the hotkey/mobile button currently held/active?
local mobileButtonIsDragging = false -- Is the mobile button being dragged?
local autoClickCoroutine = nil     -- Coroutine for the auto click loop
local lastInputTime = os.clock()   -- Last user input time for Anti-AFK
local lastInterventionTime = 0   -- Last Anti-AFK action time
local interventionCounter = 0    -- Anti-AFK action counter
local isConsideredAFK = false      -- Current AFK status

-- ----- UI References (Set during GUI creation) -----
local MyWindow = nil               -- Fluent Window instance
local MyTabs = {}                  -- Table to hold Fluent Tab instances
local Options = nil                -- Fluent Options reference
local targetIndicator = nil        -- Click position marker Frame
local mobileButton = nil           -- Mobile clicker button instance
local autoClickBindPicker = nil    -- Fluent Keybind Picker for Auto Click
local mobileButtonLockToggle = nil -- Fluent Toggle for locking mobile button
local platformDropdown = nil       -- Fluent Dropdown for platform selection
local cpsControl = nil             -- Fluent Slider for CPS
local autoClickToggle = nil        -- Fluent Toggle for Auto Click
local espToggle = nil              -- Fluent Toggle for ESP
local antiAfkToggle = nil          -- Fluent Toggle for Anti-AFK

-- ----- Resource Tracking for Cleanup -----
local connections = {}             -- Stores RBXScriptConnections
local createdUIElements = {}       -- Stores manually created UI Instances
local espHighlightTemplate = nil   -- Stores the ESP Highlight template
local espConnections = {}          -- Stores ESP-specific connections

-- =========================================================================
--                            HELPER FUNCTIONS
-- =========================================================================

-- Hàm kiểm tra và require VirtualInputManager
local function getVirtualInputManager()
    if not VirtualInputManager then
        local success, result = pcall(require, ReplicatedStorage:WaitForChild("VirtualInput", 10)) -- Chờ tối đa 10s
        if success then
            VirtualInputManager = result
            print("Hx: VirtualInputManager loaded.")
        else
            warn("Hx: Không tìm thấy hoặc không thể require VirtualInputManager:", result)
            if MyWindow then -- Chỉ thông báo nếu GUI đã tạo
                 Fluent:Notify({Title="Hx Error", Content="VirtualInputManager không có sẵn! Một số chức năng sẽ không hoạt động.", Duration=5})
            end
            VirtualInputManager = nil -- Đảm bảo là nil nếu lỗi
        end
    end
    return VirtualInputManager
end

-- Hàm thông báo ngắn gọn
local function Notify(content, title, duration)
    if not Fluent then return end
    Fluent:Notify({ Title = title or "Hx", Content = content or "...", Duration = duration or 3 })
end

-- Hàm kiểm tra vị trí có nằm trên GUI script không
local function isPositionOverScriptGui(position)
     if MyWindow and MyWindow.Enabled and MyWindow.AbsolutePosition and MyWindow.AbsoluteSize then
         local winPos, winSize = MyWindow.AbsolutePosition, MyWindow.AbsoluteSize
         if position.X >= winPos.X and position.X <= winPos.X + winSize.X and position.Y >= winPos.Y and position.Y <= winPos.Y + winSize.Y then
             return true
         end
     end
     if mobileButton and mobileButton.Visible and mobileButton.AbsolutePosition and mobileButton.AbsoluteSize then
         local btnPos, btnSize = mobileButton.AbsolutePosition, mobileButton.AbsoluteSize
          if position.X >= btnPos.X and position.X <= btnPos.X + btnSize.X and position.Y >= btnPos.Y and position.Y <= btnPos.Y + btnSize.Y then
             return true
         end
     end
    return false
end

-- Hàm lưu tự động (nếu bật)
local function TryAutoSave()
    if not HxSettings.AutoSave_Enabled or not SaveManager or not SaveManager.SaveConfig then return end
    local success, err = pcall(SaveManager.SaveConfig, SaveManager, CONFIG_FILENAME)
    if not success then warn("Hx AutoSave Error:", err) end
end

-- Hàm tải cấu hình
local function LoadHxConfig(configName)
     if not SaveManager or not SaveManager.LoadConfig then error("SaveManager:LoadConfig không tồn tại!") end
     local success, err_msg = pcall(SaveManager.LoadConfig, SaveManager, configName)

    if success then
        print("Hx: Loaded config '"..configName.."'")
        Notify("Đã tải cấu hình: " .. configName)

        -- Cập nhật UI và state không được Fluent quản lý trực tiếp
        if platformDropdown then UpdatePlatformUI() else warn("Hx LoadConfig: Platform Dropdown chưa sẵn sàng.") end
        connectHotkeyListener()
        if HxSettings.AutoClick_Platform == "Mobile" and HxSettings.IsMobileButtonCreated then createOrShowMobileButton()
        elseif HxSettings.AutoClick_Platform == "Pc" then hideOrDestroyMobileButton() end
        if HxSettings.ESP_Enabled then enableEsp() else disableEsp() end
    else
        warn("Hx Load Config Error:", err_msg)
        Notify("Lỗi khi tải cấu hình '"..configName.."': "..tostring(err_msg), "Hx Error", 4)
    end
    return success
end

-- =========================================================================
--                            CORE FEATURE FUNCTIONS
-- =========================================================================

-- ===== ✨ FPS Unlocker =====
local function unlockFPS()
    local vim = getVirtualInputManager()
    print("Hx: Attempting to unlock FPS...")
    local unlock_success, unlock_err = pcall(function()
        local cs = nil
        local settings_available, settings_obj = pcall(settings)
        if settings_available and typeof(settings_obj) == "table" then cs = settings_obj
        elseif typeof(settings) == "function" then
             settings_available, settings_obj = pcall(settings().GetService, settings(), "UserSettings")
             if settings_available and typeof(settings_obj) == "Instance" then cs = settings_obj end
        end
        if not cs then warn("Hx FPS Unlocker: Cannot access settings object."); return end
        local rs = cs.Rendering
        if not rs then warn("Hx FPS Unlocker: Cannot find Rendering settings."); return end
        if not pcall(function() local _=rs.FpsCap; return true end) then warn("Hx FPS Unlocker: FpsCap does not exist."); return end

        pcall(function() rs.FpsCap = 9999 end); task.wait(0.05);
        if pcall(function() return rs.FpsCap > 60 end) then print("Hx: FPS unlocked (Attempt 1)."); Notify("FPS đã unlock."); return end

        if vim and typeof(Stats) =="Instance" and Stats:FindFirstChild("PerformanceStats") then
            pcall(function() Stats.PerformanceStats.ReportFPS=false end); task.wait(0.05)
        end
        pcall(function() rs.FpsCap=9999 end); task.wait(0.05);

        if not pcall(function() return rs.FpsCap > 60 end) then
            print("Hx: Failed to unlock FPS.")
            Notify("FPS Unlocker: Không thể unlock.", "Hx Warning")
        else
             print("Hx: FPS unlocked (Attempt 2).")
             Notify("FPS Unlocker: Đã unlock.")
        end
    end)
    if not unlock_success then
        print("Hx: Error in unlockFPS:", unlock_err)
        Notify("Lỗi FPS Unlocker: " .. tostring(unlock_err), "Hx Error")
    end
end

-- ===== 📉 Lag Reducer =====
local function reduceLag()
    print("Hx: Attempting to reduce lag...")
    local settingsChangedCount = 0
    local lag_reduce_success, lag_reduce_err = pcall(function()
        local settings_available, settings_obj = pcall(settings)
        if settings_available and typeof(settings_obj) == "table" and settings_obj.Rendering then
             if pcall(function() settings_obj.Rendering.QualityLevel = Enum.QualityLevel.Level01 end) then settingsChangedCount = settingsChangedCount + 1 end
        elseif typeof(settings)=="function" then
             local us_ok, us = pcall(settings().GetService, settings(), "UserSettings")
             if us_ok and us and us:FindFirstChild("Rendering") then
                  if pcall(function() us.Rendering.QualityLevel = Enum.QualityLevel.Level01 end) then settingsChangedCount = settingsChangedCount + 1 end
             end
        end
        if Lighting then
            if pcall(function() Lighting.GlobalShadows = false end) then settingsChangedCount = settingsChangedCount + 1 end
            if pcall(function() Lighting.FogEnd = 100000 end) then settingsChangedCount = settingsChangedCount + 1 end
            if pcall(function() Lighting.EnvironmentDiffuseScale = 0 end) then settingsChangedCount = settingsChangedCount + 1 end
            if pcall(function() Lighting.EnvironmentSpecularScale = 0 end) then settingsChangedCount = settingsChangedCount + 1 end
            for _, effect in pairs(Lighting:GetChildren()) do
                if effect and effect:IsA("PostEffect") then
                    if pcall(function() effect.Enabled = false end) then settingsChangedCount = settingsChangedCount + 1 end
                end
            end
            local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere"); if atmosphere then if pcall(function() atmosphere.Enabled = false end) then settingsChangedCount = settingsChangedCount + 1 end end
            local clouds = Lighting:FindFirstChildOfClass("Clouds"); if clouds then if pcall(function() clouds.Enabled = false end) then settingsChangedCount = settingsChangedCount + 1 end end
            local sky = Lighting:FindFirstChildOfClass("Sky"); if sky then if pcall(function() sky.CelestialBodiesShown = false end) then settingsChangedCount = settingsChangedCount + 1 end end
        end
        local terrain = Workspace:FindFirstChild("Terrain")
        if terrain then
            if pcall(function() terrain.WaterWaveSize = 0 end) then settingsChangedCount = settingsChangedCount + 1 end
            if pcall(function() terrain.WaterWaveSpeed = 0 end) then settingsChangedCount = settingsChangedCount + 1 end
            if pcall(function() terrain.WaterReflectance = 0 end) then settingsChangedCount = settingsChangedCount + 1 end
            if pcall(function() terrain.WaterTransparency = 1 end) then settingsChangedCount = settingsChangedCount + 1 end
            if pcall(function() terrain.Decoration = false end) then settingsChangedCount = settingsChangedCount + 1 end
        end
        if settingsChangedCount > 0 then Notify("Đã áp dụng các cài đặt giảm lag.") else Notify("Giảm Lag: Không có cài đặt nào được thay đổi.") end
    end)
    if not lag_reduce_success then
        print("Hx: Error in reduceLag:", lag_reduce_err);
        Notify("Lỗi Giảm Lag: " .. tostring(lag_reduce_err), "Hx Error")
    end
end

-- ===== ✨ ESP Player Functions =====
-- (Các hàm ESP: createHighlightTemplateEsp, removeHighlightFromCharacter, addHighlightToCharacter, onEspCharacterAdded, onEspPlayerAdded, onEspPlayerRemoving, enableEsp, disableEsp được giữ nguyên logic nhưng dùng biến cục bộ và HxSettings)
local function createHighlightTemplateEsp()
    if espHighlightTemplate and espHighlightTemplate.Parent == nil then return espHighlightTemplate end
    if espHighlightTemplate then pcall(espHighlightTemplate.Destroy, espHighlightTemplate) end
    local ht = Instance.new("Highlight")
    ht.Name = "Highlight_ESP"; ht.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    ht.FillTransparency = 0.7; ht.OutlineTransparency = 0
    ht.FillColor = Color3.fromRGB(255, 0, 0); ht.OutlineColor = Color3.fromRGB(255, 255, 255)
    ht.Enabled = true; espHighlightTemplate = ht
    return ht
end
local function removeHighlightFromCharacter(character)
    if not character then return end; local hrp = character:FindFirstChild("HumanoidRootPart")
    if hrp then local h = hrp:FindFirstChild("Highlight_ESP"); if h then pcall(h.Destroy, h) end end
end
local function addHighlightToCharacter(character)
    if not HxSettings.ESP_Enabled or not character or character == player.Character then return end
    local template = createHighlightTemplateEsp(); if not template then return end
    local hrp = character:FindFirstChild("HumanoidRootPart"); if not hrp then return end
    if not hrp:FindFirstChild(template.Name) then
        local hClone = template:Clone(); hClone.Adornee = character; hClone.Parent = hrp
        local hum = character:FindFirstChildOfClass("Humanoid")
        if hum then
            local charEntry = espConnections[character] or {}
            if charEntry.DiedConnection and charEntry.DiedConnection.Connected then charEntry.DiedConnection:Disconnect() end
            charEntry.DiedConnection = hum.Died:Connect(function()
                if hClone and hClone.Parent then pcall(hClone.Destroy, hClone) end
                if espConnections[character] then
                     if espConnections[character].DiedConnection and espConnections[character].DiedConnection.Connected then pcall(espConnections[character].DiedConnection.Disconnect, espConnections[character].DiedConnection) end
                     espConnections[character] = nil
                end
            end)
            espConnections[character] = charEntry
        end
    end
end
local function onEspCharacterAdded(character) task.defer(addHighlightToCharacter, character) end
local function onEspPlayerAdded(plr)
    if not HxSettings.ESP_Enabled or plr == player then return end
    local playerEntry = espConnections[plr] or {}
    if playerEntry.CharacterAddedConnection and playerEntry.CharacterAddedConnection.Connected then playerEntry.CharacterAddedConnection:Disconnect() end
    playerEntry.CharacterAddedConnection = plr.CharacterAdded:Connect(onEspCharacterAdded)
    espConnections[plr] = playerEntry
    if plr.Character then onEspCharacterAdded(plr.Character) end
end
local function onEspPlayerRemoving(plr)
    local playerEntry = espConnections[plr]; if not playerEntry then return end
    if playerEntry.CharacterAddedConnection and playerEntry.CharacterAddedConnection.Connected then playerEntry.CharacterAddedConnection:Disconnect() end
    if plr.Character then
         removeHighlightFromCharacter(plr.Character)
         local charEntry = espConnections[plr.Character]
         if charEntry and charEntry.DiedConnection and charEntry.DiedConnection.Connected then charEntry.DiedConnection:Disconnect() end
         espConnections[plr.Character] = nil
    end
    espConnections[plr] = nil
end
local function enableEsp()
    if HxSettings.ESP_Enabled then return end; HxSettings.ESP_Enabled = true; print("Hx: Enabling ESP")
    createHighlightTemplateEsp()
    local pAddConn = espConnections["PlayerAdded"]; local pRemConn = espConnections["PlayerRemoving"]
    if pAddConn and pAddConn.Connected then pAddConn:Disconnect() end; if pRemConn and pRemConn.Connected then pRemConn:Disconnect() end
    espConnections["PlayerAdded"] = Players.PlayerAdded:Connect(onEspPlayerAdded); espConnections["PlayerRemoving"] = Players.PlayerRemoving:Connect(onEspPlayerRemoving)
    for _, p in ipairs(Players:GetPlayers()) do if p ~= player then onEspPlayerAdded(p) end end
    Notify("ESP Player: Đã Bật"); TryAutoSave()
    if espToggle and espToggle.Value ~= true then espToggle:SetValue(true) end
end
local function disableEsp()
    if not HxSettings.ESP_Enabled then return end; HxSettings.ESP_Enabled = false; print("Hx: Disabling ESP")
    local pAddConn = espConnections["PlayerAdded"]; local pRemConn = espConnections["PlayerRemoving"]
    if pAddConn and pAddConn.Connected then pAddConn:Disconnect(); espConnections["PlayerAdded"] = nil end
    if pRemConn and pRemConn.Connected then pRemConn:Disconnect(); espConnections["PlayerRemoving"] = nil end
    for target, entry in pairs(espConnections) do
        if typeof(target) == "Instance" then
            if target:IsA("Player") then
                if entry.CharacterAddedConnection and entry.CharacterAddedConnection.Connected then entry.CharacterAddedConnection:Disconnect() end
                if target.Character then removeHighlightFromCharacter(target.Character) end
            elseif target:IsA("Model") then
                removeHighlightFromCharacter(target)
                if entry.DiedConnection and entry.DiedConnection.Connected then entry.DiedConnection:Disconnect() end
            end
        end
    end; espConnections = {}
    Notify("ESP Player: Đã Tắt"); TryAutoSave()
    if espToggle and espToggle.Value ~= false then espToggle:SetValue(false) end
end

-- ===== 🛋️ Anti-AFK Functions =====
local function performAntiAFKAction()
    if not HxConfig.EnableIntervention then return end; local vim = getVirtualInputManager(); if not vim then return end
    local actionName, success = "", false; local guiVisibleState = MyWindow and MyWindow.Enabled or false
    if guiVisibleState then
        actionName="Jump"; success = pcall(function() vim:SendKeyEvent(true, Enum.KeyCode.Space, false, game); task.wait(0.06); vim:SendKeyEvent(false, Enum.KeyCode.Space, false, game); end)
    else
        actionName="Click"; local cam = Workspace.CurrentCamera; if not cam then return end; local vp = cam.ViewportSize; local cx, cy = vp.X / 2, vp.Y / 2;
        success = pcall(function() vim:SendMouseButtonEvent(cx, cy, 0, true, game, 0); task.wait(0.06); vim:SendMouseButtonEvent(cx, cy, 0, false, game, 0); end)
    end;
    if success then lastInterventionTime = os.clock(); interventionCounter = interventionCounter + 1; else print("Hx: Lỗi AntiAFK("..actionName..")"); Notify("Lỗi Anti-AFK", "Hx Anti-AFK", 2) end
end
local function onInputDetected()
    local now = os.clock(); if isConsideredAFK then isConsideredAFK = false; lastInterventionTime = 0; interventionCounter = 0; if HxConfig.EnableIntervention then Notify("Bạn đã quay lại!", "Hx Anti-AFK", 2) end; end; lastInputTime = now
end

-- ===== 🖱️ Auto Clicker Functions =====
-- (Các hàm Auto Click: doAutoClick, startClick, stopClick, triggerAutoClick, endClickPositionChoice, confirmClickPosition, cancelClickPositionChoice, startChoosingClickPos, endBinding, startBindingHotkey, connectHotkeyListener, connectMobileButtonListeners, createOrShowMobileButton, hideOrDestroyMobileButton, updatePlatformUI được giữ nguyên logic nhưng dùng biến cục bộ và HxSettings/HxConfig)
local function doAutoClick()
    local vim = getVirtualInputManager(); if not vim then autoClickActive = false; return end
    print("Hx AutoClick: Loop started.")
    while autoClickActive do
        local clickPos = HxSettings.SelectedClickPos; local mousePos = UserInputService:GetMouseLocation()
        if not mobileButtonIsDragging and not isPositionOverScriptGui(clickPos) and not isPositionOverScriptGui(mousePos) then
            local success, err = pcall(function()
                if not autoClickActive then return end; vim:SendMouseButtonEvent(clickPos.X, clickPos.Y, 0, true, game, 0);
                if not autoClickActive then return end; task.wait(0.01);
                if not autoClickActive then return end; vim:SendMouseButtonEvent(clickPos.X, clickPos.Y, 0, false, game, 0);
            end);
            if not success then print("Hx: AutoClick Error:", err); Notify("Lỗi Auto Click: " .. tostring(err), "Hx Error"); autoClickActive = false; if autoClickToggle then autoClickToggle:SetValue(false) end; return end
        end;
        if not autoClickActive then break end; local cps = cpsControl and cpsControl.Value or HxSettings.AutoClick_CPS; local delay = 1 / (cps > 0 and cps or 10); task.wait(delay)
    end; autoClickCoroutine = nil; print("Hx AutoClick: Loop stopped.")
    if autoClickToggle and autoClickToggle.Value ~= autoClickActive then autoClickToggle:SetValue(autoClickActive) end
end
local function startClick()
    if autoClickActive or isChoosingClickPos or isBindingHotkey then return end; autoClickActive = true;
    if autoClickToggle then autoClickToggle:SetValue(true) end; local cps = cpsControl and cpsControl.Value or HxSettings.AutoClick_CPS
    Notify(string.format("Auto Clicker: Đã Bật (%.0f CPS)", cps)); if autoClickCoroutine then task.cancel(autoClickCoroutine) end; autoClickCoroutine = task.spawn(doAutoClick)
end
local function stopClick()
    if not autoClickActive then return end; autoClickActive = false;
    if autoClickToggle then autoClickToggle:SetValue(false) end; Notify("Auto Clicker: Đã Tắt")
end
local function triggerAutoClick()
    if HxSettings.AutoClick_Mode == "Switch" then if autoClickActive then stopClick() else startClick() end
    elseif HxSettings.AutoClick_Mode == "Hold" then if clickTriggerActive and not autoClickActive then startClick() elseif not clickTriggerActive and autoClickActive then stopClick() end end
end
local function endClickPositionChoice(cancelled)
    if not isChoosingClickPos then return end;
    local confirmConn = connections["ConfirmClickPos"]; local cancelConn = connections["CancelClickPosKey"]
    if confirmConn and confirmConn.Connected then confirmConn:Disconnect(); connections["ConfirmClickPos"] = nil end
    if cancelConn and cancelConn.Connected then cancelConn:Disconnect(); connections["CancelClickPosKey"] = nil end
    local marker = CoreGui:FindFirstChild("CTM"); local lockBtn = CoreGui:FindFirstChild("LB")
    if marker then pcall(marker.Destroy, marker); table.removevalue(createdUIElements, marker) end
    if lockBtn then pcall(lockBtn.Destroy, lockBtn); table.removevalue(createdUIElements, lockBtn) end
    if MyWindow then MyWindow:Show() end; isChoosingClickPos = false;
    if cancelled then Notify("Chọn vị trí: Đã hủy.") else Notify(string.format("Chọn vị trí: Đã khóa (%.0f, %.0f)", HxSettings.SelectedClickPos.X, HxSettings.SelectedClickPos.Y)); TryAutoSave() end
end
local function confirmClickPosition() if not isChoosingClickPos then return end; local marker = CoreGui:FindFirstChild("CTM"); if not marker then endClickPositionChoice(true); return end; local markerPos, markerSize = marker.AbsolutePosition, marker.AbsoluteSize; HxSettings.SelectedClickPos = Vector2.new(markerPos.X + markerSize.X / 2, markerPos.Y + markerSize.Y / 2); endClickPositionChoice(false); end
local function cancelClickPositionChoice() if isChoosingClickPos then endClickPositionChoice(true) end
local function startChoosingClickPos()
    if isChoosingClickPos or isBindingHotkey then return end; if autoClickActive then stopClick() end; isChoosingClickPos = true;
    if MyWindow then MyWindow:Hide() end
    local marker = Instance.new("Frame"); marker.Name="CTM"; marker.Size=UDim2.fromOffset(HxConfig.ClickTargetMarkerSize,HxConfig.ClickTargetMarkerSize); marker.Position=UDim2.new(0.5,-HxConfig.ClickTargetMarkerSize/2, 0.5,-HxConfig.ClickTargetMarkerSize/2); marker.BackgroundColor3=HxConfig.ColorBorder; marker.BackgroundTransparency=0.5; marker.BorderSizePixel=1; marker.BorderColor3=HxConfig.ColorClickTargetBorder; marker.Active=true; marker.Draggable=true; marker.Parent=CoreGui; marker.ZIndex=1000; local mc=Instance.new("UICorner", marker); mc.CornerRadius=UDim.new(0.5,0); table.insert(createdUIElements, marker)
    local centerDot = Instance.new("Frame", marker); centerDot.Name="CD"; centerDot.Size=UDim2.fromOffset(HxConfig.ClickTargetCenterDotSize,HxConfig.ClickTargetCenterDotSize); centerDot.Position=UDim2.new(0.5,0,0.5,0); centerDot.AnchorPoint=Vector2.new(0.5,0.5); centerDot.BackgroundColor3=HxConfig.ColorClickTargetCenter; centerDot.BorderSizePixel=0; local dc=Instance.new("UICorner", centerDot); dc.CornerRadius=UDim.new(0.5,0);
    local topInset = GuiService:GetGuiInset().Y; local lockButton = Instance.new("ImageButton"); lockButton.Name="LB"; lockButton.Size=UDim2.fromOffset(HxConfig.LockButtonSize,HxConfig.LockButtonSize); lockButton.Position=UDim2.new(0.5, -HxConfig.LockButtonSize/2, 0, topInset+15); lockButton.Image=HxConfig.IconLock; lockButton.BackgroundColor3=HxConfig.ColorBackground; lockButton.BackgroundTransparency=0.3; lockButton.BorderSizePixel=1; lockButton.BorderColor3=HxConfig.ColorBorder; lockButton.Parent=CoreGui; lockButton.ZIndex=1001; local lc=Instance.new("UICorner", lockButton); lc.CornerRadius=UDim.new(0, 6); table.insert(createdUIElements, lockButton)
    connections["ConfirmClickPos"] = lockButton.MouseButton1Click:Connect(confirmClickPosition);
    connections["CancelClickPosKey"] = UserInputService.InputBegan:Connect(function(i, gp) if isChoosingClickPos and not gp and i.KeyCode == Enum.KeyCode.Escape then cancelClickPositionChoice() end end);
    Notify("Kéo hình tròn đến vị trí, nhấn 🔒 để xác nhận hoặc ESC để hủy.", nil, 5)
end
local function endBinding(cancelled, newKey)
    if not isBindingHotkey then return end; local bindingConn = connections["HotkeyBinding"]; if bindingConn and bindingConn.Connected then bindingConn:Disconnect(); connections["HotkeyBinding"] = nil end; isBindingHotkey = false;
    local currentBind = cancelled and HxSettings.AutoClick_Bind or newKey
    if autoClickBindPicker then pcall(autoClickBindPicker.SetText, autoClickBindPicker, "Hotkey: " .. currentBind.Name) end;
    if cancelled then Notify("Đặt Hotkey: Đã hủy.") else if newKey then HxSettings.AutoClick_Bind = newKey; Notify("Đặt Hotkey: Đã đặt thành " .. newKey.Name); connectHotkeyListener(); TryAutoSave() else Notify("Đặt Hotkey: Không nhận được phím hợp lệ.", "Hx Error"); connectHotkeyListener() end end
end
local function startBindingHotkey()
    if isBindingHotkey or isChoosingClickPos then return end; if autoClickActive then stopClick() end; isBindingHotkey = true;
    if autoClickBindPicker then pcall(autoClickBindPicker.SetText, autoClickBindPicker, "Nhấn phím...") end;
    Notify("Nhấn phím mới để đặt. Nhấn dấu chấm (.) để hủy.", nil, 5); local bindingConn = connections["HotkeyBinding"]; if bindingConn and bindingConn.Connected then bindingConn:Disconnect() end
    connections["HotkeyBinding"] = UserInputService.InputBegan:Connect(function(i, gp) if not isBindingHotkey or gp then return end; if i.UserInputType == Enum.UserInputType.Keyboard then if i.KeyCode == Enum.KeyCode.Period then endBinding(true) elseif i.KeyCode ~= Enum.KeyCode.Unknown then endBinding(false, i.KeyCode) end elseif i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.MouseButton2 then Notify("Vui lòng nhấn một phím trên bàn phím.") end end)
end
local function connectHotkeyListener()
    local beganConn = connections["HotkeyInputBegan"]; local endedConn = connections["HotkeyInputEnded"]; if beganConn and beganConn.Connected then beganConn:Disconnect() end; if endedConn and endedConn.Connected then endedConn:Disconnect() end; connections["HotkeyInputBegan"], connections["HotkeyInputEnded"] = nil, nil
    if HxSettings.AutoClick_Platform ~= "Pc" or not HxSettings.AutoClick_Bind or HxSettings.AutoClick_Bind == Enum.KeyCode.Unknown then return end;
    connections["HotkeyInputBegan"] = UserInputService.InputBegan:Connect(function(i, gp) local isTyping = pcall(function() return UserInputService:GetFocusedTextBox() end); if gp or isBindingHotkey or isChoosingClickPos or HxSettings.AutoClick_Platform ~= "Pc" or i.KeyCode ~= HxSettings.AutoClick_Bind or isTyping then return end; clickTriggerActive = true; triggerAutoClick() end);
    connections["HotkeyInputEnded"] = UserInputService.InputEnded:Connect(function(i, gp) if HxSettings.AutoClick_Platform ~= "Pc" or i.KeyCode ~= HxSettings.AutoClick_Bind then return end; clickTriggerActive = false; if HxSettings.AutoClick_Mode == "Hold" then triggerAutoClick() end end)
end
local function connectMobileButtonListeners(button)
    local baseName = "MobileButtonInput_"..button:GetFullName()
    local beganConn = connections[baseName.."Began"]; local endedConn = connections[baseName.."Ended"]; local dragBConn = connections[baseName.."DragB"]; local dragEConn = connections[baseName.."DragE"]
    if beganConn and beganConn.Connected then beganConn:Disconnect() end; if endedConn and endedConn.Connected then endedConn:Disconnect() end; if dragBConn and dragBConn.Connected then dragBConn:Disconnect() end; if dragEConn and dragEConn.Connected then dragEConn:Disconnect() end
    connections[baseName.."Began"] = button.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then task.wait(); if not mobileButtonIsDragging then if HxSettings.IsMobileButtonLocked then clickTriggerActive = true; triggerAutoClick() else Notify("Nút Mobile chưa khóa vị trí.") end end end end)
    connections[baseName.."Ended"] = button.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.Touch or i.UserInputType == Enum.UserInputType.MouseButton1 then local wasActive = clickTriggerActive; clickTriggerActive = false; if HxSettings.AutoClick_Mode == "Hold" and HxSettings.IsMobileButtonLocked and wasActive then triggerAutoClick() end; if mobileButtonIsDragging then mobileButtonIsDragging = false; pcall(function() button.BackgroundTransparency = 0.3 end); if HxSettings.MobileButtonPosition ~= button.Position then HxSettings.MobileButtonPosition = button.Position; TryAutoSave(); print("Hx Mobile Pos Saved:", HxSettings.MobileButtonPosition) end end end end)
    connections[baseName.."DragB"] = button.DragBegin:Connect(function() if not HxSettings.IsMobileButtonLocked then mobileButtonIsDragging = true; pcall(function() button.BackgroundTransparency = 0.1 end) end end)
end
local function createOrShowMobileButton()
    if mobileButton and mobileButton.Parent then mobileButton.Visible = true; mobileButton.Draggable = not HxSettings.IsMobileButtonLocked; connectMobileButtonListeners(mobileButton)
    else
        if mobileButton then pcall(mobileButton.Destroy, mobileButton) end
        mobileButton = Instance.new("TextButton"); mobileButton.Name = "HxMobileClickBtn"; mobileButton.Size = UDim2.fromOffset(HxConfig.MobileButtonClickSize, HxConfig.MobileButtonClickSize * 0.6); mobileButton.Position = HxSettings.MobileButtonPosition; mobileButton.Text = "CLICK"; mobileButton.TextColor3 = Color3.new(1,1,1); mobileButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50); mobileButton.BackgroundTransparency = 0.3; mobileButton.BorderSizePixel = 1; mobileButton.BorderColor3 = Color3.fromRGB(200,200,200); mobileButton.Font = Enum.Font.SourceSansSemibold; mobileButton.TextScaled = true; mobileButton.Active = true; mobileButton.Draggable = not HxSettings.IsMobileButtonLocked; mobileButton.Parent = CoreGui; mobileButton.ZIndex = 900; local c=Instance.new("UICorner", mobileButton); c.CornerRadius = UDim.new(0, 8); table.insert(createdUIElements, mobileButton)
        connectMobileButtonListeners(mobileButton); print("Hx: Mobile button created.")
    end; HxSettings.IsMobileButtonCreated = true; TryAutoSave()
end
local function hideOrDestroyMobileButton()
    if mobileButton and mobileButton.Parent then
        local baseName = "MobileButtonInput_"..mobileButton:GetFullName(); local beganConn = connections[baseName.."Began"]; local endedConn = connections[baseName.."Ended"]; local dragBConn = connections[baseName.."DragB"]; local dragEConn = connections[baseName.."DragE"]
        if beganConn and beganConn.Connected then pcall(beganConn.Disconnect, beganConn) end; if endedConn and endedConn.Connected then pcall(endedConn.Disconnect, endedConn) end; if dragBConn and dragBConn.Connected then pcall(dragBConn.Disconnect, dragBConn) end; if dragEConn and dragEConn.Connected then pcall(dragEConn.Disconnect, dragEConn) end
        pcall(mobileButton.Destroy, mobileButton); mobileButton = nil; table.removevalue(createdUIElements, mobileButton); print("Hx: Mobile button destroyed.")
    end; HxSettings.IsMobileButtonCreated = false; TryAutoSave()
end
local function updatePlatformUI()
    local isPcSelected = (HxSettings.AutoClick_Platform == "Pc"); print("Hx: Updating UI for platform:", HxSettings.AutoClick_Platform)
    if autoClickBindPicker then autoClickBindPicker:SetVisible(isPcSelected) end; local createBtn = MyTabs.Home and MyTabs.Home:GetOption("Mobile_CreateButton"); if createBtn then createBtn:SetVisible(not isPcSelected) end
    if mobileButtonLockToggle then mobileButtonLockToggle:SetVisible(not isPcSelected) end; local minBindPkr = MyTabs.Setting and MyTabs.Setting:GetOption("MinimizeKeybindPicker"); if minBindPkr then minBindPkr:SetVisible(isPcSelected) end
    if MyWindow then MyWindow.MinimizeKey = isPcSelected and (minBindPkr and minBindPkr.Value or Enum.KeyCode.RightControl) or Enum.KeyCode.Unknown end
    if isPcSelected then hideOrDestroyMobileButton(); connectHotkeyListener() else local beganConn = connections["HotkeyInputBegan"]; local endedConn = connections["HotkeyInputEnded"]; if beganConn and beganConn.Connected then beganConn:Disconnect(); connections["HotkeyInputBegan"] = nil end; if endedConn and endedConn.Connected then endedConn:Disconnect(); connections["HotkeyInputEnded"] = nil end; if HxSettings.IsMobileButtonCreated then createOrShowMobileButton() else hideOrDestroyMobileButton() end end
end

-- =========================================================================
--                            GUI CREATION
-- =========================================================================
print("Hx: Creating GUI...")
MyWindow = Fluent:CreateWindow({
    Title = "Hx", SubTitle = "v3.0.0", TabWidth = 160,
    Size = UDim2.fromOffset(580, 480), Acrylic = true, Theme = "Dark",
    MinimizeKey = Enum.KeyCode.Unknown -- Initial, will be updated
})
Options = Fluent.Options -- Get options after window creation

MyTabs = {
    Home = MyWindow:AddTab({ Title = "Home", Icon = "home" }),
    Misc = MyWindow:AddTab({ Title = "Misc", Icon = "list" }),
    Setting = MyWindow:AddTab({ Title = "Setting", Icon = "settings" }),
    Config = MyWindow:AddTab({ Title = "Config", Icon = "save" })
}

-- ----- Populate Home Tab -----
do
    local Section = MyTabs.Home:AddSection("Automation")
    antiAfkToggle = Section:AddToggle("AntiAFK_Toggle", {Title = "Anti AFK", Description = "Automatically prevent the machine from hanging", Default = antiAfkActive})
    local c1=antiAfkToggle:OnChanged(function() antiAfkActive = antiAfkToggle.Value; print("Hx Anti AFK State:", antiAfkActive); if antiAfkActive then lastInputTime = os.clock(); Notify("Anti-AFK: Đã Bật") else Notify("Anti-AFK: Đã Tắt") end end); table.insert(connections, c1)

    autoClickToggle = Section:AddToggle("AutoClick_Toggle", {Title = "Auto Click", Description = "Automatically click with the most complete features.", Default = autoClickActive})
    local c2=autoClickToggle:OnChanged(function() if autoClickToggle.Value then Notify("Auto Click Toggle: ON (Chờ kích hoạt)") else stopClick(); Notify("Auto Click Toggle: OFF") end end); table.insert(connections, c2)

    cpsControl = Section:AddSlider("AutoClick_CPS_Slider", {Title = "CPS", Description = "Your click speed per second.", Default = HxSettings.AutoClick_CPS, Min = 1, Max = 100, Rounding = 0, Compact = false, Numeric = true})
    local c3=cpsControl:OnChanged(function() HxSettings.AutoClick_CPS = cpsControl.Value; TryAutoSave() end); table.insert(connections, c3)

    local modeDropdown = Section:AddDropdown("AutoClick_Mode_Dropdown", {Title = "Mode", Description = "Your click mode.", Values = {"Switch", "Hold"}, Default = HxSettings.AutoClick_Mode})
    local c4=modeDropdown:OnChanged(function() HxSettings.AutoClick_Mode = modeDropdown.Value; TryAutoSave() end); table.insert(connections, c4)

    platformDropdown = Section:AddDropdown("AutoClick_Platform_Dropdown", {Title = "Platform", Description = "Your current device platform.", Values = {"Pc", "Mobile"}, Default = HxSettings.AutoClick_Platform})
    local c5=platformDropdown:OnChanged(function() local sel = platformDropdown.Value; if sel ~= currentPlatform then Notify("Nền tảng bạn chọn khác với phát hiện!", "Hx Warning", 5) end; HxSettings.AutoClick_Platform = sel; UpdatePlatformUI(); TryAutoSave() end); table.insert(connections, c5)

    Section:AddButton({Title = "Set Click Point", Description = "Click to select the position for auto-clicking.", Callback = startChoosingClickPos})

    autoClickBindPicker = Section:AddKeybind("AutoClick_Bind_KeyPicker", {Title = "Auto Click Bind", Description = "Press key to toggle Auto Click (. to unbind)", Default = HxSettings.AutoClick_Bind, Visible = (HxSettings.AutoClick_Platform == "Pc"), AllowUnbind = true})
    local c6=autoClickBindPicker:OnChanged(function(newKey) HxSettings.AutoClick_Bind = newKey; connectHotkeyListener(); TryAutoSave() end); table.insert(connections, c6) -- Use OnChanged for keybinds
    -- Section:AddButton({Title = "Change Hotkey", Description = "Click to set a new hotkey", Visible = (HxSettings.AutoClick_Platform == "Pc"), Callback = startBindingHotkey}) -- Removed redundant button

    local mobileGroup = Section:AddOptionsGroup("Mobile Controls", {Visible = (HxSettings.AutoClick_Platform == "Mobile")})
    mobileGroup:AddButton("Mobile_CreateButton",{Title = "Create/Show Button", Description = "Creates/Shows a draggable button", Callback = createOrShowMobileButton})
    mobileButtonLockToggle = mobileGroup:AddToggle("Mobile_LockPosition_Toggle", {Title = "Lock Pos", Description = "Prevent moving the mobile button.", Default = HxSettings.IsMobileButtonLocked})
    local c7=mobileButtonLockToggle:OnChanged(function() HxSettings.IsMobileButtonLocked = mobileButtonLockToggle.Value; if mobileButton and mobileButton.Parent then mobileButton.Draggable = not HxSettings.IsMobileButtonLocked end; TryAutoSave() end); table.insert(connections, c7)
end

-- ----- Populate Misc Tab -----
do
    local Section = MyTabs.Misc:AddSection("Utilities")
    Section:AddButton({Title = "Reduces Lag", Description = "Attempts to reduce game lag.", Callback = reduceLag})
    espToggle = Section:AddToggle("ESP_Toggle", {Title = "ESP Player", Description = "Shows player locations through walls.", Default = HxSettings.ESP_Enabled})
    local c8=espToggle:OnChanged(function() if espToggle.Value then enableEsp() else disableEsp() end end); table.insert(connections, c8)
    Section:AddButton({Title = "Unlock FPS", Description = "Attempts to remove the FPS cap.", Callback = unlockFPS})
end

-- ----- Populate Setting Tab -----
do
    local Section = MyTabs.Setting:AddSection("Configuration")
    local autoSaveToggle = Section:AddToggle("AutoSave_Toggle", {Title = "Auto Save", Description = "Automatically save settings changes", Default = HxSettings.AutoSave_Enabled})
    local c9=autoSaveToggle:OnChanged(function() HxSettings.AutoSave_Enabled = autoSaveToggle.Value; TryAutoSave() end); table.insert(connections, c9)

    Section:AddLabel("Appearance & Behavior")
    local themeDropdown = Section:AddDropdown("ThemeDropdown", {Title = "Theme", Values = Fluent:GetThemes(), Default = MyWindow.Theme or "Dark", Callback = function(t) MyWindow:SetTheme(t) end})
    local acrylicToggle = Section:AddToggle("AcrylicToggle", {Title = "Acrylic", Default = MyWindow.Acrylic or false, Callback = function(v) MyWindow.Acrylic = v end})
    local minimizeBindPicker = Section:AddKeybind("MinimizeKeybindPicker", {Title = "Minimize Bind", Description = "Key to hide/show GUI", Default = Enum.KeyCode.RightControl, Visible = (HxSettings.AutoClick_Platform == "Pc"), AllowUnbind = true})
    local c10=minimizeBindPicker:OnChanged(function(key) MyWindow.MinimizeKey = key end); table.insert(connections, c10) -- Use OnChanged

    local serverSection = MyTabs.Setting:AddSection("Server")
    serverSection:AddLabel("Job ID"):AddTooltip("Under development.")
    serverSection:AddLabel("Join Server"):AddTooltip("Under development.")
    serverSection:AddLabel("Copy Job"):AddTooltip("Under development.")
end

-- ----- Populate Config Tab -----
do
    SaveManager:SetLibrary(Fluent)
    InterfaceManager:SetLibrary(Fluent)
    SaveManager:IgnoreThemeSettings()
    SaveManager:SetIgnoreIndexes({})
    local folderName = "Hx"
    InterfaceManager:SetFolder(folderName)
    SaveManager:SetFolder(folderName .. "/configs")
    InterfaceManager:BuildInterfaceSection(MyTabs.Config)
    SaveManager:BuildConfigSection(MyTabs.Config)
end
print("Hx: GUI Created.")

-- =========================================================================
--                            INITIALIZATION & LOOPS
-- =========================================================================
print("Hx: Initializing...")

-- Try loading default config
task.spawn(function()
    task.wait(1.5)
    print("Hx: Attempting auto-load: '"..CONFIG_FILENAME.."'")
    if not LoadHxConfig(CONFIG_FILENAME) then
         print("Hx: No default config found. Applying defaults.")
         UpdatePlatformUI() -- Ensure UI matches default platform
         connectHotkeyListener() -- Connect default listener
         if HxSettings.AutoClick_Platform == "Mobile" and HxSettings.IsMobileButtonCreated then createOrShowMobileButton() end -- Create button if default says so
    end
    -- Update initial toggle states after load/defaults applied
    if antiAfkToggle then antiAfkToggle:SetValue(antiAfkActive) end
    if autoClickToggle then autoClickToggle:SetValue(autoClickActive) end
    if espToggle then espToggle:SetValue(HxSettings.ESP_Enabled) end -- Ensure ESP toggle matches loaded state

    -- Optional: Unlock FPS on start
    -- unlockFPS()
end)

-- Select initial tab
MyWindow:SelectTab(1)

-- Connect Anti-AFK input listener
local inputConn = UserInputService.InputBegan:Connect(onInputDetected)
table.insert(connections, inputConn)

-- Initialize Platform UI and Hotkey Listener
UpdatePlatformUI()
-- connectHotkeyListener() -- Called within UpdatePlatformUI

-- Start Anti-AFK Check Loop
task.spawn(function()
    while _G.HxV3_RunningInstance do
        task.wait(1)
        if antiAfkActive and HxConfig.EnableIntervention then
            local now = os.clock()
            if not isConsideredAFK and (now - lastInputTime > HxConfig.AFKTimeoutSeconds) then
                 isConsideredAFK = true; lastInterventionTime = 0; interventionCounter = 0; Notify("Đang AFK...", "Hx Anti-AFK", 3)
            elseif isConsideredAFK and (now - lastInterventionTime > HxConfig.AFKInterventionInterval) then
                 performAntiAFKAction()
            end
        elseif isConsideredAFK then isConsideredAFK = false end
    end
    print("Hx: Anti-AFK Loop stopped.")
end)

-- Final ready message
Notify("v3.0.0 - Đã tải thành công!", "Hx", 5)
print("Hx v3.0.0 GUI (Refactored) is ready!")

-- Assign cleanup function to global variable LAST
_G.HxV3_CleanupFunction = cleanup
print("Hx: Initialization complete.")
