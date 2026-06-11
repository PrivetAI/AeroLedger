import Foundation

// Per-route preview / result of one week's simulation.
struct RoutePreview {
    let cityID: String
    let assignedSeats: Int
    let cycles: Int
    let load: Double
    let passengers: Int
    let ticketRevenue: Double
    let cargoRevenue: Double
    let fuelCost: Double
    let landingCrewCost: Double
    let net: Double
    let hasAircraft: Bool
}

enum GameEngine {

    // MARK: - Range gating
    static func canOperate(model: AircraftModel, to city: CityDef, state: GameState) -> Bool {
        let runwayTier = BonusEngine.maxRunwayTier(state)
        return model.rangeKm >= city.distanceKm && model.minRunwayTier <= runwayTier
    }

    static func canOpenRoute(to city: CityDef, state: GameState) -> Bool {
        guard state.rankIndex >= city.minPrestige else { return false }
        // need at least one fleet model capable of the distance & runway
        return state.fleet.contains { ac in
            guard let m = FleetCatalog.model(ac.modelID) else { return false }
            return canOperate(model: m, to: city, state: state)
        }
    }

    // MARK: - Per-route simulation (closed form, deterministic)
    static func simulateRoute(_ route: OwnedRoute, state: GameState, bonuses: Bonuses, preview: Bool) -> RoutePreview {
        guard let city = CityCatalog.city(route.cityID) else {
            return RoutePreview(cityID: route.cityID, assignedSeats: 0, cycles: 0, load: 0, passengers: 0,
                                ticketRevenue: 0, cargoRevenue: 0, fuelCost: 0, landingCrewCost: 0, net: 0, hasAircraft: false)
        }
        // aircraft assigned to this route
        let assigned = state.fleet.filter { $0.routeID == route.cityID }
        let models = assigned.compactMap { FleetCatalog.model($0.modelID) }
        guard !models.isEmpty else {
            return RoutePreview(cityID: route.cityID, assignedSeats: 0, cycles: 0, load: 0, passengers: 0,
                                ticketRevenue: 0, cargoRevenue: 0, fuelCost: 0, landingCrewCost: 0, net: 0, hasAircraft: false)
        }

        let runway = state.facility(.runway)
        var cycles = FacilityEcon.runwayCycles(tier: runway.tier, level: runway.level)
        cycles += BonusEngine.bonusCycles(state)

        let mods = state.activeMods
        let season = DemandCurve.seasonal(amp: city.seasonAmp, phase: city.seasonPhase, week: state.week)
        let demandBoost = bonuses.demandReach * mods.demandMult * (0.85 + 0.30 * Double(state.rankIndex) / 5.0)

        // capacity per class across assigned aircraft, * cycles
        var seatsEco = 0, seatsBus = 0, seatsFst = 0
        for m in models { seatsEco += m.seatsEco; seatsBus += m.seatsBus; seatsFst += m.seatsFst }
        let capMul = bonuses.capacityMult * bonuses.throughput
        let weeklySeatsEco = Double(seatsEco * cycles) * capMul
        let weeklySeatsBus = Double(seatsBus * cycles) * capMul
        let weeklySeatsFst = Double(seatsFst * cycles) * capMul

        // demand pool per class
        let pool = Double(city.baseDemand) * season * demandBoost
        let demEco = pool * city.demandEco
        let demBus = pool * city.demandBus
        let demFst = pool * city.demandFst

        func classResult(_ cls: TravelClass, price: Double, seats: Double, demand: Double, premium: Bool) -> (pax: Double, rev: Double) {
            let ref = DemandCurve.referenceFare(cls, distanceKm: city.distanceKm)
            var lf = DemandCurve.loadFactor(price: price, reference: ref, competition: city.competition,
                                            satisfaction: state.satisfaction, demandBoost: 1.0)
            lf *= bonuses.loadBoost * mods.loadMult * min(1.2, bonuses.onTime)
            lf = min(0.99, max(0, lf))
            // passengers limited by both seats and demand
            let demandPax = demand * lf
            let pax = min(seats, demandPax)
            var rev = pax * price * mods.yieldMult
            if premium { rev *= bonuses.premiumMult * mods.premiumMult }
            return (pax, rev)
        }

        let rEco = classResult(.economy, price: route.priceEco, seats: weeklySeatsEco, demand: demEco, premium: false)
        let rBus = classResult(.business, price: route.priceBus, seats: weeklySeatsBus, demand: demBus, premium: true)
        let rFst = classResult(.first, price: route.priceFst, seats: weeklySeatsFst, demand: demFst, premium: true)

        let pax = rEco.pax + rBus.pax + rFst.pax
        let ticketRev = rEco.rev + rBus.rev + rFst.rev

        // cargo revenue
        let cargoFac = state.facility(.cargo)
        let cargoCap = FacilityEcon.cargoMult(tier: cargoFac.tier, level: cargoFac.level)
        let cargoRev = Double(city.baseDemand) * city.cargoFactor * 1.4 * cargoCap *
            bonuses.cargoMult * mods.cargoMult * (Double(cycles) / 6.0)

        // costs: fuel + landing/crew
        let fuelFac = state.facility(.fuel)
        let fuelDisc = FacilityEcon.fuelDiscount(tier: fuelFac.tier, level: fuelFac.level)
        var fuelCost = 0.0
        for m in models {
            fuelCost += m.fuelBurn * (Double(city.distanceKm) / 1000.0) * 2.0 * Double(cycles) * 22.0
        }
        fuelCost *= (1.0 - fuelDisc) * bonuses.fuelMult * mods.fuelMult

        let landingCrew = (Double(models.count) * Double(cycles) * 1800.0) + (Double(city.distanceKm) * 0.9 * Double(cycles))

        let net = ticketRev + cargoRev - fuelCost - landingCrew

        return RoutePreview(cityID: route.cityID,
                            assignedSeats: seatsEco + seatsBus + seatsFst,
                            cycles: cycles, load: pax / max(1, weeklySeatsEco + weeklySeatsBus + weeklySeatsFst),
                            passengers: Int(pax), ticketRevenue: ticketRev, cargoRevenue: cargoRev,
                            fuelCost: fuelCost, landingCrewCost: landingCrew, net: net, hasAircraft: true)
    }

