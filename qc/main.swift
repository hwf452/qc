import Foundation

enum QCError: ErrorType {
  case PasswordNotSet
  case NetworkNotSet
  case CouldNotCreateScript(String)
  case AppleScriptError(NSDictionary)
  case UnknownOption(String)
}

struct Option {
  static let help = "--help"
  static let clear = "--clear"
  static let setup = "--setup"
  static let setPassword = "--set-password"
  static let setNetwork = "--set-network"
  static let network = "--network"
}

let arguments = Process.arguments
var defaults = Keychain(identifier: "qc")

let usage =
  "usage: qc \t\t\t\tConnect to the saved network\n" +
  "   or: qc \(Option.network) <network>\t\tConnect to the given network\n" +
  "   or: qc \(Option.setup) \t\t\tRun setup wizard\n" +
  "   or: qc \(Option.setPassword) \t\tSetup password\n" +
  "   or: qc \(Option.setNetwork) <network>\tSet network\n" +
  "   or: qc \(Option.clear) \t\t\tClear saved settings\n" +
  "   or: qc \(Option.help) \t\t\tPrint help (this message) and exit\n"

let format =
"activate application \"Cisco AnyConnect Secure Mobility Client\"\n" +
  "tell application \"System Events\" to tell process \"Cisco AnyConnect Secure Mobility Client\"\n" +
  "if button \"Disconnect\" of window 1 exists then\n" +
    "click button \"Disconnect\" of window 1\n" +
    "return 1\n" +
  "end if\n" +
  "tell combo box 1 of window 1 to set value to \"%@\"\n" +
  "click button \"Connect\" of window 1\n" +
  "repeat until window 2 exists\n" +
  "end repeat\n" +
  "keystroke \"%@\"\n" +
  "click button \"OK\" of window 1\n" +
  "repeat until button \"Disconnect\" of window 1 exists\n" +
  "end repeat\n" +
  "return 0\n" +
"end tell\n"

func printErrorAndExit(error: ErrorType) {
  print("\nerror: \(error)!\n")
  print(usage)
  exit(EXIT_FAILURE)
}

func getPassword() -> Result<String?, QCError> {
  let password = getpass("Password: ")
  return .Success(String.fromCString(password))
}

func getNetwork() -> Result<String?, QCError> {
  print("Network: ", terminator: "")
  return .Success(readLine(stripNewline: true))
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

func validateOptional<T>(value: T?, error: QCError) -> Result<T, QCError> {
  switch value {
  case let .Some(value): return .Success(value)
  case .None: return .Failure(error)
  }
}

func validatePassword(password: String?) -> Result<String, QCError> {
  return validateOptional(password, error: .PasswordNotSet)
}

func validateNetwork(network: String?) -> Result<String, QCError> {
  return validateOptional(network, error: .NetworkNotSet)
}

func createScript(password: String, network: String) -> Result<NSAppleScript, QCError> {
  let source = String(format: format, network, password)
  let script = NSAppleScript(source: source)
  return validateOptional(script, error: .CouldNotCreateScript(source))
}

func executeScript(script: NSAppleScript) ->  Result<NSAppleEventDescriptor, QCError> {
  var errorDictionary: NSDictionary? = nil
  let eventDescriptor = script.executeAndReturnError(&errorDictionary)
  switch errorDictionary {
  case .Some(let error): return .Failure(.AppleScriptError(error))
  case .None: return .Success(eventDescriptor)
  }
}

func recognizeEvent(descriptor: NSAppleEventDescriptor) -> Result<String, QCError> {
    return descriptor.int32Value == 1 ? .Success("Disconnected! 🍻") : .Success("Connected! 👍")
}

func connect(password: String?, toNetwork network: String?) -> Result<String, QCError> {
  return validatePassword(password) &&& validateNetwork(network)
    >>- createScript
    >>- executeScript
    >>- recognizeEvent
}

func eval<T>(result: Result<T, QCError>, success: T -> () = { print($0) }, fail: QCError -> () = printErrorAndExit) {
  switch result {
  case let .Success(res): success(res)
  case let .Failure(error): fail(error)
  }
}

func setup() {
  eval(getPassword() >>- updatePassword)
  eval(getNetwork() >>- updateNetwork)
}

if arguments.hasOption(Option.setup) {
  setup()
}
else if arguments.hasOption(Option.setNetwork) {
  eval(updateNetwork(arguments.argumentForOption(Option.setNetwork)))
}
else if arguments.hasOption(Option.setPassword) {
  eval(getPassword() >>- updatePassword)
}
else if arguments.hasOption(Option.help) {
  print(usage)
}
else if arguments.hasOption(Option.clear) {
  defaults.clear()
  print("Settings cleared! 🖖")
}
else if arguments.hasOption(Option.network) {
  eval(connect(defaults.password, toNetwork: arguments.argumentForOption(Option.network)))
}
else if arguments.count > 1 {
  let option = arguments[1]
  printErrorAndExit(QCError.UnknownOption(option))
}
else {
  eval(connect(defaults.password, toNetwork: defaults.network))
}

exit(EXIT_SUCCESS)
