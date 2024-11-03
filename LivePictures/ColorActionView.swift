//
//  ColorActionView.swift
//  LivePictures
//
//  Created by Владислав Матковский on 29.10.2024.
//

import UIKit

final class ColorActionView: UIView, Activatable {

    var color: UIColor? {
        get { innerColorView.backgroundColor }
        set {
            if !isActive {
                colorView.backgroundColor = newValue
            }

            innerColorView.backgroundColor = newValue
        }
    }
    
    var isEnabled: Bool = true

    var isActive: Bool = false {
        didSet {
            let color = isActive ? Color.green.color(in: self) : innerColorView.backgroundColor
            
            UIView.animate(withDuration: 0.2) {
                self.colorView.backgroundColor = color
            }
        }
    }
    
    var tapAction: (() -> Void)?
    
    private let colorView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemRed
        view.layer.cornerRadius = 14
        return view
    }()
    
    private let innerColorView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemRed
        view.layer.cornerRadius = 12.5
        return view
    }()

    init() {
        super.init(frame: .zero)
        
        addSubview(colorView)
        colorView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            colorView.widthAnchor.constraint(equalToConstant: 28),
            colorView.heightAnchor.constraint(equalToConstant: 28),
            colorView.centerXAnchor.constraint(equalTo: centerXAnchor),
            colorView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        
        addSubview(innerColorView)
        innerColorView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            innerColorView.widthAnchor.constraint(equalToConstant: 25),
            innerColorView.heightAnchor.constraint(equalToConstant: 25),
            innerColorView.centerXAnchor.constraint(equalTo: centerXAnchor),
            innerColorView.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
        
        NSLayoutConstraint.activate([
            widthAnchor.constraint(equalToConstant: 32),
            heightAnchor.constraint(equalToConstant: 32),
        ])
    }
    
    required init?(coder: NSCoder) { nil }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        guard isEnabled else { return }
        
        UIView.animate(withDuration: 0.2) {
            self.colorView.backgroundColor = Color.green.color(in: self)
        }
        
        tapAction?()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        guard isEnabled, !isActive else { return }
        
        UIView.animate(withDuration: 0.2) {
            self.colorView.backgroundColor = self.innerColorView.backgroundColor
        }
    }
}
