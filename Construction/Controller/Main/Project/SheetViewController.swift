//
//  SceneViewController.swift
//  Construction
//
//  Created by Macmini on 10/30/17.
//  Copyright © 2017 LekshmySankar. All rights reserved.
//

import UIKit
import SDWebImage
import SVProgressHUD

class SheetViewController: BarHidableViewController {
    var dataSource: DataSource<FBShape>?
    var sheet: Sheet?
    @IBOutlet weak var sheetScrollView: SheetScrollView!
    @IBOutlet weak var tblShapes: UITableView!
    @IBOutlet weak var tblColors: UITableView!
    
    @IBOutlet weak var btnShape: UIButton!
    @IBOutlet weak var btnColor: UIButton!
    var selectedShape: ShapeType! {
        didSet {
            if selectedShape == .NONE {
                btnShape.setImage(UIImage(named: "icon_drawing")!, for: .normal)
            }
            else {
                if let image = UIImage(named: shape_images[selectedShape.rawValue]) {
                    btnShape.setImage(image, for: .normal)
                }
            }
            sheetScrollView.sheetView?.shapeView.selectedType = selectedShape
        }
    }
    
    var selectedColor: UIColor! {
        didSet {
            self.btnColor.tintColor = selectedColor
            self.btnShape.tintColor = selectedColor
            sheetScrollView.sheetView?.shapeView.selectedColor = selectedColor
        }
    }
    
    @IBOutlet weak var shapeBarHeight: NSLayoutConstraint!
    @IBOutlet weak var colorBarHeight: NSLayoutConstraint!
    
    let shape_images = ["shape_line",
                        "shape_circle",
                        "shape_rectangle",
                        "shape_triangle",
                        "shape_crossline",
                        "shape_polygon"
                        ]
    let shape_colors = [#colorLiteral(red: 0.004275538559, green: 0.0395718485, blue: 0.06890592191, alpha: 1),#colorLiteral(red: 1, green: 0.2509803922, blue: 0.2509803922, alpha: 1),#colorLiteral(red: 0.03051852062, green: 0.598608017, blue: 0.6147770882, alpha: 1),#colorLiteral(red: 1, green: 1, blue: 0.4, alpha: 1),#colorLiteral(red: 0, green: 1, blue: 0.4980392157, alpha: 1),#colorLiteral(red: 0.2, green: 0.6, blue: 1, alpha: 1),#colorLiteral(red: 0.8770627379, green: 0.685231328, blue: 0.346683234, alpha: 1)]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadSheetDetail()
        shapeBarHeight.constant = 0
        colorBarHeight.constant = 0
        
        tblShapes.layer.cornerRadius = 3
        tblShapes.layer.borderWidth = 1
        tblShapes.layer.borderColor = Colors.lightColor.cgColor
        
        tblColors.layer.cornerRadius = 3
        tblColors.layer.borderWidth = 1
        tblColors.layer.borderColor = Colors.lightColor.cgColor
        
        sheetScrollView.zoomDelegate = self
        loadShapes()
    }
    
    func loadShapes () {
        if let sheet = self.sheet {
            sheet.shapes.removeAll()
            let options: Options = Options()
            options.limit = 100
            options.sortDescirptors = [NSSortDescriptor(key: "createdAt", ascending: true)]
            self.dataSource = DataSource(reference: sheet.ref.child("shapeIds"), options: options, block: { (changes) in
                switch changes {
                case .initial:
                    self.updateShapesFromDB()
                case .error(let error):
                    print(error)
                case .update( _/*let deletion*/, _/*let insertions*/, _/*let modifications*/):
                    break
                }
            })
        }
    }
    
    func updateShapesFromDB() {
        if let dataSource = self.dataSource,
            let sheet = self.sheet {
            for fbshape in dataSource.objects {
                if let shape = Shape.shape(from: fbshape) {
                    sheet.shapes.append(shape)
                }
            }
            DispatchQueue.main.async {
                self.sheetScrollView.sheetView?.shapeView.redraw()
            }
        }
    }
    
