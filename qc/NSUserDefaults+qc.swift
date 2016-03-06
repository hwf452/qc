import Foundation

struct DefaultsKey {
  static let initialized = "initialized"
  static let password = "password"
}

extension NSUserDefaults {
  
  static func initiliaze() {
    guard !initialized else { return }
    let defaults = [DefaultsKey.initialized: true]
    standardUserDefaults().registerDefaults(defaults)
    standardUserDefaults().synchronize()
  }
  
  private static func _setObj(obj: AnyObject?, forKey key: String) {
    standardUserDefaults().setObject(obj, forKey: key)
    standardUserDefaults().synchronize()
  }
  
  private static func _getObjForKey<T>(key: String) -> T? {
      return standardUserDefaults().objectForKey(key) as? T
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
