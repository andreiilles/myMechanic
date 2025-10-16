//
//  Item.swift
//  myMechanic
//
//  Created by Andrei Illes on 16.10.2025.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
