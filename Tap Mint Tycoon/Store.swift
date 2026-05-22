import Foundation
import SwiftUI

// MARK: - Settings (tmt.settings.v1)

struct MintSettings: Codable {
    var soundOn: Bool
    var hapticsOn: Bool

    init(soundOn: Bool = true, hapticsOn: Bool = true) {
        self.soundOn = soundOn
        self.hapticsOn = hapticsOn
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        soundOn = try c.decodeIfPresent(Bool.self, forKey: .soundOn) ?? true
        hapticsOn = try c.decodeIfPresent(Bool.self, forKey: .hapticsOn) ?? true
    }

    enum CodingKeys: String, CodingKey { case soundOn, hapticsOn }
}

// MARK: - Save blob (tmt.save.v1)

/// The full mutable game state. Every field decodes with a default so older / partial saves
/// never fail to load.
struct MintSave: Codable {
    var coins: Double
    var lifetimeCoins: Double
    var owned: [Int]              // per-tier owned counts (12 entries)
    var purchasedUpgrades: [String]
    var bullion: Double
    var tapPower: Double          // base coins per tap before global multipliers
    var lastActive: Double        // timeIntervalSince1970
    var totalTaps: Int
    var reforges: Int
    var bestCoinsPerSecond: Double
    var idleClaims: Int

    init() {
        coins = 0
        lifetimeCoins = 0
        owned = Array(repeating: 0, count: MintCatalog.producers.count)
        purchasedUpgrades = []
        bullion = 0
        tapPower = 1
        lastActive = Date().timeIntervalSince1970
        totalTaps = 0
        reforges = 0
        bestCoinsPerSecond = 0
        idleClaims = 0
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let n = MintCatalog.producers.count
        coins = MintMath.sane(try c.decodeIfPresent(Double.self, forKey: .coins) ?? 0)
        lifetimeCoins = MintMath.sane(try c.decodeIfPresent(Double.self, forKey: .lifetimeCoins) ?? 0)
        var decodedOwned = try c.decodeIfPresent([Int].self, forKey: .owned) ?? []
        if decodedOwned.count < n {
            decodedOwned.append(contentsOf: Array(repeating: 0, count: n - decodedOwned.count))
        } else if decodedOwned.count > n {
            decodedOwned = Array(decodedOwned.prefix(n))
        }
        owned = decodedOwned.map { max(0, $0) }
        purchasedUpgrades = try c.decodeIfPresent([String].self, forKey: .purchasedUpgrades) ?? []
        bullion = MintMath.sane(try c.decodeIfPresent(Double.self, forKey: .bullion) ?? 0)
        tapPower = max(1, MintMath.sane(try c.decodeIfPresent(Double.self, forKey: .tapPower) ?? 1))
        lastActive = try c.decodeIfPresent(Double.self, forKey: .lastActive) ?? Date().timeIntervalSince1970
        totalTaps = max(0, try c.decodeIfPresent(Int.self, forKey: .totalTaps) ?? 0)
        reforges = max(0, try c.decodeIfPresent(Int.self, forKey: .reforges) ?? 0)
        bestCoinsPerSecond = MintMath.sane(try c.decodeIfPresent(Double.self, forKey: .bestCoinsPerSecond) ?? 0)
        idleClaims = max(0, try c.decodeIfPresent(Int.self, forKey: .idleClaims) ?? 0)
    }

    enum CodingKeys: String, CodingKey {
        case coins, lifetimeCoins, owned, purchasedUpgrades, bullion, tapPower
        case lastActive, totalTaps, reforges, bestCoinsPerSecond, idleClaims
    }
}

// MARK: - Store

final class MintTycoonStore: ObservableObject {
    static let offlineCapSeconds: Double = 8 * 60 * 60   // 8h cap
    static let bullionPercentEach: Double = 0.02         // each Bullion = +2% global output

    @Published private(set) var save: MintSave
    @Published var settings: MintSettings
    @Published private(set) var unlocked: Set<String>
    @Published var lastUnlocked: [String] = []

    // Offline summary surfaced once on launch.
    @Published var offlineSummary: MintOfflineSummary?

    private let saveKey = "tmt.save.v1"
    private let settingsKey = "tmt.settings.v1"
    private let achievementsKey = "tmt.achievements.v1"

    private var timer: Timer?
    private var lastTick: Date = Date()
    private var sinceLastSave: Double = 0

