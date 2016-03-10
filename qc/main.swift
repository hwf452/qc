import Foundation

enum QCError: ErrorType {
  case PasswordNotFound
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

func storePassword(password: String?) -> Result<String, QCError> {
  guard let password = password else {
    return .Failure(.PasswordNotFound)
  }
  defaults.password = password
  return .Success(password)
}

func updatePassword(password: String?) -> Result<String, QCError> {
  return
    validatePassword(password)
    >>- storePassword
    >>- {_ in .Success("Password updated! 🍻") }
}

func validatePassword(password: String?) -> Result<String, QCError> {
  switch password {
  case .Some(let password): return .Success(password)
  case .None: return .Failure(.PasswordNotFound)
  }
}

func validateNetwork(network: String?) -> Result<String, QCError> {
  return .Success(network ?? "Intel Network")
}

func createScript(password: String, network: String) -> Result<NSAppleScript, QCError> {
  let source = String(format: format, password)
  switch NSAppleScript(source: source) {
  case let .Some(script): return .Success(script)
  case .None: return .Failure(.CouldNotCreateScript(source))
  }
}

func executeScript(script: NSAppleScript) ->  Result<NSAppleEventDescriptor, QCError> {
  var errorDictionary: NSDictionary? = nil
  let eventDescriptor = script.executeAndReturnError(&errorDictionary)
  switch errorDictionary {
  case .Some(let error): return .Failure(.AppleScriptError(error))
  case .None: return .Success(eventDescriptor)
  }
}

func connect(password: String?, network: String?) -> Result<NSAppleEventDescriptor, QCError> {
  return
    validatePassword(password) &&& validateNetwork(network)
    >>- createScript
    >>- executeScript
}


if arguments.hasOption(Option.setPassword) {
  switch updatePassword(arguments.argumentForOption(Option.setPassword)) {
  case let .Success(confirmation): print(confirmation)
  case let .Failure(error): printErrorAndExit(error)
  }
}
else if arguments.hasOption(Option.help) {
  print(usage)
}
else {
  if let error = connect(defaults.password, network: arguments.argumentForOption(Option.network)).error {
    printErrorAndExit(error)
  }
}

exit(EXIT_SUCCESS)
