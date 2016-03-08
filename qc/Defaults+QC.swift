protocol QCDefaults {
  var password: String? { get set }
}

extension Defaults: QCDefaults {
  private static let passwordKey = "password"
  
  public var password: String? {
    get { return objectForKey(Defaults.passwordKey) }
    set { setObject(newValue, forKey: Defaults.passwordKey) }
  }
}
