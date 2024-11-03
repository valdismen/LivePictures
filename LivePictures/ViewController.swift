//
//  ViewController.swift
//  LivePictures
//
//  Created by Владислав Матковский on 29.10.2024.
//

import UIKit

final class ViewController: UIViewController {
    
    struct PopupViewData {
        let actionView: Activatable?
        let parentView: UIView?
        let view: UIView
    }

    private lazy var popupViews: [UIView: PopupViewData] = {
        let data: [PopupViewData] = [
            .init(actionView: nil, parentView: nil, view: layerSelectionView),
            .init(actionView: figuresActionView, parentView: nil, view: figureSelectionContainerView),
            .init(actionView: colorActionView, parentView: nil, view: fastColorSelectionContainerView),
            .init(
                actionView: paletteActionView,
                parentView: fastColorSelectionContainerView,
                view: colorSelectionView
            ),
            .init(actionView: openMenuActionView, parentView: nil, view: menuView),
            .init(actionView: addRandomLayersMenuItemView, parentView: nil, view: generatorConfigurationView),
            .init(actionView: animationSpeedMenuItemView, parentView: nil, view: animationSpeedConfigurationView),
            .init(actionView: exportMenuItemView, parentView: nil, view: exportView),
        ]
        
        return data.reduce(into: [:]) {
            $0[$1.view] = $1
        }
    }()
    
    private var picturesBookModel = PicturesBookModel()
    private let undoRedoController = UndoRedoController()
    
    private var currentPicture: PictureModel?
    private var currentPictureIndex: Int?

