local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MoneyQuestions = require(ReplicatedStorage:WaitForChild("MoneyQuestions"))

local remotes = ReplicatedStorage:FindFirstChild("MoneyMuncherRemotes")
if not remotes then
    remotes = Instance.new("Folder")
    remotes.Name = "MoneyMuncherRemotes"
    remotes.Parent = ReplicatedStorage
end

local showQuestion = remotes:FindFirstChild("ShowQuestion")
if not showQuestion then
    showQuestion = Instance.new("RemoteEvent")
    showQuestion.Name = "ShowQuestion"
    showQuestion.Parent = remotes
end

local answerQuestion = remotes:FindFirstChild("AnswerQuestion")
if not answerQuestion then
    answerQuestion = Instance.new("RemoteEvent")
    answerQuestion.Name = "AnswerQuestion"
    answerQuestion.Parent = remotes
end

local answerResult = remotes:FindFirstChild("AnswerResult")
if not answerResult then
    answerResult = Instance.new("RemoteEvent")
    answerResult.Name = "AnswerResult"
    answerResult.Parent = remotes
end

local activeGateByPlayer = {}

local function findBarrier(gate)
    local barrierName = gate:GetAttribute("BarrierName")
    if not barrierName then
        return nil
    end

    local world = workspace:FindFirstChild("MoneyMuncherWorld")
    return world and world:FindFirstChild(barrierName)
end

local function markGateComplete(player, questionId)
    local data = player:FindFirstChild("MoneyMuncherData")
    if not data then
        return
    end

    local completedGates = data:FindFirstChild("CompletedGates")
    if not completedGates then
        return
    end

    local gateValue = completedGates:FindFirstChild(questionId)
    if not gateValue then
        gateValue = Instance.new("BoolValue")
        gateValue.Name = questionId
        gateValue.Parent = completedGates
    end

    gateValue.Value = true
end

local function connectGate(gate)
    if gate:GetAttribute("Connected") then
        return
    end

    gate:SetAttribute("Connected", true)

    gate.Touched:Connect(function(hit)
        local player = Players:GetPlayerFromCharacter(hit.Parent)
        if not player then
            return
        end

        local questionId = gate:GetAttribute("QuestionId")
        local question = MoneyQuestions.getById(questionId)
        if not question then
            return
        end

        activeGateByPlayer[player] = gate
        showQuestion:FireClient(player, {
            id = question.id,
            prompt = question.prompt,
            answers = question.answers,
        })
    end)
end

answerQuestion.OnServerEvent:Connect(function(player, questionId, answerIndex)
    local gate = activeGateByPlayer[player]
    if not gate or gate:GetAttribute("QuestionId") ~= questionId then
        return
    end

    local question = MoneyQuestions.getById(questionId)
    local data = player:FindFirstChild("MoneyMuncherData")
    if not question or not data then
        return
    end

    local correct = answerIndex == question.correctIndex
    if correct then
        data.Coins.Value += question.reward
        markGateComplete(player, questionId)

        local barrier = findBarrier(gate)
        if barrier then
            barrier:Destroy()
        end

        gate:Destroy()
        activeGateByPlayer[player] = nil
    else
        data.Debt.Value += question.penalty
    end

    answerResult:FireClient(player, {
        correct = correct,
        explanation = question.explanation,
    })
end)

for _, gate in ipairs(CollectionService:GetTagged("QuestionGate")) do
    connectGate(gate)
end

CollectionService:GetInstanceAddedSignal("QuestionGate"):Connect(connectGate)
