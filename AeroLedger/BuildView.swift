import SwiftUI

struct BuildView: View {
    @EnvironmentObject var store: GameStore

    var body: some View {
        ScreenScaffold("Build & Upgrade") {
            TopHUD()
            Text("Upgrade facilities to raise capacity and income. Each upgrade also raises weekly upkeep. Levels max at 5, then advance the tier (max 4).")
                .font(.system(size: 12)).foregroundColor(Brand.faint).lineSpacing(3)

            ForEach(FacilityKind.allCases, id: \.self) { kind in
                facilityCard(kind)
            }
        }
    }

    private func facilityCard(_ kind: FacilityKind) -> some View {
        let f = store.state.facility(kind)
        let info = store.canUpgradeFacility(kind)
        return Panel {
            HStack(spacing: 10) {
                facilityIcon(kind)
                VStack(alignment: .leading, spacing: 2) {
                    Text(kind.label).font(.system(size: 15, weight: .bold)).foregroundColor(Brand.jet)
                    Text(kind.blurb).font(.system(size: 11)).foregroundColor(Brand.faint)
                }
                Spacer()
            }
            TierLevelView(tier: f.tier, level: f.level)

            // current stats
            statRow(kind, f)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("UPKEEP / WK").font(.system(size: 9, weight: .bold)).foregroundColor(Brand.faint)
                    Text(Fmt.money(FacilityEcon.upkeep(kind: kind, tier: f.tier, level: f.level)))
                        .font(.system(size: 13, weight: .semibold, design: .monospaced)).foregroundColor(Brand.amber)
                }
                Spacer()
                if info.maxed {
                    Text("MAXED").font(.system(size: 13, weight: .heavy)).foregroundColor(Brand.green)
                        .padding(.horizontal, 16).padding(.vertical, 10)
                        .background(RoundedRectangle(cornerRadius: 10).stroke(Brand.green, lineWidth: 1))
                } else {
                    Button(action: { store.upgradeFacility(kind) }) {
                        VStack(spacing: 1) {
                            Text(f.level >= FacilityEcon.maxLevel ? "Advance Tier" : "Upgrade")
                                .font(.system(size: 13, weight: .bold))
                            Text(Fmt.money(info.cost)).font(.system(size: 11, weight: .semibold, design: .monospaced))
                        }
                        .foregroundColor(info.can ? Brand.navyDeep : Brand.faint)
                        .padding(.horizontal, 18).padding(.vertical, 9)
                        .background(RoundedRectangle(cornerRadius: 10).fill(info.can ? Brand.sky : Brand.card))
                    }
                    .buttonStyle(.plain)
                    .disabled(!info.can)
                }
            }
        }
    }

    @ViewBuilder
    private func statRow(_ kind: FacilityKind, _ f: OwnedFacility) -> some View {
        switch kind {
        case .terminal:
            InfoRow(label: "Weekly capacity", value: Fmt.int(Int(FacilityEcon.terminalCapacity(tier: f.tier, level: f.level))) + " pax")
        case .runway:
            InfoRow(label: "Flight cycles / route", value: "\(FacilityEcon.runwayCycles(tier: f.tier, level: f.level))")
            InfoRow(label: "Max aircraft tier", value: "Tier \(f.tier)", tint: Brand.sky)
        case .lounge:
            InfoRow(label: "Premium revenue / wk", value: Fmt.money(FacilityEcon.loungeBase(tier: f.tier, level: f.level)))
        case .retail:
            InfoRow(label: "Income / 1K pax", value: Fmt.money(FacilityEcon.retailPerK(tier: f.tier, level: f.level)))
        case .hotel:
            InfoRow(label: "Lodging revenue / wk", value: Fmt.money(FacilityEcon.hotelBase(tier: f.tier, level: f.level)))
        case .cargo:
            InfoRow(label: "Cargo multiplier", value: String(format: "%.2fx", FacilityEcon.cargoMult(tier: f.tier, level: f.level)))
        case .hangar:
            InfoRow(label: "Wear reduction", value: Fmt.pct(FacilityEcon.hangarWearReduction(tier: f.tier, level: f.level)))
        case .fuel:
            InfoRow(label: "Fuel discount", value: Fmt.pct(FacilityEcon.fuelDiscount(tier: f.tier, level: f.level)))
        }
    }
}
