//
//  CrossLine.swift
//  Construction
//
//  Created by Macmini on 11/6/17.
//  Copyright © 2017 LekshmySankar. All rights reserved.
//

import UIKit

class CrossLine: Shape {
    override func drawShape(context: CGContext, zoomScale: CGFloat) -> Bool {
        guard super.drawShape(context: context, zoomScale: zoomScale) else {
            return false
        }
        
        guard points.count == 4 else {
            return false
        }
        
        context.beginPath()
        context.setLineWidth(lineWidth * zoomScale)
        context.setLineCap(.round)
        context.setStrokeColor(self.color.cgColor)
        context.setLineDash(phase: 0, lengths: [])
        
        context.move(to: points[0])
        context.addLine(to: points[2])
        
        context.move(to: points[1])
        context.addLine(to: points[3])
        context.strokePath()
        return true
    }
    
    override func update(at index: Int, with point: CGPoint) {
        if index == -1 {
            return
        }
        
        let old = points[index]
        for i in 0..<points.count {
            if i == index {
                continue
            }
            
            if points[i].x == old.x {
                points[i].x = point.x
            }
            
            if points[i].y == old.y {
                points[i].y = point.y
            }
        }
        super.update(at: index, with: point)
    }
}
