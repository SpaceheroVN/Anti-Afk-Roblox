-- /========================================================================\
-- ||   ██╗  ██╗██╗  ██╗    ███████╗ ██████╗██████╗ ██╗██████╗ ████████╗   ||
-- ||   ██║  ██║╚██╗██╔╝    ██╔════╝██╔════╝██╔══██╗██║██╔══██╗╚══██╔══╝   ||
-- ||   ███████║ ╚███╔╝     ███████╗██║     ██████╔╝██║██████╔╝   ██║      ||
-- ||   ██╔══██║ ██╔██╗     ╚════██║██║     ██╔══██╗██║██╔═══╝    ██║      ||
-- ||   ██║  ██║██╔╝ ██╗    ███████║╚██████╗██║  ██║██║██║        ██║      ||
-- ||   ╚═╝  ╚═╝╚═╝  ╚═╝    ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝╚═╝        ╚═╝      ||
-- \========================================================================/

-- 🎮 Dịch vụ Roblox
local NguoiChoi = game:GetService("Players")
local AnhSang = game:GetService("Lighting")
local KhongGian = game:GetService("Workspace")
local CaiDatNguoiDung = UserSettings()
local GiaoDienKhoiDong = game:GetService("StarterGui")
local DichVuChay = game:GetService("RunService")
local DichVuNhap = game:GetService("UserInputService")
local DichVuTween = game:GetService("TweenService")

print("Hx_V.0.2: Script Lag Reducer đang tải...")

-- ⚙️ Cài đặt & Hằng số
local GIAO_DIEN_BAT = true
local THONG_BAO_BAT = true
local ID_ICON_GIAM_LAG = "rbxassetid://117118515787811"

-- 🖼️ Cài đặt Nút
local CO_CHU = 16
local KICH_THUOC_ICON_MOI = UDim2.new(0, 60, 0, 60)
local RONG_KHUNG_MOI = 80
local CAO_KHUNG_MOI = 90

-- 🔔 Cài đặt Thông báo
local TG_THONG_BAO_GIAY = 5
local TG_HOAT_ANH_GIAY = 0.5
local ID_ICON_THONG_BAO = "rbxassetid://117118515787811"
local KT_GUI_THONG_BAO = UDim2.new(0, 250, 0, 60)
local VT_KHUNG_CHUA_TB = UDim2.new(1, -18, 1, -48)
local KT_KHUNG_CHUA_TB = UDim2.new(0, 300, 0, 200)

