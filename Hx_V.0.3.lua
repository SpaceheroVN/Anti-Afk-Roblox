--/==================================================================\
--||██╗  ██╗██╗  ██╗    ███████╗ ██████╗██████╗ ██╗██████╗ ████████╗||
--||██║  ██║╚██╗██╔╝    ██╔════╝██╔════╝██╔══██╗██║██╔══██╗╚══██╔══╝||
--||███████║ ╚███╔╝     ███████╗██║     ██████╔╝██║██████╔╝   ██║   ||
--||██╔══██║ ██╔██╗     ╚════██║██║     ██╔══██╗██║██╔═══╝    ██║   ||
--||██║  ██║██╔╝ ██╗    ███████║╚██████╗██║  ██║██║██║        ██║   ||
--||╚═╝  ╚═╝╚═╝  ╚═╝    ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝╚═╝        ╚═╝   ||
--\==================================================================/

--===== 🚀 Script Initialization & Reload Check =====--
if _G.UnifiedAntiAFK_AutoClicker_Running then
    if _G.UnifiedAntiAFK_AutoClicker_CleanupFunction then
        pcall(_G.UnifiedAntiAFK_AutoClicker_CleanupFunction); print("Hx: Dọn dẹp instance cũ.")
    end
end
_G.UnifiedAntiAFK_AutoClicker_Running = true

--===== 🔌 Services & Global Variables =====--
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

--===== ⚙️ Script Configuration =====--
local Config = {
    AfkThreshold = 300, InterventionInterval = 300, CheckInterval = 300, EnableIntervention = true, DefaultCPS = 20, MinCPS = 1, MaxCPS = 100,
    DefaultClickPos = Vector2.new(mouse.X, mouse.Y), DefaultAutoClickMode = "Toggle", DefaultPlatform = (UserInputService:GetPlatform() == Enum.Platform.Windows or UserInputService:GetPlatform() == Enum.Platform.OSX) and "PC" or "Mobile",
    DefaultHotkey = Enum.KeyCode.R, MobileButtonClickSize = 60, MobileButtonDefaultPos = UDim2.new(1, -80, 1, -80), ClickTargetMarkerSize = 60, ClickTargetCenterDotSize = 8,
    GuiTitle = "Hx_v2", NotificationDuration = 4, AnimationTime = 0.2, IconAntiAFK = "rbxassetid://117118515787811", IconAutoClicker = "rbxassetid://117118515787811",
    IconToggleButton = "rbxassetid://117118515787811", IconMobileClickButton = "rbxassetid://95151289125969", IconLock = "rbxassetid://114181737500273", IconETC = "rbxassetid://117118515787811", IconSystem = "rbxassetid://117118515787811",
    GuiWidth = 330, GuiHeight = 390,
    ToggleButtonSize = 40, LockButtonSize = 40, NotificationWidth = 250, NotificationHeight = 60, NotificationAnchor = Vector2.new(1, 1),
    NotificationPosition = UDim2.new(1, -18, 1, -48), ScrollbarThickness = 6, CPSBoxWidth = 80, TransparentToggleWidth = 110, TransparentBGLevel = 0.2, OpaqueBGLevel = 0, ButtonTransparentBGLevel = 0.1, ButtonOpaqueBGLevel = 0,
    ColorBackground = Color3.fromRGB(35, 35, 40), ColorBorder = Color3.fromRGB(80, 80, 90), ColorTextPrimary = Color3.fromRGB(245, 245, 245), ColorTextSecondary = Color3.fromRGB(190, 190, 200), ColorInputBackground = Color3.fromRGB(70, 70, 75),
    ColorButtonPrimary = Color3.fromRGB(80, 130, 210), ColorButtonSecondary = Color3.fromRGB(110, 110, 120), ColorToggleOn = Color3.fromRGB(70, 180, 70), ColorToggleOff = Color3.fromRGB(200, 70, 70), ColorSectionHeader = Color3.fromRGB(170, 200, 255),
    ColorScrollbar = Color3.fromRGB(100, 100, 110), ColorToggleCircleBorder = Color3.fromRGB(255, 255, 255), ColorClickTargetCenter = Color3.fromRGB(255, 0, 0), ColorClickTargetBorder = Color3.fromRGB(255, 255, 255), ColorButtonRed = Color3.fromRGB(200, 70, 70), ColorButtonGreen = Color3.fromRGB(70, 180, 70)
}
local TWEEN_INFO_FAST = TweenInfo.new(Config.AnimationTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out); local TWEEN_INFO_FAST_IN = TweenInfo.new(Config.AnimationTime, Enum.EasingStyle.Sine, Enum.EasingDirection.In)

--===== 📦 State Variables =====--
local State = {
    IsConsideredAFK = false, AutoClicking = false, ChoosingClickPos = false, IsBindingHotkey = false, ClickTriggerActive = false, MobileButtonIsDragging = false, GuiVisible = true, IsTransparent = true, MobileButtonLocked = false, LagReduced = false, EspEnabled = false,
    LastInputTime = os.clock(), LastInterventionTime = 0, LastCheckTime = 0, InterventionCounter = 0, CurrentCPS = Config.DefaultCPS, SelectedClickPos = Config.DefaultClickPos, AutoClickMode = Config.DefaultAutoClickMode, Platform = Config.DefaultPlatform, AutoClickHotkey = Config.DefaultHotkey,
    Connections = {}, EspConnections = {}, HighlightTemplate = nil,
    GuiElements = { ScreenGui = nil, MainFrame = nil, ScrollingFrame = nil, ContentListLayout = nil, GuiToggleButton = nil, TitleBarFrame = nil, TransparentToggle = nil, CircleIndicator = nil, TransparentTextButton = nil, MobileClickButton = nil, NotificationContainer = nil, ClickTargetMarker = nil, LockButton = nil, AutoClicker = { Toggle = nil, ModeGroup = nil, PlatformGroup = nil, CpsLocateFrame = nil, CPSBox = nil, LocateButton = nil, HotkeyButton = nil, MobileCreateButton = nil, MobileLockToggle = nil, ModeButtons = {}, PlatformButtons = {} }, ETC = { EtcButtonFrame = nil, ReducesLagButton = nil, AntiAFKToggleButton = nil, EspPlayerButton = nil, AFKStatusLabel = nil } },
    TransparencyTargets = {}, SliderSupported = false
}
local autoClickCoroutine = nil

--===== ✨ FPS Unlocker =====--
local function unlockFPS() local unlock_success, unlock_err = pcall(function() if not settings then return end; local cs = settings(); if not cs then return end; local rs = cs.Rendering; if not rs then return end; local cap_exists,_=pcall(function() local _=rs.FpsCap; return true end); if not cap_exists then return end; local s1,_=pcall(function() rs.FpsCap=9999 end);task.wait(0.1); local r1,c1=pcall(function() return rs.FpsCap end); if r1 and c1 and c1>60 then return end; if typeof(Stats.PerformanceStats)=="Instance" then pcall(function() Stats.PerformanceStats.ReportFPS=false end);task.wait(0.1) end; local s2,_=pcall(function() rs.FpsCap=9999 end);task.wait(0.1); local r2,c2=pcall(function() return rs.FpsCap end); if not (r2 and c2 and c2>60) then print("Hx: Không thể unlock FPS.") end end); if not unlock_success then print("Hx: Lỗi unlockFPS:", unlock_err) end end

