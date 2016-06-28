extension Keychain {
  private struct Key {
    static let Password = "Password"
    static let Network = "Network"
  }
  
  var password: String? {
    get { return getObjectForKey(Key.Password) }
    set { _ = setObject(newValue, forKey: Key.Password) }
  }
  
  var network: String? {
    get { return getObjectForKey(Key.Network) }
    set { _ = setObject(newValue, forKey: Key.Network) }
  }
}
