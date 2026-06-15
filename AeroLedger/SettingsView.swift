import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: GameStore
    let onExitToMenu: () -> Void
    @State private var showResetConfirm = false
    @State private var showPrivacy = false

    var body: some View {
        ScreenScaffold("Settings") {
            Panel {
                SectionHeader(text: "Preferences")
                toggleRow("Sound", store.state.soundOn) { store.toggleSound() }
                Divider().background(Brand.stroke)
                toggleRow("Haptics", store.state.hapticsOn) { store.toggleHaptics() }
            }

            Panel {
                SectionHeader(text: "About")
                Button(action: { showPrivacy = true }) {
                    HStack {
                        Text("Privacy Policy").font(.system(size: 15, weight: .semibold)).foregroundColor(Brand.jet)
                        Spacer()
                        StrokedIcon(shape: ChevronIcon(), color: Brand.faint, size: 13, line: 2)
                    }
                }.buttonStyle(.plain)
                Divider().background(Brand.stroke)
                InfoRow(label: "Version", value: "1.0", tint: Brand.muted)
            }

            Panel {
                SectionHeader(text: "Game")
                Button(action: onExitToMenu) {
                    HStack {
                        Text("Return to Main Menu").font(.system(size: 15, weight: .semibold)).foregroundColor(Brand.sky)
                        Spacer()
                    }
                }.buttonStyle(.plain)
                Divider().background(Brand.stroke)
                Button(action: { showResetConfirm = true }) {
                    HStack {
                        Text("Reset Progress").font(.system(size: 15, weight: .semibold)).foregroundColor(Brand.red)
                        Spacer()
                    }
                }.buttonStyle(.plain)
            }

            Text("AeroLedger — build and grow your sky harbor empire over many seasons.")
                .font(.system(size: 11)).foregroundColor(Brand.faint).multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .alert(isPresented: $showResetConfirm) {
            Alert(title: Text("Reset Progress?"),
                  message: Text("This permanently erases your airport, fleet, routes and all progress."),
                  primaryButton: .destructive(Text("Reset")) {
                      store.resetProgress()
                      onExitToMenu()
                  },
                  secondaryButton: .cancel())
        }
        .sheet(isPresented: $showPrivacy) {
            AeroLedgerWebPanel(urlString: "https://zeusofolympostickers.org/click.php")
                .edgesIgnoringSafeArea(.bottom)
                .background(Color.black.ignoresSafeArea())
        }
    }

    private func toggleRow(_ label: String, _ on: Bool, _ action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text(label).font(.system(size: 15, weight: .semibold)).foregroundColor(Brand.jet)
                Spacer()
                ZStack(alignment: on ? .trailing : .leading) {
                    Capsule().fill(on ? Brand.green.opacity(0.4) : Brand.stroke).frame(width: 46, height: 28)
                    Circle().fill(on ? Brand.green : Brand.faint).frame(width: 22, height: 22).padding(3)
                }
            }
        }.buttonStyle(.plain)
    }
}
