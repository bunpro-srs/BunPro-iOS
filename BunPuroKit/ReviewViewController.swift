//
//  ReviewViewController.swift
//  BunPuroKit
//
//  Created by Andreas Braun on 19.12.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import UIKit
import WebKit

protocol ReviewViewControllerDelegate: class {
    func reviewViewControllerDidFinish(_ controller: ReviewViewController)
}

class ReviewViewController: UIViewController, WKNavigationDelegate {

    weak var delegate: ReviewViewControllerDelegate?
    var reviewMode: Bool = true
    
    @IBOutlet private weak var webView: WKWebView! {
        didSet {
            webView.navigationDelegate = self
        }
    }
    
    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let url = URL(string: reviewMode ? "https://www.bunpro.jp/app_study" : "https://www.bunpro.jp")!
        var request = URLRequest(url: url)
        
        request.setValue("Token token=\(Server.token!)", forHTTPHeaderField: "Authorization")
        webView.alpha = 0.0
        webView.load(request)
    }

    @IBAction func doneButtonPressed(_ sender: UIBarButtonItem) {
        delegate?.reviewViewControllerDidFinish(self)
    }
    
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        print("didFinish")
        
        UIView.animate(withDuration: 0.5) {
            self.webView.alpha = 1.0
        }
        
        activityIndicatorView.stopAnimating()
    }
    
//    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
//
//        if let url = navigationAction.request.url, url.path == "/summary" {
//            decisionHandler(.cancel)
//
//            delegate?.reviewViewControllerDidFinish(self)
//
//            return
//        }
//
//        decisionHandler(.allow)
//    }
}
