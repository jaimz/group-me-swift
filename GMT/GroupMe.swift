//
//  GroupMe.swift
//  GMT
//
//  Created by James O'Brien on 04/07/2016.
//  Copyright © 2016 James O'Brien. All rights reserved.
//

import UIKit
import SwiftyJSON

/**
 Models 'GroupMe' as an abstract entity. Other classes call into this
 to send and recieve messages without worrying about the REST prototcol,
 concurrency etc.
 */
class GroupMe {

    // MARK: Notification names

    /** Notification posted when we need to authenticate with GroupMe.
        Consumers should transition to a web view showing the GroupMe auth
        page. */
    static let kNeedAuthenticationNotification = "groupme.auth.required"

    /** Notification posted when authentication with GroupMe failed */
    static let kAuthenticationFailed = "groupme.auth.failed"

    /** Notification posted when we have access to groupme (after a successful
        authentication or when authentication is unecessary */
    static let kHaveAccessNotification = "groupme.access.gained"

    /** Notification posted when we have the user's account info.
        The data object of the notification will be the Person object
        for the user. */
    static let kHaveMeNotification = "groupme.me.loaded"

    /** Notification posted wen the conversation list is updated.
        The data object associated with the notification will point to
        the conversation store */
    static let kConversationsUpdatedNotification = "groupme.convos.update"


    /// The global instance of this class
    static let instance = GroupMe()


    /** Listen to this for notifications about changing GroupMe state */
    let notifications = NSNotificationCenter()


    /// Incoming updates from GroupMe
    let Updates = GroupMeUpdates()

    /// A store of all the conversations the current user is part of
    let Conversations = ConversationStore()

    /// The current user
    var Me : Person?


    /// Handles communication with GroupMe's REST API
    let API = GroupMeAPI()



    /**
      Connect to GroupMe (and authenticate if necessary)
    */
    func connect() {
        if  API.accessToken == .None {
            notifications.postNotificationName(GroupMe.kNeedAuthenticationNotification, object: self)
        } else {
            notifications.postNotificationName(GroupMe.kHaveAccessNotification, object: self)
            begin()
        }
    }


    /// Authentication completed (not neccessarily successfuly)
    func didAuthenticate(newAccessToken: String?) {
        API.accessToken = newAccessToken
        switch newAccessToken {
        case .None:
            notifications.postNotificationName(GroupMe.kAuthenticationFailed, object: self)
        case .Some(_):
            notifications.postNotificationName(GroupMe.kHaveAccessNotification, object: self)
            begin()
        }
    }

    /// Start cominucating with GroupMe and listen for incoming updates
    private func begin() {
        self.restoreState()
        self.beginUpdateFlow()
    }

    /// Restore the conversation state from the previous invocation of the app
    func restoreState() {
        // TODO: Load and save state from some backing store
    }

    /// Start listening for updates from GroupMe
    func beginUpdateFlow() {
        self.Conversations.updateSource = self.Updates

        // TODO(james): Remove NOW
        self.Updates.startNOW()
    }


    // TODO(james): Remove - everything using this should use the
    // "Me" object instead
    func me(completion: (Person? -> ())) {
        if let _ = self.Me {
            completion(self.Me)
        } else {
            API.me { json in
                if let meJson = json {
                    self.Me = try? Person(withJson: meJson)
                }

                 completion(self.Me)
            }
        }
    }
}
