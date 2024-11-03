//
//  LineWidthSelectionView.swift
//  LivePictures
//
//  Created by Владислав Матковский on 03.11.2024.
//

import UIKit

final class LineWidthSelectionView: UIView {
    
    private enum Constants {
        static let minValue: CGFloat = 1
        static let maxValue: CGFloat = 500
    }

    private let backgroundView = OverlayView()
    
    private lazy var iconView: UIImageView = {
        let view = UIImageView()
        
        NSLayoutConstraint.activate([
            view.widthAnchor.constraint(equalToConstant: 32),
            view.heightAnchor.constraint(equalToConstant: 32),
        ])
        
        view.image = UIImage(systemName: "lineweight")
        view.tintColor = Color.actionDefault.color(in: self)
        
        return view
    }()
    
    private lazy var sliderView = {
        let slider = SliderView()

        slider.onPositionChange = { [weak self] position in

            let base: CGFloat = 10
            let constant: CGFloat = log(Constants.maxValue) / log(base)
            let value = pow(base, position * constant)
            
            self?.value = value
            self?.onValueUpdated?(value)
        }

        return slider
    }()
    
    private let textField: UITextField = {
        let textField = UITextField()
        textField.keyboardType = .numberPad
        textField.borderStyle = .roundedRect
        textField.textAlignment = .center
        
        textField.text = "\(Int(Constants.minValue))"
        
        NSLayoutConstraint.activate([
            textField.widthAnchor.constraint(equalToConstant: 48)
        ])
        
        textField.isUserInteractionEnabled = false
        return textField
    }()
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            iconView,
            sliderView,
            textField,
        ])
        
        stackView.distribution = .fill
        stackView.axis = .horizontal
        stackView.spacing = 16
        return stackView
    }()
    
    var onValueUpdated: ((CGFloat) -> Void)?
    
    var value: CGFloat = Constants.minValue {
        didSet {
            let normalizedValue = min(max(Constants.minValue, value), Constants.maxValue)
            if normalizedValue != value {
                value = normalizedValue
            }
            
            let constant: CGFloat = log(Constants.maxValue)
            sliderView.position = log(value) / constant
            textField.text = "\(Int(value.rounded(.toNearestOrEven)))"
        }
    }
    
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
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        iconView.tintColor = Color.actionDefault.color(in: self)
    }
}

private final class SliderView: UIView {
    
    private let cornerRadius: CGFloat = 16
    
    private lazy var controlView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = cornerRadius
        view.backgroundColor = Color.green.color(in: self)
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
        
        addSubview(controlView)
        
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 32)
        ])
        
        backgroundColor = Color.gray.color(in: self)
        layer.cornerRadius = cornerRadius
        layer.masksToBounds = true
    }
    
    required init?(coder: NSCoder) { nil }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateControlView()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        position = (touch.location(in: self).x - cornerRadius) / (bounds.width - cornerRadius * 2)
        onPositionChange?(position)
    }
    
    private func updateControlView() {
        controlView.frame = .init(
            x: position * (bounds.width - cornerRadius * 2),
            y: 0,
            width: cornerRadius * 2,
            height: cornerRadius * 2
        )
    }
}
