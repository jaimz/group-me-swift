//
//  GroupMeUpdates.swift
//  GMT
//
//  Created by James O'Brien on 20/07/2016.
//  Copyright © 2016 James O'Brien. All rights reserved.
//

import Foundation
import SocketRocket
import SwiftyJSON

/**
 Handles live updates from GroupMe via a web socket
 */
class GroupMeUpdatesWS : NSObject, SRWebSocketDelegate {
    static let ChannelHandshake = "/meta/handshake"
    static let ChannelConnect = "/meta/connect"
    static let ChannelSubscribe = "/meta/subscribe"
    static let ChannelUnsubscribe = "/meta/unsubscribe"


    static let PushUrl = "https://push.groupme.com/faye"

    private var webSocket : SRWebSocket? = .None
    private var clientId : String? = .None

    // Channel ID for my personal updates
    private var myChannel : String? = .None


    private func openWebSocket() throws {
        if let url = NSURL(string: GroupMeUpdatesWS.PushUrl) {
            webSocket = SRWebSocket(URL: url)
            webSocket?.delegate = self
            webSocket?.open()
        } else {
            throw GroupMeError.BadUrl(url: GroupMeUpdatesWS.PushUrl)
        }
    }

    private func closeWebSocket() {
        if let ws = self.webSocket {
            if (ws.readyState != SRReadyState.CLOSING) {
                ws.close()
            }
        }
    }

    private func sendWebSocketMessage(message : [String: AnyObject], toChannel channel : String) {
        var augmentedMessage = message
        augmentedMessage["channel"] = channel

        // this weird thing is what the current ios client does...
        augmentedMessage["id"] = "msg_\(NSDate().timeIntervalSince1970)_1"

        if let payload = try? JSON(augmentedMessage).rawData() {
            self.webSocket?.send(payload)
        } else {
            print("Problem creating data from\n\(augmentedMessage)")
        }
    }

    // MARK: Groupme handshakes
    private func checkSuccess(messageDict : [ String : JSON ], successMessage : String? = .None, errorMessage : String? = .None) -> Bool {
        var result = false

        if messageDict["success"]?.bool == true {
            result = true
            if let m = successMessage {
                print("-=-=-= \(m)")
            }
        } else {
            if let m = errorMessage {
                print("-=-=-= Failed: \(m)")
            }
        }

        return result;
    }


    private func sendHandshake() {
        let payloadDict = [
            "version": "1.0",
            "supportedConnectionTypes": "websocket"]
        sendWebSocketMessage(payloadDict, toChannel: GroupMeUpdatesWS.ChannelHandshake)
    }


    private func didHandshake(messageDict: [String : JSON]) {
        guard let cid = messageDict["clientId"]?.string else {
            print("Didn't get client ID from handshake")
            return
        }

        self.clientId = cid

        sendConnect()
    }


    private func sendConnect() {
        guard self.clientId != .None else {
            print("No client ID when asked to connect")
            return
        }

        let payloadDict = [
            "connectionType" : "websocket",
            "clientId" : self.clientId!,
            "supportedConnectionTypes" : "websocket"]

        sendWebSocketMessage(payloadDict, toChannel: GroupMeUpdatesWS.ChannelConnect)
    }


    private func didConnect(messageDict: [String : JSON]) {
        if messageDict["success"]?.bool == true {
            print("-=-=-= Connected!")
        } else {
            print("-=-=-= Failed to connect")
        }

        establishSubscriptions()
    }


    private func subscribe(subscriptionId : String) {
        guard let cid = self.clientId else {
            print("-=-=-= Asked to subscribe before we have a client ID")
            return
        }

        guard let token = GroupMe.instance.API.accessToken else {
            print("-=-=-= Don't have an access token when asked to subscribe")
            return
        }


        // Don't know why I need this type annotation but I do...
        let message : [ String : AnyObject ] = [
            "clientId" : cid,
            "subscription" : subscriptionId,
            "ext" : [ "access_token"  : token ]
        ]


        sendWebSocketMessage(message, toChannel: GroupMeUpdatesWS.ChannelSubscribe)
    }


