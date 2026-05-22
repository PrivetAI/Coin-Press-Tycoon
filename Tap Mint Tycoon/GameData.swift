import SwiftUI

// MARK: - Producer definitions (static catalog; runtime state lives in the Store)

/// One of the 12 mint-producer tiers. Pure definition — owned count & purchases are tracked
/// separately so the catalog stays immutable.
struct MintProducerDef: Identifiable {
    let id: Int
    let name: String
    let blurb: String
    let baseCost: Double      // cost of the FIRST unit
    let costGrowth: Double    // multiplied into cost per unit owned (~1.15)
    let baseOutput: Double    // coins/sec produced by ONE unit at no milestones

    /// Cost to buy the `owned+1`-th unit (i.e. the next purchase) given current owned count.
    func cost(owned: Int) -> Double {
        MintMath.sane(baseCost * pow(costGrowth, Double(max(0, owned))))
    }

    /// Total cost to buy `count` units starting from `owned` (geometric series sum).
    func bulkCost(owned: Int, count: Int) -> Double {
        guard count > 0 else { return 0 }
        let r = costGrowth
        let first = baseCost * pow(r, Double(max(0, owned)))
        // sum = first * (r^count - 1) / (r - 1)
        let sum = first * (pow(r, Double(count)) - 1) / (r - 1)
        return MintMath.sane(sum)
    }

    /// Milestone multiplier from owning `owned` units. Every 25 / 50 / 100 / 200 owned doubles
    /// output cumulatively (so a producer at 200+ is hugely boosted).
    static func milestoneMultiplier(owned: Int) -> Double {
        var m = 1.0
        let thresholds = [25, 50, 100, 200, 300, 400, 500, 750, 1000]
        for t in thresholds where owned >= t { m *= 2.0 }
        return m
    }

    /// Next milestone threshold not yet reached (for UI), or nil if all passed.
    static func nextMilestone(owned: Int) -> Int? {
        let thresholds = [25, 50, 100, 200, 300, 400, 500, 750, 1000]
        return thresholds.first(where: { $0 > owned })
    }
}

enum MintCatalog {
    /// 12 tiers. Costs and outputs scale geometrically so late tiers dominate the economy.
    static let producers: [MintProducerDef] = [
        MintProducerDef(id: 0,  name: "Hand Stamp",      blurb: "A single hand-cranked coin stamp.",        baseCost: 15,        costGrowth: 1.15, baseOutput: 0.2),
        MintProducerDef(id: 1,  name: "Coin Press",      blurb: "A small lever press for blanks.",          baseCost: 120,       costGrowth: 1.15, baseOutput: 1.2),
        MintProducerDef(id: 2,  name: "Roller Mill",     blurb: "Rolls metal sheets into strips.",          baseCost: 1_300,     costGrowth: 1.15, baseOutput: 7.0),
        MintProducerDef(id: 3,  name: "Blanking Line",   blurb: "Punches blanks from the strip.",           baseCost: 14_000,    costGrowth: 1.15, baseOutput: 40.0),
        MintProducerDef(id: 4,  name: "Annealer",        blurb: "Softens blanks for crisp strikes.",        baseCost: 200_000,   costGrowth: 1.15, baseOutput: 240.0),
        MintProducerDef(id: 5,  name: "Upset Mill",      blurb: "Raises the rim of every blank.",           baseCost: 3_300_000, costGrowth: 1.15, baseOutput: 1_500.0),
        MintProducerDef(id: 6,  name: "Striking Press",  blurb: "Hammers the design home.",                 baseCost: 52_000_000,    costGrowth: 1.15, baseOutput: 9_500.0),
        MintProducerDef(id: 7,  name: "Auto Inspector",  blurb: "Sorts flawless coins at speed.",           baseCost: 850_000_000,   costGrowth: 1.15, baseOutput: 62_000.0),
        MintProducerDef(id: 8,  name: "Plating Bath",    blurb: "Electroplates a gleaming finish.",         baseCost: 14_000_000_000,    costGrowth: 1.15, baseOutput: 420_000.0),
        MintProducerDef(id: 9,  name: "Vault Conveyor",  blurb: "Ferries coin towers to the vault.",        baseCost: 240_000_000_000,   costGrowth: 1.15, baseOutput: 2_800_000.0),
        MintProducerDef(id: 10, name: "Robotic Cell",    blurb: "A lights-out robotic mint cell.",          baseCost: 4_200_000_000_000, costGrowth: 1.15, baseOutput: 19_000_000.0),
        MintProducerDef(id: 11, name: "Quantum Foundry", blurb: "Mints coin from raw possibility.",         baseCost: 78_000_000_000_000, costGrowth: 1.15, baseOutput: 130_000_000.0),
    ]
}

// MARK: - Upgrades (one-time purchases with clear effects)

