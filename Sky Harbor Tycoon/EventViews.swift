import SwiftUI

// Event choice presented before advancing the week.
struct EventChoiceSheet: View {
    @EnvironmentObject var store: GameStore
    let event: GameEventDef
    let onResolved: () -> Void

    var body: some View {
        GeometryReader { geo in
            let w = min(geo.size.width, UIScreen.main.bounds.width)
            ZStack {
                Brand.navy.edgesIgnoringSafeArea(.all)
                ScrollView {
                    VStack(spacing: 18) {
                        ZStack {
                            Circle().fill(Brand.card).frame(width: 80, height: 80)
                            StrokedIcon(shape: BellIcon(), color: Brand.amber, size: 38, line: 2.5)
                        }
                        .padding(.top, 30)

                        Text("WEEKLY EVENT").font(.system(size: 11, weight: .bold)).tracking(2).foregroundColor(Brand.amber)
                        Text(event.title).font(.system(size: 22, weight: .bold)).foregroundColor(Brand.jet)
                            .multilineTextAlignment(.center)
                        Text(event.body).font(.system(size: 14)).foregroundColor(Brand.muted)
                            .multilineTextAlignment(.center).lineSpacing(4).padding(.horizontal, 8)

                        VStack(spacing: 12) {
                            ForEach(0..<event.choices.count, id: \.self) { i in
                                let c = event.choices[i]
                                Button(action: {
                                    store.applyEventChoice(c)
                                    onResolved()
                                }) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(c.label).font(.system(size: 15, weight: .bold)).foregroundColor(Brand.jet)
                                        Text(c.outcome).font(.system(size: 12)).foregroundColor(Brand.muted)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(14)
                                    .background(RoundedRectangle(cornerRadius: 12).fill(Brand.cardRaised))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Brand.stroke, lineWidth: 1))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.top, 8)
                        Spacer(minLength: 30)
                    }
                    .padding(20)
                    .frame(width: w)
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

// Events & News list
struct EventsNewsView: View {
    @EnvironmentObject var store: GameStore

    var body: some View {
        ScreenScaffold("Events & News") {
            TopHUD()
            if let id = store.state.pendingEventID, let ev = EventCatalog.events.first(where: { $0.id == id }) {
                Panel {
                    HStack(spacing: 8) {
                        StrokedIcon(shape: BellIcon(), color: Brand.amber, size: 18, line: 2)
                        Text("Pending Event").font(.system(size: 13, weight: .bold)).foregroundColor(Brand.amber)
                        Spacer()
                    }
                    Text(ev.title).font(.system(size: 16, weight: .bold)).foregroundColor(Brand.jet)
                    Text(ev.body).font(.system(size: 13)).foregroundColor(Brand.muted)
                    Text("Resolve this when you tap Advance Week on the Airport screen.")
                        .font(.system(size: 11)).foregroundColor(Brand.faint)
                }
            }

            Panel {
                SectionHeader(text: "News Ticker")
                if store.state.news.isEmpty {
                    Text("No news yet.").font(.system(size: 13)).foregroundColor(Brand.faint)
                } else {
                    ForEach(store.state.news) { item in
                        HStack(alignment: .top, spacing: 8) {
                            Circle().fill(item.positive ? Brand.green : Brand.amber).frame(width: 7, height: 7).padding(.top, 5)
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.text).font(.system(size: 13)).foregroundColor(Brand.jet)
                                Text("Week \(item.week)").font(.system(size: 10)).foregroundColor(Brand.faint)
                            }
                            Spacer()
                        }
                        if item.id != store.state.news.last?.id {
                            Divider().background(Brand.stroke)
                        }
                    }
                }
            }
        }
    }
}
