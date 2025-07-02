/// SwiftUI 예시 뷰: 실시간 머리 각도 표시
import SwiftUI
struct HeadView: View {
    @StateObject private var logger = MotionLogger()

    var body: some View {
        VStack(spacing: 16) {
            Text("Head Tracking")
                .font(.largeTitle).bold()
            if !logger.motionAvailableChecked {
                Text("Checking connection...")
            } else if !logger.isAirpodsConnected {
                Text("AirPods not connected").foregroundColor(.red)
            } else {
                VStack(spacing: 8) {
                    Text("Pitch: \(logger.pitchAngle, specifier: "%.1f")°")
                    Text("Roll:  \(logger.rollAngle,  specifier: "%.1f")°")
                    Text("Yaw:   \(logger.yawAngle,   specifier: "%.1f")°")
                }
                .font(.title2)
            }
            Button(logger.isRunning ? "Stop" : "Start") {
                logger.toggleLogging(isWalking: false)
            }
            .padding().background(logger.isRunning ? Color.red : Color.blue)
            .foregroundColor(.white).cornerRadius(8)
        }
        .padding()
        .onAppear { logger.checkDeviceMotionAvailable() }
    }
}


