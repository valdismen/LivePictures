//
//  MenuView.swift
//  LivePictures
//
//  Created by Владислав Матковский on 01.11.2024.
//

import UIKit

final class MenuView: UIView {
    
    private let backgroundView = OverlayView()
    
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .vertical
        stackView.distribution = .fill
        stackView.spacing = 16
        return stackView
    }()
    
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
    
    func setItems(_ views: [UIView]) {
        stackView.arrangedSubviews.forEach {
            stackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        views.forEach {
            stackView.addArrangedSubview($0)
        }
    }
}
