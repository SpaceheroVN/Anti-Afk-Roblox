--// Services
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

--// Config
local player = Players.LocalPlayer
local simulatedKeyCode = Enum.KeyCode.Space
local iconAssetId = "rbxassetid://117118515787811"
local afkThreshold = 180
local interventionInterval = 600
local checkInterval = 60
local notificationDuration = 5
local animationTime = 0.5
local enableIntervention = true
local guiSize = UDim2.new(0, 250, 0, 60)

--// Constants for GUI Names
local NOTIFICATION_GUI_NAME = "AntiAFK_NotificationContainerGui_v2"
local BUTTON_GUI_NAME = "AntiAFK_ButtonGui_v2"

--// State
local lastInputTime = os.clock()
local lastInterventionTime = 0
local interventionCounter = 0
local isConsideredAFK = false
local notificationContainer = nil
local notificationTemplate = nil
local notificationScreenGui = nil
local buttonScreenGui = nil

--// Utility
local function disconnectConnection(conn)
	if conn then conn:Disconnect() end
end

local function cleanupPreviousInstances()
	print("AntiAFK Cleanup: Bắt đầu quét dọn các phiên bản cũ...")

	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then return end

	for _, gui in ipairs(playerGui:GetChildren()) do
		if gui:IsA("ScreenGui") and (gui.Name == NOTIFICATION_GUI_NAME or gui.Name == BUTTON_GUI_NAME) then
			print("AntiAFK Cleanup: Phát hiện GUI cũ (tên: " .. gui.Name .. "): " .. gui:GetFullName())
			gui:Destroy()
			print("AntiAFK Cleanup: Đã huỷ thành công: " .. gui.ClassName)
		end
	end

	notificationContainer = nil
	notificationTemplate = nil
	notificationScreenGui = nil
	buttonScreenGui = nil

	print("AntiAFK Cleanup: Hoàn tất reset biến & GUI.")
end

--// Notification
local function createNotificationTemplate()
	if notificationTemplate then return notificationTemplate end

	local frame = Instance.new("Frame")
	frame.Name = "NotificationFrameTemplate"
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	frame.BackgroundTransparency = 1
	frame.Size = guiSize
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)

	local padding = Instance.new("UIPadding", frame)
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 10)

	local layout = Instance.new("UIListLayout", frame)
	layout.FillDirection = Enum.FillDirection.Horizontal
	layout.VerticalAlignment = Enum.VerticalAlignment.Center
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 10)

	local icon = Instance.new("ImageLabel", frame)
	icon.Name = "Icon"
	icon.Image = iconAssetId
	icon.Size = UDim2.new(0, 40, 0, 40)
	icon.BackgroundTransparency = 1
	icon.ImageTransparency = 1

	local textFrame = Instance.new("Frame", frame)
	textFrame.Name = "TextFrame"
	textFrame.BackgroundTransparency = 1
	textFrame.Size = UDim2.new(1, -50, 1, 0)

	local title = Instance.new("TextLabel", textFrame)
	title.Name = "Title"
	title.Text = "Thông báo"
	title.Font = Enum.Font.GothamBold
	title.TextSize = 15
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.BackgroundTransparency = 1
	title.TextTransparency = 1
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Size = UDim2.new(1, 0, 0, 18)

	local message = Instance.new("TextLabel", textFrame)
	message.Name = "Message"
	message.Text = "Nội dung"
	message.Font = Enum.Font.Gotham
	message.TextSize = 13
	message.TextColor3 = Color3.fromRGB(200, 200, 200)
	message.BackgroundTransparency = 1
	message.TextTransparency = 1
	message.TextWrapped = true
	message.TextXAlignment = Enum.TextXAlignment.Left
	message.Size = UDim2.new(1, 0, 0, 24)

	notificationTemplate = frame
	return frame
end

local function setupNotificationContainer()
	local playerGui = player:FindFirstChild("PlayerGui")
	if not playerGui then return end

	local gui = Instance.new("ScreenGui", playerGui)
	gui.Name = NOTIFICATION_GUI_NAME
	gui.ResetOnSpawn = false
	gui.DisplayOrder = 999

	local container = Instance.new("Frame", gui)
	container.Name = "NotificationContainerFrame"
	container.AnchorPoint = Vector2.new(1, 1)
	container.Position = UDim2.new(1, -18, 1, -48)
	container.Size = UDim2.new(0, 300, 0, 200)
	container.BackgroundTransparency = 1

	local layout = Instance.new("UIListLayout", container)
	layout.FillDirection = Enum.FillDirection.Vertical
	layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 5)

	notificationContainer = container
	return container
end

