import Foundation
import SwiftUI
import WebKit

struct MoneyMuncherWebView: UIViewRepresentable {
    let url: URL

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.contentInsetAdjustmentBehavior = .never

        context.coordinator.load(url, in: webView, configuration: configuration)

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // The app shell only changes URLs by presenting a new web experience.
    }
}

extension MoneyMuncherWebView {
    final class Coordinator: NSObject, WKNavigationDelegate {
        private let allowedHosts = [
            "moneymuncher.ca",
            "www.moneymuncher.ca"
        ]

        private let privacyRules = """
        [
          {
            "trigger": { "url-filter": ".*googletagmanager\\\\.com.*" },
            "action": { "type": "block" }
          },
          {
            "trigger": { "url-filter": ".*google-analytics\\\\.com.*" },
            "action": { "type": "block" }
          }
        ]
        """

        func load(_ url: URL, in webView: WKWebView, configuration: WKWebViewConfiguration) {
            WKContentRuleListStore.default().compileContentRuleList(
                forIdentifier: "MoneyMuncherPrivacyRules",
                encodedContentRuleList: privacyRules
            ) { ruleList, _ in
                DispatchQueue.main.async {
                    if let ruleList = ruleList {
                        configuration.userContentController.add(ruleList)
                    }

                    webView.load(URLRequest(url: url))
                }
            }
        }

        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            guard
                navigationAction.targetFrame?.isMainFrame == true,
                let host = navigationAction.request.url?.host?.lowercased()
            else {
                decisionHandler(.allow)
                return
            }

            let isFirstParty = allowedHosts.contains(host) || host.hasSuffix(".moneymuncher.ca")

            decisionHandler(isFirstParty ? .allow : .cancel)
        }
    }
}
