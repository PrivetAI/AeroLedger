import Foundation

// Aggregated staff & research bonuses used by the tick.
struct Bonuses {
    var loadBoost: Double = 1.0        // from cabin/marketers + research
    var onTime: Double = 1.0           // pilots -> reduces effective delay loss
    var throughput: Double = 1.0       // ground crew -> capacity
    var maintCostMult: Double = 1.0    // engineers/research -> lower maintenance
    var fuelMult: Double = 1.0         // research -> fuel
    var satisfactionBoost: Double = 0  // cabin -> satisfaction drift
    var demandReach: Double = 1.0      // marketers/research -> demand
    var upkeepMult: Double = 1.0       // managers/research -> upkeep
    var premiumMult: Double = 1.0      // research premium services
    var cargoMult: Double = 1.0
    var wearMult: Double = 1.0
    var capacityMult: Double = 1.0     // research hub
}

enum BonusEngine {
    static func compute(_ s: GameState) -> Bonuses {
        var b = Bonuses()

        // Staff stacking: each staff contributes a small % scaled by rarity.
        for st in s.staff {
            let m = st.rarity.multiplier
            switch st.role {
            case .pilot:    b.onTime += 0.010 * m
            case .cabin:    b.loadBoost += 0.006 * m; b.satisfactionBoost += 0.0015 * m
            case .ground:   b.throughput += 0.012 * m
            case .engineer: b.maintCostMult -= 0.012 * m
            case .manager:  b.upkeepMult -= 0.010 * m
            case .marketer: b.demandReach += 0.010 * m
            }
        }
        b.maintCostMult = max(0.4, b.maintCostMult)
        b.upkeepMult = max(0.45, b.upkeepMult)
        b.onTime = min(1.25, b.onTime)

        // Research effects
        let r = Set(s.completedResearch)
        if r.contains("r_ops") { b.upkeepMult *= 0.94 }
        if r.contains("r_fuel1") { b.fuelMult *= 0.92 }
        if r.contains("r_premium") { b.premiumMult *= 1.12 }
        if r.contains("r_fuel2") { b.fuelMult *= 0.90 }
        if r.contains("r_marketing") { b.demandReach *= 1.08 }
        if r.contains("r_maint") { b.wearMult *= 0.85 }
        if r.contains("r_cargo") { b.cargoMult *= 1.20 }
        if r.contains("r_loyalty") { b.demandReach *= 1.06; b.satisfactionBoost += 0.004 }
        if r.contains("r_alliance") { b.premiumMult *= 1.10 }
        if r.contains("r_efficiency") { b.fuelMult *= 0.88 }
        if r.contains("r_hub") { b.capacityMult *= 1.15 }

        return b
    }

    // Runway tier available, including research gating for tiers 3 and 4.
    static func maxRunwayTier(_ s: GameState) -> Int {
        var t = s.facility(.runway).tier
        let r = Set(s.completedResearch)
        if t >= 3 && !r.contains("r_runway") { t = 2 }
        if t >= 4 && !r.contains("r_widebody") { t = min(t, r.contains("r_runway") ? 3 : 2) }
        return t
    }

    // Extra weekly flight cycles from automation research.
    static func bonusCycles(_ s: GameState) -> Int {
        s.completedResearch.contains("r_automation") ? 1 : 0
    }
}
