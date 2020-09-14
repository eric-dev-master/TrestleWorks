//
//  ImageScrollView.swift
//  Beauty
//
//  Created by Nguyen Cong Huy on 1/19/16.
//  Copyright © 2016 Nguyen Cong Huy. All rights reserved.
//

import UIKit

protocol SheetScrollViewDelegate {
    func didEndZoom(scrollView: SheetScrollView)
    func didBeginZoom(scrollView: SheetScrollView)
    func hideShapeBar()
}

open class SheetScrollView: UIScrollView {
    
    static let kZoomInFactorFromMinWhenDoubleTap: CGFloat = 2
    
    public var landscapeAspectFill = true; // If TRUE, the ImageScrollView will have an 'aspect fill' behavior when in landscape orientation. Otherwise, it will be aspect fit, so that the image isn't zoomed in to fit the width of the display.
    var sheet: Sheet!
    private(set) var sheetView: SheetView? = nil

    var imageSize: CGSize = CGSize.zero
    fileprivate var pointToCenterAfterResize: CGPoint = CGPoint.zero
    fileprivate var scaleToRestoreAfterResize: CGFloat = 1.0
    var maxScaleFromMinScale: CGFloat = 10.0
    
    var zoomDelegate: SheetScrollViewDelegate?
    
    override open var frame: CGRect {
        willSet {
            if frame.equalTo(newValue) == false && newValue.equalTo(CGRect.zero) == false && imageSize.equalTo(CGSize.zero) == false {
                prepareToResize()
            }
        }
        
        didSet {
            if frame.equalTo(oldValue) == false && frame.equalTo(CGRect.zero) == false && imageSize.equalTo(CGSize.zero) == false {
                recoverFromResizing()
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        initialize()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        initialize()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    fileprivate func initialize() {
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        bouncesZoom = true
        decelerationRate = UIScrollViewDecelerationRateFast
        delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(SheetScrollView.changeOrientationNotification), name: Notification.Name.UIDeviceOrientationDidChange, object: nil)
    }
    
    public func adjustFrameToCenter() {
        
        guard let unwrappedZoomView = sheetView else {
            return
        }
        
        var frameToCenter = unwrappedZoomView.frame
        
        // center horizontally
        if frameToCenter.size.width < bounds.width {
            frameToCenter.origin.x = (bounds.width - frameToCenter.size.width) / 2
        }
        else {
            frameToCenter.origin.x = 0
        }
        
        // center vertically
        if frameToCenter.size.height < bounds.height {
            frameToCenter.origin.y = (bounds.height - frameToCenter.size.height) / 2
        }
        else {
            frameToCenter.origin.y = 0
        }
        
        unwrappedZoomView.frame = frameToCenter
    }
    
    fileprivate func prepareToResize() {
        let boundsCenter = CGPoint(x: bounds.midX, y: bounds.midY)
        pointToCenterAfterResize = convert(boundsCenter, to: sheetView)
        
        scaleToRestoreAfterResize = zoomScale
        
        // If we're at the minimum zoom scale, preserve that by returning 0, which will be converted to the minimum
        // allowable scale when the scale is restored.
        if scaleToRestoreAfterResize <= minimumZoomScale + CGFloat(Float.ulpOfOne) {
            scaleToRestoreAfterResize = 0
        }
    }
    
    fileprivate func recoverFromResizing() {
        setMaxMinZoomScalesForCurrentBounds()
        
        // restore zoom scale, first making sure it is within the allowable range.
        let maxZoomScale = max(minimumZoomScale, scaleToRestoreAfterResize)
        zoomScale = min(maximumZoomScale, maxZoomScale)
        
        // restore center point, first making sure it is within the allowable range.
        
        // convert our desired center point back to our own coordinate space
        let boundsCenter = convert(pointToCenterAfterResize, to: sheetView)
        
        // calculate the content offset that would yield that center point
        var offset = CGPoint(x: boundsCenter.x - bounds.size.width/2.0, y: boundsCenter.y - bounds.size.height/2.0)
        
        // restore offset, adjusted to be within the allowable range
        let maxOffset = maximumContentOffset()
        let minOffset = minimumContentOffset()
        
        var realMaxOffset = min(maxOffset.x, offset.x)
        offset.x = max(minOffset.x, realMaxOffset)
        
        realMaxOffset = min(maxOffset.y, offset.y)
        offset.y = max(minOffset.y, realMaxOffset)
        
        contentOffset = offset
    }
    
    fileprivate func maximumContentOffset() -> CGPoint {
        return CGPoint(x: contentSize.width - bounds.width,y:contentSize.height - bounds.height)
    }
    
    fileprivate func minimumContentOffset() -> CGPoint {
        return CGPoint.zero
    }

    // MARK: - Display sheet
    
    func display(sheet: Sheet) {

        if let sheetView = sheetView {
            sheetView.removeFromSuperview()
        }
        
        sheetView = SheetView(frame: CGRect(origin: CGPoint.zero, size: sheet.image.size))
        sheetView!.sheet = sheet
        sheetView!.isUserInteractionEnabled = true
        addSubview(sheetView!)
        sheetView!.shapeView.delegate = self
        configureImageForSize(sheet.image.size)
    }
    
    fileprivate func configureImageForSize(_ size: CGSize) {
        imageSize = size
        contentSize = imageSize
        setMaxMinZoomScalesForCurrentBounds()
        zoomScale = minimumZoomScale
        contentOffset = CGPoint.zero
    }
    
    fileprivate func setMaxMinZoomScalesForCurrentBounds() {
        // calculate min/max zoomscale
        let xScale = bounds.width / imageSize.width    // the scale needed to perfectly fit the image width-wise
        let yScale = bounds.height / imageSize.height   // the scale needed to perfectly fit the image height-wise
        
        // fill width if the image and phone are both portrait or both landscape; otherwise take smaller scale
        let imagePortrait = imageSize.height > imageSize.width
        let phonePortrait = bounds.height >= bounds.width
        var minScale = (imagePortrait == phonePortrait && self.landscapeAspectFill) ? xScale : min(xScale, yScale)
        
        let maxScale = maxScaleFromMinScale*minScale
        
        // don't let minScale exceed maxScale. (If the image is smaller than the screen, we don't want to force it to be zoomed.)
        if minScale > maxScale {
            minScale = maxScale
        }
        
        maximumZoomScale = maxScale
        minimumZoomScale = minScale * 0.999 // the multiply factor to prevent user cannot scroll page while they use this control in UIPageViewController
    }
    
    // MARK: - Gesture
    
    @objc func doubleTapGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {
        // zoom out if it bigger than middle scale point. Else, zoom in
        if zoomScale >= maximumZoomScale / 2.0 {
            setZoomScale(minimumZoomScale, animated: true)
        }
        else {
            let center = gestureRecognizer.location(in: gestureRecognizer.view)
            let zoomRect = zoomRectForScale(SheetScrollView.kZoomInFactorFromMinWhenDoubleTap * minimumZoomScale, center: center)
            zoom(to: zoomRect, animated: true)
        }
    }
    
    fileprivate func zoomRectForScale(_ scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        
        // the zoom rect is in the content view's coordinates.
        // at a zoom scale of 1.0, it would be the size of the imageScrollView's bounds.
        // as the zoom scale decreases, so more content is visible, the size of the rect grows.
        zoomRect.size.height = frame.size.height / scale
        zoomRect.size.width  = frame.size.width  / scale
        
        // choose an origin so as to get the right center.
        zoomRect.origin.x    = center.x - (zoomRect.size.width  / 2.0)
        zoomRect.origin.y    = center.y - (zoomRect.size.height / 2.0)
        
        return zoomRect
    }
    
    open func refresh() {
        if let sheet = self.sheet {
            display(sheet: sheet)
        }
    }
    
    // MARK: - Actions
    
    @objc func changeOrientationNotification() {
        configureImageForSize(imageSize)
    }
}

extension SheetScrollView: UIScrollViewDelegate{
    
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return sheetView
    }
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        adjustFrameToCenter()
    }
    
