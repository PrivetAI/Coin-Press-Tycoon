import SwiftUI

struct HowToPlayView: View {
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        ZStack {
            MintBackground()
            VStack(spacing: 0) {
                HStack {
                    Text("How to Play")
                        .font(.system(size: 20, weight: .heavy, design: .rounded))
                        .foregroundColor(MintPalette.textPrimary)
                    Spacer()
                    Button {
                        presentationMode.wrappedValue.dismiss()
                    } label: {
                        ZStack {
                            Circle().fill(MintPalette.panelSunken).frame(width: 34, height: 34)
                            MintCloseShape()
                                .stroke(MintPalette.textSecondary, style: StrokeStyle(lineWidth: 2.4, lineCap: .round))
                                .frame(width: 14, height: 14)
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)

                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        ruleCard(
                            art: AnyView(MintPressShape().frame(width: 40, height: 40)),
                            title: "Tap the Press",
                            text: "Tap the big mint press on the Mint tab to strike coins by hand. Upgrade your tap power for bigger strikes."
                        )
                        ruleCard(
                            art: AnyView(MintTabProducersIcon(color: MintPalette.mintDeep, size: 36)),
                            title: "Buy Producers",
                            text: "Spend coins on 12 tiers of automatic producers. Each one mints coins every second, even while you read this."
                        )
                        ruleCard(
                            art: AnyView(MintCoinShape().frame(width: 38, height: 38)),
                            title: "Hit Milestones",
                            text: "Owning 25, 50, 100, 200+ of a producer doubles its output each time. Stack them up to grow exponentially."
                        )
                        ruleCard(
                            art: AnyView(MintTabReforgeIcon(color: MintPalette.teal, size: 36)),
                            title: "Reforge for Bullion",
                            text: "When coins pile up, Reforge to trade lifetime coins for permanent Bullion. Each Bullion adds +2% to all output forever."
                        )
                        ruleCard(
                            art: AnyView(MintBullionShape().frame(width: 40, height: 40)),
                            title: "Come Back Anytime",
                            text: "Your mint keeps producing while you're away (up to 8 hours). Collect your earnings when you return."
                        )
                        ruleCard(
                            art: AnyView(MintMedalShape(color: MintPalette.gold, size: 38)),
                            title: "Earn Awards",
                            text: "Unlock achievements for coins minted, taps, producers, reforges, and more on the Awards tab."
                        )
                        Color.clear.frame(height: 12)
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
    }

    private func ruleCard(art: AnyView, title: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            art
                .frame(width: 44, height: 44)
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundColor(MintPalette.textPrimary)
                Text(text)
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(MintPalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .mintCard()
    }
}
