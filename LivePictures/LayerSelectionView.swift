//
//  LayerSelectionView.swift
//  LivePictures
//
//  Created by Владислав Матковский on 31.10.2024.
//

import UIKit

final class LayerSelectionView: UIView {

    private var hideTimer: Timer?
    
    private let backgroundView = OverlayView()
    private lazy var collectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.itemSize = CGSize(width: 150, height: 200)
        
        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.dataSource = self
        view.delegate = self
        view.register(Cell.self, forCellWithReuseIdentifier: "Cell")
        view.backgroundColor = .clear
        
        return view
    }()
    
    var getNumberOfPictures: (() -> Int?)?
    var getPictureAtIndex: ((Int) -> UIImage?)?
    var onSelectLayer: ((Int) -> Void)?
    
    private var selectedLayerIndex = 0
    
    init() {
        super.init(frame: .zero)
        
        addSubview(backgroundView)
        backgroundView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(makeEdgeConstraints(to: backgroundView))
        
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 200)
        ])
        
        addSubview(collectionView)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(makeEdgeConstraints(to: collectionView, insets: .init(
            top: 0, left: 4, bottom: 0, right: 4
        )))

        addGestureRecognizer(GestureRecognizer(
            onTouchesBegan: { [weak self] in
                self?.hideTimer?.invalidate()
            }, onTouchesEnded: { [weak self] in
                self?.scheduleHide()
            }
        ))
    }
    
    required init?(coder: NSCoder) { nil }
    
    func scroll() {
        collectionView.reloadData()
        
        collectionView.scrollToItem(
            at: .init(row: selectedLayerIndex, section: 0),
            at: .centeredHorizontally,
            animated: true
        )
    }
    
    func update(withLayerIndex index: Int) {
        selectedLayerIndex = index
        collectionView.reloadData()
    }
    
    func show() {
        UIView.animate(withDuration: 0.2) {
            self.alpha = 1
        }
        
        scheduleHide()
    }
    
    func toggle() {
        UIView.animate(withDuration: 0.2) {
            self.alpha = self.alpha > 0 ? 0 : 1
        }
        
        if alpha > 0 {
            scheduleHide()
        }
    }
    
    func scheduleHide() {
        hideTimer?.invalidate()
        hideTimer = Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { _ in
            UIView.animate(withDuration: 0.5) {
                self.alpha = 0
            }
        }
    }
}

extension LayerSelectionView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return getNumberOfPictures?() ?? 0
    }
    
    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)

        if let cell = cell as? Cell {
            cell.configure(
                isSelected: indexPath.row == selectedLayerIndex,
                image: getPictureAtIndex?(indexPath.row),
                onTap: { [weak self] in
                    guard let self else { return }
                    
                    self.selectedLayerIndex = indexPath.row
                    self.onSelectLayer?(self.selectedLayerIndex)
                    self.collectionView.reloadData()
                }
            )
        }
        
        return cell
    }
}

extension LayerSelectionView: UICollectionViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        scheduleHide()
    }
}

private final class Cell: UICollectionViewCell {
    
    private static let backgroundImage = {
        let image = UIImage(named: "canvas")
        return image
    }()
    
    private let pictureContent: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 8
        view.layer.masksToBounds = true
        return view
    }()
    
    private let backgroundImage: UIImageView = {
        let imageView = UIImageView()
        imageView.image = backgroundImage
        imageView.contentScaleFactor = 1 / 3.5
        return imageView
    }()
    
    private let pictureImage: UIImageView = {
        let imageView = UIImageView()
        imageView.contentScaleFactor = 1 / 3.5
        return imageView
    }()
    
    private var handleTap: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        contentView.addSubview(pictureContent)
        pictureContent.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(contentView.makeEdgeConstraints(to: pictureContent, insets: .init(
            top: 8, left: 4, bottom: 8, right: 4
        )))
        
        pictureContent.addSubview(backgroundImage)
        backgroundImage.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(pictureContent.makeEdgeConstraints(to: backgroundImage))
        
        pictureContent.addSubview(pictureImage)
        pictureImage.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(pictureContent.makeEdgeConstraints(to: pictureImage))
        
        contentView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(onTap)))
    }
    
    required init?(coder: NSCoder) { nil }
    
    func configure(
        isSelected: Bool,
        image: UIImage?,
        onTap: @escaping () -> Void
    ) {
        backgroundColor = isSelected ? Color.green.color(in: self) : .clear
        pictureImage.image = image
        self.handleTap = onTap
    }
    
    @objc private func onTap() {
        handleTap?()
    }
}

private final class GestureRecognizer: UIGestureRecognizer {
    
    private var onTouchesBegan: () -> Void
    private var onTouchesEnded: () -> Void
    
    init(onTouchesBegan: @escaping () -> Void, onTouchesEnded: @escaping () -> Void) {
        self.onTouchesBegan = onTouchesBegan
        self.onTouchesEnded = onTouchesEnded
        super.init(target: nil, action: nil)
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesBegan(touches, with: event)
        onTouchesBegan()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        super.touchesEnded(touches, with: event)
        onTouchesEnded()
    }
}
