import Foundation

// MARK: - Owned / mutable entities (Codable)

struct OwnedFacility: Codable {
    var kind: FacilityKind
    var tier: Int    // 1..4
    var level: Int   // 1..5
}

struct OwnedAircraft: Codable, Identifiable {
    var id: UUID = UUID()
    var modelID: String
    var leased: Bool
    var wear: Double          // 0..100
    var routeID: String?      // assigned route id (nil = idle)
    var name: String
}

struct OwnedRoute: Codable, Identifiable {
    var id: String { cityID }
    var cityID: String
    var priceEco: Double
    var priceBus: Double
    var priceFst: Double
}

struct OwnedStaff: Codable, Identifiable {
    var id: UUID = UUID()
    var role: StaffRole
    var rarity: Rarity
    var name: String
    var salary: Double
}

struct ResearchProgress: Codable {
    var nodeID: String
    var weeksDone: Int
}

struct HirePoolEntry: Codable, Identifiable {
    var id: UUID = UUID()
    var role: StaffRole
    var rarity: Rarity
    var name: String
    var salary: Double
    var signingFee: Double
}

struct NewsItem: Codable, Identifiable {
    var id: UUID = UUID()
    var week: Int
    var text: String
    var positive: Bool
}

struct ActiveMods: Codable {
    var fuelMult: Double = 1.0
    var loadMult: Double = 1.0
    var demandMult: Double = 1.0
    var salaryMult: Double = 1.0
    var premiumMult: Double = 1.0
    var cargoMult: Double = 1.0
    var yieldMult: Double = 1.0
    var weeksLeft: Int = 0

    mutating func reset() {
        fuelMult = 1; loadMult = 1; demandMult = 1; salaryMult = 1
        premiumMult = 1; cargoMult = 1; yieldMult = 1; weeksLeft = 0
    }
}

// One week's financial result
struct WeekResult: Codable {
    var week: Int = 0
    var passengers: Int = 0
    var ticketRevenue: Double = 0
    var cargoRevenue: Double = 0
    var loungeRevenue: Double = 0
    var concessionRevenue: Double = 0
    var hotelRevenue: Double = 0
    var fuelCost: Double = 0
    var landingCrewCost: Double = 0
    var maintenanceCost: Double = 0
    var salaryCost: Double = 0
    var upkeepCost: Double = 0
    var interestCost: Double = 0
    var net: Double = 0
    var avgLoad: Double = 0
    var prestigeGained: Double = 0

    var totalRevenue: Double { ticketRevenue + cargoRevenue + loungeRevenue + concessionRevenue + hotelRevenue }
    var totalExpense: Double { fuelCost + landingCrewCost + maintenanceCost + salaryCost + upkeepCost + interestCost }
}

struct HistoryPoint: Codable {
    var week: Int
    var revenue: Double
    var expense: Double
}

// MARK: - The whole game state (single Codable blob)
struct GameState: Codable {
    var version: Int = 1
    var week: Int = 1
    var cash: Double = 6_000_000
    var debt: Double = 0
    var prestige: Double = 0
    var satisfaction: Double = 0.75

    var facilities: [OwnedFacility] = []
    var fleet: [OwnedAircraft] = []
    var routes: [OwnedRoute] = []
    var staff: [OwnedStaff] = []

    var completedResearch: [String] = []
    var researchInProgress: ResearchProgress? = nil

    var hirePool: [HirePoolEntry] = []
    var news: [NewsItem] = []

    var activeMods: ActiveMods = ActiveMods()

    var lastResult: WeekResult = WeekResult()
    var history: [HistoryPoint] = []

    var completedContracts: [String] = []
    var unlockedAchievements: [String] = []

    // lifetime stat tracking
    var facilitiesUpgradedCount: Int = 0
    var staffHiredCount: Int = 0
    var totalProfit: Double = 0
    var peakWeeklyPassengers: Int = 0
    var peakWeeklyRevenue: Double = 0
    var peakCargoRevenue: Double = 0
    var peakLoungeRevenue: Double = 0
    var hasSeenOnboarding: Bool = false

    var hireRefreshWeek: Int = 0

    // settings
    var soundOn: Bool = true
    var hapticsOn: Bool = true

    // pending event for the upcoming week (chosen on tick screen)
    var pendingEventID: String? = nil
    var rngSeed: UInt64 = 0x9E3779B97F4A7C15

    // MARK: helpers
    func facility(_ kind: FacilityKind) -> OwnedFacility {
        facilities.first { $0.kind == kind } ?? OwnedFacility(kind: kind, tier: 1, level: 1)
    }
    var rankIndex: Int { PrestigeCatalog.rankIndex(for: prestige) }
}
