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
        webView.uiDelegate = context.coordinator
        webView.scrollView.contentInsetAdjustmentBehavior = .never

        context.coordinator.load(url, in: webView, configuration: configuration)

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // The app shell only changes URLs by presenting a new web experience.
    }
}

extension MoneyMuncherWebView {
    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate {
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

        private func presentingViewController(for webView: WKWebView) -> UIViewController? {
            var responder: UIResponder? = webView
            while let current = responder {
                if let viewController = current as? UIViewController {
                    return viewController
                }
                responder = current.next
            }
            return nil
        }

        func webView(
            _ webView: WKWebView,
            runJavaScriptAlertPanelWithMessage message: String,
            initiatedByFrame frame: WKFrameInfo,
            completionHandler: @escaping () -> Void
        ) {
            guard let presenter = presentingViewController(for: webView) else {
                completionHandler()
                return
            }

            let alert = UIAlertController(title: "Money Muncher", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default) { _ in completionHandler() })
            presenter.present(alert, animated: true)
        }

        func webView(
            _ webView: WKWebView,
            runJavaScriptConfirmPanelWithMessage message: String,
            initiatedByFrame frame: WKFrameInfo,
            completionHandler: @escaping (Bool) -> Void
        ) {
            guard let presenter = presentingViewController(for: webView) else {
                completionHandler(false)
                return
            }

            let alert = UIAlertController(title: "Money Muncher", message: message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in completionHandler(false) })
            alert.addAction(UIAlertAction(title: "Continue", style: .default) { _ in completionHandler(true) })
            presenter.present(alert, animated: true)
        }
    }
}
