//
//  AuthenticationViewController.swift
//  GMT
//
//  Created by James O'Brien on 20/05/2016.
//  Copyright © 2016 James O'Brien. All rights reserved.
//

import UIKit
import WebKit

/// ViewController that displays the GroupMe OAuth interface
class AuthenticationViewController: UIViewController, WKNavigationDelegate {
    private var webView: WKWebView?

    override func loadView() {
        webView = WKWebView()
        webView?.navigationDelegate = self

        view = webView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let api = GroupMe.instance.API
        if let url = api.authenticationUrl, wv = webView {
            let req = NSURLRequest(URL: url)
            wv.loadRequest(req)
        } else {
            print("Could not load oauth page")
        }
    }

    func webView(webView: WKWebView, decidePolicyForNavigationAction navigationAction: WKNavigationAction, decisionHandler: (WKNavigationActionPolicy) -> Void) {
        let app = UIApplication.sharedApplication()

        let api = GroupMe.instance.API
        if let url = navigationAction.request.URL {
            if (url.scheme == api.deepLinkScheme && app.canOpenURL(url)) {
                app.openURL(url)
                decisionHandler(WKNavigationActionPolicy.Cancel)
                return
            }
        }

        decisionHandler(WKNavigationActionPolicy.Allow)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}
