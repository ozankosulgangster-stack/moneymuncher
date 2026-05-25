local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local COIN_VALUE = 5
local COLLECT_RADIUS = 5
local SPIN_SPEED = 90

local coins = {}

local function collectCoin(player, coin)
    if coin:GetAttribute("Collected") then
        return
    end

    local data = player:FindFirstChild("MoneyMuncherData")
    if not data then
        return
    end

    coin:SetAttribute("Collected", true)
    data.Coins.Value += COIN_VALUE
    coins[coin] = nil
    coin:Destroy()
end

local function connectCoin(coin)
    if coin:GetAttribute("Connected") then
        return
    end

    coin:SetAttribute("Connected", true)
    coins[coin] = true

    coin.Touched:Connect(function(hit)
        local character = hit.Parent
        local player = Players:GetPlayerFromCharacter(character)
        if not player then
            return
        end

        collectCoin(player, coin)
    end)

    coin.Destroying:Connect(function()
        coins[coin] = nil
    end)
end

for _, coin in ipairs(CollectionService:GetTagged("MoneyCoin")) do
    connectCoin(coin)
end

CollectionService:GetInstanceAddedSignal("MoneyCoin"):Connect(connectCoin)

RunService.Heartbeat:Connect(function(deltaTime)
    local players = Players:GetPlayers()

    for coin in pairs(coins) do
        if not coin.Parent then
            coins[coin] = nil
            continue
        end

        coin.CFrame *= CFrame.Angles(0, math.rad(SPIN_SPEED * deltaTime), 0)

        for _, player in ipairs(players) do
            local character = player.Character
            local root = character and character:FindFirstChild("HumanoidRootPart")
            local data = player:FindFirstChild("MoneyMuncherData")

            if root and data and (root.Position - coin.Position).Magnitude <= COLLECT_RADIUS then
                collectCoin(player, coin)
                break
            end
        end
    end
end)
