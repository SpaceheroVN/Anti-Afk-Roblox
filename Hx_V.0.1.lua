-- /========================================================================\
-- ||   ██╗  ██╗██╗  ██╗    ███████╗ ██████╗██████╗ ██╗██████╗ ████████╗   ||
-- ||   ██║  ██║╚██╗██╔╝    ██╔════╝██╔════╝██╔══██╗██║██╔══██╗╚══██╔══╝   ||
-- ||   ███████║ ╚███╔╝     ███████╗██║     ██████╔╝██║██████╔╝   ██║      ||
-- ||   ██╔══██║ ██╔██╗     ╚════██║██║     ██╔══██╗██║██╔═══╝    ██║      ||
-- ||   ██║  ██║██╔╝ ██╗    ███████║╚██████╗██║  ██║██║██║        ██║      ||
-- ||   ╚═╝  ╚═╝╚═╝  ╚═╝    ╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝╚═╝        ╚═╝      ||
-- \========================================================================/
wait(1)

-- ⚙️ Dịch Vụ Roblox
local DichVuInputNguoiDung = game:GetService("UserInputService")
local NguoiChoiService = game:GetService("Players")
local DichVuChay = game:GetService("RunService")
local QuanLyInputAo = game:GetService("VirtualInputManager")
local DichVuTween = game:GetService("TweenService")

-- 🛠️ Cấu Hình Script
local NGUONG_AFK_GIAY = 180      
local KHOANG_CAN_THIEP_GIAY = 600 
local KHOANG_KIEM_TRA_GIAY = 600      
local THOI_LUONG_THONG_BAO_GIAY = 5 
local THOI_GIAN_HOAT_ANH_GIAY = 0.5      
local ID_HINH_ANH_ICON = "rbxassetid://117118515787811" 
local BAT_CAN_THIEP_TU_DONG = true        
local MA_PHIM_MO_PHONG = Enum.KeyCode.Space 

-- 📊 Biến Trạng Thái
local thoiDiemInputCuoi = time()
local thoiDiemCanThiepCuoi = 0
local thoiDiemKiemTraCuoi = 0
local boDemCanThiep = 0
local dangDuocXemLaAFK = false
local dangChay = true          
local nguoiChoiCucBo = NguoiChoiService.LocalPlayer

-- 🖼️ Biến Giao Diện Người Dùng (GUI)
local khungChuaThongBao = nil
local mauThongBao = nil
local giaoDienManHinh = nil

-- 🔗 Biến Kết Nối Sự Kiện
local ketNoiInputBegan = nil
local ketNoiInputChanged = nil
local ketNoiPlayerRemoving = nil
local cacTweenDangHoatDong = {}

-- 💎 Hằng Số
local KICH_THUOC_GUI_THONG_BAO = UDim2.new(0, 250, 0, 60)
local VI_TRI_KHUNG_CHUA = UDim2.new(1, -18, 1, -48)
local KICH_THUOC_KHUNG_CHUA = UDim2.new(0, 300, 0, 200)

-- 🧩 Các Hàm Chính

