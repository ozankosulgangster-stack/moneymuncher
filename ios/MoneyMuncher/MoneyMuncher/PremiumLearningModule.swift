import Foundation

struct PremiumLearningModule: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let concept: String
    let systemImage: String
    let dinoLine: String
    let steps: [PremiumLessonStep]
    let quiz: PremiumModuleQuiz
}

struct PremiumLessonStep: Identifiable, Hashable {
    let id: String
    let title: String
    let body: String
    let dinoTip: String
}

struct PremiumModuleQuiz: Hashable {
    let prompt: String
    let answers: [String]
    let correctAnswerIndex: Int
    let explanation: String
}

extension PremiumLearningModule {
    static let dinoModules: [PremiumLearningModule] = [
        PremiumLearningModule(
            id: "card-basics",
            title: "Card Captain",
            subtitle: "Credit cards, debit cards, and smart swipe habits.",
            concept: "Cards",
            systemImage: "creditcard.fill",
            dinoLine: "Cards look alike, but they do very different jobs.",
            steps: [
                PremiumLessonStep(
                    id: "debit",
                    title: "Debit uses your money now",
                    body: "A debit card pulls money from a bank account. If the account does not have enough money, the purchase may be declined or create a fee.",
                    dinoTip: "Dino check: debit is like opening your own wallet."
                ),
                PremiumLessonStep(
                    id: "credit",
                    title: "Credit borrows first",
                    body: "A credit card lets you buy now and pay the card company later. The card company sends a bill called a statement.",
                    dinoTip: "Dino check: credit is borrowed money, not extra money."
                ),
                PremiumLessonStep(
                    id: "statement",
                    title: "The full bill matters",
                    body: "Paying the full statement balance on time usually avoids interest on purchases. Paying only a small amount can make the purchase cost more.",
                    dinoTip: "Dino habit: treat the due date like a boss level."
                ),
                PremiumLessonStep(
                    id: "safe-use",
                    title: "Safe card habits",
                    body: "Track what you spend, protect card numbers, and ask a grown-up before saving card details in an app or website.",
                    dinoTip: "Dino rule: if a screen asks for card details, pause first."
                )
            ],
            quiz: PremiumModuleQuiz(
                prompt: "Dino buys a $20 book with a debit card. What happens?",
                answers: [
                    "The money leaves the bank account now.",
                    "Dino gets a bill next month.",
                    "The card company pays Dino interest."
                ],
                correctAnswerIndex: 0,
                explanation: "Debit spending uses money already in the account."
            )
        ),
        PremiumLearningModule(
            id: "interest-lab",
            title: "Interest Lab",
            subtitle: "How borrowing costs and saving rewards can grow.",
            concept: "Interest",
            systemImage: "percent",
            dinoLine: "Interest can help savings grow, but it can also make debt heavier.",
            steps: [
                PremiumLessonStep(
                    id: "price",
                    title: "Interest is a price or reward",
                    body: "When you borrow, interest is the price of using someone else's money. When you save, interest can be a reward for leaving money in the account.",
                    dinoTip: "Dino check: same word, two directions."
                ),
                PremiumLessonStep(
                    id: "apr",
                    title: "APR is a yearly rate",
                    body: "APR stands for annual percentage rate. It helps compare borrowing costs across loans or cards.",
                    dinoTip: "Dino shortcut: higher APR usually means borrowing gets expensive faster."
                ),
                PremiumLessonStep(
                    id: "minimum",
                    title: "Minimum payments can stretch debt",
                    body: "A minimum payment keeps an account current, but it may leave most of the balance unpaid. More unpaid balance can mean more interest.",
                    dinoTip: "Dino move: paying more than the minimum can shrink the debt faster."
                ),
                PremiumLessonStep(
                    id: "compound",
                    title: "Compounding adds layers",
                    body: "Compounding means interest can be calculated on earlier interest. That can help savings, but it can also grow debt if the balance stays unpaid.",
                    dinoTip: "Dino visual: small layers can become a big stack."
                )
            ],
            quiz: PremiumModuleQuiz(
                prompt: "Why can paying only the minimum on a credit card cost more over time?",
                answers: [
                    "Because unpaid balance can keep adding interest.",
                    "Because debit cards charge monthly interest.",
                    "Because APR means the card is free."
                ],
                correctAnswerIndex: 0,
                explanation: "The remaining balance can continue to build interest until it is paid."
            )
        ),
        PremiumLearningModule(
            id: "stock-starter",
            title: "Stock Slice Studio",
            subtitle: "Stocks, trades, risk, and why prices move.",
            concept: "Investing",
            systemImage: "chart.line.uptrend.xyaxis",
            dinoLine: "A stock is a tiny slice of a business, not a magic coin machine.",
            steps: [
                PremiumLessonStep(
                    id: "ownership",
                    title: "Stocks are ownership slices",
                    body: "Buying a stock means owning a small piece of a company. If the company does well, the stock may rise. If it struggles, the stock may fall.",
                    dinoTip: "Dino check: a share is a slice."
                ),
                PremiumLessonStep(
                    id: "trade",
                    title: "A trade is a buy or sell",
                    body: "Trading means buying or selling investments through an account. Prices change because buyers and sellers disagree about what something is worth.",
                    dinoTip: "Dino reminder: fast trading is risky and not a game."
                ),
                PremiumLessonStep(
                    id: "risk",
                    title: "Risk is always part of investing",
                    body: "Investments can lose value. Owning different kinds of investments can reduce the damage if one company has a bad day.",
                    dinoTip: "Dino habit: do not put every snack in one backpack."
                ),
                PremiumLessonStep(
                    id: "grown-up",
                    title: "Practice before real money",
                    body: "Money Muncher uses virtual examples for learning. Real investing needs a grown-up, a plan, and an understanding that losses can happen.",
                    dinoTip: "Dino rule: learn first, trade later."
                )
            ],
            quiz: PremiumModuleQuiz(
                prompt: "Why might an investor own different stocks instead of only one?",
                answers: [
                    "To reduce the impact if one company drops.",
                    "To guarantee every stock goes up.",
                    "To avoid ever needing a plan."
                ],
                correctAnswerIndex: 0,
                explanation: "Different investments can spread risk, but they do not remove risk completely."
            )
        )
    ]
}
