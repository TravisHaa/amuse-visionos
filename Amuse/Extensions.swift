//
//  Extensions.swift
//  Amuse
//
//  Created by TRAVIS HA on 12/27/25.
//

import SwiftUI

/// An extension that provides a way to chunk an array into smaller arrays
extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: self.count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, self.count)])
        }
    }
}
