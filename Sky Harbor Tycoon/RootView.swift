import SwiftUI

struct RootView: View {
    @EnvironmentObject var store: GameStore
    @State private var showMenu = true
    @State private var showOnboarding = false

    var body: some View {
        ZStack {
            Brand.navy.edgesIgnoringSafeArea(.all)
            if showMenu {
                MainMenuView(onPlay: {
                    if !store.state.hasSeenOnboarding {
                        showOnboarding = true
                    } else {
                        withAnimation { showMenu = false }
                    }
                })
                .transition(.opacity)
            } else {
                MainTabShell(onExitToMenu: { withAnimation { showMenu = true } })
                    .transition(.opacity)
            }
        }
        .fullScreenCover(isPresented: $showOnboarding, onDismiss: {
            store.markOnboarded()
            withAnimation { showMenu = false }
        }) {
            OnboardingView(onFinish: { showOnboarding = false })
                .environmentObject(store)
        }
    }
}

// MARK: - Custom tab shell
struct MainTabShell: View {
    @EnvironmentObject var store: GameStore
    let onExitToMenu: () -> Void
    @State private var tab = 0

    private func widthClamp(_ geo: GeometryProxy) -> CGFloat {
        min(geo.size.width, UIScreen.main.bounds.width)
    }

    var body: some View {
        GeometryReader { geo in
            let w = min(geo.size.width, UIScreen.main.bounds.width)
            ZStack(alignment: .bottom) {
                Brand.navy.edgesIgnoringSafeArea(.all)
                VStack(spacing: 0) {
                    Group {
                        switch tab {
                        case 0: NavigationView { AirportOverviewView(onExitToMenu: onExitToMenu) }.navigationViewStyle(StackNavigationViewStyle())
                        case 1: NavigationView { FleetView() }.navigationViewStyle(StackNavigationViewStyle())
                        case 2: NavigationView { RoutesView() }.navigationViewStyle(StackNavigationViewStyle())
                        case 3: NavigationView { FinanceView() }.navigationViewStyle(StackNavigationViewStyle())
                        case 4: NavigationView { MoreHubView(onExitToMenu: onExitToMenu) }.navigationViewStyle(StackNavigationViewStyle())
                        default: EmptyView()
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                    tabBar
                }
                .frame(width: w)
                .frame(maxWidth: .infinity)
            }
        }
        .sheet(isPresented: $store.showWeekResult) {
            WeekResultView()
                .environmentObject(store)
        }
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            tabButton(0, "Airport", AnyView(StrokedIcon(shape: TowerShape(), color: tint(0), size: 22)))
            tabButton(1, "Fleet", AnyView(FilledIcon(shape: PlaneShape(), color: tint(1), size: 20)))
            tabButton(2, "Routes", AnyView(StrokedIcon(shape: RouteIcon(), color: tint(2), size: 22)))
            tabButton(3, "Finance", AnyView(StrokedIcon(shape: CoinIcon(), color: tint(3), size: 22)))
            tabButton(4, "More", AnyView(StrokedIcon(shape: MenuDotsIcon(), color: tint(4), size: 22)))
        }
        .padding(.top, 8)
        .padding(.bottom, 4)
        .background(Brand.navyDeep.edgesIgnoringSafeArea(.bottom))
        .overlay(Rectangle().fill(Brand.stroke).frame(height: 1), alignment: .top)
    }

    private func tint(_ i: Int) -> Color { tab == i ? Brand.sky : Brand.faint }

    private func tabButton(_ i: Int, _ label: String, _ icon: AnyView) -> some View {
        Button(action: { tab = i }) {
            VStack(spacing: 5) {
                icon.frame(height: 24)
                Text(label)
                    .font(.system(size: 10, weight: tab == i ? .bold : .medium))
                    .foregroundColor(tint(i))
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}
