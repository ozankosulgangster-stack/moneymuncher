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

makePart("TrailGround", Vector3.new(90, -1, 0), Vector3.new(210, 2, 22), Color3.fromRGB(44, 178, 72), world)
makePart("TrailDirt", Vector3.new(90, -4, 0), Vector3.new(210, 4, 22), Color3.fromRGB(138, 82, 36), world)
makePart("StartPlatform", Vector3.new(0, 1, 0), Vector3.new(18, 2, 22), Color3.fromRGB(64, 201, 112), world)
makePart("BudgetBridge", Vector3.new(58, 4, 0), Vector3.new(24, 2, 16), Color3.fromRGB(255, 199, 82), world)
makePart("InvestmentHill", Vector3.new(118, 6, 0), Vector3.new(28, 2, 16), Color3.fromRGB(82, 160, 255), world)
makePart("FinishPlatform", Vector3.new(180, 2, 0), Vector3.new(20, 2, 22), Color3.fromRGB(85, 220, 188), world)

for i = 1, 40 do
    local x = 8 + i * 4
    local y = 4 + math.sin(i * 0.65) * 2
    makeCoin(Vector3.new(x, y, 0), world)
end

makeGate(1, "saving-first", 38, world)
makeGate(2, "budget-plan", 88, world)
makeGate(3, "investing-growth", 140, world)

local finish = makePart("FinishFlag", Vector3.new(190, 8, 0), Vector3.new(2, 16, 2), Color3.fromRGB(255, 255, 255), world)
finish:SetAttribute("Finish", true)
CollectionService:AddTag(finish, "LearningTrailFinish")
local flag = makePart("FinishBanner", Vector3.new(196, 14, 0), Vector3.new(10, 5, 1), Color3.fromRGB(255, 64, 83), world)
flag.CanCollide = false
