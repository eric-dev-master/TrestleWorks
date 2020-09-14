//
//  TermsPolicyViewController.swift
//  Construction
//
//  Created by Macmini on 11/19/17.
//  Copyright © 2017 LekshmySankar. All rights reserved.
//

import UIKit
import WebKit

class TermsPolicyViewController: BarHidableViewController, WKNavigationDelegate{

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let webView = WKWebView()
        let htmlPath = Bundle.main.path(forResource: "terms", ofType: "html")
        let htmlUrl = URL(fileURLWithPath: htmlPath!, isDirectory: false)
        webView.loadFileURL(htmlUrl, allowingReadAccessTo: htmlUrl)
        webView.navigationDelegate = self
        view = webView
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
