import Foundation

enum QCError: ErrorType {
  case PasswordNotSet
  case NetworkNotSet
  case CouldNotCreateScript(String)
  case AppleScriptError(NSDictionary)
}

struct Option {
  static let setPassword = "--set-password"
  static let help = "--help"
  static let setNetwork = "--set-network"
  static let clear = "--clear"
}

let arguments = Process.arguments
var defaults = Keychain(suiteName: "qc")

let usage =
  "usage: qc                           \tconnect to default VPN\n" +
  "   or: qc \(Option.setNetwork) <network>     \tconnect to specific VPN\n" +
  "   or: qc \(Option.setPassword) <password>\tset password\n" +
  "   or: qc \(Option.help)                      \tprint help\n" +
  "\nArguments:\n" +
  "  \(Option.setNetwork)\t\t\tConnect to a network with specific name\n" +
  "  \(Option.setPassword)\t\tSet a new password to be used\n" +
  "  \(Option.help)\t\t\tPrint Help (this message) and exit\n"


let format =
"activate application \"Cisco AnyConnect Secure Mobility Client\"\n" +
  "tell application \"System Events\" to tell process \"Cisco AnyConnect Secure Mobility Client\"\n" +
  "tell combo box 1 of window 1 to set value to \"%@\"\n" +
  "click button \"Connect\" of window 1\n" +
  "repeat until window 2 exists\n" +
  "end repeat\n" +
  "keystroke \"%@\"\n" +
  "click button \"OK\" of window 1\n" +
"end tell\n"

func printErrorAndExit(error: ErrorType) {
  print("\nerror: \(error)!\n")
  print(usage)
  exit(EXIT_FAILURE)
}

func storePassword(password: String) -> Result<String, QCError> {
  defaults.password = password
  return .Success(password)
}

func storeNetwork(network: String) -> Result<String, QCError> {
  defaults.network = network
  return .Success(network)
}

func updatePassword(password: String?) -> Result<String, QCError> {
  return updateValue(password,
    validator: validatePassword,
    store: storePassword,
    confirmation: {_ in .Success("Password updated! 🍻") }
  )
}

func updateNetwork(network: String?) -> Result<String, QCError> {
  return updateValue(network,
    validator: validateNetwork,
    store: storeNetwork,
    confirmation: {_ in .Success("Network updated! 🍻")})
}

func updateValue<T>(value: T?, validator validate: T? -> Result<T, QCError>, store storeValue: T -> Result<T, QCError>, confirmation sendConfirmation: T -> Result<String, QCError>) -> Result<String, QCError> {
  return
    validate(value)
    >>- storeValue
    >>- sendConfirmation
}

func validateValue<T>(value: T?, error: QCError) -> Result<T, QCError> {
  switch value {
  case let .Some(value): return .Success(value)
  case .None: return .Failure(error)
  }
}

func validatePassword(password: String?) -> Result<String, QCError> {
  return validateValue(password, error: .PasswordNotSet)
}

func validateNetwork(network: String?) -> Result<String, QCError> {
  return validateValue(network, error: .NetworkNotSet)
}

func createScript(password: String, network: String) -> Result<NSAppleScript, QCError> {
  let source = String(format: format, network, password)
  let script = NSAppleScript(source: source)
  return validateValue(script, error: .CouldNotCreateScript(source))
}

func executeScript(script: NSAppleScript) ->  Result<NSAppleEventDescriptor, QCError> {
  var errorDictionary: NSDictionary? = nil
  let eventDescriptor = script.executeAndReturnError(&errorDictionary)
  switch errorDictionary {
  case .Some(let error): return .Failure(.AppleScriptError(error))
  case .None: return .Success(eventDescriptor)
  }
}

func connect(password: String?, toNetwork network: String?) -> Result<NSAppleEventDescriptor, QCError> {
  return validatePassword(password) &&& validateNetwork(network)
    >>- createScript
    >>- executeScript
}


if arguments.hasOption(Option.setPassword) {
  switch updatePassword(arguments.argumentForOption(Option.setPassword)) {
  case let .Success(confirmation): print(confirmation)
  case let .Failure(error): printErrorAndExit(error)
  }
}
else if arguments.hasOption(Option.setNetwork) {
  switch updateNetwork(arguments.argumentForOption(Option.setNetwork)) {
  case let .Success(confirmation): print(confirmation)
  case let .Failure(error): printErrorAndExit(error)
  }
}
else if arguments.hasOption(Option.help) {
  print(usage)
}
else if arguments.hasOption(Option.clear) {
  defaults.clear()
  print("Settings cleared! 🖖")
}
else {
  if let error = connect(defaults.password, toNetwork: defaults.network).error {
    printErrorAndExit(error)
  }
}

exit(EXIT_SUCCESS)
