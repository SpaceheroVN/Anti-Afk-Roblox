local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")
local UserSettings = UserSettings()
local StarterGui = game:GetService("StarterGui")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

print("Hx_V.0.2: Script Lag Reducer đang tải...")

local UI_ENABLED = true
local NOTIFICATIONS_ENABLED = true
local ICON_IMAGE_ID_LAG_REDUCER = "rbxassetid://117118515787811"

local TEXT_SIZE = 16
local NEW_ICON_SIZE = UDim2.new(0, 60, 0, 60)
local NEW_FRAME_WIDTH = 80
local NEW_FRAME_HEIGHT = 90

local THOI_LUONG_THONG_BAO_GIAY = 5
local THOI_GIAN_HOAT_ANH_GIAY = 0.5
local ID_HINH_ANH_ICON_NOTIFICATION = "rbxassetid://117118515787811" 
local KICH_THUOC_GUI_THONG_BAO = UDim2.new(0, 250, 0, 60)
local VI_TRI_KHUNG_CHUA = UDim2.new(1, -18, 1, -48)
local KICH_THUOC_KHUNG_CHUA = UDim2.new(0, 300, 0, 200)

local SELECTED_PRESET = "OFF"
local CONFIG = {
	DISABLE_COLLISIONS = false, ANCHOR_ALL_PARTS = false,
	DISABLE_GLOBAL_SHADOWS = true, FORCE_VOXEL_LIGHTING = false,
	DISABLE_POST_EFFECTS = false, DISABLE_ATMOSPHERE = false, DISABLE_CLOUDS = false,
	HIDE_CELESTIAL_BODIES = false, SIMPLIFY_ENVIRONMENT_LIGHT = false,
	DISABLE_PARTICLES_ETC = false, DELETE_DECALS_TEXTURES = false,
	OPTIMIZE_TERRAIN = true, FLATTEN_TERRAIN_WATER = false,
	SIMPLIFY_MATERIALS = false, DELETE_NON_PLAYER_MODELS = false, FORCE_SIMPLE_GEOMETRY = false,
	SAFE_GEOMETRY_NAMES = {"Baseplate", "SpawnLocation", "HumanoidRootPart"},
	DELETE_SOUNDS = false, DELETE_UI = false,
	FORCE_LOWEST_QUALITY = false,
	OPTIMIZE_ON_ADD = true,
	OPTIMIZE_ADD_COOLDOWN = 0.05,
}
local PRESETS = {
	Minimal = { DISABLE_GLOBAL_SHADOWS = true, OPTIMIZE_TERRAIN = true, FLATTEN_TERRAIN_WATER = true, OPTIMIZE_ON_ADD = true },
	Balanced = { DISABLE_COLLISIONS = false, ANCHOR_ALL_PARTS = false, DISABLE_GLOBAL_SHADOWS = true, FORCE_VOXEL_LIGHTING = true, DISABLE_POST_EFFECTS = true, DISABLE_ATMOSPHERE = true, DISABLE_CLOUDS = true, HIDE_CELESTIAL_BODIES = true, DISABLE_PARTICLES_ETC = true, OPTIMIZE_TERRAIN = true, FLATTEN_TERRAIN_WATER = true, SIMPLIFY_MATERIALS = true, FORCE_LOWEST_QUALITY = true, OPTIMIZE_ON_ADD = true },
	PerformanceBoost = { DISABLE_COLLISIONS = false, ANCHOR_ALL_PARTS = false, DISABLE_GLOBAL_SHADOWS = true, FORCE_VOXEL_LIGHTING = true, DISABLE_POST_EFFECTS = true, DISABLE_ATMOSPHERE = true, DISABLE_CLOUDS = true, HIDE_CELESTIAL_BODIES = false, SIMPLIFY_ENVIRONMENT_LIGHT = true, DISABLE_PARTICLES_ETC = true, DELETE_DECALS_TEXTURES = true, OPTIMIZE_TERRAIN = true, FLATTEN_TERRAIN_WATER = true, SIMPLIFY_MATERIALS = true, FORCE_LOWEST_QUALITY = true, OPTIMIZE_ON_ADD = true },
	UltraLow = { DISABLE_COLLISIONS = false, ANCHOR_ALL_PARTS = false, DISABLE_GLOBAL_SHADOWS = true, FORCE_VOXEL_LIGHTING = true, DISABLE_POST_EFFECTS = true, DISABLE_ATMOSPHERE = true, DISABLE_CLOUDS = true, HIDE_CELESTIAL_BODIES = true, SIMPLIFY_ENVIRONMENT_LIGHT = true, DISABLE_PARTICLES_ETC = true, DELETE_DECALS_TEXTURES = true, OPTIMIZE_TERRAIN = true, FLATTEN_TERRAIN_WATER = true, SIMPLIFY_MATERIALS = true, DELETE_NON_PLAYER_MODELS = true, FORCE_SIMPLE_GEOMETRY = true, DELETE_SOUNDS = true, FORCE_LOWEST_QUALITY = true, OPTIMIZE_ON_ADD = true }
}

