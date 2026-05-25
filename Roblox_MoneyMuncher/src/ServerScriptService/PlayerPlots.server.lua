local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local BuildCatalog = require(ReplicatedStorage:WaitForChild("BuildCatalog"))

local plotStore = DataStoreService:GetDataStore("MoneyMuncherPlotsV1")
local MAX_ITEMS_PER_PLOT = 30
local PLOT_SIZE = Vector3.new(54, 1, 42)
local PLOT_START = Vector3.new(25, 0.35, 74)
local PLOT_SPACING = 62

local remotes = ReplicatedStorage:FindFirstChild("MoneyMuncherRemotes")
if not remotes then
    remotes = Instance.new("Folder")
    remotes.Name = "MoneyMuncherRemotes"
    remotes.Parent = ReplicatedStorage
end

local placeBuildItem = remotes:FindFirstChild("PlaceBuildItem")
if not placeBuildItem then
    placeBuildItem = Instance.new("RemoteEvent")
    placeBuildItem.Name = "PlaceBuildItem"
    placeBuildItem.Parent = remotes
end

local buildResult = remotes:FindFirstChild("BuildResult")
if not buildResult then
    buildResult = Instance.new("RemoteEvent")
    buildResult.Name = "BuildResult"
    buildResult.Parent = remotes
end

local plotsFolder = workspace:FindFirstChild("MoneyMuncherPlayerPlots")
if plotsFolder then
    plotsFolder:Destroy()
end

plotsFolder = Instance.new("Folder")
plotsFolder.Name = "MoneyMuncherPlayerPlots"
plotsFolder.Parent = workspace

local plotByPlayer = {}
local nextPlotIndex = 0

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

local function makePlotSign(player, position, parent)
    local board = makePart(player.DisplayName .. "'s Money Park", position, Vector3.new(24, 6, 1), Color3.fromRGB(255, 225, 120), parent)

    local gui = Instance.new("SurfaceGui")
    gui.Face = Enum.NormalId.Front
    gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
    gui.PixelsPerStud = 45
    gui.Parent = board

    local label = Instance.new("TextLabel")
    label.Size = UDim2.fromScale(1, 1)
    label.BackgroundTransparency = 1
    label.Text = player.DisplayName .. "'s\nMoney Park"
    label.TextColor3 = Color3.fromRGB(32, 24, 18)
    label.TextScaled = true
    label.TextWrapped = true
    label.Font = Enum.Font.GothamBold
    label.Parent = gui
end

local function makeModelRoot(name, ownerFolder)
    local model = Instance.new("Model")
    model.Name = name
    model.Parent = ownerFolder
    return model
end

local function createBuildObject(item, position, parent)
    local model = makeModelRoot(item.displayName, parent)

    if item.id == "saving_tree" then
        makePart("Trunk", position + Vector3.new(0, 3, 0), Vector3.new(2, 6, 2), Color3.fromRGB(112, 74, 37), model)
        local leaves = makePart("Coin Leaves", position + Vector3.new(0, 8, 0), Vector3.new(8, 7, 8), item.color, model)
        leaves.Shape = Enum.PartType.Ball
        makePart("Saved Coin", position + Vector3.new(2.4, 9, -1.5), Vector3.new(0.25, 1.4, 1.4), item.accentColor, model).Shape = Enum.PartType.Cylinder
    elseif item.id == "coin_statue" then
        local coin = makePart("Big Coin", position + Vector3.new(0, 4, 0), Vector3.new(0.9, 7, 7), item.color, model)
        coin.Shape = Enum.PartType.Cylinder
        coin.Orientation = Vector3.new(0, 0, 90)
        coin.Material = Enum.Material.Neon
        makePart("Coin Base", position + Vector3.new(0, 0.8, 0), Vector3.new(8, 1.6, 8), Color3.fromRGB(70, 85, 110), model)
    elseif item.id == "budget_stand" then
        makePart("Stand Base", position + Vector3.new(0, 2, 0), Vector3.new(10, 4, 7), item.color, model)
        makePart("Stand Roof", position + Vector3.new(0, 5, 0), Vector3.new(12, 2, 9), item.accentColor, model)
        makePart("Counter", position + Vector3.new(0, 2.7, -4.2), Vector3.new(10, 1.2, 1), Color3.fromRGB(255, 239, 176), model)
    elseif item.id == "question_block" then
        local block = makePart("Question Block", position + Vector3.new(0, 4, 0), Vector3.new(6, 6, 6), item.color, model)
        block.Material = Enum.Material.Neon

        local gui = Instance.new("BillboardGui")
        gui.Size = UDim2.fromOffset(90, 90)
        gui.AlwaysOnTop = true
        gui.Parent = block

        local label = Instance.new("TextLabel")
        label.Size = UDim2.fromScale(1, 1)
        label.BackgroundTransparency = 1
        label.Text = "?"
        label.TextColor3 = item.accentColor
        label.TextScaled = true
        label.Font = Enum.Font.GothamBlack
        label.Parent = gui
    elseif item.id == "mini_bridge" then
        makePart("Bridge Deck", position + Vector3.new(0, 2, 0), Vector3.new(16, 2, 7), item.color, model)
        makePart("Left Rail", position + Vector3.new(0, 4, -4), Vector3.new(16, 1.4, 1), item.accentColor, model)
        makePart("Right Rail", position + Vector3.new(0, 4, 4), Vector3.new(16, 1.4, 1), item.accentColor, model)
    end

    return model
