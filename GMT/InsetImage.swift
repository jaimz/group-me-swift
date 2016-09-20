//
//  InsetImage.swift
//  GMT
//
//  Created by James O'Brien on 09/08/2016.
//  Copyright © 2016 James O'Brien. All rights reserved.
//

import UIKit
import QuartzCore
import WebImage

/// A UIImage clone that draws an inner shadow on its image
class InsetImage: UIView {

    private let imageView = UIImageView()
    private let shadowView = InsetShadowView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }


    func setup() {
        imageView.contentMode = UIViewContentMode.ScaleAspectFill
        imageView.clipsToBounds = true
        shadowView.backgroundColor = UIColor.clearColor()
        
        self.addSubview(imageView)
        self.addSubview(shadowView)
    }

//    var image : UIImage? = .None {
//        didSet {
//            imageView.image = self.image
//        }
//    }
    
    var imageUrl : NSURL? = .None {
        didSet {
            if let url = imageUrl {
                imageView.sd_setImageWithURL(url)
            } else {
                imageView.image = nil
            }
        }
    }
    
    // NOTE(james): Kinda leaky, use a data: URL instead?
    var imageData : NSData? = .None {
        didSet {
            if let data = imageData {
                self.imageView.image = UIImage(data: data)
            } else {
                self.imageView.image = nil
            }
        }
    }

    override func layoutSubviews() {
        let f = CGRect(x: 0, y: 0, width: self.frame.size.width, height: self.frame.size.height)
        imageView.frame = f
        shadowView.frame = f
    }
}
