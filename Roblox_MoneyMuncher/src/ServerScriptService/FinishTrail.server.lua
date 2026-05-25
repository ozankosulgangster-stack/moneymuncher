local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = ReplicatedStorage:FindFirstChild("MoneyMuncherRemotes")
if not remotes then
    remotes = Instance.new("Folder")
    remotes.Name = "MoneyMuncherRemotes"
    remotes.Parent = ReplicatedStorage
end

local trailComplete = remotes:FindFirstChild("TrailComplete")
if not trailComplete then
    trailComplete = Instance.new("RemoteEvent")
    trailComplete.Name = "TrailComplete"
    trailComplete.Parent = remotes
end

local function connectFinish(finish)
    if finish:GetAttribute("Connected") then
        return
    end

    finish:SetAttribute("Connected", true)

    finish.Touched:Connect(function(hit)
        local player = Players:GetPlayerFromCharacter(hit.Parent)
        if not player then
            return
        end

        local data = player:FindFirstChild("MoneyMuncherData")
        if not data or data.CompletedLearningTrail.Value then
            return
        end

        data.CompletedLearningTrail.Value = true
        data.Coins.Value += 100
        trailComplete:FireClient(player, {
            reward = 100,
            message = "Learning Trail complete! You earned a 100 coin bonus.",
        })
    end)
end

for _, finish in ipairs(CollectionService:GetTagged("LearningTrailFinish")) do
    connectFinish(finish)
end

CollectionService:GetInstanceAddedSignal("LearningTrailFinish"):Connect(connectFinish)
