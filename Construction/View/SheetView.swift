//
//  DesignView.swift
//  Construction
//
//  Created by Macmini on 11/3/17.
//  Copyright © 2017 LekshmySankar. All rights reserved.
//

import UIKit

@IBDesignable class SheetView: UIView {
    var imageView: UIImageView!
    var shapeView: ShapeOverlayView!
    var sheet: Sheet! {
        didSet {
            if shapeView != nil {
                shapeView.sheet = sheet
            }
            
            if self.imageView != nil {
                imageView!.image = sheet.image;
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initViews()
    }
    
    func initViews() {
        self.isUserInteractionEnabled = true
        
        imageView = UIImageView(frame: self.bounds)
        if let sheet = self.sheet, let image = sheet.image {
            imageView.image = image
        }
        self.addSubview(imageView)
        
        shapeView = ShapeOverlayView(frame: self.bounds)
        shapeView.backgroundColor = UIColor.clear
        shapeView.isUserInteractionEnabled = true
        self.addSubview(shapeView)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        self.imageView.frame = self.bounds
        self.shapeView.frame = self.bounds
    }
}
