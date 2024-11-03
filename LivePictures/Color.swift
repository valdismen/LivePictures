//
//  Color.swift
//  LivePictures
//
//  Created by Владислав Матковский on 30.10.2024.
//

import UIKit

enum Color {
    case green
    case actionDefault
    case actionLight
    case gray
    
    var dark: UIColor {
        switch self {
        case .green: return Palette.green
        case .actionDefault: return Palette.white
        case .actionLight: return Palette.white
        case .gray: return Palette.gray
        }
    }
    
    var light: UIColor {
        switch self {
        case .green: return Palette.green
        case .actionDefault: return Palette.black
        case .actionLight: return Palette.white
        case .gray: return Palette.gray
        }
    }

    func color(in view: UIView) -> UIColor {
        view.traitCollection.userInterfaceStyle == .dark ? dark : light
    }
}

private enum Palette {
    static let green = UIColor(
        red: 168 / 255,
        green: 219 / 255,
        blue: 16 / 255,
        alpha: 1
    )
    
    static let white = UIColor.white
    static let black = UIColor.black
    static let gray = UIColor(white: 139 / 255, alpha: 1)
}
