import SwiftUI

struct StatisticsView: View {
    @EnvironmentObject var store: GameStore
    var body: some View {
        ScreenScaffold("Statistics") {
            let s = store.state
            Panel {
                SectionHeader(text: "Operations")
                InfoRow(label: "Weeks played", value: "\(s.week)")
                InfoRow(label: "Prestige rank", value: PrestigeCatalog.ranks[s.rankIndex].name, tint: Brand.sky)
                InfoRow(label: "Prestige points", value: Fmt.int(Int(s.prestige)))
                InfoRow(label: "Satisfaction", value: Fmt.pct(s.satisfaction), tint: s.satisfaction > 0.7 ? Brand.green : Brand.amber)
            }
            Panel {
                SectionHeader(text: "Network")
                InfoRow(label: "Open routes", value: "\(s.routes.count)")
                InfoRow(label: "Intercontinental routes", value: "\(interCount())")
                InfoRow(label: "Aircraft owned/leased", value: "\(s.fleet.count)")
                InfoRow(label: "Staff employed", value: "\(s.staff.count)")
                InfoRow(label: "Research completed", value: "\(s.completedResearch.count)/\(ResearchCatalog.nodes.count)")
                InfoRow(label: "Facility upgrades", value: "\(s.facilitiesUpgradedCount)")
            }
            Panel {
                SectionHeader(text: "Peaks")
                InfoRow(label: "Peak weekly passengers", value: Fmt.int(s.peakWeeklyPassengers), tint: Brand.sky)
                InfoRow(label: "Peak weekly revenue", value: Fmt.money(s.peakWeeklyRevenue), tint: Brand.green)
                InfoRow(label: "Peak cargo revenue", value: Fmt.money(s.peakCargoRevenue), tint: Brand.green)
                InfoRow(label: "Peak lounge revenue", value: Fmt.money(s.peakLoungeRevenue), tint: Brand.green)
            }
            Panel {
                SectionHeader(text: "Finance")
                InfoRow(label: "Cash", value: Fmt.money(s.cash), tint: Brand.green)
                InfoRow(label: "Debt", value: Fmt.money(s.debt), tint: Brand.amber)
                InfoRow(label: "Net worth", value: Fmt.money(s.cash - s.debt), tint: Brand.jet)
                InfoRow(label: "Lifetime profit", value: Fmt.moneySigned(s.totalProfit),
                        tint: s.totalProfit >= 0 ? Brand.green : Brand.red)
                InfoRow(label: "Total staff hired", value: "\(s.staffHiredCount)")
            }
            Panel {
                SectionHeader(text: "Progress")
                InfoRow(label: "Contracts completed", value: "\(s.completedContracts.count)/\(ContractCatalog.contracts.count)", tint: Brand.amber)
                InfoRow(label: "Achievements", value: "\(s.unlockedAchievements.count)/\(AchievementCatalog.achievements.count)", tint: Brand.amber)
            }
        }
    }
    private func interCount() -> Int {
        store.state.routes.filter {
            guard let c = CityCatalog.city($0.cityID) else { return false }
            return c.distanceKm >= CityCatalog.intercontinentalKm
        }.count
    }
}

struct GuideView: View {
    var body: some View {
        ScreenScaffold("How to Play") {
            guideSection("The Weekly Tick", "AeroLedger is turn-based. Each time you tap Advance Week on the Airport screen, the game auto-simulates demand, runs every booked flight, and computes revenue and expenses. There is no real-time flying — depth comes from the interacting economic systems.")
            guideSection("Facilities", "Eight facility categories each have 4 tiers and 5 levels. Terminals set passenger capacity, runways gate aircraft size and add flight cycles, lounges/retail/hotels add revenue, cargo depots boost freight, hangars cut wear, and fuel farms cut fuel cost. Upgrades raise upkeep, so grow sustainably.")
            guideSection("Fleet & Routes", "Buy or lease 12 aircraft models across Regional, Narrowbody and Widebody classes. Open routes to 26 cities — each gated by aircraft range, runway tier, and your prestige rank. Assign aircraft to routes and set Economy, Business and First fares. Pricing near the reference fare maximizes load factor.")
            guideSection("Staff & Research", "Hire six staff roles in three rarities for stacking percentage bonuses. The hiring pool refreshes every few weeks. Research a 14-node tree to unlock larger aircraft support, fuel tech, premium services, marketing and automation.")
            guideSection("Finance & Events", "Track cash, debt and a 60-week revenue/expense chart. Take loans (1.2% weekly interest) to fund expansion. Random weekly events offer choices that shift fuel costs, demand, satisfaction and more.")
            guideSection("Reputation & Goals", "Passenger satisfaction and prestige climb six ranks, unlocking premium long-haul routes. Chase 20 contracts and 24 achievements, and review everything in Statistics.")
        }
    }
    private func guideSection(_ title: String, _ body: String) -> some View {
        Panel {
            Text(title).font(.system(size: 16, weight: .bold)).foregroundColor(Brand.sky)
            Text(body).font(.system(size: 13)).foregroundColor(Brand.muted).lineSpacing(4)
        }
    }
}
