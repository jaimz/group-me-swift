//
//  AppStateNavigationController.swift
//  GMT
//
//  Created by James O'Brien on 22/05/2016.
//  Copyright © 2016 James O'Brien. All rights reserved.
//

import UIKit


class AppStateNavigationController: UINavigationController {

    // Shows the oauth web interface
    let authController = AuthenticationViewController()

    // Shows the messages in a selected conversation
    let messagesViewController = MessagesViewController(nibName: "MessagesViewController", bundle: .None)



    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)
        self.setup()
    }


    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil);
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);
    }

   
    private func setup() {
        self.navigationBarHidden = true
        self.toolbarHidden = true


        GroupMe.instance.notifications.addObserver(self,
                                                   selector: #selector(gotGroupMeNotification(_:)),
                                                   name: .None,
                                                   object: .None)

    }


    @objc private func gotGroupMeNotification(notification: NSNotification) {
        switch notification.name {
        case GroupMe.kNeedAuthenticationNotification:
            self.pushViewController(authController, animated: true)
            break
        case GroupMe.kHaveAccessNotification:
            if self.visibleViewController == authController {
                self.popViewControllerAnimated(true)
            }
            break
        default:
            break
        }
    }


    func goToConversation(withId conversationId : String) {
        let store = GroupMe.instance.Conversations
        if let convo = store[conversationId] {
            goToConversation(convo)
        }
    }


    func goToConversation(conversation: Conversation) {
        self.messagesViewController.conversation = conversation
        self.pushViewController(self.messagesViewController, animated: true)
    }



    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}


