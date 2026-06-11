import SwiftUI

struct WeekResultView: View {
    @EnvironmentObject var store: GameStore
    @Environment(\.presentationMode) var presentationMode

    var r: WeekResult { store.state.lastResult }

    var body: some View {
        GeometryReader { geo in
            let w = min(geo.size.width, UIScreen.main.bounds.width)
            ZStack {
                Brand.navy.edgesIgnoringSafeArea(.all)
                ScrollView {
                    VStack(spacing: 16) {
                        VStack(spacing: 4) {
                            Text("WEEK \(r.week) REPORT").font(.system(size: 12, weight: .bold)).tracking(2).foregroundColor(Brand.sky)
                            Text(Fmt.moneySigned(r.net))
                                .font(.system(size: 38, weight: .heavy, design: .monospaced))
                                .foregroundColor(r.net >= 0 ? Brand.green : Brand.red)
                            Text(r.net >= 0 ? "Net Profit" : "Net Loss").font(.system(size: 13)).foregroundColor(Brand.muted)
                        }
                        .padding(.top, 24)

                        HStack(spacing: 10) {
                            StatChip(label: "Passengers", value: Fmt.int(r.passengers))
                            StatChip(label: "Avg Load", value: Fmt.pct(r.avgLoad), tint: Brand.sky)
                            StatChip(label: "Prestige +", value: Fmt.int(Int(r.prestigeGained)), tint: Brand.amber)
                        }

                        Panel {
                            SectionHeader(text: "Revenue")
                            line("Ticket sales", r.ticketRevenue, Brand.green)
                            line("Cargo", r.cargoRevenue, Brand.green)
                            line("Lounges", r.loungeRevenue, Brand.green)
                            line("Retail & duty-free", r.concessionRevenue, Brand.green)
                            line("Hotels", r.hotelRevenue, Brand.green)
                            Divider().background(Brand.stroke)
                            line("Total revenue", r.totalRevenue, Brand.jet, bold: true)
                        }

                        Panel {
                            SectionHeader(text: "Expenses")
                            line("Fuel", r.fuelCost, Brand.red)
                            line("Landing & crew", r.landingCrewCost, Brand.red)
                            line("Maintenance", r.maintenanceCost, Brand.red)
                            line("Salaries", r.salaryCost, Brand.red)
                            line("Facility upkeep & leases", r.upkeepCost, Brand.red)
                            line("Debt interest", r.interestCost, Brand.red)
                            Divider().background(Brand.stroke)
                            line("Total expenses", r.totalExpense, Brand.jet, bold: true)
                        }

                        PrimaryButton(title: "Continue") {
                            presentationMode.wrappedValue.dismiss()
                        }
                        .padding(.top, 4)
                        Spacer(minLength: 20)
                    }
                    .padding(18)
                    .frame(width: w)
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }

    private func line(_ label: String, _ value: Double, _ tint: Color, bold: Bool = false) -> some View {
        HStack {
            Text(label).font(.system(size: 13, weight: bold ? .bold : .regular)).foregroundColor(bold ? Brand.jet : Brand.muted)
            Spacer()
            Text(Fmt.money(value)).font(.system(size: 13, weight: bold ? .bold : .semibold, design: .monospaced)).foregroundColor(tint)
        }
    }
}
