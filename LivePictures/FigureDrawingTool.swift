//
//  FigureDrawingTool.swift
//  LivePictures
//
//  Created by Владислав Матковский on 02.11.2024.
//

import UIKit

protocol FigureProtocol {
    func draw(center: CGPoint, right: CGPoint, color: UIColor, lineWidth: CGFloat)
    func action(center: CGPoint, right: CGPoint, color: UIColor, lineWidth: CGFloat) -> PictureModel.DrawAction
}

struct PointsFigure: FigureProtocol {

    static let square = PointsFigure(points: [
        .init(x: -1, y: -1),
        .init(x: -1, y: 1),
        .init(x: 1, y: 1),
        .init(x: 1, y: -1),
        .init(x: -1, y: -1)
    ])
    
    static let triangle = PointsFigure(points: [
        .init(x: 1, y: 0),
        .init(x: -0.5, y: sqrt(3) / 2),
        .init(x: -0.5, y: -sqrt(3) / 2),
        .init(x: 1, y: 0),
    ])
    
    static let arrow = PointsFigure(points: [
        .init(x: -1, y: 0),
        .init(x: 1, y: 0),
        .init(x: 0.2, y: 0.8),
        .init(x: 1, y: 0),
        .init(x: 0.2, y: -0.8),
    ])
    
    private let points: [CGPoint]
    
    init(points: [CGPoint]) {
        self.points = points
    }
    
    func draw(center: CGPoint, right: CGPoint, color: UIColor, lineWidth: CGFloat) {
        color.setStroke()

        let path = UIBezierPath()
        path.lineWidth = lineWidth
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        
        path.move(to: transform(points.first!, center: center, right: right))
        points.dropFirst().forEach {
            path.addLine(to: transform($0, center: center, right: right))
        }
        
        path.stroke()
    }
    
    func action(center: CGPoint, right: CGPoint, color: UIColor, lineWidth: CGFloat) -> PictureModel.DrawAction {
        .pencil(.init(
            width: lineWidth,
            points: points.map { self.transform($0, center: center, right: right) }
        ), color)
    }
    
    private func transform(_ point: CGPoint, center: CGPoint, right: CGPoint) -> CGPoint {
        let centerRightVector = CGPoint(
            x: right.x - center.x,
            y: right.y - center.y
        )
        
        return .init(
            x: centerRightVector.x * point.x - centerRightVector.y * point.y + center.x,
            y: centerRightVector.y * point.x + centerRightVector.x * point.y + center.y
        )
    }
}

struct CircleFigure: FigureProtocol {

    func draw(center: CGPoint, right: CGPoint, color: UIColor, lineWidth: CGFloat) {
        color.setStroke()

        let path = UIBezierPath()
        path.lineWidth = lineWidth
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        
        let centerRightVector = CGPoint(
            x: right.x - center.x,
            y: right.y - center.y
        )
        
        path.addArc(
            withCenter: center,
            radius: sqrt(centerRightVector.x * centerRightVector.x + centerRightVector.y * centerRightVector.y),
            startAngle: 0,
            endAngle: 2 * .pi,
            clockwise: true
        )
        
        path.stroke()
    }
    
    func action(center: CGPoint, right: CGPoint, color: UIColor, lineWidth: CGFloat) -> PictureModel.DrawAction {
        let centerRightVector = CGPoint(
            x: right.x - center.x,
            y: right.y - center.y
        )
        
        return .circle(.init(
            center: center,
            radius: sqrt(centerRightVector.x * centerRightVector.x + centerRightVector.y * centerRightVector.y),
            color: color,
            width: lineWidth
        ))
    }
}

final class FigureDrawingTool: DrawingTool {
    
    private let color: () -> UIColor
    private let lineWidth: CGFloat
    private let figure: FigureProtocol
    
    private enum TouchState {
        case idle
        case draw(touch: UITouch)
        case move(touch: UITouch, location: CGPoint)
        case transform(t1: UITouch, l1: CGPoint, t2: UITouch, l2: CGPoint)
    }
    
