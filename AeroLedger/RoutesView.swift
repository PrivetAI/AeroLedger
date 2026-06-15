import SwiftUI

struct RoutesView: View {
    @EnvironmentObject var store: GameStore

    var body: some View {
        GeometryReader { geo in
            let w = min(geo.size.width, UIScreen.main.bounds.width)
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    TopHUD()

                    // Map
                    Panel {
                        SectionHeader(text: "Route Map")
                        RouteMapView(mapWidth: w - 60)
                            .frame(height: (w - 60) * 0.62)
                        HStack(spacing: 14) {
                            legendDot(Brand.green, "Open route")
                            legendDot(Brand.sky, "Available")
                            legendDot(Brand.faint, "Locked")
                        }
                    }

                    SectionHeader(text: "Open Routes (\(store.state.routes.count))")
                    if store.state.routes.isEmpty {
                        Panel { Text("No routes yet. Pick a destination below to open one.").font(.system(size: 13)).foregroundColor(Brand.faint) }
                    } else {
                        ForEach(store.state.routes) { route in
                            if let city = CityCatalog.city(route.cityID) {
                                NavigationLink(destination: RouteDetailView(cityID: city.id)) {
                                    openRouteRow(city, route)
                                }.buttonStyle(.plain)
                            }
                        }
                    }

                    SectionHeader(text: "Destinations")
                    ForEach(CityCatalog.cities) { city in
                        if !store.state.routes.contains(where: { $0.cityID == city.id }) {
                            destinationRow(city)
                        }
                    }
                }
                .padding(16)
                .frame(width: w)
                .frame(maxWidth: .infinity)
            }
            .background(Brand.navy.edgesIgnoringSafeArea(.all))
        }
        .navigationBarTitle("Routes", displayMode: .inline)
    }

    private func legendDot(_ c: Color, _ t: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(c).frame(width: 8, height: 8)
            Text(t).font(.system(size: 10)).foregroundColor(Brand.faint)
        }
    }

    private func openRouteRow(_ city: CityDef, _ route: OwnedRoute) -> some View {
        let assigned = store.state.fleet.filter { $0.routeID == city.id }.count
        let bonuses = BonusEngine.compute(store.state)
        let preview = GameEngine.simulateRoute(route, state: store.state, bonuses: bonuses, preview: true)
        return Panel {
            HStack(spacing: 10) {
                Text(city.code).font(.system(size: 14, weight: .heavy, design: .monospaced)).foregroundColor(Brand.green).frame(width: 46)
                VStack(alignment: .leading, spacing: 2) {
                    Text(city.name).font(.system(size: 15, weight: .bold)).foregroundColor(Brand.jet)
                    Text("\(Fmt.int(city.distanceKm))km • \(assigned) aircraft").font(.system(size: 11)).foregroundColor(Brand.faint)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(Fmt.moneySigned(preview.net)).font(.system(size: 13, weight: .bold, design: .monospaced))
                        .foregroundColor(preview.net >= 0 ? Brand.green : Brand.red)
                    Text("est/wk").font(.system(size: 9)).foregroundColor(Brand.faint)
                }
                StrokedIcon(shape: ChevronIcon(), color: Brand.faint, size: 12, line: 2)
            }
        }
    }

    private func destinationRow(_ city: CityDef) -> some View {
        let canOpen = GameEngine.canOpenRoute(to: city, state: store.state)
        let rankOK = store.state.rankIndex >= city.minPrestige
        let inter = city.distanceKm >= CityCatalog.intercontinentalKm
        return Panel {
            HStack(spacing: 10) {
                Text(city.code).font(.system(size: 14, weight: .heavy, design: .monospaced))
                    .foregroundColor(canOpen ? Brand.sky : Brand.faint).frame(width: 46)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(city.name).font(.system(size: 15, weight: .bold)).foregroundColor(Brand.jet)
                        if inter {
                            Text("INTL").font(.system(size: 8, weight: .heavy)).foregroundColor(Brand.amber)
                                .padding(.horizontal, 4).padding(.vertical, 1)
                                .background(RoundedRectangle(cornerRadius: 3).stroke(Brand.amber, lineWidth: 1))
                        }
                    }
                    Text("\(Fmt.int(city.distanceKm))km • demand \(Fmt.int(city.baseDemand)) • comp \(Fmt.pct(city.competition))")
                        .font(.system(size: 11)).foregroundColor(Brand.faint)
                }
                Spacer()
            }
            if !rankOK {
                Text("Requires \(PrestigeCatalog.ranks[city.minPrestige].name) prestige")
                    .font(.system(size: 12, weight: .semibold)).foregroundColor(Brand.amber)
            } else if !canOpen {
                Text("No aircraft in range / runway tier too low")
                    .font(.system(size: 12, weight: .semibold)).foregroundColor(Brand.amber)
            }
            Button(action: { store.openRoute(city) }) {
                Text("Open Route").font(.system(size: 14, weight: .bold))
                    .foregroundColor(canOpen ? Brand.navyDeep : Brand.faint)
                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(canOpen ? Brand.sky : Brand.card))
            }.buttonStyle(.plain).disabled(!canOpen)
        }
    }
}

// MARK: - Route map (Canvas; sizes come from parent — no reliance on canvas size)
struct RouteMapView: View {
    @EnvironmentObject var store: GameStore
    let mapWidth: CGFloat

    var body: some View {
        let mapHeight = mapWidth * 0.62
        Canvas { ctx, _ in
            let sz = CGSize(width: mapWidth, height: mapHeight)
            let hub = CGPoint(x: sz.width * 0.5, y: sz.height * 0.5)

            // route lines
            for route in store.state.routes {
                if let c = CityCatalog.city(route.cityID) {
                    let p = CGPoint(x: c.x * sz.width, y: c.y * sz.height)
                    var line = Path()
                    line.move(to: hub)
                    line.addLine(to: p)
                    ctx.stroke(line, with: .color(Brand.green.opacity(0.5)),
                               style: StrokeStyle(lineWidth: 1.4, dash: [4, 3]))
                }
            }

            // city dots
            for c in CityCatalog.cities {
                let p = CGPoint(x: c.x * sz.width, y: c.y * sz.height)
                let open = store.state.routes.contains { $0.cityID == c.id }
                let canOpen = GameEngine.canOpenRoute(to: c, state: store.state)
                let color: Color = open ? Brand.green : (canOpen ? Brand.sky : Brand.faint.opacity(0.6))
                let r: CGFloat = open ? 5 : 3.5
                ctx.fill(Path(ellipseIn: CGRect(x: p.x - r, y: p.y - r, width: r*2, height: r*2)),
                         with: .color(color))
            }

            // hub marker (your airport)
            let hr: CGFloat = 7
            ctx.fill(Path(ellipseIn: CGRect(x: hub.x - hr, y: hub.y - hr, width: hr*2, height: hr*2)),
                     with: .color(Brand.amber))
            ctx.stroke(Path(ellipseIn: CGRect(x: hub.x - hr - 3, y: hub.y - hr - 3, width: hr*2 + 6, height: hr*2 + 6)),
                       with: .color(Brand.amber.opacity(0.5)), lineWidth: 1)
        }
        .frame(width: mapWidth, height: mapHeight)
        .background(RoundedRectangle(cornerRadius: 10).fill(Brand.navyDeep))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Brand.stroke, lineWidth: 1))
    }
}
