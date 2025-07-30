import Foundation
import CoreMotion
import AVFoundation
import ActivityKit
import UIKit

class MotionLogger: ObservableObject {
    private let motionManager = CMHeadphoneMotionManager()
    private var uiTimer: Timer?
    private var activity: Activity<HeadTrackingAttributes>?
    private var lastActivityUpdate: TimeInterval = 0
    private var audioEngine: AVAudioEngine?
    private var playerNode: AVAudioPlayerNode?
    
    /// 마지막 라이브업데이트 타임스탬프
    private var lastLiveUpdate: TimeInterval = 0

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
        lastLiveUpdate = 0

        // 1) 백그라운드 오디오 재생 (백그라운드 모션 유지용)
        startBackgroundAudio()

        // 2) Live Activity 요청
        requestLiveActivity()

        // 3) 모션 업데이트 → 5초 단위로만 Live Activity 갱신
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self = self, let m = motion else { return }
            // 각도 계산
            self.pitchAngle = m.attitude.pitch * 180.0 / .pi
            self.rollAngle  = m.attitude.roll  * 180.0 / .pi
            self.yawAngle   = m.attitude.yaw   * 180.0 / .pi
            
            // 5초 쓰로틀
            let now = Date().timeIntervalSinceReferenceDate
            if now - self.lastLiveUpdate >= 1 {
                self.lastLiveUpdate = now
                self.updateLiveActivity()
            }
        }

        // 4) UI용 타이머 (elapsedTime 업데이트 전용)
        uiTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.elapsedTime += 1
        }
    }

    private func stopLogging() {
        isRunning = false

        // 모션/타이머/오디오 정리
        motionManager.stopDeviceMotionUpdates()
        uiTimer?.invalidate()
        stopBackgroundAudio()

        // Live Activity 종료
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
        // 1) Attributes 와 초기 상태 생성
        let attrs = HeadTrackingAttributes(mode: isWalking ? "walking" : "sitting")
        let initState = HeadTrackingAttributes.ContentState(
            pitch: pitchAngle,
            roll:  rollAngle,
            yaw:   yawAngle
        )
        // 이름을 initialContent 로 변경
        let initialContent = ActivityContent(
            state: initState,
            staleDate: Date().addingTimeInterval(4 * 3600)
        )

        Task {
            do {
                // 2) Live Activity 요청
                let act = try Activity<HeadTrackingAttributes>.request(
                    attributes: attrs,
                    content: initialContent,
                    pushType: nil
                )
                self.activity = act
                print("✅ Live Activity 시작: \(act.id)")

                // 3) 액티비티 상태 변경 로그
                Task {
                    for await state in act.activityStateUpdates {
                        print("🔔 Activity 상태 변경: \(state)")
                    }
                }

                // 4) 콘텐츠 업데이트 반영 로그
                Task {
                    for await update in act.contentUpdates {
                        let s = update.state
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

            let now = Date().timeIntervalSince1970
            // 마지막 갱신 후 1초가 지나지 않았다면 무시
            guard now - lastActivityUpdate >= 1 else { return }
            lastActivityUpdate = now

            print("🔵 Live Activity 업데이트 요청 at \(Date())")
            let newState = HeadTrackingAttributes.ContentState(
                pitch: pitchAngle,
                roll:  rollAngle,
                yaw:   yawAngle
            )
            let nextStale = Date().addingTimeInterval(4*3600)
            let content = ActivityContent(state: newState, staleDate: nextStale)

            Task {
                await act.update(content)
                print("✅ Live Activity 실제 갱신 at \(Date())")
            }
        }

    // MARK: — Background Audio

    private func startBackgroundAudio() {
      // 1) 세션 세팅
      let session = AVAudioSession.sharedInstance()
      do {
        try session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try session.setActive(true)
      } catch {
        print("❌ AudioSession 설정 실패:", error)
        return
      }

      // 2) 엔진/플레이어 생성
      let engine = AVAudioEngine()
      let player = AVAudioPlayerNode()
      engine.attach(player)

      // 모노, 44.1kHz 포맷
      let format = AVAudioFormat(standardFormatWithSampleRate: 44_100, channels: 1)!
      engine.connect(player, to: engine.mainMixerNode, format: format)

      do {
        try engine.start()
      } catch {
        print("❌ AVAudioEngine 시작 실패:", error)
        return
      }

      // 3) 완전 무음 PCM 버퍼 (10초 분량)
      let durationSec: Double = 10
      let frameCount = AVAudioFrameCount(format.sampleRate * durationSec)
      guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else { return }
      buffer.frameLength = frameCount

      // 4) 무한 루프 스케줄
      player.scheduleBuffer(buffer, at: nil, options: .loops, completionHandler: nil)
      player.play()

      // 5) 레퍼런스 저장
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

