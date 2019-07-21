//
//  Created by Andreas Braun on 19.12.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import UIKit
import WebKit

protocol ReviewViewControllerDelegate: class {
    func reviewViewControllerDidFinish(_ controller: ReviewViewController)
}

public enum Website {
    case main
    case review
    case study
    case cram

    var url: URL {
        switch self {
        case .main:
            return URL(string: "https://www.bunpro.jp")!

        case .review:
            return URL(string: "https://www.bunpro.jp/app_study")!

        case .study:
            return URL(string: "https://www.bunpro.jp/app_learn")!

        case .cram:
            return URL(string: "https://www.bunpro.jp/app_cram")!
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
        
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
            activityIndicator = UIActivityIndicatorView(style: .medium)
        } else {
            view.backgroundColor = .white
            activityIndicator = UIActivityIndicatorView(style: .gray)
        }
        
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
}
