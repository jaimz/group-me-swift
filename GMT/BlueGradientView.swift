//
//  BlueGradientView.swift
//  GMT
//
//  Created by James O'Brien on 26/06/2016.
//  Copyright © 2016 James O'Brien. All rights reserved.
//

import UIKit

@IBDesignable
class BlueGradientView: UIView {
    let backgroundGradient = CGGradientCreateWithColors(CGColorSpaceCreateDeviceRGB(), [GMTStyleKit.blueStart.CGColor, GMTStyleKit.blueEnd.CGColor], [0, 1])!



    override func drawRect(rect: CGRect) {
        let context = UIGraphicsGetCurrentContext()
        CGContextClipToRect(context, rect);

        let width = self.frame.width
        let height = self.frame.height
        let midx = width / 2.0

        let backgroundPath = UIBezierPath(rect: CGRectMake(0, 0, width, height))
        CGContextSaveGState(context)
        backgroundPath.addClip()
        CGContextDrawRadialGradient(context, backgroundGradient,
                                    CGPointMake(midx, 0), 0,
                                    CGPointMake(midx, 0), height,
                                    [CGGradientDrawingOptions.DrawsBeforeStartLocation, CGGradientDrawingOptions.DrawsAfterEndLocation])
        CGContextRestoreGState(context)
    }
}
