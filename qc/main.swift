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
  static var initialized: Bool {
    get {
      return self.standardUserDefaults().boolForKey(DefaultsKey.initialized)
    }
    set {
      standardUserDefaults().setBool(newValue, forKey: DefaultsKey.initialized)
      standardUserDefaults().synchronize()
    }
  }
  
  static var password: String? {
    get {
      return standardUserDefaults().stringForKey(DefaultsKey.password)
    }
    set {
      standardUserDefaults().setObject(newValue, forKey: DefaultsKey.password)
      standardUserDefaults().synchronize()
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
  password
}

if NSUserDefaults.initialized == false {
  NSUserDefaults.initialized = true
}

if Process.arguments.contains(Options.setPassword) {
  setPassword(Process.arguments.last)
}
else if Process.arguments.contains(Options.printUsage) {
  printUsage()
}
else {
  runScript()
}

