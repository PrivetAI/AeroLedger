import Foundation

// MARK: - Research node graph (14 nodes, acyclic, prereq-gated)
enum ResearchCatalog {
    static let nodes: [ResearchNodeDef] = [
        ResearchNodeDef(id: "r_ops", name: "Operations Office", desc: "Cuts all facility upkeep by 6%.",
                        cost: 250_000, weeks: 2, prereqs: [], col: 0, row: 1),
        ResearchNodeDef(id: "r_fuel1", name: "Fuel Logistics", desc: "Reduces fuel cost by 8%.",
                        cost: 400_000, weeks: 2, prereqs: ["r_ops"], col: 1, row: 0),
        ResearchNodeDef(id: "r_runway", name: "Runway Engineering", desc: "Unlocks tier-3 runway upgrades.",
                        cost: 650_000, weeks: 3, prereqs: ["r_ops"], col: 1, row: 2),
        ResearchNodeDef(id: "r_premium", name: "Premium Services", desc: "Boosts lounge & first-class revenue 12%.",
                        cost: 700_000, weeks: 3, prereqs: ["r_ops"], col: 1, row: 3),
        ResearchNodeDef(id: "r_fuel2", name: "Synthetic Fuel", desc: "Reduces fuel cost a further 10%.",
                        cost: 1_200_000, weeks: 4, prereqs: ["r_fuel1"], col: 2, row: 0),
        ResearchNodeDef(id: "r_widebody", name: "Widebody Support", desc: "Unlocks tier-4 runways for widebodies.",
                        cost: 1_800_000, weeks: 4, prereqs: ["r_runway"], col: 2, row: 2),
        ResearchNodeDef(id: "r_marketing", name: "Marketing Reach", desc: "Raises demand on all routes by 8%.",
                        cost: 900_000, weeks: 3, prereqs: ["r_premium"], col: 2, row: 3),
        ResearchNodeDef(id: "r_maint", name: "Predictive Maint.", desc: "Cuts fleet wear by 15%.",
                        cost: 1_100_000, weeks: 3, prereqs: ["r_runway"], col: 2, row: 1),
        ResearchNodeDef(id: "r_cargo", name: "Cargo Network", desc: "Boosts cargo revenue 20%.",
                        cost: 1_500_000, weeks: 4, prereqs: ["r_fuel2"], col: 3, row: 0),
        ResearchNodeDef(id: "r_loyalty", name: "Loyalty Program", desc: "Raises satisfaction floor & demand 6%.",
                        cost: 1_700_000, weeks: 4, prereqs: ["r_marketing"], col: 3, row: 3),
        ResearchNodeDef(id: "r_automation", name: "Smart Scheduling", desc: "Adds +1 weekly flight cycle per route.",
                        cost: 2_400_000, weeks: 5, prereqs: ["r_maint", "r_widebody"], col: 3, row: 1),
        ResearchNodeDef(id: "r_alliance", name: "Global Alliance", desc: "Unlocks partner routes & +10% premium demand.",
                        cost: 3_200_000, weeks: 5, prereqs: ["r_loyalty"], col: 4, row: 3),
        ResearchNodeDef(id: "r_efficiency", name: "Green Efficiency", desc: "Cuts fuel & landing fees 12%.",
                        cost: 4_000_000, weeks: 6, prereqs: ["r_cargo", "r_automation"], col: 4, row: 0),
        ResearchNodeDef(id: "r_hub", name: "Mega Hub Control", desc: "Raises all route capacity 15%.",
                        cost: 6_000_000, weeks: 7, prereqs: ["r_efficiency", "r_alliance"], col: 5, row: 1),
    ]
    static func node(_ id: String) -> ResearchNodeDef? { nodes.first { $0.id == id } }
}

