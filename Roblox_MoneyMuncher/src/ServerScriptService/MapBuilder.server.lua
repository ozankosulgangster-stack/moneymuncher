local CollectionService = game:GetService("CollectionService")

local function makePart(name, position, size, color, parent)
    local part = Instance.new("Part")
    part.Name = name
    part.Anchored = true
    part.Position = position
    part.Size = size
    part.Color = color
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = parent
    return part
end

local function makeSign(text, position, parent)
    local post = makePart("SignPost", position + Vector3.new(0, -2.5, 0), Vector3.new(0.8, 5, 0.8), Color3.fromRGB(105, 65, 32), parent)
    local board = makePart("MapSign", position, Vector3.new(14, 5, 1), Color3.fromRGB(255, 223, 120), parent)

    local gui = Instance.new("SurfaceGui")
    gui.Face = Enum.NormalId.Front
    gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    gui.PixelsPerStud = 45
    gui.Parent = board

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = Color3.fromRGB(36, 24, 18)
    label.TextScaled = true
    label.TextWrapped = true
    label.Font = Enum.Font.GothamBold
    label.Parent = gui

    return post, board
end

local function makeTree(position, parent)
    makePart("Savings Tree Trunk", position + Vector3.new(0, 3, 0), Vector3.new(2, 6, 2), Color3.fromRGB(107, 72, 36), parent)
    local leaves = makePart("Savings Tree Coins", position + Vector3.new(0, 7.5, 0), Vector3.new(8, 7, 8), Color3.fromRGB(37, 176, 80), parent)
    leaves.Shape = Enum.PartType.Ball

    for i = 1, 4 do
        local coin = makePart("Tree Coin Decoration", position + Vector3.new(math.cos(i) * 3, 8 + i * 0.35, math.sin(i) * 3), Vector3.new(0.2, 1.1, 1.1), Color3.fromRGB(255, 215, 47), parent)
        coin.Shape = Enum.PartType.Cylinder
        coin.Orientation = Vector3.new(0, 0, 90)
        coin.CanCollide = false
    end
end

local function makeQuestionBlock(position, parent)
    local block = makePart("Question Block", position, Vector3.new(5, 5, 5), Color3.fromRGB(255, 176, 35), parent)
    block.Material = Enum.Material.Neon

    local gui = Instance.new("BillboardGui")
    gui.Size = UDim2.fromOffset(80, 80)
    gui.StudsOffset = Vector3.new(0, 0, 0)
    gui.AlwaysOnTop = true
    gui.Parent = block

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = "?"
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextScaled = true
    label.Font = Enum.Font.GothamBlack
    label.Parent = gui
end

local function makeCoin(position, parent)
    local coin = Instance.new("Part")
    coin.Name = "Coin"
    coin.Shape = Enum.PartType.Cylinder
    coin.Anchored = true
    coin.CanCollide = false
    coin.Position = position
    coin.Size = Vector3.new(0.25, 1.2, 1.2)
    coin.Orientation = Vector3.new(0, 0, 90)
    coin.Color = Color3.fromRGB(255, 203, 35)
    coin.Material = Enum.Material.Neon
    coin.Parent = parent
    CollectionService:AddTag(coin, "MoneyCoin")
    return coin
end

local function makeGate(index, questionId, x, parent)
    local barrier = makePart(
        "QuestionGateBarrier",
        Vector3.new(x + 5, 8, 0),
        Vector3.new(2, 16, 18),
        Color3.fromRGB(35, 178, 255),
        parent
    )
    barrier.Material = Enum.Material.ForceField
    barrier.Transparency = 0.25

    local trigger = makePart(
        "QuestionGateTrigger",
        Vector3.new(x, 5, 0),
        Vector3.new(5, 10, 18),
        Color3.fromRGB(255, 176, 35),
        parent
    )
    trigger.Transparency = 0.55
    trigger.CanCollide = false
    trigger:SetAttribute("QuestionId", questionId)
    trigger:SetAttribute("GateIndex", index)
    trigger:SetAttribute("BarrierName", barrier.Name .. tostring(index))
    trigger.Name = "QuestionGateTrigger" .. tostring(index)
    barrier.Name = barrier.Name .. tostring(index)
    CollectionService:AddTag(trigger, "QuestionGate")
end

local world = workspace:FindFirstChild("MoneyMuncherWorld")
if world then
    world:Destroy()
end

world = Instance.new("Folder")
world.Name = "MoneyMuncherWorld"
world.Parent = workspace

