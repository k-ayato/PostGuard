import UIKit

// .navigationBarHidden(true) は左端スワイプの戻るジェスチャを無効化する。
// それを復活させ、結果画面を横スワイプで戻れるようにする。
extension UINavigationController: UIGestureRecognizerDelegate {
    override open func viewDidLoad() {
        super.viewDidLoad()
        interactivePopGestureRecognizer?.delegate = self
    }

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        viewControllers.count > 1
    }
}
