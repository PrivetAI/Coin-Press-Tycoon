import SwiftUI

// All icons / art are custom SwiftUI Shapes — no SF Symbols, no emoji, no system images.

// MARK: - Coin (gold disc with an embossed mint mark)

struct MintCoinShape: View {
    var face: Color = MintPalette.gold
    var edge: Color = MintPalette.goldDeep
    var shine: Color = MintPalette.goldLight
    var mark: Color = MintPalette.goldDeep
    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack {
                Circle().fill(edge).frame(width: s, height: s)
                Circle().fill(face).frame(width: s * 0.86, height: s * 0.86)
                // shine arc
                Circle()
                    .trim(from: 0.55, to: 0.78)
                    .stroke(shine, style: StrokeStyle(lineWidth: s * 0.06, lineCap: .round))
                    .frame(width: s * 0.70, height: s * 0.70)
                // embossed mint mark — abstract "M" of two strokes
                MintMarkShape()
                    .stroke(mark, style: StrokeStyle(lineWidth: s * 0.07, lineCap: .round, lineJoin: .round))
                    .frame(width: s * 0.40, height: s * 0.40)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

// Abstract mint mark: an "M"-like double peak.
struct MintMarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let w = rect.width, h = rect.height
        p.move(to: CGPoint(x: 0, y: h))
        p.addLine(to: CGPoint(x: w * 0.12, y: 0))
        p.addLine(to: CGPoint(x: w * 0.5, y: h * 0.55))
        p.addLine(to: CGPoint(x: w * 0.88, y: 0))
        p.addLine(to: CGPoint(x: w, y: h))
        return p
    }
}

// MARK: - Gear (used on the loading splash; eoFill teeth ring)

struct MintGearShape: Shape {
    var teeth: Int = 12
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let rOuter = min(rect.width, rect.height) / 2
        let rInner = rOuter * 0.74
        let rHole = rOuter * 0.40
        let step = (2 * Double.pi) / Double(teeth * 2)
        for i in 0..<(teeth * 2) {
            let angle = Double(i) * step
            let r = (i % 2 == 0) ? rOuter : rInner
            let pt = CGPoint(x: c.x + CGFloat(cos(angle)) * r, y: c.y + CGFloat(sin(angle)) * r)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        p.addEllipse(in: CGRect(x: c.x - rHole, y: c.y - rHole, width: rHole * 2, height: rHole * 2))
        return p
    }
}

// MARK: - Mint Press (the big tappable button art)

