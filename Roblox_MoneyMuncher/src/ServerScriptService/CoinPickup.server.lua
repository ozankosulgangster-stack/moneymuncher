local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local COIN_VALUE = 5

local function connectCoin(coin)
    if coin:GetAttribute("Connected") then
        return
    end

    coin:SetAttribute("Connected", true)

    coin.Touched:Connect(function(hit)
        local character = hit.Parent
        local player = Players:GetPlayerFromCharacter(character)
        if not player then
            return
        end

        local data = player:FindFirstChild("MoneyMuncherData")
        if not data then
            return
        end

        data.Coins.Value += COIN_VALUE
        coin:Destroy()
    end)
end

for _, coin in ipairs(CollectionService:GetTagged("MoneyCoin")) do
    connectCoin(coin)
end

CollectionService:GetInstanceAddedSignal("MoneyCoin"):Connect(connectCoin)
