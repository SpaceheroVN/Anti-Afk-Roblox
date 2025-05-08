-- /========================================================================\
-- ||   ██╗  ██╗██╗  ██╗    ███████╗ ██████╗██████╗ ██╗██████╗ ████████╗   ||
-- ||   ██║  ██║╚██╗██╔╝    ██╔════╝██╔════╝██╔══██╗██║██╔══██╗╚══██╔══╝   ||
-- ||   ███████║ ╚███╔╝     ███████╗██║     ██████╔╝██║██████╔╝   ██║      ||
-- ||   ██╔══██║ ██╔██╗     ╚════██║██║     ██╔══██╗██║██╔═══╝    ██║      ||
-- ||   ██║  ██║██╔╝ ██╗    ███████║╚██████╗██║  ██║██║██║        ██║      ||
-- ||   ╚═╝  ╚═╝╚═╝  ╚═╝    ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝╚═╝        ╚═╝      ||
-- \========================================================================/

-- 🎮 Dịch Vụ Roblox
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local UserSettingsService = UserSettings()
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local HttpService = game:GetService("HttpService")
local GuiService = game:GetService("GuiService")

print("Hx_V.0.3: Script Giảm Lag đang tải...")

-- ⚙️ Cài Đặt Script
local ENABLE_UI = true
local ENABLE_NOTIFICATIONS = true
local UI_ICON_ID = "rbxassetid://117118515787811"

-- 🖼️ Cài Đặt Nút UI
local UI_TEXT_SIZE = 14
local UI_ICON_SIZE = UDim2.new(0, 35, 0, 35)
local UI_FRAME_WIDTH = 50
local UI_FRAME_HEIGHT = 50

-- 🔔 Cài Đặt Thông Báo
local NOTIF_DURATION_S = 5
local NOTIF_ANIM_DURATION_S = 0.5
local NOTIF_ICON_ID = "rbxassetid://117118515787811"
local NOTIF_GUI_SIZE = UDim2.new(0, 250, 0, 60)
local NOTIF_CONTAINER_POS = UDim2.new(1, -18, 1, -48)
local NOTIF_CONTAINER_SIZE = UDim2.new(0, 300, 0, 200)

-- Tên UI độc nhất cho phiên bản này
local MAIN_SCREEN_GUI_NAME = "HxLagReducerScreenGui_v036"
local NOTIFICATION_GUI_NAME = "HxNotificationGui_v036"

-- 🚀 Cấu Hình Tối Ưu
local DEFAULT_PRESET_ON_START = DEFAULT_SETTING or "OFF"
local DEFAULT_OPTIMIZATION_CONFIG = {
	DisableGlobalShadows = false, ForceCompatibilityLighting = true, DisablePostEffects = false,
	SimplifyEnvironmentLight = false, DisableParticleEffects = false, OptimizeTerrainWater = false,
	DeleteGenericDecalsTextures = false, DeleteNonEssentialSounds = false, DeleteNonEssentialUI = false,
	ForceLowestQualitySettings = false, OptimizeOnInstanceAdded = false, InstanceAddedCooldown = 0.05,
	ApplyFastFlags = false
}
local currentConfig = table.clone(DEFAULT_OPTIMIZATION_CONFIG)

local PRESETS = {
	Minimal = {
		DisableGlobalShadows = true, OptimizeTerrainWater = true, DisableParticleEffects = true, 
		OptimizeOnInstanceAdded = true,
	},
	Balanced = {
		DisableGlobalShadows = true, ForceCompatibilityLighting = true, DisablePostEffects = true,
		SimplifyEnvironmentLight = true, DisableParticleEffects = true, OptimizeTerrainWater = true,
		ForceLowestQualitySettings = true, OptimizeOnInstanceAdded = true, ApplyFastFlags = true,
	},
	Performance = {
		DisableGlobalShadows = true, ForceCompatibilityLighting = true, DisablePostEffects = true,
		SimplifyEnvironmentLight = true, DisableParticleEffects = true, OptimizeTerrainWater = true,
		DeleteGenericDecalsTextures = true, DeleteNonEssentialSounds = true,
		ForceLowestQualitySettings = true, OptimizeOnInstanceAdded = true, ApplyFastFlags = true
	}
}

-- 📊 Trạng Thái Script
local currentPresetName = "OFF"
local presetCycleOrder = {"OFF", "Minimal", "Balanced", "Performance"}
local optimizedObjects = setmetatable({}, { __mode = "k" })
local isListenerConnected = false
local addInstanceDebounce = false
local isRunning = true
local localPlayer = Players.LocalPlayer
local playerGui = nil
local fastFlagsApplied = false
local fastFlagsSupported = true

