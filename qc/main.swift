import Foundation
import Result

enum QCError: ErrorType {
  case PasswordNotFound
  case CouldNotCreateScript
  case AppleScriptError(NSDictionary)
}

let arguments = Process.arguments
var defaults = Defaults(suiteName: nil)

let usage =
  "usage: qc                             connect to VPN\n" +
  "   or: qc \(Option.setPassword) <password>        set password\n" +
  "   or: qc \(Option.help)                      print help\n" +
  "\nArguments:\n" +
  "  \(Option.setPassword)\t\tSet a new password to be used\n" +
  "  \(Option.help)\t\tPrint Help (this message) and exit\n"


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
  print(error)
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

func updatePassword() {
  if let error = storePassword(arguments.argumentForOption(Option.setPassword)).error {
    printErrorAndExit(error)
  } else {
    print("Password updated!")
  }
}

func validatePassword(password: String?) -> Result<String, QCError> {
  switch password {
  case .Some(let password): return .Success(password)
  case .None: return .Failure(.PasswordNotFound)
  }
}

func createScript(password: String) -> Result<NSAppleScript, QCError> {
  let source = String(format: format, password)
  if let script = NSAppleScript(source: source) {
    return .Success(script)
  } else {
    return .Failure(.CouldNotCreateScript)
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

func connect(password: String?) -> Result<NSAppleEventDescriptor, QCError> {
  return
    validatePassword(password)
    .flatMap(createScript)
    .flatMap(executeScript)
}


if arguments.hasOption(Option.setPassword) {
  updatePassword()
}
else if arguments.hasOption(Option.help) {
  print(usage)
}
else if let error = connect(defaults.password).error {
  printErrorAndExit(error)
}

exit(EXIT_SUCCESS)
