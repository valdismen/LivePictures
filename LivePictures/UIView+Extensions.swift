//
//  UIView+Extensions.swift
//  LivePictures
//
//  Created by Владислав Матковский on 29.10.2024.
//

import UIKit

extension UIView {
    func makeEdgeConstraints(
        to view: UIView,
        insets: UIEdgeInsets = .zero
    ) -> [NSLayoutConstraint] {
        [
            view.leadingAnchor.constraint(equalTo: leadingAnchor, constant: insets.left),
            view.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -insets.right),
            view.topAnchor.constraint(equalTo: topAnchor, constant: insets.top),
            view.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -insets.bottom),
        ]
    }
    
    func makeSafeAreaEdgeConstraints(
        to view: UIView,
        insets: UIEdgeInsets = .zero
    ) -> [NSLayoutConstraint] {
        [
            view.leadingAnchor.constraint(
                equalTo: safeAreaLayoutGuide.leadingAnchor, constant: insets.left
            ),
            view.trailingAnchor.constraint(
                equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -insets.right
            ),
            view.topAnchor.constraint(
                equalTo: safeAreaLayoutGuide.topAnchor, constant: insets.top
            ),
            view.bottomAnchor.constraint(
                equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -insets.bottom
            ),
        ]
    }
}
