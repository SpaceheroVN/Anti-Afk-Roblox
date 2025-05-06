-- =========================================================================
--                          INSTANCE CLEANUP CHECK
-- =========================================================================
if _G.HxV3_RunningInstance then
    if _G.HxV3_CleanupFunction then
        print("Hx Stable (Home 3.4): Phát hiện instance cũ...")
        pcall(_G.HxV3_CleanupFunction)
    end
end
_G.HxV3_RunningInstance = true
_G.HxV3_CleanupFunction = nil

-- =========================================================================
--                          LIBRARIES (Theo Mau.lua)
-- =========================================================================
print("Hx Stable (Home 3.4): Loading libraries...")
local Fluent, SaveManager, InterfaceManager
local load_success, load_error = pcall(function()
    Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
    SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
    InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()
    if not Fluent or not SaveManager or not InterfaceManager then
        error("Không thể tải một hoặc nhiều thư viện! F:"..tostring(Fluent~=nil)..", S:"..tostring(SaveManager~=nil)..", I:"..tostring(InterfaceManager~=nil))
    end
end)

-- =========================================================================
--                          HELPER: Notify (Cần định nghĩa sớm)
-- =========================================================================
local function Notify(content, title, duration)
    if not Fluent then warn("Notify bị gọi khi Fluent chưa được khởi tạo!"); return end
    pcall(Fluent.Notify, Fluent, { Title = title or "Hx", Content = content or "...", Duration = duration or 3 })
end

-- Xử lý lỗi tải thư viện
if not load_success then
    warn("Hx Stable (Home 3.4) FATAL: Lỗi khi tải thư viện:", load_error)
    Notify("Lỗi nghiêm trọng khi tải thư viện: " .. tostring(load_error) .. ". Script không thể tiếp tục.", "Hx FATAL Error", 10)
    _G.HxV3_RunningInstance = false
    return
end
print("Hx Stable (Home 3.4): Libraries loaded.")

-- =========================================================================
--                          SERVICES
-- =========================================================================
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService") -- Vẫn cần cho Settings
-- CoreGui, GuiService sẽ cần khi thêm Set Point

-- =========================================================================
--                          CONFIGURATION & STATE (Đến Bước 3.4)
-- =========================================================================
local CONFIG_FILENAME = "hx_settings_v3"
local HxSettings = {
    ESP_Enabled = false, AutoSave_Enabled = false, Theme = "Dark", Acrylic = true,
    AntiAFK_Enabled = true, AutoClick_Enabled = false, AutoClick_Platform = "Pc", -- Chỉ dùng để check Visible Keybind Setting
    AutoClick_CPS = 10, AutoClick_Mode = "Switch" -- Đã thêm Mode
    -- Các setting khác sẽ thêm sau
}
local player = Players.LocalPlayer
local MyWindow = nil; local MyTabs = {}; local Options = nil
local espToggle = nil; local minimizeBindPicker = nil; local antiAfkToggle = nil; local autoClickToggle = nil; local cpsControl = nil -- Khai báo các biến UI đã thêm
local connections = {}; local createdUIElements = {}
local antiAfkActive = HxSettings.AntiAFK_Enabled; local autoClickActive = HxSettings.AutoClick_Enabled

-- =========================================================================
--                          HELPER & CORE FUNCTIONS (Đến Bước 3.4)
-- =========================================================================
local function TryAutoSave() if not HxSettings.AutoSave_Enabled then return end; if not SaveManager or not SaveManager.SaveConfig then return end; local s, e = pcall(SaveManager.SaveConfig, SaveManager, CONFIG_FILENAME); if not s then warn("Hx AutoSave Error:", e) end end
local function reduceLag() Notify("Chức năng Giảm Lag đang phát triển.", "Hx") end
local function enableEsp() if HxSettings.ESP_Enabled then return end; HxSettings.ESP_Enabled = true; Notify("ESP Player: Đã Bật (UI Test)"); if espToggle then espToggle:SetValue(true) else warn("enableEsp: espToggle nil!") end; TryAutoSave() end
local function disableEsp() if not HxSettings.ESP_Enabled then return end; HxSettings.ESP_Enabled = false; Notify("ESP Player: Đã Tắt (UI Test)"); if espToggle then espToggle:SetValue(false) else warn("disableEsp: espToggle nil!") end; TryAutoSave() end
local function unlockFPS() Notify("Chức năng Unlock FPS đang phát triển.", "Hx") end
local function startClick() autoClickActive = true; HxSettings.AutoClick_Enabled = true; if autoClickToggle then autoClickToggle:SetValue(true) end; local cps = cpsControl and cpsControl.Value or HxSettings.AutoClick_CPS; Notify(string.format("Auto Clicker: Đã Bật (%.0f CPS) (UI Test)", cps)); TryAutoSave() end
local function stopClick() autoClickActive = false; HxSettings.AutoClick_Enabled = false; if autoClickToggle then autoClickToggle:SetValue(false) end; Notify("Auto Clicker: Đã Tắt (UI Test)"); TryAutoSave() end
-- Chưa cần các hàm phức tạp khác ở đây

