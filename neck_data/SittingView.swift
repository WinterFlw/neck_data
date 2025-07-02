// SwiftUI View 예시은 변경 없이 재사용 가능합니다.
import SwiftUI

struct SittingView: View {
    @StateObject private var logger = MotionLogger()

    var body: some View {
        VStack(spacing: 20) {
            Text("앉기 모드")
                .font(.largeTitle).bold()
            Text("타이머: \(logger.elapsedTime, specifier: "%.0f")초")
                .font(.title2)

            if !logger.motionAvailableChecked {
                Text("연결 상태 확인 중…").font(.headline)
            } else if !logger.isDeviceMotionAvailable {
                Text("모션 하드웨어 미지원").font(.headline)
            } else if logger.isAirpodsConnected {
                Text("에어팟 연결됨")
                    .font(.headline).foregroundColor(.green)
            } else {
                Text("에어팟 연결 안됨")
                    .font(.headline).foregroundColor(.red)
            }

           

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
        .onAppear { logger.checkDeviceMotionAvailable() }
    }
}

