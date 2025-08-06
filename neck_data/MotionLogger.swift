import Foundation
import CoreMotion
import AVFoundation
import ActivityKit
import UIKit

class MotionLogger: ObservableObject {
    private let motionManager = CMHeadphoneMotionManager()
    private var uiTimer: Timer?
    private var liveActivityTimer: Timer?   // ✅ Live Activity 수동 타이머 추가
    private var activity: Activity<HeadTrackingAttributes>?
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?

    // MARK: — Published Properties
    @Published var isRunning = false
    @Published var isWalking = false
    @Published var isDeviceMotionAvailable = false
    @Published var motionAvailableChecked = false
    @Published var isAirpodsConnected = false
    @Published var elapsedTime: TimeInterval = 0
    @Published var pitchAngle: Double = 0
    @Published var rollAngle:  Double = 0
    @Published var yawAngle:   Double = 0

    // MARK: — Public API

    /// AirPods/모션 지원 확인
    func checkDeviceMotionAvailable() {
        isDeviceMotionAvailable = motionManager.isDeviceMotionAvailable
        let session = AVAudioSession.sharedInstance()
        try? session.setActive(true)
        isAirpodsConnected = session.currentRoute.outputs.contains {
            [.bluetoothA2DP, .bluetoothHFP, .bluetoothLE].contains($0.portType)
        }
        motionAvailableChecked = true
    }

    /// 시작/중지 토글 (앉기/걷기 모드)
    func toggleLogging(isWalking: Bool) {
        self.isWalking = isWalking
        isRunning ? stopLogging() : startLogging()
    }

    // MARK: — Start / Stop

    private func startLogging() {
        guard motionManager.isDeviceMotionAvailable, isAirpodsConnected else {
            print("Error: AirPods 연결 또는 모션 미지원")
            return
        }

        isRunning = true
        elapsedTime = 0

        startBackgroundAudio()
        requestLiveActivity()

        // 1) 모션 업데이트 시작 (Live Activity 갱신은 제거됨)
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self = self, let m = motion else { return }
            self.pitchAngle = m.attitude.pitch * 180.0 / .pi
            self.rollAngle  = m.attitude.roll  * 180.0 / .pi
            self.yawAngle   = m.attitude.yaw   * 180.0 / .pi
        }

        // 2) UI용 타이머 (경과 시간용)
        uiTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.elapsedTime += 1
        }

        // 3) ✅ Live Activity 갱신용 수동 타이머
        liveActivityTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.updateLiveActivity()
        }
    }

    private func stopLogging() {
        isRunning = false

        motionManager.stopDeviceMotionUpdates()
        uiTimer?.invalidate()
        liveActivityTimer?.invalidate() // ✅ Live Activity 타이머 정리
        stopBackgroundAudio()

        Task {
            let finalState = HeadTrackingAttributes.ContentState(
                pitch: pitchAngle, roll: rollAngle, yaw: yawAngle
            )
            let finalContent = ActivityContent(state: finalState, staleDate: nil)
            await activity?.end(finalContent, dismissalPolicy: .immediate)
            print("⏹️ Live Activity 종료")
            activity = nil
        }
    }

    // MARK: — Live Activity

    private func requestLiveActivity() {
        let attrs = HeadTrackingAttributes(mode: isWalking ? "walking" : "sitting")
        let initState = HeadTrackingAttributes.ContentState(
            pitch: pitchAngle,
            roll:  rollAngle,
            yaw:   yawAngle
        )
        let initialContent = ActivityContent(
            state: initState,
            staleDate: Date().addingTimeInterval(4 * 3600)
        )

        Task {
            do {
                let act = try Activity<HeadTrackingAttributes>.request(
                    attributes: attrs,
                    content: initialContent,
                    pushType: nil
                )
                self.activity = act
                print("✅ Live Activity 시작: \(act.id)")

                Task {
                    for await state in act.activityStateUpdates {
                        print("🔔 Activity 상태 변경: \(state)")
                    }
                }

                Task {
                    for await update in act.contentUpdates {
                        print("📥 콘텐츠 업데이트 반영")
                    }
                }

            } catch {
                print("❌ Live Activity 요청 실패:", error)
            }
        }
    }

    private func updateLiveActivity() {
        guard let act = activity else { return }

        print("🔵 Live Activity 업데이트 요청 at \(Date())")

        let newState = HeadTrackingAttributes.ContentState(
            pitch: pitchAngle+Double.random(in: -0.01...0.01),
            roll:  rollAngle,
            yaw:   yawAngle
        )
        let nextStale = Date().addingTimeInterval(3600)
        let content = ActivityContent(state: newState, staleDate: nextStale)

        Task {
            await act.update(content)
            print("✅ Live Activity 실제 갱신 at \(Date())")
        }
    }

    // MARK: — Background Audio

    private func startBackgroundAudio() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("❌ AudioSession 설정 실패:", error)
            return
        }

        let engine = AVAudioEngine()
        let player = AVAudioPlayerNode()
        engine.attach(player)

        let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
        engine.connect(player, to: engine.mainMixerNode, format: format)

        do {
            try engine.start()
        } catch {
            print("❌ AVAudioEngine 시작 실패:", error)
            return
        }

        let durationSec: Double = 10
        let frameCount = AVAudioFrameCount(format.sampleRate * durationSec)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
        buffer.frameLength = frameCount

        player.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
        player.play()

        audioEngine = engine
        playerNode  = player

        print("▶️ AVAudioEngine 백그라운드 오디오 재생 시작")
    }

    private func stopBackgroundAudio() {
        playerNode?.stop()
        audioEngine?.stop()
        audioEngine = nil
        playerNode  = nil
        try? AVAudioSession.sharedInstance().setActive(false)
    }
}

