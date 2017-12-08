//
//  BWCircularSlider.swift
//  TB_CustomControlsSwift
//
//  Created by Yari D'areglia on 03/11/14.
//  Copyright (c) 2014 Yari D'areglia. All rights reserved.
//

import UIKit

struct Config {
    
    static let TB_SLIDER_SIZE:CGFloat = UIScreen.main.bounds.size.width
    static let TB_SAFEAREA_PADDING:CGFloat = 60.0
    static let TB_LINE_WIDTH:CGFloat = 40.0
    static let TB_FONTSIZE:CGFloat = 40.0
    
}


// MARK: Math Helpers 

func DegreesToRadians (_ value:Double) -> Double {
    return value * .pi / 180.0
}

func RadiansToDegrees (_ value:Double) -> Double {
    return value * 180.0 / .pi
}

func Square (_ value:CGFloat) -> CGFloat {
    return value * value
}


// MARK: Circular Slider

class BWCircularSlider: UIControl {

    var textField:UITextField?
    var radius:CGFloat = 0
    var angle:Int = 360
    var startColor = UIColor.blue
    var endColor = UIColor.purple
    
    // Custom initializer
    convenience init(startColor:UIColor, endColor:UIColor, frame:CGRect){
        self.init(frame: frame)
        
        self.startColor = startColor
        self.endColor = endColor
    }
    
    // Default initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.clear
        self.isOpaque = true
        
        //Define the circle radius taking into account the safe area
        radius = self.frame.size.width/2 - Config.TB_SAFEAREA_PADDING
        
        //Define the Font
        let font = UIFont(name: "Avenir", size: Config.TB_FONTSIZE)
        //Calculate font size needed to display 3 numbers
        let str = "000" as NSString
        let fontSize:CGSize = str.size(withAttributes: [.font:font!])
        
        //Using a TextField area we can easily modify the control to get user input from this field
        let textFieldRect = CGRect(
            x: (frame.size.width  - fontSize.width) / 2.0,
            y: (frame.size.height - fontSize.height) / 2.0,
            width: fontSize.width, height: fontSize.height);
        
        textField = UITextField(frame: textFieldRect)
        textField?.backgroundColor = UIColor.clear
        textField?.textColor = UIColor(white: 1.0, alpha: 0.8)
        textField?.textAlignment = .center
        textField?.font = font
        textField?.text = "\(self.angle)"
        
        addSubview(textField!)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        super.beginTracking(touch, with: event)
        
