import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: MintTycoonStore
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        ZStack {
            RootTabView()

            if let summary = store.offlineSummary {
                MintOfflineView(summary: summary) {
                    store.dismissOfflineSummary()
                }
                .transition(.opacity)
                .zIndex(20)
            }
        }
        .onChange(of: scenePhase) { phase in
            switch phase {
            case .background, .inactive:
                store.handleBackground()
            case .active:
                store.handleForeground()
            @unknown default:
                break
            }
        }
    }
}

// "While you were away" summary card.
struct MintOfflineView: View {
    let summary: MintOfflineSummary
    let onClaim: () -> Void
    @State private var appear = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
            VStack(spacing: 18) {
                MintCoinShape()
                    .frame(width: 64, height: 64)
                    .scaleEffect(appear ? 1 : 0.6)
                Text("While You Were Away")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundColor(MintPalette.textPrimary)
                Text("Your mint ran for \(summary.durationText)\(summary.capped ? " (capped)" : "") and produced:")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(MintPalette.textSecondary)
                    .multilineTextAlignment(.center)
                Text(MintFormat.coins(summary.coins))
                    .font(.system(size: 30, weight: .heavy, design: .rounded))
                    .foregroundColor(MintPalette.goldDeep)
                Text("coins")
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(MintPalette.textMuted)
                Button(action: onClaim) {
                    Text("Collect")
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(MintPalette.mint)
                        )
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
            .padding(24)
            .frame(maxWidth: 360)
            .background(
                RoundedRectangle(cornerRadius: 24, style: .continuous)
                    .fill(MintPalette.panel)
            )
            .padding(.horizontal, 30)
            .scaleEffect(appear ? 1 : 0.92)
            .opacity(appear ? 1 : 0)
        }
        .onAppear {
            withAnimation(.spring(response: 0.45, dampingFraction: 0.8)) { appear = true }
        }
    }
}
