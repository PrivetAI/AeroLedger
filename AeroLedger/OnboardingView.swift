import SwiftUI

struct OnboardingView: View {
    let onFinish: () -> Void
    @State private var page = 0

    private let pages: [(String, String, AnyView)] = [
        ("Build Your Sky Harbor",
         "Construct and upgrade eight facility categories — terminals, runways, lounges, retail, hotels, cargo, hangars and fuel farms. Each tier and level raises capacity and income but also weekly upkeep.",
         AnyView(StrokedIcon(shape: GridIcon(), color: Brand.sky, size: 64, line: 3))),
        ("Fly the Network",
         "Buy or lease 12 aircraft across three classes. Open routes to 26 cities — gated by range and runway tier — and price Economy, Business and First cabins against demand.",
         AnyView(FilledIcon(shape: PlaneShape(), color: Brand.sky, size: 64))),
        ("Run the Economy",
         "Hire staff, advance research, take loans, and survive random events. Every Advance Week tick auto-simulates demand, runs all flights and updates your books.",
         AnyView(StrokedIcon(shape: CoinIcon(), color: Brand.amber, size: 64, line: 3))),
        ("Grow Your Reputation",
         "Passenger satisfaction and prestige unlock premium long-haul routes and partnerships. Climb six prestige ranks from Local Airfield to Global Sky Harbor.",
         AnyView(StrokedIcon(shape: TrophyIcon(), color: Brand.green, size: 64, line: 3))),
        ("Reach Your Goals",
         "Chase 20 contracts and 24 achievements. Track everything in Statistics. Tap Advance Week to begin — your first weeks are designed to be solvable, so experiment freely.",
         AnyView(StrokedIcon(shape: CheckIcon(), color: Brand.sky, size: 64, line: 4))),
    ]

    var body: some View {
        GeometryReader { geo in
            let w = min(geo.size.width, UIScreen.main.bounds.width)
            ZStack {
                Brand.navy.edgesIgnoringSafeArea(.all)
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        Button("Skip") { onFinish() }
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(Brand.muted)
                    }
                    .padding()

                    Spacer()
                    pages[page].2
                        .frame(height: 90)
                        .padding(.bottom, 30)
                    Text(pages[page].0)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(Brand.jet)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 28)
                    Text(pages[page].1)
                        .font(.system(size: 15))
                        .foregroundColor(Brand.muted)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 32)
                        .padding(.top, 14)
                    Spacer()

                    HStack(spacing: 8) {
                        ForEach(0..<pages.count, id: \.self) { i in
                            Capsule()
                                .fill(i == page ? Brand.sky : Brand.stroke)
                                .frame(width: i == page ? 22 : 8, height: 8)
                        }
                    }
                    .padding(.bottom, 24)

                    PrimaryButton(title: page == pages.count - 1 ? "Start Playing" : "Next") {
                        if page == pages.count - 1 { onFinish() }
                        else { withAnimation { page += 1 } }
                    }
                    .frame(width: min(320, w - 60))
                    .padding(.bottom, 44)
                }
                .frame(width: w)
                .frame(maxWidth: .infinity)
            }
        }
    }
}