struct MintPressShape: View {
    var bodyColor: Color = MintPalette.mint
    var bodyDeep: Color = MintPalette.mintDeep
    var coin: Color = MintPalette.gold
    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack {
                // base anvil
                RoundedRectangle(cornerRadius: s * 0.10, style: .continuous)
                    .fill(bodyDeep)
                    .frame(width: s * 0.78, height: s * 0.20)
                    .offset(y: s * 0.30)
                // column
                RoundedRectangle(cornerRadius: s * 0.06, style: .continuous)
                    .fill(bodyColor)
                    .frame(width: s * 0.20, height: s * 0.46)
                    .offset(y: -s * 0.02)
                // press head
                RoundedRectangle(cornerRadius: s * 0.10, style: .continuous)
                    .fill(bodyColor)
                    .frame(width: s * 0.56, height: s * 0.18)
                    .offset(y: -s * 0.26)
                RoundedRectangle(cornerRadius: s * 0.06, style: .continuous)
                    .fill(bodyDeep)
                    .frame(width: s * 0.56, height: s * 0.05)
                    .offset(y: -s * 0.17)
                // coin on anvil
                MintCoinShape()
                    .frame(width: s * 0.26, height: s * 0.26)
                    .offset(y: s * 0.20)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

// MARK: - Bullion bar

struct MintBullionShape: View {
    var color: Color = MintPalette.bullion
    var body: some View {
        GeometryReader { geo in
            let s = min(geo.size.width, geo.size.height)
            ZStack {
                Path { p in
                    let w = s * 0.86, h = s * 0.42
                    let x = (s - w) / 2, y = (s - h) / 2
                    let taper = w * 0.12
                    p.move(to: CGPoint(x: x + taper, y: y))
                    p.addLine(to: CGPoint(x: x + w - taper, y: y))
                    p.addLine(to: CGPoint(x: x + w, y: y + h))
                    p.addLine(to: CGPoint(x: x, y: y + h))
                    p.closeSubpath()
                }
                .fill(color)
                Path { p in
                    let w = s * 0.86, h = s * 0.42
                    let x = (s - w) / 2, y = (s - h) / 2
                    let taper = w * 0.12
                    p.move(to: CGPoint(x: x + taper, y: y))
                    p.addLine(to: CGPoint(x: x + w - taper, y: y))
                    p.addLine(to: CGPoint(x: x + w - taper * 0.6, y: y + h * 0.35))
                    p.addLine(to: CGPoint(x: x + taper * 0.6, y: y + h * 0.35))
                    p.closeSubpath()
                }
                .fill(Color.white.opacity(0.25))
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
    }
}

// MARK: - Medal (achievement art)

struct MintMedalShape: View {
    var color: Color = MintPalette.gold
    var size: CGFloat = 32
    var body: some View {
        ZStack {
            // ribbon
            Path { p in
                p.move(to: CGPoint(x: size * 0.30, y: 0))
                p.addLine(to: CGPoint(x: size * 0.45, y: size * 0.42))
                p.addLine(to: CGPoint(x: size * 0.30, y: size * 0.42))
                p.closeSubpath()
                p.move(to: CGPoint(x: size * 0.70, y: 0))
                p.addLine(to: CGPoint(x: size * 0.55, y: size * 0.42))
                p.addLine(to: CGPoint(x: size * 0.70, y: size * 0.42))
                p.closeSubpath()
            }
            .fill(MintPalette.teal)
            Circle()
                .fill(color)
                .frame(width: size * 0.62, height: size * 0.62)
                .offset(y: size * 0.18)
            Circle()
                .stroke(Color.white.opacity(0.5), lineWidth: size * 0.04)
                .frame(width: size * 0.46, height: size * 0.46)
                .offset(y: size * 0.18)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Star

struct MintStar: View {
    var filled: Bool = true
    var size: CGFloat = 14
    var body: some View {
        MintStarShape()
            .fill(filled ? MintPalette.gold : MintPalette.track)
            .frame(width: size, height: size)
    }
}

struct MintStarShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let rOuter = min(rect.width, rect.height) / 2
        let rInner = rOuter * 0.42
        for i in 0..<10 {
            let angle = -Double.pi / 2 + Double(i) * Double.pi / 5
            let r = (i % 2 == 0) ? rOuter : rInner
            let pt = CGPoint(x: c.x + CGFloat(cos(angle)) * r, y: c.y + CGFloat(sin(angle)) * r)
            if i == 0 { p.move(to: pt) } else { p.addLine(to: pt) }
        }
        p.closeSubpath()
        return p
    }
}

// MARK: - Chevron / close

struct MintChevron: View {
    var color: Color = MintPalette.textMuted
    var size: CGFloat = 18
    var body: some View {
        MintChevronShape()
            .stroke(color, style: StrokeStyle(lineWidth: 2.2, lineCap: .round, lineJoin: .round))
            .frame(width: size * 0.5, height: size)
    }
}

struct MintChevronShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        return p
    }
}

struct MintCloseShape: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        p.move(to: CGPoint(x: rect.maxX, y: rect.minY))
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        return p
    }
}

// MARK: - Tab bar icons (all custom)

struct MintTabPressIcon: View {
    var color: Color
    var size: CGFloat = 24
    var body: some View {
        MintPressShape(bodyColor: color, bodyDeep: color.opacity(0.7), coin: color)
            .frame(width: size, height: size)
    }
}

struct MintTabProducersIcon: View {
    var color: Color
    var size: CGFloat = 24
    var body: some View {
        // three stacked bars (a production stack)
        VStack(spacing: size * 0.10) {
            ForEach(0..<3) { i in
                RoundedRectangle(cornerRadius: size * 0.08, style: .continuous)
                    .fill(color)
                    .frame(width: size * (0.9 - CGFloat(i) * 0.18), height: size * 0.18)
            }
        }
        .frame(width: size, height: size)
    }
}

struct MintTabReforgeIcon: View {
    var color: Color
    var size: CGFloat = 24
    var body: some View {
        // a circular arrow ring (reforge / cycle)
        ZStack {
            Circle()
                .trim(from: 0.08, to: 0.92)
                .stroke(color, style: StrokeStyle(lineWidth: size * 0.13, lineCap: .round))
                .frame(width: size * 0.78, height: size * 0.78)
                .rotationEffect(.degrees(-90))
            // arrow head
            Path { p in
                p.move(to: CGPoint(x: size * 0.62, y: size * 0.10))
                p.addLine(to: CGPoint(x: size * 0.86, y: size * 0.20))
                p.addLine(to: CGPoint(x: size * 0.66, y: size * 0.36))
            }
            .stroke(color, style: StrokeStyle(lineWidth: size * 0.10, lineCap: .round, lineJoin: .round))
        }
        .frame(width: size, height: size)
    }
}

struct MintTabAwardsIcon: View {
    var color: Color
    var size: CGFloat = 24
    var body: some View {
        MintMedalShape(color: color, size: size)
    }
}

struct MintTabMoreIcon: View {
    var color: Color
    var size: CGFloat = 24
    var body: some View {
        HStack(spacing: size * 0.14) {
            ForEach(0..<3) { _ in
                Circle().fill(color).frame(width: size * 0.16, height: size * 0.16)
            }
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Custom toggle (themed track + knob, no native reliance)

struct MintToggle: View {
    @Binding var isOn: Bool
    var body: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.16)) { isOn.toggle() }
        } label: {
            ZStack(alignment: isOn ? .trailing : .leading) {
                Capsule()
                    .fill(isOn ? MintPalette.success : MintPalette.track)
                    .frame(width: 50, height: 30)
                Circle()
                    .fill(Color.white)
                    .frame(width: 24, height: 24)
                    .padding(.horizontal, 3)
                    .shadow(color: .black.opacity(0.12), radius: 2, x: 0, y: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Progress bar

struct MintProgressBar: View {
    var fraction: Double          // 0...1
    var tint: Color = MintPalette.mint
    var height: CGFloat = 8
    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(MintPalette.track)
                Capsule()
                    .fill(tint)
                    .frame(width: max(0, min(1, fraction)) * geo.size.width)
            }
        }
        .frame(height: height)
    }
}
