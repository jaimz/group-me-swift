//
//  SermonCollectionViewCell.swift
//  GMT
//
//  Created by James O'Brien on 13/07/2016.
//  Copyright © 2016 James O'Brien. All rights reserved.
//

import UIKit
import AlamofireImage
import Alamofire

/// This is a collectionview cell that shows a number of messages from the same user, assuming
/// those messages were send in a small enough window of time.
class SermonCollectionViewCell: UICollectionViewCell {
    private static let NineOver16 : CGFloat = (9.0 / 16)

    private static let kAvatarSize : CGFloat = 36.0
    private static let kHorizMargin : CGFloat = 17.0
    private static let kVertMargin : CGFloat = 12.0
    private static let kLabelHorizStart = (kVertMargin * 2) + kAvatarSize
    private static let interLabelSpace : CGFloat = 2.0


    private static let MessageFont = UIFont.systemFontOfSize(14)


    private let senderAvatar = AvatarGem(frame: CGRect(x: SermonCollectionViewCell.kVertMargin, y: SermonCollectionViewCell.kVertMargin, width: SermonCollectionViewCell.kAvatarSize, height: SermonCollectionViewCell.kAvatarSize))
    private let nameLabel = UILabel()
    private let messageLabel = UILabel()

    private var imageUrl : NSURL? = .None
    private var imageView = InsetImage()
    private var imageTapRecognizer = UITapGestureRecognizer()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.configureViews()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder);
        self.configureViews()
    }

    private func configureViews() {
        nameLabel.numberOfLines = 1
        nameLabel.lineBreakMode = NSLineBreakMode.ByTruncatingTail
        nameLabel.font = SermonCollectionViewCell.MessageFont
        nameLabel.textColor = GMTStyleKit.messageNameForeground

        messageLabel.numberOfLines = 0
        messageLabel.lineBreakMode = NSLineBreakMode.ByWordWrapping
        messageLabel.font = SermonCollectionViewCell.MessageFont
        messageLabel.textColor = GMTStyleKit.messageForeground

        imageTapRecognizer.addTarget(self, action: #selector(SermonCollectionViewCell.didTapImage(_:)))
        imageView.addGestureRecognizer(imageTapRecognizer)

        self.contentView.addSubview(imageView)
        self.contentView.addSubview(senderAvatar)
        self.contentView.addSubview(nameLabel)
        self.contentView.addSubview(messageLabel)

        self.imageView.userInteractionEnabled = true
        self.contentView.userInteractionEnabled = true
        self.userInteractionEnabled = true
    }


    var message : Message? = .None {
        didSet {
            senderAvatar.avatarUrl = message?.avatarUrl
            nameLabel.text = message?.name
            messageLabel.text = message?.text

            imageUrl = .None
            self.imageView.imageUrl = nil
            self.imageView.imageData = nil

            if let attachments = message?.attachments {
                for a in attachments {
                    switch a.type {
                    case .Image:
                        switch a.data {
                        case .Url(let imageUrl):
                            self.imageUrl = imageUrl
                            self.imageView.imageUrl = imageUrl
                        case .Tentative(let imageData):
                            self.imageView.imageData = imageData
                        default:
                            // Not interested (yet)
                            break
                        }

                    default:
                        // Not interested (yet)
                        break
                    }
                }
            }
        }
    }

    override func prepareForReuse() {
        self.imageUrl = .None
        self.senderAvatar.avatarUrl = nil
    }

    override func sizeThatFits(size: CGSize) -> CGSize {

        // The width the name / message labels should fill...
        let contentWidth = size.width - (SermonCollectionViewCell.kLabelHorizStart + SermonCollectionViewCell.kHorizMargin)

        if contentWidth <= 0 {
            return CGSize(width: 0, height: 0)
        }

        let infHeight = CGSize(width: contentWidth, height: CGFloat.max)

        // Sum the heights of the two labels
        var height = nameLabel.sizeThatFits(infHeight).height
        height += messageLabelSize(forSize: infHeight).height
        height += SermonCollectionViewCell.interLabelSpace

        // The height we should be is the greater of the two labels or the avatar...
        height = max(height, SermonCollectionViewCell.kAvatarSize)

        // ...plus any image
        if imageUrl != nil {
            height += floor(size.width * SermonCollectionViewCell.NineOver16)
        }

        // ...plus our margin
        height += (SermonCollectionViewCell.kVertMargin * 2)


        return CGSize(width: size.width, height: height)
    }



    override func layoutSubviews() {
        let bounds = self.bounds

        self.contentView.frame = bounds

        let contentWidth = bounds.width - (SermonCollectionViewCell.kLabelHorizStart + SermonCollectionViewCell.kHorizMargin)
        let infHeight = CGSize(width: contentWidth, height: CGFloat.max)

        var y = SermonCollectionViewCell.kVertMargin
        let nameSize = nameLabel.sizeThatFits(infHeight)
        nameLabel.frame = CGRect(origin: CGPoint(x: SermonCollectionViewCell.kLabelHorizStart, y: y), size: nameSize)
        y += nameSize.height + SermonCollectionViewCell.interLabelSpace

        let messageSize = messageLabelSize(forSize: infHeight)
        messageLabel.frame = CGRect(x: SermonCollectionViewCell.kLabelHorizStart, y: y, width: messageSize.width, height: messageSize.height)


        if imageUrl != nil {
            y += SermonCollectionViewCell.kVertMargin
            imageView.frame = CGRect(x: 0, y: y, width: bounds.width, height: floor(bounds.width * SermonCollectionViewCell.NineOver16))
        } else {
            imageView.frame = CGRectZero
        }
    }


    private func messageLabelSize(forSize size:CGSize) -> CGSize {
        var result = CGRect(x: 0, y: 0, width: size.width, height: 0)

        if let m = messageLabel.text {
            let messageStr = m as NSString
            result = messageStr.boundingRectWithSize(size, options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: [NSFontAttributeName: SermonCollectionViewCell.MessageFont], context: .None)
        }

        return result.size
    }

    @objc func didTapImage(sender: UITapGestureRecognizer) {
        print("Tapped image!")
    }
}
