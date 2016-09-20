//
//  ConversationCollectionViewCell.swift
//  GMT
//
//  Created by James O'Brien on 31/05/2016.
//  Copyright © 2016 James O'Brien. All rights reserved.
//

import UIKit
import SwiftyJSON
import Alamofire

/// A CollectionViewCell that displays a precis of a conversation
/// usually as part of a list of conversations the user is a member of.
class ConversationCollectionViewCell: UICollectionViewCell {
    // Sizes of various UI elements
    private static let avatarSize : CGFloat = 44.0
    private static let avatarHPad : CGFloat = 15.0
    private static let nameFontSize : CGFloat = 18.0
    private static let messageFontSize : CGFloat = 13.0
    private static let verticalSpace : CGFloat = 6.0
    private static let leftPad : CGFloat = 10.0
    private static let topPad : CGFloat = 18.0
    private static let bottomPad : CGFloat = 32.0
    private static let imageHeight : CGFloat = 66.0

    // X coordinate of the labels in the cell
    private static let labelX : CGFloat = (ConversationCollectionViewCell.avatarHPad * 2) + ConversationCollectionViewCell.avatarSize

    // Origin of the avatar gem
    private static let avatarOrigin = CGPoint(x: ConversationCollectionViewCell.avatarHPad, y: 0.0)

    // Origin of the name label
    private static let nameLabelOrigin = CGPoint(x: labelX, y: 0)

    // Avatar of the user who sent the message
    private let avatar = AvatarGem(frame: CGRect(x: ConversationCollectionViewCell.avatarHPad, y: ConversationCollectionViewCell.topPad, width: ConversationCollectionViewCell.avatarSize, height: ConversationCollectionViewCell.avatarSize))

    // Font of the message labels
    private let messageFont = UIFont.systemFontOfSize(ConversationCollectionViewCell.messageFontSize, weight: UIFontWeightRegular)

    // Labels to display the sender's name and any text of the most recently send messages
    private let nameLabel = UILabel(frame: CGRect(x: ConversationCollectionViewCell.labelX, y: ConversationCollectionViewCell.topPad, width: 0, height: 0))
    private let messageLabel = UILabel()

    // Image URL and view if there is an attached image
    private var imageUrl : NSURL? = .None
    private let imageView = InsetImage()


    // The only way you can draw a line is with a UIView?!
    private let rule = UIView()

    // ID of the conversation our message is in
    private(set) var conversationId : String? = .None


    override init(frame: CGRect) {
        super.init(frame: frame)
        configureViews()
    }


    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        configureViews()
    }


    /// The conversation we are displaying the precis for
    var source : Conversation? = .None {
        didSet {
            conversationId = source?.ID
            nameLabel.text = source?.name ?? ""
            avatar.avatarUrl = source?.avatarUrl
            messageLabel.text = source?.preview?.messagePreview ?? ""

            avatar.isGroup = source?.conversationType == ConversationType.Group;

            imageUrl = nil
            imageView.imageUrl = nil
            imageView.imageData = nil
            if let attachments = source?.preview?.attachments {
                for a in attachments {
                    switch a.type {
                    case .Image:
                        switch a.data {
                        case .Url(let imageUrl):
                            self.imageUrl = imageUrl
                            imageView.imageUrl = imageUrl
                        case .Tentative(let imageData):
                            self.imageView.imageData = imageData
                        default:
                            // Can only understand images or tentatives for now
                            break
                        }
                    default:
                        // Only interested in images for now...
                        break
                    }
                }
            }
        }
    }


    // Configure subviews
    private func configureViews() {
        nameLabel.numberOfLines = 1
        nameLabel.lineBreakMode = NSLineBreakMode.ByTruncatingTail
        nameLabel.font = UIFont.systemFontOfSize(ConversationCollectionViewCell.nameFontSize, weight: UIFontWeightRegular)
        nameLabel.textColor = GMTStyleKit.textBlue

        messageLabel.numberOfLines = 0
        messageLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
        messageLabel.font = messageFont
        messageLabel.textColor = GMTStyleKit.textBlue

        // absurdly, this seems to be the only way to do a rule
        rule.backgroundColor = GMTStyleKit.textBlue
        rule.alpha = 0.2

        contentView.addSubview(imageView)
        contentView.addSubview(avatar)
        contentView.addSubview(nameLabel)
        contentView.addSubview(rule)
        contentView.addSubview(messageLabel)
    }



    override func sizeThatFits(size: CGSize) -> CGSize {
        let avatarHeight = ConversationCollectionViewCell.avatarSize + ConversationCollectionViewCell.verticalSpace

        let contentWidth = size.width - (ConversationCollectionViewCell.labelX + ConversationCollectionViewCell.leftPad)
        if contentWidth <= 0 {
            return CGSize(width: 0, height: 0)
        }

        let infHeight = CGSize(width: contentWidth, height: CGFloat.max)
        let nameSize = nameLabel.sizeThatFits(infHeight)
        let messageSize = _messageLabelSize(infHeight)
        let labelsHeight = nameSize.height + messageSize.height + (ConversationCollectionViewCell.verticalSpace * 2) + 1

        var finalHeight = (labelsHeight > avatarHeight ? labelsHeight : avatarHeight) + (ConversationCollectionViewCell.topPad + ConversationCollectionViewCell.bottomPad)
        
        if imageUrl != nil {
            finalHeight += ConversationCollectionViewCell.imageHeight
        }



        return CGSize(width: size.width, height: finalHeight)
    }


    override func layoutSubviews() {
        let contentWidth = self.frame.width - (ConversationCollectionViewCell.labelX + ConversationCollectionViewCell.leftPad)

        let  infHeight = CGSize(width: contentWidth, height: CGFloat.max)
        let nameSize = nameLabel.sizeThatFits(infHeight)
        nameLabel.frame.size = nameSize

        var currentY = ConversationCollectionViewCell.topPad + nameSize.height + ConversationCollectionViewCell.verticalSpace
        rule.frame = CGRect(x: ConversationCollectionViewCell.labelX, y: currentY, width: contentWidth + ConversationCollectionViewCell.leftPad, height: 1.0)

        currentY += ConversationCollectionViewCell.verticalSpace

        let messageSize = _messageLabelSize(infHeight)
        let messageLabelOrigin = CGPoint(x: ConversationCollectionViewCell.labelX, y: currentY)
        messageLabel.frame = CGRect(origin: messageLabelOrigin, size: messageSize)
        
        if imageUrl != nil {
            currentY += messageLabel.frame.height
            imageView.frame = CGRect(x: 0, y: currentY, width: self.frame.width, height: ConversationCollectionViewCell.imageHeight)
        } else {
            imageView.frame = CGRect(x: 0, y: currentY, width: 0, height: 0)
        }
    }
    
    override func prepareForReuse() {
        imageUrl = nil
        imageView.imageUrl = nil
        imageView.imageData = nil
    }
    

    // 'sizeThatFits' doesn't always give a size that, err, fits.
    // 'boundingRectWithSize' on NSString seems to give better results...
    private func _messageLabelSize(fitInto: CGSize) -> CGSize {
        var result = CGRect(x: 0, y: 0, width: fitInto.width, height: fitInto.height)

        if let m = messageLabel.text {
            let labelText = m as NSString

            result = labelText.boundingRectWithSize(fitInto, options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: [NSFontAttributeName: messageFont], context: nil)
        }

        return result.size
    }
}