    // MARK: - Full weekly tick
    static func advanceWeek(_ state: inout GameState) {
        let bonuses = BonusEngine.compute(state)
        var res = WeekResult()
        res.week = state.week

        var totalPax = 0.0
        var loadSum = 0.0
        var loadCount = 0.0

        for route in state.routes {
            let r = simulateRoute(route, state: state, bonuses: bonuses, preview: false)
            res.ticketRevenue += r.ticketRevenue
            res.cargoRevenue += r.cargoRevenue
            res.fuelCost += r.fuelCost
            res.landingCrewCost += r.landingCrewCost
            totalPax += Double(r.passengers)
            if r.hasAircraft { loadSum += r.load; loadCount += 1 }
        }
        res.passengers = Int(totalPax)
        res.avgLoad = loadCount > 0 ? loadSum / loadCount : 0

        // Terminal capacity cap on passengers
        let term = state.facility(.terminal)
        let cap = FacilityEcon.terminalCapacity(tier: term.tier, level: term.level) * bonuses.throughput
        if Double(res.passengers) > cap && res.passengers > 0 {
            let scale = cap / Double(res.passengers)
            res.passengers = Int(cap)
            res.ticketRevenue *= scale
            totalPax = cap
        }

        // Lounge / concession / hotel revenue
        let lounge = state.facility(.lounge)
        res.loungeRevenue = FacilityEcon.loungeBase(tier: lounge.tier, level: lounge.level) *
            bonuses.premiumMult * (0.6 + state.satisfaction * 0.6)
        let retail = state.facility(.retail)
        res.concessionRevenue = (totalPax / 1000.0) * FacilityEcon.retailPerK(tier: retail.tier, level: retail.level)
        let hotel = state.facility(.hotel)
        res.hotelRevenue = FacilityEcon.hotelBase(tier: hotel.tier, level: hotel.level) * (0.7 + state.satisfaction * 0.5)

        // Maintenance from fleet wear; hangar reduces it
        let hangar = state.facility(.hangar)
        let wearRed = FacilityEcon.hangarWearReduction(tier: hangar.tier, level: hangar.level)
        var maint = 0.0
        for i in state.fleet.indices {
            guard let m = FleetCatalog.model(state.fleet[i].modelID) else { continue }
            let active = state.fleet[i].routeID != nil
            if active {
                let wearAdd = m.wearRate * (1.0 - wearRed) * bonuses.wearMult
                state.fleet[i].wear = min(100, state.fleet[i].wear + wearAdd)
            } else {
                state.fleet[i].wear = max(0, state.fleet[i].wear - 1.0) // idle cools down
            }
            // maintenance cost scales with wear & model value
            let wearFrac = state.fleet[i].wear / 100.0
            maint += (m.purchaseCost * 0.0009) * (0.4 + wearFrac) * (1.0 - wearRed) * bonuses.maintCostMult
            // lease cost folded into salary/upkeep section below
        }
        res.maintenanceCost = maint

        // Lease costs
        var leaseCost = 0.0
        for ac in state.fleet where ac.leased {
            if let m = FleetCatalog.model(ac.modelID) { leaseCost += m.leaseWeekly }
        }

        // Salaries
        var salaries = 0.0
        for st in state.staff { salaries += st.salary }
        salaries *= state.activeMods.salaryMult
        res.salaryCost = salaries

        // Facility upkeep
        var upkeep = leaseCost
        for f in state.facilities {
            upkeep += FacilityEcon.upkeep(kind: f.kind, tier: f.tier, level: f.level)
        }
        upkeep *= bonuses.upkeepMult
        res.upkeepCost = upkeep

        // Debt interest (weekly)
        let weeklyRate = 0.012
        res.interestCost = state.debt * weeklyRate

        res.net = res.totalRevenue - res.totalExpense

        // Apply to cash
        state.cash += res.net

        // Satisfaction drift toward a target based on load & service
        let targetSat = min(0.98, 0.55 + res.avgLoad * 0.25 + bonuses.satisfactionBoost * 10
                            + Double(state.rankIndex) * 0.02
                            + (state.facility(.lounge).level > 2 ? 0.03 : 0))
        state.satisfaction += (targetSat - state.satisfaction) * 0.25
        state.satisfaction = min(0.99, max(0.2, state.satisfaction))

        // Prestige gain from passengers + profit
        let pres = Double(res.passengers) / 1500.0 + max(0, res.net) / 12_000.0 + Double(state.routes.count) * 2
        res.prestigeGained = pres
        state.prestige += pres

        // History & peaks
        state.history.append(HistoryPoint(week: state.week, revenue: res.totalRevenue, expense: res.totalExpense))
        if state.history.count > 60 { state.history.removeFirst(state.history.count - 60) }
        state.totalProfit += res.net
        state.peakWeeklyPassengers = max(state.peakWeeklyPassengers, res.passengers)
        state.peakWeeklyRevenue = max(state.peakWeeklyRevenue, res.totalRevenue)
        state.peakCargoRevenue = max(state.peakCargoRevenue, res.cargoRevenue)
        state.peakLoungeRevenue = max(state.peakLoungeRevenue, res.loungeRevenue)

        // Research progress
        if var rip = state.researchInProgress {
            rip.weeksDone += 1
            if let def = ResearchCatalog.node(rip.nodeID), rip.weeksDone >= def.weeks {
                state.completedResearch.append(rip.nodeID)
                state.researchInProgress = nil
                addNews(&state, "Research complete: \(def.name).", positive: true)
            } else {
                state.researchInProgress = rip
            }
        }

        // Decrement active mods
        if state.activeMods.weeksLeft > 0 {
            state.activeMods.weeksLeft -= 1
            if state.activeMods.weeksLeft == 0 { state.activeMods.reset() }
        }

        state.lastResult = res
        addNews(&state, "Week \(state.week): " + (res.net >= 0 ? "profit " : "loss ") + Fmt.money(abs(res.net)) + ", " + Fmt.int(res.passengers) + " pax.", positive: res.net >= 0)

        // advance counters
        state.week += 1

        // Refresh hire pool every 3 weeks
        if state.week - state.hireRefreshWeek >= 3 || state.hirePool.isEmpty {
            refreshHirePool(&state)
        }

        // Queue next event
        queueEvent(&state)

        // Check contracts & achievements
        evaluateProgress(&state)
    }

