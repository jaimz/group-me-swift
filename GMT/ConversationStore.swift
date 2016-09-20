//
//  ConversationStore.swift
//  GMT
//
//  Created by James O'Brien on 01/06/2016.
//  Copyright © 2016 James O'Brien. All rights reserved.
//

import UIKit
import SwiftyJSON

/// ConversationStore models the collection of conversations that the user is a perticipant in.
/// It acts as a model for the gropu list UI
class ConversationStore: NSObject, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    private static let cellReuseId = "convoStoreViewCell"
    private static let sizingView = ConversationCollectionViewCell()

    // Maps conversation IDs to conversation objects
    private var _store : [ String : Conversation ] = [:]

    // Copy of _store.values ordered by update timestamp
    private var _orderedConversations : [ Conversation ] = []


    // Call back to execute when we have updates from GroupMe
    private var updateCallback : UpdateConsumer? = .None

    // Subscription ID so we can unsubscribe from GroupMe callbacks
    private var updateSubscription : SubscriptionID? = .None


    /// The collection view that is being used to display the user's list of
    /// conversations. On assignment this class will install itself as the datasource
    /// and delegate of the class
    weak var collectionView : UICollectionView? = .None {
        didSet {
            collectionView?.registerClass(ConversationCollectionViewCell.self, forCellWithReuseIdentifier: ConversationStore.cellReuseId)
            collectionView?.dataSource = self
            collectionView?.delegate = self
        }
    }


    /// Create a new ConversationStore
    override init() {
        super.init()
        updateCallback = { [unowned self](update : Update) in self.handleUpdate(update) }
    }


    // The source of updated from GroupMe
    // TODO(james): Order of initialisation in GroupMe is horrible hence this clumsy
    // property, fix.
    var updateSource : GroupMeUpdates? = .None
    {
        willSet(newSource) {
            if let source = updateSource, id = updateSubscription {
                source.unsubscribe(id)
            }
        }

        didSet {
            if let cb = updateCallback, source = updateSource {
                updateSubscription = source.subscribe(cb)
            }
        }
    }


    /// Handle an update from GroupMe. The update will either concern membership
    /// of a group or new messages for a group
    func handleUpdate(update : Update) {

        switch update {
        case .Membership(let membershipUpdate):
            handleMembershipUpdate(membershipUpdate)
            break;
        case .Message(let messageUpdate):
            handleMessageUpdate(messageUpdate)
            break;
        default:
            // not interested
            break;
        }
    }



    private func handleMembershipUpdate(update : MembershipUpdate) {
        switch update {
        case .Joined(let newConvos):
            _orderedConversations.appendContentsOf(newConvos)
            break
        case .Left(let leftConvoIds):
            _orderedConversations = _orderedConversations.filter({ leftConvoIds.contains($0.ID) == false })
            break
        default:
            // don't care for now
            break
        }

        self.remakeTable()
        if let cv = collectionView {
            cv.reloadData()
        }
    }


    private func handleMessageUpdate(update: MessageUpdate) {
        switch update {
        case .NewMessages(convoId: let convoId, messages: let messages):
            if let convo = _store[convoId] {
                convo.appendMessages(messages)
            } else {
                print("-=-=-= Didn't have a convo for \(convoId)")
            }
            break
        default:
            // nothing
            break
        }
    }


    // Remake the conversation map from the current ordered conversation list
    private func remakeTable() {
        self._store.removeAll()
//         This crashes the compiler
//                    _orderedConversations.reduce(_store, combine: { (store, convo) in
//                        store[convo.ID] = convo
//                    })

        for group in self._orderedConversations {
            self._store[group.ID] = group
        }
    }

    /// Lookup the conversation with the given conversation ID
    subscript(convoId : String) -> Conversation? {
        get {
            return self._store[convoId]
        }
    }

    /// Get the conversation at index indexPath
    subscript(indexPath : NSIndexPath) -> Conversation? {
        get {
            return self._orderedConversations[indexPath.item]
        }
    }

    /// Return the user's current conversations (ordered by last update)
    var currentConversations : [ Conversation ] {
        get {
            // Can't do this?
            //return Array(_store.keys)

            return _orderedConversations
        }
    }



    // MARK: CollectionViewDataSource

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return _orderedConversations.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(ConversationStore.cellReuseId, forIndexPath: indexPath)

        if let c = cell as? ConversationCollectionViewCell {
            let group = _orderedConversations[indexPath.item]
            c.source = group

            // TODO(james): Do I need this?
            c.setNeedsLayout()
            c.layoutIfNeeded()
        }

        return cell
    }



    // MARK: CollectionViewDelegate
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout

        let width = collectionView.bounds.width - (flowLayout.sectionInset.left + flowLayout.sectionInset.right)

        ConversationStore.sizingView.prepareForReuse()
        ConversationStore.sizingView.source = _orderedConversations[indexPath.item]
        return ConversationStore.sizingView.sizeThatFits(CGSize(width: width, height: CGFloat.max))

    }


    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if let convo = self[indexPath] {
            Services.instance.navigator.goToConversation(convo)
        }
    }
}
