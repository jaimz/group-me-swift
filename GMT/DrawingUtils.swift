//
//  DrawingUtils.swift
//  GMT
//
//  Created by James O'Brien on 28/06/2016.
//  Copyright © 2016 James O'Brien. All rights reserved.
//

import UIKit

class DrawingUtils {
    static func ApplyShadowToLayer(shadow: NSShadow, layer: CALayer) {
        layer.shadowColor = shadow.shadowColor?.CGColor
        layer.shadowRadius = shadow.shadowBlurRadius
        layer.shadowOffset = shadow.shadowOffset
        layer.shadowOpacity = 1.0
        layer.masksToBounds = false
    }

    static func ApplyShadowToView(shadow: NSShadow, view: UIView) {
        DrawingUtils.ApplyShadowToLayer(shadow, layer: view.layer)
    }
    
    static let insetShadowLayerDelegate = InsetShadowLayerDelegate()
}

class InsetShadowLayerDelegate : NSObject {
    override func drawLayer(layer: CALayer, inContext context: CGContext) {
        let rectSize = layer.frame.size
        
        //// ShadowRectangle Drawing
        let shadowRectanglePath = UIBezierPath(rect: CGRectMake(0, -0, rectSize.width, rectSize.height))
        UIColor.clearColor().setFill()
        shadowRectanglePath.fill()
        
        ////// ShadowRectangle Inner Shadow
        CGContextSaveGState(context)
        CGContextClipToRect(context, shadowRectanglePath.bounds)
        CGContextSetShadow(context, CGSizeMake(0, 0), 0)
        CGContextSetAlpha(context, CGColorGetAlpha((GMTStyleKit.subtleShadow.shadowColor as! UIColor).CGColor))
        CGContextBeginTransparencyLayer(context, nil)
        let shadowRectangleOpaqueShadow = (GMTStyleKit.subtleShadow.shadowColor as! UIColor).colorWithAlphaComponent(1)
        CGContextSetShadowWithColor(context, GMTStyleKit.subtleShadow.shadowOffset, GMTStyleKit.subtleShadow.shadowBlurRadius, shadowRectangleOpaqueShadow.CGColor)
        CGContextSetBlendMode(context, .SourceOut)
        CGContextBeginTransparencyLayer(context, nil)
        
        shadowRectangleOpaqueShadow.setFill()
        shadowRectanglePath.fill()
        
        CGContextEndTransparencyLayer(context)
        CGContextEndTransparencyLayer(context)
        CGContextRestoreGState(context)

    }
}