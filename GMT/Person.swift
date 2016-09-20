//
//  Person.swift
//  GMT
//
//  Created by James O'Brien on 04/07/2016.
//  Copyright © 2016 James O'Brien. All rights reserved.
//

import Foundation

import SwiftyJSON

/**
 A person in the groupme system (usually yourself or a contact)
 */
class Person {
    private(set) var ID : String
    private(set) var name : String? = .None
    private(set) var avatarUrl : String? = .None
    private(set) var email : String? = .None
    private(set) var createdAt : NSDate? = .None
    private(set) var updatedAt : NSDate? = .None
    private(set) var phone : String? = .None
    private(set) var sms : Bool

    init(withJson json:JSON) throws {
        guard json["id"].string != nil else {
            print("No ID in person JSON")
            throw GroupMeError.InvalidJson(message: "No ID in user JSON")
        }

        ID = json["id"].string!
        name = json["name"].string
        avatarUrl = json["image_url"].string
        email = json["email"].string
        phone = json["phone"].string
        sms = json["sms"].bool ?? false

        if let created_stamp = json["created_at"].double {
            createdAt = NSDate(timeIntervalSince1970: created_stamp)
        }

        if let updated_stamp = json["updated_at"].double {
            updatedAt = NSDate(timeIntervalSince1970: updated_stamp)
        }
    }


    /// Update this instance with updated information from the GroupMe server.
    /// Returns a list of updates to pipe through to any consumers of the Me object
    func update(withJson newJson:JSON) throws -> [Update]? {
        var diffs : [ Update ] = []
        let jsonName = newJson["name"].string
        let jsonAvatar = newJson["avatar"].string

        if let newName = jsonName {
            if (name != .None) && (name! != newName) {
                name = newName
                diffs.append(Update.Participant(ParticipantUpdate.Name(id: self.ID, newName: newName)))
            }
        }

        if let newAvatar = jsonAvatar {
            if (avatarUrl != .None && avatarUrl != newAvatar) {
                avatarUrl = newAvatar
                diffs.append(Update.Participant(ParticipantUpdate.AvatarUrl(id: self.ID, newAvatar: newAvatar)))
            }
        }


        if diffs.count > 0 {
            return diffs
        } else {
            return .None
        }
    }
}