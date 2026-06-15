import SwiftUI

struct FleetView: View {
    @EnvironmentObject var store: GameStore
    @State private var mode = 0 // 0 = my fleet, 1 = market

    var body: some View {
        ScreenScaffold("Fleet") {
            TopHUD()
            SegmentBar(selection: $mode, options: ["My Fleet (\(store.state.fleet.count))", "Market"])

            if mode == 0 { myFleet } else { market }
        }
    }

    // MARK: My fleet
    private var myFleet: some View {
        Group {
            if store.state.fleet.isEmpty {
                Panel { Text("No aircraft yet. Visit the Market tab to buy or lease.").font(.system(size: 13)).foregroundColor(Brand.faint) }
            } else {
                ForEach(store.state.fleet) { ac in
                    fleetCard(ac)
                }
            }
        }
    }

    private func fleetCard(_ ac: OwnedAircraft) -> some View {
        let m = FleetCatalog.model(ac.modelID)
        let routeName = ac.routeID.flatMap { CityCatalog.city($0)?.name } ?? "Idle"
        return Panel {
            HStack(spacing: 10) {
                FilledIcon(shape: PlaneShape(), color: classColor(m?.cls ?? .regional), size: 24)
                VStack(alignment: .leading, spacing: 2) {
                    Text(m?.name ?? ac.modelID).font(.system(size: 15, weight: .bold)).foregroundColor(Brand.jet)
                    Text("\(ac.name) • \(ac.leased ? "Leased" : "Owned") • \(m?.totalSeats ?? 0) seats")
                        .font(.system(size: 11)).foregroundColor(Brand.faint)
                }
                Spacer()
            }
            HStack {
                Text("Wear").font(.system(size: 11)).foregroundColor(Brand.muted)
                BarView(value: ac.wear / 100, color: ac.wear > 70 ? Brand.red : (ac.wear > 40 ? Brand.amber : Brand.green), height: 6)
                Text(Fmt.pct(ac.wear / 100)).font(.system(size: 11, design: .monospaced)).foregroundColor(Brand.muted)
            }
            InfoRow(label: "Assignment", value: routeName, tint: ac.routeID != nil ? Brand.sky : Brand.faint)

            HStack(spacing: 8) {
                NavigationLink(destination: AssignView(aircraftID: ac.id)) {
                    actionLabel("Assign", Brand.sky)
                }.buttonStyle(.plain)
                Button(action: { store.maintainAircraft(ac.id) }) {
                    actionLabel("Service", ac.wear > 1 ? Brand.amber : Brand.faint)
                }.buttonStyle(.plain).disabled(ac.wear <= 1)
                Button(action: { store.sellAircraft(ac.id) }) {
                    actionLabel(ac.leased ? "Return" : "Sell", Brand.red)
                }.buttonStyle(.plain)
            }
        }
    }

    private func actionLabel(_ t: String, _ c: Color) -> some View {
        Text(t).font(.system(size: 13, weight: .semibold)).foregroundColor(c)
            .frame(maxWidth: .infinity).padding(.vertical, 9)
            .background(RoundedRectangle(cornerRadius: 9).stroke(c.opacity(0.6), lineWidth: 1))
    }

    // MARK: Market
    private var market: some View {
        Group {
            let runwayTier = BonusEngine.maxRunwayTier(store.state)
            Text("Your runways support up to aircraft tier \(runwayTier). Upgrade runways and research to unlock larger jets.")
                .font(.system(size: 12)).foregroundColor(Brand.faint).lineSpacing(3)
            ForEach(AircraftClass.allCases, id: \.self) { cls in
                SectionHeader(text: cls.label)
                ForEach(FleetCatalog.models.filter { $0.cls == cls }) { m in
                    marketCard(m, runwayTier: runwayTier)
                }
            }
        }
    }

