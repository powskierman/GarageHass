import UIKit
import WatchConnectivity
import Combine

class AppDelegate: UIResponder, UIApplicationDelegate {
    static var shared: AppDelegate? {
        return UIApplication.shared.delegate as? AppDelegate
    }

    var sessionDelegator: SessionDelegator!
    var entityStateSubject = PassthroughSubject<SessionDelegator.EntityStateChange, Never>()

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        print("AppDelegate: didFinishLaunchingWithOptions called")
        
        if WCSession.isSupported() {
            print("AppDelegate: WCSession is supported")
            sessionDelegator = SessionDelegator(entityStateSubject: entityStateSubject)
            print("AppDelegate: WCSession default session set up via SessionDelegator")
        } else {
            print("AppDelegate: WCSession is not supported on this device")
        }
        return true
    }
}
