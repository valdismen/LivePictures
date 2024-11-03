//
//  PerlinNoise1D.swift
//  LivePictures
//
//  Created by Владислав Матковский on 30.10.2024.
//

import UIKit

final class PerlinNoise1D {

    private var permutation: [Int] = []
    
    init(seed: String = UUID().uuidString) {
        let hash = seed.hash
        srand48(hash)
        
        for _ in 0..<512 {
            permutation.append(Int(drand48() * 255))
        }
    }
    
    private func lerp(a: CGFloat, b: CGFloat, x: CGFloat) -> CGFloat {
        a + x * (b - a)
    }
    
    private func fade(_ t: CGFloat) -> CGFloat {
        t * t * t * (t * (t * 6 - 15) + 10)
    }
    
    private func grad(hash: Int, x: CGFloat) -> CGFloat {
        hash & 1 == 0 ? x : -x
    }
    
    private func floor(_ x: CGFloat) -> Int {
        return x > 0 ? Int(x) : Int(x - 1)
    }
    
    func noise(x: CGFloat) -> CGFloat {
        var xi = floor(x)
        let xf = x - CGFloat(xi)
        
        xi = xi & 255

        let u = fade(xf)
        
        let a = permutation[xi]
        let b = permutation[xi + 1]
        
        let ab = lerp(a: grad(hash: a, x: xf), b: grad(hash: b, x: xf - 1), x: u)
        
        return (ab + 1) / 2
    }
    
    func octaveNoise(x: CGFloat, octaves: Int, persistence: CGFloat) -> CGFloat {
        
        var total: CGFloat = 0
        var frequency: CGFloat = 1
        var amplitude: CGFloat = 1
        var maxValue: CGFloat = 0
        
        for _ in 0..<octaves {
            total += noise(x: x * frequency) * amplitude
            
            maxValue += amplitude
            
            amplitude *= persistence
            frequency *= 2
        }
        
        return total / maxValue
    }
}
