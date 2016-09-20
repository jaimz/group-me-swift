//
//  GroupMeError.swift
//  GMT
//
//  Created by James O'Brien on 05/07/2016.
//  Copyright © 2016 James O'Brien. All rights reserved.
//

import Foundation

enum GroupMeError : ErrorType {
    case InvalidJson(message:String)
    case InvalidResponseData(message:String)
    case BadUrl(url: String)
}