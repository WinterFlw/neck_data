import SwiftUI
import ActivityKit

struct SittingView: View {
    @StateObject private var logger = MotionLogger()

    var body: some View {
        VStack(spacing: 20) {
            Text("앉기 모드")
                .font(.largeTitle).bold()

            // ───────────────────────────────────
            // 실시간 각도 & 경과시간 표시
            VStack(spacing: 8) {
                Text("Pitch: \(logger.pitchAngle, specifier: "%.1f")°")
                Text("Roll:  \(logger.rollAngle,  specifier: "%.1f")°")
                Text("Yaw:   \(logger.yawAngle,   specifier: "%.1f")°")
                Text("타이머: \(logger.elapsedTime, specifier: "%.0f")초")
            }
            .font(.headline)
            // ───────────────────────────────────

            // 연결 상태 표시
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

            // 시작 / 중지 버튼
            Button {
                logger.toggleLogging(isWalking: false)
            } label: {
                Text(logger.isRunning ? "중지" : "시작")
                    .font(.title2)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(logger.isRunning ? Color.red : Color.blue)
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

