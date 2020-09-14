//
//  Line.swift
//  Construction
//
//  Created by Macmini on 11/3/17.
//  Copyright © 2017 LekshmySankar. All rights reserved.
//

import UIKit

class Line: Shape {
    override func drawShape(context: CGContext, zoomScale: CGFloat) -> Bool {
        guard super.drawShape(context: context, zoomScale: zoomScale) else {
            return false
        }
        
        if self.points.count != 4 {
            return false
        }
        
        context.beginPath()
        context.setLineWidth(lineWidth * zoomScale)
        context.setLineCap(.round)
        context.setLineDash(phase: 0, lengths: [])
        context.setStrokeColor(self.color.cgColor)
        
        context.move(to: points[0])        
        context.addLine(to: points[2])
        
        context.strokePath()
        return true
    }
    
    override func isUpdatablePoint(point: CGPoint) -> Int {
        let index = super.isUpdatablePoint(point: point)
        if index == 0 || index == 2 {
            return index
        }
        return -1
    }
    
    override func updateBoundRect() {
        if points.count != 4 {
            return
        }
        let minX: CGFloat = min(points[0].x, points[2].x)
        let minY: CGFloat = min(points[0].y, points[2].y)
        let maxX: CGFloat = max(points[0].x, points[2].x)
        let maxY: CGFloat = max(points[0].y, points[2].y)
        self.boundRect = CGRect(x: minX, y: minY, width: maxX - minX, height: maxY - minY)
    }
}