    // Convenience accessors mirroring save fields (used by achievement closures & views).
    var coins: Double { save.coins }
    var lifetimeCoins: Double { save.lifetimeCoins }
    var bullion: Double { save.bullion }
    var tapPower: Double { save.tapPower }
    var totalTaps: Int { save.totalTaps }
    var reforges: Int { save.reforges }
    var bestCoinsPerSecond: Double { save.bestCoinsPerSecond }
    var idleClaims: Int { save.idleClaims }
    var purchasedUpgrades: [String] { save.purchasedUpgrades }

    init() {
        let d = UserDefaults.standard

        if let data = d.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode(MintSave.self, from: data) {
            save = decoded
        } else {
            save = MintSave()
        }

        if let data = d.data(forKey: settingsKey),
           let decoded = try? JSONDecoder().decode(MintSettings.self, from: data) {
            settings = decoded
        } else {
            settings = MintSettings()
        }

        if let data = d.data(forKey: achievementsKey),
           let decoded = try? JSONDecoder().decode(Set<String>.self, from: data) {
            unlocked = decoded
        } else {
            unlocked = []
        }

        creditOfflineEarnings()
        evaluateAchievements()
        startTimer()
    }

    // MARK: - Derived economy

    func owned(forTier tier: Int) -> Int {
        guard tier >= 0 && tier < save.owned.count else { return 0 }
        return save.owned[tier]
    }

    var totalProducersOwned: Int { save.owned.reduce(0, +) }

    /// Global output multiplier = product of purchased global-mult upgrades × bullion bonus.
    var globalMultiplier: Double {
        var m = 1.0
        for id in save.purchasedUpgrades {
            if case .globalMult(let f)? = MintUpgradeCatalog.def(id)?.kind { m *= f }
        }
        m *= (1.0 + save.bullion * MintTycoonStore.bullionPercentEach)
        return MintMath.sane(m)
    }

    /// Bullion-only bonus fraction (for UI display).
    var bullionBonusFraction: Double { save.bullion * MintTycoonStore.bullionPercentEach }

    /// Per-producer extra multiplier from upgrades.
    private func producerUpgradeMult(_ tier: Int) -> Double {
        var m = 1.0
        for id in save.purchasedUpgrades {
            if case .producerMult(let t, let f)? = MintUpgradeCatalog.def(id)?.kind, t == tier { m *= f }
        }
        return m
    }

    /// Output (coins/sec) of one tier given its owned count, milestones, upgrades. Excludes global.
    func tierOutput(_ tier: Int) -> Double {
        guard tier >= 0 && tier < MintCatalog.producers.count else { return 0 }
        let def = MintCatalog.producers[tier]
        let count = Double(save.owned[tier])
        if count <= 0 { return 0 }
        let milestone = MintProducerDef.milestoneMultiplier(owned: save.owned[tier])
        let upg = producerUpgradeMult(tier)
        return MintMath.sane(def.baseOutput * count * milestone * upg)
    }

    /// Output of one single additional unit of a tier (for "next unit" UI), excludes global.
    func tierUnitOutput(_ tier: Int) -> Double {
        guard tier >= 0 && tier < MintCatalog.producers.count else { return 0 }
        let def = MintCatalog.producers[tier]
        let milestone = MintProducerDef.milestoneMultiplier(owned: save.owned[tier])
        return MintMath.sane(def.baseOutput * milestone * producerUpgradeMult(tier))
    }

    /// Total coins/sec from all producers, after the global multiplier.
    var coinsPerSecond: Double {
        var base = 0.0
        for t in 0..<MintCatalog.producers.count { base += tierOutput(t) }
        return MintMath.sane(base * globalMultiplier)
    }

    /// Effective coins earned per manual tap (tap power × tap multipliers × global multiplier).
    var coinsPerTap: Double {
        var power = save.tapPower
        for id in save.purchasedUpgrades {
            switch MintUpgradeCatalog.def(id)?.kind {
            case .tapMult(let f)?: power *= f
            default: break
            }
        }
        return MintMath.sane(power * globalMultiplier)
    }

    var hasAutoBuyer: Bool {
        save.purchasedUpgrades.contains { id in
            if case .autoBuyer? = MintUpgradeCatalog.def(id)?.kind { return true }
            return false
        }
    }

    private var offlineRateMult: Double {
        var m = 1.0
        for id in save.purchasedUpgrades {
            if case .offlineBoost(let f)? = MintUpgradeCatalog.def(id)?.kind { m *= f }
        }
        return m
    }

    // MARK: - Actions

