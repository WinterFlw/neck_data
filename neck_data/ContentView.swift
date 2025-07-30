import SwiftUI
import ActivityKit

struct ContentView: View {
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
                        // 권한 확인
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
            }
            .padding()
            .navigationTitle("모드 선택")
        }
    }
}
