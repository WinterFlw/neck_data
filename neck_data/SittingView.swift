import SwiftUI

struct SittingView: View {
    @StateObject private var logger = MotionLogger()
    
    var body: some View {
        VStack(spacing: 20) {
            Text("앉기 모드")
                .font(.largeTitle)
                .bold()
            
            Text("타이머: \(logger.elapsedTime, specifier: "%.0f")초")
                .font(.title2)
            
            if logger.motionAvailableChecked {
                Text(logger.isDeviceMotionAvailable ? "에어팟 연결됨" : "에어팟 연결 안됨")
                    .foregroundColor(logger.isDeviceMotionAvailable ? .green : .red)
                    .font(.headline)
            } else {
                Text("에어팟 상태 확인 중...")
            }
            
            Button(action: {
                logger.toggleLogging(isWalking: false)
            }) {
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
