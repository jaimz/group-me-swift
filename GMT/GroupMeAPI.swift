//
//  GroupMe.swift
//  GMT
//
//  Created by James O'Brien on 20/05/2016.
//  Copyright © 2016 James O'Brien. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

typealias GroupMeCallback = JSON? -> ()

/// Result from an image upload request
enum ImageUploadResult {
    /// The upload was successful,
    case Succes(String)
    case Error(String)
}

/// Signature of a callback to execute when an image upload operation has
/// finished
typealias ImageUploadCallback = ImageUploadResult -> ()


/// Abstract representation of the GroupMe API
class GroupMeAPI {

    // Key to store the access token against
    let tokenKey = "groupme.access.token"

    // Base URL of the API server
    let baseUrl = "https://api.groupme.com/v3"

    // URL to post images to for the image service
    let baseImageServiceUrl = "https://image.groupme.com/pictures"

    // Url of the oauth authentication web page
    let authenticationUrl : NSURL? = NSURL(string: "https://oauth.groupme.com/oauth/authorize?client_id=VqkAMvOI3ySWOc8PGg0vFud6gdPiyHu1tjHJD85tHI8T9a4Z")

    // Deep link scheme that oauth will call back to
    let deepLinkScheme = "jisperapp"

    // URI path that oauth will call back to
    let oauthPath = "/oauth_callback"

    // URI parameter containing the Oauth access token
    let accessTokenName = "access_token"


    private var _accessToken : String? = .None

    /// The access token we get back from the OAuth dance
    var accessToken : String? {
        get {
            if _accessToken == .None {
                // Don't have an access token - do we have one from a previous session?
                if let _tok = NSUserDefaults.standardUserDefaults().objectForKey(tokenKey) as? String {
                    _accessToken = _tok;
                }
            }

            return _accessToken
        }

        set(newToken) {
            _accessToken = newToken

            // TODO: use keychain to store access token
            let defaults = NSUserDefaults.standardUserDefaults()
            switch _accessToken {
            case .None:
                defaults.removeObjectForKey(tokenKey)
            case .Some(let t):
                defaults.setObject(t, forKey: tokenKey)
            }

            defaults.synchronize()
        }
    }



    /**
        Returns function that will pull out the result from a successful API call and
        pass it to the given completion block.
     
        - Parameter completion The completion to call on a successful result.
    
    */
    private func jsonCompletion(completion: GroupMeCallback) -> (response: Response<String, NSError>) -> ()  {
        return { (response: Response<String, NSError>) in
            switch response.result {
            case .Failure(let error):
                print("!!!!! Error making API call \(error.localizedDescription)")
                // Uncomment for debig
//                print(response.description)
//                let s = String(data: response.data!, encoding: NSUTF8StringEncoding)
//                print(s)
//                let s2 = String(data: response.request!.HTTPBody!, encoding: NSUTF8StringEncoding)
//                print(s2)
                break
            case .Success(let result):
                if let apiResult = self.pullResult(response, result: result) {
                    completion(apiResult)
                } else {
                    // nothing - implies an API call error which 'pullResult' will
                    // already have logged
                }

                break;
            }
        }
    }


    // Pull the API result from the response envelope. Will return .None if an API error
    // has occured (and will log that error)
    private func pullResult(apiResponse: Response<String, NSError>, result: String) -> JSON? {
        var response: JSON? = .None

        if let dataFromString = result.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: true) {
            let responseEnvelope = JSON(data: dataFromString)
            response = responseEnvelope["response"]
            if response == .None {
                if let meta = responseEnvelope["meta"].dictionary {
                    if let requestUrl = apiResponse.request?.URL?.URLString {
                        if let code = meta["code"]?.int {
                            print("Bad result \(code) for \(requestUrl)")
                        } else {
                            print("Bad result for \(requestUrl)")
                        }
                    } else {
                        print("Bad result")
                    }
                }
            }
        }