    static func addNews(_ s: inout GameState, _ text: String, positive: Bool) {
        s.news.insert(NewsItem(week: s.week, text: text, positive: positive), at: 0)
        if s.news.count > 40 { s.news.removeLast(s.news.count - 40) }
    }

    // MARK: - Hire pool
    static func refreshHirePool(_ s: inout GameState) {
        var rng = SeededRNG(s.rngSeed &+ UInt64(s.week) &* 2654435761)
        s.rngSeed = rng.state
        s.hireRefreshWeek = s.week
        s.hirePool.removeAll()
        let count = 6
        for _ in 0..<count {
            let role = StaffRole.allCases[rng.int(0..<StaffRole.allCases.count)]
            let rr = rng.double()
            let rarity: Rarity = rr < 0.6 ? .rookie : (rr < 0.9 ? .pro : .veteran)
            let salary = (baseSalary(role) * rarity.multiplier).rounded()
            let fee = (salary * 4).rounded()
            s.hirePool.append(HirePoolEntry(role: role, rarity: rarity, name: randomName(&rng),
                                            salary: salary, signingFee: fee))
        }
    }

    static func baseSalary(_ role: StaffRole) -> Double {
        switch role {
        case .pilot: return 9_500
        case .cabin: return 4_200
        case .ground: return 3_400
        case .engineer: return 7_800
        case .manager: return 8_600
        case .marketer: return 6_200
        }
    }