local spawn = Instance.new("SpawnLocation")
spawn.Name = "MoneyMuncherStart"
spawn.Anchored = true
spawn.Position = Vector3.new(-6, 3, 0)
spawn.Size = Vector3.new(8, 1, 8)
spawn.Color = Color3.fromRGB(72, 221, 130)
spawn.Neutral = true
spawn.Parent = world

makePart("TrailGround", Vector3.new(90, -1, 0), Vector3.new(210, 2, 22), Color3.fromRGB(44, 178, 72), world)
makePart("TrailDirt", Vector3.new(90, -4, 0), Vector3.new(210, 4, 22), Color3.fromRGB(138, 82, 36), world)
makePart("StartPlatform", Vector3.new(0, 1, 0), Vector3.new(18, 2, 22), Color3.fromRGB(64, 201, 112), world)
makeSign("Saving Forest\nGrab coins, save some!", Vector3.new(16, 8, -9), world)

for i = 1, 7 do
    makeTree(Vector3.new(14 + i * 5, 0, i % 2 == 0 and 8 or -8), world)
end

makePart("BudgetBridge", Vector3.new(58, 4, 0), Vector3.new(24, 2, 16), Color3.fromRGB(255, 199, 82), world)
makePart("Budget Shop", Vector3.new(58, 10, 8), Vector3.new(13, 9, 6), Color3.fromRGB(255, 118, 87), world)
makePart("Budget Shop Roof", Vector3.new(58, 16, 8), Vector3.new(16, 3, 8), Color3.fromRGB(255, 210, 69), world)
makeSign("Budget Bridge\nPlan before you spend", Vector3.new(58, 14, -9), world)

makePart("InvestmentHill", Vector3.new(118, 6, 0), Vector3.new(28, 2, 16), Color3.fromRGB(82, 160, 255), world)
makePart("Investment Mountain", Vector3.new(118, 13, 8), Vector3.new(24, 14, 8), Color3.fromRGB(96, 126, 218), world)
makePart("Investment Peak", Vector3.new(118, 22, 8), Vector3.new(13, 5, 6), Color3.fromRGB(235, 241, 255), world)
makeSign("Investment Mountain\nMoney can grow over time", Vector3.new(118, 18, -9), world)

makePart("Tax Tunnel", Vector3.new(153, 6, 0), Vector3.new(18, 12, 18), Color3.fromRGB(94, 61, 145), world)
makePart("Tax Tunnel Door", Vector3.new(153, 6, -9.5), Vector3.new(12, 10, 1), Color3.fromRGB(58, 32, 95), world)
makeSign("Tax Tunnel\nWatch for surprise fees", Vector3.new(153, 15, 9), world)

makePart("FinishPlatform", Vector3.new(180, 2, 0), Vector3.new(20, 2, 22), Color3.fromRGB(85, 220, 188), world)
makeSign("Finish Flag\nClaim your learning bonus", Vector3.new(184, 12, -9), world)

for i = 1, 52 do
    local x = 8 + i * 4
    local y = 4.5 + math.sin(i * 0.65) * 1.4
    makeCoin(Vector3.new(x, y, 0), world)
end

makeQuestionBlock(Vector3.new(35, 11, 0), world)
makeQuestionBlock(Vector3.new(85, 11, 0), world)
makeQuestionBlock(Vector3.new(137, 12, 0), world)

for i = 1, 5 do
    local hazard = makePart("Debt Puddle", Vector3.new(145 + i * 3, 1.15, i % 2 == 0 and 5 or -5), Vector3.new(5, 0.35, 4), Color3.fromRGB(210, 65, 112), world)
    hazard.Material = Enum.Material.Neon
    hazard:SetAttribute("Penalty", 10)
    CollectionService:AddTag(hazard, "DebtHazard")
end

makeGate(1, "saving-first", 38, world)
makeGate(2, "budget-plan", 88, world)
makeGate(3, "investing-growth", 140, world)

local finish = makePart("FinishFlag", Vector3.new(190, 8, 0), Vector3.new(2, 16, 2), Color3.fromRGB(255, 255, 255), world)
finish:SetAttribute("Finish", true)
CollectionService:AddTag(finish, "LearningTrailFinish")
local flag = makePart("FinishBanner", Vector3.new(196, 14, 0), Vector3.new(10, 5, 1), Color3.fromRGB(255, 64, 83), world)
flag.CanCollide = false
