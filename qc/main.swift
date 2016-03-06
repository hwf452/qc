//
//  main.swift
//  qc
//
//  Created by JakubX Petrik on 3/6/16.
//  Copyright © 2016 Intel. All rights reserved.
//

import Foundation

struct Options {
  static let setPassword = "--set-pwd"
  static let printUsage = "--help"
}

func setPassword(newPassword: String?) {
  guard let password = newPassword else {
    printUsage()
    exit(EXIT_FAILURE)
  }
  
  NSUserDefaults.password = password
}

func printUsage() {
  print("usage: qc                             connect to VPN")
  print("   or: qc --set-pwd <password>        set password")
  print("   or: qc --help                      print help")
  print("\nArguments:")
  print("  \(Options.setPassword)\t\tSet a new password to be used")
  print("  \(Options.printUsage)\t\tPrint Help (this message) and exit")
}

func runScript() {
  guard let password = NSUserDefaults.password else {
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

NSUserDefaults.initiliaze()

if Process.arguments.contains(Options.setPassword) {
  setPassword(Process.arguments.last)
}
else if Process.arguments.contains(Options.printUsage) {
  printUsage()
}
else {
  runScript()
}

exit(EXIT_SUCCESS)