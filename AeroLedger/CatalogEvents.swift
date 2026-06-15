import Foundation

// MARK: - Event system definitions
// Choice-based weekly events. Effects are applied as modifiers that the tick reads.

struct EventChoice {
    let label: String
    let outcome: String
    let apply: (inout GameState) -> Void
}

struct GameEventDef: Identifiable {
    let id: String
    let title: String
    let body: String
    let choices: [EventChoice]
    let minWeek: Int
}

enum EventCatalog {
    // Helper modifiers stored on state for the upcoming tick(s).
    static let events: [GameEventDef] = [
        GameEventDef(id: "e_fuelspike", title: "Fuel Price Spike",
            body: "Global oil markets surge. Fuel costs are climbing fast this week.",
            choices: [
                EventChoice(label: "Absorb the cost", outcome: "Fuel costs +30% next week.") { s in
                    s.activeMods.fuelMult *= 1.30; s.activeMods.weeksLeft = max(s.activeMods.weeksLeft, 1)
                },
                EventChoice(label: "Hedge contracts ($120K)", outcome: "Pay $120K, fuel unaffected.") { s in
                    s.cash -= 120_000
                }
            ], minWeek: 2),
        GameEventDef(id: "e_storm", title: "Severe Storm Front",
            body: "A storm system is grounding flights across several routes.",
            choices: [
                EventChoice(label: "Ground flights", outcome: "Route load -25% next week.") { s in
                    s.activeMods.loadMult *= 0.75; s.activeMods.weeksLeft = max(s.activeMods.weeksLeft, 1)
                },
                EventChoice(label: "Reroute (pay $80K)", outcome: "Pay $80K, only -8% load.") { s in
                    s.cash -= 80_000; s.activeMods.loadMult *= 0.92; s.activeMods.weeksLeft = max(s.activeMods.weeksLeft, 1)
                }
            ], minWeek: 3),
        GameEventDef(id: "e_charter", title: "VIP Charter Offer",
            body: "A corporate group wants an exclusive charter run.",
            choices: [
                EventChoice(label: "Accept charter", outcome: "Gain $260K now, satisfaction +3%.") { s in
                    s.cash += 260_000; s.satisfaction = min(1.0, s.satisfaction + 0.03)
                },
                EventChoice(label: "Decline", outcome: "No change.") { _ in }
            ], minWeek: 2),
        GameEventDef(id: "e_inspect", title: "Safety Inspection",
            body: "Regulators schedule a surprise inspection of your operations.",
            choices: [
                EventChoice(label: "Full compliance ($90K)", outcome: "Pay $90K, prestige +150.") { s in
                    s.cash -= 90_000; s.prestige += 150
                },
                EventChoice(label: "Minimum effort", outcome: "Satisfaction -4%.") { s in
                    s.satisfaction = max(0.2, s.satisfaction - 0.04)
                }
            ], minWeek: 4),
        GameEventDef(id: "e_labor", title: "Labor Dispute",
            body: "Staff unions are demanding higher pay this quarter.",
            choices: [
                EventChoice(label: "Raise wages", outcome: "Salaries +12% next week, satisfaction +5%.") { s in
                    s.activeMods.salaryMult *= 1.12; s.activeMods.weeksLeft = max(s.activeMods.weeksLeft, 1)
                    s.satisfaction = min(1.0, s.satisfaction + 0.05)
                },
                EventChoice(label: "Hold firm", outcome: "On-time -10% load next week.") { s in
                    s.activeMods.loadMult *= 0.90; s.activeMods.weeksLeft = max(s.activeMods.weeksLeft, 1)
                }
            ], minWeek: 5),
        GameEventDef(id: "e_boom", title: "Tourism Boom",
            body: "A festival season is driving a surge in travel demand.",
            choices: [
                EventChoice(label: "Capitalize", outcome: "Demand +22% next week.") { s in
                    s.activeMods.demandMult *= 1.22; s.activeMods.weeksLeft = max(s.activeMods.weeksLeft, 1)
                },
                EventChoice(label: "Marketing push ($100K)", outcome: "Pay $100K, demand +35%.") { s in
                    s.cash -= 100_000; s.activeMods.demandMult *= 1.35; s.activeMods.weeksLeft = max(s.activeMods.weeksLeft, 1)
                }
            ], minWeek: 3),
        GameEventDef(id: "e_grant", title: "Infrastructure Grant",
            body: "The aviation authority offers a development grant.",
            choices: [
                EventChoice(label: "Accept grant", outcome: "Gain $340K.") { s in s.cash += 340_000 },
                EventChoice(label: "Decline (independence)", outcome: "Prestige +200.") { s in s.prestige += 200 }
            ], minWeek: 6),
        GameEventDef(id: "e_competitor", title: "Rival Carrier Enters",
            body: "A competitor is undercutting prices on your busiest routes.",
            choices: [
                EventChoice(label: "Price war", outcome: "Load -12% next week but hold market.") { s in
                    s.activeMods.loadMult *= 0.88; s.activeMods.weeksLeft = max(s.activeMods.weeksLeft, 1)
                },
                EventChoice(label: "Promo blitz ($150K)", outcome: "Pay $150K, demand +18%.") { s in
                    s.cash -= 150_000; s.activeMods.demandMult *= 1.18; s.activeMods.weeksLeft = max(s.activeMods.weeksLeft, 1)
                }
            ], minWeek: 5),
        GameEventDef(id: "e_maint", title: "Fleet Maintenance Alert",
            body: "Engineers flag elevated wear across several aircraft.",
            choices: [
                EventChoice(label: "Major service ($110K)", outcome: "Pay $110K, reduce fleet wear.") { s in
                    s.cash -= 110_000
                    for i in s.fleet.indices { s.fleet[i].wear = max(0, s.fleet[i].wear - 25) }
                },
                EventChoice(label: "Defer", outcome: "Fleet wear +8 across the board.") { s in
                    for i in s.fleet.indices { s.fleet[i].wear = min(100, s.fleet[i].wear + 8) }
                }
            ], minWeek: 4),
        GameEventDef(id: "e_premiumdemand", title: "Business Travel Surge",
            body: "A trade summit boosts premium-cabin demand.",
            choices: [
                EventChoice(label: "Open premium capacity", outcome: "Premium revenue +20% next week.") { s in
                    s.activeMods.premiumMult *= 1.20; s.activeMods.weeksLeft = max(s.activeMods.weeksLeft, 1)
                },
                EventChoice(label: "Steady as she goes", outcome: "No change.") { _ in }
            ], minWeek: 7),
        GameEventDef(id: "e_cargo", title: "Cargo Contract",
            body: "A logistics firm offers a lucrative bulk-cargo agreement.",
            choices: [
                EventChoice(label: "Sign on", outcome: "Cargo revenue +30% next week.") { s in
                    s.activeMods.cargoMult *= 1.30; s.activeMods.weeksLeft = max(s.activeMods.weeksLeft, 1)
                },
                EventChoice(label: "Pass", outcome: "No change.") { _ in }
            ], minWeek: 6),
        GameEventDef(id: "e_econ", title: "Economic Downturn",
            body: "A regional recession is softening travel budgets.",
            choices: [
                EventChoice(label: "Ride it out", outcome: "Demand -18% next week.") { s in
                    s.activeMods.demandMult *= 0.82; s.activeMods.weeksLeft = max(s.activeMods.weeksLeft, 1)
                },
                EventChoice(label: "Discount fares", outcome: "Load steady, revenue per seat -10%.") { s in
                    s.activeMods.yieldMult *= 0.90; s.activeMods.weeksLeft = max(s.activeMods.weeksLeft, 1)
                }
            ], minWeek: 8),
    ]
}
