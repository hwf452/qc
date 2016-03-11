import Foundation

enum QCError: ErrorType {
  case PasswordNotSet
  case NetworkNotSet
  case CouldNotCreateScript(String)
  case AppleScriptError(NSDictionary)
}

let cli = CommandLine()
let helpOpt = BoolOption(shortFlag: "h", longFlag: "help", helpMessage: "Print help (this message) and exit")
let setupOpt = BoolOption(shortFlag: "s", longFlag: "setup", helpMessage: "Run setup wizard")
let clearOpt = BoolOption(shortFlag: "c", longFlag: "clear", helpMessage: "Clear saved settings")

cli.addOptions(helpOpt, setupOpt, clearOpt)
cli.formatOutput = { s, type in
  if case .About = type {
    return "usage: qc        \t\tConnect/Disconnect to/from the saved configuration\n" +
           "   or: qc [option]\t\tPerforms given option\n\n" +
           "Options:\n\n"
  }
  return cli.defaultFormat(s, type: type)
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

func printErrorAndExit(error: ErrorType) {
  print("\nError: \(error)\n")
  cli.printUsage()
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

do {
  try cli.parse(true)
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
