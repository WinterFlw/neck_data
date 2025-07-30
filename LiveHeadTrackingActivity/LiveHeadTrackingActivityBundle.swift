//
//  LiveHeadTrackingActivityBundle.swift
//  LiveHeadTrackingActivity
//
//  Created by 이준수 on 7/3/25.
//

import WidgetKit
import SwiftUI

@main
struct LiveHeadTrackingActivityBundle: WidgetBundle {
    var body: some Widget {
        LiveHeadTrackingActivity()
        LiveHeadTrackingActivityControl()
        LiveHeadTrackingActivityLiveActivity()
    }
}