--===== 🔔 Notification System =====--
local notificationTemplate=nil; local function showNotification(t,m,i) if not _G.UnifiedAntiAFK_AutoClicker_Running then return end;local s,e=pcall(function() local c=State.GuiElements.NotificationContainer;if not c or not c.Parent then c=setupNotificationContainer(State.GuiElements.ScreenGui);if not c or not c.Parent then print("Hx: Lỗi container thông báo.");return end end;local p=notificationTemplate or createNotificationTemplate();if not p then print("Hx: Lỗi template thông báo.");return end;local n=p:Clone();if not n then return end;local o,f=n:FindFirstChild("Icon"),n:FindFirstChild("TextFrame");local l,a=f and f:FindFirstChild("Title"),f and f:FindFirstChild("Message");if not (o and l and a) then pcall(n.Destroy,n);print("Hx: Lỗi cấu trúc template.");return end;l.Text=t or "TB";a.Text=m or "";if i=="AFK" then o.Image=Config.IconAntiAFK elseif i=="Clicker" then o.Image=Config.IconAutoClicker elseif i=="ETC" then o.Image=Config.IconETC elseif i=="System" then o.Image=Config.IconSystem else o.Image=Config.IconAntiAFK end;n.Name="N_"..(t or "D"):gsub("%s+","");n.Parent=c;local g,u={BackgroundTransparency=0.1,ImageTransparency=0,TextTransparency=0},{BackgroundTransparency=1,ImageTransparency=1,TextTransparency=1};pcall(function() TweenService:Create(n,TWEEN_INFO_FAST,{BackgroundTransparency=g.BackgroundTransparency}):Play() end);pcall(function() TweenService:Create(o,TWEEN_INFO_FAST,{ImageTransparency=g.ImageTransparency}):Play() end);pcall(function() TweenService:Create(l,TWEEN_INFO_FAST,{TextTransparency=g.TextTransparency}):Play() end);pcall(function() TweenService:Create(a,TWEEN_INFO_FAST,{TextTransparency=g.TextTransparency}):Play() end);task.delay(Config.NotificationDuration,function() if not n or not n.Parent then return end;local s2,e2=pcall(function() local b,k,T,M=TweenService:Create(n,TWEEN_INFO_FAST_IN,{BackgroundTransparency=u.BackgroundTransparency}),TweenService:Create(o,TWEEN_INFO_FAST_IN,{ImageTransparency=u.ImageTransparency}),TweenService:Create(l,TWEEN_INFO_FAST_IN,{TextTransparency=u.TextTransparency}),TweenService:Create(a,TWEEN_INFO_FAST_IN,{TextTransparency=u.TextTransparency});local d="NC_"..n.Name;if State.Connections[d] then pcall(State.Connections[d].Disconnect,State.Connections[d]) end;State.Connections[d]=b.Completed:Connect(function() if n and n.Parent then pcall(n.Destroy,n) end;if State.Connections[d] then pcall(State.Connections[d].Disconnect,State.Connections[d]);State.Connections[d]=nil end end);b:Play();k:Play();T:Play();M:Play() end);if not s2 then print("Hx: Lỗi fade out:",e2);if n and n.Parent then pcall(n.Destroy,n) end end end) end);if not s then print("Hx: Lỗi showNotification:",e) end end
local function safeShowNotification(...) local s,e=pcall(showNotification,...);if not s then print("Hx: Lỗi safeShowNotification:",e) end end
local function createNotificationTemplate() if notificationTemplate then return notificationTemplate end;local f=Instance.new("Frame");f.Name="NFT";f.BackgroundColor3=Color3.fromRGB(40,40,45);f.BackgroundTransparency=1;f.BorderSizePixel=1;f.BorderColor3=Config.ColorBorder;f.Size=UDim2.new(0,Config.NotificationWidth,0,Config.NotificationHeight);f.ClipsDescendants=true;local c=Instance.new("UICorner",f);c.CornerRadius=UDim.new(0,8);local p=Instance.new("UIPadding",f);p.PaddingLeft=UDim.new(0,10);p.PaddingRight=UDim.new(0,10);p.PaddingTop=UDim.new(0,5);p.PaddingBottom=UDim.new(0,5);local l=Instance.new("UIListLayout",f);l.FillDirection=Enum.FillDirection.Horizontal;l.VerticalAlignment=Enum.VerticalAlignment.Center;l.SortOrder=Enum.SortOrder.LayoutOrder;l.Padding=UDim.new(0,10);local i=Instance.new("ImageLabel");i.Name="Icon";i.Image=Config.IconAntiAFK;i.BackgroundTransparency=1;i.ImageTransparency=1;i.Size=UDim2.new(0,35,0,35);i.LayoutOrder=1;i.Parent=f;local t=Instance.new("Frame");t.Name="TextFrame";t.BackgroundTransparency=1;t.Size=UDim2.new(1,-55,1,0);t.LayoutOrder=2;t.Parent=f;local tl=Instance.new("UIListLayout",t);tl.FillDirection=Enum.FillDirection.Vertical;tl.HorizontalAlignment=Enum.HorizontalAlignment.Left;tl.VerticalAlignment=Enum.VerticalAlignment.Center;tl.SortOrder=Enum.SortOrder.LayoutOrder;tl.Padding=UDim.new(0,2);local tt=Instance.new("TextLabel");tt.Name="Title";tt.Text="T";tt.Font=Enum.Font.SourceSansBold;tt.TextSize=17;tt.TextColor3=Config.ColorTextPrimary;tt.BackgroundTransparency=1;tt.TextTransparency=1;tt.TextXAlignment=Enum.TextXAlignment.Left;tt.Size=UDim2.new(1,0,0,20);tt.LayoutOrder=1;tt.Parent=t;local m=Instance.new("TextLabel");m.Name="Message";m.Text="M";m.Font=Enum.Font.SourceSans;m.TextSize=14;m.TextColor3=Config.ColorTextSecondary;m.BackgroundTransparency=1;m.TextTransparency=1;m.TextXAlignment=Enum.TextXAlignment.Left;m.TextWrapped=true;m.Size=UDim2.new(1,0,0.6,0);m.LayoutOrder=2;m.Parent=t;notificationTemplate=f;return notificationTemplate end
local function setupNotificationContainer(p) if State.GuiElements.NotificationContainer and State.GuiElements.NotificationContainer.Parent then return State.GuiElements.NotificationContainer end;local c=Instance.new("Frame");c.Name="NCC";c.AnchorPoint=Config.NotificationAnchor;c.Position=Config.NotificationPosition;c.Size=UDim2.new(0,Config.NotificationWidth+20,0,300);c.BackgroundTransparency=1;c.Parent=p;local l=Instance.new("UIListLayout",c);l.FillDirection=Enum.FillDirection.Vertical;l.HorizontalAlignment=Enum.HorizontalAlignment.Right;l.VerticalAlignment=Enum.VerticalAlignment.Bottom;l.SortOrder=Enum.SortOrder.LayoutOrder;l.Padding=UDim.new(0,5);State.GuiElements.NotificationContainer=c;return c end

--===== 📉 Lag Reducer =====--
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
        safeShowNotification("Giảm Lag", "Đã giảm lag thành công.", "ETC")
        State.LagReduced = true
    end)
    if not lag_reduce_success then print("Hx: Lỗi reduceLag:", lag_reduce_err); safeShowNotification("Lỗi Giảm Lag", "Có lỗi xảy ra.", "ETC") end
end

--===== ✨ ESP Player Functions =====--
local function createHighlightTemplateEsp()
    if State.HighlightTemplate then return State.HighlightTemplate end
    local ht = Instance.new("Highlight")
    ht.Name = "Highlight_ESP"
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
        local highlight = hrp:FindFirstChild("Highlight_ESP")
        if highlight then
            pcall(highlight.Destroy, highlight)
        end
    end
end

local function addHighlightToCharacter(character)
    if not State.EspEnabled or not character then return end
    local template = createHighlightTemplateEsp()
    if not template then return end
    local humanoidRootPart = character:WaitForChild("HumanoidRootPart", 5)
    if not humanoidRootPart then return end
    if not humanoidRootPart:FindFirstChild(template.Name) then
        local highlightClone = template:Clone()
        highlightClone.Adornee = character
        highlightClone.Parent = humanoidRootPart
        if not State.EspConnections[character] then State.EspConnections[character] = {} end
        State.EspConnections[character].HighlightInstance = highlightClone
        local humanoid = character:FindFirstChildOfClass("Humanoid")
        if humanoid then
             local diedConnection = humanoid.Died:Connect(function()
                 if highlightClone and highlightClone.Parent then
                     pcall(highlightClone.Destroy, highlightClone)
                 end
                 if State.EspConnections[character] and State.EspConnections[character].DiedConnection then
                     pcall(State.EspConnections[character].DiedConnection.Disconnect, State.EspConnections[character].DiedConnection)
                     State.EspConnections[character].DiedConnection = nil
                 end
             end)
            State.EspConnections[character].DiedConnection = diedConnection
        end
    end
end

local function onEspCharacterAdded(character)
    task.defer(addHighlightToCharacter, character)
end

local function onEspPlayerAdded(plr)
    if not State.EspEnabled then return end
    local charAddedConn = plr.CharacterAdded:Connect(onEspCharacterAdded)
    State.EspConnections[plr] = State.EspConnections[plr] or {}
    State.EspConnections[plr].CharacterAddedConnection = charAddedConn
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

