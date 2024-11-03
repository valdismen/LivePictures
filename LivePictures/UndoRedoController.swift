//
//  UndoRedoController.swift
//  LivePictures
//
//  Created by Владислав Матковский on 30.10.2024.
//

final class UndoRedoController {
    struct Action {
        let undo: () -> Void
        let redo: () -> Void
    }
    
    private var redoPosition: Int = 0
    private var actions: [Action] = []
    
    var canUndo: Bool { redoPosition > 0 }
    var canRedo: Bool { actions.count > redoPosition }
    
    func add(_ action: Action) {
        if canRedo {
            actions.removeLast(actions.count - redoPosition)
        }

        actions.append(action)
        redoPosition = actions.count
    }
    
    func undo() {
        guard canUndo else { return }
        redoPosition -= 1
        actions[redoPosition].undo()
    }
    
    func redo() {
        guard canRedo else { return }
        actions[redoPosition].redo()
        redoPosition += 1
    }
}
