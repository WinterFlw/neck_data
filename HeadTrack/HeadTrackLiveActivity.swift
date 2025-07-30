// LiveHeadTrackingActivity.swift

import ActivityKit
import WidgetKit
import SwiftUI

// 1) Attributes 정의
public struct HeadTrackingAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var pitch: Double
        var roll:  Double
        var yaw:   Double
    }
    // 모드 구분(앉기/걷기)
    public var mode: String
}

// 2) Live Activity 위젯 선언


struct HeadTrackLiveActivity: Widget {
  var body: some WidgetConfiguration {
    ActivityConfiguration(for: HeadTrackingAttributes.self) { context in
      // Lock screen / Banner
      VStack(spacing: 8) {
        Text("Mode: \(context.attributes.mode.capitalized)")
        HStack {
          Text("P: \(context.state.pitch, specifier: "%.1f")°")
          Text("R: \(context.state.roll,  specifier: "%.1f")°")
          Text("Y: \(context.state.yaw,   specifier: "%.1f")°")
        }
      }
      .activityBackgroundTint(.black)
      .activitySystemActionForegroundColor(.white)
    } dynamicIsland: { context in
      DynamicIsland {
        DynamicIslandExpandedRegion(.leading) {
          Text("P:\(context.state.pitch, specifier: "%.0f")°")
        }
        DynamicIslandExpandedRegion(.trailing) {
          Text("R:\(context.state.roll, specifier: "%.0f")°")
        }
        DynamicIslandExpandedRegion(.bottom) {
          Text("Y:\(context.state.yaw, specifier: "%.0f")°")
        }
      } compactLeading: {
        Text("\(context.state.pitch, specifier: "%.0f")°")
      } compactTrailing: {
        Text("\(context.state.roll, specifier: "%.0f")°")
      } minimal: {
        Text("🎧")
      }
      .widgetURL(URL(string: "yourapp://headtracking"))
      .keylineTint(.yellow)
    }
  }
}

