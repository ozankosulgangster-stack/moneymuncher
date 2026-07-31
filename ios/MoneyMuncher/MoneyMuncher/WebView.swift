import Foundation
import SwiftUI
import WebKit

enum MoneyMuncherWebEvent: Equatable {
    case openFamilyQuest
}

struct MoneyMuncherWebView: UIViewRepresentable {
    let url: URL
    let onEvent: (MoneyMuncherWebEvent) -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onEvent: onEvent)
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        configuration.allowsInlineMediaPlayback = true
        configuration.defaultWebpagePreferences.allowsContentJavaScript = true
        configuration.mediaTypesRequiringUserActionForPlayback = []
        configuration.userContentController.add(context.coordinator, name: Coordinator.messageHandlerName)

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.uiDelegate = context.coordinator
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        webView.scrollView.keyboardDismissMode = .interactive
        webView.scrollView.alwaysBounceVertical = true

        context.coordinator.load(url, in: webView, configuration: configuration)

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {
        // The app shell only changes URLs by presenting a new web experience.
    }

    static func dismantleUIView(_ uiView: WKWebView, coordinator: Coordinator) {
        uiView.configuration.userContentController.removeScriptMessageHandler(forName: Coordinator.messageHandlerName)
        uiView.navigationDelegate = nil
        uiView.uiDelegate = nil
    }
}

extension MoneyMuncherWebView {
    final class Coordinator: NSObject, WKNavigationDelegate, WKUIDelegate, WKScriptMessageHandler {
        static let messageHandlerName = "moneyMuncher"

        private let onEvent: (MoneyMuncherWebEvent) -> Void
        private let allowedHosts = [
            "moneymuncher.ca",
            "www.moneymuncher.ca"
        ]

        init(onEvent: @escaping (MoneyMuncherWebEvent) -> Void) {
            self.onEvent = onEvent
        }

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

                    let request = URLRequest(
                        url: url,
                        cachePolicy: .reloadIgnoringLocalCacheData,
                        timeoutInterval: 30
                    )
                    webView.load(request)
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

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard message.name == Self.messageHandlerName, message.frameInfo.isMainFrame else { return }

            let eventName: String?
            if let body = message.body as? String {
                eventName = body
            } else if let body = message.body as? [String: Any] {
                eventName = body["type"] as? String
            } else {
                eventName = nil
            }

            guard eventName == "open-family-quest" else { return }
            DispatchQueue.main.async {
                self.onEvent(.openFamilyQuest)
            }
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
