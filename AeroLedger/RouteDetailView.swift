import SwiftUI

struct RouteDetailView: View {
    @EnvironmentObject var store: GameStore
    let cityID: String
    @Environment(\.presentationMode) var presentationMode

    private var route: OwnedRoute? { store.state.routes.first { $0.cityID == cityID } }
    private var city: CityDef? { CityCatalog.city(cityID) }

    var body: some View {
        ScreenScaffold("Route Detail") {
            if let c = city, let r = route {
                TopHUD()
                Panel {
                    HStack {
                        Text(c.code).font(.system(size: 20, weight: .heavy, design: .monospaced)).foregroundColor(Brand.green)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(c.name).font(.system(size: 18, weight: .bold)).foregroundColor(Brand.jet)
                            Text("\(Fmt.int(c.distanceKm))km from hub").font(.system(size: 12)).foregroundColor(Brand.faint)
                        }
                        Spacer()
                    }
                    HStack(spacing: 10) {
                        StatChip(label: "Base demand", value: Fmt.int(c.baseDemand))
                        StatChip(label: "Competition", value: Fmt.pct(c.competition), tint: Brand.amber)
                        StatChip(label: "Season swing", value: Fmt.pct(c.seasonAmp), tint: Brand.sky)
                    }
                }

                let bonuses = BonusEngine.compute(store.state)
                let preview = GameEngine.simulateRoute(r, state: store.state, bonuses: bonuses, preview: true)

                Panel {
                    SectionHeader(text: "Projected Week")
                    if !preview.hasAircraft {
                        Text("No aircraft assigned. Assign aircraft from the Fleet tab to fly this route.")
                            .font(.system(size: 13)).foregroundColor(Brand.amber)
                    }
                    InfoRow(label: "Passengers", value: Fmt.int(preview.passengers), tint: Brand.jet)
                    InfoRow(label: "Avg load factor", value: Fmt.pct(preview.load), tint: Brand.sky)
                    InfoRow(label: "Ticket revenue", value: Fmt.money(preview.ticketRevenue), tint: Brand.green)
                    InfoRow(label: "Cargo revenue", value: Fmt.money(preview.cargoRevenue), tint: Brand.green)
                    InfoRow(label: "Fuel cost", value: Fmt.money(preview.fuelCost), tint: Brand.red)
                    InfoRow(label: "Landing & crew", value: Fmt.money(preview.landingCrewCost), tint: Brand.red)
                    Divider().background(Brand.stroke)
                    InfoRow(label: "Net / week", value: Fmt.moneySigned(preview.net), tint: preview.net >= 0 ? Brand.green : Brand.red)
                }

                Panel {
                    SectionHeader(text: "Cabin Pricing")
                    priceControl(.economy, price: r.priceEco, ref: DemandCurve.referenceFare(.economy, distanceKm: c.distanceKm))
                    Divider().background(Brand.stroke)
                    priceControl(.business, price: r.priceBus, ref: DemandCurve.referenceFare(.business, distanceKm: c.distanceKm))
                    Divider().background(Brand.stroke)
                    priceControl(.first, price: r.priceFst, ref: DemandCurve.referenceFare(.first, distanceKm: c.distanceKm))
                    Text("Pricing near the reference fare maximizes load. Higher prices raise yield but cut load factor.")
                        .font(.system(size: 11)).foregroundColor(Brand.faint).padding(.top, 4)
                }

                Button(action: { store.closeRoute(cityID); presentationMode.wrappedValue.dismiss() }) {
                    Text("Close Route").font(.system(size: 14, weight: .semibold)).foregroundColor(Brand.red)
                        .frame(maxWidth: .infinity).padding(.vertical, 11)
                        .background(RoundedRectangle(cornerRadius: 10).stroke(Brand.red.opacity(0.6), lineWidth: 1))
                }.buttonStyle(.plain)
            } else {
                Text("Route not found.").foregroundColor(Brand.faint)
            }
        }
    }

    private func priceControl(_ cls: TravelClass, price: Double, ref: Double) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle().fill(Brand.classColor(cls)).frame(width: 9, height: 9)
                Text(cls.label).font(.system(size: 14, weight: .semibold)).foregroundColor(Brand.jet)
                Spacer()
                Text(Fmt.money(price)).font(.system(size: 15, weight: .bold, design: .monospaced)).foregroundColor(Brand.classColor(cls))
            }
            Text("Reference fare \(Fmt.money(ref))").font(.system(size: 10)).foregroundColor(Brand.faint)
            HStack(spacing: 8) {
                stepBtn("-10%") { store.setPrice(cityID, cls: cls, price: price * 0.9) }
                stepBtn("-5%") { store.setPrice(cityID, cls: cls, price: price * 0.95) }
                stepBtn("Reset") { store.setPrice(cityID, cls: cls, price: ref.rounded()) }
                stepBtn("+5%") { store.setPrice(cityID, cls: cls, price: price * 1.05) }
                stepBtn("+10%") { store.setPrice(cityID, cls: cls, price: price * 1.1) }
            }
        }
    }

    private func stepBtn(_ t: String, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(t).font(.system(size: 11, weight: .bold)).foregroundColor(Brand.sky)
                .frame(maxWidth: .infinity).padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 8).stroke(Brand.sky.opacity(0.5), lineWidth: 1))
        }.buttonStyle(.plain)
    }
}
