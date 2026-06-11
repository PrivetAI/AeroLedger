import SwiftUI

struct AirportOverviewView: View {
    @EnvironmentObject var store: GameStore
    let onExitToMenu: () -> Void
    @State private var showEvent = false

    private var pendingEvent: GameEventDef? {
        guard let id = store.state.pendingEventID else { return nil }
        return EventCatalog.events.first { $0.id == id }
    }

    var body: some View {
        ScreenScaffold("Airport Overview", trailing: AnyView(
            Button(action: onExitToMenu) {
                Text("Menu").font(.system(size: 14, weight: .semibold)).foregroundColor(Brand.sky)
            })) {

            TopHUD()

            AdvanceWeekChip {
                if pendingEvent != nil { showEvent = true } else { store.advanceWeek() }
            }

            // standing
            Panel {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(PrestigeCatalog.ranks[store.state.rankIndex].name)
                            .font(.system(size: 17, weight: .bold)).foregroundColor(Brand.jet)
                        Text("Prestige rank \(store.state.rankIndex + 1) of 6")
                            .font(.system(size: 11)).foregroundColor(Brand.faint)
                    }
                    Spacer()
                    StrokedIcon(shape: TowerShape(), color: Brand.sky, size: 30, line: 2)
                }
                prestigeBar
                HStack(spacing: 10) {
                    StatChip(label: "Satisfaction", value: Fmt.pct(store.state.satisfaction),
                             tint: store.state.satisfaction > 0.7 ? Brand.green : Brand.amber)
                    StatChip(label: "Routes", value: "\(store.state.routes.count)")
                    StatChip(label: "Fleet", value: "\(store.state.fleet.count)")
                }
            }

            // last week summary
            if store.state.week > 1 {
                Panel {
                    SectionHeader(text: "Last Week")
                    HStack(spacing: 10) {
                        StatChip(label: "Net", value: Fmt.moneySigned(store.state.lastResult.net),
                                 tint: store.state.lastResult.net >= 0 ? Brand.green : Brand.red)
                        StatChip(label: "Passengers", value: Fmt.int(store.state.lastResult.passengers))
                        StatChip(label: "Avg Load", value: Fmt.pct(store.state.lastResult.avgLoad))
                    }
                    Button(action: { store.showWeekResult = true }) {
                        Text("View full week report").font(.system(size: 13, weight: .semibold)).foregroundColor(Brand.sky)
                    }
                }
            }

