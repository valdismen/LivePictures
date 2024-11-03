//
//  ExportView.swift
//  LivePictures
//
//  Created by Владислав Матковский on 01.11.2024.
//

import UIKit
import UniformTypeIdentifiers

final class ExportView: UIView {
    
    private static let backgroundImage = UIImage(named: "canvas")

    private let backgroundView = OverlayView()

    private let titleLabel = {
        let label = UILabel()
        label.text = "Экспорт анимации"
        label.font = .systemFont(ofSize: .init(20))
        label.textAlignment = .center
        return label
    }()
    
    private let progressLabel = {
        let label = UILabel()
        label.text = "50%"
        label.font = .systemFont(ofSize: .init(12))
        label.textAlignment = .center
        return label
    }()
    
    private let progressBar = {
        let view = UIProgressView(progressViewStyle: .bar)
        view.setProgress(0.5, animated: false)
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
    
    private lazy var buttonsStackView = {
        let stackView = UIStackView(arrangedSubviews: [cancelButton])
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        return stackView
    }()
    
    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [
            titleLabel,
            progressLabel,
            progressBar,
            buttonsStackView
        ])
        
        stackView.setCustomSpacing(4, after: progressLabel)
        stackView.distribution = .fill
        stackView.axis = .vertical
        stackView.spacing = 16
        return stackView
    }()
    
    private var isCancelled: Bool = false
    
    var errorMessageHandler: ((String) -> Void)?
    var completionHandler: (() -> Void)?
    
    var getNumberOfPictures: (() -> Int?)?
    var getPictureAtIndex: ((Int) -> UIImage?)?
    
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
    
    func runExport(rate: CGFloat, size: CGSize, completion: @escaping (URL?) -> Void) {
        isCancelled = false
        
        let aspectRatio = size.height / size.width
        let newWidth = min(100, size.width)
        let newSize = CGSize(width: newWidth, height: newWidth * aspectRatio)
        
        progressBar.setProgress(0, animated: false)
        progressLabel.text = "0%"
        
        let totalFrames = self.getNumberOfPictures?() ?? 0
        
        guard totalFrames <= 1000 else {
            completion(nil)
            errorMessageHandler?("Для экспорта изображения необходимо уменьшить количество кадров до 1000")
            onComplete()
            return
        }
        
        guard rate <= 100 else {
            completion(nil)
            errorMessageHandler?("Для экспорта изображения необходимо уменьшить частоту кадров до 100")
            onComplete()
            return
        }
        
        DispatchQueue.global().async {
            let destinationFilename = "\(UUID().uuidString).gif"
            let destinationURL = URL(
                fileURLWithPath: NSTemporaryDirectory()
            ).appendingPathComponent(destinationFilename)
            
            let fileDictionary = [
                kCGImagePropertyGIFDictionary: [
                    kCGImagePropertyGIFLoopCount: 0
                ]
            ]
            
            guard let animatedGifFile = CGImageDestinationCreateWithURL(
                destinationURL as CFURL,
                UTType.gif.identifier as CFString,
                totalFrames,
                nil
            ) else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                
                return
            }
            
            CGImageDestinationSetProperties(animatedGifFile, fileDictionary as CFDictionary)
            
            let frameDictionary = [
                kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFDelayTime: 1.0 / rate]
            ]
            
            var framesCount = 0
            
            while framesCount < totalFrames {
                
                let count = min(20, totalFrames - framesCount)
                
                autoreleasepool {
                    let frames = (0..<count).map {
                        self.appendBackground(
                            image: self.getPictureAtIndex?(framesCount + $0),
                            size: newSize
                        ).cgImage!
                    }
                    
                    frames.forEach {
                        CGImageDestinationAddImage(
                            animatedGifFile,
                            $0,
                            frameDictionary as CFDictionary
                        )
                    }
                }

                framesCount += count
                
                DispatchQueue.main.async {
                    let progress = Float(framesCount) / Float(totalFrames)
                    self.progressLabel.text = "\(Int(progress * 100))%"
                    self.progressBar.setProgress(progress, animated: true)
                }
                
                if self.isCancelled {
                    break
                }
            }
            
            CGImageDestinationFinalize(animatedGifFile)
            
            DispatchQueue.main.async {
                if self.isCancelled {
                    completion(nil)
                } else {
                    completion(destinationURL)
                }
                
                self.onComplete()
            }
        }
    }
    
    @objc private func handleCancel() {
        cancelButton.isEnabled = false
        isCancelled = true
    }
    
    private func onComplete() {
        completionHandler?()
        cancelButton.isEnabled = true
    }
    
    private func appendBackground(image: UIImage?, size: CGSize) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { context in
            Self.backgroundImage?.draw(in: .init(origin: .zero, size: size))
            image?.draw(in: .init(origin: .zero, size: size))
        }
    }
}
