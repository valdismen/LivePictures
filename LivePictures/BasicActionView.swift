//
//  BasicActionView.swift
//  LivePictures
//
//  Created by Владислав Матковский on 29.10.2024.
//

import UIKit

protocol Activatable: AnyObject {
    var isActive: Bool { get set }
}

final class BasicActionView: UIView, Activatable {

    var icon: UIImage? {
        get { imageView.image }
        set { imageView.image = newValue?.withRenderingMode(.alwaysTemplate) }
    }
    
    var isEnabled: Bool = true {
        didSet {
            guard isEnabled != oldValue else { return }
            
            let colorToken: Color
            
            if isEnabled {
                colorToken = isActive ? Color.green : basicColorToken
            } else {
                colorToken = Color.gray
            }
            
            updateColor(colorToken)
        }
    }
    
    var isActive: Bool = false {
        didSet {
            guard isEnabled else { return }
            updateColor(isActive ? Color.green : basicColorToken)
        }
    }
    
    var tapAction: (() -> Void)?
    
    private var basicColorToken: Color
    private var currentColorToken: Color = .actionDefault
    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = basicColorToken.color(in: self)
        return imageView
    }()

    init(basicColorToken: Color = .actionDefault) {
        self.basicColorToken = basicColorToken
        super.init(frame: .zero)
        
        addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(makeEdgeConstraints(to: imageView))
        
        NSLayoutConstraint.activate([
            imageView.widthAnchor.constraint(equalToConstant: 32),
            imageView.heightAnchor.constraint(equalToConstant: 32),
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
        updateColor(basicColorToken)
    }
    
    private func updateColor(_ colorToken: Color, animated: Bool = true) {
        currentColorToken = colorToken
        
        if animated {
            UIView.animate(withDuration: 0.2) {
                self.imageView.tintColor = colorToken.color(in: self)
            }
        } else {
            imageView.tintColor = colorToken.color(in: self)
        }
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        updateColor(currentColorToken, animated: false)
    }
}