    private var playStartTime: CFTimeInterval = 0
    private lazy var displayLink = CADisplayLink(target: self, selector: #selector(onFrameUpdate))
    private var playingPicture: PictureModel?
    private var playingRate: CFTimeInterval = 10

    private lazy var canvasView = {
        let view = CanvasView()
        
        view.onFreeTap = { [weak self] in
            self?.toggleLayerSelectionView()
        }
        
        return view
    }()

    private lazy var layerSelectionView = {
        let view = LayerSelectionView()
        view.alpha = 0

        view.getNumberOfPictures = { [weak self] in
            self?.picturesBookModel.numberOfPictures
        }
        
        view.getPictureAtIndex = { [weak self] in
            self?.picturesBookModel.getPicture(at: $0)?.getImage()
        }
        
        view.onSelectLayer = { [weak self] index in
            guard let self, let picture = self.picturesBookModel.getPicture(at: index) else { return }
            self.showPicture(picture, index: index)
        }
        
        return view
    }()
    
    private let topActionBar: UIView = {
        let view = UIView()
        
        NSLayoutConstraint.activate([
            view.heightAnchor.constraint(equalToConstant: 32)
        ])
        
        return view
    }()
    
    private let undoRedoActionsGroupView = ActionsGroupView()
    private let layersActionsGroupView = ActionsGroupView()
    private let playbackActionsGroupView = ActionsGroupView()
    private let drawingActionsGroupView = ActionsGroupView()
    private let fastColorSelectionActionsGroupView = ActionsGroupView()
    private let figureSelectionActionsGroupView = ActionsGroupView()

    private lazy var fastColorSelectionContainerView = {
        let view = OverlayView()
        view.alpha = 0
        
        view.addSubview(fastColorSelectionActionsGroupView)
        fastColorSelectionActionsGroupView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(view.makeEdgeConstraints(to: fastColorSelectionActionsGroupView, insets: .init(
            top: 16, left: 16, bottom: 16, right: 16
        )))
        
        return view
    }()
    
    private lazy var figureSelectionContainerView = {
        let view = OverlayView()
        view.alpha = 0
        
        view.addSubview(figureSelectionActionsGroupView)
        figureSelectionActionsGroupView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(view.makeEdgeConstraints(to: figureSelectionActionsGroupView, insets: .init(
            top: 16, left: 16, bottom: 16, right: 16
        )))
        
        return view
    }()
    
    private lazy var undoActionView = {
        let view = BasicActionView()
        view.icon = UIImage(named: "step_back")
        
        view.tapAction = { [weak self] in
            self?.undoRedoController.undo()
            self?.updateActions()
        }
        
        return view
    }()
    
    private lazy var redoActionView = {
        let view = BasicActionView()
        view.icon = UIImage(named: "step_forward")
        
        view.tapAction = { [weak self] in
            self?.undoRedoController.redo()
            self?.updateActions()
        }
        
        return view
    }()
    
    private lazy var removeLayerActionView = {
        let view = BasicActionView()
        view.icon = UIImage(named: "bin")
        
        view.tapAction = { [weak self] in
            guard let self, let pictureToRemove = self.currentPicture, let currentPictureIndex else { return }
            
            picturesBookModel.removePicture(at: currentPictureIndex)
            
            let previousPicture: PictureModel
            let previousPictureIndex: Int
            
            let numberOfPictures = picturesBookModel.numberOfPictures

            if numberOfPictures > 0 {
                previousPictureIndex = currentPictureIndex == 0 ? numberOfPictures - 1 : currentPictureIndex - 1

                guard let picture = picturesBookModel.getPicture(at: previousPictureIndex) else { return }
                previousPicture = picture
                
                let action = UndoRedoController.Action(
                    undo: { [weak self] in
                        self?.picturesBookModel.addPicture(pictureToRemove, at: currentPictureIndex)
                        self?.showPicture(pictureToRemove, index: currentPictureIndex)
                    },
                    redo: { [weak self] in
                        _ = self?.picturesBookModel.removePicture(at: currentPictureIndex)
                        self?.showPicture(previousPicture, index: previousPictureIndex)
                    }
                )
                
                undoRedoController.add(action)
            } else {
                previousPicture = PictureModel(size: self.canvasView.bounds.size)
                previousPictureIndex = 0
                self.picturesBookModel.addPicture(previousPicture)
                
                let action = UndoRedoController.Action(
                    undo: { [weak self] in
                        self?.picturesBookModel.removePicture(at: previousPictureIndex)
                        self?.picturesBookModel.addPicture(pictureToRemove, at: currentPictureIndex)
                        self?.showPicture(pictureToRemove, index: currentPictureIndex)
                    },
                    redo: { [weak self] in
                        self?.picturesBookModel.removePicture(at: currentPictureIndex)
                        self?.picturesBookModel.addPicture(previousPicture)
                        self?.showPicture(previousPicture, index: previousPictureIndex)
                    }
                )
                
                undoRedoController.add(action)
            }

            showPicture(previousPicture, index: previousPictureIndex)
            updateActions()
            showLayerSelectionView()
        }
        
        return view
    }()
    
    private lazy var addLayerActionView = {
        let view = BasicActionView()
        view.icon = UIImage(named: "plus")
        
        view.tapAction = { [weak self] in
            guard let self, let currentPicture, let currentPictureIndex else { return }
            
            let pictureModel = PictureModel(size: self.canvasView.bounds.size)
            let newPictureIndex = currentPictureIndex + 1
            
            picturesBookModel.addPicture(pictureModel, at: newPictureIndex)
            showPicture(pictureModel, index: newPictureIndex)
            
            let action = UndoRedoController.Action(
                undo: { [weak self] in
                    self?.picturesBookModel.removePicture(at: newPictureIndex)
                    self?.showPicture(currentPicture, index: currentPictureIndex)
                },
                redo: { [weak self] in
                    self?.picturesBookModel.addPicture(pictureModel, at: newPictureIndex)
                    self?.showPicture(pictureModel, index: newPictureIndex)
                }
            )
            
            undoRedoController.add(action)
            updateActions()
            showLayerSelectionView()
        }
        
        return view
    }()
    
    private lazy var openMenuActionView = {
        let view = BasicActionView()
        view.icon = UIImage(systemName: "filemenu.and.selection")
        
        view.tapAction = { [weak self] in
            self?.toggleMenuView()
        }
        
        return view
    }()
    
    private lazy var pauseActionView = {
        let view = BasicActionView()
        view.icon = UIImage(named: "pause")
        view.isEnabled = false
        
        view.tapAction = { [weak self] in
            self?.pause()
        }
        
        return view
    }()
    
    private lazy var playActionView = {
        let view = BasicActionView()
        view.icon = UIImage(named: "play")
        
        view.tapAction = { [weak self] in
            self?.play()
        }
        
        return view
    }()
    
    private lazy var toolsActionViews: [BasicActionView] = {
        let color = { [weak self] in
            self?.colorActionView.color ?? .black
        }
        
        return [
            makeToolActionView(
                icon: UIImage(named: "pencil"),
                drawingTool: { PencilDrawingTool(color: color, lineWidth: 5) }
            ),
            makeToolActionView(
                icon: UIImage(systemName: "pencil.line"),
                drawingTool: { LineDrawingTool(color: color, lineWidth: 5) }
            ),
            makeToolActionView(
                icon: UIImage(named: "eraser"),
                drawingTool: { EraserDrawingTool(lineWidth: 15) }
            ),
        ]
    }()
    
    private lazy var figuresToolsActionViews: [BasicActionView] = {
        let color = { [weak self] in
            self?.colorActionView.color ?? .black
        }
        
        return [
            makeToolActionView(
                icon: UIImage(named: "square"),
                drawingTool: { FigureDrawingTool(figure: PointsFigure.square, color: color, lineWidth: 10) }
            ),
            makeToolActionView(
                icon: UIImage(systemName: "circle"),
                drawingTool: { FigureDrawingTool(figure: CircleFigure(), color: color, lineWidth: 10) }
            ),
            makeToolActionView(
                icon: UIImage(named: "triangle"),
                drawingTool: { FigureDrawingTool(figure: PointsFigure.triangle, color: color, lineWidth: 10) }
            ),
            makeToolActionView(
                icon: UIImage(named: "arrow_up"),
                drawingTool: { FigureDrawingTool(figure: PointsFigure.arrow, color: color, lineWidth: 10) }
            ),
        ]
    }()
    
    private lazy var figuresActionView = {
        let view = BasicActionView()
        view.icon = UIImage(named: "figures")
        
        view.tapAction = { [weak self] in
            self?.toggleFigureSelectionView()
        }
        
        return view
    }()
    
    private lazy var colorActionView = {
        let view = ColorActionView()
        
        view.tapAction = { [weak self] in
            self?.toggleFastColorSelectionView()
        }
        
        return view
    }()
    
    private lazy var paletteActionView = {
        let view = BasicActionView()
        view.icon = UIImage(named: "palette")
        
        view.tapAction = { [weak self] in
            self?.toggleColorSelectionView()
        }
        
        return view
    }()
    
    private lazy var fastColorsActionViews: [ColorActionView] = {
        ([
            UIColor(red: 255 / 255, green: 255 / 255, blue: 255 / 255, alpha: 1),
            UIColor(red: 255 / 255, green: 61 / 255, blue: 0 / 255, alpha: 1),
            UIColor(red: 28 / 255, green: 28 / 255, blue: 28 / 255, alpha: 1),
            UIColor(red: 25 / 255, green: 118 / 255, blue: 210 / 255, alpha: 1),
        ] as [UIColor]).map {
            let view = ColorActionView()
            view.color = $0

            view.tapAction = { [weak self, weak view] in
                self?.toggleFastColorSelectionView()
                self?.colorActionView.color = view?.color
            }

            return view
        }
    }()
    
    private lazy var generatorConfigurationView = {
        let view = GeneratorConfigurationView()
        view.alpha = 0
        
        view.errorMessageHandler = { [weak self] message in
            self?.showAlert(message: message)
        }
        
        view.cancelHandler = { [weak self] in
            self?.toggleGeneratorConfigurationView()
        }
        
        view.addHandler = { [weak self] count in
            self?.toggleGeneratorConfigurationView()
            self?.addRandomLayers(count: count)
        }

        return view
    }()
    
    private lazy var animationSpeedConfigurationView = {
        let view = AnimationSpeedConfigurationView()
        view.alpha = 0
        
        view.errorMessageHandler = { [weak self] message in
            self?.showAlert(message: message)
        }
        
        view.cancelHandler = { [weak self] in
            self?.toggleAnimationSpeedConfigurationView()
        }
        
        view.saveHandler = { [weak self] rate in
            self?.toggleAnimationSpeedConfigurationView()
            self?.playingRate = CFTimeInterval(rate)
        }

        return view
    }()
    
    private lazy var exportView = {
        let view = ExportView()
        view.alpha = 0
        
        view.errorMessageHandler = { [weak self] message in
            self?.showAlert(message: message)
        }
        
        view.completionHandler = { [weak self] in
            self?.toggleExportView()
            
            UIView.animate(withDuration: 0.2) { [weak self] in
                guard let self else { return }
                self.undoRedoActionsGroupView.alpha = 1
                self.layersActionsGroupView.alpha = 1
                self.drawingActionsGroupView.alpha = 1
                self.playbackActionsGroupView.alpha = 1
            }
        }
        
        view.getNumberOfPictures = { [weak self] in
            self?.picturesBookModel.numberOfPictures
        }
        
        view.getPictureAtIndex = { [weak self] in
            self?.picturesBookModel.getPicture(at: $0)?.getImage()
        }

        return view
    }()
    
    private lazy var colorSelectionView = {
        let view = ColorSelectionView()
        view.alpha = 0
        
        view.onColorUpdated = { [weak self] color in
            self?.colorActionView.color = color
        }
        
        return view
    }()
    
    private let menuView = {
        let view = MenuView()
        view.alpha = 0
        return view
    }()
    
    private lazy var addRandomLayersMenuItemView = {
        let view = MenuItemView()
        
        view.icon = UIImage(systemName: "dice")
        view.title = "Генерация кадров"
        
        view.tapAction = { [weak self] in
            self?.toggleMenuView()
            self?.toggleGeneratorConfigurationView()
        }
        
        return view
    }()
    
    private lazy var copyPictureMenuItemView = {
        let view = MenuItemView()
        
        view.icon = UIImage(systemName: "doc.on.doc")
        view.title = "Дублировать кадр"
        
        view.tapAction = { [weak self] in
            guard let self, let currentPicture, let currentPictureIndex else { return }
            
            let pictureModel = PictureModel(size: self.canvasView.bounds.size)
            currentPicture.drawActionsSequence.forEach {
                pictureModel.appendAction($0)
            }
            
            let newPictureIndex = currentPictureIndex + 1
            
            picturesBookModel.addPicture(pictureModel, at: newPictureIndex)
            showPicture(pictureModel, index: newPictureIndex)
            
            let action = UndoRedoController.Action(
                undo: { [weak self] in
                    self?.picturesBookModel.removePicture(at: newPictureIndex)
                    self?.showPicture(currentPicture, index: currentPictureIndex)
                },
                redo: { [weak self] in
                    self?.picturesBookModel.addPicture(pictureModel, at: newPictureIndex)
                    self?.showPicture(pictureModel, index: newPictureIndex)
                }
            )
            
            undoRedoController.add(action)
            updateActions()
            showLayerSelectionView()
        }
        
        return view
    }()
    
    private lazy var removeAllPicturesMenuItemView = {
        let view = MenuItemView()
        
        view.icon = UIImage(systemName: "clear")
        view.title = "Удалить все кадры"
        
        view.tapAction = { [weak self] in
            guard let self, let currentPicture = self.currentPicture, let currentPictureIndex else { return }
            
            let oldPicturesBookModel = picturesBookModel
            let newPicturesBookModel = PicturesBookModel()
            self.picturesBookModel = newPicturesBookModel
            
            let firstPicture = PictureModel(size: self.canvasView.bounds.size)
            newPicturesBookModel.addPicture(firstPicture, at: 0)
            showPicture(firstPicture, index: 0)
            
            let action = UndoRedoController.Action(
                undo: { [weak self] in
                    self?.picturesBookModel = oldPicturesBookModel
                    self?.showPicture(currentPicture, index: currentPictureIndex)
                },
                redo: { [weak self] in
                    self?.picturesBookModel = newPicturesBookModel
                    self?.showPicture(firstPicture, index: 0)
                }
            )
            
            undoRedoController.add(action)
            
            updateActions()
            showLayerSelectionView()
        }
        
        return view
    }()
    
    private lazy var animationSpeedMenuItemView = {
        let view = MenuItemView()
        
        view.icon = UIImage(systemName: "timer.circle")
        view.title = "Скорость воспроизведения"
        
        view.tapAction = { [weak self] in
            self?.toggleMenuView()
            self?.toggleAnimationSpeedConfigurationView()
        }
        
        return view
    }()
    
    private lazy var exportMenuItemView = {
        let view = MenuItemView()
        
        view.icon = UIImage(systemName: "square.and.arrow.up")
        view.title = "Экспортировать в GIF"
        
        view.tapAction = { [weak self] in
            guard let self else { return }
            
            popupViews.values.forEach {
                $0.actionView?.isActive = false
            }
            
            UIView.animate(withDuration: 0.2) { [weak self] in
                guard let self else { return }
                
                self.popupViews.values.forEach {
                    $0.view.alpha = 0
                }
                
                self.undoRedoActionsGroupView.alpha = 0
                self.layersActionsGroupView.alpha = 0
                self.drawingActionsGroupView.alpha = 0
                self.playbackActionsGroupView.alpha = 0
            }
            
            toggleExportView()
            
            exportView.runExport(rate: playingRate, size: canvasView.bounds.size) { [weak self] url in
                guard let url else { return }

                let activityViewController = UIActivityViewController(
                    activityItems: [url],
                    applicationActivities: nil
                )

                self?.present(activityViewController, animated: true, completion: nil)
            }
        }
        
        return view
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addSubview(canvasView)
        canvasView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(view.makeSafeAreaEdgeConstraints(to: canvasView, insets: .init(
            top: 80, left: 16, bottom: 54, right: 16
        )))
        
        view.addSubview(topActionBar)
        topActionBar.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topActionBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            topActionBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            topActionBar.bottomAnchor.constraint(equalTo: canvasView.topAnchor, constant: -32)
        ])
        
