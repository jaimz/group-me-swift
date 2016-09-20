//
//  MessageCollection.swift
//  GMT
//
//  Created by James O'Brien on 30/06/2016.
//  Copyright © 2016 James O'Brien. All rights reserved.
//

import UIKit
import SwiftyJSON


/**
 A lazy, potentially infinite, list of messages such as the messages
 contained in a group conversation or a DM conversation
 */
class MessageCollection: NSObject, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout {
    private static let CellId = "message.cell"
    private static let SizingView = SermonCollectionViewCell()

    // Used for sizing cells
    private var infiniteHeight = CGSize(width: 0, height: CGFloat.infinity)

    private(set) var conversationId : String;

    private var _orderedMessages : [ Message ] = []

    private var _lastDisplayedIdx = 0


    init(conversationId: String) {
        self.conversationId = conversationId
    }


    /// The collection view controller displaying the messages that we
    /// contain
    weak var conversationView : MessagesViewController? = .None {
        willSet(newConversationView) {
            if let cv = conversationView {
                // The user is nav'ing away from a conversation view.
                // Remove ourselves as the datasource and delegate of any
                // current view...
                cv.collectionViewDataSource = .None
                cv.collectionViewDelegate = .None
            }
        }

        didSet {
            if let cv = conversationView {
                cv.registerClass(SermonCollectionViewCell.self, forUseWithReuseIdentifier: MessageCollection.CellId)
                cv.collectionViewDataSource = self
                cv.collectionViewDelegate = self
            }
        }
    }


    /// Time of the newest message in the conversation
    var newestTime : NSDate {
        get { return NSDate() }
    }

    /// Time of the oldest (loaded) message in the conversation
    var oldestTime : NSDate {
        get { return NSDate() }
    }

    /// The ID of the newest message in the conversation (that isn't a tentative message)
    var newestMessageId : String? {
        get {
            // Weirdly, there isn't a 'findFirst' on Sequence...
            let reversedMessages = _orderedMessages.reverse()
            if let idx = reversedMessages.indexOf({ $0.isTentative == false }) {
                return reversedMessages[idx].ID
            }

            return .None
        }
    }


    /// Number of unread messages in this collection
    var unreadCount : Int {
        get {
            if _orderedMessages.count > 0 {
                return _orderedMessages.count - _lastDisplayedIdx
            }

            return 0
        }
    }


    /// The number of messages we have loaded from the server (not necc. the
    /// number of messages that have ever been in the conversation)
    var loadedCount : Int {
        get { return _orderedMessages.count }
    }


    /// Append some messages to this collection
    func append(newMessages : [ Message ]) {
        // TODO: Should probably do some sanity checking about dates/sequence numbers etc.
        // TODO: Assuming that the messages need to be revesed since that's the order they
        // come in from the server...
        if _orderedMessages.count > 0 {
            self._lastDisplayedIdx = self._orderedMessages.count - 1
        }

        // TODO: This is massively inefficient, fix
        self._orderedMessages = self._orderedMessages.filter({ t in t.isTentative == false || newMessages.contains({ $0.ID == t.ID }) })
        self._orderedMessages.appendContentsOf(newMessages.reverse())

        self.conversationView?.didAppendMessages()
    }

    

    // MARK: UICollectionViewDataSource

    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return _orderedMessages.count
    }

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(MessageCollection.CellId, forIndexPath: indexPath)
        if let sermonCell = cell as? SermonCollectionViewCell {
            sermonCell.message = _orderedMessages[indexPath.item]
            sermonCell.setNeedsLayout()
            sermonCell.layoutIfNeeded()
        }
        return cell
    }

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }

    // MARK: UICollectionViewDelegateFlowLayout
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let flowLayout = collectionViewLayout as! UICollectionViewFlowLayout
        let width = collectionView.bounds.width - (flowLayout.sectionInset.left + flowLayout.sectionInset.right)

        if (_orderedMessages.count > indexPath.item) {
            MessageCollection.SizingView.message = _orderedMessages[indexPath.item]
            infiniteHeight.width = width
            return MessageCollection.SizingView.sizeThatFits(infiniteHeight)
        }

        return CGSizeZero;
    }
}