    func loadSheetDetail() {
        guard let sheet = self.sheet else {
            return
        }
        
        self.title = sheet.name
        if let file = sheet.backgroundImage {
            if let url = file.downloadURL {
                if SDImageCache.shared().diskImageDataExists(withKey: url.absoluteString) == false {
                    if file.data == nil {
                        if file.downloadTask == nil {
                            SVProgressHUD.show()
                            let _ = file.dataWithMaxSize(9999999, completion: { (data, err) in
                                SVProgressHUD.dismiss()
                                if let data = data {
                                    file.data = data
                                    DispatchQueue.global(qos: .background).async {
                                        SDImageCache.shared().storeImageData(toDisk: data, forKey: url.absoluteString)
                                        DispatchQueue.main.async {
                                            if let image = UIImage(data: data) {
                                                sheet.image = image
                                                self.sheetScrollView.sheet = sheet
                                                self.sheetScrollView.refresh()
                                            }
                                        }
                                    }
                                }
                            })
                        }
                    }
                }
                else {
                    if let image = SDImageCache.shared().imageFromCache(forKey: url.absoluteString) {
                        if let data = image.sd_imageData() {
                            file.data = data
                            sheet.image = image
                            sheetScrollView.sheet = sheet
                            sheetScrollView.refresh()
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func onClose(_ sender: Any) {
        if let present = self.presentingViewController {
            present.dismiss(animated: true, completion: nil)
        }
    }
    
    @IBAction func onShape(_ sender: Any) {
        if tblShapes.bounds.size.height == 0 {
            self.showShapeBar(show: true)
        }
        else {
            self.showShapeBar(show: false)
        }
    }
    
    @IBAction func onColor(_ sender: Any) {
        if tblColors.bounds.size.height == 0 {
            self.showColorBar(show: true)
        }
        else {
            self.showColorBar(show: false)
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIDevice.current.setValue(UIInterfaceOrientation.portrait.rawValue, forKey: "orientation")
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        sheetScrollView.refresh()
    }
}

extension SheetViewController: SheetScrollViewDelegate {
    func didEndZoom(scrollView: SheetScrollView) {
        
    }
    
    func didBeginZoom(scrollView: SheetScrollView) {
        self.selectedShape = .NONE
    }
    
    func hideShapeBar() {
        self.showColorBar(show: false)
        self.showShapeBar(show: false)
    }
}

extension SheetViewController { //Shape & Color UI
    func showColorBar(show: Bool, animated: Bool = true) {
        var time = 0.0
        if animated {
            time = 0.3
        }
        
        var size = 0
        if show {
            size = shape_colors.count * 30
        }
        
        UIView.animate(withDuration: time) {
            self.colorBarHeight.constant = CGFloat(size)
            self.view.layoutIfNeeded()
        }
    }
    
    func showShapeBar(show: Bool, animated: Bool = true) {
        var time = 0.0
        if animated {
            time = 0.3
        }
        
        var size = 0
        if show {
            size = shape_images.count * 30
        }
        
        UIView.animate(withDuration: time) {
            self.shapeBarHeight.constant = CGFloat(size)
            self.view.layoutIfNeeded()
        }
    }
}

extension SheetViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == tblColors {
            return shape_colors.count
        }
        else {
            return shape_images.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == tblColors {
            let cell = tableView.dequeueReusableCell(withIdentifier: "COLOR_CELL", for: indexPath) as! ColorTableViewCell
            cell.reset(newColor: shape_colors[indexPath.row])
            
            return cell
        }
        else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "SHAPE_CELL", for: indexPath) as! ShapeTableViewCell
            cell.reset(shape_images[indexPath.row])
            return cell
        }
    }
}

extension SheetViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 30
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if tableView == tblColors {
            self.showColorBar(show: false)
            self.selectedColor = shape_colors[indexPath.row]
        }
        else {
            self.showShapeBar(show: false)
            self.selectedShape = ShapeType(rawValue: indexPath.row)
        }
    }
}

class ShapeTableViewCell: UITableViewCell {
    @IBOutlet weak var imgShape: UIImageView!
    var imgName: String?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        imgShape.tintColor = UIColor.white
    }
    
    func reset(_ newImgName: String) {
        if let name = imgName {
            if name != newImgName {
                self.imgName = newImgName
                if let image = UIImage(named: newImgName) {
                    self.imgShape.image = image
                }
            }
        }
        else {
            self.imgName = newImgName
            if let image = UIImage(named: newImgName) {
                self.imgShape.image = image
            }
        }
    }
}

class ColorTableViewCell: UITableViewCell {
    @IBOutlet weak var vwColor: UIView!
    var color: UIColor?
    
    func reset(newColor: UIColor) {
        if color == newColor {
            return
        }
        self.color = newColor
        self.vwColor.backgroundColor = self.color
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        vwColor.layer.cornerRadius = vwColor.bounds.size.height/2
    }
}

