import Foundation

struct DefaultsKey {
  static let initialized = "initialized"
  static let password = "password"
}

public struct Defaults {
  
  private let defaults: NSUserDefaults
  
  private var initialized: Bool {
    get { return _getObjForKey(DefaultsKey.initialized) ?? false }
    set { _setObj(newValue, forKey: DefaultsKey.initialized) }
  }
  
  public var password: String? {
    get { return _getObjForKey(DefaultsKey.password) }
    set { _setObj(newValue, forKey: DefaultsKey.password) }
  }
  
  public init(suiteName suitename: String?) {
    defaults = NSUserDefaults(suiteName: suitename) ?? NSUserDefaults.standardUserDefaults()
    setup()
  }
  
  private func setup() {
    guard !initialized else { return }
    let initialDefaults = [DefaultsKey.initialized: true]
    defaults.registerDefaults(initialDefaults)
    defaults.synchronize()
  }
  
  private func _setObj(obj: AnyObject?, forKey key: String) {
    defaults.setObject(obj, forKey: key)
    defaults.synchronize()
  }
  
  private func _getObjForKey<T>(key: String) -> T? {
    return defaults.objectForKey(key) as? T
  }
}
