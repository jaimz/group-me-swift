//
//  Gallery.swift
//  GMT
//
//  Created by James O'Brien on 13/09/2016.
//  Copyright © 2016 James O'Brien. All rights reserved.
//

import Foundation


/// A "Gallery" contains all the media shared within a conversation
/// TODO(james): This is actually just a filtered list of messages, does it
/// need to be a separate class?
class Gallery {
    private var mediaMessages : [ Message ] = []
    private var messageMap = [:]

    init() {

    }

    func haveNewMessages(messages: [Message]) {
        mediaMessages.appendContentsOf(messages.filter(Gallery.ShouldContain))
    }

    private static func ShouldContain(message: Message) -> Bool {
        return message.attachments.count > 0
    }
}