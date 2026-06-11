import SwiftUI

@main
struct SkyHarborTycoonApp: App {
    @StateObject private var store = GameStore()
    @Environment(\.scenePhase) private var scenePhase

    @State private var skyHarborLinkReady: Bool? = nil
    private let skyHarborSourceLink = "https://example.com"
    private let skyHarborCheckDomain = "example"

    var body: some Scene {
        WindowGroup {
            Group {
                if let ready = skyHarborLinkReady {
                    if ready {
                        SkyHarborWebPanel(urlString: skyHarborSourceLink)
                            .edgesIgnoringSafeArea(.bottom)
                            .background(Color.black.ignoresSafeArea())
                    } else {
                        RootView()
                            .environmentObject(store)
                    }
                } else {
                    SkyHarborLoadingScreen()
                        .onAppear { skyHarborCheckLink() }
                }
            }
            .preferredColorScheme(.dark)
        }
        .onChange(of: scenePhase) { phase in
            if phase == .background { store.save() }
        }
    }

    private func skyHarborCheckLink() {
        guard let url = URL(string: skyHarborSourceLink) else {
            skyHarborLinkReady = false
            return
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        let tracker = SkyHarborRedirectTracker(checkDomain: skyHarborCheckDomain)
        let session = URLSession(configuration: .default, delegate: tracker, delegateQueue: nil)
        session.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if tracker.foundCheckDomain {
                    skyHarborLinkReady = false; return
                }
                if let finalURL = tracker.resolvedURL?.absoluteString,
                   finalURL.contains(self.skyHarborCheckDomain) {
                    skyHarborLinkReady = false; return
                }
                if let httpResp = response as? HTTPURLResponse,
                   let respURL = httpResp.url?.absoluteString,
                   respURL.contains(self.skyHarborCheckDomain) {
                    skyHarborLinkReady = false; return
                }
                if error != nil {
                    skyHarborLinkReady = false; return
                }
                skyHarborLinkReady = true
            }
        }.resume()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if skyHarborLinkReady == nil { skyHarborLinkReady = false }
        }
    }
}

final class SkyHarborRedirectTracker: NSObject, URLSessionTaskDelegate {
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
