import SwiftUI

@main
struct TapMintTycoonApp: App {
    @State private var mintTycoonLinkReady: Bool? = nil
    @StateObject private var store = MintTycoonStore()

    private let mintTycoonSourceLink = "https://example.com"
    private let mintTycoonCheckDomain = "example"

    var body: some Scene {
        WindowGroup {
            Group {
                if let ready = mintTycoonLinkReady {
                    if ready {
                        MintTycoonWebPanel(mintTycoonURLString: mintTycoonSourceLink)
                            .edgesIgnoringSafeArea(.all)
                    } else {
                        ContentView()
                            .environmentObject(store)
                    }
                } else {
                    MintTycoonLoadingScreen()
                        .onAppear { mintTycoonCheckLink() }
                }
            }
            .preferredColorScheme(.light)
        }
    }

    private func mintTycoonCheckLink() {
        guard let url = URL(string: mintTycoonSourceLink) else {
            mintTycoonLinkReady = false
            return
        }
        var request = URLRequest(url: url)
        request.timeoutInterval = 5
        let tracker = MintTycoonRedirectTracker(checkDomain: mintTycoonCheckDomain)
        let session = URLSession(configuration: .default, delegate: tracker, delegateQueue: nil)
        session.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if tracker.foundCheckDomain {
                    mintTycoonLinkReady = false; return
                }
                if let finalURL = tracker.resolvedURL?.absoluteString,
                   finalURL.contains(mintTycoonCheckDomain) {
                    mintTycoonLinkReady = false; return
                }
                if let httpResp = response as? HTTPURLResponse,
                   let respURL = httpResp.url?.absoluteString,
                   respURL.contains(mintTycoonCheckDomain) {
                    mintTycoonLinkReady = false; return
                }
                if error != nil {
                    mintTycoonLinkReady = false; return
                }
                mintTycoonLinkReady = true
            }
        }.resume()
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            if mintTycoonLinkReady == nil { mintTycoonLinkReady = false }
        }
    }
}

final class MintTycoonRedirectTracker: NSObject, URLSessionTaskDelegate {
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
