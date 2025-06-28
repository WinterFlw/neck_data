//
//  Item.swift
//  neck_data
//
//  Created by 겨울꽃 on 6/28/25.
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
