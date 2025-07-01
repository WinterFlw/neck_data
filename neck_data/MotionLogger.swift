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
    private var isWalking: Bool = false // 파일명 구분을 위한 변수
    
    func checkDeviceMotionAvailable() {
        isDeviceMotionAvailable = motionManager.isDeviceMotionAvailable
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
    
    func saveCSV() {
        let header = "timestamp,gyroX,gyroY,gyroZ,steps"
        let csv = ([header] + log).joined(separator: "\n")

        let type = isWalking ? "walking" : "sitting"
        let filename = "log_\(type)_\(Date().timeIntervalSince1970).csv"

        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
            .appendingPathComponent(filename)
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            print("CSV 저장 완료: \(url)")
        } catch {
            print("CSV 저장 실패: \(error)")
        }
    }
    
    // 저장된 경로의 csv 파일 모두 삭제 함수. 필요하면 사용
    func deleteCSV() {
        let fileManager = FileManager.default
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!

        do {
            let fileURLs = try fileManager.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil)
            for fileURL in fileURLs {
                if fileURL.pathExtension == "csv" {
                    try fileManager.removeItem(at: fileURL)
                    print("삭제된 CSV 파일: \(fileURL.lastPathComponent)")
                }
            }
        } catch {
            print("CSV 파일 삭제 실패: \(error)")
        }
    }

}
