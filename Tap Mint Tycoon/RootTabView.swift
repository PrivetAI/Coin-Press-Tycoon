import SwiftUI

/// App shell: a custom HStack tab bar (NOT a TabView) over a `switch` on the selected tab.
/// Each tab hosts its own NavigationView so navigation state is isolated per tab.
struct RootTabView: View {
    @EnvironmentObject var store: MintTycoonStore
    @State private var selectedTab = 0
    @State private var toastTitle: String?

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                Group {
                    switch selectedTab {
                    case 0:
                        NavigationView { MintView() }
                            .navigationViewStyle(StackNavigationViewStyle())
                    case 1:
                        NavigationView { ProducersView() }
                            .navigationViewStyle(StackNavigationViewStyle())
                    case 2:
                        NavigationView { ReforgeView() }
                            .navigationViewStyle(StackNavigationViewStyle())
                    case 3:
                        NavigationView { AwardsView() }
                            .navigationViewStyle(StackNavigationViewStyle())
                    default:
                        NavigationView { MoreView() }
                            .navigationViewStyle(StackNavigationViewStyle())
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                tabBar
            }

            if let title = toastTitle {
                unlockToast(title)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(30)
            }
        }
        // Surface newly-unlocked achievements as a top banner (~2s), then clear the queue.
        .onChange(of: store.lastUnlocked) { ids in
            guard let first = ids.first,
                  let ach = MintAchievements.all.first(where: { $0.id == first }) else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                toastTitle = ach.title
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    toastTitle = nil
                }
                store.lastUnlocked = []
            }
        }
    }

    private func unlockToast(_ title: String) -> some View {
        VStack {
            HStack(spacing: 10) {
                MintMedalShape(color: MintPalette.gold, size: 32)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Achievement Unlocked")
                        .font(.system(size: 10, weight: .bold, design: .rounded))
                        .tracking(0.8)
                        .foregroundColor(MintPalette.textMuted)
                    Text(title)
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundColor(MintPalette.textPrimary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(MintPalette.panel)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(MintPalette.mint.opacity(0.4), lineWidth: 1.5)
                    )
                    .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 4)
            )
            .padding(.horizontal, 16)
            .padding(.top, 8)
            Spacer()
        }
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabButton(0, "Mint", AnyView(MintTabPressIcon(color: tint(0), size: 24)))
            tabButton(1, "Producers", AnyView(MintTabProducersIcon(color: tint(1), size: 24)))
            tabButton(2, "Reforge", AnyView(MintTabReforgeIcon(color: tint(2), size: 24)))
            tabButton(3, "Awards", AnyView(MintTabAwardsIcon(color: tint(3), size: 24)))
            tabButton(4, "More", AnyView(MintTabMoreIcon(color: tint(4), size: 24)))
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(MintPalette.panel.edgesIgnoringSafeArea(.bottom))
        .overlay(
            Rectangle()
                .fill(MintPalette.panelRaised)
                .frame(height: 1),
            alignment: .top
        )
    }

    private func tint(_ i: Int) -> Color { selectedTab == i ? MintPalette.mintDeep : MintPalette.textMuted }

    private func tabButton(_ i: Int, _ label: String, _ icon: AnyView) -> some View {
        Button {
            selectedTab = i
        } label: {
            VStack(spacing: 3) {
                icon
                    .frame(height: 26)
                Text(label)
                    .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                    .foregroundColor(tint(i))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