    private var touchState: TouchState = .idle
    
    private var figureCenterPosition: CGPoint?
    private var figureRightPoint: CGPoint?
    private var figureColor: UIColor?
    
    private var isFigureDrawn = false {
        didSet {
            controllingView.configure(
                cancelEnabled: isFigureDrawn,
                doneEnabled: isFigureDrawn
            )
        }
    }
    
    private var moveFigureCenterPosition: CGPoint?
    private var moveFigureRightPoint: CGPoint?

    var partCompletionHandler: ((PictureModel.DrawAction) -> Void)?
    var onRedrawNeeded: (() -> Void)?
    
    private lazy var controllingView = {
        let view = ControllingView()
        view.configure(cancelEnabled: false, doneEnabled: false)
        
        view.onCancel = { [weak self, weak view] in
            self?.touchState = .idle
            self?.isFigureDrawn = false
            self?.figureCenterPosition = nil
            self?.onRedrawNeeded?()
        }
        
        view.onDone = { [weak self] in
            guard let self else { return }
            
            touchState = .idle
            isFigureDrawn = false
            
            partCompletionHandler?(figure.action(
                center: figureCenterPosition ?? .zero,
                right: figureRightPoint ?? .zero,
                color: figureColor ?? .black,
                lineWidth: lineWidth
            ))

            figureCenterPosition = nil
        }
        
        return view
    }()
    
    var toolControllingView: UIView? { controllingView }
    
    init(figure: FigureProtocol, color: @escaping () -> UIColor, lineWidth: CGFloat) {
        self.figure = figure
        self.color = color
        self.lineWidth = lineWidth
    }
    
    func touchesBegan(_ touches: Set<UITouch>, view: UIView) {
        switch touchState {
        case .idle where !isFigureDrawn:
            let touch = touches.first!
            touchState = .draw(touch: touch)
            figureCenterPosition = touch.location(in: view)
            figureRightPoint = .init(x: (figureCenterPosition?.x ?? 0) + 10, y: figureCenterPosition?.y ?? 0)
            figureColor = color()
        case .idle where touches.count == 1:
            setupMove(with: touches.first!, view: view)
        case .idle where touches.count > 1:
            let touches = Array(touches)
            setupTransform(with: touches[0], touch2: touches[1], view: view)
        case let .move(firstTouch, _):
            setupTransform(with: firstTouch, touch2: touches.first!, view: view)
        default: break
        }
    }
    
    func touchesMoved(_ touches: Set<UITouch>, view: UIView) {
        switch touchState {
        case let .draw(touch):
            figureRightPoint = touch.location(in: view)
        case let .move(touch, moveTouchPoint):
            guard let moveFigureRightPoint, let moveFigureCenterPosition else { return }

            let location = touch.location(in: view)
            
            self.figureRightPoint = .init(
                x: moveFigureRightPoint.x + location.x - moveTouchPoint.x,
                y: moveFigureRightPoint.y + location.y - moveTouchPoint.y
            )

            self.figureCenterPosition = .init(
                x: moveFigureCenterPosition.x + location.x - moveTouchPoint.x,
                y: moveFigureCenterPosition.y + location.y - moveTouchPoint.y
            )
        case let .transform(transformTouch1, transformTouchPoint1, transformTouch2, transformTouchPoint2):
            guard let moveFigureRightPoint, let moveFigureCenterPosition else { return }
            
            let location1 = transformTouch1.location(in: view)
            let location2 = transformTouch2.location(in: view)
            
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
            
            let rotationAngle = atan2(
                location1Vector.y, location1Vector.x
            ) - atan2(
                touchPoint1Vector.y, touchPoint1Vector.x
            )
            
            let scale = sqrt(
                location1Vector.x * location1Vector.x + location1Vector.y * location1Vector.y
            ) / sqrt(
                touchPoint1Vector.x * touchPoint1Vector.x + touchPoint1Vector.y * touchPoint1Vector.y
            )
            
            let a = cos(rotationAngle) * scale
            let b = -sin(rotationAngle) * scale
            let c = -b
            let d = a
            
            let figureCenterPositionVector = CGPoint(
                x: moveFigureCenterPosition.x - center1.x,
                y: moveFigureCenterPosition.y - center1.y
            )
            
            let figureRightPointVector = CGPoint(
                x: moveFigureRightPoint.x - center1.x,
                y: moveFigureRightPoint.y - center1.y
            )
            
            figureCenterPosition = .init(
                x: figureCenterPositionVector.x * a + figureCenterPositionVector.y * b + center2.x,
                y: figureCenterPositionVector.x * c + figureCenterPositionVector.y * d + center2.y
            )
            
            figureRightPoint = .init(
                x: figureRightPointVector.x * a + figureRightPointVector.y * b + center2.x,
                y: figureRightPointVector.x * c + figureRightPointVector.y * d + center2.y
            )
        default: break
        }
    }
    
