import Foundation

// MARK: - Deterministic PRNG (splitmix64) for events & hire pool
struct SeededRNG {
    var state: UInt64
    init(_ seed: UInt64) { state = seed }
    mutating func next() -> UInt64 {
        state = state &+ 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
    mutating func double() -> Double { Double(next() >> 11) * (1.0 / 9007199254740992.0) }
    mutating func int(_ range: Range<Int>) -> Int {
        let span = UInt64(range.upperBound - range.lowerBound)
        return range.lowerBound + Int(next() % span)
    }
}

// MARK: - Facility economics
enum FacilityEcon {
    static let maxTier = 4
    static let maxLevel = 5

    // Base upgrade/build cost grows with tier and level.
    static func upgradeCost(kind: FacilityKind, tier: Int, level: Int) -> Double {
        let base = baseCost(kind)
        let tierMul = pow(2.4, Double(tier - 1))
        let levelMul = pow(1.55, Double(level - 1))
        return (base * tierMul * levelMul).rounded()
    }

    static func baseCost(_ kind: FacilityKind) -> Double {
        switch kind {
        case .terminal: return 380_000
        case .runway: return 620_000
        case .lounge: return 260_000
        case .retail: return 220_000
        case .hotel: return 300_000
        case .cargo: return 340_000
        case .hangar: return 360_000
        case .fuel: return 320_000
        }
    }

    // The "power" of a facility scales with tier*level.
    static func power(tier: Int, level: Int) -> Double {
        Double(tier) * (1.0 + 0.4 * Double(level - 1))
    }

    // Weekly upkeep rises with tier and level (rising upkeep).
    static func upkeep(kind: FacilityKind, tier: Int, level: Int) -> Double {
        let base = baseCost(kind) * 0.014
        return (base * power(tier: tier, level: level) * 1.15).rounded()
    }

    // Passenger capacity (terminal). Total weekly pax slots.
    static func terminalCapacity(tier: Int, level: Int) -> Double {
        220_000 * power(tier: tier, level: level)
    }
    // Flight cycles per route per week derived from runway.
    static func runwayCycles(tier: Int, level: Int) -> Int {
        2 + tier + (level - 1)        // tier1/lvl1 -> 3 ... tier4/lvl5 -> 10
    }
    // Lounge weekly premium revenue base.
    static func loungeBase(tier: Int, level: Int) -> Double {
        18_000 * power(tier: tier, level: level)
    }
    // Retail concession per 1000 passengers.
    static func retailPerK(tier: Int, level: Int) -> Double {
        260 * power(tier: tier, level: level)
    }
    // Hotel weekly base revenue.
    static func hotelBase(tier: Int, level: Int) -> Double {
        14_000 * power(tier: tier, level: level)
    }
    // Cargo capacity multiplier.
    static func cargoMult(tier: Int, level: Int) -> Double {
        0.6 + 0.5 * power(tier: tier, level: level)
    }
    // Hangar reduces wear & maintenance cost (fraction 0..~0.5).
    static func hangarWearReduction(tier: Int, level: Int) -> Double {
        min(0.55, 0.06 * power(tier: tier, level: level))
    }
    // Fuel farm reduces fuel cost (fraction 0..~0.4).
    static func fuelDiscount(tier: Int, level: Int) -> Double {
        min(0.42, 0.045 * power(tier: tier, level: level))
    }
}

// MARK: - Pricing / demand curve
enum DemandCurve {
    // Reference fares per class as a function of distance.
    static func referenceFare(_ cls: TravelClass, distanceKm: Int) -> Double {
        let d = Double(distanceKm)
        let base: Double
        switch cls {
        case .economy:  base = 38 + d * 0.052
        case .business: base = 140 + d * 0.165
        case .first:    base = 320 + d * 0.34
        }
        return base
    }

    /// Load factor (0..1) given the price vs reference. Higher price -> lower load.
    /// Smooth, never negative, never > ~0.99.
    static func loadFactor(price: Double, reference: Double, competition: Double, satisfaction: Double, demandBoost: Double) -> Double {
        guard reference > 0 else { return 0 }
        let ratio = max(0.2, price / reference)
        // logistic-ish elasticity around ratio=1
        let elasticity = 2.2
        let raw = 1.0 / (1.0 + pow(ratio, elasticity))   // 0..1, =0.5 at ratio 1
        // map raw (0..1, 0.5 mid) to a fuller load band
        var lf = raw * 1.7
        // competition pushes load down, satisfaction & marketing push up
        lf *= (1.0 - competition * 0.45)
        lf *= (0.7 + satisfaction * 0.5)
        lf *= demandBoost
        return min(0.99, max(0.0, lf))
    }

    /// Seasonal demand multiplier for a given week.
    static func seasonal(amp: Double, phase: Double, week: Int) -> Double {
        let t = (Double(week) + phase) / 52.0 * 2.0 * Double.pi
        return 1.0 + amp * sin(t)
    }
}