local function updateEspButtonState()
    local btn = State.GuiElements.ETC.EspPlayerButton
    if not btn then return end
    local bT = State.IsTransparent and Config.ButtonTransparentBGLevel or Config.ButtonOpaqueBGLevel
    if State.EspEnabled then
        btn.Text = "ESP: ON" -- Shortened
        pcall(function() btn.BackgroundColor3 = Config.ColorToggleOn end)
        pcall(function() btn.BackgroundTransparency = bT end)
    else
        btn.Text = "ESP: OFF" -- Shortened
        pcall(function() btn.BackgroundColor3 = Config.ColorToggleOff end)
        pcall(function() btn.BackgroundTransparency = bT end)
    end
end

local function enableEsp()
    if State.EspEnabled then return end
    State.EspEnabled = true
    createHighlightTemplateEsp()
    if State.Connections.EspPlayerAdded then
        pcall(State.Connections.EspPlayerAdded.Disconnect, State.Connections.EspPlayerAdded)
    end
    State.Connections.EspPlayerAdded = Players.PlayerAdded:Connect(onEspPlayerAdded)
    if State.Connections.EspPlayerRemoving then
         pcall(State.Connections.EspPlayerRemoving.Disconnect, State.Connections.EspPlayerRemoving)
     end
     State.Connections.EspPlayerRemoving = Players.PlayerRemoving:Connect(onEspPlayerRemoving)
    for _, p in ipairs(Players:GetPlayers()) do
        onEspPlayerAdded(p)
    end
    updateEspButtonState()
    safeShowNotification("ESP Player", "Đã Bật", "ETC")
end

local function disableEsp()
    if not State.EspEnabled then return end
    State.EspEnabled = false
    if State.Connections.EspPlayerAdded then
        pcall(State.Connections.EspPlayerAdded.Disconnect, State.Connections.EspPlayerAdded)
        State.Connections.EspPlayerAdded = nil
    end
     if State.Connections.EspPlayerRemoving then
         pcall(State.Connections.EspPlayerRemoving.Disconnect, State.Connections.EspPlayerRemoving)
         State.Connections.EspPlayerRemoving = nil
     end
    for p, conns in pairs(State.EspConnections) do
         if type(p) == "userdata" and p:IsA("Player") then
             if conns.CharacterAddedConnection then
                 pcall(conns.CharacterAddedConnection.Disconnect, conns.CharacterAddedConnection)
             end
             if p.Character then
                 removeHighlightFromCharacter(p.Character)
                 if conns.DiedConnection then
                     pcall(conns.DiedConnection.Disconnect, conns.DiedConnection)
                 end
             end
         end
    end
    State.EspConnections = {}
    updateEspButtonState()
    safeShowNotification("ESP Player", "Đã Tắt", "ETC")
end

local function toggleEsp()
    if State.EspEnabled then
        disableEsp()
    else
        enableEsp()
    end
end

--===== 🧹 Cleanup Function =====--
local function cleanup()
    print("Hx: Bắt đầu dọn dẹp...")
    if not _G.UnifiedAntiAFK_AutoClicker_Running then return end
    _G.UnifiedAntiAFK_AutoClicker_Running = false
    if State.AutoClicking then State.AutoClicking = false; autoClickCoroutine = nil end
    if State.ChoosingClickPos then if State.GuiElements.ClickTargetMarker then pcall(State.GuiElements.ClickTargetMarker.Destroy, State.GuiElements.ClickTargetMarker) end; if State.GuiElements.LockButton then pcall(State.GuiElements.LockButton.Destroy, State.GuiElements.LockButton) end; State.ChoosingClickPos = false end
    State.IsBindingHotkey = false
    State.LagReduced = false
    if State.EspEnabled then disableEsp() end
    State.HighlightTemplate = nil
    for _, connection in pairs(State.Connections) do if connection and typeof(connection) == "RBXScriptConnection" then pcall(connection.Disconnect, connection) end end
    State.Connections = {}
    State.EspConnections = {}
    if State.GuiElements.ScreenGui and State.GuiElements.ScreenGui.Parent and State.GuiElements.ScreenGui.Name == "Hx_v2_GUI" then pcall(State.GuiElements.ScreenGui.Destroy, State.GuiElements.ScreenGui) end
    State.GuiElements = { ScreenGui = nil, MainFrame = nil, ScrollingFrame = nil, ContentListLayout = nil, GuiToggleButton = nil, TitleBarFrame = nil, TransparentToggle = nil, CircleIndicator = nil, TransparentTextButton = nil, MobileClickButton = nil, NotificationContainer = nil, ClickTargetMarker = nil, LockButton = nil, AutoClicker = { Toggle = nil, ModeGroup = nil, PlatformGroup = nil, CpsLocateFrame = nil, CPSBox = nil, LocateButton = nil, HotkeyButton = nil, MobileCreateButton = nil, MobileLockToggle = nil, ModeButtons = {}, PlatformButtons = {} }, ETC = { EtcButtonFrame = nil, ReducesLagButton = nil, AntiAFKToggleButton = nil, EspPlayerButton = nil, AFKStatusLabel = nil } }
    State.TransparencyTargets = {}
    print("Hx: Dọn dẹp hoàn tất.")
    _G.UnifiedAntiAFK_AutoClicker_CleanupFunction = nil
end
_G.UnifiedAntiAFK_AutoClicker_CleanupFunction = cleanup

--===== 🛋️ Anti-AFK Functions =====--
local function isPositionOverScriptGui(p) if not State.GuiElements.ScreenGui then return false end;local e={State.GuiElements.MainFrame,State.GuiElements.GuiToggleButton,State.GuiElements.MobileClickButton,State.GuiElements.NotificationContainer};if State.ChoosingClickPos then table.insert(e,State.GuiElements.ClickTargetMarker);table.insert(e,State.GuiElements.LockButton) end;for _,g in ipairs(e) do if g and g:IsA("GuiObject") and g.Visible and g.AbsoluteSize.X>0 then local o,s=g.AbsolutePosition,g.AbsoluteSize;if p.X>=o.X and p.X<=o.X+s.X and p.Y>=o.Y and p.Y<=o.Y+s.Y then return true end end end;if State.GuiElements.NotificationContainer then for _,n in ipairs(State.GuiElements.NotificationContainer:GetChildren()) do if n:IsA("GuiObject") and n.Visible and n.AbsoluteSize.X>0 then local np,ns=n.AbsolutePosition,n.AbsoluteSize;if p.X>=np.X and p.X<=np.X+ns.X and p.Y>=np.Y and p.Y<=np.Y+ns.Y then return true end end end end;return false end
local function performAntiAFKAction() if not Config.EnableIntervention then return end;local a,s,e="",false,"?";local g=State.GuiElements;if State.GuiVisible and g.MainFrame and g.MainFrame.Visible then a="Jump";s,e=pcall(function() VirtualInputManager:SendKeyEvent(true,Enum.KeyCode.Space,false,game);task.wait(0.06);VirtualInputManager:SendKeyEvent(false,Enum.KeyCode.Space,false,game) end) else a="Click";local c=Workspace.CurrentCamera;if not c then return end;local v=c.ViewportSize;local x,y=v.X/2,v.Y/2;s,e=pcall(function() VirtualInputManager:SendMouseButtonEvent(x,y,0,true,game,0);task.wait(0.06);VirtualInputManager:SendMouseButtonEvent(x,y,0,false,game,0) end) end;if not s then print("Hx: Lỗi AntiAFK("..a.."):",e);safeShowNotification("Lỗi Anti-AFK","Lỗi","AFK") else State.LastInterventionTime=os.clock();State.InterventionCounter=State.InterventionCounter+1 end end
local function updateAFKStatusLabel()
    local s = State.GuiElements.ETC.AFKStatusLabel; if not s then return end
    s.Text = (not Config.EnableIntervention and "AFK: Đã tắt") or (State.IsConsideredAFK and "Trạng thái: Đang AFK") or "Trạng thái: Đang hoạt động"
    s.TextColor3 = (not Config.EnableIntervention and Config.ColorTextSecondary) or (State.IsConsideredAFK and Color3.fromRGB(255, 200, 80)) or Color3.fromRGB(180, 255, 180)