-- 💾 Lưu Trữ Cài Đặt Gốc
local originalLightingSettings = {}
local originalTerrainSettings = {}
local originalQualityLevel = Enum.SavedQualitySetting.Automatic
local originalEffectStates = setmetatable({}, {__mode = "k"}) 

-- 🖼️ Biến UI & 🔌 Biến Kết Nối Sự Kiện
local mainFrame, notificationGui, notificationContainer, notificationTemplate
local descendantAddedConn, playerRemovingConn, buttonInputBeganConn, buttonInputEndedConn, buttonClickConn, frameDragConn
local activeTweens = {}

-- 🧹 Chức Năng Dọn Dẹp
local function cleanupResources()
	print("Hx_V.0.3: Bắt đầu dọn dẹp tài nguyên...")
	if not isRunning then return end; isRunning = false
	local connections = {descendantAddedConn,playerRemovingConn,buttonInputBeganConn,buttonInputEndedConn,buttonClickConn,frameDragConn}
	for _,conn in ipairs(connections) do if conn then conn:Disconnect() end end
	descendantAddedConn,playerRemovingConn,buttonInputBeganConn,buttonInputEndedConn,buttonClickConn,frameDragConn = nil,nil,nil,nil,nil,nil
	isListenerConnected = false
	for tween,_ in pairs(activeTweens) do if typeof(tween)=="Instance" and tween:IsA("Tween") then pcall(tween.Cancel,tween) end end; activeTweens = {}
	local notifGuiToDestroy = playerGui and playerGui:FindFirstChild(NOTIFICATION_GUI_NAME); if notifGuiToDestroy then notifGuiToDestroy:Destroy() end
	local mainUiToDestroy = playerGui and playerGui:FindFirstChild(MAIN_SCREEN_GUI_NAME); if mainUiToDestroy then mainUiToDestroy:Destroy() end
	notificationGui,notificationContainer,notificationTemplate,mainFrame = nil,nil,nil,nil
	print("Hx_V.0.3: Dọn dẹp hoàn tất.")
end

-- ✨ Quản Lý Tween
local function trackTween(tween) activeTweens[tween] = true end
local function untrackTween(tween) if activeTweens[tween] then activeTweens[tween] = nil end end

-- 📣 Chức Năng Thông Báo
local function createNotificationTemplate()
	if notificationTemplate and notificationTemplate.Parent == nil then return notificationTemplate end
	notificationTemplate = Instance.new("Frame"); notificationTemplate.Name = "NotificationFrameTemplate"; notificationTemplate.BackgroundColor3 = Color3.fromRGB(30,30,30); notificationTemplate.BackgroundTransparency = 1; notificationTemplate.BorderSizePixel = 0; notificationTemplate.Size = NOTIF_GUI_SIZE; notificationTemplate.ClipsDescendants = true
	local c = Instance.new("UICorner", notificationTemplate); c.CornerRadius = UDim.new(0,8); local p = Instance.new("UIPadding", notificationTemplate); p.PaddingLeft,p.PaddingRight,p.PaddingTop,p.PaddingBottom = UDim.new(0,10),UDim.new(0,10),UDim.new(0,5),UDim.new(0,5)
	local ll = Instance.new("UIListLayout", notificationTemplate); ll.FillDirection,ll.VerticalAlignment,ll.SortOrder,ll.Padding = Enum.FillDirection.Horizontal,Enum.VerticalAlignment.Center,Enum.SortOrder.LayoutOrder,UDim.new(0,10)
	local i = Instance.new("ImageLabel", notificationTemplate); i.Name = "Icon"; i.Image = NOTIF_ICON_ID; i.BackgroundTransparency=1; i.ImageTransparency=1; i.Size=UDim2.new(0,40,0,40); i.LayoutOrder=1
	local tf = Instance.new("Frame", notificationTemplate); tf.Name="TextFrame"; tf.BackgroundTransparency=1; tf.Size=UDim2.new(1,-50,1,0); tf.LayoutOrder=2
	local tll = Instance.new("UIListLayout", tf); tll.FillDirection,tll.HorizontalAlignment,tll.VerticalAlignment,tll.SortOrder,tll.Padding = Enum.FillDirection.Vertical,Enum.HorizontalAlignment.Left,Enum.VerticalAlignment.Center,Enum.SortOrder.LayoutOrder,UDim.new(0,2)
	local tt = Instance.new("TextLabel", tf); tt.Name="Title"; tt.Text="Tiêu đề"; tt.Font=Enum.Font.SourceSansSemibold; tt.TextSize=17; tt.TextColor3=Color3.fromRGB(255,255,255); tt.BackgroundTransparency=1; tt.TextTransparency=1; tt.TextXAlignment=Enum.TextXAlignment.Left; tt.Size=UDim2.new(1,0,0,18); tt.LayoutOrder=1
	local msg = Instance.new("TextLabel", tf); msg.Name="Message"; msg.Text="Nội dung."; msg.Font=Enum.Font.SourceSans; msg.TextSize=14; msg.TextColor3=Color3.fromRGB(200,200,200); msg.BackgroundTransparency=1; msg.TextTransparency=1; msg.TextXAlignment=Enum.TextXAlignment.Left; msg.TextWrapped=true; msg.Size=UDim2.new(1,0,0,28); msg.LayoutOrder=2
	return notificationTemplate
