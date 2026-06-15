import SwiftUI

final class GameStore: ObservableObject {
    @Published var state: GameState
    @Published var showWeekResult = false

    private let saveKey = "sht.gamestate"
    private let onboardKey = "sht.onboarded"

    init() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode(GameState.self, from: data) {
            state = decoded
        } else {
            state = GameStore.newGame()
        }
    }

    // MARK: - New game defaults (solvable opening)
    static func newGame() -> GameState {
        var s = GameState()
        s.cash = 6_000_000
        s.facilities = FacilityKind.allCases.map { OwnedFacility(kind: $0, tier: 1, level: 1) }
        // starter aircraft: two regionals leased
        s.fleet = [
            OwnedAircraft(modelID: "ac_rj70", leased: false, wear: 0, routeID: nil, name: "Pioneer"),
            OwnedAircraft(modelID: "ac_prop48", leased: true, wear: 0, routeID: nil, name: "Dawn"),
        ]
        s.staff = [
            OwnedStaff(role: .pilot, rarity: .rookie, name: "Sam Hart", salary: GameEngine.baseSalary(.pilot)),
            OwnedStaff(role: .ground, rarity: .rookie, name: "Riley Cole", salary: GameEngine.baseSalary(.ground)),
        ]
        GameEngine.refreshHirePool(&s)
        GameEngine.queueEvent(&s)
        GameEngine.addNews(&s, "Welcome to Sky Harbor. Open your first routes and advance the week.", positive: true)
        return s
    }

    // MARK: - Persistence
    func save() {
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: saveKey)
        }
    }

    func resetProgress() {
        // wipe all sht.* keys
        let defaults = UserDefaults.standard
        for key in defaults.dictionaryRepresentation().keys where key.hasPrefix("sht.") {
            defaults.removeObject(forKey: key)
        }
        state = GameStore.newGame()
        save()
        objectWillChange.send()
    }

    // MARK: - Advance week
    func advanceWeek() {
        // apply pending event choice happens in EventsView before this; here just tick
        GameEngine.advanceWeek(&state)
        save()
        showWeekResult = true
    }

    func applyEventChoice(_ choice: EventChoice) {
        choice.apply(&state)
        state.pendingEventID = nil
        save()
    }

    // MARK: - Facility actions
    func canUpgradeFacility(_ kind: FacilityKind) -> (can: Bool, cost: Double, maxed: Bool) {
        let f = state.facility(kind)
        if f.tier >= FacilityEcon.maxTier && f.level >= FacilityEcon.maxLevel {
            return (false, 0, true)
        }
        let cost = FacilityEcon.upgradeCost(kind: kind, tier: f.tier, level: f.level)
        return (state.cash >= cost, cost, false)
    }

    func upgradeFacility(_ kind: FacilityKind) {
        guard let idx = state.facilities.firstIndex(where: { $0.kind == kind }) else { return }
        let f = state.facilities[idx]
        let info = canUpgradeFacility(kind)
        guard info.can, !info.maxed else { return }
        state.cash -= info.cost
        // level up, roll to next tier when level maxes
        if f.level >= FacilityEcon.maxLevel {
            if f.tier < FacilityEcon.maxTier {
                state.facilities[idx].tier += 1
                state.facilities[idx].level = 1
            }
        } else {
            state.facilities[idx].level += 1
        }
        state.facilitiesUpgradedCount += 1
        GameEngine.evaluateProgress(&state)
        save()
    }

    // MARK: - Fleet actions
    func buyAircraft(_ model: AircraftModel, leased: Bool) {
        let cost = leased ? model.leaseWeekly * 2 : model.purchaseCost
        guard state.cash >= cost else { return }
        state.cash -= cost
        let n = (state.fleet.count + 1)
        state.fleet.append(OwnedAircraft(modelID: model.id, leased: leased, wear: 0, routeID: nil,
                                         name: "Craft \(n)"))
        GameEngine.evaluateProgress(&state)
        save()
    }

    func sellAircraft(_ id: UUID) {
        guard let idx = state.fleet.firstIndex(where: { $0.id == id }) else { return }
        let ac = state.fleet[idx]
        if !ac.leased, let m = FleetCatalog.model(ac.modelID) {
            let resale = m.purchaseCost * 0.55 * (1.0 - ac.wear / 200.0)
            state.cash += resale
        }
        state.fleet.remove(at: idx)
        save()
    }

    func assignAircraft(_ id: UUID, to routeID: String?) {
        guard let idx = state.fleet.firstIndex(where: { $0.id == id }) else { return }
        state.fleet[idx].routeID = routeID
        save()
    }

    func maintainAircraft(_ id: UUID) {
        guard let idx = state.fleet.firstIndex(where: { $0.id == id }),
              let m = FleetCatalog.model(state.fleet[idx].modelID) else { return }
        let cost = m.purchaseCost * 0.002 * (state.fleet[idx].wear / 10.0)
        guard state.cash >= cost else { return }
        state.cash -= cost
        state.fleet[idx].wear = 0
        save()
    }

    // MARK: - Route actions
    func openRoute(_ city: CityDef) {
        guard !state.routes.contains(where: { $0.cityID == city.id }) else { return }
        guard GameEngine.canOpenRoute(to: city, state: state) else { return }
        let eco = DemandCurve.referenceFare(.economy, distanceKm: city.distanceKm)
        let bus = DemandCurve.referenceFare(.business, distanceKm: city.distanceKm)
        let fst = DemandCurve.referenceFare(.first, distanceKm: city.distanceKm)
        state.routes.append(OwnedRoute(cityID: city.id, priceEco: eco.rounded(),
                                       priceBus: bus.rounded(), priceFst: fst.rounded()))
        GameEngine.evaluateProgress(&state)
        save()
    }

    func closeRoute(_ cityID: String) {
        state.routes.removeAll { $0.cityID == cityID }
        for i in state.fleet.indices where state.fleet[i].routeID == cityID {
            state.fleet[i].routeID = nil
        }
        save()
    }

    func setPrice(_ cityID: String, cls: TravelClass, price: Double) {
        guard let idx = state.routes.firstIndex(where: { $0.cityID == cityID }) else { return }
        let p = max(10, price)
        switch cls {
        case .economy: state.routes[idx].priceEco = p
        case .business: state.routes[idx].priceBus = p
        case .first: state.routes[idx].priceFst = p
        }
        save()
    }

    // MARK: - Staff actions
    func hire(_ entry: HirePoolEntry) {
        guard state.cash >= entry.signingFee else { return }
        state.cash -= entry.signingFee
        state.staff.append(OwnedStaff(role: entry.role, rarity: entry.rarity, name: entry.name, salary: entry.salary))
        state.staffHiredCount += 1
        state.hirePool.removeAll { $0.id == entry.id }
        GameEngine.evaluateProgress(&state)
        save()
    }

    func fire(_ id: UUID) {
        state.staff.removeAll { $0.id == id }
        save()
    }

    // MARK: - Research actions
    func canStartResearch(_ def: ResearchNodeDef) -> Bool {
        guard state.researchInProgress == nil else { return false }
        guard !state.completedResearch.contains(def.id) else { return false }
        guard def.prereqs.allSatisfy({ state.completedResearch.contains($0) }) else { return false }
        return state.cash >= def.cost
    }

    func startResearch(_ def: ResearchNodeDef) {
        guard canStartResearch(def) else { return }
        state.cash -= def.cost
        state.researchInProgress = ResearchProgress(nodeID: def.id, weeksDone: 0)
        save()
    }

    // MARK: - Finance / loans
    func takeLoan(_ amount: Double) {
        guard amount > 0 else { return }
        state.debt += amount
        state.cash += amount
        save()
    }

    func repayLoan(_ amount: Double) {
        let pay = min(amount, min(state.debt, state.cash))
        guard pay > 0 else { return }
        state.debt -= pay
        state.cash -= pay
        save()
    }

    var maxLoan: Double {
        // credit limit scales with prestige & weekly revenue, minus current debt
        let limit = 5_000_000 + Double(state.rankIndex) * 8_000_000 + state.peakWeeklyRevenue * 6
        return max(0, limit - state.debt)
    }

    // MARK: - Settings
    func toggleSound() { state.soundOn.toggle(); save() }
    func toggleHaptics() { state.hapticsOn.toggle(); save() }
    func markOnboarded() { state.hasSeenOnboarding = true; save() }
}
