import SwiftUI

struct MainMenuView: View {
    @EnvironmentObject var store: GameStore
    let onPlay: () -> Void

    var body: some View {
        GeometryReader { geo in
            let w = min(geo.size.width, UIScreen.main.bounds.width)
            ZStack {
                Brand.navy.edgesIgnoringSafeArea(.all)
                // subtle runway lines backdrop
                MenuBackdrop().stroke(Brand.skyDim.opacity(0.10), lineWidth: 1)
                    .edgesIgnoringSafeArea(.all)

                VStack(spacing: 0) {
                    Spacer()
                    ZStack {
                        Circle().fill(Brand.card).frame(width: 130, height: 130)
                        Circle().stroke(Brand.sky.opacity(0.5), lineWidth: 2).frame(width: 130, height: 130)
                        PlaneShape().fill(Brand.sky).frame(width: 60, height: 60)
                    }
                    .padding(.bottom, 22)

                    Text("AERO")
                        .font(.system(size: 34, weight: .heavy))
                        .tracking(5)
                        .foregroundColor(Brand.jet)
                    Text("L E D G E R")
                        .font(.system(size: 15, weight: .semibold))
                        .tracking(8)
                        .foregroundColor(Brand.sky)
                        .padding(.top, 2)

                    if store.state.week > 1 || !store.state.routes.isEmpty {
                        VStack(spacing: 4) {
                            Text("Week \(store.state.week)  •  \(PrestigeCatalog.ranks[store.state.rankIndex].name)")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(Brand.muted)
                            Text(Fmt.money(store.state.cash))
                                .font(.system(size: 18, weight: .bold, design: .monospaced))
                                .foregroundColor(Brand.green)
                        }
                        .padding(.top, 18)
                    }

                    Spacer()

                    VStack(spacing: 12) {
                        PrimaryButton(title: store.state.week > 1 ? "Continue" : "Start Airport", action: onPlay)
                        GhostButton(title: "How to Play") { showGuide = true }
                    }
                    .frame(width: min(320, w - 60))
                    .padding(.bottom, 50)
                }
                .frame(width: w)
                .frame(maxWidth: .infinity)
            }
        }
        .sheet(isPresented: $showGuide) {
            NavigationView { GuideView() }.navigationViewStyle(StackNavigationViewStyle())
        }
    }

    @State private var showGuide = false
}

struct MenuBackdrop: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        let n = 7
        for i in 0...n {
            let y = rect.height * CGFloat(i) / CGFloat(n)
            p.move(to: CGPoint(x: 0, y: y))
            p.addLine(to: CGPoint(x: rect.width, y: y + 30))
        }
        return p
    }
}
