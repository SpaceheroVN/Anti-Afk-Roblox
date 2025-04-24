--// 🌐 GLOBAL SETUP
_G.AntiAFK_Enabled = _G.AntiAFK_Enabled or false

local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local VIM = game:GetService("VirtualInputManager")
local LP = Players.LocalPlayer
local Mouse = LP:GetMouse()

--// 📦 NOTIFICATION UI
local function CreateNotification(message: string, icon: string)
	local screenGui = game.CoreGui:FindFirstChild("NiceNotify") or Instance.new("ScreenGui", game.CoreGui)
	screenGui.Name = "NiceNotify"
	screenGui.ResetOnSpawn = false

	local container = Instance.new("Frame", screenGui)
	container.AnchorPoint = Vector2.new(1, 0)
	container.Position = UDim2.new(1, -10, 0, 10)
	container.Size = UDim2.new(0, 300, 0, 50)
	container.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	container.BackgroundTransparency = 0.2
	container.BorderSizePixel = 0
	container.AutomaticSize = Enum.AutomaticSize.Y
	container.ClipsDescendants = true
	container.Name = "NotifyBox"
	container.ZIndex = 20
	container:SetAttribute("Life", tick())

	local uiCorner = Instance.new("UICorner", container)
	uiCorner.CornerRadius = UDim.new(0, 12)

	local iconLabel = Instance.new("ImageLabel", container)
	iconLabel.Image = icon
	iconLabel.Size = UDim2.new(0, 30, 0, 30)
	iconLabel.Position = UDim2.new(0, 10, 0.5, -15)
	iconLabel.BackgroundTransparency = 1

	local textLabel = Instance.new("TextLabel", container)
	textLabel.Text = message
	textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	textLabel.TextTransparency = 0
	textLabel.Font = Enum.Font.Gotham
	textLabel.TextSize = 14
	textLabel.TextWrapped = true
	textLabel.BackgroundTransparency = 1
	textLabel.Position = UDim2.new(0, 50, 0, 5)
	textLabel.Size = UDim2.new(1, -60, 1, -10)
	textLabel.TextXAlignment = Enum.TextXAlignment.Left

	-- Animate in
	container.Position = UDim2.new(1, 310, 0, 10)
	container:TweenPosition(UDim2.new(1, -10, 0, 10), Enum.EasingDirection.Out, Enum.EasingStyle.Quint, 0.4, true)

	-- Auto destroy after delay
	task.delay(4, function()
		if container then
			container:TweenPosition(UDim2.new(1, 310, 0, 10), Enum.EasingDirection.In, Enum.EasingStyle.Quad, 0.3, true)
			task.wait(0.35)
			if container then container:Destroy() end
		end
	end)
end

--// 🤖 ANTI AFK CORE
local AntiAFK_Connection = nil

local function ToggleAntiAFK(state: boolean)
	if state then
		AntiAFK_Connection = game:GetService("Players").LocalPlayer.Idled:Connect(function()
			VIM:SendKeyEvent(true, Enum.KeyCode.Space, false, nil)
			VIM:SendKeyEvent(false, Enum.KeyCode.Space, false, nil)
			CreateNotification("Đã tránh kick AFK", "rbxassetid://7734053491")
		end)
	else
		if AntiAFK_Connection then
			AntiAFK_Connection:Disconnect()
			AntiAFK_Connection = nil
		end
	end
end

--// 🎛️ MAIN GUI
local screenGui = Instance.new("ScreenGui", game.CoreGui)
screenGui.Name = "MainScriptUI"
screenGui.ResetOnSpawn = false

local mainFrame = Instance.new("Frame", screenGui)
mainFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 45)
mainFrame.Position = UDim2.new(0, 10, 0.5, -100)
mainFrame.Size = UDim2.new(0, 170, 0, 130)
mainFrame.ZIndex = 10

local corner = Instance.new("UICorner", mainFrame)
corner.CornerRadius = UDim.new(0, 16)

local logo = Instance.new("ImageLabel", mainFrame)
logo.Image = "rbxassetid://7733684309"
logo.BackgroundTransparency = 1
logo.Size = UDim2.new(0, 32, 0, 32)
logo.Position = UDim2.new(0, 10, 0, 10)

local title = Instance.new("TextLabel", mainFrame)
title.Text = "Tiện ích"
title.Font = Enum.Font.GothamBold
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 16
title.Position = UDim2.new(0, 50, 0, 14)
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, -60, 0, 20)
title.TextXAlignment = Enum.TextXAlignment.Left

local antiAFKToggle = Instance.new("TextButton", mainFrame)
antiAFKToggle.Size = UDim2.new(1, -20, 0, 30)
antiAFKToggle.Position = UDim2.new(0, 10, 0, 60)
antiAFKToggle.BackgroundColor3 = Color3.fromRGB(70, 70, 70)
antiAFKToggle.TextColor3 = Color3.fromRGB(255, 255, 255)
antiAFKToggle.Text = "Bật AntiAFK"
antiAFKToggle.Font = Enum.Font.Gotham
antiAFKToggle.TextSize = 14

Instance.new("UICorner", antiAFKToggle).CornerRadius = UDim.new(0, 8)

--// 🎮 HOOKUP TOGGLE
antiAFKToggle.MouseButton1Click:Connect(function()
	_G.AntiAFK_Enabled = not _G.AntiAFK_Enabled
	ToggleAntiAFK(_G.AntiAFK_Enabled)
	antiAFKToggle.Text = _G.AntiAFK_Enabled and "Tắt AntiAFK" or "Bật AntiAFK"
	CreateNotification(_G.AntiAFK_Enabled and "Đã bật AntiAFK" or "Đã tắt AntiAFK", "rbxassetid://7734053491")
end)

-- Nếu người dùng bật sẵn từ trước
if _G.AntiAFK_Enabled then
	ToggleAntiAFK(true)
	antiAFKToggle.Text = "Tắt AntiAFK"
end