    private func didSubscribe(messageDict: [String : JSON]) {
        checkSuccess(messageDict, successMessage: "Subscription successful", errorMessage: "Subscription unsuccessful")
    }



    private func unsubscribe(subscriptionId: String) {
        guard let cid = self.clientId else {
            print("-=-=-= Don't have a client ID when asked to unsubscribe")
            return
        }

        let message = [
            "clientId" : cid,
            "channel" : subscriptionId
        ]

        sendWebSocketMessage(message, toChannel: GroupMeUpdatesWS.ChannelUnsubscribe)
    }

    private func didUnsubscribe(messageDict: [String : JSON]) {
        checkSuccess(messageDict, successMessage: "Unsubscription successful", errorMessage: "Unsubscription unsuccessful")
    }



    private func subscribeToGroup(groupId : String) {
        subscribe("/group/\(groupId)")
    }

    private func unsubscribeFromGroup(groupId : String) {
        unsubscribe("/group/\(groupId)")
    }


    private func subscribeToUser(userId : String) {
        subscribe("/user/\(userId)")
    }

    private func unsubscribeFromUser(userId : String) {
        unsubscribe("/user/\(userId)")
    }


    private func establishSubscriptions() {
        if let me = GroupMe.instance.Me {
            myChannel = "/users/\(me.ID)"
            subscribe(myChannel!)
        }

        // TODO: Remember and re-establish any prior group/GM subscriptions
    }


    private func handleMessage(messageDict: [String: JSON], forChannel channel : String, withAlert alertString : String? = .None) {

    }




    // MARK: SRWebSocketDelegate methods
    @objc func webSocketDidOpen(webSocket: SRWebSocket!) {
        self.sendHandshake()
    }

    @objc func webSocket(webSocket: SRWebSocket!, didCloseWithCode code: Int, reason: String!, wasClean: Bool) {
        self.webSocket?.delegate = .None
        self.webSocket = .None
    }

    @objc func webSocket(webSocket: SRWebSocket!, didFailWithError error: NSError!) {
        print("-=-=-= WebSocket failed with \(error)")

        if webSocket == self.webSocket {
            self.webSocket?.delegate = .None
            self.webSocket = .None

            // TODO: Retry...
        }
    }

    @objc func webSocket(webSocket: SRWebSocket!, didReceiveMessage message: AnyObject!) {
        guard let responseStr = message as? String else {
            print("-=-=-= Response from server wasn't a string???")
            print("-=-=-= \(message)")
            return
        }

        if let jsonData = responseStr.dataUsingEncoding(NSUTF8StringEncoding),
            jsonResponse = JSON(data: jsonData).array
        {
            for message in jsonResponse {
                if let messageDict = message.dictionary,
                    channel = messageDict["channel"]?.string
                {
                    switch channel {
                    case GroupMeUpdatesWS.ChannelHandshake:
                        didHandshake(messageDict)
                        break;
                    case GroupMeUpdatesWS.ChannelConnect:
                        didConnect(messageDict)
                        break
                    case GroupMeUpdatesWS.ChannelSubscribe:
                        didSubscribe(messageDict)
                        break
                    case GroupMeUpdatesWS.ChannelUnsubscribe:
                        didUnsubscribe(messageDict)
                        break;
                    default:
                        if let messageContentDict = messageDict["data"]?.dictionary {
                            handleMessage(messageContentDict, forChannel: channel, withAlert: messageDict["alert"]?.string)
                        } else {
                            print("-=-= Don't understand message:\n\(messageDict)");
                        }
                        break;
                    }
                } else {
                    print("-=-= MEssage is not a dictionary or doesn't contain a channel\n\(message)");
                }
            }
        } else {
            print("Message from websocket is not a JSON array?\n \(responseStr)")
        }
    }

}
