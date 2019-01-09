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

final public class ReviewViewController: UIViewController, WKNavigationDelegate {

    weak var delegate: ReviewViewControllerDelegate?
    public var website: Website = .main {
        didSet {
            guard oldValue != website else {
                return
            }
            
            loadWebsite()
        }
    }
    
    @IBOutlet private weak var webView: WKWebView! {
        didSet {
            webView.navigationDelegate = self
        }
    }
    
    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        
        loadWebsite()
    }
    
    private func loadWebsite() {
        activityIndicatorView?.startAnimating()
        
        guard let token = Server.token else {
            activityIndicatorView.stopAnimating()
            return
        }
        
        var request = URLRequest(url: website.url)
        
        request.setValue("Token token=\(token)", forHTTPHeaderField: "Authorization")
        webView?.alpha = 0.0
        webView?.load(request)
    }

    @IBAction func doneButtonPressed(_ sender: UIBarButtonItem) {
        delegate?.reviewViewControllerDidFinish(self)
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        
        print("didFinish")
        
        UIView.animate(withDuration: 0.5) {
            self.webView.alpha = 1.0
        }
        
        activityIndicatorView.stopAnimating()
    }
}
