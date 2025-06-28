import Foundation
import CoreMotion

class MotionLogger: ObservableObject {
    private let motionManager = CMHeadphoneMotionManager()
    private var timer: Timer?
    
    @Published var isRunning = false
    @Published var isDeviceMotionAvailable = false
    @Published var motionAvailableChecked = false
    @Published var elapsedTime: TimeInterval = 0
    
    private var log: [String] = []
    
    func checkDeviceMotionAvailable() {
        isDeviceMotionAvailable = motionManager.isDeviceMotionAvailable
        motionAvailableChecked = true
    }
    
    func toggleLogging(isWalking: Bool) {
        if isRunning {
            stopLogging()
        } else {
            startLogging(isWalking: isWalking)
        }
    }
    
    func startLogging(isWalking: Bool) {
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
                
                if self.motionManager.isDeviceMotionAvailable,
                   let data = self.motionManager.deviceMotion {
                    let r = data.rotationRate
                    row += ",\(r.x),\(r.y),\(r.z)"
                } else {
                    row += ",0,0,0"
                }
                
                if isWalking {
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
    
    func saveCSV() {
        let header = "timestamp,gyroX,gyroY,gyroZ,steps"
        let csv = ([header] + log).joined(separator: "\n")
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent("log_\(Date().timeIntervalSince1970).csv")
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            print("CSV 저장 완료: \(url)")
        } catch {
            print("CSV 저장 실패: \(error)")
        }
    }
}