end
local function onInputDetected() local n=os.clock();if State.IsConsideredAFK then State.IsConsideredAFK=false;State.LastInterventionTime=0;State.InterventionCounter=0;if Config.EnableIntervention then safeShowNotification("Bạn đã quay lại!","OK","AFK") end;updateAFKStatusLabel() end;State.LastInputTime=n end

--===== 🖱️ Auto Clicker Functions =====--
local function doAutoClick() local cp=State.SelectedClickPos;while State.AutoClicking do local mp=UserInputService:GetMouseLocation();local co=isPositionOverScriptGui(cp);local mo=isPositionOverScriptGui(mp);if not State.MobileButtonIsDragging and not co and not mo then local s,e=pcall(function() if not State.AutoClicking then return end;VirtualInputManager:SendMouseButtonEvent(cp.X,cp.Y,0,true,game,0);if not State.AutoClicking then return end;task.wait(0.01);if not State.AutoClicking then return end;VirtualInputManager:SendMouseButtonEvent(cp.X,cp.Y,0,false,game,0) end);if not s then print("Hx: Lỗi AC:",e);safeShowNotification("Lỗi Auto Click","Tắt","Clicker");stopClick();return end end;if not State.AutoClicking then break end;local d=1/State.CurrentCPS;if d<=0.001 then d=0.001 end;task.wait(d) end;autoClickCoroutine=nil end
local function updateAutoClickToggleButtonState()
    local t = State.GuiElements.AutoClicker.Toggle; if not(t and t.Parent) then return end
    local i = State.AutoClicking
    local l = "Auto Click: " .. (i and "ON" or "OFF")
    local c = i and Config.ColorToggleOn or Config.ColorToggleOff
    t.Text = l; pcall(function() t.BackgroundColor3 = c end)
end
local function startClick() if State.AutoClicking or State.ChoosingClickPos or State.IsBindingHotkey then return end;State.AutoClicking=true;updateAutoClickToggleButtonState();safeShowNotification("Auto Clicker",string.format("Bật(%.0f CPS)",State.CurrentCPS),"Clicker");autoClickCoroutine=task.spawn(doAutoClick) end
local function stopClick() if not State.AutoClicking then return end;State.AutoClicking=false;updateAutoClickToggleButtonState();safeShowNotification("Auto Clicker","Tắt","Clicker") end
local function triggerAutoClick() if State.AutoClickMode=="Toggle" then if State.AutoClicking then stopClick() else startClick() end elseif State.AutoClickMode=="Hold" then if State.ClickTriggerActive and not State.AutoClicking then startClick() elseif not State.ClickTriggerActive and State.AutoClicking then stopClick() end end end
local function endClickPositionChoice(c) if not State.ChoosingClickPos then return end;local o,g=State.Connections,State.GuiElements;if o.ConfirmClickPos then pcall(o.ConfirmClickPos.Disconnect,o.ConfirmClickPos);o.ConfirmClickPos=nil end;if o.CancelClickPosKey then pcall(o.CancelClickPosKey.Disconnect,o.CancelClickPosKey);o.CancelClickPosKey=nil end;if g.ClickTargetMarker and g.ClickTargetMarker.Parent then pcall(g.ClickTargetMarker.Destroy,g.ClickTargetMarker);g.ClickTargetMarker=nil end;if g.LockButton and g.LockButton.Parent then pcall(g.LockButton.Destroy,g.LockButton);g.LockButton=nil end;if g.MainFrame then g.MainFrame.Visible=State.GuiVisible end;if g.GuiToggleButton then g.GuiToggleButton.Visible=true end;State.ChoosingClickPos=false;if c then safeShowNotification("Chọn vị trí","Hủy","Clicker")else safeShowNotification("Chọn vị trí",string.format("Khóa:(%.0f,%.0f)",State.SelectedClickPos.X,State.SelectedClickPos.Y),"Clicker") end end
local function confirmClickPosition() if not State.ChoosingClickPos then return end; local g=State.GuiElements; if not g.ClickTargetMarker or not g.ClickTargetMarker.Parent then endClickPositionChoice(true); return end; local m=g.ClickTargetMarker; local p,s=m.AbsolutePosition,m.AbsoluteSize; State.SelectedClickPos=Vector2.new(p.X+s.X/2, p.Y+s.Y*1.5); endClickPositionChoice(false); end
local function cancelClickPositionChoice() if State.ChoosingClickPos then endClickPositionChoice(true) end end
local function startChoosingClickPos() if State.ChoosingClickPos or State.IsBindingHotkey then return end;if State.AutoClicking then stopClick() end;local g,c=State.GuiElements,State.Connections;State.ChoosingClickPos=true;if g.MainFrame then g.MainFrame.Visible=false end;if g.GuiToggleButton then g.GuiToggleButton.Visible=false end;local m=Instance.new("Frame");m.Name="CTM";m.Size=UDim2.fromOffset(Config.ClickTargetMarkerSize,Config.ClickTargetMarkerSize);m.Position=UDim2.new(0.5,0,0.5,0);m.AnchorPoint=Vector2.new(0.5,0.5);m.BackgroundColor3=Config.ColorBorder;m.BackgroundTransparency=0.5;m.BorderSizePixel=1;m.BorderColor3=Config.ColorClickTargetBorder;m.Active=true;m.Draggable=true;m.Parent=g.ScreenGui;m.ZIndex=20;Instance.new("UICorner",m).CornerRadius=UDim.new(0.5,0);g.ClickTargetMarker=m;local d=Instance.new("Frame");d.Name="CD";d.Size=UDim2.fromOffset(Config.ClickTargetCenterDotSize,Config.ClickTargetCenterDotSize);d.Position=UDim2.new(0.5,0,0.5,0);d.AnchorPoint=Vector2.new(0.5,0.5);d.BackgroundColor3=Config.ColorClickTargetCenter;d.BorderSizePixel=0;d.Parent=m;Instance.new("UICorner",d).CornerRadius=UDim.new(0.5,0);local t=GuiService:GetGuiInset().Y;local l=Instance.new("ImageButton");l.Name="LB";l.Size=UDim2.fromOffset(Config.LockButtonSize,Config.LockButtonSize);l.Position=UDim2.new(0.5,0,0,t+15);l.AnchorPoint=Vector2.new(0.5,0);l.Image=Config.IconLock;l.BackgroundColor3=Config.ColorBackground;l.BackgroundTransparency=0.5;l.BorderSizePixel=1;l.BorderColor3=Config.ColorBorder;l.Parent=g.ScreenGui;l.ZIndex=21;Instance.new("UICorner",l).CornerRadius=UDim.new(0,6);g.LockButton=l;if c.ConfirmClickPos then pcall(c.ConfirmClickPos.Disconnect,c.ConfirmClickPos) end;c.ConfirmClickPos=l.MouseButton1Click:Connect(confirmClickPosition);if c.CancelClickPosKey then pcall(c.CancelClickPosKey.Disconnect,c.CancelClickPosKey) end;c.CancelClickPosKey=UserInputService.InputBegan:Connect(function(i,gp) if State.ChoosingClickPos and not gp and i.KeyCode==Enum.KeyCode.Escape then cancelClickPositionChoice() end end);safeShowNotification("Chọn vị trí","Kéo, nhấn 🔒 xác nhận.","Clicker") end
local function startBindingHotkey()
    if State.IsBindingHotkey or State.ChoosingClickPos then return end; if State.AutoClicking then stopClick() end; State.IsBindingHotkey = true; local h = State.GuiElements.AutoClicker.HotkeyButton; local oT, oC; if h then oT, oC = h.Text, h.BackgroundColor3; h.BackgroundColor3 = Color3.fromRGB(200, 150, 50); h.Text = "Nhấn..." end; safeShowNotification("Đặt Hotkey", "Nhấn phím (. hủy)", "Clicker"); local c = State.Connections; if c.HotkeyBinding then pcall(c.HotkeyBinding.Disconnect, c.HotkeyBinding); c.HotkeyBinding = nil end
    local function endBinding(cancelled, newKey) if not State.IsBindingHotkey then return end; if c.HotkeyBinding then pcall(c.HotkeyBinding.Disconnect, c.HotkeyBinding); c.HotkeyBinding = nil end; State.IsBindingHotkey = false; if h then h.BackgroundColor3 = oC end; if cancelled then if h then h.Text = oT end; safeShowNotification("Đặt Hotkey", "Hủy", "Clicker") else if newKey then State.AutoClickHotkey = newKey; if h then h.Text = "Hotkey: " .. newKey.Name end; safeShowNotification("Đặt Hotkey", "Đặt: " .. newKey.Name, "Clicker"); connectHotkeyListener() else if h then h.Text = oT end end end end
    c.HotkeyBinding = UserInputService.InputBegan:Connect(function(input, gp)
        if not State.IsBindingHotkey or gp then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            if input.KeyCode == Enum.KeyCode.Period then
                endBinding(true)
            elseif input.KeyCode ~= Enum.KeyCode.Unknown then
                endBinding(false, input.KeyCode)
            end
        elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
            safeShowNotification("Đặt Hotkey", "Nhấn phím.", "Clicker")
        end
    end)