end

local function getSlotPosition(plotInfo, slotIndex)
    local columns = 5
    local spacingX = 10
    local spacingZ = 8
    local column = (slotIndex - 1) % columns
    local row = math.floor((slotIndex - 1) / columns)
    local offsetX = -20 + column * spacingX
    local offsetZ = -13 + row * spacingZ
    return plotInfo.origin + Vector3.new(offsetX, 0.75, offsetZ)
end

local function loadPlotItems(player)
    local success, data = pcall(function()
        return plotStore:GetAsync(tostring(player.UserId))
    end)

    if success and type(data) == "table" and type(data.items) == "table" then
        return data.items
    end

    return {}
end

local function savePlot(player)
    local plotInfo = plotByPlayer[player]
    if not plotInfo then
        return
    end

    pcall(function()
        plotStore:SetAsync(tostring(player.UserId), {
            items = plotInfo.items,
        })
    end)
end

local function createPlot(player)
    nextPlotIndex += 1
    local origin = PLOT_START + Vector3.new((nextPlotIndex - 1) * PLOT_SPACING, 0, 0)
    local folder = Instance.new("Folder")
    folder.Name = tostring(player.UserId)
    folder.Parent = plotsFolder

    local base = makePart("Personal Money Park Plot", origin, PLOT_SIZE, Color3.fromRGB(75, 196, 120), folder)
    base:SetAttribute("OwnerUserId", player.UserId)
    makePlotSign(player, origin + Vector3.new(0, 8, -PLOT_SIZE.Z / 2 - 2), folder)

    local itemsFolder = Instance.new("Folder")
    itemsFolder.Name = "BuiltItems"
    itemsFolder.Parent = folder

    local plotInfo = {
        origin = origin,
        folder = folder,
        itemsFolder = itemsFolder,
        items = loadPlotItems(player),
    }

    plotByPlayer[player] = plotInfo

    for index, savedItem in ipairs(plotInfo.items) do
        local item = BuildCatalog.getById(savedItem.id)
        if item then
            createBuildObject(item, getSlotPosition(plotInfo, index), itemsFolder)
        end
    end
end

local function placeItem(player, itemId)
    local plotInfo = plotByPlayer[player]
    local data = player:FindFirstChild("MoneyMuncherData")
    local item = BuildCatalog.getById(itemId)

    if not plotInfo or not data or not item then
        return
    end

    if #plotInfo.items >= MAX_ITEMS_PER_PLOT then
        buildResult:FireClient(player, false, "Your Money Park is full.")
        return
    end

    if data.Coins.Value < item.cost then
        buildResult:FireClient(player, false, "Collect more coins to build that.")
        return
    end

    data.Coins.Value -= item.cost
    table.insert(plotInfo.items, { id = item.id })
    createBuildObject(item, getSlotPosition(plotInfo, #plotInfo.items), plotInfo.itemsFolder)
    savePlot(player)
    buildResult:FireClient(player, true, "Built " .. item.displayName .. "!")
end

placeBuildItem.OnServerEvent:Connect(placeItem)

Players.PlayerAdded:Connect(createPlot)

Players.PlayerRemoving:Connect(function(player)
    savePlot(player)

    local plotInfo = plotByPlayer[player]
    if plotInfo and plotInfo.folder then
        plotInfo.folder:Destroy()
    end

    plotByPlayer[player] = nil
end)

game:BindToClose(function()
    for _, player in ipairs(Players:GetPlayers()) do
        savePlot(player)
    end
end)
