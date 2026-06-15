import Foundation

// MARK: - Enums

enum TravelClass: String, Codable, CaseIterable, Identifiable {
    case economy, business, first
    var id: String { rawValue }
    var label: String {
        switch self {
        case .economy: return "Economy"
        case .business: return "Business"
        case .first: return "First"
        }
    }
    var short: String {
        switch self {
        case .economy: return "ECO"
        case .business: return "BUS"
        case .first: return "FST"
        }
    }
}

enum AircraftClass: String, Codable, CaseIterable {
    case regional, narrowbody, widebody
    var label: String {
        switch self {
        case .regional: return "Regional"
        case .narrowbody: return "Narrowbody"
        case .widebody: return "Widebody"
        }
    }
}

enum Rarity: String, Codable, CaseIterable {
    case rookie, pro, veteran
    var label: String {
        switch self {
        case .rookie: return "Rookie"
        case .pro: return "Pro"
        case .veteran: return "Veteran"
        }
    }
    var multiplier: Double {
        switch self {
        case .rookie: return 1.0
        case .pro: return 1.8
        case .veteran: return 3.0
        }
    }
}

enum StaffRole: String, Codable, CaseIterable {
    case pilot, cabin, ground, engineer, manager, marketer
    var label: String {
        switch self {
        case .pilot: return "Pilots"
        case .cabin: return "Cabin Crew"
        case .ground: return "Ground Crew"
        case .engineer: return "Engineers"
        case .manager: return "Managers"
        case .marketer: return "Marketers"
        }
    }
    var effect: String {
        switch self {
        case .pilot: return "On-time %"
        case .cabin: return "Satisfaction"
        case .ground: return "Throughput"
        case .engineer: return "Maint. cost"
        case .manager: return "All upkeep"
        case .marketer: return "Demand reach"
        }
    }
}

enum FacilityKind: String, Codable, CaseIterable {
    case terminal, runway, lounge, retail, hotel, cargo, hangar, fuel
    var label: String {
        switch self {
        case .terminal: return "Terminals & Gates"
        case .runway: return "Runways"
        case .lounge: return "Lounges"
        case .retail: return "Retail & Duty-Free"
        case .hotel: return "Hotels"
        case .cargo: return "Cargo Depots"
        case .hangar: return "Maintenance Hangars"
        case .fuel: return "Fuel Farms"
        }
    }
    var blurb: String {
        switch self {
        case .terminal: return "Passenger capacity"
        case .runway: return "Flight throughput + larger aircraft"
        case .lounge: return "Premium revenue per week"
        case .retail: return "Concession income per passenger"
        case .hotel: return "Lodging revenue from layovers"
        case .cargo: return "Cargo handling revenue"
        case .hangar: return "Reduces fleet wear & maintenance"
        case .fuel: return "Reduces fuel cost"
        }
    }
}

// MARK: - Catalog structs (static definitions)

struct AircraftModel: Identifiable {
    let id: String
    let name: String
    let cls: AircraftClass
    let seatsEco: Int
    let seatsBus: Int
    let seatsFst: Int
    let rangeKm: Int
    let fuelBurn: Double      // per 1000km cost units per flight
    let purchaseCost: Double
    let leaseWeekly: Double
    let wearRate: Double      // wear per flight
    let minRunwayTier: Int    // 1-4 runway tier required
    var totalSeats: Int { seatsEco + seatsBus + seatsFst }
}

struct CityDef: Identifiable {
    let id: String
    let name: String
    let code: String          // 3-letter
    let x: Double             // 0..1 map position
    let y: Double
    let distanceKm: Int
    let baseDemand: Int        // weekly base passengers potential
    let demandEco: Double      // share weight
    let demandBus: Double
    let demandFst: Double
    let seasonAmp: Double      // seasonal swing amplitude 0..1
    let seasonPhase: Double    // phase offset (weeks)
    let competition: Double    // 0..1 (higher = tougher)
    let cargoFactor: Double    // cargo demand factor
    let minPrestige: Int       // prestige rank index required (0-5)
}

struct ResearchNodeDef: Identifiable {
    let id: String
    let name: String
    let desc: String
    let cost: Double
    let weeks: Int
    let prereqs: [String]
    let col: Int
    let row: Int
}

struct ContractDef: Identifiable {
    let id: String
    let title: String
    let detail: String
    let reward: Double
    let metric: ContractMetric
    let target: Double
}

enum ContractMetric: String, Codable {
    case weeklyPassengers, totalRoutes, intercontinentalRoutes, cash, fleetSize
    case prestige, weeksPlayed, totalProfit, facilitiesUpgraded, satisfaction
    case staffHired, researchDone, cargoRevenue, loungeRevenue, weeklyRevenue
}

struct AchievementDef: Identifiable {
    let id: String
    let title: String
    let desc: String
    let metric: ContractMetric
    let target: Double
}

struct PrestigeRank {
    let name: String
    let threshold: Double      // cumulative prestige points
}
