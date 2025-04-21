--⚙️ Dịch vụ cần thiết
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

--📦 Biến kết nối và nút
local inputBeganConnection
local inputChangedConnection
local afkButton

--📌 Hàm ngắt kết nối an toàn
local function disconnectConnection(conn)
	if conn and typeof(conn) == "RBXScriptConnection" then
		conn:Disconnect()
	end
end

--🔄 Hàm dọn dẹp khi cần thiết
local function cleanup()
	disconnectConnection(inputBeganConnection)
	disconnectConnection(inputChangedConnection)
	if afkButton then
		afkButton:Destroy()
		afkButton = nil
	end
end

--🎨 Tạo nút UI tùy chỉnh
local function createCustomButton()
	-- Đảm bảo ScreenGui tồn tại
	local screenGui = playerGui:FindFirstChild("AFKControlGui")
	if not screenGui then
		screenGui = Instance.new("ScreenGui")
		screenGui.Name = "AFKControlGui"
		screenGui.ResetOnSpawn = false
		screenGui.Parent = playerGui
	end

	-- Nút chính
	local buttonFrame = Instance.new("TextButton")
	buttonFrame.Name = "AFKButton"
	buttonFrame.Size = UDim2.new(0, 140, 0, 40)
	buttonFrame.Position = UDim2.new(1, -160, 1, -60)
	buttonFrame.AnchorPoint = Vector2.new(1, 1)
	buttonFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	buttonFrame.BackgroundTransparency = 0.5
	buttonFrame.TextColor3 = Color3.fromRGB(255, 255, 255)
	buttonFrame.Text = "Anti AFK: OFF"
	buttonFrame.Font = Enum.Font.GothamBold
	buttonFrame.TextSize = 16
	buttonFrame.AutoButtonColor = false
	buttonFrame.Parent = screenGui

	-- Viền nút
	local border = Instance.new("UIStroke")
	border.Color = Color3.fromRGB(255, 255, 255)
	border.Thickness = 2
	border.Transparency = 0.3
	border.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	border.Parent = buttonFrame

	-- Bo góc
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 8)
	corner.Parent = buttonFrame

	return buttonFrame
end

--🖱️ Cài đặt hiệu ứng tương tác hover
local function setupButtonInteraction(buttonFrame)
	local hoverIn = TweenService:Create(buttonFrame, TweenInfo.new(0.3), { BackgroundTransparency = 0.2 })
	local hoverOut = TweenService:Create(buttonFrame, TweenInfo.new(0.3), { BackgroundTransparency = 0.5 })

	local border = buttonFrame:FindFirstChild("UIStroke")
	local borderIn = border and TweenService:Create(border, TweenInfo.new(0.3), { Transparency = 0 })
	local borderOut = border and TweenService:Create(border, TweenInfo.new(0.3), { Transparency = 0.3 })

	buttonFrame.MouseEnter:Connect(function()
		hoverIn:Play()
		if borderIn then borderIn:Play() end
	end)

	buttonFrame.MouseLeave:Connect(function()
		hoverOut:Play()
		if borderOut then borderOut:Play() end
	end)
end

--🚫 Cài đặt phát hiện AFK và xử lý input
local function activateAntiAFK(button)
	if inputBeganConnection or inputChangedConnection then return end

	inputBeganConnection = UserInputService.InputBegan:Connect(function()
		if button then button.Text = "Anti AFK: ON (Input)" end
	end)

	inputChangedConnection = UserInputService.InputChanged:Connect(function()
		if button then button.Text = "Anti AFK: ON (Input)" end
	end)
end

--▶️ Hàm khởi động và xử lý nút bấm
local function init()
	cleanup()

	afkButton = createCustomButton()
	setupButtonInteraction(afkButton)

	local active = false

	afkButton.MouseButton1Click:Connect(function()
		active = not active
		if active then
			activateAntiAFK(afkButton)
			afkButton.Text = "Anti AFK: ON"
			afkButton.BackgroundColor3 = Color3.fromRGB(60, 180, 75) -- Màu xanh
		else
			cleanup()
			afkButton = createCustomButton()
			setupButtonInteraction(afkButton)
			afkButton.Text = "Anti AFK: OFF"
			afkButton.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
		end
	end)
end

--▶️ Khởi chạy script
init()
