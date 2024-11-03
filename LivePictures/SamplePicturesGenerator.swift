//
//  SamplePicturesGenerator.swift
//  LivePictures
//
//  Created by Владислав Матковский on 30.10.2024.
//

import UIKit

protocol PicturesGenerator {
    func getPicture(at index: Int) -> PictureModel
}

final class SamplePicturesGenerator: PicturesGenerator {
    
    private let frameSize: CGSize
    private let noiseX = PerlinNoise1D()
    private let noiseY = PerlinNoise1D()
    private let noiseR = PerlinNoise1D()
    private let randomString: String = UUID().uuidString
    
    init(frameSize: CGSize) {
        self.frameSize = frameSize
    }
    
    func getPicture(at index: Int) -> PictureModel {
        let picture = PictureModel(size: frameSize)
        let noiseL = PerlinNoise1D(seed: "\(randomString)_\(index)_CL")
        
        let center = CGPoint(
            x: (noiseX.octaveNoise(x: CGFloat(index) / 100, octaves: 4, persistence: 3)) * frameSize.width,
            y: (noiseY.octaveNoise(x: CGFloat(index) / 100, octaves: 4, persistence: 3)) * frameSize.height
        )
        
        let radius = 10 + CGFloat(noiseR.octaveNoise(x: CGFloat(index) / 100, octaves: 4, persistence: 3)) * 90
        
        picture.appendAction(.pencil(.init(
            width: 10,
            points: generateCirclePoints(radius: radius, noise: noiseL).map {
                .init(
                    x: $0.x + center.x,
                    y: $0.y + center.y
                )
            }
        ), .systemBlue))
        return picture
    }
    
    private func generateCirclePoints(radius: CGFloat, noise: PerlinNoise1D) -> [CGPoint] {
        let pointsCount = Int(radius)
        let angleStep: CGFloat = .pi / CGFloat(pointsCount) * 2
        
        let indexOffset = noise.octaveNoise(x: 0.5, octaves: 4, persistence: 1) * CGFloat(pointsCount)
        
        return (0..<pointsCount).map { index in
            
            let noisedRadius = radius + noise.octaveNoise(x: CGFloat(index) / 20, octaves: 4, persistence: 1) * 20
            
            return .init(
                x: noisedRadius * cos(angleStep * (CGFloat(index) + indexOffset)),
                y: noisedRadius * sin(angleStep * (CGFloat(index) + indexOffset))
            )
        }
    }
}