    private func marketCard(_ m: AircraftModel, runwayTier: Int) -> some View {
        let supported = m.minRunwayTier <= runwayTier
        return Panel {
            HStack(spacing: 10) {
                FilledIcon(shape: PlaneShape(), color: classColor(m.cls), size: 22)
                VStack(alignment: .leading, spacing: 2) {
                    Text(m.name).font(.system(size: 15, weight: .bold)).foregroundColor(Brand.jet)
                    Text("\(m.totalSeats) seats • \(Fmt.int(m.rangeKm))km range • tier \(m.minRunwayTier)")
                        .font(.system(size: 11)).foregroundColor(Brand.faint)
                }
                Spacer()
            }
            HStack(spacing: 10) {
                StatChip(label: "Eco/Bus/Fst", value: "\(m.seatsEco)/\(m.seatsBus)/\(m.seatsFst)")
                StatChip(label: "Fuel burn", value: "\(Int(m.fuelBurn))")
                StatChip(label: "Wear/flt", value: String(format: "%.1f", m.wearRate))
            }
            if !supported {
                Text("Requires runway tier \(m.minRunwayTier)").font(.system(size: 12, weight: .semibold)).foregroundColor(Brand.amber)
            }
            HStack(spacing: 8) {
                Button(action: { store.buyAircraft(m, leased: false) }) {
                    buyLabel("Buy", Fmt.money(m.purchaseCost), store.state.cash >= m.purchaseCost && supported, Brand.sky)
                }.buttonStyle(.plain).disabled(!(store.state.cash >= m.purchaseCost && supported))
                Button(action: { store.buyAircraft(m, leased: true) }) {
                    buyLabel("Lease", Fmt.money(m.leaseWeekly) + "/wk", store.state.cash >= m.leaseWeekly * 2 && supported, Brand.green)
                }.buttonStyle(.plain).disabled(!(store.state.cash >= m.leaseWeekly * 2 && supported))
            }
        }
    }

    private func buyLabel(_ t: String, _ sub: String, _ enabled: Bool, _ c: Color) -> some View {
        VStack(spacing: 1) {
            Text(t).font(.system(size: 13, weight: .bold))
            Text(sub).font(.system(size: 10, weight: .semibold, design: .monospaced))
        }
        .foregroundColor(enabled ? Brand.navyDeep : Brand.faint)
        .frame(maxWidth: .infinity).padding(.vertical, 9)
        .background(RoundedRectangle(cornerRadius: 9).fill(enabled ? c : Brand.card))
    }

    private func classColor(_ c: AircraftClass) -> Color {
        switch c {
        case .regional: return Brand.muted
        case .narrowbody: return Brand.sky
        case .widebody: return Brand.amber
        }
    }
}

// MARK: - Assign aircraft to a route
struct AssignView: View {
    @EnvironmentObject var store: GameStore
    let aircraftID: UUID
    @Environment(\.presentationMode) var presentationMode

    var body: some View {
        ScreenScaffold("Assign Aircraft") {
            let ac = store.state.fleet.first { $0.id == aircraftID }
            let model = ac.flatMap { FleetCatalog.model($0.modelID) }
            if let m = model {
                Panel {
                    Text(m.name).font(.system(size: 16, weight: .bold)).foregroundColor(Brand.jet)
                    Text("Assign to a route within \(Fmt.int(m.rangeKm))km range. Idle aircraft earn nothing.")
                        .font(.system(size: 12)).foregroundColor(Brand.faint)
                }
                Button(action: { store.assignAircraft(aircraftID, to: nil); presentationMode.wrappedValue.dismiss() }) {
                    HStack {
                        Text("Set Idle (unassign)").font(.system(size: 14, weight: .semibold)).foregroundColor(Brand.muted)
                        Spacer()
                    }
                    .padding(14).frame(maxWidth: .infinity).card()
                }.buttonStyle(.plain)

                if store.state.routes.isEmpty {
                    Panel { Text("No routes open. Open routes in the Routes tab first.").font(.system(size: 13)).foregroundColor(Brand.faint) }
                } else {
                    ForEach(store.state.routes) { route in
                        if let city = CityCatalog.city(route.cityID) {
                            let inRange = m.rangeKm >= city.distanceKm
                            Button(action: {
                                if inRange { store.assignAircraft(aircraftID, to: route.cityID); presentationMode.wrappedValue.dismiss() }
                            }) {
                                HStack(spacing: 10) {
                                    Text(city.code).font(.system(size: 13, weight: .heavy, design: .monospaced))
                                        .foregroundColor(Brand.sky).frame(width: 44)
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(city.name).font(.system(size: 14, weight: .semibold)).foregroundColor(Brand.jet)
                                        Text("\(Fmt.int(city.distanceKm))km").font(.system(size: 11)).foregroundColor(Brand.faint)
                                    }
                                    Spacer()
                                    if ac?.routeID == route.cityID {
                                        StrokedIcon(shape: CheckIcon(), color: Brand.green, size: 16, line: 2.5)
                                    } else if !inRange {
                                        Text("Out of range").font(.system(size: 11, weight: .semibold)).foregroundColor(Brand.red)
                                    } else {
                                        StrokedIcon(shape: ChevronIcon(), color: Brand.faint, size: 12, line: 2)
                                    }
                                }
                                .padding(14).frame(maxWidth: .infinity).card()
                            }
                            .buttonStyle(.plain).disabled(!inRange)
                        }
                    }
                }
            } else {
                Text("Aircraft not found.").foregroundColor(Brand.faint)
            }
        }
    }
}
