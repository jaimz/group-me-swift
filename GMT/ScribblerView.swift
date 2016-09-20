//
//  ScribblerView.swift
//  GMT
//
//  Created by James O'Brien on 27/07/2016.
//  Copyright © 2016 James O'Brien. All rights reserved.
//

import UIKit


/// Provides a view the user can "scribble" on with their finger
class ScribblerView: UIView {
    private var bezierPoints = Array<CGPoint>(count: 5, repeatedValue: CGPoint())
    private var bezierPath = UIBezierPath()
    private var bezierCounter : Int = 0
    private var maxPoint = CGPointZero
    private var minPoint = CGPointZero

    var strokeColor : UIColor = UIColor.blackColor()
    var strokeWidth : CGFloat = 2.0


    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setup()
    }


    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setup()
    }

    private func setup() {
        bezierPath.lineWidth = strokeWidth
    }

    override func drawRect(rect: CGRect) {
        bezierPath.stroke()
        strokeColor.setStroke()
        bezierPath.stroke()
    }

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let touch = touches.first {
            bezierPoints[0] = touch.locationInView(self)
            bezierCounter = 0
        }
    }

    override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
        if let touch = touches.first {
            let point = touch.locationInView(self)
            bezierCounter += 1
            bezierPoints[bezierCounter] = point

            if bezierCounter == 4 {
                bezierPoints[3] = CGPointMake((bezierPoints[2].x + bezierPoints[4].x) / 2,
                                              (bezierPoints[2].y + bezierPoints[4].y) / 2)
                bezierPath.moveToPoint(bezierPoints[0])
                bezierPath.addCurveToPoint(bezierPoints[3], controlPoint1: bezierPoints[1], controlPoint2: bezierPoints[2])
                setNeedsDisplay()
                bezierPoints[0] = bezierPoints[3]
                bezierPoints[1] = bezierPoints[4]
                bezierCounter = 1
            }
        }
    }

    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        bezierCounter = 0
    }


    func getJPEGImageData() -> NSData? {
        UIGraphicsBeginImageContext(CGSizeMake(self.bounds.size.width, self.bounds.size.height))
        self.layer.renderInContext(UIGraphicsGetCurrentContext()!)
        let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()

        return UIImageJPEGRepresentation(image, 0.5)
    }

    func clear() {
        bezierPath.removeAllPoints()
        setNeedsDisplay()
    }

}
