import Foundation

public struct Defaults {
  
  private let defaults: NSUserDefaults
  
  private struct Key {
    static let initialized = "initialized"
  }
  
  private var initialized: Bool {
    get { return objectForKey(Key.initialized) ?? false }
    set { setObject(newValue, forKey: Key.initialized) }
  }
  
  public init(suiteName suitename: String?) {
    defaults = NSUserDefaults(suiteName: suitename) ?? NSUserDefaults.standardUserDefaults()
    setup()
  }
  
  private func synchronize(@noescape operation: NSUserDefaults -> ()) {
    operation(defaults)
    defaults.synchronize()
  }
  
  private func setup() {
    guard !initialized else { return }
    let initialDefaults = [Key.initialized: true]
    synchronize {
      $0.registerDefaults(initialDefaults)
    }
  }
  
  public func setObject(obj: AnyObject?, forKey key: String) {
    synchronize {
      $0.setObject(obj, forKey: key)
    }
  }
  
  public func objectForKey<T>(key: String) -> T? {
    return defaults.objectForKey(key) as? T
  }
}
