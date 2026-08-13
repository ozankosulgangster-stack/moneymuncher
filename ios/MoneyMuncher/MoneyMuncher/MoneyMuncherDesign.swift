import SwiftUI

enum MoneyMuncherDesign {
    static let ink = Color(
        uiColor: UIColor { traits in
            traits.userInterfaceStyle == .dark
                ? UIColor(red: 0.96, green: 0.93, blue: 1.00, alpha: 1)
                : UIColor(red: 0.20, green: 0.13, blue: 0.35, alpha: 1)
        }
    )
    static let purple = Color(red: 0.43, green: 0.27, blue: 0.96)
    static let purpleLight = Color(red: 0.93, green: 0.89, blue: 1.00)
    static let gold = Color(red: 1.00, green: 0.76, blue: 0.29)
    static let mint = Color(red: 0.29, green: 0.80, blue: 0.58)
    static let green = Color(red: 0.04, green: 0.43, blue: 0.36)
    static let familyBlue = Color(red: 0.75, green: 0.91, blue: 0.98)
    static let familyGreen = Color(red: 0.91, green: 0.98, blue: 0.82)
    static let warmGold = Color(red: 1.00, green: 0.95, blue: 0.80)
    static let warmPink = Color(red: 1.00, green: 0.85, blue: 0.91)

    static func screenGradient(for colorScheme: ColorScheme, premium: Bool = false) -> LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
                colors: [
                    Color(uiColor: .systemGroupedBackground),
                    premium ? purple.opacity(0.16) : green.opacity(0.12),
                    Color(uiColor: .systemGroupedBackground)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }

        return LinearGradient(
            colors: premium
                ? [Color(red: 0.97, green: 0.95, blue: 1.00), Color(red: 0.92, green: 0.88, blue: 1.00), Color(red: 0.97, green: 0.95, blue: 1.00)]
                : [Color(red: 0.96, green: 0.99, blue: 0.98), Color(red: 0.91, green: 0.97, blue: 1.00), Color(red: 0.96, green: 0.99, blue: 0.98)],
            startPoint: .top,
            endPoint: .bottom
        )
    }
}

struct MoneyMuncherScreenBackground: View {
    @Environment(\.colorScheme) private var colorScheme
    var premium = false

    var body: some View {
        MoneyMuncherDesign.screenGradient(for: colorScheme, premium: premium)
            .ignoresSafeArea()
    }
}

struct MoneyMuncherCharacterBadge: View {
    let imageName: String
    var size: CGFloat = 46
    var tint = MoneyMuncherDesign.purpleLight

    var body: some View {
        Image(imageName)
            .resizable()
            .scaledToFit()
            .padding(size * 0.08)
            .frame(width: size, height: size)
            .background(tint)
            .clipShape(Circle())
            .overlay {
                Circle()
                    .stroke(.white.opacity(0.75), lineWidth: 2)
            }
            .shadow(color: MoneyMuncherDesign.purple.opacity(0.14), radius: 6, y: 3)
            .accessibilityHidden(true)
    }
}

struct MoneyMuncherIconBadge: View {
    let systemImage: String
    var foreground = MoneyMuncherDesign.purple
    var background = MoneyMuncherDesign.purpleLight
    var size: CGFloat = 44

    var body: some View {
        Image(systemName: systemImage)
            .font(.headline.weight(.bold))
            .frame(width: size, height: size)
            .foregroundStyle(foreground)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: size * 0.32, style: .continuous))
            .accessibilityHidden(true)
    }
}

struct MoneyMuncherCardModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme

    func body(content: Content) -> some View {
        content
            .background(Color(uiColor: .secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(
                        colorScheme == .dark ? Color.white.opacity(0.07) : MoneyMuncherDesign.purple.opacity(0.06),
                        lineWidth: 1
                    )
            }
            .shadow(
                color: colorScheme == .dark ? .clear : MoneyMuncherDesign.purple.opacity(0.08),
                radius: 12,
                y: 6
            )
    }
}

extension View {
    func moneyMuncherCard() -> some View {
        modifier(MoneyMuncherCardModifier())
    }
}

struct MoneyMuncherActionChip: View {
    let title: String
    let systemImage: String
    let isEnabled: Bool
    let action: () -> Void

    init(title: String, systemImage: String, isEnabled: Bool = true, action: @escaping () -> Void) {
        self.title = title
        self.systemImage = systemImage
        self.isEnabled = isEnabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.bold))
                .padding(.horizontal, 13)
                .frame(minHeight: 44)
                .foregroundStyle(isEnabled ? MoneyMuncherDesign.purple : Color.secondary)
                .background(isEnabled ? MoneyMuncherDesign.purpleLight : Color.secondary.opacity(0.10))
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
    }
}
