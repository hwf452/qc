import Foundation

struct DefaultsKey {
  static let initialized = "initialized"
  static let password = "password"
}

struct Defaults {
  
  private static let defaults = NSUserDefaults.standardUserDefaults()
  
  static func setup() {
    guard !initialized else { return }
    let initialDefaults = [DefaultsKey.initialized: true]
    defaults.registerDefaults(initialDefaults)
    defaults.synchronize()
  }
  
  private static func _setObj(obj: AnyObject?, forKey key: String) {
    defaults.setObject(obj, forKey: key)
    defaults.synchronize()
  }
  
  private static func _getObjForKey<T>(key: String) -> T? {
      return defaults.objectForKey(key) as? T
  }
  
  static var initialized: Bool {
    get {
      return _getObjForKey(DefaultsKey.initialized) ?? false
    }
    set {
      _setObj(newValue, forKey: DefaultsKey.initialized)
    }
  }
  
  static var password: String? {
    get {
      return _getObjForKey(DefaultsKey.password)
    }
    set {
      _setObj(newValue, forKey: DefaultsKey.password)
    }
  }
}
