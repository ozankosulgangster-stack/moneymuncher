local MoneyQuestions = {
    {
        id = "saving-first",
        prompt = "You found 10 coins. What is the smartest first move?",
        answers = {
            "Save some of it",
            "Spend it all fast",
            "Throw it away",
        },
        correctIndex = 1,
        explanation = "Saving some coins helps you prepare for bigger goals.",
        reward = 25,
        penalty = 10,
    },
    {
        id = "budget-plan",
        prompt = "What is a budget?",
        answers = {
            "A plan for money",
            "A magic coin box",
            "A way to spend without thinking",
        },
        correctIndex = 1,
        explanation = "A budget is a plan for what you earn, save, and spend.",
        reward = 35,
        penalty = 10,
    },
    {
        id = "investing-growth",
        prompt = "What does investing mean?",
        answers = {
            "Putting money to work over time",
            "Buying every toy today",
            "Losing coins on purpose",
        },
        correctIndex = 1,
        explanation = "Investing means using money to try to grow more money later.",
        reward = 50,
        penalty = 15,
    },
}

function MoneyQuestions.getById(id)
    for _, question in ipairs(MoneyQuestions) do
        if type(question) == "table" and question.id == id then
            return question
        end
    end

    return nil
end

return MoneyQuestions