-- 🚀 Cấu hình Tối ưu
local CAI_DAT_TRUOC_CHON = "OFF"
local CAU_HINH = {
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
local CAI_DAT_TRUOC = {
	Minimal = { DISABLE_GLOBAL_SHADOWS = true, OPTIMIZE_TERRAIN = true, FLATTEN_TERRAIN_WATER = true, OPTIMIZE_ON_ADD = true },
	Balanced = { DISABLE_COLLISIONS = false, ANCHOR_ALL_PARTS = false, DISABLE_GLOBAL_SHADOWS = true, FORCE_VOXEL_LIGHTING = true, DISABLE_POST_EFFECTS = true, DISABLE_ATMOSPHERE = true, DISABLE_CLOUDS = true, HIDE_CELESTIAL_BODIES = true, DISABLE_PARTICLES_ETC = true, OPTIMIZE_TERRAIN = true, FLATTEN_TERRAIN_WATER = true, SIMPLIFY_MATERIALS = true, FORCE_LOWEST_QUALITY = true, OPTIMIZE_ON_ADD = true },
	PerformanceBoost = { DISABLE_COLLISIONS = false, ANCHOR_ALL_PARTS = false, DISABLE_GLOBAL_SHADOWS = true, FORCE_VOXEL_LIGHTING = true, DISABLE_POST_EFFECTS = true, DISABLE_ATMOSPHERE = true, DISABLE_CLOUDS = true, HIDE_CELESTIAL_BODIES = false, SIMPLIFY_ENVIRONMENT_LIGHT = true, DISABLE_PARTICLES_ETC = true, DELETE_DECALS_TEXTURES = true, OPTIMIZE_TERRAIN = true, FLATTEN_TERRAIN_WATER = true, SIMPLIFY_MATERIALS = true, FORCE_LOWEST_QUALITY = true, OPTIMIZE_ON_ADD = true },
	UltraLow = { DISABLE_COLLISIONS = false, ANCHOR_ALL_PARTS = false, DISABLE_GLOBAL_SHADOWS = true, FORCE_VOXEL_LIGHTING = true, DISABLE_POST_EFFECTS = true, DISABLE_ATMOSPHERE = true, DISABLE_CLOUDS = true, HIDE_CELESTIAL_BODIES = true, SIMPLIFY_ENVIRONMENT_LIGHT = true, DISABLE_PARTICLES_ETC = true, DELETE_DECALS_TEXTURES = true, OPTIMIZE_TERRAIN = true, FLATTEN_TERRAIN_WATER = true, SIMPLIFY_MATERIALS = true, DELETE_NON_PLAYER_MODELS = true, FORCE_SIMPLE_GEOMETRY = true, DELETE_SOUNDS = true, FORCE_LOWEST_QUALITY = true, OPTIMIZE_ON_ADD = true }
}

-- 📊 Biến Trạng thái
local tenCdtHienTai = "OFF"
local cacCdt = {"OFF", "Minimal", "Balanced", "PerformanceBoost", "UltraLow"}
local dtdToiUu = setmetatable({}, { __mode = "k" })
local listenerDaKetNoi = false
local debounceToiUuThem = false
local dangChay = true
local nguoiChoi = NguoiChoi.LocalPlayer
local giaoDienNguoiChoi = nil

-- 🖼️ Biến Giao diện
local khungGiamLag = nil
local guiThongBao = nil
local khungChuaTB = nil
local mauTB = nil

-- 🔌 Biến Kết nối
local ketNoiThemDescendant = nil
local ketNoiXoaNguoiChoi = nil
local ketNoiNutNhan = nil
local ketNoiNutTha = nil
local ketNoiNutClick = nil
local ketNoiKeoTha = nil
local cacTweenDangChay = {}

-- 🧹 Dọn dẹp
local function donDepTaiNguyen()
	print("Hx_V.0.2: Bắt đầu dọn dẹp tài nguyên...")
	if not dangChay then return end
	dangChay = false

	if ketNoiThemDescendant then ketNoiThemDescendant:Disconnect(); ketNoiThemDescendant = nil end
	if ketNoiXoaNguoiChoi then ketNoiXoaNguoiChoi:Disconnect(); ketNoiXoaNguoiChoi = nil end
	if ketNoiNutNhan then ketNoiNutNhan:Disconnect(); ketNoiNutNhan = nil end
	if ketNoiNutTha then ketNoiNutTha:Disconnect(); ketNoiNutTha = nil end
	if ketNoiNutClick then ketNoiNutClick:Disconnect(); ketNoiNutClick = nil end
	if ketNoiKeoTha then ketNoiKeoTha:Disconnect(); ketNoiKeoTha = nil end
	listenerDaKetNoi = false

	for tweenInstance, _ in pairs(cacTweenDangChay) do
		if typeof(tweenInstance) == "Instance" and tweenInstance:IsA("Tween") then
			pcall(function() tweenInstance:Cancel() end)
		end
	end
	cacTweenDangChay = {}

	if guiThongBao and guiThongBao.Parent then
		guiThongBao:Destroy()
	end
	local lagReducerGui = giaoDienNguoiChoi and giaoDienNguoiChoi:FindFirstChild("LagReducerScreenGui")
	if lagReducerGui then
		lagReducerGui:Destroy()
	end

	guiThongBao = nil
	khungChuaTB = nil
	mauTB = nil
	khungGiamLag = nil

	print("Hx_V.0.2: Dọn dẹp hoàn tất.")
end

-- ⚙️ Quản lý Tween
local function xoaTweenKhoiTheoDoi(tweenInstance)
	if cacTweenDangChay[tweenInstance] then
		cacTweenDangChay[tweenInstance] = nil
	end
end

-- 🔔 Tạo Mẫu Thông báo
local function taoMauThongBao()
	if mauTB and mauTB.Parent == nil then
		return mauTB
	end

	local frame = Instance.new("Frame")
	frame.Name = "NotificationFrameTemplate"
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	frame.BackgroundTransparency = 1
	frame.BorderSizePixel = 0
	frame.Size = KT_GUI_THONG_BAO
	frame.ClipsDescendants = true
	mauTB = frame

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
	icon.Image = ID_ICON_THONG_BAO
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

	return mauTB
end

-- 🔔 Thiết lập Khung Thông báo
local function thietLapKhungChuaThongBao()
	if khungChuaTB and khungChuaTB.Parent and guiThongBao and guiThongBao.Parent then
		return khungChuaTB
	end

	if not nguoiChoi or not nguoiChoi:IsDescendantOf(NguoiChoi) then
		warn("Hx_V.0.2: Đối tượng người chơi cục bộ không hợp lệ.")
		return nil
	end
	if not giaoDienNguoiChoi then
		 warn("Hx_V.0.2: PlayerGui chưa sẵn sàng.")
		 return nil
	end

	local oldGui = giaoDienNguoiChoi:FindFirstChild("HxNotificationGui")
	if oldGui then
		oldGui:Destroy()
	end

	guiThongBao = Instance.new("ScreenGui")
	guiThongBao.Name = "HxNotificationGui"
	guiThongBao.ResetOnSpawn = false
	guiThongBao.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	guiThongBao.DisplayOrder = 999
	guiThongBao.Parent = giaoDienNguoiChoi

	local container = Instance.new("Frame")
	container.Name = "NotificationContainerFrame"
	container.AnchorPoint = Vector2.new(1, 1)
	container.Position = VT_KHUNG_CHUA_TB
	container.Size = KT_KHUNG_CHUA_TB
	container.BackgroundTransparency = 1
	container.Parent = guiThongBao

	local listLayout = Instance.new("UIListLayout", container)
	listLayout.FillDirection = Enum.FillDirection.Vertical
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	listLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 5)

	khungChuaTB = container
	return khungChuaTB
