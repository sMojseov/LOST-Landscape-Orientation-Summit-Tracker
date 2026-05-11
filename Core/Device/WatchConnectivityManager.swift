import Foundation
import WatchConnectivity
import Combine

class WatchConnectivityManager: NSObject, ObservableObject {
    static let shared = WatchConnectivityManager()

    @Published var isPaired: Bool = false
    @Published var isReachable: Bool = false
    @Published var isSessionActive: Bool = false

    var connectionStatus: String {
        if !WCSession.isSupported() { return "NOT SUPPORTED" }
        if !isSessionActive { return "INACTIVE" }
        if !isPaired { return "NO WATCH PAIRED" }
        if isReachable { return "CONNECTED" }
        return "PAIRED"
    }

    private override init() {
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }
}

extension WatchConnectivityManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isSessionActive = activationState == .activated
            self.isPaired = session.isPaired
            self.isReachable = session.isReachable
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        DispatchQueue.main.async { self.isSessionActive = false }
    }

    func sessionDidDeactivate(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isSessionActive = false
            self.isReachable = false
        }
        WCSession.default.activate()
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
            self.isPaired = session.isPaired
        }
    }
}
