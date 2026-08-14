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
            title: "Captain Jack's Card Cabin",
            subtitle: "A Shark story about debit, credit, and loyalty points.",
            concept: "Cards",
            systemImage: "creditcard.fill",
            dinoLine: "Captain Jack says: cards can be useful tools when you know whose money is being spent.",
            steps: [
                PremiumLessonStep(
                    id: "debit",
                    title: "Kai's debit voyage",
                    body: "Kai has $12 in a bank account before visiting the harbor snack stand. A $4 smoothie is enough, so Kai taps a debit card and the money leaves the account right away. A $15 souvenir has to wait because debit uses money Kai already has.",
                    dinoTip: "Dino check: debit is like opening your own wallet. Check the balance first."
                ),
                PremiumLessonStep(
                    id: "credit",
                    title: "Credit starts a promise",
                    body: "Captain Jack uses a credit card for a $20 ship compass. The card company pays the shop first, then sends Jack a statement, which is a bill to pay later. The compass is not free: credit is borrowed money that needs a plan for repayment.",
                    dinoTip: "Dino check: credit is borrowed money, not extra money."
                ),
                PremiumLessonStep(
                    id: "statement",
                    title: "Finish the whole map",
                    body: "Jack's statement says $20 is due. When he pays the full statement balance on time, he finishes that purchase before it becomes more expensive. Paying only a small amount can leave money unpaid and may add interest later.",
                    dinoTip: "Dino habit: treat the due date like a boss level."
                ),
                PremiumLessonStep(
                    id: "safe-use",
                    title: "Safe cards and loyalty points",
                    body: "At the market, a loyalty card offers Kai a few points after a purchase. The points can be a small bonus, but Kai still checks the price and asks a grown-up before sharing a name, email, or card details. A reward is not a reason to buy something unplanned.",
                    dinoTip: "Dino rule: if a screen asks for card details or personal information, pause first."
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
            title: "Mira's Interest Garden",
            subtitle: "A Turtle story about saving, borrowing, and time.",
            concept: "Interest",
            systemImage: "percent",
            dinoLine: "Mira says: interest can help savings grow or make borrowing cost more.",
            steps: [
                PremiumLessonStep(
                    id: "price",
                    title: "Mira's two garden jars",
                    body: "Mira puts $10 in a savings jar at the bank. Over time, the bank may add a little extra money called interest. A second jar represents borrowed money: when money is borrowed, interest can be an extra cost paid back later.",
                    dinoTip: "Dino check: same word, two directions. Savings may earn; borrowing may cost."
                ),
                PremiumLessonStep(
                    id: "apr",
                    title: "The APR garden sign",
                    body: "Mira sees two borrowing offers on a garden sign. APR means annual percentage rate, or a yearly way to compare borrowing costs. A higher APR usually means the borrowed jar can grow more expensive faster, even when the first payment looks small.",
                    dinoTip: "Dino shortcut: higher APR usually means borrowing gets expensive faster."
                ),
                PremiumLessonStep(
                    id: "minimum",
                    title: "The tiny watering can",
                    body: "A minimum payment can keep an account current, but it may be like using a tiny watering can on a much bigger garden bed. Most of the balance can remain, and interest may keep being added. Paying more than the minimum can help the balance shrink faster.",
                    dinoTip: "Dino move: paying more than the minimum can shrink the debt faster."
                ),
                PremiumLessonStep(
                    id: "compound",
                    title: "Little layers become a stack",
                    body: "Mira watches a small leaf sprout in the savings jar. Compounding means interest can be calculated on earlier interest, so savings can build layer by layer. The same idea can make debt grow if a balance stays unpaid, which is why a plan matters.",
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
            title: "Sammy's Stock Slice Studio",
            subtitle: "A Unicorn story about ownership, patience, and risk.",
            concept: "Investing",
            systemImage: "chart.line.uptrend.xyaxis",
            dinoLine: "Sammy says: a stock is a tiny slice of a business, not a magic coin machine.",
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