end

-- 🔔 Hiển thị Thông báo
local function hienThiThongBao(tieuDe, noiDung)
	if not THONG_BAO_BAT or not dangChay then return end

	if not khungChuaTB or not khungChuaTB.Parent then
        if not thietLapKhungChuaThongBao() then
		    warn("Hx_V.0.2: Khung chứa thông báo không hợp lệ và không thể tạo.")
            return
        end
    end
	if not mauTB then
        if not taoMauThongBao() then
            warn("Hx_V.0.2: Mẫu thông báo chưa được tạo và không thể tạo.")
            return
        end
    end

	local khungMoi = mauTB:Clone()
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
	khungMoi.Parent = khungChuaTB

	local thongTinTweenXuatHien = TweenInfo.new(TG_HOAT_ANH_GIAY, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	local tweenMoDanKhung = DichVuTween:Create(khungMoi, thongTinTweenXuatHien, { BackgroundTransparency = 0.2 })
	local tweenMoDanIcon = DichVuTween:Create(hinhIcon, thongTinTweenXuatHien, { ImageTransparency = 0 })
	local tweenMoDanTieuDe = DichVuTween:Create(nhanTieuDe, thongTinTweenXuatHien, { TextTransparency = 0 })
	local tweenMoDanNoiDung = DichVuTween:Create(nhanNoiDung, thongTinTweenXuatHien, { TextTransparency = 0 })

	cacTweenDangChay[tweenMoDanKhung] = true
	cacTweenDangChay[tweenMoDanIcon] = true
	cacTweenDangChay[tweenMoDanTieuDe] = true
	cacTweenDangChay[tweenMoDanNoiDung] = true

	tweenMoDanKhung.Completed:Connect(function() xoaTweenKhoiTheoDoi(tweenMoDanKhung) end)
	tweenMoDanIcon.Completed:Connect(function() xoaTweenKhoiTheoDoi(tweenMoDanIcon) end)
	tweenMoDanTieuDe.Completed:Connect(function() xoaTweenKhoiTheoDoi(tweenMoDanTieuDe) end)
	tweenMoDanNoiDung.Completed:Connect(function() xoaTweenKhoiTheoDoi(tweenMoDanNoiDung) end)

	tweenMoDanKhung:Play()
	tweenMoDanIcon:Play()
	tweenMoDanTieuDe:Play()
	tweenMoDanNoiDung:Play()

	task.delay(TG_THONG_BAO_GIAY, function()
		if not dangChay or not khungMoi or not khungMoi.Parent then
			xoaTweenKhoiTheoDoi(tweenMoDanKhung)
			xoaTweenKhoiTheoDoi(tweenMoDanIcon)
			xoaTweenKhoiTheoDoi(tweenMoDanTieuDe)
			xoaTweenKhoiTheoDoi(tweenMoDanNoiDung)
			return
		end

		local thongTinTweenBienMat = TweenInfo.new(TG_HOAT_ANH_GIAY, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
		local tweenMoDanKhung_Mat = DichVuTween:Create(khungMoi, thongTinTweenBienMat, { BackgroundTransparency = 1 })
		local tweenMoDanIcon_Mat = DichVuTween:Create(hinhIcon, thongTinTweenBienMat, { ImageTransparency = 1 })
		local tweenMoDanTieuDe_Mat = DichVuTween:Create(nhanTieuDe, thongTinTweenBienMat, { TextTransparency = 1 })
		local tweenMoDanNoiDung_Mat = DichVuTween:Create(nhanNoiDung, thongTinTweenBienMat, { TextTransparency = 1 })

		cacTweenDangChay[tweenMoDanKhung_Mat] = true
		cacTweenDangChay[tweenMoDanIcon_Mat] = true
		cacTweenDangChay[tweenMoDanTieuDe_Mat] = true
		cacTweenDangChay[tweenMoDanNoiDung_Mat] = true

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

-- 🤔 Hàm Hỗ trợ
local function laBoPhanNhanVat(object)
	if not (object:IsA("BasePart") or object:IsA("Accessory") or object:IsA("Tool")) then return false end
	for _, p in pairs(NguoiChoi:GetPlayers()) do if p.Character and object:IsDescendantOf(p.Character) then return true end end
	return false
end

-- 💾 Cài đặt Gốc
local caiDatAnhSangGoc = {}
local caiDatDiaHinhGoc = {}
local mucChatLuongGoc = Enum.SavedQualitySetting.Automatic

local function luuCaiDatGoc()
	mucChatLuongGoc = Enum.SavedQualitySetting.Automatic
	local success, err = pcall(function()
		pcall(function() caiDatAnhSangGoc.GlobalShadows = AnhSang.GlobalShadows end)
		pcall(function() caiDatAnhSangGoc.Technology = AnhSang.Technology end)
		pcall(function() caiDatAnhSangGoc.Brightness = AnhSang.Brightness end)
		pcall(function() caiDatAnhSangGoc.EnvironmentDiffuseScale = AnhSang.EnvironmentDiffuseScale end)
		pcall(function() caiDatAnhSangGoc.EnvironmentSpecularScale = AnhSang.EnvironmentSpecularScale end)
		pcall(function() caiDatAnhSangGoc.Ambient = AnhSang.Ambient end)
		pcall(function() caiDatAnhSangGoc.OutdoorAmbient = AnhSang.OutdoorAmbient end)
		local terrain = KhongGian:FindFirstChildOfClass("Terrain")
		if terrain then
			pcall(function() caiDatDiaHinhGoc.WaterWaveSize = terrain.WaterWaveSize end)
			pcall(function() caiDatDiaHinhGoc.WaterWaveSpeed = terrain.WaterWaveSpeed end)
			pcall(function() caiDatDiaHinhGoc.WaterReflectance = terrain.WaterReflectance end)
			pcall(function() caiDatDiaHinhGoc.WaterTransparency = terrain.WaterTransparency end)
		end
		pcall(function()
			if CaiDatNguoiDung and CaiDatNguoiDung.GameSettings then
				mucChatLuongGoc = CaiDatNguoiDung.GameSettings.SavedQualityLevel
			elseif typeof(settings) == "function" then
			    local s, currentQuality = pcall(settings().Rendering.QualityLevel)
			    if s then mucChatLuongGoc = currentQuality end
				warn("Hx_V.0.2: Không thể lưu/khôi phục cài đặt chất lượng gốc từ API settings() cũ.")
			else
				warn("Hx_V.0.2: Không thể truy cập UserSettings để lưu chất lượng gốc.")
			end
		end)
	end)
	if not success then warn("Hx_V.0.2: Lỗi khi lưu cài đặt gốc!", err) end
end

-- 🚀 Tối ưu Đối tượng
local function toiUuDoiTuong(obj)
	if not dangChay then return end
	if khungGiamLag and (obj == khungGiamLag or obj:IsDescendantOf(khungGiamLag)) then return end
	if guiThongBao and (obj == guiThongBao or obj:IsDescendantOf(guiThongBao)) then return end

	local isValid = pcall(function() return obj and obj.Parent end)
	if not isValid or dtdToiUu[obj] then return end

	local laPhanNhanVat = laBoPhanNhanVat(obj)
	local success, err = pcall(function()
		if CAU_HINH.DISABLE_PARTICLES_ETC and (obj:IsA("ParticleEmitter") or obj:IsA("Beam") or obj:IsA("Trail") or obj:IsA("Smoke") or obj:IsA("Fire") or obj:IsA("Sparkles") or obj:IsA("Explosion")) then
			obj.Enabled = false
		end
		if CAU_HINH.DELETE_DECALS_TEXTURES and (obj:IsA("Decal") or obj:IsA("Texture")) then
			obj:Destroy()
			return
		end
		if CAU_HINH.DELETE_SOUNDS and obj:IsA("Sound") then
			obj:Destroy()
			return
		end
		if obj:IsA("BasePart") then
			if not laPhanNhanVat then
				if CAU_HINH.ANCHOR_ALL_PARTS then obj.Anchored = true end
				if CAU_HINH.DISABLE_COLLISIONS then obj.CanCollide, obj.CanTouch, obj.CanQuery = false, false, false end
				if CAU_HINH.FORCE_SIMPLE_GEOMETRY and (obj:IsA("MeshPart") or obj:IsA("UnionOperation")) then
					if not table.find(CAU_HINH.SAFE_GEOMETRY_NAMES, obj.Name) then
						obj:Destroy()
						return
					end
				end
			end
			if CAU_HINH.DISABLE_GLOBAL_SHADOWS then obj.CastShadow = false end
			if CAU_HINH.SIMPLIFY_MATERIALS then obj.Material, obj.Reflectance = Enum.Material.Plastic, 0 end
		end
		if CAU_HINH.DELETE_NON_PLAYER_MODELS and obj:IsA("Model") and not obj:FindFirstChildWhichIsA("Humanoid") and not NguoiChoi:GetPlayerFromCharacter(obj) then
			if not table.find(CAU_HINH.SAFE_GEOMETRY_NAMES, obj.Name) then
				obj:Destroy()
				return
			end
		end
		if CAU_HINH.DELETE_UI and obj:IsA("ScreenGui") then
			if obj ~= guiThongBao and obj.Name ~= "LagReducerScreenGui" and obj.Name ~= "CoreGui" and obj.Name ~= "EssentialUI" then
				obj:Destroy()
				return
			end
		end
	end)
	if success or isValid then dtdToiUu[obj] = true end
end

-- 💡 Tối ưu Ánh sáng
local function toiUuAnhSang(isReverting)
	local s, e
	if isReverting then
		s, e = pcall(function()
			if caiDatAnhSangGoc.GlobalShadows ~= nil then pcall(function() AnhSang.GlobalShadows = caiDatAnhSangGoc.GlobalShadows end) end
			if caiDatAnhSangGoc.Technology ~= nil then pcall(function() AnhSang.Technology = caiDatAnhSangGoc.Technology end) end
			if caiDatAnhSangGoc.Brightness ~= nil then pcall(function() AnhSang.Brightness = caiDatAnhSangGoc.Brightness end) end
			if caiDatAnhSangGoc.EnvironmentDiffuseScale ~= nil then pcall(function() AnhSang.EnvironmentDiffuseScale = caiDatAnhSangGoc.EnvironmentDiffuseScale end) end
			if caiDatAnhSangGoc.EnvironmentSpecularScale ~= nil then pcall(function() AnhSang.EnvironmentSpecularScale = caiDatAnhSangGoc.EnvironmentSpecularScale end) end
			if caiDatAnhSangGoc.Ambient ~= nil then pcall(function() AnhSang.Ambient = caiDatAnhSangGoc.Ambient end) end
			if caiDatAnhSangGoc.OutdoorAmbient ~= nil then pcall(function() AnhSang.OutdoorAmbient = caiDatAnhSangGoc.OutdoorAmbient end) end
			if CAU_HINH.DISABLE_POST_EFFECTS then
				for _, v in pairs(AnhSang:GetChildren()) do if v and v:IsA("PostEffect") then pcall(function() v.Enabled = true end) end end
			end
			local k = AnhSang:FindFirstChildOfClass("Sky")
			if CAU_HINH.HIDE_CELESTIAL_BODIES and k then
				pcall(function() k.CelestialBodiesShown = true end)
			end
		end)
		if not s then warn("Hx_V.0.2: Lỗi khôi phục Lighting:", e) end
		return
	end
	s, e = pcall(function()
		if CAU_HINH.DISABLE_GLOBAL_SHADOWS then AnhSang.GlobalShadows = false end
		if CAU_HINH.FORCE_VOXEL_LIGHTING then AnhSang.Technology = Enum.Technology.Voxel end
		pcall(function() AnhSang.FogEnd = 1000000 end)
		if CAU_HINH.SIMPLIFY_ENVIRONMENT_LIGHT then
			AnhSang.Brightness, AnhSang.EnvironmentDiffuseScale, AnhSang.EnvironmentSpecularScale = 0, 0, 0
			AnhSang.Ambient, AnhSang.OutdoorAmbient = Color3.fromRGB(50, 50, 50), Color3.fromRGB(50, 50, 50)
		end
		if CAU_HINH.DISABLE_POST_EFFECTS then
			for _, v in pairs(AnhSang:GetChildren()) do if v and v:IsA("PostEffect") then v.Enabled = false end end
		end
		local a = AnhSang:FindFirstChildOfClass("Atmosphere")
		if CAU_HINH.DISABLE_ATMOSPHERE and a then a:Destroy() end
		local l = AnhSang:FindFirstChildOfClass("Clouds")
		if CAU_HINH.DISABLE_CLOUDS and l then l:Destroy() end
		local k = AnhSang:FindFirstChildOfClass("Sky")
		if CAU_HINH.HIDE_CELESTIAL_BODIES and k then k.CelestialBodiesShown = false end
	end)
	if not s then warn("Hx_V.0.2: Lỗi tối ưu hóa Lighting:", e) end
end

-- 🌳 Tối ưu Địa hình
local function toiUuDiaHinh(isReverting)
	local terrain = KhongGian:FindFirstChildOfClass("Terrain")
	if not terrain then return end
	local s, e
	if isReverting then
		s, e = pcall(function()
			if caiDatDiaHinhGoc.WaterWaveSize ~= nil then pcall(function() terrain.WaterWaveSize = caiDatDiaHinhGoc.WaterWaveSize end) end
			if caiDatDiaHinhGoc.WaterWaveSpeed ~= nil then pcall(function() terrain.WaterWaveSpeed = caiDatDiaHinhGoc.WaterWaveSpeed end) end
			if caiDatDiaHinhGoc.WaterReflectance ~= nil then pcall(function() terrain.WaterReflectance = caiDatDiaHinhGoc.WaterReflectance end) end
			if caiDatDiaHinhGoc.WaterTransparency ~= nil then pcall(function() terrain.WaterTransparency = caiDatDiaHinhGoc.WaterTransparency end) end
		end)
		if not s then warn("Hx_V.0.2: Lỗi khôi phục Terrain:", e) end
		return
	end
	if not CAU_HINH.OPTIMIZE_TERRAIN then return end
	s, e = pcall(function()
		if CAU_HINH.FLATTEN_TERRAIN_WATER then
			terrain.WaterWaveSize, terrain.WaterWaveSpeed, terrain.WaterReflectance, terrain.WaterTransparency = 0, 0, 0, 1
		end
	end)
	if not s then warn("Hx_V.0.2: Lỗi tối ưu hóa Terrain:", e) end
end

-- 📉 Ép Chất lượng
local function epChatLuongThap(isReverting)
	local targetSavedQuality
	if isReverting then
		targetSavedQuality = mucChatLuongGoc
	else
		targetSavedQuality = Enum.SavedQualitySetting.QualityLevel1
	end

	if not isReverting and not CAU_HINH.FORCE_LOWEST_QUALITY then return end
	if not targetSavedQuality then warn("Hx_V.0.2: Không thể xác định giá trị SavedQualitySetting đích."); return end

	local success, err = pcall(function()
		if CaiDatNguoiDung and CaiDatNguoiDung.GameSettings then
			CaiDatNguoiDung.GameSettings.SavedQualityLevel = targetSavedQuality
		elseif typeof(settings) == "function" then
			warn("Hx_V.0.2: API settings() cũ không được hỗ trợ cập nhật SavedQualitySetting.")
		else
			error("Không thể truy cập UserSettings hoặc settings() để thay đổi mức chất lượng.")
		end
	end)
	if not success then warn("Hx_V.0.2: Lỗi đặt mức chất lượng đồ họa (SavedQualityLevel)! ", err) end
end

-- 🔄 Áp dụng Tối ưu
local function apDungTatCaToiUu(is_rerun)
    if not dangChay then return end
	toiUuAnhSang(false)
	toiUuDiaHinh(false)

	local startOptimizeTime = tick()
	local descendants = KhongGian:GetDescendants()
	local count = 0
	for i = #descendants, 1, -1 do
        if not dangChay then break end
        local obj = descendants[i]
        if obj and obj.Parent then toiUuDoiTuong(obj); count = count + 1 end
        if tick() - startOptimizeTime > 0.05 then task.wait(); startOptimizeTime = tick() end
    end
    if not dangChay then return end

	if CAU_HINH.DELETE_UI then
        local ui_count = 0
        for _, p in pairs(NguoiChoi:GetPlayers()) do
            local pGui = p:FindFirstChild("PlayerGui")
            if pGui then
                local guis = pGui:GetChildren()
                for i = #guis, 1, -1 do
                    if guis[i] and guis[i]:IsA("ScreenGui") then toiUuDoiTuong(guis[i]); ui_count = ui_count + 1 end
                end
            end
        end
    end

	epChatLuongThap(false)

    if listenerDaKetNoi and (not CAU_HINH.OPTIMIZE_ON_ADD or tenCdtHienTai == "OFF") then
        if ketNoiThemDescendant then ketNoiThemDescendant:Disconnect() end
        ketNoiThemDescendant = nil
        listenerDaKetNoi = false
	elseif not listenerDaKetNoi and CAU_HINH.OPTIMIZE_ON_ADD and tenCdtHienTai ~= "OFF" then
        listenerDaKetNoi = true
        if ketNoiThemDescendant then ketNoiThemDescendant:Disconnect() end
        ketNoiThemDescendant = game.DescendantAdded:Connect(function(descendant)
            if not dangChay or debounceToiUuThem then return end
            debounceToiUuThem = true
            toiUuDoiTuong(descendant)
            task.delay(CAU_HINH.OPTIMIZE_ADD_COOLDOWN, function() debounceToiUuThem = false end)
        end)
    end
end

-- <0xF0><0x9F><0x94><0x85> Áp dụng Cài đặt
local function apDungCaiDatTruoc(presetName)
    if not dangChay then return end
	local notificationMessage = "Đang chuyển sang chế độ: " .. presetName
	if presetName == "OFF" then notificationMessage = "Đang tắt tối ưu hóa..." end
    hienThiThongBao("Hx_V.0.2", notificationMessage)

    if ketNoiThemDescendant then ketNoiThemDescendant:Disconnect(); ketNoiThemDescendant = nil; listenerDaKetNoi = false end
    dtdToiUu = setmetatable({}, { __mode = "k" })

	local defaultConfig = { DISABLE_COLLISIONS = false, ANCHOR_ALL_PARTS = false, DISABLE_GLOBAL_SHADOWS = true, FORCE_VOXEL_LIGHTING = false, DISABLE_POST_EFFECTS = false, DISABLE_ATMOSPHERE = false, DISABLE_CLOUDS = false, HIDE_CELESTIAL_BODIES = false, SIMPLIFY_ENVIRONMENT_LIGHT = false, DISABLE_PARTICLES_ETC = false, DELETE_DECALS_TEXTURES = false, OPTIMIZE_TERRAIN = true, FLATTEN_TERRAIN_WATER = false, SIMPLIFY_MATERIALS = false, DELETE_NON_PLAYER_MODELS = false, FORCE_SIMPLE_GEOMETRY = false, SAFE_GEOMETRY_NAMES = {"Baseplate", "SpawnLocation", "HumanoidRootPart"}, DELETE_SOUNDS = false, DELETE_UI = false, FORCE_LOWEST_QUALITY = false, OPTIMIZE_ON_ADD = false, OPTIMIZE_ADD_COOLDOWN = 0.05, }
	tenCdtHienTai = presetName

    if presetName == "OFF" then
        CAU_HINH = defaultConfig
        CAU_HINH.OPTIMIZE_ON_ADD = false
        toiUuAnhSang(true)
        toiUuDiaHinh(true)
        epChatLuongThap(true)
    else
        local presetConfigData = CAI_DAT_TRUOC[presetName]
        if presetConfigData then
            CAU_HINH = table.clone(defaultConfig)
            CAU_HINH.OPTIMIZE_ON_ADD = true
            for key, value in pairs(presetConfigData) do
                if CAU_HINH[key] ~= nil then
                    CAU_HINH[key] = value
                else
                    warn("Hx_V.0.2: Không rõ key config trong preset", presetName, ":", key)
                end
            end
            apDungTatCaToiUu(true)
        else
            warn("Hx_V.0.2: Preset không tìm thấy:", presetName, ". Đang quay về OFF.")
            apDungCaiDatTruoc("OFF")
            return
        end
    end

	if khungGiamLag and khungGiamLag.Parent and khungGiamLag:FindFirstChild("StatusLabel") then
        pcall(function()
            khungGiamLag.StatusLabel.Text = "Hx: " .. tenCdtHienTai
        end)
    end
end

-- <0xF0><0x9F><0x96><0xB1>️ Kéo thả Nút
local dangKeo = false
local viTriChuotKhiKeo = nil
local viTriKhungKhiKeoUDim2 = nil

-- 🖼️ Tạo/Lấy UI Nút
local function taoHoacLayUI()
	if not GIAO_DIEN_BAT or not dangChay then return end
	if not giaoDienNguoiChoi or not giaoDienNguoiChoi.Parent then
		giaoDienNguoiChoi = nguoiChoi:WaitForChild("PlayerGui", 15)
		if not giaoDienNguoiChoi then warn("Hx_V.0.2: PlayerGui không tìm thấy trong taoHoacLayUI."); return nil end
	end

	local existingScreenGui = giaoDienNguoiChoi:FindFirstChild("LagReducerScreenGui")
	if existingScreenGui then
		existingScreenGui:Destroy()
		khungGiamLag = nil
		if ketNoiNutNhan then ketNoiNutNhan:Disconnect(); ketNoiNutNhan = nil end
		if ketNoiNutTha then ketNoiNutTha:Disconnect(); ketNoiNutTha = nil end
		if ketNoiNutClick then ketNoiNutClick:Disconnect(); ketNoiNutClick = nil end
		if ketNoiKeoTha then ketNoiKeoTha:Disconnect(); ketNoiKeoTha = nil end
	end

	local screenGui
	local tempKhungGiamLag = nil
	local success, result = pcall(function()
		screenGui = Instance.new("ScreenGui")
		screenGui.Name = "LagReducerScreenGui"
		screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
		screenGui.ResetOnSpawn = false
		screenGui.Enabled = true
		screenGui.DisplayOrder = 1000

		tempKhungGiamLag = Instance.new("Frame")
		tempKhungGiamLag.Name = "LagReducerFrame"
		tempKhungGiamLag.Size = UDim2.new(0, RONG_KHUNG_MOI, 0, CAO_KHUNG_MOI)
		tempKhungGiamLag.AnchorPoint = Vector2.new(0.5, 0)
		tempKhungGiamLag.Position = UDim2.new(0.5, 0, 0, 20)
		tempKhungGiamLag.BackgroundTransparency = 0.8
		tempKhungGiamLag.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		tempKhungGiamLag.BorderSizePixel = 0
		tempKhungGiamLag.Visible = true
		tempKhungGiamLag.ZIndex = 1
		tempKhungGiamLag.Active = false
		local frameCorner = Instance.new("UICorner", tempKhungGiamLag)
		frameCorner.CornerRadius = UDim.new(0, 8)
		tempKhungGiamLag.Parent = screenGui

		local iconButton = Instance.new("ImageButton")
		iconButton.Name = "IconButton"
		iconButton.Size = KICH_THUOC_ICON_MOI
		iconButton.Position = UDim2.new(0.5, 0, 0, 5)
		iconButton.AnchorPoint = Vector2.new(0.5, 0)
		iconButton.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
		iconButton.BackgroundTransparency = 0.3
		iconButton.Image = ID_ICON_GIAM_LAG
		iconButton.Visible = true
		iconButton.ZIndex = 2
		iconButton.BorderSizePixel = 0
		iconButton.Active = true
		local buttonCorner = Instance.new("UICorner", iconButton)
		buttonCorner.CornerRadius = UDim.new(0, 6)
		iconButton.Parent = tempKhungGiamLag

		local statusLabel = Instance.new("TextLabel")
		statusLabel.Name = "StatusLabel"
		statusLabel.AutomaticSize = Enum.AutomaticSize.XY
		statusLabel.AnchorPoint = Vector2.new(0.5, 0)
		statusLabel.Position = UDim2.new(0.5, 0, 0, 70)
		statusLabel.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
		statusLabel.BackgroundTransparency = 0.5
		statusLabel.Font = Enum.Font.SourceSansSemibold
		statusLabel.TextSize = CO_CHU
		statusLabel.TextColor3 = Color3.new(1, 1, 1)
		statusLabel.TextStrokeTransparency = 0.4
		statusLabel.Text = "Hx: " .. tenCdtHienTai
		statusLabel.Visible = true
		statusLabel.ZIndex = 2
		statusLabel.Active = false
		local labelPadding = Instance.new("UIPadding")
		labelPadding.PaddingTop = UDim.new(0, 3)
		labelPadding.PaddingBottom = UDim.new(0, 3)
		labelPadding.PaddingLeft = UDim.new(0, 6)
		labelPadding.PaddingRight = UDim.new(0, 6)
		labelPadding.Parent = statusLabel
		local labelCorner = Instance.new("UICorner")
		labelCorner.CornerRadius = UDim.new(0, 6)
		labelCorner.Parent = statusLabel
		statusLabel.Parent = tempKhungGiamLag

		ketNoiNutNhan = iconButton.InputBegan:Connect(function(input)
			if not dangChay then return end
			if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and not dangKeo then
				dangKeo = true
				viTriChuotKhiKeo = input.Position
				viTriKhungKhiKeoUDim2 = tempKhungGiamLag.Position
				if ketNoiKeoTha then ketNoiKeoTha:Disconnect() end

				ketNoiKeoTha = DichVuNhap.InputChanged:Connect(function(moveInput)
					if not dangChay then if ketNoiKeoTha then ketNoiKeoTha:Disconnect() end; return end
					if dangKeo and (moveInput.UserInputType == Enum.UserInputType.MouseMovement or moveInput.UserInputType == Enum.UserInputType.Touch) then
						if not viTriKhungKhiKeoUDim2 or not viTriChuotKhiKeo then return end
						local mouseDelta = Vector2.new(moveInput.Position.X - viTriChuotKhiKeo.X, moveInput.Position.Y - viTriChuotKhiKeo.Y)
						local newOffsetX = viTriKhungKhiKeoUDim2.X.Offset + mouseDelta.X
						local newOffsetY = viTriKhungKhiKeoUDim2.Y.Offset + mouseDelta.Y
						local originalScaleX = viTriKhungKhiKeoUDim2.X.Scale
						local originalScaleY = viTriKhungKhiKeoUDim2.Y.Scale
                        pcall(function()
						    tempKhungGiamLag.Position = UDim2.new(originalScaleX, newOffsetX, originalScaleY, newOffsetY)
                        end)
					end
				end)
			end
		end)

		ketNoiNutTha = iconButton.InputEnded:Connect(function(input)
			if not dangChay then return end
			if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) and dangKeo then
				dangKeo = false
				viTriChuotKhiKeo = nil
				viTriKhungKhiKeoUDim2 = nil
				if ketNoiKeoTha then
					ketNoiKeoTha:Disconnect()
					ketNoiKeoTha = nil
				end
			end
		end)

		ketNoiNutClick = iconButton.MouseButton1Click:Connect(function()
            if not dangChay then return end
			local currentIndex = table.find(cacCdt, tenCdtHienTai) or 0
			local nextIndex = (currentIndex % #cacCdt) + 1
			local nextPreset = cacCdt[nextIndex]
			apDungCaiDatTruoc(nextPreset)
		end)

		screenGui.Parent = giaoDienNguoiChoi
		return tempKhungGiamLag
	end)

	if not success then
		warn("Hx_V.0.2: LỖI TRONG PCALL KHI TẠO UI NÚT BẤM! Error:", result)
		if screenGui and screenGui.Parent == nil then screenGui:Destroy() end
		khungGiamLag = nil
		return nil
	else
		khungGiamLag = result
		return result
	end
end

-- ▶️ Khởi tạo
if DichVuChay:IsClient() then
	giaoDienNguoiChoi = nguoiChoi:WaitForChild("PlayerGui", 60)
    if not giaoDienNguoiChoi then
        warn("Hx_V.0.2: PlayerGui không tìm thấy! Script không thể khởi tạo.")
        return
    end

    local oldUINames = {"LagReducerScreenGui", "HxNotificationGui", "HxContainerGui"}
    local oldUIFound = false
    for _, name in ipairs(oldUINames) do
        local oldGui = giaoDienNguoiChoi:FindFirstChild(name)
        if oldGui then
            if not oldUIFound then
                 warn("Phát hiện UI cũ, tiến hành dọn dẹp!")
                 oldUIFound = true
            end
            oldGui:Destroy()
        end
    end

	if THONG_BAO_BAT then
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
        hienThiThongBao("Hx_V.0.2", "Lag Reducer đã kích hoạt.")
    end

	if not nguoiChoi.Character or not nguoiChoi.Character.Parent then
		nguoiChoi.CharacterAdded:Wait()
		task.wait(0.5)
	end

	if CAI_DAT_TRUOC_CHON ~= "Custom" and CAI_DAT_TRUOC[CAI_DAT_TRUOC_CHON] then
        tenCdtHienTai = CAI_DAT_TRUOC_CHON
    else
        tenCdtHienTai = "OFF"
    end

	luuCaiDatGoc()

	if GIAO_DIEN_BAT then
        if not taoHoacLayUI() then
            warn("Hx_V.0.2: Không thể tạo UI nút bấm khi khởi tạo.")
        end
    end

	apDungCaiDatTruoc(tenCdtHienTai)

    if ketNoiXoaNguoiChoi then ketNoiXoaNguoiChoi:Disconnect() end
    ketNoiXoaNguoiChoi = NguoiChoi.PlayerRemoving:Connect(function(leavingPlayer)
        if leavingPlayer == nguoiChoi then
            donDepTaiNguyen()
        end
    end)

    print("Hx_V.0.2 Script đã khởi chạy.")

else
	warn("Hx_V.0.2: Script phải là LocalScript và chạy trên client!")
end
