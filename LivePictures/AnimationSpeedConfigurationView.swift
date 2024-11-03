//
//  AnimationSpeedConfigurationView.swift
//  LivePictures
//
//  Created by Владислав Матковский on 31.10.2024.
//

import UIKit

final class AnimationSpeedConfigurationView: UIView {
    
    private let backgroundView = OverlayView()

    private let titleLabel = {
        let label = UILabel()
        label.text = "Скорость воспроизведения"
        label.font = .systemFont(ofSize: .init(20))
        label.textAlignment = .center
        return label
    }()
    
    private let textInputView = {
        let view = TextInputView()
        view.title = "Количество кадров в секунду"
        return view
    }()
    
    private lazy var cancelButton = {
        let button = UIButton()
        button.setTitle("Отмена", for: .normal)
        button.setTitleColor(.systemRed, for: .normal)
        button.setTitleColor(.red, for: .highlighted)
        button.addTarget(self, action: #selector(handleCancel), for: .touchUpInside)
        return button
    }()
    
    private lazy var saveButton = {
        let button = UIButton()
        button.setTitle("Сохранить", for: .normal)
        button.setTitleColor(.systemBlue, for: .normal)
        button.setTitleColor(.blue, for: .highlighted)
        button.addTarget(self, action: #selector(handleSave), for: .touchUpInside)
        return button
    }()
    
    private lazy var buttonsStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            cancelButton, saveButton
        ])

        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        return stackView
    }()
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            titleLabel,
            textInputView,
            buttonsStackView
        ])

        stackView.distribution = .fill
        stackView.axis = .vertical
        stackView.spacing = 16
        return stackView
    }()
    
    var errorMessageHandler: ((String) -> Void)?
    var saveHandler: ((Int) -> Void)?
    var cancelHandler: (() -> Void)?
    
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
    
    func focus() {
        textInputView.focus()
    }
    
    @objc private func handleSave() {
        if let value = validateValue() {
            saveHandler?(value)
        } else {
            errorMessageHandler?("Введите число от 1 до \(Int32.max)")
        }
    }
    
    @objc private func handleCancel() {
        cancelHandler?()
    }
    
    private func validateValue() -> Int? {
        guard
            let value = textInputView.text,
            let intValue = Int(value),
            intValue > 0,
            intValue <= Int32.max
        else { return nil }
        
        return intValue
    }
}