end
local function connectHotkeyListener() local c=State.Connections;if c.HotkeyInputBegan then pcall(c.HotkeyInputBegan.Disconnect,c.HotkeyInputBegan);c.HotkeyInputBegan=nil end;if c.HotkeyInputEnded then pcall(c.HotkeyInputEnded.Disconnect,c.HotkeyInputEnded);c.HotkeyInputEnded=nil end;if State.Platform~="PC" or not State.AutoClickHotkey or State.AutoClickHotkey==Enum.KeyCode.Unknown then return end;c.HotkeyInputBegan=UserInputService.InputBegan:Connect(function(i,gp) if gp or State.IsBindingHotkey or State.ChoosingClickPos or State.Platform~="PC" or i.KeyCode~=State.AutoClickHotkey or UserInputService:GetFocusedTextBox() then return end;State.ClickTriggerActive=true;triggerAutoClick() end);c.HotkeyInputEnded=UserInputService.InputEnded:Connect(function(i,gp) if State.Platform~="PC" or i.KeyCode~=State.AutoClickHotkey then return end;State.ClickTriggerActive=false;if State.AutoClickMode=="Hold" then triggerAutoClick() end end) end
local function connectMobileButtonListeners(b)
    local c=State.Connections
    if c.MobileButtonInputBegan then pcall(c.MobileButtonInputBegan.Disconnect,c.MobileButtonInputBegan);c.MobileButtonInputBegan=nil end
    if c.MobileButtonInputEnded then pcall(c.MobileButtonInputEnded.Disconnect,c.MobileButtonInputEnded);c.MobileButtonInputEnded=nil end
    c.MobileButtonInputBegan=b.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then task.wait();if not State.MobileButtonIsDragging then if State.MobileButtonLocked then State.ClickTriggerActive=true;triggerAutoClick() else safeShowNotification("Nút Mobile","Khóa vị trí nút.","Clicker") end end end end)
    c.MobileButtonInputEnded=b.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.Touch or i.UserInputType==Enum.UserInputType.MouseButton1 then local wa=State.ClickTriggerActive;State.ClickTriggerActive=false;if State.AutoClickMode=="Hold" and State.MobileButtonLocked and wa then triggerAutoClick() end;if State.MobileButtonIsDragging then State.MobileButtonIsDragging=false;b.BackgroundTransparency=0.4 end end end)
end
local function createOrShowMobileButton() local g=State.GuiElements;if g.MobileClickButton and g.MobileClickButton.Parent then g.MobileClickButton.Visible=true;g.MobileClickButton.Draggable=not State.MobileButtonLocked;connectMobileButtonListeners(g.MobileClickButton) else local s=g.ScreenGui;if not s or not s.Parent then print("Hx: Lỗi tạo nút Mobile.");return end;local b=Instance.new("ImageButton");b.Name="MCB";b.Size=UDim2.fromOffset(Config.MobileButtonClickSize,Config.MobileButtonClickSize);b.Position=Config.MobileButtonDefaultPos;b.Image=Config.IconMobileClickButton;b.BackgroundColor3=Color3.fromRGB(255,255,255);b.BackgroundTransparency=0.4;b.Active=true;b.Draggable=not State.MobileButtonLocked;b.Selectable=true;b.ZIndex=15;b.Parent=s;Instance.new("UICorner",b).CornerRadius=UDim.new(0.5,0);g.MobileClickButton=b;connectMobileButtonListeners(b) end end
local function hideOrDestroyMobileButton() local g=State.GuiElements;local c=State.Connections;if g.MobileClickButton and g.MobileClickButton.Parent then if c.MobileButtonInputBegan then pcall(c.MobileButtonInputBegan.Disconnect,c.MobileButtonInputBegan);c.MobileButtonInputBegan=nil end;if c.MobileButtonInputEnded then pcall(c.MobileButtonInputEnded.Disconnect,c.MobileButtonInputEnded);c.MobileButtonInputEnded=nil end;pcall(g.MobileClickButton.Destroy,g.MobileClickButton);g.MobileClickButton=nil end end
local function updatePlatformUI() local p=State.Platform=="PC";local a=State.GuiElements.AutoClicker;local g=State.GuiElements;if a.HotkeyButton then a.HotkeyButton.Visible=p end;if a.MobileCreateButton then a.MobileCreateButton.Visible=not p end;if a.MobileLockToggle then a.MobileLockToggle.Visible=not p end;if p then hideOrDestroyMobileButton();connectHotkeyListener() else local c=State.Connections;if c.HotkeyInputBegan then pcall(c.HotkeyInputBegan.Disconnect,c.HotkeyInputBegan);c.HotkeyInputBegan=nil end;if c.HotkeyInputEnded then pcall(c.HotkeyInputEnded.Disconnect,c.HotkeyInputEnded);c.HotkeyInputEnded=nil end;if g.MobileClickButton and g.MobileClickButton.Parent then g.MobileClickButton.Visible=true;g.MobileClickButton.Draggable=not State.MobileButtonLocked;connectMobileButtonListeners(g.MobileClickButton) end end end

