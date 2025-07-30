//
//  LiveHeadTrackingActivityLiveActivity.swift
//  LiveHeadTrackingActivity
//
//  Created by 이준수 on 7/3/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct LiveHeadTrackingActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct LiveHeadTrackingActivityLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: LiveHeadTrackingActivityAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension LiveHeadTrackingActivityAttributes {
    fileprivate static var preview: LiveHeadTrackingActivityAttributes {
        LiveHeadTrackingActivityAttributes(name: "World")
    }
}

extension LiveHeadTrackingActivityAttributes.ContentState {
    fileprivate static var smiley: LiveHeadTrackingActivityAttributes.ContentState {
        LiveHeadTrackingActivityAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: LiveHeadTrackingActivityAttributes.ContentState {
         LiveHeadTrackingActivityAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: LiveHeadTrackingActivityAttributes.preview) {
   LiveHeadTrackingActivityLiveActivity()
} contentStates: {
    LiveHeadTrackingActivityAttributes.ContentState.smiley
    LiveHeadTrackingActivityAttributes.ContentState.starEyes
}
