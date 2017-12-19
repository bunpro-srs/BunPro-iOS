//
//  ReviewViewController.swift
//  BunPuroKit
//
//  Created by Andreas Braun on 19.12.17.
//  Copyright © 2017 Andreas Braun. All rights reserved.
//

import UIKit
import WebKit

class ReviewViewController: UIViewController {

    @IBOutlet private weak var webView: WKWebView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let url = URL(string: "https://www.bunpro.jp/app_study")!
        var request = URLRequest(url: url)
        
        request.setValue("Token token=\(Server.token!)", forHTTPHeaderField: "Authorization")
        
        webView.load(request)
    }

    @IBAction func doneButtonPressed(_ sender: UIBarButtonItem) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
}