enum MintUpgradeKind {
    case globalMult(Double)         // multiply ALL coin output by factor (stacks multiplicatively)
    case tapAdd(Double)             // add flat coins to tap power
    case tapMult(Double)            // multiply tap power
    case producerMult(Int, Double)  // multiply one producer tier's output
    case autoBuyer                  // unlock the auto-buyer
    case offlineBoost(Double)       // extend/boost offline earnings cap multiplier
}

struct MintUpgradeDef: Identifiable {
    let id: String
    let name: String
    let blurb: String
    let cost: Double          // coin cost (one-time)
    let kind: MintUpgradeKind
    let category: MintUpgradeCategory
}

enum MintUpgradeCategory {
    case tap, global, producer, special
}

enum MintUpgradeCatalog {
    static let all: [MintUpgradeDef] = [
        // Tap power
        MintUpgradeDef(id: "tap_steel",   name: "Steel Dies",        blurb: "Each tap mints +2 coins.",            cost: 250,        kind: .tapAdd(2),          category: .tap),
        MintUpgradeDef(id: "tap_double",  name: "Twin Hammers",      blurb: "Double your tap power.",              cost: 6_000,      kind: .tapMult(2),         category: .tap),
        MintUpgradeDef(id: "tap_carbide", name: "Carbide Tooling",   blurb: "Each tap mints +25 coins.",           cost: 90_000,     kind: .tapAdd(25),         category: .tap),
        MintUpgradeDef(id: "tap_triple",  name: "Triple Strike",     blurb: "Triple your tap power.",              cost: 2_500_000,  kind: .tapMult(3),         category: .tap),
        MintUpgradeDef(id: "tap_laser",   name: "Laser Engraver",    blurb: "Each tap mints +500 coins.",          cost: 60_000_000, kind: .tapAdd(500),        category: .tap),
        MintUpgradeDef(id: "tap_x5",      name: "Master Striker",    blurb: "×5 tap power.",                       cost: 5_000_000_000, kind: .tapMult(5),      category: .tap),

        // Global multipliers
        MintUpgradeDef(id: "glob_polish",  name: "Quality Polish",   blurb: "+25% to all coin output.",            cost: 4_000,       kind: .globalMult(1.25), category: .global),
        MintUpgradeDef(id: "glob_oil",     name: "Machine Oiling",   blurb: "+50% to all coin output.",            cost: 120_000,     kind: .globalMult(1.5),  category: .global),
        MintUpgradeDef(id: "glob_shift",   name: "Night Shift",      blurb: "Double all coin output.",             cost: 8_000_000,   kind: .globalMult(2.0),  category: .global),
        MintUpgradeDef(id: "glob_logistic",name: "Smart Logistics",  blurb: "+75% to all coin output.",            cost: 400_000_000, kind: .globalMult(1.75), category: .global),
        MintUpgradeDef(id: "glob_empire",  name: "Mint Empire",      blurb: "Triple all coin output.",             cost: 30_000_000_000, kind: .globalMult(3.0), category: .global),
        MintUpgradeDef(id: "glob_dynasty", name: "Coin Dynasty",     blurb: "×4 to all coin output.",              cost: 1_500_000_000_000, kind: .globalMult(4.0), category: .global),

        // Per-producer boosts (early tiers, big payoff)
        MintUpgradeDef(id: "prod_stamp",   name: "Reinforced Stamps", blurb: "Hand Stamps produce ×3.",            cost: 1_500,       kind: .producerMult(0, 3),  category: .producer),
        MintUpgradeDef(id: "prod_press",   name: "Quick Presses",     blurb: "Coin Presses produce ×3.",           cost: 30_000,      kind: .producerMult(1, 3),  category: .producer),
        MintUpgradeDef(id: "prod_roller",  name: "Hardened Rollers",  blurb: "Roller Mills produce ×3.",           cost: 600_000,     kind: .producerMult(2, 3),  category: .producer),
        MintUpgradeDef(id: "prod_blank",   name: "Twin Punches",      blurb: "Blanking Lines produce ×3.",         cost: 12_000_000,  kind: .producerMult(3, 3),  category: .producer),
        MintUpgradeDef(id: "prod_strike",  name: "Tandem Presses",    blurb: "Striking Presses produce ×3.",       cost: 4_000_000_000, kind: .producerMult(6, 3), category: .producer),

        // Special
        MintUpgradeDef(id: "spec_autobuy", name: "Auto-Buyer",        blurb: "Auto-buys the cheapest affordable producer.", cost: 500_000, kind: .autoBuyer, category: .special),
        MintUpgradeDef(id: "spec_offline", name: "Night Watch",       blurb: "Offline earnings run at +50% rate.",  cost: 25_000_000,  kind: .offlineBoost(1.5), category: .special),
    ]

    static func def(_ id: String) -> MintUpgradeDef? { all.first { $0.id == id } }
}

// MARK: - Achievements

struct MintAchievementDef: Identifiable {
    let id: String
    let title: String
    let detail: String
    let goal: Double
    let progress: (MintTycoonStore) -> Double
}

