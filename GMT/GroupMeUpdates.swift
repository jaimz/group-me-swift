//
//  GroupMeUpdates.swift
//  GMT
//
//  Created by James O'Brien on 25/07/2016.
//  Copyright © 2016 James O'Brien. All rights reserved.
//

import Foundation


/// Possible updates to a participant
enum ParticipantUpdate {
    case Name(id: String, newName: String)
    case AvatarUrl(id: String, newAvatar: String)
}



/// Possibble updates to the set of conversations that the user is a member of
enum MembershipUpdate {
    /// The user has joined the given conversations
    case Joined([Conversation])

    /// The user has left the conversations with the given IDs
    case Left([String])

    /// The conversation with convoId has new participants
    case ParticipantsJoined(convoId: String, newParticipants: [Person])

    /// Participants have left the conversation with convoId
    case ParticipantsLeft(convoId: String, leftParticipants: [Person])

    /// The given list of participants are typing in conversation "convoId"
    case Typers(convoId : String, typers: [Person])
}



// Possible updates to the set of messages within a conversation
enum MessageUpdate {
    /// The conversation has new messages
    case NewMessages(convoId : String, messages : [Message])

    /// Some messages have been liked
    case HeartMessages(convoId : String, message : [Message])
}


/// The set of all possible updates from GroupMe
enum Update {
    case Participant(ParticipantUpdate)
    case Membership(MembershipUpdate)
    case Message(MessageUpdate)
}



/// Signature of a callback function that consumes updates
typealias UpdateConsumer = (Update) -> ()

typealias SubscriptionID = String


/// This class represents a netwok endpoint that handles the real-time updates from the GroupMe service
/// Bit of a hask right now that just polls for information rather than uses the WebSocket endpoint
class GroupMeUpdates {
    private static let SlowPollTime : NSTimeInterval = 7
    private static let FastPollTime : NSTimeInterval = 3


    // The collection of current update consumers
    private var consumerTable : [ SubscriptionID : UpdateConsumer ] = [ : ]


    // Poll delay for getting group updates
    private var groupsTimer = NSTimer()

    // Poll delay for getting message updates
    private var messagesTimer = NSTimer()


    /// The given consumer wants to be called back for any future updates
    /// of the given type
    func subscribe(consumer: UpdateConsumer) -> SubscriptionID {
        let subId = NSUUID().UUIDString

        consumerTable[subId] = consumer


        return subId
    }

    /// The given consumer wants to stop being called for any future updates
    /// of the given type
    func unsubscribe(consumerId: SubscriptionID) {
        consumerTable.removeValueForKey(consumerId)
    }

    // Post updates to current subscribers
    private func postUpdates(updates: [ Update ]) {
        for update in updates {
            for subscriber in consumerTable.values {
                subscriber(update)
            }
        }
    }


    func startNOW() {
        doSlowUpdates(groupsTimer)

    }

    /// Start listening for updates from GroupMe
    func start() {
        groupsTimer = NSTimer(timeInterval: GroupMeUpdates.SlowPollTime, target: self, selector: #selector(GroupMeUpdates.doSlowUpdates), userInfo: .None, repeats: false)
    }

    /// Stop listening for updated from GrupMe
    func stop() {

    }


    func startGroupsTimer() {
        groupsTimer = NSTimer.scheduledTimerWithTimeInterval(GroupMeUpdates.SlowPollTime,
                                                             target: self,
                                                             selector: #selector(GroupMeUpdates.doSlowUpdates(_:)),
                                                             userInfo: .None,
                                                             repeats: false)
    }

    func startMessagesTimer() {
        messagesTimer = NSTimer.scheduledTimerWithTimeInterval(GroupMeUpdates.FastPollTime,
                                               target: self,
                                               selector: #selector(GroupMeUpdates.doFastUpdates(_:)),
                                               userInfo: nil,
                                               repeats: true)
    }

    // Callback for a timer so needs to be @objc
    @objc func doSlowUpdates(timer: NSTimer) {
        doMeUpdate()
        doGroupsUpdate()
    }

    // Update the current Me object
    private func doMeUpdate() {
        GroupMe.instance.API.me { json in
            if let meJson = json {
                if let currentMe = GroupMe.instance.Me {
                    if let maybeUpdates = try? currentMe.update(withJson: meJson) {
                        if let updates = maybeUpdates {
                            self.postUpdates(updates)
                        }
                    } else {
                        print("-=-=-= Problem parsing Me update")
                    }
                } else {
                    GroupMe.instance.Me = try? Person(withJson: meJson)
                }
            }
        }
    }

    // Update the current groups list
    private func doGroupsUpdate() {
        GroupMe.instance.API.myGroups { json in
            if let groupsJson = json?.array {
                let currentConvoIds = GroupMe.instance.Conversations.currentConversations.map({ $0.ID })
                let newConvoIds = groupsJson.map({ $0.dictionary?["id"]?.string }).flatMap({ $0 })
                let added = newConvoIds.filter({ newId in currentConvoIds.contains(newId) == false })
                let removed = currentConvoIds.filter({ id in newConvoIds.contains(id) == false })
                var updates : [ Update ] = []

                if added.count > 0 {
                    let joinedJson = groupsJson.map({ $0.dictionary }).flatMap({ $0 }).filter({ added.contains(($0["id"]?.string ?? "")) })
                    let joinedConvos = joinedJson.map({ Conversation(withGroup: $0) })
                    updates.append(Update.Membership(MembershipUpdate.Joined(joinedConvos)))
                }

                if removed.count > 0 {
                    updates.append(Update.Membership(MembershipUpdate.Left(removed)))
                }

                if updates.count > 0 {
                    self.messagesTimer.invalidate()

                    self.postUpdates(updates)

                    self.startMessagesTimer()
                } else {
                    print("-=-=-= No updates to post when checking groups")
                }
            } else {
                print("-=-=-= Couldn't bind groups JSON as array when checking groups")
            }
        }
    }


    @objc func doFastUpdates(timer: NSTimer) {
        doMessagesUpdate()
    }

    // Update the messages foor the currently selected group
    private func doMessagesUpdate() {
        let conversations = GroupMe.instance.Conversations.currentConversations
        let api = GroupMe.instance.API
        if conversations.count > 0 {
            for conversation in conversations {
                api.messagesAfter(conversation.ID, afterId: conversation.messages.newestMessageId, completion: { json in
                    if let messagesResult = json?.dictionary, let messagesJson = messagesResult["messages"]?.array {
                        if messagesJson.count > 0 {
                            // Make sure all the elements messagesJson are dictionaries, get rid of the ones that aren't (shouldn't be
                            // any) then convert the rest to message objects
                            let messages = messagesJson
                                 .map({ $0.dictionary })  // Make sure everything is a dictionary
                                .flatMap({ $0 })         // Remove anything that isn't
                                .map({ try? Message(withJson: $0) })  // Convert everything into a Message object, .None if there's an exception
                                .flatMap({ $0 })         // Get rid of the .None's


                            let update = Update.Message(MessageUpdate.NewMessages(convoId: conversation.ID, messages: messages))
                            self.postUpdates([update])
                        }
                    }
                })
            }
        } else {
            print("-=-=-= No conversations when asked for messages")
        }
    }

}

