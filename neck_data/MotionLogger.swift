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
    @Published var pitchAngle: Double = 0.0
    @Published var rollAngle: Double = 0.0
    @Published var yawAngle: Double = 0.0
    private var lastLogTime: TimeInterval?
    
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
    
    //    func startLogging() { //각도값만 계산
    //        // deleteCSV() // 기존 csv 파일 삭제. 필요하면 주석 해제
    //        if !motionManager.isDeviceMotionAvailable {
    //            print("에어팟 연결 안됨. 데이터 수집 불가.")
    //        }
    //
    //        isRunning = true
    //        elapsedTime = 0
    //        log = []
    //
    //        if motionManager.isDeviceMotionAvailable {
    //            motionManager.startDeviceMotionUpdates(to: .main) { _, error in
    //                if let error = error {
    //                    print("Motion Error: \(error)")
    //                }
    //            }
    //        }
    //
    //        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { t in
    //            self.elapsedTime += 1
    //
    //            if Int(self.elapsedTime) % 10 == 0 {
    //                var row = "\(Date().timeIntervalSince1970)"
    //
    //                if self.motionManager.isDeviceMotionAvailable {
    //                    if let data = self.motionManager.deviceMotion {
    //                        let r = data.rotationRate
    //                        row += ",\(r.x),\(r.y),\(r.z)"
    //                    } else {
    //                        row += ",0,0,0"
    //                    }
    //                }
    //                if self.isWalking {
    //                    row += ",0" // 걷기 데이터 자리
    //                }
    //
    //                self.log.append(row)
    //            }
    //        }
    //    }
    //    func startLogging() { 머리각도까지 계산
    //            guard motionManager.isDeviceMotionAvailable && isAirpodsConnected else {
    //                print("Error: AirPods 연결 및 헤드폰 모션 미지원")
    //                return
    //            }
    //            isRunning = true
    //            elapsedTime = 0
    //            log.removeAll()
    //
    //            motionManager.startDeviceMotionUpdates(
    //                to: OperationQueue.main,
    //                withHandler: { [weak self] (motion: CMDeviceMotion?, error: Error?) in
    //                    guard let self = self, let motion = motion else {
    //                        if let err = error { print("Motion Error: \(err.localizedDescription)") }
    //                        return
    //                    }
    //                    let attitude = motion.attitude
    //                    self.pitchAngle = attitude.pitch * 180.0 / .pi
    //                    self.rollAngle  = attitude.roll  * 180.0 / .pi
    //                    self.yawAngle   = attitude.yaw   * 180.0 / .pi
    //
    //                    let ts = Date().timeIntervalSince1970
    //                    let r = motion.rotationRate
    //                    let mode = self.isWalking ? "walking" : "sitting"
    //                    // 수정된 포맷: ts, gyroX, gyroY, gyroZ, pitch, roll, yaw, mode
    //                    let row = String(format: "%.3f,%.3f,%.3f,%.3f,%.1f,%.1f,%.1f,%@",
    //                                     ts,
    //                                     r.x, r.y, r.z,
    //                                     self.pitchAngle,
    //                                     self.rollAngle,
    //                                     self.yawAngle,
    //                                     mode)
    //                    self.log.append(row)
    //                }
    //            )
    //
    //            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
    //                self?.elapsedTime += 1
    //            }
    //        }
    func startLogging() {
        guard motionManager.isDeviceMotionAvailable && isAirpodsConnected else {
            print("Error: AirPods 연결 및 헤드폰 모션 미지원")
            return
        }
        isRunning = true
        elapsedTime = 0
        log.removeAll()
        lastLogTime = nil
        
        motionManager.startDeviceMotionUpdates(
            to: OperationQueue.main,
            withHandler: { [weak self] (motion: CMDeviceMotion?, error: Error?) in
                guard let self = self, let motion = motion else {
                    if let err = error { print("Motion Error: \(err.localizedDescription)") }
                    return
                }
                // update angles
                let attitude = motion.attitude
                self.pitchAngle = attitude.pitch * 180.0 / .pi
                self.rollAngle  = attitude.roll  * 180.0 / .pi
                self.yawAngle   = attitude.yaw   * 180.0 / .pi
                
                let ts = Date().timeIntervalSince1970
                // log only every 15 seconds
                if let last = self.lastLogTime {
                    if ts - last < 1 { return }
                }
                self.lastLogTime = ts
                
                let r = motion.rotationRate
                let mode = self.isWalking ? "walking" : "sitting"
                let row = String(format: "%.3f,%.3f,%.3f,%.3f,%.1f,%.1f,%.1f,%@",
                                 ts,
                                 r.x, r.y, r.z,
                                 self.pitchAngle,
                                 self.rollAngle,
                                 self.yawAngle,
                                 mode)
                self.log.append(row)
            }
        )
        
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
                    self?.elapsedTime += 1
                }
    }
    
    func stopLogging() {
        isRunning = false
        timer?.invalidate()
        timer = nil
        motionManager.stopDeviceMotionUpdates()
        saveCSV()
    }
    
    ////    private func saveCSV() {
    ////            // 헤더 포함
    ////            let header = "timestamp,gyroX,gyroY,gyroZ,neckAngle,mode"
    ////            let content = ([header] + log).joined(separator: "\n")
    ////
    ////            // 파일 이름: 모드와 날짜
    ////            let type = isWalking ? "walking" : "sitting"
    ////            let formatter = DateFormatter()
    ////            formatter.dateFormat = "yyyyMMdd_HHmmss"
    ////            let filename = "log_\(type)_\(formatter.string(from: Date())).csv"
    ////
    ////            // Documents 디렉터리에 저장
    ////            let url = FileManager.default
    ////                .urls(for: .documentDirectory, in: .userDomainMask)[0]
    ////                .appendingPathComponent(filename)
    ////            do {
    ////                try content.write(to: url, atomically: true, encoding: .utf8)
    ////                print("CSV 저장 완료: \(url)")
    ////            } catch {
    ////                print("CSV 저장 실패: \(error)")
    ////            }
    ////        }
    //    // 저장된 경로의 csv 파일 모두 삭제 함수. 필요하면 사용
    //
    //}
    private func saveCSV() {
        let header = "timestamp,gyroX,gyroY,gyroZ,pitch,roll,yaw,mode"
        // 로그 문자열을 정렬하여 시간순 보장
        let sortedLog = log.sorted()
        let content = ([header] + sortedLog).joined(separator: "\n")

        // 파일명에 날짜 포함 (yyyyMMdd_HHmmss)
        let type = isWalking ? "walking" : "sitting"
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let filename = "headlog_\(type)_\(formatter.string(from: Date())).csv"

        let url = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent(filename)
        do {
            try content.write(to: url, atomically: true, encoding: .utf8)
            print("CSV saved: \(url)")
        } catch {
            print("Failed to save CSV: \(error)")
        }
    }
}
