//
//  TextInputView.swift
//  LivePictures
//
//  Created by Владислав Матковский on 31.10.2024.
//

import UIKit

final class TextInputView: UIView {
    
    private lazy var label: UILabel = {
        let label = UILabel()
        label.textColor = Color.actionDefault.color(in: self)
        label.font = .systemFont(ofSize: .init(16))
        return label
    }()
    
    private let textField: UITextField = {
        let textField = UITextField()
        textField.keyboardType = .numberPad
        textField.borderStyle = .roundedRect
        return textField
    }()
    
    var text: String? {
        get { textField.text }
        set { textField.text = newValue }
    }
    
    var title: String? {
        get { label.text }
        set { label.text = newValue }
    }
    
    init() {
        super.init(frame: .zero)
        
        [label, textField].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }
        
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.topAnchor.constraint(equalTo: topAnchor),
            
            textField.leadingAnchor.constraint(equalTo: leadingAnchor),
            textField.trailingAnchor.constraint(equalTo: trailingAnchor),
            textField.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 8),
            textField.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    func focus() {
        textField.becomeFirstResponder()
    }
    
    required init?(coder: NSCoder) { nil }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        label.textColor = Color.actionDefault.color(in: self)
    }
}
