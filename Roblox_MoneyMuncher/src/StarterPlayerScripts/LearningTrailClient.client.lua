local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("MoneyMuncherRemotes")
local showQuestion = remotes:WaitForChild("ShowQuestion")
local answerQuestion = remotes:WaitForChild("AnswerQuestion")
local answerResult = remotes:WaitForChild("AnswerResult")
local progressChanged = remotes:WaitForChild("ProgressChanged")
local trailComplete = remotes:WaitForChild("TrailComplete")

local playerGui = player:WaitForChild("PlayerGui")

local gui = Instance.new("ScreenGui")
gui.Name = "MoneyMuncherLearningUI"
gui.ResetOnSpawn = false
gui.Parent = playerGui

local scoreLabel = Instance.new("TextLabel")
scoreLabel.Name = "ScoreLabel"
scoreLabel.AnchorPoint = Vector2.new(0, 0)
scoreLabel.Position = UDim2.fromOffset(18, 18)
scoreLabel.Size = UDim2.fromOffset(330, 42)
scoreLabel.BackgroundTransparency = 0.25
scoreLabel.BackgroundColor3 = Color3.fromRGB(15, 22, 35)
scoreLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
scoreLabel.Font = Enum.Font.GothamBold
scoreLabel.TextSize = 20
scoreLabel.TextXAlignment = Enum.TextXAlignment.Left
scoreLabel.Text = "Coins: 0  Debt: 0"
scoreLabel.Parent = gui

local panel = Instance.new("Frame")
panel.Name = "QuestionPanel"
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(620, 330)
panel.BackgroundColor3 = Color3.fromRGB(15, 22, 35)
panel.BackgroundTransparency = 0.05
panel.Visible = false
panel.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 10)
corner.Parent = panel

local questionLabel = Instance.new("TextLabel")
questionLabel.Name = "QuestionLabel"
questionLabel.Position = UDim2.fromOffset(28, 24)
questionLabel.Size = UDim2.fromOffset(564, 86)
questionLabel.BackgroundTransparency = 1
questionLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
questionLabel.Font = Enum.Font.GothamBold
questionLabel.TextSize = 24
questionLabel.TextWrapped = true
questionLabel.Parent = panel

local feedbackLabel = Instance.new("TextLabel")
feedbackLabel.Name = "FeedbackLabel"
feedbackLabel.Position = UDim2.fromOffset(28, 258)
feedbackLabel.Size = UDim2.fromOffset(564, 48)
feedbackLabel.BackgroundTransparency = 1
feedbackLabel.TextColor3 = Color3.fromRGB(255, 231, 137)
feedbackLabel.Font = Enum.Font.Gotham
feedbackLabel.TextSize = 18
feedbackLabel.TextWrapped = true
feedbackLabel.Parent = panel

local answerButtons = {}
local activeQuestionId = nil

local function makeButton(index)
    local button = Instance.new("TextButton")
    button.Name = "Answer" .. tostring(index)
    button.Position = UDim2.fromOffset(50, 110 + (index - 1) * 48)
    button.Size = UDim2.fromOffset(520, 38)
    button.BackgroundColor3 = Color3.fromRGB(255, 196, 61)
    button.TextColor3 = Color3.fromRGB(15, 22, 35)
    button.Font = Enum.Font.GothamBold
    button.TextSize = 18
    button.Parent = panel

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = UDim.new(0, 8)
    buttonCorner.Parent = button

    button.Activated:Connect(function()
        if activeQuestionId then
            answerQuestion:FireServer(activeQuestionId, index)
        end
    end)

    answerButtons[index] = button
end

for index = 1, 3 do
    makeButton(index)
end

showQuestion.OnClientEvent:Connect(function(question)
    activeQuestionId = question.id
    questionLabel.Text = question.prompt
    feedbackLabel.Text = ""

    for index, button in ipairs(answerButtons) do
        button.Text = question.answers[index] or ""
        button.Visible = question.answers[index] ~= nil
        button.Active = true
        button.AutoButtonColor = true
    end

    panel.Visible = true
end)

answerResult.OnClientEvent:Connect(function(result)
    if result.correct then
        feedbackLabel.Text = "Correct! " .. result.explanation

        for _, button in ipairs(answerButtons) do
            button.Active = false
            button.AutoButtonColor = false
        end

        task.delay(1.2, function()
            panel.Visible = false
            activeQuestionId = nil
        end)
    else
        feedbackLabel.Text = "Try again. " .. result.explanation
    end
end)

progressChanged.OnClientEvent:Connect(function(progress)
    scoreLabel.Text = string.format("Coins: %d  Debt: %d", progress.coins or 0, progress.debt or 0)
end)

trailComplete.OnClientEvent:Connect(function(result)
    activeQuestionId = nil
    questionLabel.Text = "You finished the Money Learning Trail!"
    feedbackLabel.Text = result.message or "Great job learning about money."

    for _, button in ipairs(answerButtons) do
        button.Visible = false
    end

    panel.Visible = true

    task.delay(3, function()
        panel.Visible = false
    end)
end)