-- =========================================================================
--                          GUI CREATION (Đến Home - Part 4)
-- =========================================================================
print("Hx Stable (Home 3.4): Creating GUI...")
local gui_create_success, gui_error = pcall(function()
    MyWindow = Fluent:CreateWindow({ Title = "Hx", SubTitle = "v3.0.0 (Home 3.4)", TabWidth = 160, Size = UDim2.fromOffset(580, 480), Acrylic = HxSettings.Acrylic, Theme = HxSettings.Theme, MinimizeKey = Enum.KeyCode.RightControl })
    if not MyWindow then error("Fluent:CreateWindow trả về nil!") end
    Options = Fluent.Options

    MyTabs = { Home = MyWindow:AddTab({ Title = "Home", Icon = "home" }), Misc = MyWindow:AddTab({ Title = "Misc", Icon = "list" }), Setting = MyWindow:AddTab({ Title = "Setting", Icon = "settings" }), Config = MyWindow:AddTab({ Title = "Config", Icon = "save" }) }
    print("Hx Stable (Home 3.4): Added tabs.")

    -- POPULATE MISC TAB (Xóa OnChanged)
    do local Section = MyTabs.Misc:AddSection("Utilities"); Section:AddButton({Title = "Reduces Lag", Callback = reduceLag}); espToggle = Section:AddToggle("ESP_Toggle", {Title = "ESP Player", Default = HxSettings.ESP_Enabled}); Section:AddButton({Title = "Unlock FPS", Callback = unlockFPS}); print("Hx Stable (Home 3.4): Misc Tab populated.") end

    -- POPULATE SETTING TAB (Xóa OnChanged, bỏ Server)
    do local Section = MyTabs.Setting:AddSection("Configuration"); local autoSaveToggle = Section:AddToggle("AutoSave_Toggle", {Title = "Auto Save", Default = HxSettings.AutoSave_Enabled}); local availableThemes = {"Dark", "Light", "Grey", "Midnight"}; if Fluent and Fluent.GetThemes then local s, t = pcall(Fluent.GetThemes, Fluent); if s and type(t) == "table" then availableThemes = t else warn("Hx Home: GetThemes failed.") end end; local themeDropdown = Section:AddDropdown("ThemeDropdown", { Title = "Theme", Values = availableThemes, Default = HxSettings.Theme, Callback = function(sel) if MyWindow then MyWindow:SetTheme(sel) end; HxSettings.Theme = sel; TryAutoSave() end }); local acrylicToggle = Section:AddToggle("AcrylicToggle", { Title = "Acrylic", Default = HxSettings.Acrylic, Callback = function(val) if MyWindow then MyWindow.Acrylic = val end; HxSettings.Acrylic = val; TryAutoSave() end }); minimizeBindPicker = Section:AddKeybind("MinimizeKeybindPicker", { Title = "Minimize Bind", Default = Enum.KeyCode.RightControl.Name, Visible = (HxSettings.AutoClick_Platform == "Pc"), AllowUnbind = true }); print("Hx Stable (Home 3.4): Setting Tab populated (no server section).") end

    -- POPULATE CONFIG TAB (Giữ nguyên)
    do if SaveManager and InterfaceManager and Fluent then SaveManager:SetLibrary(Fluent); InterfaceManager:SetLibrary(Fluent); SaveManager:IgnoreThemeSettings(); SaveManager:SetIgnoreIndexes({}); local folderName = "HxConfigFolder_v3"; InterfaceManager:SetFolder(folderName); SaveManager:SetFolder(folderName .. "/configs"); InterfaceManager:BuildInterfaceSection(MyTabs.Config); SaveManager:BuildConfigSection(MyTabs.Config); print("Hx Stable (Home 3.4): Config Tab populated.") else warn("Hx Stable (Home 3.4): Save/InterfaceManager missing. Config Tab skipped."); MyTabs.Config:AddParagraph("ConfigErrorPara", { Title = "Lỗi: Không thể tải addon Save/Load." }) end end

    -- POPULATE HOME TAB (Đến Part 3.4 - Mode Dropdown)
    do
        print("Hx Stable (Home 3.4): Populating Home Tab...")
        local Section = MyTabs.Home:AddSection("Automation")
        antiAfkToggle = Section:AddToggle("AntiAFK_Toggle", { Title = "Anti AFK", Default = HxSettings.AntiAFK_Enabled })
        autoClickToggle = Section:AddToggle("AutoClick_Toggle", { Title = "Auto Click", Default = HxSettings.AutoClick_Enabled })
        cpsControl = Section:AddSlider("AutoClick_CPS_Slider", { Title = "CPS", Default = HxSettings.AutoClick_CPS, Min = 1, Max = 100, Rounding = 0, Numeric = true })
        local modeDropdown = Section:AddDropdown("AutoClick_Mode_Dropdown", { Title = "Mode", Values = {"Switch", "Hold"}, Default = HxSettings.AutoClick_Mode })
        -- Xóa hết các OnChanged
        print("Hx Stable (Home 3.4): Added Home Tab elements up to Mode Dropdown.")
    end

end) -- Kết thúc pcall tạo GUI

