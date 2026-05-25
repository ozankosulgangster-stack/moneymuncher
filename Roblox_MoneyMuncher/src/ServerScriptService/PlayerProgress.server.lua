local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local progressStore = DataStoreService:GetDataStore("MoneyMuncherProgressV1")

local remotes = ReplicatedStorage:FindFirstChild("MoneyMuncherRemotes")
if not remotes then
    remotes = Instance.new("Folder")
    remotes.Name = "MoneyMuncherRemotes"
    remotes.Parent = ReplicatedStorage
end

local progressChanged = remotes:FindFirstChild("ProgressChanged")
if not progressChanged then
    progressChanged = Instance.new("RemoteEvent")
    progressChanged.Name = "ProgressChanged"
    progressChanged.Parent = remotes
end

local function defaultData()
    return {
        coins = 0,
        debt = 0,
        completedGates = {},
        completedLearningTrail = false,
    }
end

local function loadData(player)
    local success, data = pcall(function()
        return progressStore:GetAsync(tostring(player.UserId))
    end)

    if success and type(data) == "table" then
        return data
    end

    return defaultData()
end

local function saveData(player)
    local dataFolder = player:FindFirstChild("MoneyMuncherData")
    if not dataFolder then
        return
    end

    local data = {
        coins = dataFolder.Coins.Value,
        debt = dataFolder.Debt.Value,
        completedGates = {},
        completedLearningTrail = dataFolder.CompletedLearningTrail.Value,
    }

    local completedGates = dataFolder:FindFirstChild("CompletedGates")
    if completedGates then
        for _, gate in ipairs(completedGates:GetChildren()) do
            data.completedGates[gate.Name] = gate.Value
        end
    end

    pcall(function()
        progressStore:SetAsync(tostring(player.UserId), data)
    end)
end

local function sendProgress(player)
    local dataFolder = player:FindFirstChild("MoneyMuncherData")
    if not dataFolder then
        return
    end

    progressChanged:FireClient(player, {
        coins = dataFolder.Coins.Value,
        debt = dataFolder.Debt.Value,
        completedLearningTrail = dataFolder.CompletedLearningTrail.Value,
    })
end

Players.PlayerAdded:Connect(function(player)
    local data = loadData(player)

    local folder = Instance.new("Folder")
    folder.Name = "MoneyMuncherData"
    folder.Parent = player

    local coins = Instance.new("IntValue")
    coins.Name = "Coins"
    coins.Value = data.coins or 0
    coins.Parent = folder

    local debt = Instance.new("IntValue")
    debt.Name = "Debt"
    debt.Value = data.debt or 0
    debt.Parent = folder

    local completedLearningTrail = Instance.new("BoolValue")
    completedLearningTrail.Name = "CompletedLearningTrail"
    completedLearningTrail.Value = data.completedLearningTrail == true
    completedLearningTrail.Parent = folder

    local completedGates = Instance.new("Folder")
    completedGates.Name = "CompletedGates"
    completedGates.Parent = folder

    if type(data.completedGates) == "table" then
        for gateId, completed in pairs(data.completedGates) do
            local value = Instance.new("BoolValue")
            value.Name = gateId
            value.Value = completed == true
            value.Parent = completedGates
        end
    end

    coins.Changed:Connect(function()
        sendProgress(player)
    end)

    debt.Changed:Connect(function()
        sendProgress(player)
    end)

    task.defer(sendProgress, player)
end)

Players.PlayerRemoving:Connect(saveData)

game:BindToClose(function()
    for _, player in ipairs(Players:GetPlayers()) do
        saveData(player)
    end
end)