local function donDepTaiNguyen()
	print("Hx: Bắt đầu dọn dẹp tài nguyên...")
	dangChay = false 

	if ketNoiInputBegan then ketNoiInputBegan:Disconnect(); ketNoiInputBegan = nil end
	if ketNoiInputChanged then ketNoiInputChanged:Disconnect(); ketNoiInputChanged = nil end
	if ketNoiPlayerRemoving then ketNoiPlayerRemoving:Disconnect(); ketNoiPlayerRemoving = nil end

	for tweenInstance, _ in pairs(cacTweenDangHoatDong) do
		if typeof(tweenInstance) == "Instance" and tweenInstance:IsA("Tween") then
			tweenInstance:Cancel()
		end
	end
	cacTweenDangHoatDong = {}

	if giaoDienManHinh and giaoDienManHinh.Parent then
		giaoDienManHinh:Destroy()
	end
	giaoDienManHinh = nil
	khungChuaThongBao = nil
	mauThongBao = nil

	nguoiChoiCucBo = nil

	print("Hx: Dọn dẹp hoàn tất.")
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
	icon.Image = ID_HINH_ANH_ICON
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
	if khungChuaThongBao and khungChuaThongBao.Parent and giaoDienManHinh and giaoDienManHinh.Parent then
		return khungChuaThongBao
	end

	if not nguoiChoiCucBo or not nguoiChoiCucBo:IsDescendantOf(NguoiChoiService) then
		warn("Hx: Đối tượng người chơi cục bộ không hợp lệ.")
		return nil
	end
	local playerGui = nguoiChoiCucBo:FindFirstChild("PlayerGui")
	if not playerGui then
		playerGui = nguoiChoiCucBo:WaitForChild("PlayerGui", 5)
		if not playerGui then
			 warn("Hx: Không tìm thấy PlayerGui cho " .. nguoiChoiCucBo.Name)
			 return nil
		end
	end

	local oldGui = playerGui:FindFirstChild("HxContainerGui")
	if oldGui then
		warn("Hx: Phát hiện và hủy GUI Hx_V.0.1 cũ.")
		oldGui:Destroy()
	end

	giaoDienManHinh = Instance.new("ScreenGui")
	giaoDienManHinh.Name = "HxContainerGui"
	giaoDienManHinh.ResetOnSpawn = false
	giaoDienManHinh.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	giaoDienManHinh.DisplayOrder = 999
	giaoDienManHinh.Parent = playerGui

	local container = Instance.new("Frame")
	container.Name = "NotificationContainerFrame"
	container.AnchorPoint = Vector2.new(1, 1)
	container.Position = VI_TRI_KHUNG_CHUA
	container.Size = KICH_THUOC_KHUNG_CHUA
	container.BackgroundTransparency = 1
	container.Parent = giaoDienManHinh

	local listLayout = Instance.new("UIListLayout", container)
	listLayout.FillDirection = Enum.FillDirection.Vertical
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
	listLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	listLayout.Padding = UDim.new(0, 5)

	khungChuaThongBao = container
	return khungChuaThongBao
end

