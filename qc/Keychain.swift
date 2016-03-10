import Foundation

public final class Keychain {
  
  private let suiteName: String
  private lazy var values: NSMutableDictionary = {
    guard let data = self.load(),
      values = NSKeyedUnarchiver.unarchiveObjectWithData(data) as? NSMutableDictionary else {
        return NSMutableDictionary()
    }
    return values
  }()
  
  public init(suiteName: String) {
    self.suiteName = suiteName
  }
  
  public func getObjectForKey<T>(key: String) -> T? {
    return values.objectForKey(key) as? T
  }
  
  public func setObject(object: AnyObject?, forKey key: String) {
    if let objectToSet = object {
      values.setObject(objectToSet, forKey: key)
    } else {
      values.removeObjectForKey(key)
    }
    let data = NSKeyedArchiver.archivedDataWithRootObject(values)
    save(data)
  }
  
  public func clear() {
    delete()
    values = NSMutableDictionary()
  }
  
  private func save(data: NSData) -> Bool {
    let query = [
      kSecClass as String       : kSecClassGenericPassword as String,
      kSecAttrAccount as String : suiteName,
      kSecValueData as String   : data ]
    
    SecItemDelete(query as CFDictionaryRef)
    
    let status = SecItemAdd(query as CFDictionaryRef, nil)
    
    return status == noErr
  }
  
  private func load() -> NSData? {
    let query = [
      kSecClass as String       : kSecClassGenericPassword,
      kSecAttrAccount as String : suiteName,
      kSecReturnData as String  : kCFBooleanTrue,
      kSecMatchLimit as String  : kSecMatchLimitOne ]
    
    let dataTypeRef = UnsafeMutablePointer<AnyObject?>.alloc(1)
    
    let status = SecItemCopyMatching(query, dataTypeRef)
    
    guard let data = dataTypeRef.memory as? NSData where status == noErr else { return nil }
    return data
  }
  
  private func delete() -> Bool {
    let query = [
      kSecClass as String       : kSecClassGenericPassword,
      kSecAttrAccount as String : suiteName ]
    
    let status: OSStatus = SecItemDelete(query as CFDictionaryRef)
    
    return status == noErr
  }
  
}
