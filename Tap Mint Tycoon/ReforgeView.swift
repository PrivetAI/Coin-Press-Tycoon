import SwiftUI

/// The Reforge tab — prestige preview/confirm plus the one-time upgrades shop (tap, global,
/// per-producer, special).
struct ReforgeView: View {
    @EnvironmentObject var store: MintTycoonStore
    @State private var showConfirm = false
    @State private var category: MintShopFilter = .all

    var body: some View {
        ZStack {
            MintBackground()
            ScrollView {
                VStack(spacing: 14) {
                    reforgeCard
                    shopHeader
                    ForEach(filteredUpgrades) { def in
                        UpgradeRow(def: def)
                    }
                    Color.clear.frame(height: 12)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationBarTitle("Reforge", displayMode: .inline)
        .alert(isPresented: $showConfirm) {
            Alert(
                title: Text("Reforge the Mint?"),
                message: Text("You will gain \(MintFormat.coins(store.pendingReforgeBullion)) Bullion (+\(MintFormat.coins(store.pendingReforgeBullion * 2))% permanent output). This resets your coins, producers, and most upgrades. Bullion, permanent perks, and achievements are kept."),
                primaryButton: .destructive(Text("Reforge")) {
                    store.reforge()
                },
                secondaryButton: .cancel()
            )
        }
    }

    private var reforgeCard: some View {
        VStack(spacing: 14) {
            HStack(spacing: 10) {
                MintBullionShape().frame(width: 34, height: 34)
                VStack(alignment: .leading, spacing: 1) {
                    Text("Bullion")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .tracking(0.8)
                        .foregroundColor(MintPalette.textMuted)
                    Text(MintFormat.coins(store.bullion))
                        .font(.system(size: 24, weight: .heavy, design: .rounded))
                        .foregroundColor(MintPalette.textPrimary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 1) {
                    Text("Global Bonus")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .tracking(0.6)
                        .foregroundColor(MintPalette.textMuted)
                    Text(store.bullion > 0 ? MintFormat.percent(store.bullionBonusFraction) : "+0%")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundColor(MintPalette.teal)
                }
            }

            Rectangle().fill(MintPalette.panelRaised).frame(height: 1)

            VStack(spacing: 6) {
                Text("Reforge to convert lifetime coins into permanent Bullion.")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(MintPalette.textSecondary)
                    .multilineTextAlignment(.center)
                HStack(spacing: 16) {
                    miniStat("Lifetime", MintFormat.coins(store.lifetimeCoins))
                    miniStat("On Reforge", "+" + MintFormat.coins(store.pendingReforgeBullion))
                }
            }

            Button {
                if store.canReforge { showConfirm = true }
            } label: {
                Text(store.canReforge ? "Reforge for \(MintFormat.coins(store.pendingReforgeBullion)) Bullion" : "Need 1M lifetime coins to Reforge")
                    .font(.system(size: 16, weight: .heavy, design: .rounded))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(store.canReforge ? MintPalette.teal : MintPalette.track)
                    )
            }
            .buttonStyle(.plain)
            .disabled(!store.canReforge)
        }
        .padding(16)
        .mintCard()
    }

    private func miniStat(_ title: String, _ value: String) -> some View {
        VStack(spacing: 2) {
            Text(title.uppercased())
                .font(.system(size: 9.5, weight: .bold, design: .rounded))
                .tracking(0.6)
                .foregroundColor(MintPalette.textMuted)
            Text(value)
                .font(.system(size: 15, weight: .heavy, design: .rounded))
                .foregroundColor(MintPalette.goldDeep)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
    }

    private var shopHeader: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Upgrades")
                    .font(.system(size: 18, weight: .heavy, design: .rounded))
                    .foregroundColor(MintPalette.textPrimary)
                Spacer()
                Text("\(store.purchasedUpgrades.count)/\(MintUpgradeCatalog.all.count)")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(MintPalette.textSecondary)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(MintShopFilter.allCases, id: \.self) { f in
                        Button {
                            category = f
                        } label: {
                            Text(f.label)
                                .font(.system(size: 12.5, weight: .bold, design: .rounded))
                                .foregroundColor(category == f ? .white : MintPalette.textSecondary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 7)
                                .background(
                                    Capsule().fill(category == f ? MintPalette.mint : MintPalette.panelSunken)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
        .padding(.top, 4)
    }

    private var filteredUpgrades: [MintUpgradeDef] {
        MintUpgradeCatalog.all.filter { def in
            switch category {
            case .all: return true
            case .tap: return def.category == .tap
            case .global: return def.category == .global
            case .producer: return def.category == .producer
            case .special: return def.category == .special
            }
        }
    }
}

enum MintShopFilter: CaseIterable {
    case all, tap, global, producer, special
    var label: String {
        switch self {
        case .all: return "All"
        case .tap: return "Tap"
        case .global: return "Global"
        case .producer: return "Producer"
        case .special: return "Special"
        }
    }
}

struct UpgradeRow: View {
    @EnvironmentObject var store: MintTycoonStore
    let def: MintUpgradeDef

    private var purchased: Bool { store.isPurchased(def.id) }
    private var affordable: Bool { store.canAfford(upgrade: def) }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(categoryColor.opacity(0.16))
                    .frame(width: 46, height: 46)
                categoryIcon
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(def.name)
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundColor(MintPalette.textPrimary)
                Text(def.blurb)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(MintPalette.textSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 4)
            if purchased {
                Text("OWNED")
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundColor(MintPalette.success)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(MintPalette.success.opacity(0.15)))
            } else {
                Button {
                    store.buyUpgrade(def)
                } label: {
                    Text(MintFormat.coins(def.cost))
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundColor(affordable ? .white : MintPalette.textMuted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.6)
                        .frame(width: 76)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(affordable ? MintPalette.mint : MintPalette.track)
                        )
                }
                .buttonStyle(.plain)
                .disabled(!affordable)
            }
        }
        .padding(12)
        .mintCard(corner: MintMetrics.cornerSmall)
        .opacity(purchased ? 0.85 : 1)
    }

    private var categoryColor: Color {
        switch def.category {
        case .tap: return MintPalette.goldDeep
        case .global: return MintPalette.mintDeep
        case .producer: return MintPalette.teal
        case .special: return MintPalette.bullion
        }
    }

    private var categoryIcon: some View {
        Group {
            switch def.category {
            case .tap: MintPressShape(bodyColor: categoryColor, bodyDeep: categoryColor.opacity(0.7), coin: MintPalette.gold).frame(width: 26, height: 26)
            case .global: MintCoinShape().frame(width: 26, height: 26)
            case .producer: MintTabProducersIcon(color: categoryColor, size: 24)
            case .special: MintTabReforgeIcon(color: categoryColor, size: 24)
            }
        }
    }
}
