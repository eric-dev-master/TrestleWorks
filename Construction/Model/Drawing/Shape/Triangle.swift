//
//  Triangle.swift
//  Construction
//
//  Created by Macmini on 11/3/17.
//  Copyright © 2017 LekshmySankar. All rights reserved.
//

import UIKit

class Triangle: Shape {
    override func drawShape(context: CGContext, zoomScale: CGFloat) -> Bool {
        guard super.drawShape(context: context, zoomScale: zoomScale) else {
            return false
        }
        
        context.beginPath()
        context.setLineWidth(lineWidth * zoomScale)
        context.setLineCap(.round)
        context.setLineDash(phase: 0, lengths: [])
        context.setStrokeColor(self.color.cgColor)
        
        if (points.count == 4) {
            let startPoint = CGPoint(x: (points[0].x + points[3].x)/2, y:(points[0].y + points[3].y)/2)
            context.move(to: startPoint)
            context.addLine(to: points[1])
            context.addLine(to: points[2])
            context.addLine(to: startPoint)
        }
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
