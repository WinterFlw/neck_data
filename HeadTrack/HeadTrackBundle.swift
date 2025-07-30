//
//  HeadTrackBundle.swift
//  HeadTrack
//
//  Created by 이준수 on 7/24/25.
//

import WidgetKit
import SwiftUI

@main
struct HeadTrackBundle: WidgetBundle {
    var body: some Widget {
        HeadTrackControl()
        HeadTrackLiveActivity()
    }
}
