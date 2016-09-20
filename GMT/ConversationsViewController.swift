//
//  ConversationsViewController.swift
//  GMT
//
//  Created by James O'Brien on 24/05/2016.
//  Copyright © 2016 James O'Brien. All rights reserved.
//

import UIKit
import SwiftyJSON


/// Manages a view that lists the conversations the user is currently a participant in
class ConversationsViewController: UIViewController {

    @IBOutlet var createGroupsButton: UIButton!
    @IBOutlet var contactsSwitch: UIButton!
    @IBOutlet var chatsSwitch: UIButton!
    @IBOutlet var userAvatar: AvatarGem!
    @IBOutlet var convoCollectionView: UICollectionView!
   

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }


    private func setup() {
        // TODO(james) don't really need to use notifications any more, fix this
        GroupMe.instance.notifications.addObserver(self, selector: #selector(ConversationsViewController.gotGroupMeNotification(_:)), name: .None, object: .None)
    }


    override func viewDidLoad() {
        super.viewDidLoad()
        contactsSwitch.alpha = 0.7
        createGroupsButton.setImage(GMTStyleKit.imageOfCreateGroup, forState: UIControlState.Normal)

        // Set ourself as the principle conversations list
        GroupMe.instance.Conversations.collectionView = self.convoCollectionView
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent;
    }


    // TODO(james): Shouldn't need this any more, listen for "me" updates instead
    @objc private func gotGroupMeNotification(notification: NSNotification) {
        switch notification.name {
        case GroupMe.kHaveAccessNotification:
            GroupMe.instance.me(gotMe)
        default:
            // Nothing
            break;
        }
    }


    private func gotMe(maybeMe: Person?) {
        guard let me = maybeMe else {
            return
        }

        userAvatar.avatarUrl = me.avatarUrl
    }
}
