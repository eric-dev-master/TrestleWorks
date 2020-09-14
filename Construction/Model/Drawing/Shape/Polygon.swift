//
//  Polygon.swift
//  Construction
//
//  Created by Macmini on 11/3/17.
//  Copyright © 2017 LekshmySankar. All rights reserved.
//

import UIKit

class Polygon: Shape {
    override func drawShape(context: CGContext, zoomScale: CGFloat) -> Bool {
        guard super.drawShape(context: context, zoomScale: zoomScale) else {
            return false
        }
        
        context.beginPath()
        context.setLineWidth(lineWidth * zoomScale)
        context.setLineCap(.round)
        context.setLineDash(phase: 0, lengths: [])
        context.setStrokeColor(self.color.cgColor)
        
        var startPoint = points[0]
        for point in self.points {
            if point == startPoint {
                continue
            }
            
            context.move(to: startPoint)
            context.addLine(to: point)
            startPoint = point
        }
        if isClosed {
            context.addLine(to: points[0])
        }
        
        context.strokePath()
        return true
    }
    
    override func addPoint(point: CGPoint) -> Bool {
        if self.points.count >= 2 {
            if (Shape.distance(from: points[0], to: point) <= 10.0) {
                return false
            }
        }
        return super.addPoint(point: point)
    }
}