// MARK: - Prestige ranks (6)
enum PrestigeCatalog {
    static let ranks: [PrestigeRank] = [
        PrestigeRank(name: "Local Airfield", threshold: 0),
        PrestigeRank(name: "Regional Hub", threshold: 1_200),
        PrestigeRank(name: "National Gateway", threshold: 5_000),
        PrestigeRank(name: "Continental Port", threshold: 16_000),
        PrestigeRank(name: "International Hub", threshold: 45_000),
        PrestigeRank(name: "Global Sky Harbor", threshold: 110_000),
    ]
    static func rankIndex(for points: Double) -> Int {
        var idx = 0
        for (i, r) in ranks.enumerated() where points >= r.threshold { idx = i }
        return idx
    }
}

// MARK: - Contracts / milestones (20)
enum ContractCatalog {
    static let contracts: [ContractDef] = [
        ContractDef(id: "ct_1", title: "First Departures", detail: "Open your first 2 routes.", reward: 200_000, metric: .totalRoutes, target: 2),
        ContractDef(id: "ct_2", title: "Growing Roster", detail: "Own or lease 4 aircraft.", reward: 250_000, metric: .fleetSize, target: 4),
        ContractDef(id: "ct_3", title: "Busy Season", detail: "Carry 100K passengers in one week.", reward: 350_000, metric: .weeklyPassengers, target: 100_000),
        ContractDef(id: "ct_4", title: "Build Up", detail: "Complete 6 facility upgrades.", reward: 300_000, metric: .facilitiesUpgraded, target: 6),
        ContractDef(id: "ct_5", title: "Network Spread", detail: "Operate 6 routes.", reward: 400_000, metric: .totalRoutes, target: 6),
        ContractDef(id: "ct_6", title: "Talent Drive", detail: "Hire 8 staff members.", reward: 350_000, metric: .staffHired, target: 8),
        ContractDef(id: "ct_7", title: "Lab Coats", detail: "Complete 3 research nodes.", reward: 500_000, metric: .researchDone, target: 3),
        ContractDef(id: "ct_8", title: "Mass Transit", detail: "Carry 250K weekly passengers.", reward: 800_000, metric: .weeklyPassengers, target: 250_000),
        ContractDef(id: "ct_9", title: "Long Haul", detail: "Open 3 intercontinental routes.", reward: 900_000, metric: .intercontinentalRoutes, target: 3),
        ContractDef(id: "ct_10", title: "Cash Cushion", detail: "Hold $10M in cash.", reward: 600_000, metric: .cash, target: 10_000_000),
        ContractDef(id: "ct_11", title: "Premium Lounge", detail: "Earn $200K lounge revenue in a week.", reward: 700_000, metric: .loungeRevenue, target: 200_000),
        ContractDef(id: "ct_12", title: "Cargo King", detail: "Earn $1M cargo revenue in a week.", reward: 900_000, metric: .cargoRevenue, target: 1_000_000),
        ContractDef(id: "ct_13", title: "Reputation Rising", detail: "Reach National Gateway prestige.", reward: 1_200_000, metric: .prestige, target: 2),
        ContractDef(id: "ct_14", title: "Big Fleet", detail: "Own or lease 12 aircraft.", reward: 1_000_000, metric: .fleetSize, target: 12),
        ContractDef(id: "ct_15", title: "Ten Cities", detail: "Operate 12 routes.", reward: 1_400_000, metric: .totalRoutes, target: 12),
        ContractDef(id: "ct_16", title: "Profit Machine", detail: "Reach $2M weekly revenue.", reward: 1_500_000, metric: .weeklyRevenue, target: 2_000_000),
        ContractDef(id: "ct_17", title: "Happy Travelers", detail: "Reach 90% satisfaction.", reward: 1_300_000, metric: .satisfaction, target: 0.90),
        ContractDef(id: "ct_18", title: "Intercontinental", detail: "Open 10 intercontinental routes.", reward: 2_500_000, metric: .intercontinentalRoutes, target: 10),
        ContractDef(id: "ct_19", title: "Half-Million Flyers", detail: "Carry 500K weekly passengers.", reward: 3_000_000, metric: .weeklyPassengers, target: 500_000),
        ContractDef(id: "ct_20", title: "Sky Empire", detail: "Reach Global Sky Harbor prestige.", reward: 6_000_000, metric: .prestige, target: 5),
    ]
}

