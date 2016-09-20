//
//  AttachmentCollection.swift
//  GMT
//
//  Created by James O'Brien on 01/07/2016.
//  Copyright © 2016 James O'Brien. All rights reserved.
//

import UIKit
import SwiftyJSON

/// The attachment types currently offered in GroupMe
enum AttachmentType : String {
    case Image = "image"
    case Video = "video"
    case Split = "split"
    case Emoji = "emoji"
    case Document = "document"
    case Location = "location"
    case Event = "event"
}

/** 
    The various kinds of attachment data that can be supplied with attachments 
 
    - Url: a url supplied with an image or video attachment
    - Location: location data for a location attachment
    - Emoji: the placeholder sting and charmap for an emoji attachment
    - FileId: the groupme fileid for a shared file
 */
enum AttachmentData {
    case Url(NSURL)
    case Location(lat: String, lon: String, name: String)
    case Token(String)
    case Emoji(placeholder: String, charmap: [[Int]])
    case FileId(String)
    case EventInfo
    case Tentative(NSData)

    /// Return an attachement data instance for the given attachment type, given the
    /// JSON encoding of that data
    static func dataForType(type: AttachmentType, json: [String : JSON]) -> AttachmentData? {
        var result : AttachmentData? = .None

        switch type {
        case .Image:
            fallthrough
        case .Video:
            if let urlStr = json["url"]?.string {
                if let url = NSURL(string: urlStr) {
                    result = AttachmentData.Url(url)
                }
            }
            break;

        case .Document:
            if let fileIdStr = json["file_id"]?.string {
                result = AttachmentData.FileId(fileIdStr)
            }
            break

        case .Split:
            if let tokenStr = json["token"]?.string {
                result = AttachmentData.Token(tokenStr)
            }
            break
        case .Location:
            if let lat = json["lat"]?.string, lon = json["lon"]?.string, name = json["name"]?.string {
                result = AttachmentData.Location(lat: lat, lon: lon, name: name)
            }
            break
        case .Emoji:
            // TODO(james): This will crash if any of the options are .None DON'T SHIP
            // (need a smarter way of unwrapping the nested array)
            if let placeholder = json["placeholder"]?.string, json_cmap = json["charmap"]?.array {
                let cmap = json_cmap.map { packOffsetJson in packOffsetJson.array!.map { jint in jint.int! }}
                result = AttachmentData.Emoji(placeholder: placeholder, charmap: cmap)
            }
            break;
        case .Event:
            result = AttachmentData.EventInfo
            break
        }

        return result
    }

    /// Convert the attachment data to a dictionary, usually because we are about to
    /// POST it to GroupMe
    func toDictionary() -> [ String : String ] {
        var dict : [ String : String ] = [ : ]
        switch self {
        case .Url(let url):
            dict["url"] = url.absoluteString
            break
        case .Location(lat: let lat, lon: let lon, name: let name):
            dict["lat"] = lat
            dict["lon"] = lon
            dict["name"] = name
            break
        case .Emoji(placeholder: _, charmap: _):
            // Don't care yet
            break;
        case .Token(let tokenString):
            dict["token"] = tokenString
            break
        case .FileId(let fileIdString):
            dict["file_id"] = fileIdString
            break
        case .EventInfo:
            // Huh?
            break
        case .Tentative(_):
            // nothing - tentative data is uploaded separately
            break
        }

        return dict

    }
}


/**
 A message attachment
 */
class Attachment {
    private(set) var type: AttachmentType
    private(set) var data: AttachmentData

    // Hmmmm
    private(set) var tentativePreviewData: NSData?

    /// true if this represents an attachment that is currently being processed on the server
    private(set) var isTentative = false


    init(withJson json:[String : JSON]) throws {
        guard let typeStr = json["type"]?.string else {
            throw GroupMeError.InvalidJson(message: "No attachment type in attachment json")
        }

        guard let maybeAT = AttachmentType(rawValue: typeStr) else {
            throw GroupMeError.InvalidResponseData(message: "Unrecognised attachment type \(typeStr)")
        }

        type = maybeAT

        guard let maybeData = AttachmentData.dataForType(type, json: json) else {
            throw GroupMeError.InvalidResponseData(message: "Can't parse attachment data")
        }


        data = maybeData
    }


    // NOTE: These 'toDictionary' methods feel very Java'ish and wrong - there
    // must be a more functional way of doing this...
    func toDictionary() -> [ String : String ] {
        var dict : [ String : String ] = [ "type" : type.rawValue ]
        for (k,v) in data.toDictionary() {
            dict[k] = v
        }

        return dict
    }


    private init(type: AttachmentType, data: AttachmentData) {
        self.type = type
        self.data = data
    }



    static func tentativeAttachment(ofType type : AttachmentType, data: AttachmentData) -> Attachment {
        let a = Attachment(type: type, data: data)
        a.isTentative = true

        return a
    }


    static func updateTentativeData(onAttachment attachment : Attachment, withNewData data : AttachmentData) {
        attachment.data = data
    }


    static func viewForAttachment(attachment : Attachment) -> UIView? {
        var result : UIView? = .None
        let data = attachment.data
        switch attachment.type {
        case .Image:
            let imageView = UIImageView()
            switch data {
            case .Tentative(let imageData):
                imageView.image = UIImage(data: imageData)
                break;
            case .Url(let imageUrl):
                imageView.af_setImageWithURL(imageUrl)
                break
            default:
                print("-=-=-= Unexpected data for image attachment: \(data)")
                break
            }

            result = imageView
        default:
            // Nothing yet...
            break
        }

        return result
    }
}
