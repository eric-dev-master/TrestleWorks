//
//  ShapeFactory.swift
//  Construction
//
//  Created by Macmini on 11/3/17.
//  Copyright © 2017 LekshmySankar. All rights reserved.
//

import UIKit

typealias Dict = [String: Any]

class ShapeFactory: NSObject {
    static let shared = ShapeFactory()
    
    func create(type: ShapeType, color: UIColor) -> Shape?{
        var shape: Shape? = nil
        switch type {
        case .LINE:
            shape = Line()
            break
        case .RECTANGLE:
            shape = Rectangle()
            break
        case .TRIANGLE:
            shape = Triangle()
            break
        case .CIRCLE:
            shape = Circle()
            break
        case .POLYGON:
            shape = Polygon()
            break
        case .CROSSLINE:
            shape = CrossLine()
            break
        default:
            break
        }
        
        if let shape = shape {
            shape.type = type
            shape.color = color
        }
        return shape
    }
    
    func decodeShape(from dict: Dict) -> Shape? {
        return nil
    }
    
    func getRandomColor() -> UIColor{
        let randomRed:CGFloat = CGFloat(drand48())
        let randomGreen:CGFloat = CGFloat(drand48())
        let randomBlue:CGFloat = CGFloat(drand48())
        return UIColor(red: randomRed, green: randomGreen, blue: randomBlue, alpha: 1.0)
        
    }
}
