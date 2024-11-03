//
//  LineDrawingTool.swift
//  LivePictures
//
//  Created by Владислав Матковский on 03.11.2024.
//

import UIKit

final class LineDrawingTool: DrawingTool {
    
    private let path = UIBezierPath()
    private let color: () -> UIColor
    private let lineWidth: CGFloat
    
    private var drawTouch: UITouch?
    private var startPoint: CGPoint?

    var partCompletionHandler: ((PictureModel.DrawAction) -> Void)?
    
    init(color: @escaping () -> UIColor, lineWidth: CGFloat) {
        self.color = color
        self.lineWidth = lineWidth
    }
    
    func touchesBegan(_ touches: Set<UITouch>, view: UIView) {
        guard drawTouch == nil else {
            drawTouch = nil
            path.removeAllPoints()
            startPoint = nil
            return
        }
        
        guard let touch = touches.first else { return }
        drawTouch = touch
        
        let location = touch.location(in: view)
        
        path.move(to: location)
        path.addLine(to: location)
        startPoint = location
    }
    
    func touchesMoved(_ touches: Set<UITouch>, view: UIView) {
        guard let touch = drawTouch else { return }
        let location = touch.location(in: view)
        
        path.removeAllPoints()
        path.move(to: startPoint ?? .zero)
        path.addLine(to: location)
    }
    
    func touchesEnded(_ touches: Set<UITouch>, view: UIView) {
        guard let drawTouch else { return }

        partCompletionHandler?(.pencil(
            .init(
                width: lineWidth,
                points: [startPoint ?? .zero, drawTouch.location(in: view)]
            ),
            color()
        ))
        
        self.drawTouch = nil

        path.removeAllPoints()
        startPoint = nil
    }
    
    func touchesCancelled(_ touches: Set<UITouch>, view: UIView) {
        drawTouch = nil
    }
    
    func draw() {
        color().setStroke()
        path.lineWidth = lineWidth
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        path.stroke()
    }
}