    func tap() {
        let gain = coinsPerTap
        save.coins = MintMath.sane(save.coins + gain)
        save.lifetimeCoins = MintMath.sane(save.lifetimeCoins + gain)
        save.totalTaps += 1
        if settings.hapticsOn { MintFeedback.tap() }
        evaluateAchievements()
        objectWillChange.send()
    }

    /// Max units of a tier affordable right now.
    func maxAffordable(tier: Int) -> Int {
        guard tier >= 0 && tier < MintCatalog.producers.count else { return 0 }
        let def = MintCatalog.producers[tier]
        var owned = save.owned[tier]
        var budget = save.coins
        var n = 0
        // bounded loop; geometric growth keeps this small
        while n < 100000 {
            let c = def.cost(owned: owned)
            if c <= budget {
                budget -= c
                owned += 1
                n += 1
            } else { break }
        }
        return n
    }

    @discardableResult
    func buyProducer(tier: Int, count: Int = 1) -> Bool {
        guard tier >= 0 && tier < MintCatalog.producers.count, count > 0 else { return false }
        let def = MintCatalog.producers[tier]
        let total = def.bulkCost(owned: save.owned[tier], count: count)
        guard save.coins >= total else { return false }
        save.coins = MintMath.sane(save.coins - total)
        save.owned[tier] += count
        if settings.hapticsOn { MintFeedback.buy() }
        evaluateAchievements()
        persist()
        objectWillChange.send()
        return true
    }

    func canAfford(upgrade def: MintUpgradeDef) -> Bool {
        save.coins >= def.cost && !save.purchasedUpgrades.contains(def.id)
    }

    func isPurchased(_ id: String) -> Bool { save.purchasedUpgrades.contains(id) }

    @discardableResult
    func buyUpgrade(_ def: MintUpgradeDef) -> Bool {
        guard !save.purchasedUpgrades.contains(def.id), save.coins >= def.cost else { return false }
        save.coins = MintMath.sane(save.coins - def.cost)
        save.purchasedUpgrades.append(def.id)
        // Apply permanent flat tap-power adds immediately.
        if case .tapAdd(let v) = def.kind {
            save.tapPower = MintMath.sane(save.tapPower + v)
        }
        if settings.hapticsOn { MintFeedback.success() }
        evaluateAchievements()
        persist()
        objectWillChange.send()
        return true
    }

    // MARK: - Reforge (prestige)

    /// Bullion that a reforge right now would yield: floor(sqrt(lifetimeCoins / 1e6)).
    var pendingReforgeBullion: Double {
        let v = save.lifetimeCoins / 1_000_000.0
        guard v > 0, v.isFinite else { return 0 }
        return floor(sqrt(v))
    }

    var canReforge: Bool { pendingReforgeBullion >= 1 }

    func reforge() {
        let gained = pendingReforgeBullion
        guard gained >= 1 else { return }
        save.bullion = MintMath.sane(save.bullion + gained)
        save.reforges += 1
        // Reset coins / producers / non-permanent upgrades. Keep bullion, permanent tap adds,
        // achievements. Tap-power adds are permanent; reset tapPower base back to 1 + any
        // purchased flat adds that are kept (auto-buyer & offline kept too as "permanent").
        save.coins = 0
        save.lifetimeCoins = 0
        save.owned = Array(repeating: 0, count: MintCatalog.producers.count)
        // Keep "permanent" upgrades: tapAdd (already folded into tapPower), autoBuyer, offlineBoost.
        let kept = save.purchasedUpgrades.filter { id in
            switch MintUpgradeCatalog.def(id)?.kind {
            case .tapAdd?, .autoBuyer?, .offlineBoost?: return true
            default: return false
            }
        }
        // Recompute tapPower from base 1 + kept flat adds.
        var tp = 1.0
        for id in kept {
            if case .tapAdd(let v)? = MintUpgradeCatalog.def(id)?.kind { tp += v }
        }
        save.tapPower = tp
        save.purchasedUpgrades = kept
        save.bestCoinsPerSecond = 0
        if settings.hapticsOn { MintFeedback.success() }
        evaluateAchievements()
        persist()
        objectWillChange.send()
    }

    // MARK: - Tick engine

