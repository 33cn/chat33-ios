//
//  Float+Tool.swift
//  IMSDK
//
//  Created by .. on 2019/12/11.
//

import Foundation

extension Float {
      func roundTo(places: Int, _ rule: FloatingPointRoundingRule?) -> Float {
        let divisor = Float(powf(10, Float(places)))
        return (self * divisor).rounded(rule ?? .toNearestOrAwayFromZero) / divisor
    }
}