// MARK: - Achievements (24)
enum AchievementCatalog {
    static let achievements: [AchievementDef] = [
        AchievementDef(id: "a_1", title: "Wheels Up", desc: "Open your first route.", metric: .totalRoutes, target: 1),
        AchievementDef(id: "a_2", title: "Fleet Founder", desc: "Acquire your first aircraft.", metric: .fleetSize, target: 1),
        AchievementDef(id: "a_3", title: "Payroll", desc: "Hire your first staff member.", metric: .staffHired, target: 1),
        AchievementDef(id: "a_4", title: "First Upgrade", desc: "Upgrade any facility once.", metric: .facilitiesUpgraded, target: 1),
        AchievementDef(id: "a_5", title: "Researcher", desc: "Finish your first research.", metric: .researchDone, target: 1),
        AchievementDef(id: "a_6", title: "Week Ten", desc: "Reach week 10.", metric: .weeksPlayed, target: 10),
        AchievementDef(id: "a_7", title: "Full Concourse", desc: "Carry 50K weekly passengers.", metric: .weeklyPassengers, target: 50_000),
        AchievementDef(id: "a_8", title: "Six Figures", desc: "Reach $500K weekly revenue.", metric: .weeklyRevenue, target: 500_000),
        AchievementDef(id: "a_9", title: "Spread Wings", desc: "Operate 5 routes.", metric: .totalRoutes, target: 5),
        AchievementDef(id: "a_10", title: "Squadron", desc: "Own or lease 6 aircraft.", metric: .fleetSize, target: 6),
        AchievementDef(id: "a_11", title: "Regional Hub", desc: "Reach Regional Hub prestige.", metric: .prestige, target: 1),
        AchievementDef(id: "a_12", title: "Crew of Twenty", desc: "Hire 20 staff members.", metric: .staffHired, target: 20),
        AchievementDef(id: "a_13", title: "Knowledge Base", desc: "Complete 7 research nodes.", metric: .researchDone, target: 7),
        AchievementDef(id: "a_14", title: "Builder", desc: "Complete 15 facility upgrades.", metric: .facilitiesUpgraded, target: 15),
        AchievementDef(id: "a_15", title: "Packed Terminals", desc: "Carry 250K weekly passengers.", metric: .weeklyPassengers, target: 250_000),
        AchievementDef(id: "a_16", title: "Coffers", desc: "Hold $25M cash.", metric: .cash, target: 25_000_000),
        AchievementDef(id: "a_17", title: "Globe Trotter", desc: "Open 5 intercontinental routes.", metric: .intercontinentalRoutes, target: 5),
        AchievementDef(id: "a_18", title: "Continental", desc: "Reach Continental Port prestige.", metric: .prestige, target: 3),
        AchievementDef(id: "a_19", title: "Veteran Owner", desc: "Reach week 52.", metric: .weeksPlayed, target: 52),
        AchievementDef(id: "a_20", title: "Cargo Hub", desc: "Earn $2M cargo revenue in a week.", metric: .cargoRevenue, target: 2_000_000),
        AchievementDef(id: "a_21", title: "Five Star", desc: "Reach 95% satisfaction.", metric: .satisfaction, target: 0.95),
        AchievementDef(id: "a_22", title: "Mega Carrier", desc: "Carry 600K weekly passengers.", metric: .weeklyPassengers, target: 600_000),
        AchievementDef(id: "a_23", title: "Tech Tree", desc: "Complete all 14 research nodes.", metric: .researchDone, target: 14),
        AchievementDef(id: "a_24", title: "Sky Harbor", desc: "Reach Global Sky Harbor prestige.", metric: .prestige, target: 5),
    ]
}