    func touchesEnded(_ touches: Set<UITouch>, view: UIView) {
        switch touchState {
        case let .draw(touch):
            if touches.contains(touch) {
                touchState = .idle
                isFigureDrawn = true
            }
        case let .move(touch, _):
            if touches.contains(touch) {
                touchState = .idle
            }
        case let .transform(t1, _, t2, _):
            if touches.contains(t1) && touches.contains(t2) {
                touchState = .idle
            } else if touches.contains(t1) {
                setupMove(with: t2, view: view)
            } else if touches.contains(t2) {
                setupMove(with: t1, view: view)
            }
        case .idle: break
        }
    }
    
    func touchesCancelled(_ touches: Set<UITouch>, view: UIView) {
        touchState = .idle
    }
    
    func draw() {
        guard let figureCenterPosition else { return }
        
        figure.draw(
            center: figureCenterPosition,
            right: figureRightPoint ?? .zero,
            color: figureColor ?? .black,
            lineWidth: lineWidth
        )
    }
    
    private func setupMove(with touch: UITouch, view: UIView) {
        touchState = .move(touch: touch, location: touch.location(in: view))
        moveFigureCenterPosition = figureCenterPosition
        moveFigureRightPoint = figureRightPoint
    }
    
    private func setupTransform(with touch1: UITouch, touch2: UITouch, view: UIView) {
        touchState = .transform(
            t1: touch1,
            l1: touch1.location(in: view),
            t2: touch2,
            l2: touch2.location(in: view)
        )

        moveFigureCenterPosition = figureCenterPosition
        moveFigureRightPoint = figureRightPoint
    }
}

private final class ControllingView: UIView {
    
    private lazy var containerView = {
        let view = OverlayView()
        view.alpha = 1
        
        view.addSubview(actionsView)
        actionsView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(view.makeEdgeConstraints(to: actionsView, insets: .init(
            top: 8, left: 16, bottom: 8, right: 16
        )))
        
        return view
    }()
    
    private let actionsView = ActionsGroupView()
    
    var onCancel: (() -> Void)?
    var onDone: (() -> Void)?
    
    private lazy var cancelActionView = {
        let view = BasicActionView()
        view.icon = UIImage(systemName: "xmark.square")
        
        view.tapAction = { [weak self] in
            self?.onCancel?()
        }
        
        return view
    }()
    
    private lazy var doneActionView = {
        let view = BasicActionView()
        view.icon = UIImage(systemName: "checkmark.square")
        
        view.tapAction = { [weak self] in
            self?.onDone?()
        }
        
        return view
    }()
    
    init() {
        super.init(frame: .zero)
        
        addSubview(containerView)
        containerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor),
            containerView.topAnchor.constraint(equalTo: topAnchor),
        ])
        
        actionsView.setActionsViews([
            cancelActionView,
            doneActionView,
        ])
    }
    
    required init?(coder: NSCoder) { nil }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        return view == self ? nil : view
    }
    
    func configure(cancelEnabled: Bool, doneEnabled: Bool) {
        cancelActionView.isEnabled = cancelEnabled
        doneActionView.isEnabled = doneEnabled
    }
}
