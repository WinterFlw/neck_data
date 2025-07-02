import Foundation
import CoreMotion
import AVFoundation
class MotionLogger: ObservableObject {
    private let motionManager = CMHeadphoneMotionManager()
    private var timer: Timer?
    
    @Published var isRunning = false
    @Published var isDeviceMotionAvailable = false
    @Published var motionAvailableChecked = false
    @Published var isAirpodsConnected = false
    @Published var elapsedTime: TimeInterval = 0
    
    private var log: [String] = []
    private var isWalking: Bool = false // 파일명 구분을 위한 변수
    
    /// 실제 연결 상태를 체크하도록 수정
    func checkDeviceMotionAvailable() {
            // 모션 하드웨어 지원 여부
            isDeviceMotionAvailable = motionManager.isDeviceMotionAvailable
            
            // 실제 AirPods 연결 여부 체크
            let session = AVAudioSession.sharedInstance()
            try? session.setActive(true)
            isAirpodsConnected = session.currentRoute.outputs.contains { output in
                [.bluetoothA2DP, .bluetoothHFP, .bluetoothLE].contains(output.portType)
            }
            
            motionAvailableChecked = true
        }
    
    func toggleLogging(isWalking: Bool) {
        self.isWalking = isWalking // Sitting/WalkingView에서 전달해준 상태로 설정
        if isRunning {
            stopLogging()
        } else {
            startLogging()
        }
    }
    
    func startLogging() {
        // deleteCSV() // 기존 csv 파일 삭제. 필요하면 주석 해제
        if !motionManager.isDeviceMotionAvailable {
            print("에어팟 연결 안됨. 데이터 수집 불가.")
        }
        
        isRunning = true
        elapsedTime = 0
        log = []
        
        if motionManager.isDeviceMotionAvailable {
            motionManager.startDeviceMotionUpdates(to: .main) { _, error in
                if let error = error {
                    print("Motion Error: \(error)")
                }
            }
        }
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { t in
            self.elapsedTime += 1
            
            if Int(self.elapsedTime) % 10 == 0 {
                var row = "\(Date().timeIntervalSince1970)"
                
                if self.motionManager.isDeviceMotionAvailable {
                    if let data = self.motionManager.deviceMotion {
                        let r = data.rotationRate
                        row += ",\(r.x),\(r.y),\(r.z)"
                    } else {
                        row += ",0,0,0"
                    }
                }
                if self.isWalking {
                    row += ",0" // 걷기 데이터 자리
                }
                
                self.log.append(row)
            }
        }
    }
    
    func stopLogging() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        motionManager.stopDeviceMotionUpdates()
        saveCSV()
    }
    
    private func saveCSV() {
            // 헤더 포함
            let header = "timestamp,gyroX,gyroY,gyroZ,neckAngle,mode"
            let content = ([header] + log).joined(separator: "\n")

            // 파일 이름: 모드와 날짜
            let type = isWalking ? "walking" : "sitting"
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyyMMdd_HHmmss"
            let filename = "log_\(type)_\(formatter.string(from: Date())).csv"

            // Documents 디렉터리에 저장
            let url = FileManager.default
                .urls(for: .documentDirectory, in: .userDomainMask)[0]
                .appendingPathComponent(filename)
            do {
                try content.write(to: url, atomically: true, encoding: .utf8)
                print("CSV 저장 완료: \(url)")
            } catch {
                print("CSV 저장 실패: \(error)")
            }
        }
    // 저장된 경로의 csv 파일 모두 삭제 함수. 필요하면 사용

}
