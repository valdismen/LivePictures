//
//  EraserDrawingTool.swift
//  LivePictures
//
//  Created by Владислав Матковский on 30.10.2024.
//

import UIKit

final class EraserDrawingTool: DrawingTool {
    
    private let path = UIBezierPath()
    private var lineWidth: CGFloat
    
    private var drawTouch: UITouch?
    private var points: [CGPoint] = []

    var partCompletionHandler: ((PictureModel.DrawAction) -> Void)?
    
    private lazy var controllingView = {
        let view = ControllingView()
        
        view.configure(lineWidth: lineWidth)
        
        view.onLineWidthUpdated = { [weak self] lineWidth in
            self?.lineWidth = lineWidth
        }
        
        return view
    }()
    
    var toolControllingView: UIView? { controllingView }
    
    init(lineWidth: CGFloat) {
        self.lineWidth = lineWidth
    }
    
    func touchesBegan(_ touches: Set<UITouch>, view: UIView) {
        guard drawTouch == nil else {
            drawTouch = nil
            path.removeAllPoints()
            points = []
            return
        }
        
        guard let touch = touches.first else { return }
        drawTouch = touch
        
        let location = touch.location(in: view)
        
        path.move(to: location)
        path.addLine(to: location)
        points.append(location)
    }
    
    func touchesMoved(_ touches: Set<UITouch>, view: UIView) {
        guard let touch = drawTouch else { return }
        let location = touch.location(in: view)
        
        path.addLine(to: location)
        points.append(location)
    }
    
    func touchesEnded(_ touches: Set<UITouch>, view: UIView) {
        guard drawTouch != nil else { return }
        drawTouch = nil
        
        partCompletionHandler?(.erase(
            .init(width: lineWidth, points: points)
        ))

        path.removeAllPoints()
        points = []
    }
    
    func touchesCancelled(_ touches: Set<UITouch>, view: UIView) {
        drawTouch = nil
    }
    
    func draw() {
        path.lineWidth = lineWidth
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        path.stroke(with: .clear, alpha: 1)
    }
}

private final class ControllingView: UIView {
    
    private lazy var lineWidthSelectionView = {
        let view = LineWidthSelectionView()
        
        view.onValueUpdated = { [weak self] value in
            self?.onLineWidthUpdated?(value)
        }
        
        return view
    }()
    
    var onLineWidthUpdated: ((CGFloat) -> Void)?
    
    init() {
        super.init(frame: .zero)
        
        addSubview(lineWidthSelectionView)
        lineWidthSelectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            lineWidthSelectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            lineWidthSelectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            lineWidthSelectionView.bottomAnchor.constraint(equalTo: bottomAnchor),
        ])
    }
    
    required init?(coder: NSCoder) { nil }
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let view = super.hitTest(point, with: event)
        return view == self ? nil : view
    }
    
    func configure(lineWidth: CGFloat) {
        lineWidthSelectionView.value = lineWidth
    }
}
