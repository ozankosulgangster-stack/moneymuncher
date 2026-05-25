local BuildCatalog = {
    {
        id = "saving_tree",
        displayName = "Saving Tree",
        cost = 25,
        color = Color3.fromRGB(44, 176, 83),
        accentColor = Color3.fromRGB(255, 215, 47),
    },
    {
        id = "coin_statue",
        displayName = "Coin Statue",
        cost = 35,
        color = Color3.fromRGB(255, 205, 45),
        accentColor = Color3.fromRGB(255, 245, 165),
    },
    {
        id = "budget_stand",
        displayName = "Budget Stand",
        cost = 50,
        color = Color3.fromRGB(255, 123, 84),
        accentColor = Color3.fromRGB(255, 225, 95),
    },
    {
        id = "question_block",
        displayName = "Question Block",
        cost = 75,
        color = Color3.fromRGB(255, 176, 35),
        accentColor = Color3.fromRGB(255, 255, 255),
    },
    {
        id = "mini_bridge",
        displayName = "Mini Bridge",
        cost = 90,
        color = Color3.fromRGB(171, 103, 45),
        accentColor = Color3.fromRGB(255, 214, 106),
    },
}

function BuildCatalog.getById(itemId)
    for _, item in ipairs(BuildCatalog) do
        if type(item) == "table" and item.id == itemId then
            return item
        end
    end

    return nil
end

function BuildCatalog.publicList()
    local list = {}

    for _, item in ipairs(BuildCatalog) do
        if type(item) == "table" then
            table.insert(list, {
                id = item.id,
                displayName = item.displayName,
                cost = item.cost,
            })
        end
    end

    return list
end

return BuildCatalog