            // facility summary grid
            Panel {
                SectionHeader(text: "Facilities")
                let cols = [GridItem(.flexible()), GridItem(.flexible())]
                LazyVGrid(columns: cols, spacing: 10) {
                    ForEach(FacilityKind.allCases, id: \.self) { kind in
                        let f = store.state.facility(kind)
                        VStack(alignment: .leading, spacing: 6) {
                            HStack(spacing: 6) {
                                facilityIcon(kind)
                                Text(shortName(kind)).font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(Brand.jet).lineLimit(1).minimumScaleFactor(0.7)
                                Spacer()
                            }
                            TierLevelView(tier: f.tier, level: f.level)
                        }
                        .padding(10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 10).fill(Brand.navyDeep))
                    }
                }
                NavigationLink(destination: BuildView()) {
                    HStack {
                        Text("Build & Upgrade").font(.system(size: 14, weight: .bold)).foregroundColor(Brand.navyDeep)
                        Spacer()
                        StrokedIcon(shape: ChevronIcon(), color: Brand.navyDeep, size: 14, line: 2.5)
                    }
                    .padding(.horizontal, 14).padding(.vertical, 11)
                    .background(RoundedRectangle(cornerRadius: 11).fill(Brand.sky))
                }
                .buttonStyle(.plain)
            }

            // quick links
            Panel {
                SectionHeader(text: "Manage")
                navRow("Staff & Hiring", PeopleIcon(), AnyView(StaffView()))
                Divider().background(Brand.stroke)
                navRow("Research Lab", FlaskIcon(), AnyView(ResearchView()))
                Divider().background(Brand.stroke)
                navRow("Events & News", BellIcon(), AnyView(EventsNewsView()))
            }

            // news ticker
            if let latest = store.state.news.first {
                Panel {
                    SectionHeader(text: "Latest")
                    HStack(spacing: 8) {
                        Circle().fill(latest.positive ? Brand.green : Brand.amber).frame(width: 7, height: 7)
                        Text(latest.text).font(.system(size: 12)).foregroundColor(Brand.muted)
                        Spacer()
                    }
                }
            }
        }
        .sheet(isPresented: $showEvent) {
            if let ev = pendingEvent {
                EventChoiceSheet(event: ev) {
                    showEvent = false
                    // iOS 15: wait for the event sheet to finish dismissing before
                    // the week-result sheet is presented from the tab shell.
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        store.advanceWeek()
                    }
                }
                .environmentObject(store)
            }
        }
    }

    private var prestigeBar: some View {
        let idx = store.state.rankIndex
        let cur = PrestigeCatalog.ranks[idx].threshold
        let next = idx < PrestigeCatalog.ranks.count - 1 ? PrestigeCatalog.ranks[idx + 1].threshold : cur + 1
        let frac = idx < PrestigeCatalog.ranks.count - 1 ? (store.state.prestige - cur) / max(1, next - cur) : 1.0
        return VStack(alignment: .leading, spacing: 4) {
            BarView(value: frac, color: Brand.sky)
            HStack {
                Text("\(Fmt.int(Int(store.state.prestige))) pts").font(.system(size: 10, design: .monospaced)).foregroundColor(Brand.faint)
                Spacer()
                if idx < PrestigeCatalog.ranks.count - 1 {
                    Text("Next: \(PrestigeCatalog.ranks[idx + 1].name)").font(.system(size: 10)).foregroundColor(Brand.faint)
                } else {
                    Text("Max rank").font(.system(size: 10)).foregroundColor(Brand.green)
                }
            }
        }
    }

    private func navRow(_ title: String, _ shape: some Shape, _ dest: AnyView) -> some View {
        NavigationLink(destination: dest) {
            HStack(spacing: 10) {
                StrokedIcon(shape: shape, color: Brand.sky, size: 20, line: 2)
                Text(title).font(.system(size: 14, weight: .semibold)).foregroundColor(Brand.jet)
                Spacer()
                StrokedIcon(shape: ChevronIcon(), color: Brand.faint, size: 13, line: 2)
            }
            .padding(.vertical, 4)
        }
        .buttonStyle(.plain)
    }

    private func shortName(_ k: FacilityKind) -> String {
        switch k {
        case .terminal: return "Terminals"
        case .runway: return "Runways"
        case .lounge: return "Lounges"
        case .retail: return "Retail"
        case .hotel: return "Hotels"
        case .cargo: return "Cargo"
        case .hangar: return "Hangars"
        case .fuel: return "Fuel"
        }
    }
}

@ViewBuilder
func facilityIcon(_ k: FacilityKind) -> some View {
    switch k {
    case .terminal: StrokedIcon(shape: GateShape(), color: Brand.sky, size: 18, line: 2)
    case .runway: StrokedIcon(shape: RunwayShape(), color: Brand.sky, size: 18, line: 1.6)
    case .lounge: StrokedIcon(shape: GaugeShape(), color: Brand.amber, size: 18, line: 2)
    case .retail: StrokedIcon(shape: CoinIcon(), color: Brand.green, size: 18, line: 2)
    case .hotel: StrokedIcon(shape: GateShape(), color: Brand.green, size: 18, line: 2)
    case .cargo: FilledIcon(shape: PlaneShape(), color: Brand.muted, size: 16)
    case .hangar: StrokedIcon(shape: TowerShape(), color: Brand.amber, size: 18, line: 2)
    case .fuel: FilledIcon(shape: FuelDropShape(), color: Brand.sky, size: 16)
    }
}
