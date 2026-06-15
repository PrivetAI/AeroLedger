import SwiftUI

struct StaffView: View {
    @EnvironmentObject var store: GameStore
    @State private var mode = 0

    var body: some View {
        ScreenScaffold("Staff") {
            TopHUD()
            SegmentBar(selection: $mode, options: ["Roster (\(store.state.staff.count))", "Hiring Pool"])

            if mode == 0 { roster } else { hiring }
        }
    }

    private var roster: some View {
        Group {
            Panel {
                SectionHeader(text: "Active Bonuses")
                let counts = roleCounts()
                ForEach(StaffRole.allCases, id: \.self) { role in
                    InfoRow(label: role.label + " (" + role.effect + ")", value: "\(counts[role] ?? 0)",
                            tint: (counts[role] ?? 0) > 0 ? Brand.sky : Brand.faint)
                }
            }
            if store.state.staff.isEmpty {
                Panel { Text("No staff hired. Check the Hiring Pool.").font(.system(size: 13)).foregroundColor(Brand.faint) }
            } else {
                ForEach(store.state.staff) { st in
                    staffCard(st)
                }
            }
        }
    }

    private func staffCard(_ st: OwnedStaff) -> some View {
        Panel {
            HStack(spacing: 10) {
                rarityFrame(st.rarity)
                VStack(alignment: .leading, spacing: 2) {
                    Text(st.name).font(.system(size: 15, weight: .bold)).foregroundColor(Brand.jet)
                    Text("\(st.rarity.label) \(st.role.label.dropLast(st.role.label.hasSuffix("s") ? 1 : 0))")
                        .font(.system(size: 11)).foregroundColor(Brand.rarityColor(st.rarity))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(Fmt.money(st.salary) + "/wk").font(.system(size: 12, weight: .semibold, design: .monospaced)).foregroundColor(Brand.amber)
                    Button(action: { store.fire(st.id) }) {
                        Text("Dismiss").font(.system(size: 11, weight: .semibold)).foregroundColor(Brand.red)
                    }.buttonStyle(.plain)
                }
            }
        }
    }

    private var hiring: some View {
        Group {
            Text("The hiring pool refreshes every few weeks. Veterans give the strongest stacking bonuses.")
                .font(.system(size: 12)).foregroundColor(Brand.faint).lineSpacing(3)
            if store.state.hirePool.isEmpty {
                Panel { Text("Pool empty — it will refresh on the next Advance Week.").font(.system(size: 13)).foregroundColor(Brand.faint) }
            } else {
                ForEach(store.state.hirePool) { e in
                    hireCard(e)
                }
            }
        }
    }

    private func hireCard(_ e: HirePoolEntry) -> some View {
        let canHire = store.state.cash >= e.signingFee
        return Panel {
            HStack(spacing: 10) {
                rarityFrame(e.rarity)
                VStack(alignment: .leading, spacing: 2) {
                    Text(e.name).font(.system(size: 15, weight: .bold)).foregroundColor(Brand.jet)
                    Text("\(e.rarity.label) • \(e.role.label) • \(e.role.effect)")
                        .font(.system(size: 11)).foregroundColor(Brand.rarityColor(e.rarity))
                }
                Spacer()
            }
            HStack(spacing: 10) {
                StatChip(label: "Salary/wk", value: Fmt.money(e.salary))
                StatChip(label: "Signing fee", value: Fmt.money(e.signingFee), tint: Brand.amber)
            }
            Button(action: { store.hire(e) }) {
                Text("Hire").font(.system(size: 14, weight: .bold)).foregroundColor(canHire ? Brand.navyDeep : Brand.faint)
                    .frame(maxWidth: .infinity).padding(.vertical, 10)
                    .background(RoundedRectangle(cornerRadius: 10).fill(canHire ? Brand.sky : Brand.card))
            }.buttonStyle(.plain).disabled(!canHire)
        }
    }

    private func rarityFrame(_ r: Rarity) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10).fill(Brand.navyDeep).frame(width: 44, height: 44)
            RoundedRectangle(cornerRadius: 10).stroke(Brand.rarityColor(r), lineWidth: 2).frame(width: 44, height: 44)
            StrokedIcon(shape: PeopleIcon(), color: Brand.rarityColor(r), size: 24, line: 2)
        }
    }

    private func roleCounts() -> [StaffRole: Int] {
        var d: [StaffRole: Int] = [:]
        for s in store.state.staff { d[s.role, default: 0] += 1 }
        return d
    }
}
