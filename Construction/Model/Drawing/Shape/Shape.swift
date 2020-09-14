//
//  Shape.swift
//  Construction
//
//  Created by Macmini on 11/3/17.
//  Copyright © 2017 LekshmySankar. All rights reserved.
//

import UIKit

enum ShapeType: Int {
    case NONE = -1
    case LINE = 0
    case CIRCLE = 1
    case RECTANGLE = 2
    case TRIANGLE = 3
    case CROSSLINE = 4
    case POLYGON = 5
}

let lineWidth: CGFloat = 2.0

class FBShape: Object {
    @objc dynamic var isClosed: Bool = false
    @objc dynamic var type: Int = -1
    @objc dynamic var points = [String]()
    @objc dynamic var color: String?
}

class Shape {
    var fbshape: FBShape! 
    var isClosed: Bool = false
    var type: ShapeType = .NONE {
        didSet {
            if fbshape != nil {
                fbshape.type = type.rawValue
            }
        }
    }
    var points = [CGPoint]() {
        didSet {
            self.updateBoundRect()
        }
    }
    var color: UIColor = UIColor.black {
        didSet {
            if fbshape != nil {
                fbshape.color = color.toHexString()
            }
        }
    }
    var boundRect: CGRect = CGRect.zero
    var selected: Bool = false
    
    var updatingPointIndex: Int = -1
    
    class func shape(from fbshape: FBShape) -> Shape? {
        if let type = ShapeType(rawValue: fbshape.type),
            let color = fbshape.color {
            if let shape = ShapeFactory.shared.create(type: type, color: UIColor(hexString: color)) {
                shape.isClosed = fbshape.isClosed
                shape.points = fbshape.points.map() { return CGPointFromString($0)}
                shape.fbshape = fbshape
                shape.type = type
                return shape
            }
        }
        return nil
    }
    
    func fbShape() -> FBShape? {
        let fbshape = FBShape()
        fbshape.color = self.color.toHexString()
        fbshape.type = self.type.rawValue
        fbshape.points = self.points.map() { return NSStringFromCGPoint($0)}
        fbshape.isClosed = self.isClosed
        return fbshape
    }
    
    func updateFBShape() {
        if fbshape != nil {
            fbshape.points = points.map() { return NSStringFromCGPoint($0)}
        }
    }
    
    init() {
        self.type = .NONE
    }
    
    required init(from decoder: Decoder) throws {
        
    }
    
    func encode(to encoder: Encoder) {
        
    }
    
    func isUpdatablePoint(point: CGPoint) -> Int {
        for i in 0..<points.count {
            if Shape.distance(from: point, to: points[i]) < 5{
                return i
            }
        }
        return -1
    }
    
    func update(at index: Int, with point: CGPoint) {
        if (index == -1) {
            return
        }
        
        self.points.remove(at: index)
        self.points.insert(point, at: index)
        self.updateBoundRect()
    }
    
    func move(dp: CGPoint) {
        var newPoints = [CGPoint]()
        for point in points {
            let newpoint = CGPoint(x: point.x + dp.x, y: point.y + dp.y)
            newPoints.append(newpoint)
        }
        self.points = newPoints
    }
    
    func drawAt(context: CGContext, zoomScale: CGFloat) {
        if selected {
            drawBound(context: context)
        }
        
        _ = drawShape(context: context, zoomScale: zoomScale)
        
        if selected {
            drawDots(context: context, zoomScale: zoomScale)
        }
    }
    
    func drawShape(context: CGContext, zoomScale: CGFloat) -> Bool{
        guard points.count >= 1 else {
            return false
        }
        return true
    }

    func drawDots(context: CGContext, zoomScale: CGFloat) {
        if selected {
            context.beginPath()
            context.setLineWidth(zoomScale*2.0)
            context.setLineCap(.round)
            context.setStrokeColor(Colors.lightColor.cgColor)
            context.setLineDash(phase: 0, lengths: [])
            context.setFillColor(UIColor.white.cgColor)

            for point in self.points {
                if isUpdatablePoint(point: point) != -1 {
                    let circleRect = CGRect(origin: CGPoint(x: point.x - 5*zoomScale, y: point.y-5), size: CGSize(width: 10, height: 10))
                    context.fillEllipse(in: circleRect)
                    context.strokeEllipse(in: circleRect)
                    context.fillPath()
                }
            }
            context.strokePath()
        }
    }
    
    func drawBound(context: CGContext) {
        if self.points.count < 2 {
            return
        }
        
        context.beginPath()
        context.setLineWidth(1)
        context.setLineDash(phase: 3, lengths: [3, 12])
        context.setLineCap(.square)
        context.setStrokeColor(UIColor.black.cgColor)
        
        context.move(to: boundRect.origin)
        context.addLine(to: CGPoint(x: boundRect.origin.x, y: boundRect.origin.y + boundRect.size.height))
        context.addLine(to: CGPoint(x: boundRect.origin.x + boundRect.size.width, y: boundRect.origin.y + boundRect.size.height))
        context.addLine(to: CGPoint(x: boundRect.origin.x + boundRect.size.width, y: boundRect.origin.y))
        context.addLine(to: CGPoint(x: boundRect.origin.x, y: boundRect.origin.y))
        context.strokePath()
    }
    
    func addPoint(point: CGPoint) -> Bool{
        self.points.append(point)
        self.updateBoundRect()
        return true
    }
    
    func updateBoundRect() {
        var minX: CGFloat = 100000
        var minY: CGFloat = 100000
        var maxX: CGFloat = 0
        var maxY: CGFloat = 0
        
        for point in self.points {
            if (point.x <= minX) {
                minX = point.x
            }
            if (point.y <= minY) {
                minY = point.y
            }
            if (point.x >= maxX) {
                maxX = point.x
            }
            if (point.y >= maxY) {
                maxY = point.y
            }
        }
        self.boundRect = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}

extension Shape {
    class func distanceSquared(from: CGPoint, to: CGPoint) -> CGFloat {
        return (from.x - to.x) * (from.x - to.x) + (from.y - to.y) * (from.y - to.y)
    }

    class func distance(from: CGPoint, to: CGPoint) -> CGFloat {
        return sqrt(distanceSquared(from: from, to: to))
    }
}

