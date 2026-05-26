import SwiftUI

/// The Producers tab — the 12 producer tiers with cost, output, owned count, milestone progress,
/// and a buy-quantity selector (×1 / ×10 / Max).
struct ProducersView: View {
    @EnvironmentObject var store: CoinPressStore
    @State private var buyMode: MintBuyMode = .one

    var body: some View {
        ZStack {
            MintBackground()
            ScrollView {
                VStack(spacing: 12) {
                    header
                    ForEach(MintCatalog.producers) { def in
                        ProducerRow(def: def, buyMode: buyMode)
                    }
                    Color.clear.frame(height: 12)
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .frame(maxWidth: 600)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationBarTitle("Producers", displayMode: .inline)
    }

    private var header: some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                MintCoinShape().frame(width: 22, height: 22)
                Text(MintFormat.coins(store.coins))
                    .font(.system(size: 24, weight: .heavy, design: .rounded))
                    .foregroundColor(MintPalette.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                Spacer()
                Text(MintFormat.rate(store.coinsPerSecond))
                    .font(.system(size: 14, weight: .semibold, design: .rounded))
                    .foregroundColor(MintPalette.mintDeep)
            }
            // buy-quantity selector
            HStack(spacing: 8) {
                ForEach(MintBuyMode.allCases, id: \.self) { mode in
                    Button {
                        buyMode = mode
                    } label: {
                        Text(mode.label)
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundColor(buyMode == mode ? .white : MintPalette.textSecondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 10, style: .continuous)
                                    .fill(buyMode == mode ? MintPalette.mint : MintPalette.panelSunken)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            if store.hasAutoBuyer {
                HStack(spacing: 6) {
                    MintTabReforgeIcon(color: MintPalette.teal, size: 14)
                    Text("Auto-Buyer active — purchasing the cheapest producer for you.")
                        .font(.system(size: 11, weight: .semibold, design: .rounded))
                        .foregroundColor(MintPalette.teal)
                    Spacer()
                }
            }
        }
        .padding(14)
        .mintCard()
    }
}

enum MintBuyMode: CaseIterable {
    case one, ten, max
    var label: String {
        switch self {
        case .one: return "Buy ×1"
        case .ten: return "Buy ×10"
        case .max: return "Buy Max"
        }
    }
}

struct ProducerRow: View {
    @EnvironmentObject var store: CoinPressStore
    let def: MintProducerDef
    let buyMode: MintBuyMode

    private var owned: Int { store.owned(forTier: def.id) }
    private var unlocked: Bool {
        // tier 0 always; later tiers unlock once any of the previous tier is owned OR coins reach
        // a fraction of base cost so the catalog reveals progressively.
        if def.id == 0 { return true }
        return store.owned(forTier: def.id - 1) > 0 || store.lifetimeCoins >= def.baseCost * 0.5 || owned > 0
    }

    private var buyCount: Int {
        switch buyMode {
        case .one: return 1
        case .ten: return 10
        case .max: return max(1, store.maxAffordable(tier: def.id))
        }
    }

    private var cost: Double {
        if buyMode == .max {
            let n = store.maxAffordable(tier: def.id)
            return def.bulkCost(owned: owned, count: max(1, n))
        }
        return def.bulkCost(owned: owned, count: buyCount)
    }

    private var affordable: Bool {
        if buyMode == .max { return store.maxAffordable(tier: def.id) >= 1 }
        return store.coins >= cost
    }

    var body: some View {
        if unlocked {
            unlockedRow
        } else {
            lockedRow
        }
    }

    private var unlockedRow: some View {
        HStack(spacing: 12) {
            // tier badge
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(MintPalette.panelSunken)
                    .frame(width: 52, height: 52)
                Text("\(def.id + 1)")
                    .font(.system(size: 20, weight: .heavy, design: .rounded))
                    .foregroundColor(MintPalette.mintDeep)
            }
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(def.name)
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                        .foregroundColor(MintPalette.textPrimary)
                    Spacer(minLength: 0)
                    Text("×\(owned)")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundColor(MintPalette.textSecondary)
                }
                Text("+\(MintFormat.rate(store.tierOutput(def.id) * store.globalMultiplier))")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(MintPalette.mintDeep)
                milestoneBar
            }
            buyButton
        }
        .padding(12)
        .mintCard(corner: MintMetrics.cornerSmall)
    }

    private var milestoneBar: some View {
        Group {
            if let next = MintProducerDef.nextMilestone(owned: owned) {
                let prev = previousMilestone(before: next)
                let frac = Double(owned - prev) / Double(next - prev)
                VStack(alignment: .leading, spacing: 2) {
                    MintProgressBar(fraction: frac, tint: MintPalette.gold, height: 5)
                    Text("\(owned)/\(next) → ×2 output")
                        .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                        .foregroundColor(MintPalette.textMuted)
                }
                .padding(.top, 1)
            } else {
                Text("All milestones reached")
                    .font(.system(size: 9.5, weight: .semibold, design: .rounded))
                    .foregroundColor(MintPalette.gold)
            }
        }
    }

    private func previousMilestone(before next: Int) -> Int {
        let thresholds = [0, 25, 50, 100, 200, 300, 400, 500, 750, 1000]
        return thresholds.last(where: { $0 < next }) ?? 0
    }

    private var buyButton: some View {
        Button {
            if buyMode == .max {
                let n = store.maxAffordable(tier: def.id)
                if n >= 1 { store.buyProducer(tier: def.id, count: n) }
            } else {
                store.buyProducer(tier: def.id, count: buyCount)
            }
        } label: {
            VStack(spacing: 2) {
                Text(buyMode == .max ? "MAX ×\(max(1, store.maxAffordable(tier: def.id)))" : (buyMode == .ten ? "×10" : "BUY"))
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(affordable ? .white : MintPalette.textMuted)
                Text(MintFormat.coins(cost))
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .foregroundColor(affordable ? .white : MintPalette.textMuted)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .frame(width: 78)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(affordable ? MintPalette.mint : MintPalette.track)
            )
        }
        .buttonStyle(.plain)
        .disabled(!affordable)
    }

    private var lockedRow: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(MintPalette.panelSunken)
                    .frame(width: 52, height: 52)
                MintLockShape()
                    .stroke(MintPalette.lock, style: StrokeStyle(lineWidth: 2.4, lineCap: .round, lineJoin: .round))
                    .frame(width: 20, height: 22)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text("Locked Tier")
                    .font(.system(size: 15, weight: .heavy, design: .rounded))
                    .foregroundColor(MintPalette.textMuted)
                Text("Unlocks around \(MintFormat.coins(def.baseCost * 0.5)) coins")
                    .font(.system(size: 12, weight: .semibold, design: .rounded))
                    .foregroundColor(MintPalette.textMuted)
            }
            Spacer()
        }
        .padding(12)
        .mintCard(corner: MintMetrics.cornerSmall)
        .opacity(0.7)
    }
}

// padlock shape (custom)
struct MintLockShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        // shackle
        p.addArc(center: CGPoint(x: w * 0.5, y: h * 0.36),
                 radius: w * 0.30,
                 startAngle: .degrees(180), endAngle: .degrees(0), clockwise: false)
        // body
        let bodyRect = CGRect(x: w * 0.12, y: h * 0.36, width: w * 0.76, height: h * 0.6)
        p.addRoundedRect(in: bodyRect, cornerSize: CGSize(width: w * 0.12, height: w * 0.12))
        return p
    }
}
