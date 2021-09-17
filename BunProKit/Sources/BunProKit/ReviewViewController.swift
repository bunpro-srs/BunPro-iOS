//
//  Created by Andreas Braun on 19.12.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import CoreData
import UIKit
import WebKit
import SafariServices

protocol ReviewViewControllerDelegate: AnyObject {
    func reviewViewControllerDidFinish(_ controller: ReviewViewController)
    func reviewViewControllerWillOpenGrammar(_ controller: ReviewViewController, identifier: Int)
}

public enum Website {
    case main
    case review
    case study
    case cram

    var url: URL {
        switch self {
        case .main:
            return URL(string: "https://bunpro.jp")!

        case .review:
            return URL(string: "https://bunpro.jp/app_study")!

        case .study:
            return URL(string: "https://bunpro.jp/app_learn")!

        case .cram:
            return URL(string: "https://bunpro.jp/app_cram")!
        }
    }
}

public final class ReviewViewController: UIViewController, WKNavigationDelegate {
    
    weak var delegate: ReviewViewControllerDelegate?
    
    public var website: Website = .main {
        didSet {
            guard oldValue != website else { return }

            loadWebsite()
        }
    }

    private var webView: WKWebView! {
        didSet {
            webView.navigationDelegate = self
        }
    }
    
    private var activityIndicator: UIActivityIndicatorView!

    override public func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        activityIndicator = UIActivityIndicatorView(style: .medium)
        
        activityIndicator.hidesWhenStopped = true
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneButtonPressed(_:)))
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: activityIndicator)
        
        activityIndicator.startAnimating()
        
        webView = WKWebView()
        webView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(webView)
        
        NSLayoutConstraint.activate([
            webView.topAnchor.constraint(equalTo: view.topAnchor),
            view.bottomAnchor.constraint(equalTo: webView.bottomAnchor),
            webView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: webView.trailingAnchor)
        ])
        
        loadWebsite()
    }

    private func loadWebsite() {
        guard let token = Server.token else {
            return
        }

        var request = URLRequest(url: website.url)

        request.setValue("Token token=\(token)", forHTTPHeaderField: "Authorization")
        webView?.alpha = 0.0
        webView?.load(request)
    }

    @IBAction private func doneButtonPressed(_ sender: UIBarButtonItem) {
        delegate?.reviewViewControllerDidFinish(self)
    }

    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        UIView.animate(withDuration: 0.5) {
            self.webView.alpha = 1.0
            self.activityIndicator.stopAnimating()
        }
    }
    
    public func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        
        if isValidBunproURL(navigationAction.request.url) {
            if let identifier = grammarPointIdentifier(for: navigationAction.request.url) {
                delegate?.reviewViewControllerWillOpenGrammar(self, identifier: identifier)
                decisionHandler(.cancel)
            } else {
                decisionHandler(.allow)
            }
        } else {
            if let url = navigationAction.request.url {
                let safariViewController = SFSafariViewController(url: url)
                present(safariViewController, animated: true)
            }
            
            decisionHandler(.cancel)
        }
    }
    
    private func isValidBunproURL(_ url: URL?) -> Bool {
        if url?.scheme == "about" { return true }
        guard let host = url?.host else { return false }
        return [
            "www.bunpro.jp",
            "bunpro.jp",
            "js.stripe.com",
            "m.stripe.network"
        ].contains(host)
    }
    
    private func grammarPointIdentifier(for url: URL?) -> Int? {
        guard
            url?.pathComponents.contains("grammar_points") ?? false,
            let idString = url?.pathComponents.last,
            let id = Int(idString)
            else { return nil }
        
        print(id)
        
        return id
    }
}