enum MintAchievements {
    static let all: [MintAchievementDef] = [
        // Coin totals (lifetime)
        MintAchievementDef(id: "coin_1k",  title: "First Roll",     detail: "Mint 1K coins total.",    goal: 1_000)       { $0.lifetimeCoins },
        MintAchievementDef(id: "coin_100k",title: "Pocket Change",  detail: "Mint 100K coins total.",  goal: 100_000)     { $0.lifetimeCoins },
        MintAchievementDef(id: "coin_10m", title: "Coin Counter",   detail: "Mint 10M coins total.",   goal: 10_000_000)  { $0.lifetimeCoins },
        MintAchievementDef(id: "coin_1b",  title: "Billionaire",    detail: "Mint 1B coins total.",    goal: 1_000_000_000) { $0.lifetimeCoins },
        MintAchievementDef(id: "coin_1t",  title: "Treasury",       detail: "Mint 1T coins total.",    goal: 1_000_000_000_000) { $0.lifetimeCoins },
        MintAchievementDef(id: "coin_1e15",title: "Mint Magnate",   detail: "Mint 1Qa coins total.",   goal: 1e15)        { $0.lifetimeCoins },

        // Tap counts
        MintAchievementDef(id: "tap_100",  title: "Warm Up",        detail: "Tap the press 100 times.",   goal: 100)    { Double($0.totalTaps) },
        MintAchievementDef(id: "tap_1k",   title: "Busy Hands",     detail: "Tap the press 1,000 times.", goal: 1_000)  { Double($0.totalTaps) },
        MintAchievementDef(id: "tap_10k",  title: "Iron Thumb",     detail: "Tap the press 10,000 times.",goal: 10_000) { Double($0.totalTaps) },

        // Producers owned (total across all tiers)
        MintAchievementDef(id: "prod_10",  title: "Small Floor",    detail: "Own 10 producers.",   goal: 10)   { Double($0.totalProducersOwned) },
        MintAchievementDef(id: "prod_50",  title: "Busy Floor",     detail: "Own 50 producers.",   goal: 50)   { Double($0.totalProducersOwned) },
        MintAchievementDef(id: "prod_200", title: "Full Factory",   detail: "Own 200 producers.",  goal: 200)  { Double($0.totalProducersOwned) },
        MintAchievementDef(id: "prod_500", title: "Mint Complex",   detail: "Own 500 producers.",  goal: 500)  { Double($0.totalProducersOwned) },

        // Specific tier ownership
        MintAchievementDef(id: "tier_press", title: "Press Gang",   detail: "Own 25 Coin Presses.", goal: 25) { Double($0.owned(forTier: 1)) },
        MintAchievementDef(id: "tier_strike",title: "On the Money", detail: "Own 25 Striking Presses.", goal: 25) { Double($0.owned(forTier: 6)) },
        MintAchievementDef(id: "tier_quantum",title: "Reality Mint",detail: "Own a Quantum Foundry.", goal: 1) { Double($0.owned(forTier: 11)) },

        // Rate
        MintAchievementDef(id: "rate_1k",  title: "Steady Flow",    detail: "Reach 1K coins/sec.",  goal: 1_000)     { $0.bestCoinsPerSecond },
        MintAchievementDef(id: "rate_1m",  title: "Gushing Mint",   detail: "Reach 1M coins/sec.",  goal: 1_000_000) { $0.bestCoinsPerSecond },
        MintAchievementDef(id: "rate_1b",  title: "Coin Torrent",   detail: "Reach 1B coins/sec.",  goal: 1_000_000_000) { $0.bestCoinsPerSecond },

        // Reforge / bullion
        MintAchievementDef(id: "reforge_1", title: "First Reforge", detail: "Reforge once.",        goal: 1)   { Double($0.reforges) },
        MintAchievementDef(id: "reforge_5", title: "Reborn",        detail: "Reforge 5 times.",     goal: 5)   { Double($0.reforges) },
        MintAchievementDef(id: "bull_10",   title: "Bullion Stash", detail: "Hold 10 Bullion.",     goal: 10)  { $0.bullion },
        MintAchievementDef(id: "bull_100",  title: "Bullion Baron", detail: "Hold 100 Bullion.",    goal: 100) { $0.bullion },

        // Upgrades & idle
        MintAchievementDef(id: "up_5",     title: "Tinkerer",       detail: "Buy 5 upgrades.",      goal: 5)   { Double($0.purchasedUpgrades.count) },
        MintAchievementDef(id: "up_all",   title: "Fully Equipped", detail: "Buy every upgrade.",   goal: Double(MintUpgradeCatalog.all.count)) { Double($0.purchasedUpgrades.count) },
        MintAchievementDef(id: "idle_1",   title: "Welcome Back",   detail: "Claim offline earnings once.", goal: 1) { Double($0.idleClaims) },
    ]

    static func def(_ id: String) -> MintAchievementDef? { all.first { $0.id == id } }
}
