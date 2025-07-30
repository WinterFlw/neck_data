import SwiftUI
import ActivityKit

struct WalkingView: View {
    @StateObject private var logger = MotionLogger()

    var body: some View {
        VStack(spacing: 20) {
            Text("걷기 모드")
                .font(.largeTitle).bold()

            VStack(spacing: 8) {
                Text("Pitch: \(logger.pitchAngle, specifier: "%.1f")°")
                Text("Roll:  \(logger.rollAngle,  specifier: "%.1f")°")
                Text("Yaw:   \(logger.yawAngle,   specifier: "%.1f")°")
                Text("타이머: \(logger.elapsedTime, specifier: "%.0f")초")
            }
            .font(.headline)

            if !logger.motionAvailableChecked {
                Text("연결 상태 확인 중…").font(.subheadline)
            } else if !logger.isDeviceMotionAvailable {
                Text("모션 하드웨어 미지원").font(.subheadline)
            } else if logger.isAirpodsConnected {
                Text("에어팟 연결됨")
                    .font(.subheadline).foregroundColor(.green)
            } else {
                Text("에어팟 연결 안됨")
                    .font(.subheadline).foregroundColor(.red)
            }

            Button {
                logger.toggleLogging(isWalking: true)
            } label: {
                Text(logger.isRunning ? "중지" : "시작")
                    .font(.title2)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(logger.isRunning ? Color.red : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding()
        .onAppear {
            logger.checkDeviceMotionAvailable()
        }
    }
}