        view.addSubview(undoRedoActionsGroupView)
        undoRedoActionsGroupView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            undoRedoActionsGroupView.leadingAnchor.constraint(equalTo: topActionBar.leadingAnchor),
            undoRedoActionsGroupView.centerYAnchor.constraint(equalTo: topActionBar.centerYAnchor),
        ])
        
        view.addSubview(layersActionsGroupView)
        layersActionsGroupView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            layersActionsGroupView.centerXAnchor.constraint(equalTo: topActionBar.centerXAnchor),
            layersActionsGroupView.centerYAnchor.constraint(equalTo: topActionBar.centerYAnchor),
        ])
        
        view.addSubview(playbackActionsGroupView)
        playbackActionsGroupView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            playbackActionsGroupView.trailingAnchor.constraint(equalTo: topActionBar.trailingAnchor),
            playbackActionsGroupView.centerYAnchor.constraint(equalTo: topActionBar.centerYAnchor),
        ])
        
        view.addSubview(drawingActionsGroupView)
        drawingActionsGroupView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            drawingActionsGroupView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            drawingActionsGroupView.topAnchor.constraint(equalTo: canvasView.bottomAnchor, constant: 22),
        ])
        
        view.addSubview(fastColorSelectionContainerView)
        fastColorSelectionContainerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            fastColorSelectionContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            fastColorSelectionContainerView.bottomAnchor.constraint(
                equalTo: drawingActionsGroupView.topAnchor, constant: -16
            ),
        ])
        
        view.addSubview(figureSelectionContainerView)
        figureSelectionContainerView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            figureSelectionContainerView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            figureSelectionContainerView.bottomAnchor.constraint(
                equalTo: drawingActionsGroupView.topAnchor, constant: -16
            ),
        ])
        
        view.addSubview(colorSelectionView)
        colorSelectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            colorSelectionView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            colorSelectionView.widthAnchor.constraint(equalTo: fastColorSelectionContainerView.widthAnchor),
            colorSelectionView.bottomAnchor.constraint(
                equalTo: fastColorSelectionContainerView.topAnchor, constant: -8
            ),
        ])
        
        view.addSubview(generatorConfigurationView)
        generatorConfigurationView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            generatorConfigurationView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            generatorConfigurationView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            generatorConfigurationView.bottomAnchor.constraint(
                equalTo: view.keyboardLayoutGuide.topAnchor,
                constant: -16
            )
        ])
        
        view.addSubview(animationSpeedConfigurationView)
        animationSpeedConfigurationView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            animationSpeedConfigurationView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            animationSpeedConfigurationView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            animationSpeedConfigurationView.bottomAnchor.constraint(
                equalTo: view.keyboardLayoutGuide.topAnchor,
                constant: -16
            )
        ])
        
        view.addSubview(exportView)
        exportView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            exportView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            exportView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            exportView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        
        view.addSubview(layerSelectionView)
        layerSelectionView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            layerSelectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: -4),
            layerSelectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: 4),
            layerSelectionView.bottomAnchor.constraint(equalTo: drawingActionsGroupView.topAnchor, constant: -16)
        ])
        
        view.addSubview(menuView)
        menuView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            menuView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            menuView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            menuView.topAnchor.constraint(equalTo: topActionBar.bottomAnchor, constant: 16)
        ])
        
        undoRedoActionsGroupView.setActionsViews([
            undoActionView,
            redoActionView,
        ])
        
        layersActionsGroupView.setActionsViews([
            removeLayerActionView,
            addLayerActionView,
            openMenuActionView,
        ])
        
        playbackActionsGroupView.setActionsViews([
            pauseActionView,
            playActionView,
        ])
        
        drawingActionsGroupView.setActionsViews(toolsActionViews + [
            figuresActionView,
            colorActionView,
        ])
        
        fastColorSelectionActionsGroupView.setActionsViews([
            paletteActionView,
        ] + fastColorsActionViews)
        
        figureSelectionActionsGroupView.setActionsViews(figuresToolsActionViews)

        menuView.setItems([
            addRandomLayersMenuItemView,
            copyPictureMenuItemView,
            removeAllPicturesMenuItemView,
            animationSpeedMenuItemView,
            exportMenuItemView,
        ])
        
        updateActions()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard picturesBookModel.numberOfPictures == 0 else { return }

        let pictureModel = PictureModel(size: canvasView.bounds.size)
        picturesBookModel.addPicture(pictureModel)
        showPicture(pictureModel, index: 0)
    }
    
    private func makeToolActionView(icon: UIImage?, drawingTool: @escaping () -> DrawingTool) -> BasicActionView {
        let view = BasicActionView()
        view.icon = icon
        
        view.tapAction = { [weak self, weak view] in
            guard let self, let view else { return }
            
            guard !view.isActive else {
                view.isActive = false
                canvasView.setDrawingTool(nil)
                return
            }
            
            self.toolsActionViews.forEach {
                $0.isActive = false
            }
            
            self.figuresToolsActionViews.forEach {
                $0.isActive = false
            }
            
            view.isActive = true

            canvasView.setDrawingTool(drawingTool().with { [weak self] in
                self?.handleDrawAction(action: $0)
            })
        }
        
        return view
    }
    
    private func showPicture(_ picture: PictureModel, index: Int) {
        canvasView.setPictureModel(picture)
        canvasView.setPreviousImage(picturesBookModel.getPicture(beforeIndex: index)?.getImage())
        currentPicture = picture
        
        if currentPictureIndex != index {
            canvasView.resetScale()
        }
        
        currentPictureIndex = index
    }
    
    private func updateActions() {
        undoActionView.isEnabled = undoRedoController.canUndo
        redoActionView.isEnabled = undoRedoController.canRedo
        removeLayerActionView.isEnabled = picturesBookModel.numberOfPictures > 1 || currentPicture?.isEmpty == false
        playActionView.isEnabled = picturesBookModel.numberOfPictures > 1
        
        layerSelectionView.update(withLayerIndex: currentPictureIndex ?? 0)
    }
    
    private func handleDrawAction(action: PictureModel.DrawAction) {
        guard let currentPictureIndex else { return }
        
        currentPicture?.appendAction(action)
        
        undoRedoController.add(.init(
            undo: { [weak self] in
                guard let picture = self?.picturesBookModel.getPicture(at: currentPictureIndex) else { return }
                picture.removeLastAction()
                self?.showPicture(picture, index: currentPictureIndex)
            },
            redo: { [weak self] in
                guard let picture = self?.picturesBookModel.getPicture(at: currentPictureIndex) else { return }
                picture.appendAction(action)
                self?.showPicture(picture, index: currentPictureIndex)
            }
        ))
        
        updateActions()
    }
    
    private func addRandomLayers(count: Int) {
        guard let currentPictureIndex else { return }

        let generator = SamplePicturesGenerator(frameSize: canvasView.bounds.size)

        picturesBookModel.addGenerator(generator, count: count, at: currentPictureIndex + 1)
        let pictureIndexToShow = currentPictureIndex + count
        guard let pictureToShow = picturesBookModel.getPicture(at: pictureIndexToShow) else { return }
        showPicture(pictureToShow, index: pictureIndexToShow)
        
        undoRedoController.add(.init(
            undo: { [weak self] in
                self?.picturesBookModel.removeRange(
                    range: (currentPictureIndex + 1)..<(currentPictureIndex + count + 1)
                )
                
                guard let picture = self?.picturesBookModel.getPicture(at: currentPictureIndex) else { return }
                self?.showPicture(picture, index: currentPictureIndex)
            },
            redo: { [weak self] in
                self?.picturesBookModel.addGenerator(generator, count: count, at: currentPictureIndex + 1)
                guard let pictureToShow = self?.picturesBookModel.getPicture(at: pictureIndexToShow) else {
                    return
                }

                self?.showPicture(pictureToShow, index: pictureIndexToShow)
            }
        ))
        
        updateActions()
    }
    
    private func play() {
        guard !playActionView.isActive else { return }
        
        view.endEditing(true)
        
        popupViews.values.forEach {
            $0.actionView?.isActive = false
        }
        
        UIView.animate(withDuration: 0.2) {
            self.popupViews.values.forEach {
                $0.view.alpha = 0
            }
            
            self.undoRedoActionsGroupView.alpha = 0
            self.layersActionsGroupView.alpha = 0
            self.drawingActionsGroupView.alpha = 0
        }
        
        canvasView.setPreviousImage(nil)
        
        pauseActionView.isEnabled = true
        playActionView.isActive = true
        canvasView.isUserInteractionEnabled = false
        canvasView.resetScale()
        playStartTime = CACurrentMediaTime()
        displayLink.add(to: .main, forMode: .common)
    }
    
    private func pause() {
        guard playActionView.isActive else { return }
        
        displayLink.remove(from: .main, forMode: .common)

        UIView.animate(withDuration: 0.2) {
            self.undoRedoActionsGroupView.alpha = 1
            self.layersActionsGroupView.alpha = 1
            self.drawingActionsGroupView.alpha = 1
        }
        
        currentPicture.flatMap { showPicture($0, index: currentPictureIndex ?? 0) }
        
        pauseActionView.isEnabled = false
        playActionView.isActive = false
        canvasView.isUserInteractionEnabled = true
    }
    
    @objc private func onFrameUpdate() {
        let numberOfPictures = picturesBookModel.numberOfPictures
        let timeDelta = CACurrentMediaTime() - playStartTime
        let frameIndex = Int(playingRate * timeDelta) % numberOfPictures
        
        guard
            let picture = picturesBookModel.getPicture(at: frameIndex),
            playingPicture != picture
        else { return }
        
        playingPicture = picture
        canvasView.setPictureModel(picture)
    }
    
    private func toggleMenuView() {
        openMenuActionView.isActive.toggle()
        let newAlpha: CGFloat = openMenuActionView.isActive ? 1 : 0
        
        UIView.animate(withDuration: 0.2) {
            self.menuView.alpha = newAlpha
        }
    }
    
    private func toggleFigureSelectionView() {
        figuresActionView.isActive.toggle()
        let newAlpha: CGFloat = figuresActionView.isActive ? 1 : 0
        
        UIView.animate(withDuration: 0.2) {
            self.figureSelectionContainerView.alpha = newAlpha
        }
    }
    
    private func toggleFastColorSelectionView() {
        if paletteActionView.isActive {
            toggleColorSelectionView()
        }
        
        colorActionView.isActive.toggle()
        let newAlpha: CGFloat = colorActionView.isActive ? 1 : 0
        
        UIView.animate(withDuration: 0.2) {
            self.fastColorSelectionContainerView.alpha = newAlpha
        }
    }
    
    private func toggleColorSelectionView() {
        paletteActionView.isActive.toggle()
        let newAlpha: CGFloat = paletteActionView.isActive ? 1 : 0
        
        colorSelectionView.color = colorActionView.color ?? .black
        
        UIView.animate(withDuration: 0.2) {
            self.colorSelectionView.alpha = newAlpha
        }
    }
    
    private func toggleGeneratorConfigurationView() {
        if generatorConfigurationView.alpha > 0 {
            view.endEditing(true)
        } else {
            generatorConfigurationView.focus()
        }
        
        let newAlpha: CGFloat = generatorConfigurationView.alpha > 0 ? 0 : 1
        
        UIView.animate(withDuration: 0.2) {
            self.generatorConfigurationView.alpha = newAlpha
        }
    }
    
    private func toggleAnimationSpeedConfigurationView() {
        if animationSpeedConfigurationView.alpha > 0 {
            view.endEditing(true)
        } else {
            animationSpeedConfigurationView.focus()
        }
        
        let newAlpha: CGFloat = animationSpeedConfigurationView.alpha > 0 ? 0 : 1
        
        UIView.animate(withDuration: 0.2) {
            self.animationSpeedConfigurationView.alpha = newAlpha
        }
    }
    
    private func toggleExportView() {
        let newAlpha: CGFloat = exportView.alpha > 0 ? 0 : 1
        
        UIView.animate(withDuration: 0.2) {
            self.exportView.alpha = newAlpha
        }
    }
    
    private func showLayerSelectionView() {
        layerSelectionView.show()
        layerSelectionView.scroll()
    }
    
    private func toggleLayerSelectionView() {
        layerSelectionView.toggle()
    }
    
    private func showAlert(message: String) {
        let alert = UIAlertController(title: "Ошибка", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Хорошо", style: .default, handler: nil))
        present(alert, animated: true, completion: nil)
    }
}

