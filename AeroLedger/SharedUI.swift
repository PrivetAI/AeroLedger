import SwiftUI

// Top HUD bar showing cash, week, prestige — used inside screens.
struct TopHUD: View {
    @EnvironmentObject var store: GameStore
    var body: some View {
        HStack(spacing: 10) {
            hudItem("CASH", Fmt.money(store.state.cash), store.state.cash >= 0 ? Brand.green : Brand.red)
            hudItem("WEEK", "\(store.state.week)", Brand.jet)
            hudItem("DEBT", Fmt.money(store.state.debt), store.state.debt > 0 ? Brand.amber : Brand.muted)
        }
    }
    private func hudItem(_ l: String, _ v: String, _ c: Color) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(l).font(.system(size: 8, weight: .bold)).tracking(0.5).foregroundColor(Brand.faint)
            Text(v).font(.system(size: 13, weight: .bold, design: .monospaced)).foregroundColor(c)
                .lineLimit(1).minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// Advance-week action bar shown at top of overview.
struct AdvanceWeekChip: View {
    @EnvironmentObject var store: GameStore
    let onAdvance: () -> Void
    var body: some View {
        Button(action: onAdvance) {
            HStack(spacing: 10) {
                StrokedIcon(shape: ChevronIcon(), color: Brand.navyDeep, size: 16, line: 2.5)
                VStack(alignment: .leading, spacing: 1) {
                    Text("ADVANCE WEEK").font(.system(size: 13, weight: .heavy)).tracking(1)
                        .foregroundColor(Brand.navyDeep)
                    if store.state.pendingEventID != nil {
                        Text("An event awaits").font(.system(size: 10, weight: .semibold)).foregroundColor(Brand.navyDeep.opacity(0.8))
                    } else {
                        Text("Simulate week \(store.state.week)").font(.system(size: 10, weight: .semibold)).foregroundColor(Brand.navyDeep.opacity(0.7))
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .background(RoundedRectangle(cornerRadius: 13).fill(Brand.amber))
        }
        .buttonStyle(.plain)
    }
}

// Progress bar
struct BarView: View {
    var value: Double // 0..1
    var color: Color = Brand.sky
    var height: CGFloat = 7
    var body: some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(Brand.navyDeep)
                Capsule().fill(color).frame(width: max(0, min(1, value)) * g.size.width)
            }
        }
        .frame(height: height)
    }
}

// Tier/level pips
struct TierLevelView: View {
    let tier: Int
    let level: Int
    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 3) {
                Text("T").font(.system(size: 9, weight: .bold)).foregroundColor(Brand.faint)
                ForEach(1...FacilityEcon.maxTier, id: \.self) { i in
                    Circle().fill(i <= tier ? Brand.sky : Brand.stroke).frame(width: 7, height: 7)
                }
            }
            HStack(spacing: 3) {
                Text("L").font(.system(size: 9, weight: .bold)).foregroundColor(Brand.faint)
                ForEach(1...FacilityEcon.maxLevel, id: \.self) { i in
                    RoundedRectangle(cornerRadius: 1).fill(i <= level ? Brand.amber : Brand.stroke)
                        .frame(width: 6, height: 7)
                }
            }
        }
    }
}

// A simple labeled row
struct InfoRow: View {
    let label: String
    let value: String
    var tint: Color = Brand.jet
    var body: some View {
        HStack {
            Text(label).font(.system(size: 13)).foregroundColor(Brand.muted)
            Spacer()
            Text(value).font(.system(size: 13, weight: .semibold, design: .monospaced)).foregroundColor(tint)
        }
    }
}

// Section container with padding
struct Panel<Content: View>: View {
    let content: Content
    init(@ViewBuilder content: () -> Content) { self.content = content() }
    var body: some View {
        VStack(alignment: .leading, spacing: 12) { content }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .card()
    }
}

// Screen scaffold clamping width for iPad
struct ScreenScaffold<Content: View>: View {
    let title: String
    var trailing: AnyView? = nil
    let content: Content
    init(_ title: String, trailing: AnyView? = nil, @ViewBuilder content: () -> Content) {
        self.title = title; self.trailing = trailing; self.content = content()
    }
    var body: some View {
        GeometryReader { geo in
            let w = min(geo.size.width, UIScreen.main.bounds.width)
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    content
                }
                .padding(16)
                .frame(width: w)
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)
            .background(Brand.navy.edgesIgnoringSafeArea(.all))
        }
        .navigationBarTitle(title, displayMode: .inline)
        .navigationBarItems(trailing: trailing ?? AnyView(EmptyView()))
    }
}

// Custom segmented control (no system components).
struct SegmentBar: View {
    @Binding var selection: Int
    let options: [String]
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<options.count, id: \.self) { i in
                Button(action: { withAnimation(.easeInOut(duration: 0.15)) { selection = i } }) {
                    Text(options[i])
                        .font(.system(size: 13, weight: selection == i ? .bold : .semibold))
                        .foregroundColor(selection == i ? Brand.navyDeep : Brand.muted)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(selection == i ? Brand.sky : Color.clear)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(4)
        .background(RoundedRectangle(cornerRadius: 12, style: .continuous).fill(Brand.navyDeep))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(Brand.stroke, lineWidth: 1))
    }
}
