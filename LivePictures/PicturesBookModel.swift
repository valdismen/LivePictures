//
//  PicturesBookModel.swift
//  LivePictures
//
//  Created by Владислав Матковский on 29.10.2024.
//

import UIKit

final class PicturesBookModel {

    private enum Batch {
        case array([PictureModel])
        case generator(PicturesGenerator, start: Int, count: Int)
        
        var count: Int {
            switch self {
            case let .array(array): return array.count
            case let .generator(_, _, count): return count
            }
        }
        
        func cutting(range: Range<Int>) -> [Batch] {
            switch self {
            case let .array(array):
                let leftArray = Array(array[0..<max(0, range.lowerBound)])
                let rightArray = Array(array[min(array.count, range.upperBound)..<array.count])
                return [.array(leftArray + rightArray)].filter { $0.count > 0 }
            case let .generator(generator, start, count):
                return [
                    .generator(generator, start: start, count: range.lowerBound),
                    .generator(
                        generator,
                        start: start + range.upperBound,
                        count: count - (range.upperBound - range.lowerBound)
                    )
                ].filter { $0.count > 0 }
            }
        }
    }
    
    private var batches: [Batch] = []
    
    private(set) var numberOfPictures = 0
    
    func getPicture(at index: Int) -> PictureModel? {
        guard index >= 0, index < numberOfPictures else { return nil }
        guard let (batchIndex, start) = getBatchIndex(for: index) else { return nil }

        let batch = batches[batchIndex]
        let indexInBatch = index - start
        
        switch batch {
        case let .array(pictures):
            return pictures[indexInBatch]
        case let .generator(generator, startIndex, count):
            let picture = generator.getPicture(at: startIndex + indexInBatch)
            let newBatches = divideGeneratorBatchWithReplacing(
                generator: generator,
                start: startIndex,
                count: count,
                at: indexInBatch,
                batch: .array([picture])
            )
            
            batches.replaceSubrange(batchIndex...batchIndex, with: newBatches)
            return picture
        }
    }
    
    func getLastPicture() -> PictureModel? {
        let numberOfPictures = self.numberOfPictures
        guard numberOfPictures > 0 else { return nil }
        return getPicture(at: numberOfPictures - 1)
    }
    
    func getPicture(beforeIndex index: Int) -> PictureModel? {
        let numberOfPictures = numberOfPictures
        
        guard numberOfPictures > 1 else {
            return nil
        }

        if index == 0 {
            return getLastPicture()
        } else {
            return getPicture(at: index - 1)
        }
    }
    
    func addPicture(_ picture: PictureModel, at index: Int? = nil) {
        let numberOfPictures = numberOfPictures
        
        let index = index.flatMap {
            min(numberOfPictures, max($0, 0))
        } ?? numberOfPictures
        
        if index == numberOfPictures {
            batches.append(.array([picture]))
            updateNumberOfPictures()
            return
        }
        
        guard let (batchIndex, start) = getBatchIndex(for: index) else { return }

        let batch = batches[batchIndex]
        let indexInBatch = index - start
        
        let newBatches: [Batch]
        
        switch batch {
        case var .array(pictures):
            pictures.insert(picture, at: indexInBatch)
            newBatches = [.array(pictures)]
        case let .generator(generator, startIndex, count):
            newBatches = divideGeneratorBatchWithInsertion(
                generator: generator,
                start: startIndex,
                count: count,
                at: indexInBatch,
                batch: .array([picture])
            )
        }
        
        batches.replaceSubrange(batchIndex...batchIndex, with: newBatches)
        updateNumberOfPictures()
    }
    
    func addGenerator(_ generator: PicturesGenerator, count: Int, at index: Int? = nil) {
        let numberOfPictures = numberOfPictures
        
        let index = index.flatMap {
            min(numberOfPictures, max($0, 0))
        } ?? numberOfPictures
        
        let generatorBatch: Batch = .generator(generator, start: 0, count: count)
        
        if index == numberOfPictures {
            batches.append(generatorBatch)
            updateNumberOfPictures()
            return
        }
        
        guard let (batchIndex, start) = getBatchIndex(for: index) else { return }

        let batch = batches[batchIndex]
        let indexInBatch = index - start
        
        let newBatches: [Batch]
        
        switch batch {
        case let .array(pictures):
            newBatches = [
                .array(Array(pictures[0..<indexInBatch])),
                generatorBatch,
                .array(Array(pictures[indexInBatch...]))
            ].filter { $0.count > 0 }
        case let .generator(generator, startIndex, count):
            newBatches = divideGeneratorBatchWithInsertion(
                generator: generator,
                start: startIndex,
                count: count,
                at: indexInBatch,
                batch: generatorBatch
            )
        }
        
        batches.replaceSubrange(batchIndex...batchIndex, with: newBatches)
        updateNumberOfPictures()
    }
    
    func removePicture(at index: Int) {
        removeRange(range: index..<(index + 1))
    }
    