local function hienThiThongBao(tieuDe, noiDung)
	if not dangChay then return end
	if not khungChuaThongBao or not khungChuaThongBao.Parent then warn("Hx: Khung chứa thông báo không hợp lệ."); return end
	if not mauThongBao then warn("Hx: Mẫu thông báo chưa được tạo."); return end

	local khungMoi = mauThongBao:Clone()
	if not khungMoi then warn("Hx: Không thể clone mẫu thông báo."); return end

	local hinhIcon = khungMoi:FindFirstChild("Icon")
	local khungChu = khungMoi:FindFirstChild("TextFrame")
	local nhanTieuDe = khungChu and khungChu:FindFirstChild("Title")
	local nhanNoiDung = khungChu and khungChu:FindFirstChild("Message")

	if not (hinhIcon and nhanTieuDe and nhanNoiDung) then
		warn("Hx: Khung thông báo clone bị lỗi cấu trúc.")
		khungMoi:Destroy()
		return
	end

	nhanTieuDe.Text = tieuDe or "Thông báo"
	nhanNoiDung.Text = noiDung or ""
	khungMoi.Name = "Notification_" .. (tieuDe or "Default"):gsub("%s+", "_")
	khungMoi.Parent = khungChuaThongBao

	local thongTinTweenXuatHien = TweenInfo.new(THOI_GIAN_HOAT_ANH_GIAY, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	local tweenMoDanKhung = DichVuTween:Create(khungMoi, thongTinTweenXuatHien, { BackgroundTransparency = 0.2 })
	local tweenMoDanIcon = DichVuTween:Create(hinhIcon, thongTinTweenXuatHien, { ImageTransparency = 0 })
	local tweenMoDanTieuDe = DichVuTween:Create(nhanTieuDe, thongTinTweenXuatHien, { TextTransparency = 0 })
	local tweenMoDanNoiDung = DichVuTween:Create(nhanNoiDung, thongTinTweenXuatHien, { TextTransparency = 0 })

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
		local tweenMoDanKhung_Mat = DichVuTween:Create(khungMoi, thongTinTweenBienMat, { BackgroundTransparency = 1 })
		local tweenMoDanIcon_Mat = DichVuTween:Create(hinhIcon, thongTinTweenBienMat, { ImageTransparency = 1 })
		local tweenMoDanTieuDe_Mat = DichVuTween:Create(nhanTieuDe, thongTinTweenBienMat, { TextTransparency = 1 })
		local tweenMoDanNoiDung_Mat = DichVuTween:Create(nhanNoiDung, thongTinTweenBienMat, { TextTransparency = 1 })

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

local function thucHienHanhDongChongAFK()
	if not dangChay or not BAT_CAN_THIEP_TU_DONG then return end

	local thanhCong, loi = pcall(function()
		if not nguoiChoiCucBo or not nguoiChoiCucBo:IsDescendantOf(NguoiChoiService) then
			 error("Người chơi cục bộ không còn hợp lệ.")
		end
		QuanLyInputAo:SendKeyEvent(true, MA_PHIM_MO_PHONG, false, game)
		task.wait(0.05 + math.random() * 0.05)
		QuanLyInputAo:SendKeyEvent(false, MA_PHIM_MO_PHONG, false, game)
	end)

	if not thanhCong then
		warn("Hx: Không thể mô phỏng nhấn phím " .. tostring(MA_PHIM_MO_PHONG) .. ". Lỗi:", loi)
	else
		thoiDiemCanThiepCuoi = time()
		boDemCanThiep = boDemCanThiep + 1
		print(string.format("Hx: Đã thực hiện can thiệp lần %d (nhấn %s)", boDemCanThiep, tostring(MA_PHIM_MO_PHONG)))
	end
end

local function xuLyInput(doiTuongInput)
	local loaiInput = doiTuongInput.UserInputType
	local laInputLienQuan = false

	if loaiInput == Enum.UserInputType.Keyboard or
	   loaiInput == Enum.UserInputType.MouseButton1 or
	   loaiInput == Enum.UserInputType.MouseButton2 or
	   loaiInput == Enum.UserInputType.MouseButton3 or
	   loaiInput == Enum.UserInputType.Touch or
	   loaiInput == Enum.UserInputType.MouseMovement or
	   loaiInput == Enum.UserInputType.MouseWheel then
		laInputLienQuan = true
	elseif typeof(loaiInput) == "EnumItem" and loaiInput.Name:sub(1, 7) == "Gamepad" then
		 laInputLienQuan = true
	end

	if laInputLienQuan then
		local hienTai = time()
		if dangDuocXemLaAFK then
			dangDuocXemLaAFK = false
			thoiDiemCanThiepCuoi = 0
			boDemCanThiep = 0
			hienThiThongBao("Bạn đã quay lại!", "Đã tạm dừng can thiệp AFK.")
			print("Hx_V.0.1: Người dùng không còn AFK.")
		end
		thoiDiemInputCuoi = hienTai
	end
end

local function vongLapChinh()
	if not thietLapKhungChuaThongBao() then
		warn("Hx_V.0.1: Không thể khởi tạo container GUI.")
		donDepTaiNguyen()
		return
	end
	if not taoMauThongBao() then
		warn("Hx_V.0.1: Không thể tạo template GUI.")
		donDepTaiNguyen()
		return
	end

	ketNoiInputBegan = DichVuInputNguoiDung.InputBegan:Connect(function(input, gameProcessedEvent)
		if gameProcessedEvent or not dangChay then return end
		xuLyInput(input)
	end)
	ketNoiInputChanged = DichVuInputNguoiDung.InputChanged:Connect(function(input, gameProcessedEvent)
		if gameProcessedEvent or not dangChay then return end
		xuLyInput(input)
	end)

	task.wait(3)
	if not dangChay then return end
	hienThiThongBao("Hx_V.0.1", "Anti AFK đã được kích hoạt.")
	print("Hx_V.0.1 Script đã khởi chạy.")

	while dangChay do
		local hienTai = time()
		local thoiGianRanhRoi = hienTai - thoiDiemInputCuoi

		if dangDuocXemLaAFK then
			local thoiGianTuCanThiepCuoi = hienTai - thoiDiemCanThiepCuoi
			local thoiGianTuKiemTraCuoi = hienTai - thoiDiemKiemTraCuoi

			if BAT_CAN_THIEP_TU_DONG and thoiGianTuCanThiepCuoi >= KHOANG_CAN_THIEP_GIAY then
				if not dangChay then break end
				thucHienHanhDongChongAFK()
				thoiGianTuCanThiepCuoi = hienTai - thoiDiemCanThiepCuoi
			end

			if not dangChay then break end

			if thoiGianTuKiemTraCuoi >= KHOANG_KIEM_TRA_GIAY then
				local canThiepTiepTheoTrong = math.max(0, KHOANG_CAN_THIEP_GIAY - thoiGianTuCanThiepCuoi)
				local thongDiep = BAT_CAN_THIEP_TU_DONG and string.format("Can thiệp tiếp theo sau ~%.0f giây.", canThiepTiepTheoTrong) or "Chế độ can thiệp đang tắt."
				hienThiThongBao("Vẫn đang AFK...", thongDiep)
				thoiDiemKiemTraCuoi = hienTai
			end
		else
			if thoiGianRanhRoi >= NGUONG_AFK_GIAY then
				if not dangChay then break end
				dangDuocXemLaAFK = true
				thoiDiemCanThiepCuoi = hienTai
				thoiDiemKiemTraCuoi = hienTai
				boDemCanThiep = 0
				local thongDiep = BAT_CAN_THIEP_TU_DONG and string.format("Sẽ can thiệp sau ~%.0f giây nếu không hoạt động.", KHOANG_CAN_THIEP_GIAY) or "Bạn hiện đang AFK (can thiệp tự động đang tắt)."
				hienThiThongBao("Cảnh báo AFK!", thongDiep)
				print("Hx_V.0.1: Người dùng được coi là AFK.")
			end
		end

		if not dangChay then break end
		task.wait(0.5)
	end
	print("Hx_V.0.1: Vòng lặp chính đã thoát.")
end

-- ▶️ Khởi Tạo và Dọn Dẹp
if not nguoiChoiCucBo then
	warn("Hx_V.0.1: Không tìm thấy người chơi khi script bắt đầu.")
else
	ketNoiPlayerRemoving = NguoiChoiService.PlayerRemoving:Connect(function(nguoiChoiRoiDi)
		if nguoiChoiRoiDi == nguoiChoiCucBo then
			print("Hx_V.0.1: Người chơi đang rời đi. Bắt đầu dọn dẹp.")
			if dangChay then
			   donDepTaiNguyen()
			end
		end
	end)

	local luongChinh = coroutine.create(vongLapChinh)
	local khoiTaoThanhCong, loiKhoiTao = coroutine.resume(luongChinh)
	if not khoiTaoThanhCong then
		warn("Hx_V.0.1 Lỗi Khởi Tạo Coroutine:", loiKhoiTao)
		if dangChay then donDepTaiNguyen() end
	elseif coroutine.status(luongChinh) == "dead" and dangChay then
		 warn("Hx_V.0.1: Coroutine chính đã kết thúc bất ngờ.")
		 if dangChay then donDepTaiNguyen() end
	end
end
