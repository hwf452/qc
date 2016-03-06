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
  
  static var initialized: Bool {
    get {
    return standardUserDefaults().boolForKey(DefaultsKey.initialized)
    }
    set {
      _setObj(newValue, forKey: DefaultsKey.initialized)
    }
  }
  
  static var password: String? {
    get {
    return standardUserDefaults().stringForKey(DefaultsKey.password)
    }
    set {
      _setObj(newValue, forKey: DefaultsKey.password)
    }
  }
}
