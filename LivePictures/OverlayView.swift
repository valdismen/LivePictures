//
//  OverlayView.swift
//  LivePictures
//
//  Created by Владислав Матковский on 30.10.2024.
//

import UIKit

final class OverlayView: UIView {
    
    init() {
        super.init(frame: .zero)
        
        let borderView = UIView()
        borderView.layer.masksToBounds = true
        borderView.layer.cornerRadius = 4
        borderView.layer.borderWidth = 1
        borderView.layer.borderColor = UIColor(white: 85 / 255, alpha: 0.16).cgColor
        borderView.backgroundColor = UIColor(white: 0, alpha: 0.14)
        
        addSubview(borderView)
        borderView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(makeEdgeConstraints(to: borderView, insets: .init(
            top: 1, left: 1, bottom: 1, right: 1
        )))
        
        let blurEffect = UIBlurEffect(style: .regular)
        let blurEffectView = UIVisualEffectView(effect: blurEffect)

        borderView.addSubview(blurEffectView)
        blurEffectView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(borderView.makeEdgeConstraints(to: blurEffectView))
    }
    
    required init?(coder: NSCoder) { nil }
    
}
