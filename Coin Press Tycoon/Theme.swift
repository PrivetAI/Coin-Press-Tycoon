import SwiftUI

// Mint-house palette — minty teal/green primary, gold coin accent, cream background,
// dark slate text. Clean and abstract. Forced light scheme at the scene root.
enum MintPalette {
    static let background = Color(red: 0.96, green: 0.98, blue: 0.95)      // cream
    static let backgroundDeep = Color(red: 0.91, green: 0.96, blue: 0.93)  // soft mint cream
    static let panel = Color(red: 1.00, green: 1.00, blue: 1.00)           // card white
    static let panelRaised = Color(red: 0.88, green: 0.93, blue: 0.90)     // card edge
    static let panelSunken = Color(red: 0.93, green: 0.97, blue: 0.95)

    static let mint = Color(red: 0.24, green: 0.74, blue: 0.55)            // primary mint
    static let mintDeep = Color(red: 0.16, green: 0.58, blue: 0.44)        // deep mint
    static let mintLight = Color(red: 0.55, green: 0.86, blue: 0.72)       // light mint
    static let teal = Color(red: 0.18, green: 0.62, blue: 0.62)            // teal accent

    static let gold = Color(red: 0.93, green: 0.74, blue: 0.27)            // coin gold
    static let goldDeep = Color(red: 0.80, green: 0.58, blue: 0.14)        // deep gold
    static let goldLight = Color(red: 0.98, green: 0.86, blue: 0.50)       // light gold

    static let bullion = Color(red: 0.45, green: 0.78, blue: 0.70)         // reforge currency

    static let accent = MintPalette.mint
    static let accentDeep = MintPalette.mintDeep

    static let textPrimary = Color(red: 0.13, green: 0.20, blue: 0.18)     // dark slate
    static let textSecondary = Color(red: 0.34, green: 0.44, blue: 0.41)
    static let textMuted = Color(red: 0.55, green: 0.64, blue: 0.61)

    static let success = Color(red: 0.27, green: 0.74, blue: 0.50)
    static let danger = Color(red: 0.86, green: 0.40, blue: 0.36)
    static let lock = Color(red: 0.70, green: 0.78, blue: 0.75)
    static let track = Color(red: 0.86, green: 0.92, blue: 0.89)
}

enum MintMetrics {
    static let corner: CGFloat = 18
    static let cornerSmall: CGFloat = 12
}

// Reusable raised card background.
struct MintCard: ViewModifier {
    var corner: CGFloat = MintMetrics.corner
    func body(content: Content) -> some View {
        content
            .background(
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(MintPalette.panel)
                    .overlay(
                        RoundedRectangle(cornerRadius: corner, style: .continuous)
                            .stroke(MintPalette.panelRaised, lineWidth: 1)
                    )
                    .shadow(color: MintPalette.mintDeep.opacity(0.06), radius: 8, x: 0, y: 3)
            )
    }
}

extension View {
    func mintCard(corner: CGFloat = MintMetrics.corner) -> some View {
        modifier(MintCard(corner: corner))
    }
}

// Background gradient used across screens.
struct MintBackground: View {
    var body: some View {
        LinearGradient(
            colors: [MintPalette.background, MintPalette.backgroundDeep],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}