    static let firstNames = ["Alex","Jordan","Taylor","Morgan","Casey","Riley","Sam","Quinn","Avery","Drew","Reese","Sky","Jamie","Robin","Dana","Lee","Noah","Maya","Ivy","Cole"]
    static let lastNames = ["Hart","Vance","Brooks","Mercer","Cole","Frost","Lane","Stone","Reyes","Quill","Marsh","Beck","Hale","Wren","Cross","Pace","Knox","Vale","Ridge","Sloan"]
    static func randomName(_ rng: inout SeededRNG) -> String {
        firstNames[rng.int(0..<firstNames.count)] + " " + lastNames[rng.int(0..<lastNames.count)]
    }

    // MARK: - Events
    static func queueEvent(_ s: inout GameState) {
        var rng = SeededRNG(s.rngSeed &+ UInt64(s.week) &* 40503)
        s.rngSeed = rng.state
        // 60% chance an event appears for the upcoming week
        if rng.double() < 0.60 {
            let eligible = EventCatalog.events.filter { $0.minWeek <= s.week }
            if !eligible.isEmpty {
                s.pendingEventID = eligible[rng.int(0..<eligible.count)].id
                return
            }
        }
        s.pendingEventID = nil
    }

    // MARK: - Contracts & achievements
    static func metricValue(_ m: ContractMetric, _ s: GameState) -> Double {
        switch m {
        case .weeklyPassengers: return Double(max(s.peakWeeklyPassengers, s.lastResult.passengers))
        case .totalRoutes: return Double(s.routes.count)
        case .intercontinentalRoutes:
            return Double(s.routes.filter {
                guard let c = CityCatalog.city($0.cityID) else { return false }
                return c.distanceKm >= CityCatalog.intercontinentalKm
            }.count)
        case .cash: return s.cash
        case .fleetSize: return Double(s.fleet.count)
        case .prestige: return Double(s.rankIndex)
        case .weeksPlayed: return Double(s.week)
        case .totalProfit: return s.totalProfit
        case .facilitiesUpgraded: return Double(s.facilitiesUpgradedCount)
        case .satisfaction: return s.satisfaction
        case .staffHired: return Double(s.staffHiredCount)
        case .researchDone: return Double(s.completedResearch.count)
        case .cargoRevenue: return max(s.peakCargoRevenue, s.lastResult.cargoRevenue)
        case .loungeRevenue: return max(s.peakLoungeRevenue, s.lastResult.loungeRevenue)
        case .weeklyRevenue: return max(s.peakWeeklyRevenue, s.lastResult.totalRevenue)
        }
    }

    static func evaluateProgress(_ s: inout GameState) {
        for c in ContractCatalog.contracts where !s.completedContracts.contains(c.id) {
            if metricValue(c.metric, s) >= c.target {
                s.completedContracts.append(c.id)
                s.cash += c.reward
                addNews(&s, "Contract complete: \(c.title) (+\(Fmt.money(c.reward))).", positive: true)
            }
        }
        for a in AchievementCatalog.achievements where !s.unlockedAchievements.contains(a.id) {
            if metricValue(a.metric, s) >= a.target {
                s.unlockedAchievements.append(a.id)
                addNews(&s, "Achievement unlocked: \(a.title).", positive: true)
            }
        }
    }
}
