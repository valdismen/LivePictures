//
//  DrawingView.swift
//  LivePictures
//
//  Created by Владислав Матковский on 29.10.2024.
//

import UIKit

protocol DrawingTool: AnyObject {
    var partCompletionHandler: ((PictureModel.DrawAction) -> Void)? { get set }
    var onRedrawNeeded: (() -> Void)? { get set }
    
    var toolControllingView: UIView? { get }

    func touchesBegan(_ touches: Set<UITouch>, view: UIView)
    func touchesMoved(_ touches: Set<UITouch>, view: UIView)
    func touchesEnded(_ touches: Set<UITouch>, view: UIView)
    func touchesCancelled(_ touches: Set<UITouch>, view: UIView)

    func draw()
}

extension DrawingTool {
    func with(partCompletionHandler: @escaping (PictureModel.DrawAction) -> Void) -> Self {
        self.partCompletionHandler = partCompletionHandler
        return self
    }
    
    var toolControllingView: UIView? { nil }
    var onRedrawNeeded: (() -> Void)? {
        get { nil }
        set {}
    }
}

final class DrawingView: UIView {
    
    var image: UIImage? = nil {
        didSet {
            setNeedsDisplay()
        }
    }

    var tool: DrawingTool? {
        didSet {
            let previousCompletionHandler = tool?.partCompletionHandler
            tool?.partCompletionHandler = { [weak self] action in
                previousCompletionHandler?(action)
                self?.drawToImage()
                self?.setNeedsDisplay()
            }
            
            tool?.onRedrawNeeded = { [weak self] in
                self?.setNeedsDisplay()
            }
        }
    }
    
    init() {
        super.init(frame: .zero)
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) { nil }
    
    override func draw(_ rect: CGRect) {
        image?.draw(in: rect)
        tool?.draw()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let tool else {
            super.touchesBegan(touches, with: event)
            return
        }
        
        tool.touchesBegan(touches, view: self)
        setNeedsDisplay()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let tool else {
            super.touchesMoved(touches, with: event)
            return
        }
        
        tool.touchesMoved(touches, view: self)
        setNeedsDisplay()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let tool else {
            super.touchesEnded(touches, with: event)
            return
        }
        
        tool.touchesEnded(touches, view: self)
        setNeedsDisplay()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        tool?.touchesCancelled(touches, view: self)
        setNeedsDisplay()
    }
    
    private func drawToImage() {
        image = UIGraphicsImageRenderer(size: bounds.size).image { _ in
            image?.draw(in: bounds)
            tool?.draw()
        }
    }
}