    func removeRange(range: Range<Int>) {
        let numberOfPictures = numberOfPictures
        guard numberOfPictures > 0 else { return }
        
        let startIndex = max(range.lowerBound, 0)
        let endIndex = min(range.upperBound, numberOfPictures)
        
        guard
            let (startBatchIndex, startBatchIndexStart) = getBatchIndex(for: startIndex),
            let (endBatchIndex, endBatchIndexStart) = getBatchIndex(for: endIndex - 1)
        else { return }
        
        let newBatches: [Batch]
        
        if startBatchIndex == endBatchIndex {
            let startIndexInBatch = startIndex - startBatchIndexStart
            let endIndexInBatch = endIndex - startBatchIndexStart
            newBatches = batches[startBatchIndex].cutting(range: startIndexInBatch..<endIndexInBatch)
        } else {
            let startIndexInStartBatch = startIndex - startBatchIndexStart
            let endIndexInStartBatch = endIndex - startBatchIndexStart
            
            let startIndexInEndBatch = startIndex - endBatchIndexStart
            let endIndexInEndBatch = endIndex - endBatchIndexStart
            
            newBatches = batches[startBatchIndex].cutting(
                range: startIndexInStartBatch..<endIndexInStartBatch
            ) + batches[endBatchIndex].cutting(
                range: startIndexInEndBatch..<endIndexInEndBatch
            )
        }
        
        batches.replaceSubrange(startBatchIndex...endBatchIndex, with: newBatches)
        updateNumberOfPictures()

        assert(self.numberOfPictures == numberOfPictures - (endIndex - startIndex))
    }
    
    private func getBatchIndex(for index: Int) -> (index: Int, start: Int)? {
        var start = 0
        
        let index = batches.firstIndex {
            let end: Int
            
            switch $0 {
            case let .array(array):
                end = start + array.count
            case let .generator(_, _, count):
                end = start + count
            }
            
            if index >= start && index < end {
                return true
            } else {
                start = end
                return false
            }
        }
        
        return index.flatMap { (index: $0, start: start) }
    }
    
    private func divideGeneratorBatchWithReplacing(
        generator: PicturesGenerator,
        start: Int,
        count: Int,
        at offset: Int,
        batch: Batch
    ) -> [Batch] {
        let leftBatch: Batch = .generator(generator, start: start, count: offset)
        let rightBatch: Batch = .generator(generator, start: start + offset + 1, count: count - offset - 1)
        return [leftBatch, batch, rightBatch].filter { $0.count > 0 }
    }
    
    private func divideGeneratorBatchWithInsertion(
        generator: PicturesGenerator,
        start: Int,
        count: Int,
        at offset: Int,
        batch: Batch
    ) -> [Batch] {
        let leftBatch: Batch = .generator(generator, start: start, count: offset)
        let rightBatch: Batch = .generator(generator, start: start + offset, count: count - offset)
        return [leftBatch, batch, rightBatch].filter { $0.count > 0 }
    }
    
    private func divideGeneratorBatchWithRemoving(
        generator: PicturesGenerator,
        start: Int,
        count: Int,
        at offset: Int
    ) -> [Batch] {
        let leftBatch: Batch = .generator(generator, start: start, count: offset)
        let rightBatch: Batch = .generator(generator, start: start + offset + 1, count: count - offset - 1)
        return [leftBatch, rightBatch].filter { $0.count > 0 }
    }
    
    private func updateNumberOfPictures() {
        numberOfPictures = batches.reduce(0) { $0 + $1.count }
    }
}

final class PictureModel: Equatable {
    
    enum DrawAction {
        struct CurveModel {
            let width: CGFloat
            let points: [CGPoint]
        }
        
        struct CircleModel {
            let center: CGPoint
            let radius: CGFloat
            let color: UIColor
            let width: CGFloat
        }
        
        case pencil(CurveModel, UIColor)
        case erase(CurveModel)
        case circle(CircleModel)
        
        func draw() {
            switch self {
            case let .pencil(curve, color):
                let path = UIBezierPath()
                color.setStroke()
                path.lineWidth = curve.width
                path.lineCapStyle = .round
                path.lineJoinStyle = .round

                guard let firstPoint = curve.points.first else { return }

                path.move(to: firstPoint)
                curve.points.forEach {
                    path.addLine(to: $0)
                }

                path.stroke()
            case let .erase(curve):
                let path = UIBezierPath()
                path.lineWidth = curve.width
                path.lineCapStyle = .round
                path.lineJoinStyle = .round

                guard let firstPoint = curve.points.first else { return }

                path.move(to: firstPoint)
                curve.points.forEach {
                    path.addLine(to: $0)
                }

                path.stroke(with: .clear, alpha: 1)
            case let .circle(model):
                model.color.setStroke()

                let path = UIBezierPath()
                path.lineWidth = model.width
                path.lineCapStyle = .round
                path.lineJoinStyle = .round
                
                path.addArc(
                    withCenter: model.center,
                    radius: model.radius,
                    startAngle: 0,
                    endAngle: 2 * .pi,
                    clockwise: true
                )
                
                path.stroke()
            }
        }
    }
    
    private let size: CGSize
    private(set) var drawActionsSequence: [DrawAction] = []
    
    var isEmpty: Bool { drawActionsSequence.isEmpty }
    
    init(size: CGSize) {
        self.size = size
    }
    
    func removeLastAction() {
        guard !drawActionsSequence.isEmpty else { return }
        drawActionsSequence.removeLast()
    }
    
    func appendAction(_ action: DrawAction) {
        drawActionsSequence.append(action)
    }
    
    func getImage() -> UIImage {
        UIGraphicsImageRenderer(size: size).image { _ in
            drawActionsSequence.forEach { $0.draw() }
        }
    }
    
    static func == (lhs: PictureModel, rhs: PictureModel) -> Bool {
        lhs === rhs
    }
}
