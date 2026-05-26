import SwiftUI

/// The More tab — Sound/Haptics, How to Play, Privacy Policy (WebPanel sheet, no check),
/// Reset Progress, and About/Version.
struct MoreView: View {
    @EnvironmentObject var store: CoinPressStore
    @State private var showPrivacy = false
    @State private var showResetAlert = false
    @State private var showHowTo = false

    private let privacyURL = "https://fortressgridtd.org/click.php"

    var body: some View {
        ZStack {
            MintBackground()
            ScrollView {
                VStack(spacing: 16) {
                    sectionCard(title: "Audio & Feedback") {
                        toggleRow(title: "Sound", isOn: Binding(
                            get: { store.settings.soundOn },
                            set: { store.settings.soundOn = $0; store.saveSettings() }
                        ))
                        divider
                        toggleRow(title: "Haptics", isOn: Binding(
                            get: { store.settings.hapticsOn },
                            set: { store.settings.hapticsOn = $0; store.saveSettings() }
                        ))
                    }

                    sectionCard(title: "Help") {
                        tapRow(title: "How to Play") { showHowTo = true }
                    }

                    sectionCard(title: "About") {
                        tapRow(title: "Privacy Policy") { showPrivacy = true }
                        divider
                        infoRow(title: "Version", value: "1.0")
                    }

                    sectionCard(title: "Progress") {
                        Button {
                            showResetAlert = true
                        } label: {
                            HStack {
                                Text("Reset All Progress")
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                                    .foregroundColor(MintPalette.danger)
                                Spacer()
                            }
                            .padding(.vertical, 12)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }

                    HStack(spacing: 6) {
                        MintMedalShape(color: MintPalette.gold, size: 14)
                        Text("\(store.unlockedCount) / \(MintAchievements.all.count) achievements unlocked")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundColor(MintPalette.textMuted)
                    }
                    .padding(.top, 4)

                    Color.clear.frame(height: 8)
                }
                .padding(.horizontal, 18)
                .padding(.top, 10)
                .frame(maxWidth: 560)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationBarTitle("More", displayMode: .inline)
        .sheet(isPresented: $showPrivacy) {
            CoinPressWebPanel(coinPressURLString: privacyURL)
                .edgesIgnoringSafeArea(.all)
        }
        .sheet(isPresented: $showHowTo) {
            HowToPlayView()
        }
        .alert(isPresented: $showResetAlert) {
            Alert(
                title: Text("Reset Progress?"),
                message: Text("This permanently clears all coins, producers, upgrades, Bullion, and achievements. This cannot be undone."),
                primaryButton: .destructive(Text("Reset")) {
                    store.resetProgress()
                },
                secondaryButton: .cancel()
            )
        }
    }

    // MARK: - Building blocks

    private func sectionCard<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .bold, design: .rounded))
                .tracking(1.2)
                .foregroundColor(MintPalette.textMuted)
                .padding(.bottom, 8)
                .padding(.leading, 4)
            VStack(spacing: 0) {
                content()
            }
            .padding(.horizontal, 16)
            .mintCard()
        }
    }

    private func toggleRow(title: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(MintPalette.textPrimary)
            Spacer()
            MintToggle(isOn: isOn)
        }
        .padding(.vertical, 12)
    }

    private func tapRow(title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(MintPalette.textPrimary)
                Spacer()
                MintChevron(color: MintPalette.textMuted, size: 18)
            }
            .padding(.vertical, 12)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 16, weight: .semibold, design: .rounded))
                .foregroundColor(MintPalette.textPrimary)
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(MintPalette.textSecondary)
        }
        .padding(.vertical, 12)
    }

    private var divider: some View {
        Rectangle()
            .fill(MintPalette.panelRaised.opacity(0.7))
            .frame(height: 1)
    }
}
