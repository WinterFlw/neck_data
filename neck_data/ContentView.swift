import SwiftUI
import ActivityKit
import UIKit

// 근접 센서 상태를 감지하는 ObservableObject
class ProximityManager: ObservableObject {
    @Published var isClose = false

    init() {
        UIDevice.current.isProximityMonitoringEnabled = true
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleProximityChange),
            name: UIDevice.proximityStateDidChangeNotification,
            object: nil
        )
    }

    deinit {
        UIDevice.current.isProximityMonitoringEnabled = false
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func handleProximityChange() {
        let state = UIDevice.current.proximityState
        DispatchQueue.main.async {
            self.isClose = state
        }
    }
}

struct ContentView: View {
    @StateObject private var proximity = ProximityManager()
    @State private var showAlert = false

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                NavigationLink(destination: SittingView()) {
                    Text("앉기 모드")
                        .font(.title)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }

                NavigationLink(destination: WalkingView()) {
                    Text("걷기 모드")
                        .font(.title)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }

                Button("Start Live Tracking") {
                    print("▶️ Start button tapped")
                    Task {
                        let auth = ActivityAuthorizationInfo().areActivitiesEnabled
                        print("Live Activity enabled? \(auth)")

                        let attrs = HeadTrackingAttributes(mode: "sitting")
                        let state = HeadTrackingAttributes.ContentState(pitch: 0, roll: 0, yaw: 0)
                        let content = ActivityContent(state: state, staleDate: nil)

                        do {
                            let activity = try Activity<HeadTrackingAttributes>.request(
                                attributes: attrs,
                                content: content,
                                pushType: nil
                            )
                            print("✅ Activity started: \(activity.id)")
                        } catch {
                            print("❌ Failed to start Activity:", error)
                        }
                    }
                }

                Spacer()
            }
            .padding()
            .navigationTitle("모드 선택")
            .onChange(of: proximity.isClose) { isNear in
                if isNear {
                    showAlert = true
                }
            }
            .alert("주의", isPresented: $showAlert) {
                Button("알겠어요") { showAlert = false }
            } message: {
                Text("화면이 얼굴과 너무 가까워요. 조금 멀리 떨어져 주세요.")
            }
        }
    }
}

