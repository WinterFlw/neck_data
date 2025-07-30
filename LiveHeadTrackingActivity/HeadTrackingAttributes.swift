//
//  HeadTrackingAttributes.swift
//  neck_data
//
//  Created by 이준수 on 7/3/25.
//

import ActivityKit

struct HeadTrackingAttributes: ActivityAttributes {
  public struct ContentState: Codable, Hashable {
    // 동적으로 바뀌는 상태
    var pitch: Double
    var roll: Double
    var yaw: Double
  }

  // 액티비티 고정 속성
  var mode: String
}
