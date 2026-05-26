import SwiftUI

/// The Mint tab — the big tap press, balance, coins/sec, tap power. Tapping the press mints coins.
struct MintView: View {
    @EnvironmentObject var store: CoinPressStore
    @State private var pressDown = false
    @State private var floaters: [MintFloater] = []

    var body: some View {
        ZStack {
            MintBackground()
            VStack(spacing: 0) {
                balanceHeader
                Spacer(minLength: 8)
                pressArea
                Spacer(minLength: 8)
                statStrip
                    .padding(.horizontal, 18)
                    .padding(.bottom, 14)
            }
        }
        .navigationBarTitle("Mint", displayMode: .inline)
    }

    // MARK: balance

    private var balanceHeader: some View {
        VStack(spacing: 4) {
            HStack(spacing: 8) {
                MintCoinShape().frame(width: 26, height: 26)
                Text(MintFormat.coins(store.coins))
                    .font(.system(size: 38, weight: .heavy, design: .rounded))
                    .foregroundColor(MintPalette.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
            }
            Text(MintFormat.rate(store.coinsPerSecond))
                .font(.system(size: 15, weight: .semibold, design: .rounded))
                .foregroundColor(MintPalette.mintDeep)
        }
        .padding(.top, 18)
        .padding(.horizontal, 18)
    }

    // MARK: tap press

    private var pressArea: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height) * 0.82
            ZStack {
                // glow ring
                Circle()
                    .fill(MintPalette.mintLight.opacity(0.30))
                    .frame(width: side * 1.04, height: side * 1.04)
                Circle()
                    .fill(MintPalette.panel)
                    .overlay(Circle().stroke(MintPalette.mint.opacity(0.5), lineWidth: 3))
                    .frame(width: side, height: side)
                    .shadow(color: MintPalette.mintDeep.opacity(0.18), radius: 14, x: 0, y: 6)
                MintPressShape()
                    .frame(width: side * 0.62, height: side * 0.62)
                    .scaleEffect(pressDown ? 0.92 : 1.0)

                // floating "+coins" feedback
                ForEach(floaters) { f in
                    Text("+\(MintFormat.coins(f.amount))")
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundColor(MintPalette.goldDeep)
                        .offset(x: f.dx, y: f.dy)
                        .opacity(f.opacity)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .contentShape(Circle())
            .onTapGesture {
                handleTap(in: geo.size)
            }
            .scaleEffect(pressDown ? 0.98 : 1.0)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 360)
    }

    private func handleTap(in size: CGSize) {
        let gain = store.coinsPerTap
        store.tap()
        withAnimation(.easeOut(duration: 0.08)) { pressDown = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
            withAnimation(.easeOut(duration: 0.12)) { pressDown = false }
        }
        spawnFloater(amount: gain)
    }

    private func spawnFloater(amount: Double) {
        let id = UUID()
        var seed = MintSplitMix64(seed: UInt64(bitPattern: Int64(store.totalTaps)) &* 0x2545F4914F6CDD1D &+ 0x9E3779B9)
        let dx = CGFloat(seed.nextUnit() * 80 - 40)
        let floater = MintFloater(id: id, amount: amount, dx: dx, dy: -10, opacity: 1)
        floaters.append(floater)
        withAnimation(.easeOut(duration: 0.9)) {
            if let idx = floaters.firstIndex(where: { $0.id == id }) {
                floaters[idx].dy = -120
                floaters[idx].opacity = 0
            }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.95) {
            floaters.removeAll { $0.id == id }
        }
    }

    // MARK: stat strip

    private var statStrip: some View {
        HStack(spacing: 12) {
            statCard(title: "Per Tap", value: MintFormat.coins(store.coinsPerTap), tint: MintPalette.goldDeep)
            statCard(title: "Per Sec", value: MintFormat.coins(store.coinsPerSecond), tint: MintPalette.mintDeep)
            statCard(title: "Bonus", value: store.bullion > 0 ? MintFormat.percent(store.bullionBonusFraction) : "—", tint: MintPalette.teal)
        }
    }

    private func statCard(title: String, value: String, tint: Color) -> some View {
        VStack(spacing: 4) {
            Text(title.uppercased())
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(0.8)
                .foregroundColor(MintPalette.textMuted)
            Text(value)
                .font(.system(size: 16, weight: .heavy, design: .rounded))
                .foregroundColor(tint)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .mintCard(corner: MintMetrics.cornerSmall)
    }
}

struct MintFloater: Identifiable {
    let id: UUID
    let amount: Double
    var dx: CGFloat
    var dy: CGFloat
    var opacity: Double
}