local currentPresetName = "OFF"
local availablePresets = {"OFF", "Minimal", "Balanced", "PerformanceBoost", "UltraLow"}
local optimizedObjects = setmetatable({}, { __mode = "k" })
local listenerConnected = false
local optimizeAddDebounce = false
local dangChay = true
local player = Players.LocalPlayer
local playerGui = nil

local lagReducerFrame = nil 
local giaoDienManHinhThongBao = nil 
local khungChuaThongBao = nil 
local mauThongBao = nil 

local descendantAddedConn = nil
local playerRemovingConn = nil
local buttonInputBeganConn = nil
local buttonInputEndedConn = nil
local buttonClickConn = nil
local dragMoveConnection = nil
local cacTweenDangHoatDong = {} 

local function donDepTaiNguyen()
	print("Hx_V.0.2: Bắt đầu dọn dẹp tài nguyên...")
	if not dangChay then return end
	dangChay = false

	if descendantAddedConn then descendantAddedConn:Disconnect(); descendantAddedConn = nil end
	if playerRemovingConn then playerRemovingConn:Disconnect(); playerRemovingConn = nil end
	if buttonInputBeganConn then buttonInputBeganConn:Disconnect(); buttonInputBeganConn = nil end
	if buttonInputEndedConn then buttonInputEndedConn:Disconnect(); buttonInputEndedConn = nil end
	if buttonClickConn then buttonClickConn:Disconnect(); buttonClickConn = nil end
	if dragMoveConnection then dragMoveConnection:Disconnect(); dragMoveConnection = nil end
	listenerConnected = false

	for tweenInstance, _ in pairs(cacTweenDangHoatDong) do
		if typeof(tweenInstance) == "Instance" and tweenInstance:IsA("Tween") then
			pcall(function() tweenInstance:Cancel() end)
		end
	end
	cacTweenDangHoatDong = {}

	if giaoDienManHinhThongBao and giaoDienManHinhThongBao.Parent then
		giaoDienManHinhThongBao:Destroy()
	end
	local lagReducerGui = playerGui and playerGui:FindFirstChild("LagReducerScreenGui")
	if lagReducerGui then
		lagReducerGui:Destroy()
	end

	giaoDienManHinhThongBao = nil
	khungChuaThongBao = nil
	mauThongBao = nil
	lagReducerFrame = nil

	print("Hx_V.0.2: Dọn dẹp hoàn tất.")
end

local function xoaTweenKhoiTheoDoi(tweenInstance)
	if cacTweenDangHoatDong[tweenInstance] then
		cacTweenDangHoatDong[tweenInstance] = nil
	end
end

local function taoMauThongBao()
	if mauThongBao and mauThongBao.Parent == nil then
		return mauThongBao
	end

	local frame = Instance.new("Frame")
	frame.Name = "NotificationFrameTemplate"
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Size = KICH_THUOC_GUI_THONG_BAO 
	frame.ClipsDescendants = true
	mauThongBao = frame 

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
	icon.Image = ID_HINH_ANH_ICON_NOTIFICATION 
	icon.BackgroundTransparency = 1
	icon.ImageTransparency = 1
	icon.Size = UDim2.new(0, 40, 0, 40)
	icon.LayoutOrder = 1
	icon.Parent = frame

	local textFrame = Instance.new("Frame")
	textFrame.Name = "TextFrame"
	textFrame.BackgroundTransparency = 1
	textFrame.Size = UDim2.new(1, -50, 1, 0)
	textFrame.LayoutOrder = 2
	textFrame.Parent = frame

	local textListLayout = Instance.new("UIListLayout", textFrame)
	textListLayout.FillDirection = Enum.FillDirection.Vertical
	textListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	textListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	textListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	textListLayout.Padding = UDim.new(0, 2)

	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Text = "Tiêu đề"
	title.Font = Enum.Font.GothamBold 
	title.TextSize = 15
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.BackgroundTransparency = 1
	title.TextTransparency = 1
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Size = UDim2.new(1, 0, 0, 18)
	title.LayoutOrder = 1
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
	message.TextWrapped = true
	message.Size = UDim2.new(1, 0, 0, 28) 
	message.LayoutOrder = 2
	message.Parent = textFrame

	return mauThongBao
end

local function thietLapKhungChuaThongBao()
	if khungChuaThongBao and khungChuaThongBao.Parent and giaoDienManHinhThongBao and giaoDienManHinhThongBao.Parent then
		return khungChuaThongBao
	end

	if not player or not player:IsDescendantOf(Players) then
		warn("Hx_V.0.2: Đối tượng người chơi cục bộ không hợp lệ.")
		return nil
	end
	if not playerGui then
		 warn("Hx_V.0.2: PlayerGui chưa sẵn sàng.")
		 return nil
	end

	local oldGui = playerGui:FindFirstChild("HxNotificationGui") 
	if oldGui then
		oldGui:Destroy()
	end

	giaoDienManHinhThongBao = Instance.new("ScreenGui")
	giaoDienManHinhThongBao.Name = "HxNotificationGui" 
	giaoDienManHinhThongBao.ResetOnSpawn = false
	giaoDienManHinhThongBao.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	giaoDienManHinhThongBao.DisplayOrder = 999 
	giaoDienManHinhThongBao.Parent = playerGui

	local container = Instance.new("Frame")
	container.Name = "NotificationContainerFrame"
	container.AnchorPoint = Vector2.new(1, 1)
	container.Position = VI_TRI_KHUNG_CHUA 
	container.Size = KICH_THUOC_KHUNG_CHUA 
	container.BackgroundTransparency = 1
	container.Parent = giaoDienManHinhThongBao 

	local listLayout = Instance.new("UIListLayout", container)
	listLayout.FillDirection = Enum.FillDirection.Vertical
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	listLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 5)

	khungChuaThongBao = container 
	return khungChuaThongBao