end
local function setupNotificationContainer()
	if notificationContainer and notificationContainer.Parent and notificationGui and notificationGui.Parent then return notificationContainer end
	if not localPlayer or not localPlayer:IsDescendantOf(Players) then warn("Hx_V.0.3: Người chơi cục bộ không hợp lệ."); return nil end
	if not playerGui then warn("Hx_V.0.3: PlayerGui chưa sẵn sàng."); return nil end
	local oldGui = playerGui:FindFirstChild(NOTIFICATION_GUI_NAME); if oldGui then oldGui:Destroy() end
	notificationGui = Instance.new("ScreenGui"); notificationGui.Name=NOTIFICATION_GUI_NAME; notificationGui.ResetOnSpawn=false; notificationGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; notificationGui.DisplayOrder=999; notificationGui.Parent=playerGui
	notificationContainer = Instance.new("Frame", notificationGui); notificationContainer.Name="NotificationContainerFrame"; notificationContainer.AnchorPoint=Vector2.new(1,1); notificationContainer.Position=NOTIF_CONTAINER_POS; notificationContainer.Size=NOTIF_CONTAINER_SIZE; notificationContainer.BackgroundTransparency=1
	local ll = Instance.new("UIListLayout",notificationContainer); ll.FillDirection,ll.HorizontalAlignment,ll.VerticalAlignment,ll.SortOrder,ll.Padding = Enum.FillDirection.Vertical,Enum.HorizontalAlignment.Right,Enum.VerticalAlignment.Bottom,Enum.SortOrder.LayoutOrder,UDim.new(0,5)
	return notificationContainer
