import SwiftUI

struct FinanceView: View {
    @EnvironmentObject var store: GameStore
    @State private var loanField = 500_000.0

    var body: some View {
        GeometryReader { geo in
            let w = min(geo.size.width, UIScreen.main.bounds.width)
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    TopHUD()

                    Panel {
                        SectionHeader(text: "Revenue vs Expenses (last \(store.state.history.count) weeks)")
                        FinanceChart(width: w - 60, history: store.state.history)
                            .frame(height: 160)
                        HStack(spacing: 16) {
                            chartLegend(Brand.green, "Revenue")
                            chartLegend(Brand.red, "Expense")
                        }
                    }

                    Panel {
                        SectionHeader(text: "Standing")
                        InfoRow(label: "Cash", value: Fmt.money(store.state.cash), tint: store.state.cash >= 0 ? Brand.green : Brand.red)
                        InfoRow(label: "Debt", value: Fmt.money(store.state.debt), tint: store.state.debt > 0 ? Brand.amber : Brand.muted)
                        InfoRow(label: "Weekly interest", value: Fmt.money(store.state.debt * 0.012), tint: Brand.red)
                        InfoRow(label: "Lifetime profit", value: Fmt.moneySigned(store.state.totalProfit),
                                tint: store.state.totalProfit >= 0 ? Brand.green : Brand.red)
                        InfoRow(label: "Net worth", value: Fmt.money(store.state.cash - store.state.debt), tint: Brand.jet)
                    }

                    if store.state.week > 1 {
                        Panel {
                            SectionHeader(text: "Last Week Expense Breakdown")
                            ExpenseBreakdown(result: store.state.lastResult, width: w - 60)
                        }
                    }

                    Panel {
                        SectionHeader(text: "Loans")
                        InfoRow(label: "Available credit", value: Fmt.money(store.maxLoan), tint: Brand.sky)
                        Text("Take a loan to fund expansion. Interest accrues weekly at 1.2%.")
                            .font(.system(size: 11)).foregroundColor(Brand.faint)
                        HStack(spacing: 8) {
                            loanBtn("Borrow $250K", Brand.sky) { store.takeLoan(min(250_000, store.maxLoan)) }
                            loanBtn("Borrow $1M", Brand.sky) { store.takeLoan(min(1_000_000, store.maxLoan)) }
                        }
                        HStack(spacing: 8) {
                            loanBtn("Borrow $5M", Brand.sky) { store.takeLoan(min(5_000_000, store.maxLoan)) }
                            loanBtn("Borrow Max", Brand.green) { store.takeLoan(store.maxLoan) }
                        }
                        Divider().background(Brand.stroke)
                        HStack(spacing: 8) {
                            loanBtn("Repay $250K", Brand.amber) { store.repayLoan(250_000) }
                            loanBtn("Repay $1M", Brand.amber) { store.repayLoan(1_000_000) }
                            loanBtn("Repay All", Brand.green) { store.repayLoan(store.state.debt) }
                        }
                    }
                }
                .padding(16)
                .frame(width: w)
                .frame(maxWidth: .infinity)
            }
            .background(Brand.navy.edgesIgnoringSafeArea(.all))
        }
        .navigationBarTitle("Finance", displayMode: .inline)
    }

    private func chartLegend(_ c: Color, _ t: String) -> some View {
        HStack(spacing: 5) {
            RoundedRectangle(cornerRadius: 2).fill(c).frame(width: 14, height: 4)
            Text(t).font(.system(size: 11)).foregroundColor(Brand.muted)
        }
    }
    private func loanBtn(_ t: String, _ c: Color, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(t).font(.system(size: 12, weight: .bold)).foregroundColor(c)
                .frame(maxWidth: .infinity).padding(.vertical, 10)
                .background(RoundedRectangle(cornerRadius: 9).stroke(c.opacity(0.5), lineWidth: 1))
        }.buttonStyle(.plain)
    }
}

// MARK: - Custom Path chart (NOT Charts framework). Handles 0..60 points & empty.
struct FinanceChart: View {
    let width: CGFloat
    let history: [HistoryPoint]

    var body: some View {
        let h: CGFloat = 160
        Canvas { ctx, _ in
            let sz = CGSize(width: width, height: h)
            let pad: CGFloat = 6
            let plotW = sz.width - pad * 2
            let plotH = sz.height - pad * 2

            // gridlines
            for i in 0...3 {
                let y = pad + plotH * CGFloat(i) / 3
                var g = Path()
                g.move(to: CGPoint(x: pad, y: y))
                g.addLine(to: CGPoint(x: pad + plotW, y: y))
                ctx.stroke(g, with: .color(Brand.stroke.opacity(0.5)), lineWidth: 0.5)
            }

            guard history.count >= 1 else {
                ctx.draw(Text("No data yet").font(.system(size: 12)).foregroundColor(Brand.faint),
                         at: CGPoint(x: sz.width/2, y: sz.height/2))
                return
            }

            let maxVal = max(1, history.map { max($0.revenue, $0.expense) }.max() ?? 1)
            let n = history.count
            func x(_ i: Int) -> CGFloat {
                n == 1 ? pad + plotW/2 : pad + plotW * CGFloat(i) / CGFloat(n - 1)
            }
            func y(_ v: Double) -> CGFloat {
                pad + plotH * (1 - CGFloat(v / maxVal))
            }

            func series(_ key: (HistoryPoint) -> Double, color: Color) {
                var line = Path()
                for (i, pt) in history.enumerated() {
                    let p = CGPoint(x: x(i), y: y(key(pt)))
                    if i == 0 { line.move(to: p) } else { line.addLine(to: p) }
                }
                if n == 1, let only = history.first {
                    let p = CGPoint(x: x(0), y: y(key(only)))
                    ctx.fill(Path(ellipseIn: CGRect(x: p.x-3, y: p.y-3, width: 6, height: 6)), with: .color(color))
                } else {
                    ctx.stroke(line, with: .color(color), style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
                }
            }
            series({ $0.revenue }, color: Brand.green)
            series({ $0.expense }, color: Brand.red)
        }
        .frame(width: width, height: h)
        .background(RoundedRectangle(cornerRadius: 10).fill(Brand.navyDeep))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Brand.stroke, lineWidth: 1))
    }
}

// MARK: - Expense breakdown bars
struct ExpenseBreakdown: View {
    let result: WeekResult
    let width: CGFloat

    var body: some View {
        let items: [(String, Double, Color)] = [
            ("Fuel", result.fuelCost, Brand.sky),
            ("Landing & crew", result.landingCrewCost, Brand.skyDim),
            ("Maintenance", result.maintenanceCost, Brand.amber),
            ("Salaries", result.salaryCost, Brand.green),
            ("Upkeep & leases", result.upkeepCost, Brand.muted),
            ("Interest", result.interestCost, Brand.red),
        ]
        let total = max(1, items.map { $0.1 }.reduce(0, +))
        return VStack(spacing: 8) {
            ForEach(0..<items.count, id: \.self) { i in
                let it = items[i]
                HStack(spacing: 8) {
                    Text(it.0).font(.system(size: 12)).foregroundColor(Brand.muted).frame(width: 110, alignment: .leading)
                    BarView(value: it.1 / total, color: it.2, height: 8)
                    Text(Fmt.money(it.1)).font(.system(size: 11, design: .monospaced)).foregroundColor(Brand.jet)
                        .frame(width: 56, alignment: .trailing)
                }
            }
        }
    }
}
