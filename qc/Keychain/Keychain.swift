import Foundation

public final class Keychain {
  
  private let identifier: String
  private lazy var values: NSMutableDictionary = {
    guard let data = self.load(),
      values = NSKeyedUnarchiver.unarchiveObject(with: data) as? NSMutableDictionary else {
        return NSMutableDictionary()
    }
    return values
  }()
  
  public init(identifier: String) {
    self.identifier = identifier
  }
  
  public func getObjectForKey<T>(_ key: String) -> T? {
    return values.object(forKey: key) as? T
  }
  
  public func setObject(_ object: AnyObject?, forKey key: String) -> Bool {
    if let objectToSet = object {
      values.setObject(objectToSet, forKey: key)
    }
    else {
      values.removeObject(forKey: key)
    }
    let archivedData = NSKeyedArchiver.archivedData(withRootObject: values)
    return save(archivedData)
  }
  
  public func clear() {
    _ = delete()
    values = NSMutableDictionary()
  }
  
  private func save(_ data: Data) -> Bool {
    let query = [
      kSecClass as String       : kSecClassGenericPassword as String,
      kSecAttrAccount as String : identifier,
      kSecValueData as String   : data ]
    
    SecItemDelete(query as CFDictionary)
    
    let status = SecItemAdd(query as CFDictionary, nil)
    
    return status == noErr
  }
  
  private func load() -> Data? {
    let query = [
      kSecClass as String       : kSecClassGenericPassword,
      kSecAttrAccount as String : identifier,
      kSecReturnData as String  : kCFBooleanTrue,
      kSecMatchLimit as String  : kSecMatchLimitOne ]
    
    let dataTypeRef = UnsafeMutablePointer<AnyObject?>(allocatingCapacity: 1)
    
    let status = SecItemCopyMatching(query, dataTypeRef)
    
    guard let data = dataTypeRef.pointee as? Data where status == noErr else { return nil }
    return data
  }
  
  private func delete() -> Bool {
    let query = [
      kSecClass as String       : kSecClassGenericPassword,
      kSecAttrAccount as String : identifier ]
    
    let status = SecItemDelete(query as CFDictionary)
    
    return status == noErr
  }
  
}
