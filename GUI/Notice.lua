--[[
    Standalone Notification Module
    Version: 1.0
    Description: A self-contained notification system for Roblox.
    API:
        Notifier.show({
            title = "string",
            message = "string",
            icon = "System" | "Success" | "Warning" | "Error" | "rbxassetid://...",
            duration = number (optional, default is 4s)
        })
]]

local Notifier = {}

--===== ⚙️ Module Configuration =====--
-- Tất cả các cài đặt cần thiết đều nằm ở đây, không phụ thuộc script bên ngoài.
local Config = {
    NotificationDuration = 4,
    AnimationTime = 0.2,
    NotificationWidth = 250,
    NotificationHeight = 60,
    NotificationAnchor = Vector2.new(1, 1),
    NotificationPosition = UDim2.new(1, -18, 1, -48),

    -- Icons
    IconSystem = "rbxassetid://117118515787811",
    IconSuccess = "rbxassetid://15229232932", -- Checkmark Icon
    IconWarning = "rbxassetid://15229234832", -- Warning Icon
    IconError = "rbxassetid://15229231238",   -- X Icon

    -- Colors
    ColorBackground = Color3.fromRGB(40, 40, 45),
    ColorBorder = Color3.fromRGB(80, 80, 90),
    ColorTextPrimary = Color3.fromRGB(245, 245, 245),
    ColorTextSecondary = Color3.fromRGB(190, 190, 200),
}
local TWEEN_INFO_FAST = TweenInfo.new(Config.AnimationTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
local TWEEN_INFO_FAST_IN = TweenInfo.new(Config.AnimationTime, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui")

--===== 📦 Module State =====--
-- Chỉ lưu trữ các đối tượng UI cần thiết cho module này.
local moduleState = {
    ScreenGui = nil,
    NotificationContainer = nil,
    NotificationTemplate = nil,
}

--===== 🔧 Helper Functions =====--
local function createTemplate()
    if moduleState.NotificationTemplate then return moduleState.NotificationTemplate end
    
    local frame = Instance.new("Frame")
    frame.Name = "Notification_Template"
    frame.BackgroundColor3 = Config.ColorBackground
    frame.BackgroundTransparency = 1
    frame.BorderSizePixel = 1
    frame.BorderColor3 = Config.ColorBorder
    frame.Size = UDim2.new(0, Config.NotificationWidth, 0, Config.NotificationHeight)
    frame.ClipsDescendants = true
    
    local corner = Instance.new("UICorner", frame); corner.CornerRadius = UDim.new(0, 8)
    local padding = Instance.new("UIPadding", frame); padding.PaddingLeft=UDim.new(0,10); padding.PaddingRight=UDim.new(0,10); padding.PaddingTop=UDim.new(0,5); padding.PaddingBottom=UDim.new(0,5)
    local layout = Instance.new("UIListLayout", frame); layout.FillDirection=Enum.FillDirection.Horizontal; layout.VerticalAlignment=Enum.VerticalAlignment.Center; layout.SortOrder=Enum.SortOrder.LayoutOrder; layout.Padding=UDim.new(0,10)
    
    local icon = Instance.new("ImageLabel"); icon.Name="Icon"; icon.BackgroundTransparency=1; icon.ImageTransparency=1; icon.Size=UDim2.new(0,35,0,35); icon.LayoutOrder=1; icon.Parent=frame
    
    local textFrame = Instance.new("Frame"); textFrame.Name="TextFrame"; textFrame.BackgroundTransparency=1; textFrame.Size=UDim2.new(1,-55,1,0); textFrame.LayoutOrder=2; textFrame.Parent=frame
    local textLayout = Instance.new("UIListLayout", textFrame); textLayout.FillDirection=Enum.FillDirection.Vertical; textLayout.HorizontalAlignment=Enum.HorizontalAlignment.Left; textLayout.VerticalAlignment=Enum.VerticalAlignment.Center; textLayout.SortOrder=Enum.SortOrder.LayoutOrder; textLayout.Padding=UDim.new(0,2)
    
    local title = Instance.new("TextLabel"); title.Name="Title"; title.Font=Enum.Font.SourceSansBold; title.TextSize=17; title.TextColor3=Config.ColorTextPrimary; title.BackgroundTransparency=1; title.TextTransparency=1; title.TextXAlignment=Enum.TextXAlignment.Left; title.Size=UDim2.new(1,0,0,20); title.LayoutOrder=1; title.Parent=textFrame
    local message = Instance.new("TextLabel"); message.Name="Message"; message.Font=Enum.Font.SourceSans; message.TextSize=14; message.TextColor3=Config.ColorTextSecondary; message.BackgroundTransparency=1; message.TextTransparency=1; message.TextXAlignment=Enum.TextXAlignment.Left; message.TextWrapped=true; message.Size=UDim2.new(1,0,0.6,0); message.LayoutOrder=2; message.Parent=textFrame
    
    moduleState.NotificationTemplate = frame
    return frame
end

local function getContainer()
    if moduleState.NotificationContainer and moduleState.NotificationContainer.Parent then
        return moduleState.NotificationContainer
    end

    moduleState.ScreenGui = CoreGui:FindFirstChild("HxNotificationGui") or Instance.new("ScreenGui", CoreGui)
    moduleState.ScreenGui.Name = "HxNotificationGui"
    moduleState.ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    moduleState.ScreenGui.DisplayOrder = 9999 -- Luôn hiển thị trên cùng

    local container = Instance.new("Frame")
    container.Name = "NotificationContainer"
    container.AnchorPoint = Config.NotificationAnchor
    container.Position = Config.NotificationPosition
    container.Size = UDim2.new(0, Config.NotificationWidth + 20, 1, 0)
    container.BackgroundTransparency = 1
    container.Parent = moduleState.ScreenGui

    local listLayout = Instance.new("UIListLayout", container)
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    listLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    listLayout.SortOrder = Enum.SortOrder.LayoutOrder
    listLayout.Padding = UDim.new(0, 5)

    moduleState.NotificationContainer = container
    return container
end


--===== 📢 Public API =====--

function Notifier.show(props)
    local success, err = pcall(function()
        props = props or {}
        local titleText = props.title or "Notification"
        local messageText = props.message or ""
        local iconType = props.icon or "System"
        local duration = props.duration or Config.NotificationDuration

        local container = getContainer()
        local template = createTemplate()
        if not (container and template) then return end
        
        local notification = template:Clone()
        local iconLabel, textFrame = notification:FindFirstChild("Icon"), notification:FindFirstChild("TextFrame")
        local titleLabel, messageLabel = textFrame:FindFirstChild("Title"), textFrame:FindFirstChild("Message")

        if not (iconLabel and titleLabel and messageLabel) then
            notification:Destroy()
            return
        end

        titleLabel.Text = titleText
        messageLabel.Text = messageText

        if iconType == "System" then iconLabel.Image = Config.IconSystem
        elseif iconType == "Success" then iconLabel.Image = Config.IconSuccess
        elseif iconType == "Warning" then iconLabel.Image = Config.IconWarning
        elseif iconType == "Error" then iconLabel.Image = Config.IconError
        else iconLabel.Image = iconType -- Cho phép dùng rbxassetid trực tiếp
        end
        
        notification.Parent = container

        -- Fade In Animation
        local fadeInGoals = {BackgroundTransparency = 0.1}
        local fadeInElements = {notification, iconLabel, titleLabel, messageLabel}
        for _, element in ipairs(fadeInElements) do
            local propName = (element:IsA("ImageLabel")) and "ImageTransparency" or (element:IsA("TextLabel")) and "TextTransparency" or "BackgroundTransparency"
            local goal = {[propName] = (propName == "BackgroundTransparency") and 0.1 or 0}
            TweenService:Create(element, TWEEN_INFO_FAST, goal):Play()
        end

        -- Fade Out
        task.delay(duration, function()
            if not notification or not notification.Parent then return end
            
            for _, element in ipairs(fadeInElements) do
                 local propName = (element:IsA("ImageLabel")) and "ImageTransparency" or (element:IsA("TextLabel")) and "TextTransparency" or "BackgroundTransparency"
                 local tween = TweenService:Create(element, TWEEN_INFO_FAST_IN, {[propName] = 1})
                 if element == notification then
                     tween.Completed:Connect(function() notification:Destroy() end)
                 end
                 tween:Play()
            end
        end)
    end)

    if not success then
        warn("Notification Module Error:", err)
    end
end

return Notifier
