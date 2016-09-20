//
//  InsetShadowView.swift
//  GMT
//
//  Created by James O'Brien on 16/08/2016.
//  Copyright © 2016 James O'Brien. All rights reserved.
//

import UIKit

class InsetShadowView: UIView {

    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // TODO: clip
        GMTStyleKit.drawInnerShadowRect(rectSize: rect.size)
    }

}
