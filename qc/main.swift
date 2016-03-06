//
//  main.swift
//  qc
//
//  Created by JakubX Petrik on 3/6/16.
//  Copyright © 2016 Intel. All rights reserved.
//

import Foundation

struct Options {
  static let setPassword = "--pwd"
  static let printUsage = "--help"
}

struct DefaultsKey {
  static let initialized = "initialized"
  static let password = "password"
}

extension NSUserDefaults {
  
  static func initiliaze() {
    guard !initialized else { return }
    let defaults = [DefaultsKey.initialized: true]
    standardUserDefaults().registerDefaults(defaults)
    standardUserDefaults().synchronize()
  }
  
  private static func _setObj(obj: AnyObject?, forKey key: String) {
    standardUserDefaults().setObject(obj, forKey: key)
    standardUserDefaults().synchronize()
  }
  
  static var initialized: Bool {
    get {
      return standardUserDefaults().boolForKey(DefaultsKey.initialized)
    }
    set {
      _setObj(newValue, forKey: DefaultsKey.initialized)
    }
  }
  
  static var password: String? {
    get {
      return standardUserDefaults().stringForKey(DefaultsKey.password)
    }
    set {
      _setObj(newValue, forKey: DefaultsKey.password)
    }
  }
}

func setPassword(newPassword: String?) {
  guard let password = newPassword else {
    printUsage()
    exit(EXIT_FAILURE)
  }
  
  NSUserDefaults.password = password
}

func printUsage() {
  print("usage: qc [\(Options.setPassword) <password>] | [\(Options.printUsage)]")
}

func runScript() {
  guard let password = NSUserDefaults.password else {
    print("No password found!")
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