//
//  Message.swift
//  GMT
//
//  Created by James O'Brien on 30/06/2016.
//  Copyright © 2016 James O'Brien. All rights reserved.
//

import UIKit
import SwiftyJSON

/**
 A GroupMe message
 */
class Message {
    private(set) var ID : String
    private(set) var sourceGuid : String
    private(set) var createdAtStamp : Double?
    private(set) var createdAt : NSDate?

    // ID of the group this message was sent to (?)
    private(set) var groupId : String?

    // Sender's ID
    private(set) var userId : String?

    // Sender's name
    private(set) var name : String?

    // Sender's avatar
    private(set) var avatarUrl : String?

    // Text of the message
    private(set) var text : String?

    // ID's of user's that have favourited this message
    private(set) var favouritedBy : [ String ] = []

    // Attachment to this message
    private(set) var attachments : [ Attachment ] = []

    // True if this message is tentative (i.e. hasn't been acknowleged by the server yet
    private(set) var isTentative : Bool = false

    init(withJson json : [String : JSON]) throws {
        guard let _ = json["id"]?.string else {
            print("No ID in message JSON")
            throw GroupMeError.InvalidJson(message: "No ID in message JSON")
        }

        guard let _ = json["source_guid"]?.string else {
            print("-=-=-= No Source GUID")
            throw GroupMeError.InvalidJson(message: "No source Guid in message JSON")
        }

        ID = json["id"]!.string!
        sourceGuid = json["source_guid"]!.string!
        createdAtStamp = json["created_at"]?.double
        if let ca = createdAtStamp {
            createdAt = NSDate(timeIntervalSince1970: ca)
        }

        groupId = json["group_id"]?.string
        userId = json["user_id"]?.string
        name = json["name"]?.string
        avatarUrl = json["avatar_url"]?.string

        text = json["text"]?.string

        if let favJson = json["favourited_by"]?.array {
            favouritedBy = favJson.filter({ j -> Bool in
                return j != .None
            }).map({ idStr -> String in
                idStr.string!
            })
        }

        // Map the attachment JSON into an array of attachments, 
        // "flatMap" will pull out any .None and unwrap any .Some
        if let attachmentsJson = json["attachments"]?.array {
            attachments = attachmentsJson.map({ j -> Attachment? in
                                return try? Attachment(withJson: j.dictionary!)
            }).flatMap({ $0 })
        }
    }



    /// The dictionary of info needed to post this message to groupme
    var postInfo : [ String : [ String : AnyObject ] ]? {
        get {
            var dict : [ String : AnyObject ] = [ "source_guid" : self.sourceGuid ]
            if let text = self.text {
                dict["text"] = text
            }

            if self.attachments.count > 0 {
                dict["attachments"] = self.attachments.map({ $0.toDictionary() })
            }

            if dict.count > 0 {
                return [ "message" : dict ]
            }

            return .None
        }
    }



    // A private initialiser for creating tentative messages
    private init() {
        ID = "<Tentative>"
        sourceGuid = NSUUID().UUIDString
    }


    /// Generate a message that has not been accepted by the server yet
    static func tentativeMessage(forGroup groupId : String, withText text : String?, attachments : [ Attachment ]?) -> Message {
        let message = Message()

        message.groupId = groupId
        message.text = text
        if let a = attachments { message.attachments.appendContentsOf(a) }
        message.createdAt = NSDate()
        message.createdAtStamp = message.createdAt?.timeIntervalSince1970
        if let me = GroupMe.instance.Me {
            message.name = me.name
            message.userId = me.ID
            message.avatarUrl = me.avatarUrl
        }

        message.isTentative = true
        return message
    }
}


