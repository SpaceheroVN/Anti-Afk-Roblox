-- Anti AFK Script with Lag-Reduction Prompt
local UserInputService      = game:GetService("UserInputService")
local Players               = game:GetService("Players")
local RunService            = game:GetService("RunService")
local VirtualInputManager   = game:GetService("VirtualInputManager")
local TweenService          = game:GetService("TweenService")
local UserSettings          = UserSettings()  -- for graphics quality

local afkThreshold          = 180
local interventionInterval  = 600
local checkInterval         = 60
local notificationDuration  = 5
local animationTime         = 0.5
local iconAssetId           = "rbxassetid://117118515787811"
local enableIntervention    = true
local simulatedKeyCode      = Enum.KeyCode.Space

local lastInputTime         = os.clock()
local lastInterventionTime  = 0
local lastCheckTime         = 0
local interventionCounter   = 0
local isConsideredAFK       = false

local notificationContainer = nil
local notificationTemplate  = nil
local inputBeganConnection  = nil
local inputChangedConnection = nil
local player                = Players.LocalPlayer

local guiSize = UDim2.new(0, 250, 0, 60)

-- existing functions: createNotificationTemplate, setupNotificationContainer, showNotification, performAntiAFKAction, onInput, cleanup
-- [Insert the existing functions here unchanged]

-- Function to apply lowest graphics settings
local function applyLowGraphics()
    -- Set quality to lowest
    local success, settings = pcall(function()
        return UserSettings():GetService("UserGameSettings")
    end)
    if success and settings.SetTechnology then
        -- Some APIs use SetQualityLevel or similar
        if settings.SetQualityLevel then
            settings:SetQualityLevel(Enum.SavedQualitySetting.QualityLevel1, true)
        elseif settings.SetVisualSettingsOverride then
            settings:SetVisualSettingsOverride(Enum.SavedQualitySetting.QualityLevel1)
        end
    end
    -- Disable shadows and heavy effects
    if game.Lighting then
        game.Lighting.GlobalShadows = false
        game.Lighting.FogEnd = 0
    end
    -- Disable particle emitters, trails, beams
    for _, obj in ipairs(workspace:GetDescendants()) do
        if obj:IsA("ParticleEmitter") or obj:IsA("Trail") or obj:IsA("Beam") then
            obj.Enabled = false
        end
    end
    -- Show confirmation
    showNotification("Đang giảm lag...", "Thành công!!!!")
end

-- Function to show lag-reduction prompt
local function showLagOptionNotification()
    if not notificationContainer or not notificationContainer.Parent then
        setupNotificationContainer()
    end
    if not notificationTemplate then
        createNotificationTemplate()
    end

    local frame = notificationTemplate:Clone()
    frame.Name = "LagOptionNotification"
    frame.Parent = notificationContainer

    -- Adjust size to fit buttons
    frame.Size = UDim2.new(0, 300, 0, 100)

    -- Update title and message
    local textFrame = frame:FindFirstChild("TextFrame")
    if textFrame then
        local titleLabel = textFrame:FindFirstChild("Title")
        local messageLabel = textFrame:FindFirstChild("Message")
        titleLabel.Text = "Bạn có muốn giảm lag không?"
        messageLabel.Text = ""
    end

    -- Create button container
    local buttonContainer = Instance.new("Frame")
    buttonContainer.Name = "ButtonContainer"
    buttonContainer.BackgroundTransparency = 1
    buttonContainer.Size = UDim2.new(1, 0, 0, 30)
    buttonContainer.Position = UDim2.new(0, 0, 1, -35)
    buttonContainer.Parent = frame

    local listLayout = Instance.new("UIListLayout", buttonContainer)
    listLayout.FillDirection = Enum.FillDirection.Horizontal
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    listLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    listLayout.Padding = UDim.new(0, 10)

    -- "Có" button
    local yesBtn = Instance.new("TextButton")
    yesBtn.Name = "YesButton"
    yesBtn.Text = "Có"
    yesBtn.Font = Enum.Font.GothamBold
    yesBtn.TextSize = 14
    yesBtn.BackgroundColor3 = Color3.fromRGB(50, 200, 50)
    yesBtn.TextColor3 = Color3.new(1,1,1)
    yesBtn.Size = UDim2.new(0, 100, 1, -10)
    yesBtn.AutoButtonColor = true
    yesBtn.Parent = buttonContainer
    yesBtn.MouseButton1Click:Connect(function()
        frame:Destroy()
        applyLowGraphics()
    end)

    -- "Không" button
    local noBtn = yesBtn:Clone()
    noBtn.Name = "NoButton"
    noBtn.Text = "Không"
    noBtn.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
    noBtn.Parent = buttonContainer
    noBtn.MouseButton1Click:Connect(function()
        frame:Destroy()
    end)
end

-- In main, after initial activation notification, show lag prompt
local function main()
    notificationContainer = setupNotificationContainer()
    if not notificationContainer then return end

    notificationTemplate = createNotificationTemplate()
    if not notificationTemplate then return end

    inputBeganConnection = UserInputService.InputBegan:Connect(function(input, processed)
        if processed then return end
        if input.UserInputType == Enum.UserInputType.Keyboard
            or input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.MouseButton2
            or input.UserInputType == Enum.UserInputType.Touch then
                onInput()
        end
    end)
    inputChangedConnection = UserInputService.InputChanged:Connect(function(input, processed)
        if processed then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.MouseWheel
            or tostring(input.UserInputType):find("Gamepad") then
                onInput()
        end
    end)

    task.wait(3)
    showNotification("Anti AFK", "Đã được kích hoạt.")
    showLagOptionNotification()  -- New prompt
    print("Anti-AFK Script đã khởi chạy và đang theo dõi input.")

    -- rest of while loop unchanged...
end

-- Start the script
local mainThread = coroutine.create(main)
local success, err = coroutine.resume(mainThread)
if not success then warn("AntiAFK Lỗi Khởi Tạo:", err) end

if player then
    Players.PlayerRemoving:Connect(function(leaving)
        if leaving == player then cleanup() end
    end)
else
    warn("AntiAFK: Không tìm thấy LocalPlayer.")
end