if not gui_create_success then
    warn("Hx Stable (Home 3.4) FATAL: Lỗi tạo GUI:", gui_error); Notify("Lỗi tạo GUI: "..tostring(gui_error), "Hx GUI Error", 6)
    _G.HxV3_RunningInstance = false; if MyWindow then pcall(MyWindow.Destroy, MyWindow) end; return
end
if not MyWindow then
     warn("Hx Stable (Home 3.4) FATAL: MyWindow nil?"); Notify("Lỗi nghiêm trọng: Không thể tạo cửa sổ.", "Hx Critical Error", 6)
     _G.HxV3_RunningInstance = false; return
end
print("Hx Stable (Home 3.4): GUI Created successfully.")

-- =========================================================================
--                          INITIALIZATION & LOOPS (AutoLoad)
-- =========================================================================
print("Hx Stable (Home 3.4): Initializing...")
-- Không gọi UpdatePlatformUI vì chưa có Platform Dropdown
task.spawn(function()
    print("Hx Stable (Home 3.4): Attempting AutoLoad...")
    task.wait(1)
    if SaveManager and SaveManager.LoadConfig then
        local load_ok, load_msg = pcall(SaveManager.LoadConfig, SaveManager, CONFIG_FILENAME)
        if load_ok then
            Notify("Đã tự động tải cấu hình đã lưu.", "Hx AutoLoad", 3)
            if MyWindow then pcall(MyWindow.SetTheme, MyWindow, HxSettings.Theme); MyWindow.Acrylic = HxSettings.Acrylic end
            if espToggle then espToggle:SetValue(HxSettings.ESP_Enabled) end
            if antiAfkToggle then antiAfkToggle:SetValue(HxSettings.AntiAFK_Enabled) end
            if autoClickToggle then autoClickToggle:SetValue(HxSettings.AutoClick_Enabled) end
            if cpsControl then cpsControl:SetValue(HxSettings.AutoClick_CPS) end
            -- Mode/Platform Dropdown tự cập nhật
            antiAfkActive = HxSettings.AntiAFK_Enabled; autoClickActive = HxSettings.AutoClick_Enabled
            print("Hx Stable (Home 3.4): Applied loaded settings.")
        else
            print("Hx Stable (Home 3.4): No saved config or error:", load_msg)
            if espToggle then espToggle:SetValue(HxSettings.ESP_Enabled) end
            if antiAfkToggle then antiAfkToggle:SetValue(HxSettings.AntiAFK_Enabled) end
            if autoClickToggle then autoClickToggle:SetValue(HxSettings.AutoClick_Enabled) end
            if cpsControl then cpsControl:SetValue(HxSettings.AutoClick_CPS) end
        end
    else
        warn("Hx Stable (Home 3.4): SaveManager missing for AutoLoad.")
        if espToggle then espToggle:SetValue(HxSettings.ESP_Enabled) end
        if antiAfkToggle then antiAfkToggle:SetValue(HxSettings.AntiAFK_Enabled) end
        if autoClickToggle then autoClickToggle:SetValue(HxSettings.AutoClick_Enabled) end
        if cpsControl then cpsControl:SetValue(HxSettings.AutoClick_CPS) end
    end
end)

MyWindow:SelectTab(1) -- Chọn Tab Home

-- =========================================================================
--                          CLEANUP FUNCTION
-- =========================================================================
local function cleanup()
    print("Hx Stable (Home 3.4): Cleaning up..."); _G.HxV3_RunningInstance = false
    print("Hx Stable (Home 3.4): Disconnecting " .. #connections .. " connections...")
    for i, conn in pairs(connections) do if conn and conn.Connected then pcall(conn.Disconnect, conn) end end; connections = {}
    print("Hx Stable (Home 3.4): Destroying " .. #createdUIElements .. " created UI elements...")
    for i, element in pairs(createdUIElements) do if element and element.Parent then pcall(element.Destroy, element) end end; createdUIElements = {}
    if MyWindow then pcall(MyWindow.Destroy, MyWindow); MyWindow = nil end
    _G.HxV3_CleanupFunction = nil; print("Hx Stable (Home 3.4): Cleanup complete.")
end

-- =========================================================================
--                          FINALIZATION
-- =========================================================================
Notify("Hx v3.0 (Home 3.4 Stable) - Đã tải!", "Hx", 5)
print("Hx Stable (Home 3.4) Ready!")
_G.HxV3_CleanupFunction = cleanup
print("Hx Stable (Home 3.4): Init complete.")

-- KHÔNG CÓ 'end' Ở CUỐI CÙNG
