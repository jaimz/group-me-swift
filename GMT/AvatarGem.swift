//
//  AvatarGem.swift
//  GMT
//
//  Created by James O'Brien on 23/05/2016.
//  Copyright © 2016 James O'Brien. All rights reserved.
//

import UIKit
import Alamofire
import WebImage


@IBDesignable
class AvatarGem: UIView {
    private static let borderWidth : CGFloat = 1.0
    private static let borderColor = UIColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 0.8)
    private static let groupCornerRadius : CGFloat = 3.0

    // Need a separate image layer since we mask to a circle.
    // If we just set our layer's content to the image and mask we lose
    // the shadow
    private let imageLayer = CALayer()

    // Similarly, since we're stacking layers, we now need yet another layer for the border
    private let borderLayer = CALayer()

    private let maskLayer = CALayer()

    private var initials = "GMT"

    private var shadowPath = UIBezierPath()


    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder:NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    override func prepareForInterfaceBuilder() {
        self.usersName = "James OBrien"
    }

    @IBInspectable
    var isGroup : Bool = false

    @IBInspectable
    var hasShadow : Bool = true

    var avatarImage : UIImage = GMTStyleKit.imageOfAvatar(initials: "GMT", avatarSize: CGSize(width: 54, height: 54)) {
        didSet {
            self.imageLayer.contents = avatarImage.CGImage
        }
    }

    var avatarUrl : String? = .None {
        didSet {
            if let urlString = avatarUrl {
                let url = NSURL(string: urlString)
                let imageManager = SDWebImageManager.sharedManager()
                imageManager.downloadImageWithURL(url,
                                                  options: SDWebImageOptions.init(rawValue: 0),
                                                  progress: nil,
                                                  completed:
                    { (image : UIImage?, error : NSError?, cacheType : SDImageCacheType, finished : Bool, url : NSURL?) in
//                        print(url)
                        if let retrievedUrl = url, i = image {
                            if retrievedUrl == url {
                                self.avatarImage = i
                            }
                        } else {
                            self.avatarImage = GMTStyleKit.imageOfAvatar(initials: self.initials, avatarSize: self.frame.size)
                        }
                    }
                )
            } else {
                avatarImage = GMTStyleKit.imageOfAvatar(initials: initials, avatarSize: self.frame.size)
            }
        }
    }

    @IBInspectable
    var usersName : String? = .None {
        didSet {
            if let n = usersName {
                let ws = NSCharacterSet.whitespaceCharacterSet()
                let names = n.stringByTrimmingCharactersInSet(ws).componentsSeparatedByCharactersInSet(ws)
                let chars = names
                    .filter({ $0.isEmpty == false})
                    .map({ (s : String) in return s[s.startIndex] })
                initials = String(chars)
            }
        }
    }


    func setup() {
        self.borderLayer.borderColor = AvatarGem.borderColor.CGColor
        self.borderLayer.borderWidth = AvatarGem.borderWidth

        let avImg = GMTStyleKit.imageOfAvatar(initials: "GMT", avatarSize: CGSize(width: self.frame.width, height: self.frame.height))
        self.imageLayer.contents = avImg.CGImage
        self.imageLayer.contentsGravity = kCAGravityResizeAspectFill

        let r = isGroup ? AvatarGem.groupCornerRadius : floor(self.frame.width / 2.0)
        self.borderLayer.cornerRadius = r

        self.maskLayer.frame = CGRect(x: 0,y: 0,width: self.frame.width, height: self.frame.height)

        self.maskLayer.cornerRadius = r
        self.maskLayer.backgroundColor = UIColor.blackColor().CGColor
        self.imageLayer.mask = self.maskLayer

        self.layer.addSublayer(imageLayer)
        self.layer.addSublayer(borderLayer)

        if hasShadow {
            let shadow : NSShadow = GMTStyleKit.subtleShadow
            self.layer.shadowColor = shadow.shadowColor?.CGColor
            self.layer.shadowOffset = shadow.shadowOffset
            self.layer.shadowOpacity = 1.0
            self.layer.shadowRadius = shadow.shadowBlurRadius

            shadowPath = UIBezierPath(ovalInRect: CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height))
            self.layer.shadowPath = shadowPath.CGPath
        }
    }

    override func layoutSublayersOfLayer(layer: CALayer) {
        let w = layer.frame.width
        let h = layer.frame.height
        let r = isGroup ? AvatarGem.groupCornerRadius : floor(w / 2.0)

        borderLayer.frame.size.width = w
        borderLayer.frame.size.height = h
        borderLayer.cornerRadius = r

        imageLayer.frame.size.width = w
        imageLayer.frame.size.height = h
        if let m = imageLayer.mask {
            m.cornerRadius = r
        }

        if hasShadow {
            if isGroup {
                shadowPath = UIBezierPath(roundedRect: CGRect(origin: CGPoint(x: 0, y: 0), size: self.frame.size), cornerRadius: AvatarGem.groupCornerRadius)
            } else {
                shadowPath = UIBezierPath(ovalInRect: CGRect(x: 0, y: 0, width: self.frame.width, height: self.frame.height))
            }

            self.layer.shadowPath = shadowPath.CGPath
        } else {
            self.layer.shadowOpacity = 0
            self.borderLayer.borderWidth = 0
        }
    }
}