end

local function showNotification(tieuDe, noiDung)
	if not NOTIFICATIONS_ENABLED or not dangChay then return end

	if not khungChuaThongBao or not khungChuaThongBao.Parent then
        if not thietLapKhungChuaThongBao() then
		    warn("Hx_V.0.2: Khung chứa thông báo không hợp lệ và không thể tạo.")
            return
        end
    end
	if not mauThongBao then
        if not taoMauThongBao() then
            warn("Hx_V.0.2: Mẫu thông báo chưa được tạo và không thể tạo.")
            return
        end
    end

	local khungMoi = mauThongBao:Clone()
	if not khungMoi then warn("Hx_V.0.2: Không thể clone mẫu thông báo."); return end

	local hinhIcon = khungMoi:FindFirstChild("Icon")
	local khungChu = khungMoi:FindFirstChild("TextFrame")
	local nhanTieuDe = khungChu and khungChu:FindFirstChild("Title")
	local nhanNoiDung = khungChu and khungChu:FindFirstChild("Message")

	if not (hinhIcon and nhanTieuDe and nhanNoiDung) then
		warn("Hx_V.0.2: Khung thông báo clone bị lỗi cấu trúc.")
		khungMoi:Destroy()
		return
	end

	nhanTieuDe.Text = tieuDe or "Thông báo" 
	nhanNoiDung.Text = noiDung or ""
	khungMoi.Name = "Notification_" .. (tieuDe or "Default"):gsub("%s+", "_") 
	khungMoi.Parent = khungChuaThongBao 

	local thongTinTweenXuatHien = TweenInfo.new(THOI_GIAN_HOAT_ANH_GIAY, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	local tweenMoDanKhung = TweenService:Create(khungMoi, thongTinTweenXuatHien, { BackgroundTransparency = 0.2 })
	local tweenMoDanIcon = TweenService:Create(hinhIcon, thongTinTweenXuatHien, { ImageTransparency = 0 })
	local tweenMoDanTieuDe = TweenService:Create(nhanTieuDe, thongTinTweenXuatHien, { TextTransparency = 0 })
	local tweenMoDanNoiDung = TweenService:Create(nhanNoiDung, thongTinTweenXuatHien, { TextTransparency = 0 })

	cacTweenDangHoatDong[tweenMoDanKhung] = true
	cacTweenDangHoatDong[tweenMoDanIcon] = true
	cacTweenDangHoatDong[tweenMoDanTieuDe] = true
	cacTweenDangHoatDong[tweenMoDanNoiDung] = true

	tweenMoDanKhung.Completed:Connect(function() xoaTweenKhoiTheoDoi(tweenMoDanKhung) end)
	tweenMoDanIcon.Completed:Connect(function() xoaTweenKhoiTheoDoi(tweenMoDanIcon) end)
	tweenMoDanTieuDe.Completed:Connect(function() xoaTweenKhoiTheoDoi(tweenMoDanTieuDe) end)
	tweenMoDanNoiDung.Completed:Connect(function() xoaTweenKhoiTheoDoi(tweenMoDanNoiDung) end)

	tweenMoDanKhung:Play()
	tweenMoDanIcon:Play()
	tweenMoDanTieuDe:Play()
	tweenMoDanNoiDung:Play()

	task.delay(THOI_LUONG_THONG_BAO_GIAY, function()
		if not dangChay or not khungMoi or not khungMoi.Parent then 
			xoaTweenKhoiTheoDoi(tweenMoDanKhung)
			xoaTweenKhoiTheoDoi(tweenMoDanIcon)
			xoaTweenKhoiTheoDoi(tweenMoDanTieuDe)
			xoaTweenKhoiTheoDoi(tweenMoDanNoiDung)
			return
		end

		local thongTinTweenBienMat = TweenInfo.new(THOI_GIAN_HOAT_ANH_GIAY, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
		local tweenMoDanKhung_Mat = TweenService:Create(khungMoi, thongTinTweenBienMat, { BackgroundTransparency = 1 })
		local tweenMoDanIcon_Mat = TweenService:Create(hinhIcon, thongTinTweenBienMat, { ImageTransparency = 1 })
		local tweenMoDanTieuDe_Mat = TweenService:Create(nhanTieuDe, thongTinTweenBienMat, { TextTransparency = 1 })
		local tweenMoDanNoiDung_Mat = TweenService:Create(nhanNoiDung, thongTinTweenBienMat, { TextTransparency = 1 })

		cacTweenDangHoatDong[tweenMoDanKhung_Mat] = true
		cacTweenDangHoatDong[tweenMoDanIcon_Mat] = true
		cacTweenDangHoatDong[tweenMoDanTieuDe_Mat] = true
		cacTweenDangHoatDong[tweenMoDanNoiDung_Mat] = true

		tweenMoDanKhung_Mat.Completed:Connect(function()
			xoaTweenKhoiTheoDoi(tweenMoDanKhung_Mat)
			xoaTweenKhoiTheoDoi(tweenMoDanIcon_Mat)
			xoaTweenKhoiTheoDoi(tweenMoDanTieuDe_Mat)
			xoaTweenKhoiTheoDoi(tweenMoDanNoiDung_Mat)

			if khungMoi and khungMoi.Parent then
				khungMoi:Destroy()
			end
		end)

		tweenMoDanKhung_Mat:Play()
		tweenMoDanIcon_Mat:Play()
		tweenMoDanTieuDe_Mat:Play()
		tweenMoDanNoiDung_Mat:Play()
	end)
end

local function isPartOfCharacter(object)
	if not (object:IsA("BasePart") or object:IsA("Accessory") or object:IsA("Tool")) then return false end
	for _, p in pairs(Players:GetPlayers()) do if p.Character and object:IsDescendantOf(p.Character) then return true end end
	return false
end

local originalLightingSettings = {}
local originalTerrainSettings = {}
local originalQualityLevel = Enum.SavedQualitySetting.Automatic

local function storeOriginalSettings()
	originalQualityLevel = Enum.SavedQualitySetting.Automatic
	local success, err = pcall(function()
		pcall(function() originalLightingSettings.GlobalShadows = Lighting.GlobalShadows end); pcall(function() originalLightingSettings.Technology = Lighting.Technology end); pcall(function() originalLightingSettings.Brightness = Lighting.Brightness end); pcall(function() originalLightingSettings.EnvironmentDiffuseScale = Lighting.EnvironmentDiffuseScale end); pcall(function() originalLightingSettings.EnvironmentSpecularScale = Lighting.EnvironmentSpecularScale end); pcall(function() originalLightingSettings.Ambient = Lighting.Ambient end); pcall(function() originalLightingSettings.OutdoorAmbient = Lighting.OutdoorAmbient end)
		local terrain = Workspace:FindFirstChildOfClass("Terrain"); if terrain then pcall(function() originalTerrainSettings.WaterWaveSize = terrain.WaterWaveSize end); pcall(function() originalTerrainSettings.WaterWaveSpeed = terrain.WaterWaveSpeed end); pcall(function() originalTerrainSettings.WaterReflectance = terrain.WaterReflectance end); pcall(function() originalTerrainSettings.WaterTransparency = terrain.WaterTransparency end) end
		pcall(function() if UserSettings and UserSettings.GameSettings then originalQualityLevel = UserSettings.GameSettings.SavedQualityLevel elseif typeof(settings) == "function" then warn("Hx_V.0.2: Không thể lưu cài đặt chất lượng gốc từ API settings() cũ.") else warn("Hx_V.0.2: Không thể truy cập UserSettings để lưu chất lượng gốc.") end end)
	end)
	if not success then warn("Hx_V.0.2: Lỗi khi lưu cài đặt gốc!", err) end
end

local function optimizeObject(obj)
	if not dangChay then return end
	if lagReducerFrame and (obj == lagReducerFrame or obj:IsDescendantOf(lagReducerFrame)) then return end
	if giaoDienManHinhThongBao and (obj == giaoDienManHinhThongBao or obj:IsDescendantOf(giaoDienManHinhThongBao)) then return end
	local isValid = pcall(function() return obj and obj.Parent end); if not isValid or optimizedObjects[obj] then return end
	local isCharacterPart = isPartOfCharacter(obj); local success, err = pcall(function()
		if CONFIG.DISABLE_PARTICLES_ETC and (obj:IsA("ParticleEmitter") or obj:IsA("Beam") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") or obj:IsA("Explosion")) then obj.Enabled = false end
		if CONFIG.DELETE_DECALS_TEXTURES and (obj:IsA("Decal") or obj:IsA("Texture")) then obj:Destroy(); return end
		if CONFIG.DELETE_SOUNDS and obj:IsA("Sound") then obj:Destroy(); return end
		if obj:IsA("BasePart") then if not isCharacterPart then if CONFIG.ANCHOR_ALL_PARTS then obj.Anchored = true end; if CONFIG.DISABLE_COLLISIONS then obj.CanCollide, obj.CanTouch, obj.CanQuery = false, false, false end; if CONFIG.FORCE_SIMPLE_GEOMETRY and (obj:IsA("MeshPart") or obj:IsA("UnionOperation")) then if not table.find(CONFIG.SAFE_GEOMETRY_NAMES, obj.Name) then obj:Destroy(); return end end end; if CONFIG.DISABLE_GLOBAL_SHADOWS then obj.CastShadow = false end; if CONFIG.SIMPLIFY_MATERIALS then obj.Material, obj.Reflectance = Enum.Material.Plastic, 0 end end
		if CONFIG.DELETE_NON_PLAYER_MODELS and obj:IsA("Model") and not obj:FindFirstChildWhichIsA("Humanoid") and not Players:GetPlayerFromCharacter(obj) then if obj.Name ~= "ImportantModelExample" and obj.Name ~= "Map" then obj:Destroy(); return end end
		if CONFIG.DELETE_UI and obj:IsA("ScreenGui") then
			if obj ~= giaoDienManHinhThongBao and obj.Name ~= "LagReducerScreenGui" and obj.Name ~= "CoreGui" and obj.Name ~= "EssentialUI" then
				obj:Destroy()
				return
			end
		end
	end); if success or isValid then optimizedObjects[obj] = true end
end

local function optimizeLighting(isReverting)
	local s, e; if isReverting then s, e = pcall(function() if originalLightingSettings.GlobalShadows ~= nil then pcall(function() Lighting.GlobalShadows = originalLightingSettings.GlobalShadows end) end; if originalLightingSettings.Technology ~= nil then pcall(function() Lighting.Technology = originalLightingSettings.Technology end) end; if originalLightingSettings.Brightness ~= nil then pcall(function() Lighting.Brightness = originalLightingSettings.Brightness end) end; if originalLightingSettings.EnvironmentDiffuseScale ~= nil then pcall(function() Lighting.EnvironmentDiffuseScale = originalLightingSettings.EnvironmentDiffuseScale end) end; if originalLightingSettings.EnvironmentSpecularScale ~= nil then pcall(function() Lighting.EnvironmentSpecularScale = originalLightingSettings.EnvironmentSpecularScale end) end; if originalLightingSettings.Ambient ~= nil then pcall(function() Lighting.Ambient = originalLightingSettings.Ambient end) end; if originalLightingSettings.OutdoorAmbient ~= nil then pcall(function() Lighting.OutdoorAmbient = originalLightingSettings.OutdoorAmbient end) end; if CONFIG.DISABLE_POST_EFFECTS then for _, v in pairs(Lighting:GetChildren()) do if v and v:IsA("PostEffect") then pcall(function() v.Enabled = true end) end end end; local k = Lighting:FindFirstChildOfClass("Sky"); if CONFIG.HIDE_CELESTIAL_BODIES and k then pcall(function() k.CelestialBodiesShown = true end) end end); if not s then warn("Hx_V.0.2: Lỗi khôi phục Lighting:", e) end; return end
	s, e = pcall(function() if CONFIG.DISABLE_GLOBAL_SHADOWS then Lighting.GlobalShadows = false end; if CONFIG.FORCE_VOXEL_LIGHTING then Lighting.Technology = Enum.Technology.Voxel end; pcall(function() Lighting.FogEnd = 1000000 end); if CONFIG.SIMPLIFY_ENVIRONMENT_LIGHT then Lighting.Brightness, Lighting.EnvironmentDiffuseScale, Lighting.EnvironmentSpecularScale = 0, 0, 0; Lighting.Ambient, Lighting.OutdoorAmbient = Color3.fromRGB(50, 50, 50), Color3.fromRGB(50, 50, 50) end; if CONFIG.DISABLE_POST_EFFECTS then for _, v in pairs(Lighting:GetChildren()) do if v and v:IsA("PostEffect") then v.Enabled = false end end end; local a = Lighting:FindFirstChildOfClass("Atmosphere"); if CONFIG.DISABLE_ATMOSPHERE and a then a:Destroy() end; local l = Lighting:FindFirstChildOfClass("Clouds"); if CONFIG.DISABLE_CLOUDS and l then l:Destroy() end; local k = Lighting:FindFirstChildOfClass("Sky"); if CONFIG.HIDE_CELESTIAL_BODIES and k then k.CelestialBodiesShown = false end end); if not s then warn("Hx_V.0.2: Lỗi tối ưu hóa Lighting:", e) end
end

local function optimizeTerrain(isReverting)
	local terrain = Workspace:FindFirstChildOfClass("Terrain"); if not terrain then return end; local s, e; if isReverting then s, e = pcall(function() if originalTerrainSettings.WaterWaveSize ~= nil then pcall(function() terrain.WaterWaveSize = originalTerrainSettings.WaterWaveSize end) end; if originalTerrainSettings.WaterWaveSpeed ~= nil then pcall(function() terrain.WaterWaveSpeed = originalTerrainSettings.WaterWaveSpeed end) end; if originalTerrainSettings.WaterReflectance ~= nil then pcall(function() terrain.WaterReflectance = originalTerrainSettings.WaterReflectance end) end; if originalTerrainSettings.WaterTransparency ~= nil then pcall(function() terrain.WaterTransparency = originalTerrainSettings.WaterTransparency end) end end); if not s then warn("Hx_V.0.2: Lỗi khôi phục Terrain:", e) end; return end
	if not CONFIG.OPTIMIZE_TERRAIN then return end; s, e = pcall(function() if CONFIG.FLATTEN_TERRAIN_WATER then terrain.WaterWaveSize, terrain.WaterWaveSpeed, terrain.WaterReflectance, terrain.WaterTransparency = 0, 0, 0, 1 end end); if not s then warn("Hx_V.0.2: Lỗi tối ưu hóa Terrain:", e) end
end

local function forceLowQuality(isReverting)
	local targetSavedQuality; if isReverting then targetSavedQuality = originalQualityLevel else targetSavedQuality = Enum.SavedQualitySetting.QualityLevel1 end
	if not isReverting and not CONFIG.FORCE_LOWEST_QUALITY then return end; if not targetSavedQuality then warn("Hx_V.0.2: Không thể xác định giá trị SavedQualitySetting đích."); return end
	local success, err = pcall(function() if UserSettings and UserSettings.GameSettings then UserSettings.GameSettings.SavedQualityLevel = targetSavedQuality elseif typeof(settings) == "function" then warn("Hx_V.0.2: API settings() cũ không được hỗ trợ cập nhật SavedQualitySetting.") else error("Cannot access UserSettings or settings() to change quality level.") end end)
	if not success then warn("Hx_V.0.2: Lỗi đặt mức chất lượng đồ họa (SavedQualityLevel)! ", err) end
end

local function applyAllOptimizations(is_rerun)
    if not dangChay then return end
	optimizeLighting(false); optimizeTerrain(false); local startOptimizeTime = tick(); local descendants = Workspace:GetDescendants()
	local count = 0
	for i = #descendants, 1, -1 do
        if not dangChay then break end
        local obj = descendants[i];
        if obj and obj.Parent then optimizeObject(obj); count = count + 1; end;
        if tick() - startOptimizeTime > 0.05 then task.wait(); startOptimizeTime = tick() end
    end
    if not dangChay then return end

	if CONFIG.DELETE_UI then
        local ui_count = 0
        for _, p in pairs(Players:GetPlayers()) do
            local pGui = p:FindFirstChild("PlayerGui");
            if pGui then
                local guis = pGui:GetChildren();
                for i = #guis, 1, -1 do
                    if guis[i] and guis[i]:IsA("ScreenGui") then optimizeObject(guis[i]); ui_count = ui_count + 1; end
                end
            end
        end
    end
	forceLowQuality(false);

    if listenerConnected and (not CONFIG.OPTIMIZE_ON_ADD or currentPresetName == "OFF") then
        if descendantAddedConn then descendantAddedConn:Disconnect() end; descendantAddedConn = nil; listenerConnected = false
	elseif not listenerConnected and CONFIG.OPTIMIZE_ON_ADD and currentPresetName ~= "OFF" then
        listenerConnected = true;
        if descendantAddedConn then descendantAddedConn:Disconnect() end;
        descendantAddedConn = game.DescendantAdded:Connect(function(descendant)
            if not dangChay or optimizeAddDebounce then return end;
            optimizeAddDebounce = true;
            optimizeObject(descendant);
            task.delay(CONFIG.OPTIMIZE_ADD_COOLDOWN, function() optimizeAddDebounce = false end)
        end)
    end
end

local function applyPreset(presetName)
    if not dangChay then return end
	local notificationMessage = "Đang chuyển sang chế độ: " .. presetName; if presetName == "OFF" then notificationMessage = "Đang tắt tối ưu hóa..." end;
    showNotification("Hx_V.0.2", notificationMessage) 

	if descendantAddedConn then descendantAddedConn:Disconnect(); descendantAddedConn = nil; listenerConnected = false end
    optimizedObjects = setmetatable({}, { __mode = "k" })

	local defaultConfig = { DISABLE_COLLISIONS = false, ANCHOR_ALL_PARTS = false, DISABLE_GLOBAL_SHADOWS = true, FORCE_VOXEL_LIGHTING = false, DISABLE_POST_EFFECTS = false, DISABLE_ATMOSPHERE = false, DISABLE_CLOUDS = false, HIDE_CELESTIAL_BODIES = false, SIMPLIFY_ENVIRONMENT_LIGHT = false, DISABLE_PARTICLES_ETC = false, DELETE_DECALS_TEXTURES = false, OPTIMIZE_TERRAIN = true, FLATTEN_TERRAIN_WATER = false, SIMPLIFY_MATERIALS = false, DELETE_NON_PLAYER_MODELS = false, FORCE_SIMPLE_GEOMETRY = false, SAFE_GEOMETRY_NAMES = {"Baseplate", "SpawnLocation", "HumanoidRootPart"}, DELETE_SOUNDS = false, DELETE_UI = false, FORCE_LOWEST_QUALITY = false, OPTIMIZE_ON_ADD = false, OPTIMIZE_ADD_COOLDOWN = 0.05, }
	currentPresetName = presetName;

    if presetName == "OFF" then
        CONFIG = defaultConfig;
        CONFIG.OPTIMIZE_ON_ADD = false;
        optimizeLighting(true);
        optimizeTerrain(true);
        forceLowQuality(true)
    else
        local presetConfigData = PRESETS[presetName];
        if presetConfigData then
            CONFIG = table.clone(defaultConfig);
            CONFIG.OPTIMIZE_ON_ADD = true;
            for key, value in pairs(presetConfigData) do
                if CONFIG[key] ~= nil then
                    CONFIG[key] = value
                else
                    warn("Hx_V.0.2: Không rõ key config trong preset", presetName, ":", key)
                end
            end
            applyAllOptimizations(true)
        else
            warn("Hx_V.0.2: Preset không tìm thấy:", presetName, ". Đang quay về OFF.");
            applyPreset("OFF");
            return
        end
    end

	if lagReducerFrame and lagReducerFrame.Parent and lagReducerFrame:FindFirstChild("StatusLabel") then
        pcall(function()
            lagReducerFrame.StatusLabel.Text = "Hx: " .. currentPresetName 
        end)
    end
end

local isDragging = false
local dragStartMousePos = nil
local dragStartFramePosUDim2 = nil

local function createOrGetUI()
	if not UI_ENABLED or not dangChay then return end
	if not playerGui or not playerGui.Parent then
		playerGui = player:WaitForChild("PlayerGui", 15);
		if not playerGui then warn("Hx_V.0.2: PlayerGui không tìm thấy trong createOrGetUI."); return nil end
	end

	local existingScreenGui = playerGui:FindFirstChild("LagReducerScreenGui")
	if existingScreenGui then
		existingScreenGui:Destroy()
		lagReducerFrame = nil
		if buttonInputBeganConn then buttonInputBeganConn:Disconnect(); buttonInputBeganConn = nil end
		if buttonInputEndedConn then buttonInputEndedConn:Disconnect(); buttonInputEndedConn = nil end
		if buttonClickConn then buttonClickConn:Disconnect(); buttonClickConn = nil end
		if dragMoveConnection then dragMoveConnection:Disconnect(); dragMoveConnection = nil end
	end

	local screenGui
	local tempLagReducerFrame = nil
	local success, result = pcall(function()
		screenGui = Instance.new("ScreenGui"); screenGui.Name = "LagReducerScreenGui"; screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling; screenGui.ResetOnSpawn = false; screenGui.Enabled = true; screenGui.DisplayOrder = 1000

		tempLagReducerFrame = Instance.new("Frame"); tempLagReducerFrame.Name = "LagReducerFrame"; tempLagReducerFrame.Size = UDim2.new(0, NEW_FRAME_WIDTH, 0, NEW_FRAME_HEIGHT); tempLagReducerFrame.AnchorPoint = Vector2.new(0.5, 0); tempLagReducerFrame.Position = UDim2.new(0.5, 0, 0, 20); tempLagReducerFrame.BackgroundTransparency = 0.8; tempLagReducerFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30); tempLagReducerFrame.BorderSizePixel = 0; tempLagReducerFrame.Visible = true; tempLagReducerFrame.ZIndex = 1
		tempLagReducerFrame.Active = false
		local frameCorner = Instance.new("UICorner", tempLagReducerFrame); frameCorner.CornerRadius = UDim.new(0, 8)
		tempLagReducerFrame.Parent = screenGui

		local iconButton = Instance.new("ImageButton"); iconButton.Name = "IconButton"; iconButton.Size = NEW_ICON_SIZE; iconButton.Position = UDim2.new(0.5, 0, 0, 5); iconButton.AnchorPoint = Vector2.new(0.5, 0); iconButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50); iconButton.BackgroundTransparency = 0.3; iconButton.Image = ICON_IMAGE_ID_LAG_REDUCER; iconButton.Visible = true; iconButton.ZIndex = 2; iconButton.BorderSizePixel = 0; iconButton.Active = true
		local buttonCorner = Instance.new("UICorner", iconButton); buttonCorner.CornerRadius = UDim.new(0, 6)
		iconButton.Parent = tempLagReducerFrame

		local statusLabel = Instance.new("TextLabel"); statusLabel.Name = "StatusLabel"; statusLabel.AutomaticSize = Enum.AutomaticSize.XY; statusLabel.AnchorPoint = Vector2.new(0.5, 0); statusLabel.Position = UDim2.new(0.5, 0, 0, 70); statusLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40); statusLabel.BackgroundTransparency = 0.5; statusLabel.Font = Enum.Font.SourceSansSemibold; statusLabel.TextSize = TEXT_SIZE; statusLabel.TextColor3 = Color3.new(1, 1, 1); statusLabel.TextStrokeTransparency = 0.4; statusLabel.Text = "Hx: " .. currentPresetName; statusLabel.Visible = true; statusLabel.ZIndex = 2; statusLabel.Active = false
		local labelPadding = Instance.new("UIPadding"); labelPadding.PaddingTop = UDim.new(0, 3); labelPadding.PaddingBottom = UDim.new(0, 3); labelPadding.PaddingLeft = UDim.new(0, 6); labelPadding.PaddingRight = UDim.new(0, 6); labelPadding.Parent = statusLabel
		local labelCorner = Instance.new("UICorner"); labelCorner.CornerRadius = UDim.new(0, 6); labelCorner.Parent = statusLabel
		statusLabel.Parent = tempLagReducerFrame

		buttonInputBeganConn = iconButton.InputBegan:Connect(function(input)
			if not dangChay then return end
			if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not isDragging then
				isDragging = true
				dragStartMousePos = input.Position
				dragStartFramePosUDim2 = tempLagReducerFrame.Position
				if dragMoveConnection then dragMoveConnection:Disconnect() end

				dragMoveConnection = UserInputService.InputChanged:Connect(function(moveInput)
					if not dangChay then if dragMoveConnection then dragMoveConnection:Disconnect() end; return end
					if isDragging and (moveInput.UserInputType == Enum.UserInputType.MouseMovement or moveInput.UserInputType == Enum.UserInputType.Touch) then
						if not dragStartFramePosUDim2 or not dragStartMousePos then return end
						local mouseDelta = Vector2.new(moveInput.Position.X - dragStartMousePos.X, moveInput.Position.Y - dragStartMousePos.Y)
						local newOffsetX = dragStartFramePosUDim2.X.Offset + mouseDelta.X
						local newOffsetY = dragStartFramePosUDim2.Y.Offset + mouseDelta.Y
						local originalScaleX = dragStartFramePosUDim2.X.Scale
						local originalScaleY = dragStartFramePosUDim2.Y.Scale
                        pcall(function()
						    tempLagReducerFrame.Position = UDim2.new(originalScaleX, newOffsetX, originalScaleY, newOffsetY)
                        end)
					end
				end)
			end
		end)

		buttonInputEndedConn = iconButton.InputEnded:Connect(function(input)
			if not dangChay then return end
			if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and isDragging then
				isDragging = false
				dragStartMousePos = nil
				dragStartFramePosUDim2 = nil
				if dragMoveConnection then
					dragMoveConnection:Disconnect()
					dragMoveConnection = nil
				end
			end
		end)

		buttonClickConn = iconButton.MouseButton1Click:Connect(function()
            if not dangChay then return end
			local currentIndex = table.find(availablePresets, currentPresetName) or 0
			local nextIndex = (currentIndex % #availablePresets) + 1
			local nextPreset = availablePresets[nextIndex]
			applyPreset(nextPreset)
		end)

		screenGui.Parent = playerGui
		return tempLagReducerFrame
	end)

	if not success then
		warn("Hx_V.0.2: LỖI TRONG PCALL KHI TẠO UI NÚT BẤM! Error:", result)
		if screenGui and screenGui.Parent == nil then screenGui:Destroy() end
		lagReducerFrame = nil
		return nil
	else
		lagReducerFrame = result
		return result
	end
end

if RunService:IsClient() then
	playerGui = player:WaitForChild("PlayerGui", 60)
    if not playerGui then
        warn("Hx_V.0.2: PlayerGui không tìm thấy! Script không thể khởi tạo.")
        return 
    end

    local oldUINames = {"LagReducerScreenGui", "HxNotificationGui", "HxContainerGui"}
    local oldUIFound = false
    for _, name in ipairs(oldUINames) do
        local oldGui = playerGui:FindFirstChild(name)
        if oldGui then
            if not oldUIFound then 
                 warn("Phát hiện UI cũ, tiến hành dọn dẹp!")
                 oldUIFound = true
            end
            oldGui:Destroy()
        end
    end

	if NOTIFICATIONS_ENABLED then
        if not taoMauThongBao() then
            warn("Hx_V.0.2: Không thể tạo mẫu thông báo ban đầu.")
            donDepTaiNguyen()
            return
        end
        if not thietLapKhungChuaThongBao() then
             warn("Hx_V.0.2: Không thể thiết lập khung chứa thông báo ban đầu.")
            donDepTaiNguyen()
            return
        end
        showNotification("Hx_V.0.2", "Lag Reducer đã kích hoạt.")
    end

	if not player.Character or not player.Character.Parent then
		player.CharacterAdded:Wait()
		task.wait(0.5)
	end

	if SELECTED_PRESET ~= "Custom" and PRESETS[SELECTED_PRESET] then
        currentPresetName = SELECTED_PRESET
    else
        currentPresetName = "OFF"
    end

	storeOriginalSettings()

	if UI_ENABLED then
        if not createOrGetUI() then
            warn("Hx_V.0.2: Không thể tạo UI nút bấm khi khởi tạo.")
        end
    end

	applyPreset(currentPresetName)

    if playerRemovingConn then playerRemovingConn:Disconnect() end
    playerRemovingConn = Players.PlayerRemoving:Connect(function(leavingPlayer)
        if leavingPlayer == player then
            donDepTaiNguyen()
        end
    end)

    print("Hx_V.0.2 Script đã khởi chạy.")

else
	warn("Hx_V.0.2: Script phải là LocalScript và chạy trên client!")
end
