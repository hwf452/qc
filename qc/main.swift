import Foundation

enum QCError: ErrorProtocol {
  case passwordNotSet
  case networkNotSet
  case couldNotCreateScript(String)
  case appleScriptError(NSDictionary)
}

let cli = CommandLine()
let helpOpt = BoolOption(shortFlag: "h", longFlag: "help", helpMessage: "Print help (this message) and exit")
let setupOpt = BoolOption(shortFlag: "s", longFlag: "setup", helpMessage: "Run setup wizard")
let clearOpt = BoolOption(shortFlag: "c", longFlag: "clear", helpMessage: "Clear saved settings")

cli.addOptions(helpOpt, setupOpt, clearOpt)
cli.formatOutput = { s, type in
  switch type {
  case .About:
    return "usage: qc        \t\tConnect/Disconnect to/from the saved configuration\n" +
           "   or: qc [option]\t\tPerforms given option\n\n" +
           "Options:\n\n"
  default: return cli.defaultFormat(s: s, type: type)
  }
}

var defaults = Keychain(identifier: "qc")

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

func printErrorAndExit(_ error: ErrorProtocol) {
  print("\nError: \(error)\n")
  cli.printUsage()
  exit(EXIT_FAILURE)
}

func getPassword() -> Result<String?, QCError> {
  let password = getpass("Password: ")
  return .success(String(cString: password!))
}

func getNetwork() -> Result<String?, QCError> {
  print("Network: ", terminator: "")
  return .success(readLine(strippingNewline: true))
}

func storePassword(_ password: String) -> Result<String, QCError> {
  defaults.password = password
  return .success(password)
}

func storeNetwork(_ network: String) -> Result<String, QCError> {
  defaults.network = network
  return .success(network)
}

func updatePassword(_ password: String?) -> Result<String, QCError> {
  return updateValue(password,
    validator: validatePassword,
    store: storePassword,
    confirmation: {_ in .success("Password updated! 🍻") }
  )
}

func updateNetwork(_ network: String?) -> Result<String, QCError> {
  return updateValue(network,
    validator: validateNetwork,
    store: storeNetwork,
    confirmation: {_ in .success("Network updated! 🍻")})
}

func updateValue<T>(_ value: T?, validator validate: (T?) -> Result<T, QCError>, store storeValue: (T) -> Result<T, QCError>, confirmation sendConfirmation: (T) -> Result<String, QCError>) -> Result<String, QCError> {
  return
    validate(value)
    >>- storeValue
    >>- sendConfirmation
}

func validateOptional<T>(_ value: T?, error: QCError) -> Result<T, QCError> {
  switch value {
  case let .some(value): return .success(value)
  case .none: return .failure(error)
  }
}

func validatePassword(_ password: String?) -> Result<String, QCError> {
  return validateOptional(password, error: .passwordNotSet)
}

func validateNetwork(_ network: String?) -> Result<String, QCError> {
  return validateOptional(network, error: .networkNotSet)
}

func createScript(_ password: String, network: String) -> Result<NSAppleScript, QCError> {
  let source = String(format: format, network, password)
  let script = NSAppleScript(source: source)
  return validateOptional(script, error: .couldNotCreateScript(source))
}

func executeScript(_ script: NSAppleScript) ->  Result<NSAppleEventDescriptor, QCError> {
  var errorDictionary: NSDictionary? = nil
  let eventDescriptor = script.executeAndReturnError(&errorDictionary)
  switch errorDictionary {
  case .some(let error): return .failure(.appleScriptError(error))
  case .none: return .success(eventDescriptor)
  }
}

func recognizeEvent(_ descriptor: NSAppleEventDescriptor) -> Result<String, QCError> {
    return descriptor.int32Value == 1 ? .success("Disconnected! 🍻") : .success("Connected! 👍")
}

func connect(_ password: String?, toNetwork network: String?) -> Result<String, QCError> {
  return validatePassword(password) &&& validateNetwork(network)
    >>- createScript
    >>- executeScript
    >>- recognizeEvent
}

func eval<T>(_ result: Result<T, QCError>, success: (T) -> () = { print($0) }, fail: (QCError) -> () = printErrorAndExit) {
  switch result {
  case let .success(res): success(res)
  case let .failure(error): fail(error)
  }
}

func setup() {
  eval(getPassword() >>- updatePassword)
  eval(getNetwork() >>- updateNetwork)
}


do {
  try cli.parse(strict: true)
}
catch let e {
  printErrorAndExit(e)
}

if helpOpt.wasSet {
  cli.printUsage()
}
else if setupOpt.wasSet {
  setup()
}
else if clearOpt.wasSet {
  defaults.clear()
  print("Settings cleared! 🖖")
}
else {
  eval(connect(defaults.password, toNetwork: defaults.network))
}

exit(EXIT_SUCCESS)