        return response
    }


    /**
     Make an API request
     
     - parameters
        - *method*     The HTTP method to use
        - *path*       The REST path to talk to
        - *parameters* The parameters to add to the request (we will automatically add the access token)
        - *completion* Function to call when the request completes
    */
    private func req(method: Alamofire.Method,
                     path: String,
                     parameters: [String:AnyObject]? = .None,
                     encoding : ParameterEncoding = .URL,
                     completion: GroupMeCallback) {
        guard let token = accessToken
        else {
            print("!!!!! Request made with no access \(path)")
            return
        }

        var urlString = [ baseUrl, path ].joinWithSeparator("/")
        var realParams : [ String : AnyObject ] = [:]

        // Hack to work around awkwardness in AlamoFire, for POSTs we need to
        // encode JSON in the body *and* a token in the URL. AlamoFire only allows
        // one or the other...
        if method == .POST {
            urlString = "\(baseUrl)/\(path)?token=\(ParameterEncoding.URLEncodedInURL.escape(token))"
        } else {
            realParams["token"] = token
        }

        if let p = parameters {
            for (k, v) in p {
                realParams[k] = v
            }
        }


        let callback = jsonCompletion(completion)


        Alamofire.request(method, urlString, parameters: realParams, encoding: encoding).validate().responseString(completionHandler: callback)
    }


    // MARK: API methods

    /**
        Get the logged in user's profile information
     
        - Parameters:
            - completion: The function to call when the API responds. Will be passed a
                          JSON object containing the user's profile data.
     */
    func me (completion: GroupMeCallback) {
        req(.GET, path: "users/me", parameters: .None, completion: completion)
    }

    /**
        Get the logged in user's groups
     
        - Parameters:
            - completion GroupMeCallback to call when we have the groups data. Will be passed
                         a JSON object containing the API response
     */
    func myGroups (completion: GroupMeCallback) {
        req(.GET, path: "groups", parameters: .None, completion: completion)
    }


    /**
        Get the messages from a specific group.
        - Parameters:
            - groupId: The ID of the group to get messages for.
            - afterId: Only get the messages after this message ID
            - completion: `GroupMeCallback` to call  when we have the API result
    */
    func messagesAfter(groupId: String, afterId: String?, completion: GroupMeCallback) {
        var params : Dictionary<String, String>? = .None

        if let after = afterId {
            params = ["after_id" : after ]
        }

        req(.GET, path: "groups/\(groupId)/messages", parameters: params, completion: completion)
    }


    /**
        Send a message.
        - Parameters
            - message: The tentative message to send. If the message does not contain
                       a groupId it will not be sent
            - completion: function to call when we have the API result
    */
    func sendMessage(message: Message, completion: GroupMeCallback) {
        if let groupId = message.groupId, postInfo = message.postInfo {
            req(.POST,
                path: "groups/\(groupId)/messages",
                parameters: postInfo,
                encoding: .JSON,
                completion: completion)
        }
    }

    /**
        Upload an image to the image service
        - Parameters
            - imageData: The data constituting the image we want to upload
            - completion: A callback to execute when the upload is complete
     */
    func uploadImage(imageData: NSData, completion: ImageUploadCallback) {
        guard let accessToken = self.accessToken else {
            print("-=-=-= Can't upload an image without an access token")
            return
        }

        upload(.POST,
               baseImageServiceUrl,
               headers: [ "X-Access-Token" : accessToken, "Content-Type" : "image/jpeg" ],
               data: imageData)
            .progress { bytesWritten, totalBytesWritten, totalBytesExpectedToWrite in
                print("\(totalBytesExpectedToWrite - totalBytesWritten)")
            }
            .validate()
            .responseJSON { response in
                guard response.result.isSuccess else {
                    print("error uploading image \(response.result.error)")
                    completion(ImageUploadResult.Error(response.result.error!.localizedDescription))
                    return
                }

                guard let value = response.result.value as? [String : AnyObject],
                    payload = value["payload"] as? [ String : AnyObject] else {
                        print("Unexpected response from image upload service")
                        print(response.result.value)
                        completion(ImageUploadResult.Error("Bad JSON from image upload service"))
                        return
                }

                if let imageUrl = payload["url"] as? String {
                    print("Got image URL \(imageUrl)")
                    completion(ImageUploadResult.Succes(imageUrl))
                } else {
                    print("Could not find image url in response from upload service")
                    completion(ImageUploadResult.Error("Could not find image url in response from upload service"))
                }
            }
    }
}