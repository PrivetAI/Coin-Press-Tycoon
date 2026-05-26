import Foundation

// MARK: - Deterministic SplitMix64 RNG (NEVER Hasher / String.hashValue)

struct MintSplitMix64 {
    private var state: UInt64
    init(seed: UInt64) { self.state = seed }

    mutating func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z &>> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z &>> 27)) &* 0x94D049BB133111EB
        return z ^ (z &>> 31)
    }

    // Uniform Double in [0, 1).
    mutating func nextUnit() -> Double {
        Double(next() &>> 11) * (1.0 / 9007199254740992.0)
    }
}

// MARK: - Big-number formatting

/// Clean compact formatter used everywhere numbers are shown.
/// K, M, B, T, then two-letter suffixes aa, ab, ac… and finally scientific for
/// astronomically large values. Robust against NaN / infinity / negatives.
enum MintFormat {

    private static let shortSuffix = ["", "K", "M", "B", "T"]
    private static let alpha = Array("abcdefghijklmnopqrstuvwxyz")

    /// Returns the suffix for the given thousands-power index.
    /// 0 -> "", 1 -> "K"… 4 -> "T", 5 -> "aa", 6 -> "ab", … then scientific handled by caller.
    private static func suffix(forTier tier: Int) -> String {
        if tier < shortSuffix.count { return shortSuffix[tier] }
        let n = tier - shortSuffix.count          // 0-based into the aa, ab… space
        let first = n / 26
        let second = n % 26
        guard first < 26 else { return "" }       // caller falls back to scientific
        return String(alpha[first]) + String(alpha[second])
    }

    /// Format a quantity (coins, output, etc.).
    static func coins(_ value: Double) -> String {
        guard value.isFinite else { return "∞" }
        if value < 0 { return "0" }
        if value < 1000 {
            // small integers shown without decimals; fractions get one decimal under 10
            if value < 10 && value != value.rounded() {
                return String(format: "%.1f", value)
            }
            return String(Int(value.rounded(.down)))
        }
        var tier = 0
        var v = value
        while v >= 1000 && tier < 1000 {
            v /= 1000
            tier += 1
        }
        // Beyond the supported two-letter range, fall back to scientific.
        let lastNamedTier = shortSuffix.count - 1 + 26 * 26
        if tier > lastNamedTier {
            return String(format: "%.2e", value)
        }
        let s = suffix(forTier: tier)
        if s.isEmpty { return String(format: "%.2e", value) }
        if v < 10 { return String(format: "%.2f%@", v, s) }
        if v < 100 { return String(format: "%.1f%@", v, s) }
        return String(format: "%.0f%@", v, s)
    }

    /// Per-second rate string.
    static func rate(_ value: Double) -> String {
        coins(value) + "/s"
    }

    /// Compact integer count (for owned producers, taps, etc.).
    static func count(_ value: Int) -> String {
        if value < 100000 { return String(value) }
        return coins(Double(value))
    }

    /// Percentage from a multiplier delta (e.g. 0.25 -> "+25%").
    static func percent(_ fraction: Double) -> String {
        let pct = fraction * 100
        if abs(pct) >= 100 || pct == pct.rounded() {
            return String(format: "+%.0f%%", pct)
        }
        return String(format: "+%.1f%%", pct)
    }

    /// Multiplier string (e.g. 2.5 -> "×2.5").
    static func mult(_ value: Double) -> String {
        guard value.isFinite else { return "×∞" }
        if value >= 1000 { return "×" + coins(value) }
        if value == value.rounded() { return String(format: "×%.0f", value) }
        return String(format: "×%.2f", value)
    }
}

// MARK: - Safe math helpers

enum MintMath {
    /// Clamp to a finite non-negative double (guards against NaN / overflow).
    static func sane(_ v: Double) -> Double {
        if v.isNaN { return 0 }
        if v < 0 { return 0 }
        if v > 1e300 { return 1e300 }
        return v
    }
}
