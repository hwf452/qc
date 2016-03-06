import Foundation

extension Process {
  public static func hasOption(option: String) -> Bool {
    return arguments.contains(option)
  }
  
  public static func argumentForOption(option: String) -> String? {
    guard let optionIndex = arguments.indexOf(option) where optionIndex < arguments.count - 1 else { return nil }
    return arguments[optionIndex.advancedBy(1)]
  }
}