    private func startTimer() {
        timer?.invalidate()
        lastTick = Date()
        let t = Timer(timeInterval: 0.15, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func tick() {
        let now = Date()
        let delta = max(0, now.timeIntervalSince(lastTick))
        lastTick = now

        let cps = coinsPerSecond
        if cps > 0 && delta > 0 {
            let gain = cps * delta
            save.coins = MintMath.sane(save.coins + gain)
            save.lifetimeCoins = MintMath.sane(save.lifetimeCoins + gain)
        }
        if cps > save.bestCoinsPerSecond {
            save.bestCoinsPerSecond = cps
        }

        if hasAutoBuyer { runAutoBuyer() }

        save.lastActive = now.timeIntervalSince1970
        evaluateAchievements()

        sinceLastSave += delta
        if sinceLastSave >= 2.0 {
            sinceLastSave = 0
            persist()
        }
        objectWillChange.send()
    }

    /// Auto-buyer: buys the single cheapest affordable producer per tick (gentle pace).
    private func runAutoBuyer() {
        var bestTier = -1
        var bestCost = Double.greatestFiniteMagnitude
        for t in 0..<MintCatalog.producers.count {
            let c = MintCatalog.producers[t].cost(owned: save.owned[t])
            if c <= save.coins && c < bestCost {
                bestCost = c
                bestTier = t
            }
        }
        if bestTier >= 0 {
            save.coins = MintMath.sane(save.coins - bestCost)
            save.owned[bestTier] += 1
        }
    }

    // MARK: - Offline earnings

    private func creditOfflineEarnings() {
        let now = Date().timeIntervalSince1970
        let elapsed = now - save.lastActive
        guard elapsed > 5 else {           // ignore trivial gaps
            save.lastActive = now
            return
        }
        let capped = min(elapsed, MintTycoonStore.offlineCapSeconds)
        // Use the current production rate as the offline rate (a fair, simple model).
        let rate = coinsPerSecond * offlineRateMult
        let gain = MintMath.sane(rate * capped)
        if gain > 0 {
            save.coins = MintMath.sane(save.coins + gain)
            save.lifetimeCoins = MintMath.sane(save.lifetimeCoins + gain)
            save.idleClaims += 1
            offlineSummary = MintOfflineSummary(seconds: capped, coins: gain, capped: elapsed > MintTycoonStore.offlineCapSeconds)
        }
        save.lastActive = now
        persist()
    }

    func dismissOfflineSummary() { offlineSummary = nil }

    // MARK: - Scene phase hook

    func handleBackground() {
        save.lastActive = Date().timeIntervalSince1970
        persist()
    }

    func handleForeground() {
        lastTick = Date()
    }

    // MARK: - Persistence

    func persist() {
        let d = UserDefaults.standard
        if let data = try? JSONEncoder().encode(save) {
            d.set(data, forKey: saveKey)
        }
    }

    func saveSettings() {
        if let data = try? JSONEncoder().encode(settings) {
            UserDefaults.standard.set(data, forKey: settingsKey)
        }
    }

    private func saveAchievements() {
        if let data = try? JSONEncoder().encode(unlocked) {
            UserDefaults.standard.set(data, forKey: achievementsKey)
        }
    }

    func resetProgress() {
        save = MintSave()
        unlocked = []
        lastUnlocked = []
        offlineSummary = nil
        persist()
        saveAchievements()
        lastTick = Date()
        objectWillChange.send()
    }

    // MARK: - Achievements

    func isUnlocked(_ id: String) -> Bool { unlocked.contains(id) }

    func evaluateAchievements() {
        var newly: [String] = []
        for ach in MintAchievements.all where !unlocked.contains(ach.id) {
            if ach.progress(self) >= ach.goal {
                unlocked.insert(ach.id)
                newly.append(ach.id)
            }
        }
        if !newly.isEmpty {
            lastUnlocked.append(contentsOf: newly)
            saveAchievements()
        }
    }

    var unlockedCount: Int { unlocked.count }
}

// MARK: - Offline summary value

struct MintOfflineSummary {
    let seconds: Double
    let coins: Double
    let capped: Bool

    var durationText: String {
        let s = Int(seconds)
        let h = s / 3600
        let m = (s % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        if m > 0 { return "\(m)m" }
        return "\(s)s"
    }
}

// MARK: - Haptics

enum MintFeedback {
    static func tap() {
        let gen = UIImpactFeedbackGenerator(style: .light)
        gen.impactOccurred()
    }
    static func buy() {
        let gen = UIImpactFeedbackGenerator(style: .rigid)
        gen.impactOccurred()
    }
    static func success() {
        let gen = UINotificationFeedbackGenerator()
        gen.notificationOccurred(.success)
    }
}
