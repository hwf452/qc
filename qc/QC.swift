import Foundation

struct QC {
  
  static func run(arguments: [String]) {
    Defaults.setup()
    
    if arguments.hasOption(Options.setPassword) {
      setPassword(arguments.argumentForOption(Options.setPassword))
    }
    else if arguments.hasOption(Options.printUsage) {
      printUsage()
    }
    else {
      runScript()
    }
    
    exit(EXIT_SUCCESS)
  }
  
  static func setPassword(newPassword: String?) {
    guard let password = newPassword else {
      printUsage()
      exit(EXIT_FAILURE)
    }
    
    Defaults.password = password
  }
  
  static func printUsage() {
    print("usage: qc                             connect to VPN")
    print("   or: qc \(Options.setPassword) <password>        set password")
    print("   or: qc \(Options.printUsage)                      print help")
    print("\nArguments:")
    print("  \(Options.setPassword)\t\tSet a new password to be used")
    print("  \(Options.printUsage)\t\tPrint Help (this message) and exit")
  }
  
  static func runScript() {
    guard let password = Defaults.password else {
      print("Password not found!")
      printUsage()
      exit(EXIT_FAILURE)
    }
    
    let format =
    "activate application \"Cisco AnyConnect Secure Mobility Client\"\n" +
      "tell application \"System Events\" to tell process \"Cisco AnyConnect Secure Mobility Client\"\n" +
      "click button \"Connect\" of window 1\n" +
      "repeat until window 2 exists\n" +
      "end repeat\n" +
      "keystroke \"%@\"\n" +
      "click button \"OK\" of window 1\n" +
    "end tell\n"
    
    let source = String(format: format, password)
    guard let script = NSAppleScript(source: source) else {
      print("Could not create script!")
      printUsage()
      exit(EXIT_FAILURE)
    }
    
    script.executeAndReturnError(nil)
  }
  
}
