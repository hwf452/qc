import Foundation

extension Array where Element: Comparable, Element: Equatable {
  public func hasOption(option: Element) -> Bool {
    return contains { $0 == option }
  }
  
  public func argumentForOption(option: Element) -> Element? {
    guard let optionIndex = indexOf(option) where optionIndex < count - 1 else { return nil }
    return self[optionIndex.advancedBy(1)]
  }
}