end
local function showNotification(title, message)
	local notifTitle = title or "Hx Lag Reducer"; if not ENABLE_NOTIFICATIONS or not isRunning then return end
	if not notificationContainer or not notificationContainer.Parent then if not setupNotificationContainer() then warn("Hx_V.0.3: Khung chứa thông báo lỗi."); return end end
	if not notificationTemplate then if not createNotificationTemplate() then warn("Hx_V.0.3: Mẫu thông báo lỗi."); return end end
	local newNotifFrame = notificationTemplate:Clone(); if not newNotifFrame then warn("Hx_V.0.3: Sao chép mẫu thông báo lỗi."); return end
	local iconImg, textFrame = newNotifFrame:FindFirstChild("Icon"), newNotifFrame:FindFirstChild("TextFrame"); local titleLabel, messageLabel = textFrame and textFrame:FindFirstChild("Title"), textFrame and textFrame:FindFirstChild("Message")
	if not (iconImg and titleLabel and messageLabel) then warn("Hx_V.0.3: Cấu trúc thông báo sao chép bị lỗi."); newNotifFrame:Destroy(); return end
	titleLabel.Text, messageLabel.Text = notifTitle, message or ""; newNotifFrame.Name, newNotifFrame.Parent = "Notification_" .. (notifTitle):gsub("%s+", "_"), notificationContainer
	local tweenInfoIn = TweenInfo.new(NOTIF_ANIM_DURATION_S, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	local tweensIn = {TweenService:Create(newNotifFrame,tweenInfoIn,{BackgroundTransparency=0.2}), TweenService:Create(iconImg,tweenInfoIn,{ImageTransparency=0}), TweenService:Create(titleLabel,tweenInfoIn,{TextTransparency=0}), TweenService:Create(messageLabel,tweenInfoIn,{TextTransparency=0})}
	for _,t in ipairs(tweensIn) do trackTween(t); t.Completed:Connect(function() untrackTween(t) end); t:Play() end
	task.delay(NOTIF_DURATION_S, function()
		if not isRunning or not newNotifFrame or not newNotifFrame.Parent then return end
		local tweenInfoOut = TweenInfo.new(NOTIF_ANIM_DURATION_S,Enum.EasingStyle.Sine,Enum.EasingDirection.In)
		local tweensOut = {TweenService:Create(newNotifFrame,tweenInfoOut,{BackgroundTransparency=1}), TweenService:Create(iconImg,tweenInfoOut,{ImageTransparency=1}), TweenService:Create(titleLabel,tweenInfoOut,{TextTransparency=1}), TweenService:Create(messageLabel,tweenInfoOut,{TextTransparency=1})}
		local completedCount=0; for _,t in ipairs(tweensOut) do trackTween(t); t.Completed:Connect(function() untrackTween(t); completedCount=completedCount+1; if completedCount==#tweensOut and newNotifFrame and newNotifFrame.Parent then newNotifFrame:Destroy() end end); t:Play() end
	end)
end

-- ⚙️ Chức Năng Cốt Lõi Tối Ưu & Phục Hồi
local function saveOriginalSettings()
	originalQualityLevel = Enum.SavedQualitySetting.Automatic
	local success = pcall(function()
		originalLightingSettings.GlobalShadows=Lighting.GlobalShadows; originalLightingSettings.Technology=Lighting.Technology; originalLightingSettings.Brightness=Lighting.Brightness; originalLightingSettings.EnvironmentDiffuseScale=Lighting.EnvironmentDiffuseScale; originalLightingSettings.EnvironmentSpecularScale=Lighting.EnvironmentSpecularScale; originalLightingSettings.Ambient=Lighting.Ambient; originalLightingSettings.OutdoorAmbient=Lighting.OutdoorAmbient
		for _,effect in ipairs(Lighting:GetChildren()) do if effect:IsA("PostEffect") then originalEffectStates[effect]=effect.Enabled end end
		local terrain=Workspace:FindFirstChildOfClass("Terrain"); if terrain then originalTerrainSettings.WaterWaveSize=terrain.WaterWaveSize; originalTerrainSettings.WaterWaveSpeed=terrain.WaterWaveSpeed; originalTerrainSettings.WaterReflectance=terrain.WaterReflectance; originalTerrainSettings.WaterTransparency=terrain.WaterTransparency end
		if UserSettingsService and UserSettingsService.GameSettings then originalQualityLevel=UserSettingsService.GameSettings.SavedQualityLevel
		elseif typeof(settings)=="function" then local s,q=pcall(settings().Rendering.QualityLevel); if s then originalQualityLevel=q end; warn("Hx_V.0.3: API settings() cũ.")
		else warn("Hx_V.0.3: Lỗi UserSettings.") end
	end); if not success then warn("Hx_V.0.3: Lỗi khi lưu cài đặt gốc!") end
end

local function optimizeObjectSafe(obj)
	if not isRunning or optimizedObjects[obj] then return end
	local isPlayerPart = false; if localPlayer and localPlayer.Character and (obj==localPlayer.Character or obj:IsDescendantOf(localPlayer.Character)) then isPlayerPart=true end
	pcall(function()
		if currentConfig.DisableParticleEffects and (obj:IsA("ParticleEmitter") or obj:IsA("Beam") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") or obj:IsA("Explosion")) then
			if obj.Enabled then originalEffectStates[obj]=obj.Enabled; obj.Enabled=false end
		elseif currentConfig.DeleteGenericDecalsTextures and (obj:IsA("Decal") or obj:IsA("Texture")) and not isPlayerPart then obj:Destroy()
		elseif currentConfig.DeleteNonEssentialSounds and obj:IsA("Sound") then if obj.Parent and obj.Name~="BackgroundSound" and not obj.IsPlaying then obj:Destroy() end
		elseif currentConfig.DeleteNonEssentialUI and obj:IsA("ScreenGui") then if obj.Name~=NOTIFICATION_GUI_NAME and obj.Name~=MAIN_SCREEN_GUI_NAME and obj.Name~="CoreGui" and obj.Name~="EssentialUI" and obj.Name~="Chat" then obj:Destroy() end
		end
	end)
	optimizedObjects[obj]=true
end

local function optimizeLightingSafe(isReverting)
	if isReverting then
		local s=pcall(function() for k,v in pairs(originalLightingSettings) do if Lighting[k]~=nil then Lighting[k]=v end end; for ef,en in pairs(originalEffectStates) do if ef and ef.Parent then ef.Enabled=en end end; originalEffectStates=setmetatable({}, {__mode="k"}) end)
		if not s then warn("Hx_V.0.3: Lỗi khôi phục Lighting.") end; return
	end
	local s=pcall(function()
		if currentConfig.DisableGlobalShadows then Lighting.GlobalShadows=false end
		Lighting.Technology = currentConfig.ForceCompatibilityLighting and Enum.Technology.Compatibility or Enum.Technology.Voxel
		if currentConfig.SimplifyEnvironmentLight then Lighting.Brightness,Lighting.EnvironmentDiffuseScale,Lighting.EnvironmentSpecularScale,Lighting.Ambient,Lighting.OutdoorAmbient = 0,0,0,Color3.new(0.2,0.2,0.2),Color3.new(0.2,0.2,0.2) end
		if currentConfig.DisablePostEffects then for _,ef in ipairs(Lighting:GetChildren()) do if ef:IsA("PostEffect") then if ef.Enabled then originalEffectStates[ef]=ef.Enabled; ef.Enabled=false end end end end
	end); if not s then warn("Hx_V.0.3: Lỗi tối ưu Lighting.") end
end

local function optimizeTerrainSafe(isReverting)
	local tr=Workspace:FindFirstChildOfClass("Terrain"); if not tr then return end
	if isReverting then pcall(function() for k,v in pairs(originalTerrainSettings) do if tr[k]~=nil then tr[k]=v end end end); return end
	if currentConfig.OptimizeTerrainWater then pcall(function() tr.WaterWaveSize,tr.WaterWaveSpeed,tr.WaterReflectance,tr.WaterTransparency=0,0,0,1 end) end
end

local function forceLowQualitySettings(isReverting)
	local tq=isReverting and originalQualityLevel or Enum.SavedQualitySetting.QualityLevel1
	if not isReverting and not currentConfig.ForceLowestQualitySettings then return end; if not tq then warn("Hx_V.0.3: Target Quality lỗi."); return end
	local s=pcall(function() if UserSettingsService and UserSettingsService.GameSettings then UserSettingsService.GameSettings.SavedQualityLevel=tq elseif typeof(settings)=="function" then warn("Hx_V.0.3: API settings() cũ.") else error("Lỗi UserSettings/settings() quality.") end end)
	if not s then warn("Hx_V.0.3: Lỗi đặt quality!") end
end

local fastFlagDataJson = [[{"FastFlags":{"FFlagDebugEnableFastSignals":"true","FFlagGraphicsQualityAutoAdjust":"false","FFlagFixGraphicsQualitySettingCrash":"true","FFlagParallelLuaEnable":"true","FFlagRenderShadowSkipHugeCulling":"true","FFlagOcclusionCullingBetaFeature":"true","FFlagUserCameraInputRefactor3":"true","FFlagUserCameraControlLastInputTypeUpdate":"true","FFlagDisablePostFx":"true","FFlagLuaGCThrottleEnabled":"true","FFlagGCEnabledV2":"true","FFlagNetworkCullingNew":"true","FFlagNewPhysicsSenderThrottle":"true","FFlagStreamOutBehaviorFix":"true","FFlagIsFastFlagEnabled":"true","FFlagDebugDisableTelemetryV2Event":"true","FFlagDebugDisableTelemetryV2Stat":"true","FFlagDebugDisableTelemetryEphemeralCounter":"true","DFIntTeleportClientAssetPreloadingHundredthsPercentage":"100000","FIntRenderGrassDetailStrands":"0","FFlagFixVRRaycastLag":"false","FFlagFixVREdgeCasePerf":"false"}}]]
local function applyFastFlags()
	if not fastFlagsSupported then return end
    if fastFlagsApplied then showNotification(nil,"FastFlags đã được áp dụng từ trước."); return end
    local allSetSuccess = true
    local decodeSuccess, flagsTable = pcall(HttpService.JSONDecode, HttpService, fastFlagDataJson)
    if not decodeSuccess or not flagsTable or not flagsTable.FastFlags then
        warn("Hx_V.0.3: Lỗi giải mã JSON FastFlags hoặc cấu trúc không đúng:", flagsTable)
        showNotification(nil,"Lỗi FastFlags: Dữ liệu không hợp lệ.")
        fastFlagsSupported = false
        return
    end

    for n,v in pairs(flagsTable.FastFlags) do 
        local setSuccess, setError = pcall(setfflag, n, v)
        if not setSuccess then
            warn("Hx_V.0.3: Lỗi khi đặt FastFlag '" .. tostring(n) .. "': " .. tostring(setError))
            allSetSuccess = false
            if string.find(tostring(setError or ""), "requires Admin") or string.find(tostring(setError or ""), "The current identity") then
                print("Hx_V.0.3: Phát hiện FastFlags không được hỗ trợ trên nền tảng này.")
                fastFlagsSupported = false
                showNotification(nil,"FastFlags không được hỗ trợ trên thiết bị này.")
                return
            end
        end
    end
    
    if allSetSuccess then
        fastFlagsApplied=true
        print("Hx_V.0.3: ✅ FastFlags đã được bật.")
        showNotification(nil,"FastFlags đã được kích hoạt!")
    else
        warn("Hx_V.0.3: Một số FastFlags không thể áp dụng.")
        showNotification(nil,"Lỗi FastFlags: Một số không thể áp dụng.")
    end
end

local function applyAllSafeOptimizations()
    if not isRunning then return end; optimizeLightingSafe(false); optimizeTerrainSafe(false)
	local st=tick(); local ds=Workspace:GetDescendants(); local c=0
	for i=#ds,1,-1 do if not isRunning then break end; local o=ds[i]; if o and o.Parent then optimizeObjectSafe(o); c=c+1 end; if c%200==0 and tick()-st>0.04 then task.wait(); st=tick() end end
    if not isRunning then return end
	if currentConfig.DeleteNonEssentialUI then for _,p in ipairs(Players:GetPlayers()) do local pG=p:FindFirstChild("PlayerGui"); if pG then local gs=pG:GetChildren(); for i=#gs,1,-1 do if gs[i] and gs[i]:IsA("ScreenGui") then optimizeObjectSafe(gs[i]) end end end end end
	forceLowQualitySettings(false); if currentConfig.ApplyFastFlags and not fastFlagsApplied and fastFlagsSupported then applyFastFlags() end
    if isListenerConnected and (not currentConfig.OptimizeOnInstanceAdded or currentPresetName=="OFF") then if descendantAddedConn then descendantAddedConn:Disconnect() end; descendantAddedConn,isListenerConnected=nil,false
	elseif not isListenerConnected and currentConfig.OptimizeOnInstanceAdded and currentPresetName~="OFF" then isListenerConnected=true; if descendantAddedConn then descendantAddedConn:Disconnect() end
		descendantAddedConn=Workspace.DescendantAdded:Connect(function(d) if not isRunning or addInstanceDebounce then return end; addInstanceDebounce=true; optimizeObjectSafe(d); task.delay(currentConfig.InstanceAddedCooldown,function()addInstanceDebounce=false end) end)
    end
end

local function restoreAllSafeOptimizations()
    if not isRunning then return end; optimizeLightingSafe(true); optimizeTerrainSafe(true); forceLowQualitySettings(true)
	optimizedObjects=setmetatable({}, {__mode="k"})
end

local function applyPreset(presetName)
    if not isRunning then return end
    local primaryMessage = presetName=="OFF" and "Đang tắt & khôi phục..." or "Chuyển sang chế độ: "..presetName; showNotification(nil, primaryMessage)
    if descendantAddedConn then descendantAddedConn:Disconnect(); descendantAddedConn,isListenerConnected=nil,false end
    currentConfig,currentPresetName=table.clone(DEFAULT_OPTIMIZATION_CONFIG),presetName
    if presetName=="OFF" then
        restoreAllSafeOptimizations()
        if fastFlagsApplied and fastFlagsSupported then task.wait(0.5); showNotification("Hx Lag Reducer", "Một số không thể đảo ngược!") end
    else local presetData=PRESETS[presetName]; if presetData then for k,v in pairs(presetData) do if currentConfig[k]~=nil then currentConfig[k]=v else warn("Hx_V.0.3: Key lạ '"..k.."' trong preset '"..presetName.."'") end end; optimizedObjects=setmetatable({}, {__mode="k"}); applyAllSafeOptimizations()
        else warn("Hx_V.0.3: Preset '"..presetName.."' không tìm thấy. Quay về OFF."); applyPreset("OFF"); return end
    end
	if mainFrame and mainFrame.Parent and mainFrame:FindFirstChild("StatusLabel") then pcall(function() mainFrame.StatusLabel.Text="Hx: "..currentPresetName end) end
end

-- 🎨 Chức Năng UI (Nút Bấm & Kéo Thả)
local isDragging=false; local dragStartMousePos=nil; local dragStartFramePos=nil
local function createOrGetUi()
	if not ENABLE_UI or not isRunning then return end
	if not playerGui or not playerGui.Parent then playerGui=localPlayer:WaitForChild("PlayerGui",15) if not playerGui then warn("Hx_V.0.3: PlayerGui lỗi."); return nil end end
	local oldScreenGui=playerGui:FindFirstChild(MAIN_SCREEN_GUI_NAME); if oldScreenGui then oldScreenGui:Destroy(); mainFrame=nil; local conns={buttonInputBeganConn,buttonInputEndedConn,buttonClickConn,frameDragConn}; for _,c in ipairs(conns) do if c then c:Disconnect() end end; buttonInputBeganConn,buttonInputEndedConn,buttonClickConn,frameDragConn=nil,nil,nil,nil end
	local screenGui,tempFrame; local success,result=pcall(function()
		screenGui=Instance.new("ScreenGui"); screenGui.Name=MAIN_SCREEN_GUI_NAME; screenGui.ZIndexBehavior=Enum.ZIndexBehavior.Sibling; screenGui.ResetOnSpawn=false; screenGui.DisplayOrder=1000
		tempFrame=Instance.new("Frame",screenGui); tempFrame.Name="LagReducerFrame"; tempFrame.Size=UDim2.new(0,UI_FRAME_WIDTH,0,UI_FRAME_HEIGHT); tempFrame.AnchorPoint=Vector2.new(0.5,0); tempFrame.Position=UDim2.new(0.25,0,-0.05,0); tempFrame.BackgroundTransparency=0.8; tempFrame.BackgroundColor3=Color3.fromRGB(30,30,30); local fc=Instance.new("UICorner",tempFrame); fc.CornerRadius=UDim.new(0,8)
		local btn=Instance.new("ImageButton",tempFrame); btn.Name="IconButton"; btn.Size=UI_ICON_SIZE; btn.Position=UDim2.new(0.5,0,0,5); btn.AnchorPoint=Vector2.new(0.5,0); btn.BackgroundColor3=Color3.fromRGB(50,50,50); btn.BackgroundTransparency=0.3; btn.Image=UI_ICON_ID; local bc=Instance.new("UICorner",btn); bc.CornerRadius=UDim.new(0,6)
		local lbl=Instance.new("TextLabel",tempFrame); lbl.Name="StatusLabel"; lbl.AutomaticSize=Enum.AutomaticSize.XY; lbl.AnchorPoint=Vector2.new(0.5,0); lbl.Position=UDim2.new(0.5,0,0,UI_ICON_SIZE.Y.Offset+10); lbl.BackgroundColor3=Color3.fromRGB(40,40,40); lbl.BackgroundTransparency=0.5; lbl.Font=Enum.Font.SourceSansSemibold; lbl.TextSize=UI_TEXT_SIZE; lbl.TextColor3=Color3.new(1,1,1); lbl.Text="Hx: "..currentPresetName; local lp=Instance.new("UIPadding",lbl); lp.PaddingTop,lp.PaddingBottom,lp.PaddingLeft,lp.PaddingRight=UDim.new(0,3),UDim.new(0,3),UDim.new(0,6),UDim.new(0,6); local lc=Instance.new("UICorner",lbl); lc.CornerRadius=UDim.new(0,6)
		buttonInputBeganConn=btn.InputBegan:Connect(function(input) if not isRunning or not(input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch) or isDragging then return end; isDragging,dragStartMousePos,dragStartFramePos=true,input.Position,tempFrame.Position; if frameDragConn then frameDragConn:Disconnect() end
			frameDragConn=UserInputService.InputChanged:Connect(function(moveInput) if not(isRunning and isDragging and (moveInput.UserInputType==Enum.UserInputType.MouseMovement or moveInput.UserInputType==Enum.UserInputType.Touch) and dragStartFramePos and dragStartMousePos) then if isDragging and frameDragConn then frameDragConn:Disconnect();frameDragConn=nil end return end; local delta=Vector2.new(moveInput.Position.X-dragStartMousePos.X,moveInput.Position.Y-dragStartMousePos.Y); pcall(function()tempFrame.Position=UDim2.new(dragStartFramePos.X.Scale,dragStartFramePos.X.Offset+delta.X,dragStartFramePos.Y.Scale,dragStartFramePos.Y.Offset+delta.Y)end) end) end)
		buttonInputEndedConn=btn.InputEnded:Connect(function(input) if not isRunning or not(input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch) or not isDragging then return end; isDragging,dragStartMousePos,dragStartFramePos=false,nil,nil; if frameDragConn then frameDragConn:Disconnect();frameDragConn=nil end end)
		buttonClickConn=btn.MouseButton1Click:Connect(function() if not isRunning then return end; local currentIndex=(#presetCycleOrder>0 and table.find(presetCycleOrder,currentPresetName)) or 0; local nextPreset=presetCycleOrder[(currentIndex%#presetCycleOrder)+1]; if nextPreset then applyPreset(nextPreset) else warn("Hx_V.0.3: Lỗi tìm preset tiếp theo.") end end)
		screenGui.Parent=playerGui; return tempFrame end)
	if not success then warn("Hx_V.0.3: LỖI TẠO UI!",result); if screenGui and not screenGui.Parent then screenGui:Destroy() end; return nil else mainFrame=result; return result end
end

-- ▶️ Khởi Tạo Script
local function initializeScript()
	if not localPlayer then
		warn("Hx_V.0.3: localPlayer is nil! Waiting for player...")
		localPlayer = Players.LocalPlayer or Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
		if not localPlayer then warn("Hx_V.0.3: Still cannot get localPlayer! Script cannot initialize."); return end
		print("Hx_V.0.3: localPlayer obtained.")
	end

	playerGui = localPlayer:WaitForChild("PlayerGui", 60)
    if not playerGui then warn("Hx_V.0.3: PlayerGui không tìm thấy! Script không thể khởi tạo."); return end
    
    local oldMainUI = playerGui:FindFirstChild(MAIN_SCREEN_GUI_NAME); if oldMainUI then warn("Hx_V.0.3: Dọn UI chính cũ: ", MAIN_SCREEN_GUI_NAME); oldMainUI:Destroy() end
    local oldNotifUI = playerGui:FindFirstChild(NOTIFICATION_GUI_NAME); if oldNotifUI then warn("Hx_V.0.3: Dọn UI thông báo cũ: ", NOTIFICATION_GUI_NAME); oldNotifUI:Destroy() end
    
	if ENABLE_NOTIFICATIONS then if not createNotificationTemplate() or not setupNotificationContainer() then warn("Hx_V.0.3: Lỗi khởi tạo hệ thống thông báo."); cleanupResources(); return else showNotification(nil,"V.0.3 đã kích hoạt.") end end
	
	if not localPlayer.Character or not localPlayer.Character.Parent then 
        local char = localPlayer.CharacterAdded:Wait()
        if not char then warn("Hx_V.0.3: CharacterAdded trả về nil!") else task.wait(0.5) end
    else task.wait(0.5) end

    currentPresetName = PRESETS[DEFAULT_PRESET_ON_START] and DEFAULT_PRESET_ON_START or "OFF"
	saveOriginalSettings()
	if ENABLE_UI then if not createOrGetUi() then warn("Hx_V.0.3: Lỗi tạo UI nút bấm khi khởi tạo.") end end
	applyPreset(currentPresetName)
    
    if playerRemovingConn then playerRemovingConn:Disconnect() end
    playerRemovingConn = Players.PlayerRemoving:Connect(function(leavingPlayer) if leavingPlayer==localPlayer then cleanupResources() end end)
    print("Hx_V.0.3 Script đã khởi chạy với preset:", currentPresetName)
end

if RunService:IsClient() then
	local canSetFFlagTest, errTest = pcall(setfflag, "HxTestFlag", "true")
	if not canSetFFlagTest then
		if errTest and (string.find(tostring(errTest), "requires Admin") or string.find(tostring(errTest), "The current identity")) then
			print("Hx_V.0.3: FastFlags không được hỗ trợ trên nền tảng này (yêu cầu quyền Admin hoặc do định danh).")
			fastFlagsSupported = false
		else
			print("Hx_V.0.3: Có lỗi khi kiểm tra setfflag, nhưng không phải lỗi quyền Admin. FastFlags có thể không hoạt động đúng. Lỗi:", tostring(errTest))
		end
	else
		print("Hx_V.0.3: FastFlags có vẻ được hỗ trợ.")
	end
	initializeScript()
else
	warn("Hx_V.0.3: Script phải là LocalScript và chạy trên client!")
end