        return true
    }
    
    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        super.continueTracking(touch, with: event)
        
        let lastPoint = touch.location(in: self)
        
        self.moveHandle(lastPoint: lastPoint)
        
        self.sendActions(for: .valueChanged)
        
        return true
    }
    
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        super.endTracking(touch, with: event)
    }
    
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        guard let ctx = UIGraphicsGetCurrentContext() else {
            return
        }
        
        /** Draw the Background **/
        
        ctx.addArc(center: CGPoint(x: bounds.size.width / 2, y: bounds.size.height / 2), radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: false)
        UIColor.black.set()
        
        ctx.setLineWidth(72)
        ctx.setLineCap(.butt)
        
        ctx.drawPath(using: .stroke)
        
        /** Draw the circle **/
        
        /** Create THE MASK Image **/
        let renderer = UIGraphicsImageRenderer(size: bounds.size)
        let maskImage = renderer.image { (imageRendererContext) in
            let ctx = imageRendererContext.cgContext
            ctx.addArc(center: CGPoint(x: bounds.size.width / 2, y: bounds.size.height / 2), radius: radius, startAngle: 0, endAngle: CGFloat(DegreesToRadians(Double(angle))), clockwise: false)
            UIColor.red.set()
            
            //Use shadow to create the Blur effect
            ctx.setShadow(offset: .zero, blur: CGFloat(self.angle / 15), color: UIColor.black.cgColor)
            
            //define the path
            ctx.setLineWidth(Config.TB_LINE_WIDTH)
            ctx.drawPath(using: .stroke)
        }
        let mask = maskImage.cgImage!
        
        /** Clip Context to the mask **/
        ctx.saveGState()
        
        ctx.clip(to: bounds, mask: mask)
        
        
        /** The Gradient **/
        
        // Split colors in components (rgba)
        let startColorComps = startColor.cgColor.components!
        let endColorComps = endColor.cgColor.components!
        
        let components : [CGFloat] = [
            startColorComps[0], startColorComps[1], startColorComps[2], 1.0,     // Start color
            endColorComps[0], endColorComps[1], endColorComps[2], 1.0      // End color
        ]
        
        // Setup the gradient
        let baseSpace = CGColorSpaceCreateDeviceRGB()
        let gradient = CGGradient(colorSpace: baseSpace, colorComponents: components, locations: nil, count: 2)
        
        // Gradient direction
        let startPoint = CGPoint(x: rect.midX, y: rect.minY)
        let endPoint = CGPoint(x: rect.midX, y: rect.maxY)
        
        // Draw the gradient
        ctx.drawLinearGradient(gradient!, start: startPoint, end: endPoint, options: [])
        
        /* Draw the handle */
        drawTheHandle(ctx: ctx)
    }
    
    /** Draw a white knob over the circle **/
    
    func drawTheHandle(ctx:CGContext){
        
        ctx.saveGState()
        
        //I Love shadows
        ctx.setShadow(offset: .zero, blur: 3, color: UIColor.black.cgColor)
        
        //Get the handle position
        let handleCenter = pointFromAngle(angleInt: angle)

        //Draw It!
        UIColor(white:1.0, alpha:0.7).set();
        ctx.fillEllipse(in: CGRect(x: handleCenter.x, y: handleCenter.y, width: Config.TB_LINE_WIDTH, height: Config.TB_LINE_WIDTH))
        
        ctx.restoreGState()
    }
    
    
    
    /** Move the Handle **/

    func moveHandle(lastPoint:CGPoint){
        
        //Get the center
        let centerPoint:CGPoint  = CGPoint(x: self.frame.size.width/2, y: self.frame.size.height/2);
        //Calculate the direction from a center point and a arbitrary position.
        let currentAngle:Double = AngleFromNorth(p1: centerPoint, p2: lastPoint, flipped: false);
        let angleInt = Int(floor(currentAngle))

        //Store the new angle
        angle = Int(360 - angleInt)

        //Update the textfield
        textField!.text = "\(angle)"
        
        //Redraw
        setNeedsDisplay()
    }
    
    /** Given the angle, get the point position on circumference **/
    func pointFromAngle(angleInt:Int)->CGPoint{
    
        //Circle center
        let centerPoint = CGPoint(x: self.frame.size.width/2.0 - Config.TB_LINE_WIDTH/2.0, y: self.frame.size.height/2.0 - Config.TB_LINE_WIDTH/2.0);

        //The point position on the circumference
        var result:CGPoint = .zero
        let y = round(Double(radius) * sin(DegreesToRadians(Double(-angleInt)))) + Double(centerPoint.y)
        let x = round(Double(radius) * cos(DegreesToRadians(Double(-angleInt)))) + Double(centerPoint.x)
        result.y = CGFloat(y)
        result.x = CGFloat(x)
            
        return result;
    }
    
    
    //Sourcecode from Apple example clockControl
    //Calculate the direction in degrees from a center point to an arbitrary position.
    func AngleFromNorth(p1:CGPoint , p2:CGPoint , flipped:Bool) -> Double {
        var v:CGPoint  = CGPoint(x: p2.x - p1.x, y: p2.y - p1.y)
        let vmag:CGFloat = Square(Square(v.x) + Square(v.y))
        var result:Double = 0.0
        v.x /= vmag;
        v.y /= vmag;
        let radians = Double(atan2(v.y,v.x))
        result = RadiansToDegrees(radians)
        return (result >= 0  ? result : result + 360.0);
    }

}
