import SwiftUI

/// The Awards tab — lifetime stats strip, milestones panel, and the achievements grid.
struct AwardsView: View {
    @EnvironmentObject var store: MintTycoonStore

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        ZStack {
            MintBackground()
            ScrollView {
                VStack(spacing: 16) {
                    statsCard
                    milestonesCard
                    achievementsSection
                    Color.clear.frame(height: 12)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationBarTitle("Awards", displayMode: .inline)
    }

    // MARK: stats

    private var statsCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Statistics")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundColor(MintPalette.textPrimary)
                Spacer()
            }
            .padding(.bottom, 10)
            VStack(spacing: 0) {
                statRow("Coins (current)", MintFormat.coins(store.coins))
                divider
                statRow("Lifetime coins", MintFormat.coins(store.lifetimeCoins))
                divider
                statRow("Coins / sec", MintFormat.coins(store.coinsPerSecond))
                divider
                statRow("Best coins / sec", MintFormat.coins(store.bestCoinsPerSecond))
                divider
                statRow("Total taps", MintFormat.count(store.totalTaps))
                divider
                statRow("Producers owned", MintFormat.count(store.totalProducersOwned))
                divider
                statRow("Reforges", "\(store.reforges)")
                divider
                statRow("Bullion", MintFormat.coins(store.bullion))
            }
        }
        .padding(16)
        .mintCard()
    }

    private func statRow(_ title: String, _ value: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 14, weight: .semibold, design: .rounded))
                .foregroundColor(MintPalette.textSecondary)
            Spacer()
            Text(value)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundColor(MintPalette.textPrimary)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(.vertical, 9)
    }

    // MARK: milestones

    private var milestonesCard: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Milestones")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundColor(MintPalette.textPrimary)
                Spacer()
            }
            .padding(.bottom, 10)
            milestoneRow("Total coins minted", value: store.lifetimeCoins, target: nextThreshold(store.lifetimeCoins, base: [1e3, 1e5, 1e7, 1e9, 1e12, 1e15, 1e18]))
            milestoneRow("Total taps", value: Double(store.totalTaps), target: nextThreshold(Double(store.totalTaps), base: [100, 1000, 10000, 100000, 1000000]))
            milestoneRow("Producers owned", value: Double(store.totalProducersOwned), target: nextThreshold(Double(store.totalProducersOwned), base: [10, 50, 200, 500, 1000, 2000]))
            milestoneRow("Reforges", value: Double(store.reforges), target: nextThreshold(Double(store.reforges), base: [1, 5, 10, 25, 50]))
        }
        .padding(16)
        .mintCard()
    }

    private func nextThreshold(_ value: Double, base: [Double]) -> Double {
        base.first(where: { $0 > value }) ?? (base.last ?? 1)
    }

    private func milestoneRow(_ title: String, value: Double, target: Double) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(MintPalette.textSecondary)
                Spacer()
                Text("\(MintFormat.coins(value)) / \(MintFormat.coins(target))")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundColor(MintPalette.textMuted)
            }
            MintProgressBar(fraction: target > 0 ? value / target : 1, tint: MintPalette.mint, height: 7)
        }
        .padding(.vertical, 8)
    }

    // MARK: achievements

    private var achievementsSection: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Achievements")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundColor(MintPalette.textPrimary)
                Spacer()
                Text("\(store.unlockedCount)/\(MintAchievements.all.count)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(MintPalette.textSecondary)
            }
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(MintAchievements.all) { ach in
                    AchievementCell(ach: ach)
                }
            }
        }
    }

    private var divider: some View {
        Rectangle().fill(MintPalette.panelRaised.opacity(0.7)).frame(height: 1)
    }
}

struct AchievementCell: View {
    @EnvironmentObject var store: MintTycoonStore
    let ach: MintAchievementDef

    private var unlocked: Bool { store.isUnlocked(ach.id) }
    private var prog: Double { min(1, ach.progress(store) / max(ach.goal, 1)) }

    var body: some View {
        VStack(spacing: 8) {
            MintMedalShape(color: unlocked ? MintPalette.gold : MintPalette.track, size: 38)
                .opacity(unlocked ? 1 : 0.55)
            Text(ach.title)
                .font(.system(size: 13, weight: .heavy, design: .rounded))
                .foregroundColor(unlocked ? MintPalette.textPrimary : MintPalette.textMuted)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(ach.detail)
                .font(.system(size: 10.5, weight: .medium, design: .rounded))
                .foregroundColor(MintPalette.textMuted)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(height: 28)
            if unlocked {
                Text("UNLOCKED")
                    .font(.system(size: 9.5, weight: .heavy, design: .rounded))
                    .foregroundColor(MintPalette.success)
            } else {
                MintProgressBar(fraction: prog, tint: MintPalette.mint, height: 5)
                    .padding(.horizontal, 6)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .mintCard(corner: MintMetrics.cornerSmall)
        .opacity(unlocked ? 1 : 0.85)
    }
}
