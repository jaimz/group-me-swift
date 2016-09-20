//
//  Conversation.swift
//  GMT
//
//  Created by James O'Brien on 29/06/2016.
//  Copyright © 2016 James O'Brien. All rights reserved.
//

import UIKit
import SwiftyJSON

/// Types of conversation
enum ConversationType {
    /// A group conversation
    case Group

    /// A direct message conversation
    case Direct
}


/// Encapsulates a preview of a conversation, usually created from the last
/// message sent to it
class Preview {
    private(set) var nickname: String
    private(set) var text: String
    private(set) var avatarUrl: String? = .None
    private(set) var attachments : [ Attachment ] = []

    init(withGroupPreview preview:[String : JSON]) {
        nickname = preview["nickname"]?.string ?? ""
        text = preview["text"]?.string ?? ""
        avatarUrl = preview["image_url"]?.string

        if let attachmentsJson = preview["attachments"]?.array {
            self.attachments = attachmentsJson
                .map({ $0.dictionary })
                .flatMap({ $0 })
                .map({ try? Attachment(withJson: $0 )})
                .flatMap({ $0 })
        }
    }

    var messagePreview : String {
        get { return "\(nickname): \(text)" }
    }
}

/// Represents a GroupMe conversation. Used as a model for various bits of UI, principly
/// the chat list.
class Conversation {
    private(set) var conversationType : ConversationType = .Group

    private(set) var ID : String
    private(set) var name : String
    private(set) var description : String? = .None
    private(set) var avatarUrl : String? = .None

    private(set) var createdAt : NSDate? = .None
    private(set) var updatedAt : NSDate? = .None
    private(set) var updatedStamp : NSTimeInterval?

    private(set) var shareUrl : NSURL? = .None

    private(set) var members : [ (userId: String, nickname: String, mute: Bool, imageUrl: String) ]? = .None

    private(set) var preview : Preview? = .None

    private(set) var messages : MessageCollection


    /// Create a conversation given the JSON representation we get back from GroupMe
    init(withGroup groupDescription: [ String : JSON ]) {
        ID = groupDescription["id"]?.string ?? ""
        name = groupDescription["name"]?.string ?? "??"
        description = groupDescription["description"]?.string
        avatarUrl = groupDescription["image_url"]?.string

        if let createStamp = groupDescription["created_at"]?.double {
            createdAt = NSDate(timeIntervalSince1970: createStamp)
        }

        updatedStamp = groupDescription["updated_at"]?.double
        if let s = updatedStamp {
            updatedAt = NSDate(timeIntervalSince1970: s)
        }

        if let shareUrlString = groupDescription["share_url"]?.string
        {
            shareUrl = NSURL(string: shareUrlString)
        }

        if let previewJson = groupDescription["messages"]?["preview"].dictionary {
            preview = Preview(withGroupPreview: previewJson)
        }

        if let membersJson = groupDescription["members"]?.array {
            members = membersJson.map { m in
                ( m["user_id"].string ?? "",
                    m["nickname"].string ?? "",
                    m["muted"].bool ?? false,
                    m["image_url"].string ?? "" )
            }
        }

        messages = MessageCollection(conversationId: ID)
    }


    /// New messages have arrived for this conversation
    func appendMessages(newMessages: [ Message ]) {
        messages.append(newMessages)
    }


    /// Send a message to this conversation
    /// - Parameters:
    ///     - text: The text of the message
    ///     - attachments: Attachments to, err, attach to the message
    func sendMessage(text: String?, attachments: [ Attachment ]?) {
        guard (text != .None) || (attachments != nil) else {
            print("-=--= Need either text or attachments to send a message")
            return
        }

        // Append a tentative message so we get a representation in the UI
        let tentativeMessage = Message.tentativeMessage(forGroup: ID, withText: text, attachments: attachments)
        appendMessages([ tentativeMessage ])

        // Send the message
        GroupMe.instance.API.sendMessage(tentativeMessage) { json in
            print("Sent message!") }
    }


    /// Send an image to the conversation
    /// - Parameters:
    ///     - imageData: the data for the image to send
    func sendImage(imageData : NSData) {

        // Insert a tentative message into the chat while we do the upload
        let attachment = Attachment.tentativeAttachment(ofType: AttachmentType.Image, data: AttachmentData.Tentative(imageData))
        let tentativeMessage = Message.tentativeMessage(forGroup: ID, withText: nil, attachments: [ attachment ])
        appendMessages([ tentativeMessage ])


        GroupMe.instance.API.uploadImage(imageData) { (uploadResult : ImageUploadResult) in
            switch uploadResult {
            case .Succes(let imageUrl):
                // Update the tentative attachment with it's actual image service URL
                if let url = NSURL(string: imageUrl) {
                    Attachment.updateTentativeData(onAttachment: tentativeMessage.attachments[0],
                                                    withNewData: AttachmentData.Url(url))
                    GroupMe.instance.API.sendMessage(tentativeMessage) { json in
                        print("Sent image message")
                    }
                } else {
                    print("-=-=-= Could not create URL from image upload result: \(imageUrl)")
                }
                break
            case .Error(let errorMessage):
                print("-=-=-= Error sending image: \(errorMessage)")
                break
            }
        }
    }
}