    public func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        if let delegate = zoomDelegate {
            delegate.didBeginZoom(scrollView: self)
        }
    }
    
    public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        if let delegate = zoomDelegate {
            delegate.didEndZoom(scrollView: self)
        }
    }
}

extension SheetScrollView: ShapeOverLayDelegate {
    func needsFirstResponder(needsFirstResponder: Bool) {
        self.isScrollEnabled = !needsFirstResponder
    }
    
    func drawCancelled() {
        if let delegate = zoomDelegate {
            delegate.didBeginZoom(scrollView: self)
        }
    }
    
    func shapeCreated(_ shape: Shape) {
        if let sheet = self.sheet {
            if let fbshape = shape.fbShape() {
                fbshape.save({ (ref, error) in
                    if let error = error {
                        print(error.localizedDescription)
                    }
                    else {
                        sheet.shapeIds.insert(fbshape.id)
                        shape.fbshape = fbshape
                    }
                })
            }
        }
    }
    
    func shapeDeleted(_ shape: Shape) {
        if let sheet = self.sheet {
            if let fbshape = shape.fbshape {
                sheet.shapeIds.remove(fbshape.id)
                fbshape.remove()
                shape.fbshape = nil
            }
        }
    }
    
    func focused() {
        if let delegate = zoomDelegate {
            delegate.hideShapeBar()
        }
    }
}



