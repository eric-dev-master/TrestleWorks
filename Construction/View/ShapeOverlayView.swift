//
//  ShapeOverlayView.swift
//  Construction
//
//  Created by Macmini on 11/3/17.
//  Copyright © 2017 LekshmySankar. All rights reserved.
//

import UIKit

protocol ShapeOverLayDelegate {
    func needsFirstResponder(needsFirstResponder: Bool)
    func drawCancelled()
    func shapeCreated(_ shape: Shape)
    func shapeDeleted(_ shape: Shape)
    func focused()
}

@IBDesignable class ShapeOverlayView: UIView {
    var sheet: Sheet!
    var zoomeScale: CGFloat = 1.0
    
    var selectedType: ShapeType = .NONE {
        didSet {
            if self.delegate != nil {
                self.delegate.needsFirstResponder(needsFirstResponder: selectedType != .NONE)
            }
        }
    }
    var selectedColor: UIColor = Colors.darkColor
    var isDrawing: Bool = false

    var delegate: ShapeOverLayDelegate!
    
    private var _selectedShape: Shape?
    var selectedShape: Shape? {
        get {
            return _selectedShape
        }
        set {
            if let old = _selectedShape {
                old.selected = false
                self.hideDelete()
            }
            
            if let newShape = newValue {
                newShape.selected = true
                self.showDelete(on: newShape)
            }
            
            if self.delegate != nil {
                self.delegate.needsFirstResponder(needsFirstResponder: newValue != nil)
            }
            _selectedShape = newValue
        }
    }
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initialize()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }
    
    func hideDelete() {
        let menu = UIMenuController.shared
        menu.setMenuVisible(false, animated: true)
    }
    
    func showDelete(on shape: Shape) {
        let menu = UIMenuController.shared
        menu.menuItems = [UIMenuItem(title: "Delete", action: #selector(ShapeOverlayView.deleteShape))]
        menu.setTargetRect(shape.boundRect, in: self)
        menu.setMenuVisible(true, animated: true)
        becomeFirstResponder()
    }
    
    @objc func deleteShape() {
        if let shape = self.selectedShape {
            if let index = self.sheet.shapes.index(where: { (shapeInShapes) -> Bool in
                if shape.fbshape == shapeInShapes.fbshape {
                    return true
                }
                return false
            }) {
                self.sheet.shapes.remove(at: index)
            }
            
            if let delegate = self.delegate {
                delegate.shapeDeleted(shape)
            }
            
            DispatchQueue.main.async {
                self.selectedShape = nil
                self.redraw()
            }
        }
    }
    
    func initialize() {
        self.contentMode = .scaleToFill
        if sheet == nil {
            sheet = Sheet()
        }
        self.selectedShape = nil
        self.isUserInteractionEnabled = true
        self.isMultipleTouchEnabled = true
        becomeFirstResponder()
    }
    
    override func draw(_ rect: CGRect) {
        guard let shapes = self.sheet.shapes else {
            return
        }
        
        if let context = UIGraphicsGetCurrentContext() {
            for shape in shapes {
                _ = shape.drawAt(context: context, zoomScale: zoomeScale)
            }
            
            if let current = selectedShape {
                _ = current.drawAt(context: context, zoomScale: zoomeScale)
            }
        }
    }
    
    func redraw() {
        setNeedsDisplay()
    }
    
    func shapeAtPoint(point: CGPoint) -> Shape? {
        for i in (0..<sheet.shapes.count).reversed(){
            if sheet.shapes[i].boundRect.contains(point) {
                return sheet.shapes[i]
            }
        }
        return nil
    }
    
    func createShape(shape: Shape) {
        sheet.shapes.append(shape)
        if let delegate = self.delegate {
            delegate.shapeCreated(shape)
        }
//        self.selectedType = .NONE
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.count > 1 {
            return
        }
        
        if let delegate = self.delegate {
            delegate.focused()
        }
        
        if let touch = touches.first {
            let point = touch.location(in: self)
            
            if isDrawing == false {
                //select shape at point
                if let shape = self.selectedShape {
                    let index = shape.isUpdatablePoint(point: point)
                    if index != -1 {
                        shape.updatingPointIndex = index
                        return
                    }
                }
                
                if let shape = shapeAtPoint(point: point) {
                    self.selectedShape = shape
                }
                else {
                    if let shape = ShapeFactory.shared.create(type: selectedType, color: selectedColor) {
                        isDrawing = true
                        _ = shape.addPoint(point: point)
                        self.selectedShape = shape
                    }
                    else {
                        self.selectedShape = nil
                    }
                }
            }
            else {
                if let shape = self.selectedShape{
                    if shape.type == .POLYGON {
                        if shape.addPoint(point: point) == false {
                            self.createShape(shape: shape)
                            shape.updateFBShape()
                            shape.isClosed = true
                            self.selectedShape = nil
                            isDrawing = false
                        }
                    }
                }
            }
            redraw()
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.count > 1 {
            return
        }
        
        if let touch = touches.first {
            let point = touch.location(in: self)
            if isDrawing {
                guard let shape = selectedShape else {
                    return
                }
                
                guard shape.type != .POLYGON else {
                    return
                }
                
                if shape.points.count > 0 {
                    var points = [CGPoint]()
                    let start = shape.points[0]
                    points.append(start)
                    points.append(CGPoint(x: start.x, y: point.y))
                    points.append(point)
                    points.append(CGPoint(x: point.x, y: start.y))
                    shape.points = points
                }
            }
            else {
                let prevPoint = touch.previousLocation(in: self)
                if let shape = selectedShape {
                    if shape.updatingPointIndex != -1 {
                        shape.update(at: shape.updatingPointIndex, with: point)
                    }
                    else {
                        if shape.boundRect.contains(point) {
                            shape.move(dp: CGPoint(x: point.x - prevPoint.x, y: point.y - prevPoint.y))
                        }
                    }
                }
            }
        }
        redraw()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.count > 1 {
            return
        }
        
        guard let shape = self.selectedShape else {
            return
        }
        
        guard shape.type != .POLYGON else {
            if !isDrawing {
                if shape.updatingPointIndex != -1 {
                    shape.updatingPointIndex = -1;
                }
            }
            return
        }
        
        if isDrawing {
            if shape.points.count >= 2 {
                self.createShape(shape: shape)
            }
            else {
                if let delegate = self.delegate {
                    delegate.drawCancelled()
                }
                self.selectedShape = nil
            }
            isDrawing = false
        }
        else {
            if shape.updatingPointIndex != -1 {
                shape.updatingPointIndex = -1;
            }
        }
        shape.updateFBShape()
        redraw()
    }
}

extension ShapeOverlayView {
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(ShapeOverlayView.deleteShape) {
            return true
        }
        return false
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
}
