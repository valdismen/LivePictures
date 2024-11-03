//
//  CanvasView.swift
//  LivePictures
//
//  Created by Владислав Матковский on 29.10.2024.
//

import UIKit

final class CanvasView: UIView {
    
    private enum TouchState {
        case idle
        case move(touch: UITouch, location: CGPoint)
        case transform(t1: UITouch, l1: CGPoint, t2: UITouch, l2: CGPoint)
    }
    
    private var touchState: TouchState = .idle

    private var offsetPosition: CGPoint = .zero
    private var scale: CGFloat = 1 {
        didSet {
            contentView.transform = .init(scaleX: scale, y: scale)
        }
    }
    
    private var moveOffsetPosition: CGPoint?
    private var moveScale: CGFloat?
    
    private let contentView = UIView()
    
    private let imageView = {
        let view = UIImageView(image: UIImage(named: "canvas"))
        view.contentMode = .center
        return view
    }()
    
    private let previousImageView = {
        let view = UIImageView()
        view.alpha = 0.5
        return view
    }()
    
    private let drawingView = DrawingView()
    
    private var toolControllingView: UIView?
    
    var onFreeTap: (() -> Void)?
    
    init() {
        super.init(frame: .zero)
        
        layer.masksToBounds = true
        contentView.layer.cornerRadius = 20
        contentView.layer.masksToBounds = true
        contentView.transform = .init(scaleX: scale, y: scale)
        
        addSubview(contentView)
        
        contentView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(contentView.makeEdgeConstraints(to: imageView))
        
        contentView.addSubview(previousImageView)
        previousImageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(contentView.makeEdgeConstraints(to: previousImageView))
        
        contentView.addSubview(drawingView)
        drawingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(contentView.makeEdgeConstraints(to: drawingView))
        
        drawingView.isMultipleTouchEnabled = true
    }
    
    required init?(coder: NSCoder) { nil }
    
    func resetScale() {
        scale = 1
        offsetPosition = .zero
        setNeedsLayout()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.frame = .init(origin: .init(
            x: offsetPosition.x, y: offsetPosition.y
        ), size: .init(
            width: bounds.width * scale,
            height: bounds.height * scale
        ))
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)

        guard toolControllingView == nil else {
            touchState = .idle
            return
        }

        onFreeTap?()
        
        switch touchState {
        case .idle where touches.count == 1:
            setupMove(with: touches.first!, view: self)
        case .idle where touches.count > 1:
            let touches = Array(touches)
            setupTransform(with: touches[0], touch2: touches[1], view: self)
        case let .move(firstTouch, _):
            setupTransform(with: firstTouch, touch2: touches.first!, view: self)
        default: break
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        
        switch touchState {
        case let .move(touch, moveTouchPoint):
            guard let moveOffsetPosition else { return }
            
            let location = touch.location(in: self)
            
            let width = bounds.width * scale
            let height = bounds.height * scale
            
            let minX = -width + bounds.width / 2
            let minY = -height + bounds.height / 2
            let maxX = bounds.width / 2
            let maxY = bounds.height / 2
            
            offsetPosition = .init(
                x: min(max(moveOffsetPosition.x + location.x - moveTouchPoint.x, minX), maxX),
                y: min(max(moveOffsetPosition.y + location.y - moveTouchPoint.y, minY), maxY)
            )
            
            
            setNeedsLayout()
        case let .transform(transformTouch1, transformTouchPoint1, transformTouch2, transformTouchPoint2):
            guard let moveOffsetPosition, let moveScale else { return }
            
            let location1 = transformTouch1.location(in: self)
            let location2 = transformTouch2.location(in: self)
            
            let center1 = CGPoint(
                x: (transformTouchPoint1.x + transformTouchPoint2.x) / 2,
                y: (transformTouchPoint1.y + transformTouchPoint2.y) / 2
            )
            
            let center2 = CGPoint(
                x: (location1.x + location2.x) / 2,
                y: (location1.y + location2.y) / 2
            )
            
            let touchPoint1Vector = CGPoint(
                x: transformTouchPoint1.x - center1.x,
                y: transformTouchPoint1.y - center1.y
            )
            
            let location1Vector = CGPoint(
                x: location1.x - center2.x,
                y: location1.y - center2.y
            )
            
            let scale = sqrt(
                location1Vector.x * location1Vector.x + location1Vector.y * location1Vector.y
            ) / sqrt(
                touchPoint1Vector.x * touchPoint1Vector.x + touchPoint1Vector.y * touchPoint1Vector.y
            )
            
            let newScale = min(max(moveScale * scale, 0.5), 100)
            
            let offsetPositionVector = CGPoint(
                x: moveOffsetPosition.x - center1.x,
                y: moveOffsetPosition.y - center1.y
            )
            
            let width = bounds.width * newScale
            let height = bounds.height * newScale
            
            let minX = -width + bounds.width / 2
            let minY = -height + bounds.height / 2
            let maxX = bounds.width / 2
            let maxY = bounds.height / 2
            
            offsetPosition = .init(
                x: min(max(offsetPositionVector.x * newScale / moveScale + center2.x, minX), maxX),
                y: min(max(offsetPositionVector.y * newScale / moveScale + center2.y, minY), maxY)
            )
            
            self.scale = newScale
            
            setNeedsLayout()
        default: break
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        switch touchState {
        case let .move(touch, _):
            if touches.contains(touch) {
                touchState = .idle
            }
        case let .transform(t1, _, t2, _):
            if touches.contains(t1) && touches.contains(t2) {
                touchState = .idle
            } else if touches.contains(t1) {
                setupMove(with: t2, view: self)
            } else if touches.contains(t2) {
                setupMove(with: t1, view: self)
            }
        case .idle: break
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        touchState = .idle
    }
    
    func setPreviousImage(_ image: UIImage?) {
        previousImageView.image = image
    }
    
    func setPictureModel(_ pictureModel: PictureModel) {
        drawingView.image = pictureModel.getImage()
    }
    
    func setDrawingTool(_ tool: DrawingTool?) {
        toolControllingView?.removeFromSuperview()
        toolControllingView = tool?.toolControllingView
        
        if let toolControllingView {
            addSubview(toolControllingView)
            toolControllingView.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate(makeEdgeConstraints(to: toolControllingView))
        }
        
        drawingView.tool = tool
        drawingView.setNeedsDisplay()
    }
    
    private func setupMove(with touch: UITouch, view: UIView) {
        touchState = .move(touch: touch, location: touch.location(in: view))
        moveOffsetPosition = offsetPosition
    }
    
    private func setupTransform(with touch1: UITouch, touch2: UITouch, view: UIView) {
        touchState = .transform(
            t1: touch1,
            l1: touch1.location(in: view),
            t2: touch2,
            l2: touch2.location(in: view)
        )

        moveOffsetPosition = offsetPosition
        moveScale = scale
    }
}
