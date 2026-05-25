local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BuildCatalog = require(ReplicatedStorage:WaitForChild("BuildCatalog"))

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("MoneyMuncherRemotes")
local placeBuildItem = remotes:WaitForChild("PlaceBuildItem")
local buildResult = remotes:WaitForChild("BuildResult")

local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "MoneyMuncherBuildUI"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local toggle = Instance.new("TextButton")
toggle.Name = "BuildToggle"
toggle.AnchorPoint = Vector2.new(1, 0)
toggle.Position = UDim2.new(1, -18, 0, 18)
toggle.Size = UDim2.fromOffset(160, 42)
toggle.BackgroundColor3 = Color3.fromRGB(255, 196, 61)
toggle.TextColor3 = Color3.fromRGB(15, 22, 35)
toggle.Font = Enum.Font.GothamBold
toggle.TextSize = 18
toggle.Text = "Build Park"
toggle.Parent = gui

local toggleCorner = Instance.new("UICorner")
toggleCorner.CornerRadius = UDim.new(0, 9)
toggleCorner.Parent = toggle

local panel = Instance.new("Frame")
panel.Name = "BuildPanel"
panel.AnchorPoint = Vector2.new(1, 0)
panel.Position = UDim2.new(1, -18, 0, 70)
panel.Size = UDim2.fromOffset(285, 360)
panel.BackgroundColor3 = Color3.fromRGB(15, 22, 35)
panel.BackgroundTransparency = 0.06
panel.Visible = false
panel.Parent = gui

local panelCorner = Instance.new("UICorner")
panelCorner.CornerRadius = UDim.new(0, 10)
panelCorner.Parent = panel

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Position = UDim2.fromOffset(16, 12)
title.Size = UDim2.fromOffset(253, 40)
title.BackgroundTransparency = 1
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.Font = Enum.Font.GothamBold
title.TextSize = 21
title.Text = "Build Your Money Park"
title.TextXAlignment = Enum.TextXAlignment.Left
title.Parent = panel

local message = Instance.new("TextLabel")
message.Name = "Message"
message.Position = UDim2.fromOffset(16, 306)
message.Size = UDim2.fromOffset(253, 38)
message.BackgroundTransparency = 1
message.TextColor3 = Color3.fromRGB(255, 231, 137)
message.Font = Enum.Font.Gotham
message.TextSize = 15
message.TextWrapped = true
message.Text = "Spend earned coins on safe preset items."
message.Parent = panel

local function makeButton(item, index)
    local button = Instance.new("TextButton")
    button.Name = item.id
    button.Position = UDim2.fromOffset(16, 60 + (index - 1) * 48)
    button.Size = UDim2.fromOffset(253, 38)
    button.BackgroundColor3 = Color3.fromRGB(88, 210, 143)
    button.TextColor3 = Color3.fromRGB(15, 22, 35)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 16
    button.Text = string.format("%s - %d coins", item.displayName, item.cost)
    button.Parent = panel

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = button

    button.Activated:Connect(function()
        message.Text = "Building " .. item.displayName .. "..."
        placeBuildItem:FireServer(item.id)
    end)
end

for index, item in ipairs(BuildCatalog.publicList()) do
    makeButton(item, index)
end

toggle.Activated:Connect(function()
    panel.Visible = not panel.Visible
end)

buildResult.OnClientEvent:Connect(function(success, resultMessage)
    message.Text = resultMessage or (success and "Built!" or "Could not build.")
    message.TextColor3 = success and Color3.fromRGB(168, 255, 190) or Color3.fromRGB(255, 170, 170)
end)
