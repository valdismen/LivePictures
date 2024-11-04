//
//  ColorSelectionView.swift
//  LivePictures
//
//  Created by Владислав Матковский on 02.11.2024.
//

import UIKit

final class ColorSelectionView: UIView {

    private let backgroundView = OverlayView()
    
    private lazy var redColorSlider = {
        let slider = ColorSliderView()
        slider.setColors(left: .black, right: .red)

        slider.onPositionChange = { [weak self] _ in
            self?.handlePositionChange()
        }

        return slider
    }()
    
    private lazy var greenColorSlider = {
        let slider = ColorSliderView()
        slider.setColors(left: .black, right: .green)
        
        slider.onPositionChange = { [weak self] _ in
            self?.handlePositionChange()
        }

        return slider
    }()
    
    private lazy var blueColorSlider = {
        let slider = ColorSliderView()
        slider.setColors(left: .black, right: .blue)
        
        slider.onPositionChange = { [weak self] _ in
            self?.handlePositionChange()
        }

        return slider
    }()
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            redColorSlider,
            greenColorSlider,
            blueColorSlider
        ])
        
        stackView.distribution = .fill
        stackView.axis = .vertical
        stackView.spacing = 16
        return stackView
    }()
    
    var color: UIColor = .black {
        didSet {
            let color = CIColor(cgColor: color.cgColor)
            
            redColorSlider.setColors(
                left: UIColor(red: 0, green: color.green, blue: color.blue, alpha: 1),
                right: UIColor(red: 1, green: color.green, blue: color.blue, alpha: 1)
            )
            
            redColorSlider.position = color.red
            
            greenColorSlider.setColors(
                left: UIColor(red: color.red, green: 0, blue: color.blue, alpha: 1),
                right: UIColor(red: color.red, green: 1, blue: color.blue, alpha: 1)
            )
            
            greenColorSlider.position = color.green
            
            blueColorSlider.setColors(
                left: UIColor(red: color.red, green: color.green, blue: 0, alpha: 1),
                right: UIColor(red: color.red, green: color.green, blue: 1, alpha: 1)
            )
            
            blueColorSlider.position = color.blue
        }
    }
    
    var onColorUpdated: ((UIColor) -> Void)?
    
    init() {
        super.init(frame: .zero)
        
        addSubview(backgroundView)
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(makeEdgeConstraints(to: backgroundView))
        
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(makeEdgeConstraints(to: stackView, insets: .init(
            top: 16, left: 16, bottom: 16, right: 16
        )))
    }
    
    required init?(coder: NSCoder) { nil }
    
    private func handlePositionChange() {
        color = UIColor(
            red: redColorSlider.position,
            green: greenColorSlider.position,
            blue: blueColorSlider.position,
            alpha: 1
        )
        
        onColorUpdated?(color)
    }
}

private final class ColorSliderView: UIView {
    
    private let cornerRadius: CGFloat = 16
    
    private let leftColorLayer = CALayer()
    private let rightColorLayer = CALayer()
    private let gradientLayer = {
        let layer = CAGradientLayer()
        layer.startPoint = .init(x: 0, y: 0)
        layer.endPoint = .init(x: 1, y: 0)
        return layer
    }()
    
    private lazy var controlView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = cornerRadius
        view.layer.borderColor = Color.actionLight.color(in: self).withAlphaComponent(0.5).cgColor
        view.layer.borderWidth = 1.5
        return view
    }()
    
    var position: CGFloat = 0 {
        didSet {
            let normalizedPosition = min(max(0, position), 1)
            if position != normalizedPosition {
                position = normalizedPosition
            }
            
            setNeedsLayout()
        }
    }
    
    var onPositionChange: ((CGFloat) -> Void)?
    
    init() {
        super.init(frame: .zero)
        
        layer.addSublayer(leftColorLayer)
        layer.addSublayer(rightColorLayer)
        layer.addSublayer(gradientLayer)
        
        addSubview(controlView)
        
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 32)
        ])
        
        layer.cornerRadius = cornerRadius
        layer.masksToBounds = true
    }
    
    required init?(coder: NSCoder) { nil }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        leftColorLayer.frame = .init(origin: .zero, size: .init(width: cornerRadius, height: bounds.height))
        rightColorLayer.frame = .init(
            origin: .init(x: bounds.width - cornerRadius, y: 0),
            size: .init(width: cornerRadius, height: bounds.height)
        )
        
        gradientLayer.frame = .init(
            x: cornerRadius, y: 0,
            width: bounds.width - cornerRadius * 2, height: bounds.height
        )

        updateControlLayer()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        position = (touch.location(in: self).x - cornerRadius) / (bounds.width - cornerRadius * 2)
        onPositionChange?(position)
    }
    
    func setColors(left: UIColor, right: UIColor) {
        leftColorLayer.backgroundColor = left.cgColor
        rightColorLayer.backgroundColor = right.cgColor
        gradientLayer.colors = [leftColorLayer.backgroundColor!, rightColorLayer.backgroundColor!]
        updateControlLayer()
    }
    
    func updateControlLayer() {
        controlView.frame = .init(
            x: position * (bounds.width - cornerRadius * 2),
            y: 0,
            width: cornerRadius * 2,
            height: cornerRadius * 2
        )
        
        controlView.layer.backgroundColor = interpolatedColor(
            c1: CIColor(cgColor: leftColorLayer.backgroundColor!),
            c2: CIColor(cgColor: rightColorLayer.backgroundColor!),
            t: position
        )
    }
    
    private func interpolatedColor(c1: CIColor, c2: CIColor, t: CGFloat) -> CGColor {
        UIColor(
            red: c1.red.interpolated(towards: c2.red, amount: Double(t)),
            green: c1.green.interpolated(towards: c2.green, amount: Double(t)),
            blue: c1.blue.interpolated(towards: c2.blue, amount: Double(t)),
            alpha: 1
        ).cgColor
    }
}
