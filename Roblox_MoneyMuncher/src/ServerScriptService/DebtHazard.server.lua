local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local cooldownByPlayer = {}

local function connectHazard(hazard)
    if hazard:GetAttribute("Connected") then
        return
    end

    hazard:SetAttribute("Connected", true)

    hazard.Touched:Connect(function(hit)
        local player = Players:GetPlayerFromCharacter(hit.Parent)
        if not player then
            return
        end

        local now = os.clock()
        if cooldownByPlayer[player] and now - cooldownByPlayer[player] < 1.5 then
            return
        end

        local data = player:FindFirstChild("MoneyMuncherData")
        if not data then
            return
        end

        cooldownByPlayer[player] = now
        data.Debt.Value += hazard:GetAttribute("Penalty") or 10
    end)
end

for _, hazard in ipairs(CollectionService:GetTagged("DebtHazard")) do
    connectHazard(hazard)
end

CollectionService:GetInstanceAddedSignal("DebtHazard"):Connect(connectHazard)