--===== 🔧 UI Helper Functions =====--
local function createGuiElement(cn,p) local e=Instance.new(cn);for k,v in pairs(p) do pcall(function() e[k]=v end) end;return e end
local function createToggle(n,l,o,p,i,c) local bT=State.IsTransparent and Config.ButtonTransparentBGLevel or Config.ButtonOpaqueBGLevel;local t=createGuiElement("TextButton",{Name=n,Size=UDim2.new(1,0,0,30),Text=l..(i and": ON"or": OFF"),Font=Enum.Font.SourceSansSemibold,TextSize=15,TextColor3=Config.ColorTextPrimary,BackgroundColor3=i and Config.ColorToggleOn or Config.ColorToggleOff,BackgroundTransparency=bT,LayoutOrder=o,Parent=p,AutoButtonColor=false});createGuiElement("UICorner",{CornerRadius=UDim.new(0,5),Parent=t});table.insert(State.TransparencyTargets,t);local N=n.."_Click";if State.Connections[N] then pcall(State.Connections[N].Disconnect,State.Connections[N]) end;State.Connections[N]=t.MouseButton1Click:Connect(function() if c then local s=c();if type(s)=="boolean" then local L=l..(s and": ON"or": OFF");local C=s and Config.ColorToggleOn or Config.ColorToggleOff;t.Text=L;pcall(function()t.BackgroundColor3=C end) end end end);return t end
local function createRadioGroup(n,o,s,d,p,c) local f=createGuiElement("Frame",{Name=n.."GF",Size=UDim2.new(1,0,0,30),BackgroundTransparency=1,LayoutOrder=d,Parent=p});local l=createGuiElement("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,HorizontalAlignment=Enum.HorizontalAlignment.Center,VerticalAlignment=Enum.VerticalAlignment.Center,SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,8),Parent=f});local b,u={},s;local m=#o;local tP=(m-1)*l.Padding.Offset;local aW=Config.GuiWidth-20-tP;local bW=math.max(50,aW/m);local bT=State.IsTransparent and Config.ButtonTransparentBGLevel or Config.ButtonOpaqueBGLevel;local function v() for O,B in pairs(b) do if B and B.Parent then local S=(O==u);local C=S and Config.ColorButtonPrimary or Config.ColorButtonSecondary;local T=S and Config.ColorTextPrimary or Config.ColorTextSecondary;pcall(function()B.BackgroundColor3=C end);pcall(function()B.TextColor3=T end) end end end;for i,N in ipairs(o) do local B=createGuiElement("TextButton",{Name=n..N:gsub("%s+",""),Size=UDim2.new(0,bW,1,0),Text=N,Font=Enum.Font.SourceSansSemibold,TextSize=14,LayoutOrder=i,Parent=f,AutoButtonColor=false,BackgroundTransparency=bT});createGuiElement("UICorner",{CornerRadius=UDim.new(0,5),Parent=B});b[N]=B;table.insert(State.TransparencyTargets,B);local I=B.Name.."_Click";if State.Connections[I] then pcall(State.Connections[I].Disconnect,State.Connections[I]) end;State.Connections[I]=B.MouseButton1Click:Connect(function() if u~=N then u=N;if c then pcall(c,u) end;v() end end) end;v();return f,b end
local function updateCPSPlaceholder() local c=State.GuiElements.AutoClicker.CPSBox;if c then if c:IsFocused() then c.PlaceholderText="CPS..." else c.PlaceholderText=string.format("CPS:%d",State.CurrentCPS) end end end
local function updateElementsTransparency(t) local b=t and Config.TransparentBGLevel or Config.OpaqueBGLevel;local u=t and Config.ButtonTransparentBGLevel or Config.ButtonOpaqueBGLevel;pcall(function() if State.GuiElements.MainFrame then TweenService:Create(State.GuiElements.MainFrame,TWEEN_INFO_FAST,{BackgroundTransparency=b}):Play() end end);pcall(function() if State.GuiElements.GuiToggleButton then TweenService:Create(State.GuiElements.GuiToggleButton,TWEEN_INFO_FAST,{BackgroundTransparency=u}):Play() end end);for _,e in ipairs(State.TransparencyTargets) do if e and e.Parent then pcall(function() TweenService:Create(e,TWEEN_INFO_FAST,{BackgroundTransparency=u}):Play() end) end end;pcall(function() if State.GuiElements.MobileClickButton and State.GuiElements.MobileClickButton.Parent then local r=t and 0.7 or 0.4;TweenService:Create(State.GuiElements.MobileClickButton,TWEEN_INFO_FAST,{BackgroundTransparency=r}):Play() end end);pcall(function() if State.GuiElements.LockButton and State.GuiElements.LockButton.Parent then local r=t and 0.8 or 0.5;TweenService:Create(State.GuiElements.LockButton,TWEEN_INFO_FAST,{BackgroundTransparency=r}):Play() end end) end

--===== 🎨 GUI Creation =====--
local function createGUI()
    local oldGui=CoreGui:FindFirstChild("Hx_v2_GUI");if oldGui then pcall(cleanup) end;local g,c=State.GuiElements,State.Connections;State.TransparencyTargets={};local s=createGuiElement("ScreenGui",{Name="Hx_v2_GUI",ResetOnSpawn=false,ZIndexBehavior=Enum.ZIndexBehavior.Sibling,DisplayOrder=1003,IgnoreGuiInset=true,Parent=CoreGui});g.ScreenGui=s;setupNotificationContainer(s);createNotificationTemplate();local tI=GuiService:GetGuiInset().Y;local cBBT=State.IsTransparent and Config.ButtonTransparentBGLevel or Config.ButtonOpaqueBGLevel;local gTB=createGuiElement("ImageButton",{Name="GTB",Size=UDim2.fromOffset(Config.ToggleButtonSize,Config.ToggleButtonSize),Position=UDim2.new(0.5,0,0,tI+15),AnchorPoint=Vector2.new(0.5,0),Image=Config.IconToggleButton,BackgroundColor3=Config.ColorBackground,BackgroundTransparency=cBBT,BorderSizePixel=1,BorderColor3=Config.ColorBorder,Active=true,Draggable=true,Selectable=true,Parent=s,ZIndex=10});createGuiElement("UICorner",{CornerRadius=UDim.new(0,6),Parent=gTB});g.GuiToggleButton=gTB;local cBT=State.IsTransparent and Config.TransparentBGLevel or Config.OpaqueBGLevel;local mF=createGuiElement("Frame",{Name="MF",Size=UDim2.fromOffset(Config.GuiWidth,Config.GuiHeight),Position=UDim2.new(0.5,0,0.5,0),AnchorPoint=Vector2.new(0.5,0.5),BackgroundColor3=Config.ColorBackground,BackgroundTransparency=cBT,BorderColor3=Config.ColorBorder,BorderSizePixel=1,Active=true,Draggable=true,ClipsDescendants=true,Visible=State.GuiVisible,Parent=s,ZIndex=5});createGuiElement("UICorner",{CornerRadius=UDim.new(0,8),Parent=mF});g.MainFrame=mF;local tBF=createGuiElement("Frame",{Name="TBF",Size=UDim2.new(1,-20,0,35),Position=UDim2.new(0,10,0,5),BackgroundTransparency=1,Parent=mF});g.TitleBarFrame=tBF;local tBL=createGuiElement("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,SortOrder=Enum.SortOrder.LayoutOrder,VerticalAlignment=Enum.VerticalAlignment.Center,Padding=UDim.new(0,10),Parent=tBF});createGuiElement("TextLabel",{Name="T",Size=UDim2.new(1,-(Config.TransparentToggleWidth+tBL.Padding.Offset),1,0),Text=Config.GuiTitle,Font=Enum.Font.SourceSansBold,TextSize=20,TextColor3=Config.ColorTextPrimary,BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=1,Parent=tBF});local tT=createGuiElement("Frame",{Name="TT",Size=UDim2.new(0,Config.TransparentToggleWidth,1,0),BackgroundTransparency=1,LayoutOrder=2,Parent=tBF});g.TransparentToggle=tT;local tL=createGuiElement("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,SortOrder=Enum.SortOrder.LayoutOrder,VerticalAlignment=Enum.VerticalAlignment.Center,HorizontalAlignment=Enum.HorizontalAlignment.Right,Padding=UDim.new(0,5),Parent=tT});local tTB=createGuiElement("TextButton",{Name="TTB",Size=UDim2.new(0,85,1,0),Text="Transparent",Font=Enum.Font.SourceSans,TextSize=15,TextColor3=Config.ColorTextSecondary,BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Right,LayoutOrder=1,Parent=tT,AutoButtonColor=false,Active=true,Selectable=true});g.TransparentTextButton=tTB;local cI=createGuiElement("Frame",{Name="CI",Size=UDim2.fromOffset(16,16),BackgroundColor3=Config.ColorToggleOn,BackgroundTransparency=State.IsTransparent and 0 or 1,LayoutOrder=2,Parent=tT});createGuiElement("UICorner",{CornerRadius=UDim.new(0.5,0)}).Parent=cI;createGuiElement("UIStroke",{Thickness=1.5,Color=Config.ColorToggleCircleBorder,ApplyStrokeMode=Enum.ApplyStrokeMode.Border}).Parent=cI;g.CircleIndicator=cI;local sF=createGuiElement("ScrollingFrame",{Name="SF",Size=UDim2.new(1,0,1,-(tBF.AbsoluteSize.Y+10)),Position=UDim2.new(0,0,0,tBF.AbsoluteSize.Y+5),BackgroundTransparency=1,BorderSizePixel=0,CanvasSize=UDim2.new(0,0,0,0),ScrollBarImageColor3=Config.ColorScrollbar,ScrollBarThickness=Config.ScrollbarThickness,ScrollingDirection=Enum.ScrollingDirection.Y,Parent=mF});g.ScrollingFrame=sF;local cLL=createGuiElement("UIListLayout",{Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder,HorizontalAlignment=Enum.HorizontalAlignment.Center,FillDirection=Enum.FillDirection.Vertical,Parent=sF});g.ContentListLayout=cLL;createGuiElement("UIPadding",{PaddingTop=UDim.new(0,5),PaddingBottom=UDim.new(0,10),PaddingLeft=UDim.new(0,10),PaddingRight=UDim.new(0,10),Parent=sF});local cSCN="CS";if c[cSCN] then pcall(c[cSCN].Disconnect,c[cSCN]) end;c[cSCN]=cLL:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function() if sF and sF.Parent then sF.CanvasSize=UDim2.new(0,0,0,cLL.AbsoluteContentSize.Y+5) end end);local cP,lO=sF,0

    --===== Auto Clicker Section =====--
    lO=lO+1;createGuiElement("TextLabel",{Name="ACH",Size=UDim2.new(1,0,0,22),Text="───═══[ 🖱️ Auto Clicker 🖱️ ]═══───",Font=Enum.Font.SourceSansBold,TextSize=17,TextColor3=Config.ColorSectionHeader,BackgroundTransparency=1,LayoutOrder=lO,Parent=cP});
    lO=lO+1;local aCT=createToggle("ACT","Auto Click",lO,cP,State.AutoClicking,function()triggerAutoClick();return State.AutoClicking end);g.AutoClicker.Toggle=aCT;
    lO=lO+1;createGuiElement("TextLabel",{Name="ML",Size=UDim2.new(1,0,0,18),Text="Chế độ Click:",Font=Enum.Font.SourceSans,TextSize=13,TextColor3=Config.ColorTextSecondary,BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=lO,Parent=cP});
    lO=lO+1;local mG,mB=createRadioGroup("CM",{"Toggle","Hold"},State.AutoClickMode,lO,cP,function(nM) State.AutoClickMode=nM; if State.AutoClicking then stopClick() end; State.ClickTriggerActive=false; updateAutoClickToggleButtonState() end);g.AutoClicker.ModeGroup=mG;g.AutoClicker.ModeButtons=mB;
    lO=lO+1;createGuiElement("TextLabel",{Name="PL",Size=UDim2.new(1,0,0,18),Text="Nền tảng:",Font=Enum.Font.SourceSans,TextSize=13,TextColor3=Config.ColorTextSecondary,BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=lO,Parent=cP});
    lO=lO+1;local pG,pB=createRadioGroup("P",{"PC","Mobile"},State.Platform,lO,cP,function(nP) if State.Platform~=nP then State.Platform=nP;updatePlatformUI() end end);g.AutoClicker.PlatformGroup=pG;g.AutoClicker.PlatformButtons=pB;
    lO=lO+1;local hB=createGuiElement("TextButton",{Name="HB",Size=UDim2.new(1,0,0,32),Text="Hotkey: "..State.AutoClickHotkey.Name,Font=Enum.Font.SourceSansBold,TextSize=15,TextColor3=Config.ColorTextPrimary,BackgroundColor3=Config.ColorButtonPrimary,BackgroundTransparency=cBBT,LayoutOrder=lO,Visible=(State.Platform=="PC"),Parent=cP});createGuiElement("UICorner",{CornerRadius=UDim.new(0,5),Parent=hB});g.AutoClicker.HotkeyButton=hB;c.HBC=hB.MouseButton1Click:Connect(startBindingHotkey);table.insert(State.TransparencyTargets,hB);
    local mCB=createGuiElement("TextButton",{Name="MCB",Size=UDim2.new(1,0,0,32),Text="Tạo/Hiện nút Mobile",Font=Enum.Font.SourceSansBold,TextSize=15,TextColor3=Config.ColorTextPrimary,BackgroundColor3=Config.ColorButtonPrimary,BackgroundTransparency=cBBT,LayoutOrder=lO,Visible=(State.Platform=="Mobile"),Parent=cP});createGuiElement("UICorner",{CornerRadius=UDim.new(0,5),Parent=mCB});g.AutoClicker.MobileCreateButton=mCB;c.MCC=mCB.MouseButton1Click:Connect(createOrShowMobileButton);table.insert(State.TransparencyTargets,mCB);
    lO=lO+1;local mLT=createToggle("MLT","Khóa vị trí nút",lO,cP,State.MobileButtonLocked,function() State.MobileButtonLocked=not State.MobileButtonLocked;if g.MobileClickButton then g.MobileClickButton.Draggable=not State.MobileButtonLocked end;local lS=State.MobileButtonLocked and "Khóa(OK)"or"Mở(No AC)";safeShowNotification("Nút Mobile",lS,"Clicker");if not State.MobileButtonLocked and State.AutoClicking then stopClick();safeShowNotification("Auto Clicker","Tắt(Mở khóa)","Clicker") end;return State.MobileButtonLocked end);mLT.Visible=(State.Platform=="Mobile");g.AutoClicker.MobileLockToggle=mLT;
    lO=lO+1;local cLF=createGuiElement("Frame",{Name="CLF",Size=UDim2.new(1,0,0,35),BackgroundTransparency=1,LayoutOrder=lO,Parent=cP});g.AutoClicker.CpsLocateFrame=cLF;local cLL2=createGuiElement("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,VerticalAlignment=Enum.VerticalAlignment.Center,HorizontalAlignment=Enum.HorizontalAlignment.Left,SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,8),Parent=cLF});local cpsB=createGuiElement("TextBox",{Name="CPS",Size=UDim2.new(0,Config.CPSBoxWidth,1,0),Text="",Font=Enum.Font.SourceSans,TextSize=15,TextColor3=Config.ColorTextPrimary,BackgroundColor3=Config.ColorInputBackground,BackgroundTransparency=0.1,PlaceholderColor3=Config.ColorTextSecondary,ClearTextOnFocus=true,TextXAlignment=Enum.TextXAlignment.Center,LayoutOrder=1,Parent=cLF});createGuiElement("UICorner",{CornerRadius=UDim.new(0,5),Parent=cpsB});g.AutoClicker.CPSBox=cpsB;updateCPSPlaceholder();local lB=createGuiElement("TextButton",{Name="LB",Size=UDim2.new(1,-(Config.CPSBoxWidth+cLL2.Padding.Offset),1,0),Text="Chọn vị trí",Font=Enum.Font.SourceSansBold,TextSize=15,TextColor3=Config.ColorTextPrimary,BackgroundColor3=Config.ColorButtonPrimary,BackgroundTransparency=cBBT,LayoutOrder=2,Parent=cLF});createGuiElement("UICorner",{CornerRadius=UDim.new(0,5),Parent=lB});g.AutoClicker.LocateButton=lB;c.LBC=lB.MouseButton1Click:Connect(startChoosingClickPos);table.insert(State.TransparencyTargets,lB)

    --===== ETC Section =====--
    lO=lO+1;createGuiElement("TextLabel",{Name="ETCH",Size=UDim2.new(1,0,0,22),Text="───═══[ ✨ ETC ✨ ]═══───",Font=Enum.Font.SourceSansBold,TextSize=17,TextColor3=Config.ColorSectionHeader,BackgroundTransparency=1,LayoutOrder=lO,Parent=cP});
    lO=lO+1; local eBF=createGuiElement("Frame",{Name="EBF",Size=UDim2.new(1,0,0,30),BackgroundTransparency=1,LayoutOrder=lO,Parent=cP});g.ETC.EtcButtonFrame = eBF
    local eBL=createGuiElement("UIListLayout",{FillDirection=Enum.FillDirection.Horizontal,VerticalAlignment=Enum.VerticalAlignment.Center,HorizontalAlignment=Enum.HorizontalAlignment.Center,SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,5), Parent=eBF});
    local totalPadding = eBL.Padding.Offset * 2; local availableWidth = Config.GuiWidth - 20 - totalPadding; local buttonWidth = math.floor(availableWidth / 3)
    local rLB=createGuiElement("TextButton",{Name="RLB",Size=UDim2.new(0,buttonWidth,1,0), Text="Reduces Lag", Font=Enum.Font.SourceSansSemibold, TextSize=14, TextColor3=Config.ColorTextPrimary, BackgroundColor3=State.LagReduced and Config.ColorButtonGreen or Config.ColorButtonRed, BackgroundTransparency=cBBT, LayoutOrder=1, Parent=eBF, AutoButtonColor=false});createGuiElement("UICorner",{CornerRadius=UDim.new(0,5),Parent=rLB}); g.ETC.ReducesLagButton=rLB; table.insert(State.TransparencyTargets,rLB); c.RLC=rLB.MouseButton1Click:Connect(function()if not State.LagReduced then reduceLag();if State.LagReduced then pcall(function()rLB.BackgroundColor3=Config.ColorButtonGreen; rLB.Text = "Lag Reduced" end)end else safeShowNotification("Giảm Lag","Vào lại để tắt.","ETC")end end);
    local aATB=createGuiElement("TextButton",{Name="AATB",Size=UDim2.new(0,buttonWidth,1,0), Text="AntiAFK"..(Config.EnableIntervention and": ON"or": OFF"), Font=Enum.Font.SourceSansSemibold, TextSize=14, TextColor3=Config.ColorTextPrimary, BackgroundColor3=Config.EnableIntervention and Config.ColorToggleOn or Config.ColorToggleOff, BackgroundTransparency=cBBT, LayoutOrder=2, Parent=eBF, AutoButtonColor=false}); createGuiElement("UICorner",{CornerRadius=UDim.new(0,5),Parent=aATB}); g.ETC.AntiAFKToggleButton=aATB; table.insert(State.TransparencyTargets,aATB); c.EATC=aATB.MouseButton1Click:Connect(function() Config.EnableIntervention=not Config.EnableIntervention; local s=Config.EnableIntervention and"BẬT"or"TẮT"; safeShowNotification("Anti-AFK","Can thiệp: "..s,"AFK"); aATB.Text="AntiAFK"..(Config.EnableIntervention and": ON"or": OFF"); pcall(function()aATB.BackgroundColor3=Config.EnableIntervention and Config.ColorToggleOn or Config.ColorToggleOff end); updateAFKStatusLabel() end);
    local ePB=createGuiElement("TextButton",{Name="EPB",Size=UDim2.new(0,buttonWidth,1,0), Text="ESP: OFF", Font=Enum.Font.SourceSansSemibold, TextSize=14, TextColor3=Config.ColorTextPrimary, BackgroundColor3=Config.ColorToggleOff, BackgroundTransparency=cBBT, LayoutOrder=3, Parent=eBF, AutoButtonColor=false}); createGuiElement("UICorner",{CornerRadius=UDim.new(0,5),Parent=ePB}); g.ETC.EspPlayerButton=ePB; table.insert(State.TransparencyTargets,ePB); c.EPC=ePB.MouseButton1Click:Connect(toggleEsp); updateEspButtonState()
    lO=lO+1;local aSL=createGuiElement("TextLabel",{Name="ASL",Size=UDim2.new(1,0,0,20),Text="AFK: Bình thường",Font=Enum.Font.SourceSans,TextSize=14,TextColor3=Color3.fromRGB(180,255,180),BackgroundTransparency=1,TextXAlignment=Enum.TextXAlignment.Left,LayoutOrder=lO,Parent=cP });g.ETC.AFKStatusLabel=aSL;updateAFKStatusLabel();

    --===== GUI Footer & Event Connections =====--
    lO=lO+1;createGuiElement("Frame",{Name="BPF",Size=UDim2.new(1,0,0,10),BackgroundTransparency=1,BorderSizePixel=0,LayoutOrder=lO,Parent=cP})
    local function vS(i,s) local n=tonumber(i);if n then n=math.floor(math.clamp(n,Config.MinCPS,Config.MaxCPS)+0.5);if State.CurrentCPS~=n then State.CurrentCPS=n;if s=="T" then safeShowNotification("Auto Clicker",string.format("CPS:%d",State.CurrentCPS),"Clicker") end;updateCPSPlaceholder() end;return true else if s=="T"and i~=""then safeShowNotification("Lỗi CPS","Số?","Clicker")end;updateCPSPlaceholder();return false end end
    local cFL="CFL";if c[cFL] then pcall(c[cFL].Disconnect,c[cFL]) end;c[cFL]=cpsB.FocusLost:Connect(function(eP) local t=cpsB.Text;if t~=""then vS(t,"T")end;cpsB.Text="";updateCPSPlaceholder();if eP then pcall(cpsB.ReleaseFocus,cpsB)end end)
    local cF="CF";if c[cF] then pcall(c[cF].Disconnect,c[cF]) end;c[cF]=cpsB.Focused:Connect(updateCPSPlaceholder)
    local tTBC="TTBC";if c[tTBC] then pcall(c[tTBC].Disconnect,c[tTBC]) end;c[tTBC]=tTB.MouseButton1Click:Connect(function() State.IsTransparent=not State.IsTransparent;local cI=g.CircleIndicator;if cI then pcall(function()TweenService:Create(cI,TWEEN_INFO_FAST,{BackgroundTransparency=State.IsTransparent and 0 or 1}):Play()end)end;updateElementsTransparency(State.IsTransparent) end)
    local gTBC="GTBC";if c[gTBC] then pcall(c[gTBC].Disconnect,c[gTBC]) end;c[gTBC]=gTB.MouseButton1Click:Connect(function() State.GuiVisible=not State.GuiVisible;mF.Visible=State.GuiVisible;if not State.GuiVisible then if State.ChoosingClickPos then cancelClickPositionChoice()end end end)
    connectHotkeyListener();updatePlatformUI();task.wait(0.1);print("Hx: GUI đã tạo.")
