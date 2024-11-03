//
//  ActionsGroupView.swift
//  LivePictures
//
//  Created by Владислав Матковский on 29.10.2024.
//

import UIKit

final class ActionsGroupView: UIView {
    
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fill
        stackView.spacing = 16
        return stackView
    }()
    
    init() {
        super.init(frame: .zero)
        
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 32),
        ])
        
        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(makeEdgeConstraints(to: stackView))
    }
    
    required init?(coder: NSCoder) { nil }
    
    func setActionsViews(_ views: [UIView]) {
        stackView.arrangedSubviews.forEach {
            stackView.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        views.forEach {
            stackView.addArrangedSubview($0)
        }
    }
}