local function showNotification(title, message)
	if not notificationContainer then setupNotificationContainer() end
	if not notificationTemplate then createNotificationTemplate() end

	local newFrame = notificationTemplate:Clone()
	newFrame.TextFrame.Title.Text = title
	newFrame.TextFrame.Message.Text = message
	newFrame.Parent = notificationContainer

	local tweenInfo = TweenInfo.new(animationTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
	TweenService:Create(newFrame, tweenInfo, { BackgroundTransparency = 0.2 }):Play()
	TweenService:Create(newFrame.Icon, tweenInfo, { ImageTransparency = 0 }):Play()
	TweenService:Create(newFrame.TextFrame.Title, tweenInfo, { TextTransparency = 0 }):Play()
	TweenService:Create(newFrame.TextFrame.Message, tweenInfo, { TextTransparency = 0 }):Play()

	task.delay(notificationDuration, function()
		local tweenOut = TweenInfo.new(animationTime, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
		TweenService:Create(newFrame, tweenOut, { BackgroundTransparency = 1 }):Play()
		TweenService:Create(newFrame.Icon, tweenOut, { ImageTransparency = 1 }):Play()
		TweenService:Create(newFrame.TextFrame.Title, tweenOut, { TextTransparency = 1 }):Play()
		TweenService:Create(newFrame.TextFrame.Message, tweenOut, { TextTransparency = 1 }):Play()
		task.delay(animationTime, function()
			if newFrame then newFrame:Destroy() end
		end)
	end)
end

--// Anti-AFK
local function performAntiAFKAction()
	if not enableIntervention then return end
	pcall(function()
		VirtualInputManager:SendKeyEvent(true, simulatedKeyCode, false, game)
		task.wait(0.1)
		VirtualInputManager:SendKeyEvent(false, simulatedKeyCode, false, game)
	end)
	lastInterventionTime = os.clock()
	interventionCounter += 1
end

local function onInput()
	if isConsideredAFK then
		isConsideredAFK = false
		lastInterventionTime = 0
		interventionCounter = 0
		showNotification("Bạn đã quay lại!", "Đã tạm dừng can thiệp AFK.")
	end
	lastInputTime = os.clock()
end

--// Optimization Button
local function createCustomButton()
	local playerGui = player:WaitForChild("PlayerGui")
	local screenGui = Instance.new("ScreenGui", playerGui)
	screenGui.Name = BUTTON_GUI_NAME
	screenGui.ResetOnSpawn = false
	screenGui.DisplayOrder = 998

	local frame = Instance.new("Frame", screenGui)
	frame.Name = "CustomButton"
	frame.Size = UDim2.new(0, 120, 0, 40)
	frame.Position = UDim2.new(1, -20, 1, -50)
	frame.AnchorPoint = Vector2.new(1, 1)
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
	frame.BackgroundTransparency = 0.5

	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 8)
	local stroke = Instance.new("UIStroke", frame)
	stroke.Thickness = 2
	stroke.Color = Color3.fromRGB(50, 50, 50)
	stroke.Transparency = 0.3

	local title = Instance.new("TextLabel", frame)
	title.Name = "Title"
	title.Text = "Tối ưu"
	title.Font = Enum.Font.GothamBold
	title.TextSize = 14
	title.TextColor3 = Color3.fromRGB(255, 255, 255)
	title.BackgroundTransparency = 1
	title.Size = UDim2.new(1, 0, 1, 0)

	return frame, title
end

local function optimizeGame()
	settings().Rendering.QualityLevel = Enum.QualityLevel.Level01
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("Decal") or obj:IsA("Texture") then
			obj.Transparency = 1
		elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
			obj.Enabled = false
		elseif obj:IsA("BasePart") then
			obj.Material = Enum.Material.Plastic
			obj.Reflectance = 0
		end
	end
end

local function restoreSettings()
	settings().Rendering.QualityLevel = Enum.QualityLevel.Automatic
	for _, obj in ipairs(workspace:GetDescendants()) do
		if obj:IsA("Decal") or obj:IsA("Texture") then
			obj.Transparency = 0
		elseif obj:IsA("ParticleEmitter") or obj:IsA("Trail") then
			obj.Enabled = true
		elseif obj:IsA("BasePart") then
			obj.Material = Enum.Material.SmoothPlastic
			obj.Reflectance = 0
		end
	end
end

local function setupButtonInteraction(button, title)
	local formatting = false
	local isOptimized = false
	local dots = 0

	local function animateDots()
		while formatting do
			dots = (dots + 1) % 4
			title.Text = "Đang định dạng" .. string.rep(".", dots)
			wait(0.5)
		end
	end

	button.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 and not formatting then
			formatting = true
			button.BackgroundColor3 = Color3.fromRGB(255, 213, 0)
			task.spawn(animateDots)

			task.delay(3, function()
				formatting = false
				if not isOptimized then
					optimizeGame()
					title.Text = "Hủy tối ưu"
					button.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
					isOptimized = true
				else
					restoreSettings()
					title.Text = "Tối ưu"
					button.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
					isOptimized = false
				end
			end)
		end
	end)
end

--// Start
cleanupPreviousInstances()
local button, title = createCustomButton()
setupButtonInteraction(button, title)
UserInputService.InputBegan:Connect(onInput)