end

--===== 🔄 Initialization & Main Loop =====--
local function initialize()
    print("Hx: Bắt đầu initialize...")
    local unlockSuccess, unlockErr = pcall(unlockFPS); if not unlockSuccess then print("Hx: Lỗi unlockFPS:", unlockErr) end
    local guiSuccess, guiErr = pcall(createGUI)
    if not guiSuccess then print("Hx: LỖI TẠO GUI:", guiErr); error("GUI creation failed: "..tostring(guiErr)) end
    if not State.GuiElements.ScreenGui then print("Hx: Lỗi ScreenGui nil."); error("ScreenGui is nil after createGUI.") end

    local connections=State.Connections
    local gIB="GIB";if connections[gIB] then pcall(connections[gIB].Disconnect,connections[gIB]) end
    connections[gIB]=UserInputService.InputBegan:Connect(function(i,gp) local f=pcall(UserInputService.GetFocusedTextBox,UserInputService);if f then return end;if State.IsBindingHotkey or State.ChoosingClickPos then return end;if State.Platform=="PC"and i.UserInputType==Enum.UserInputType.Keyboard and i.KeyCode==State.AutoClickHotkey then return end;if i.UserInputType==Enum.UserInputType.Keyboard or i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.MouseButton2 or i.UserInputType==Enum.UserInputType.Touch then onInputDetected() end end)
    local gIC="GIC";if connections[gIC] then pcall(connections[gIC].Disconnect,connections[gIC]) end
    connections[gIC]=UserInputService.InputChanged:Connect(function(i,gp) local f=pcall(UserInputService.GetFocusedTextBox,UserInputService);if f then return end;if State.IsBindingHotkey or State.ChoosingClickPos then return end;if i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.MouseWheel or string.find(tostring(i.UserInputType),"Gamepad") then onInputDetected() end end)
    if player then local cR="CR";if connections[cR] then pcall(connections[cR].Disconnect,connections[cR]) end;connections[cR]=player.CharacterRemoving:Connect(function()end) end
    local pR="PR";if connections[pR] then pcall(connections[pR].Disconnect,connections[pR]) end;connections[pR]=Players.PlayerRemoving:Connect(function(rP)if rP==player then print("Hx: Player rời, dọn dẹp.");cleanup()end end)

    task.wait(1);safeShowNotification(Config.GuiTitle,"Đã kích hoạt!","System");print("Hx: Script đã khởi chạy.")
    print("Hx: Bắt đầu vòng lặp chính...")

    while _G.UnifiedAntiAFK_AutoClicker_Running do
        local loopSuccess,loopErr=pcall(function() local cT=os.clock();local tS=cT-State.LastInputTime;if Config.EnableIntervention then if State.IsConsideredAFK then local tI,tC=cT-State.LastInterventionTime,cT-State.LastCheckTime;if tI>=Config.InterventionInterval then performAntiAFKAction();State.LastCheckTime=cT elseif tC>=Config.CheckInterval then local tN=math.max(0,Config.InterventionInterval-tI);safeShowNotification("AFK...",string.format("Next ~%.0fs.",tN),"AFK");State.LastCheckTime=cT end else if tS>=Config.AfkThreshold then State.IsConsideredAFK=true;State.LastInterventionTime=cT;State.LastCheckTime=cT;State.InterventionCounter=0;local m=string.format("Next ~%.0fs.",Config.InterventionInterval);safeShowNotification("Cảnh báo AFK!",m,"AFK");updateAFKStatusLabel()end end else if State.IsConsideredAFK then State.IsConsideredAFK=false;updateAFKStatusLabel()end end end)
        if not loopSuccess then print("Hx: Lỗi vòng lặp:",loopErr) end;task.wait(1)
    end;print("Hx: Vòng lặp kết thúc.")
end

--===== ▶️ Script Execution =====--
task.spawn(function()
    local success, err = pcall(initialize)
    if not success then
        print("Hx LỖI KHỞI TẠO:", err)
        if err then print(debug.traceback()) end
        pcall(cleanup)
        _G.UnifiedAntiAFK_AutoClicker_Running = false
    end
end)
