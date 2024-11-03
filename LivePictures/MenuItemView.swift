//
//  MenuItemView.swift
//  LivePictures
//
//  Created by Владислав Матковский on 01.11.2024.
//

import UIKit

final class MenuItemView: UIView, Activatable {

    var icon: UIImage? {
        get { imageView.image }
        set { imageView.image = newValue?.withRenderingMode(.alwaysTemplate) }
    }
    
    var title: String? {
        get { label.text }
        set { label.text = newValue }
    }
    
    var isEnabled: Bool = true {
        didSet {
            guard isEnabled != oldValue else { return }
            
            let color: Color
            
            if isEnabled {
                color = isActive ? Color.green : Color.actionDefault
            } else {
                color = Color.gray
            }
            
            updateColor(color)
        }
    }
    
    var isActive: Bool = false {
        didSet {
            guard isEnabled else { return }
            updateColor(isActive ? Color.green : Color.actionDefault)
        }
    }
    
    var tapAction: (() -> Void)?
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = Color.actionDefault.color(in: self)
        
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 32),
            imageView.heightAnchor.constraint(equalToConstant: 32),
        ])
        
        return imageView
    }()

    private lazy var label: UILabel = {
        let label = UILabel()
        label.textColor = Color.actionDefault.color(in: self)
        label.font = .systemFont(ofSize: 16)
        return label
    }()
    
    private var currentColorToken: Color = .actionDefault
    
    init() {
        super.init(frame: .zero)
        
        [imageView, label].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.topAnchor.constraint(equalTo: topAnchor),
            imageView.bottomAnchor.constraint(equalTo: bottomAnchor),
            
            label.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 16),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
        ])
    }
    
    required init?(coder: NSCoder) { nil }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        guard isEnabled else { return }
        updateColor(Color.green)
        tapAction?()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        guard isEnabled, !isActive else { return }
        updateColor(Color.actionDefault)
    }
    
    private func updateColor(_ colorToken: Color, animated: Bool = true) {
        currentColorToken = colorToken
        
        if animated {
            UIView.transition(with: label, duration: 0.2, options: .transitionCrossDissolve) {
                self.label.textColor = colorToken.color(in: self)
            }
            
            UIView.animate(withDuration: 0.2) {
                self.imageView.tintColor = colorToken.color(in: self)
            }
        } else {
            label.textColor = colorToken.color(in: self)
            imageView.tintColor = colorToken.color(in: self)
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateColor(currentColorToken, animated: false)
    }
}
