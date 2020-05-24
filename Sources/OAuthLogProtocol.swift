//
//  OAuthLog.swift
//  OAuthSwift
//
//  Created by Sardorbek Ruzmatov on 4/11/20.
//  Copyright © 2020 Dongri Jin. All rights reserved.
//

import Foundation

/// Define the level of log types
public enum OAuthLogLevel: Int {
   // basic level; prints debug, warn, and error statements
   case trace = 0
   // medium level; prints warn and error statements
   case warn
   // highest level; prints only error statements
   case error

}

public protocol OAuthLogProtocol {

   var level: OAuthLogLevel { get }

   /// basic level of print messages
   func trace<T>(_ message: @autoclosure () -> T, filename: String, line: Int, function: String)

   /// medium level of print messages
   func warn<T>(_ message: @autoclosure () -> T, filename: String, line: Int, function: String)

   /// highest level of print messages
   func error<T>(_ message: @autoclosure () -> T, filename: String, line: Int, function: String)
}

extension OAuthLogProtocol {

   public func trace<T>(_ message: @autoclosure () -> T, filename: String = #file, line: Int = #line, function: String = #function) {
      let logLevel = OAuthLogLevel.trace
      // deduce based on the current log level vs. globally set level, to print such log or not
      if level.rawValue >= logLevel.rawValue {
         print("[TRACE] \((filename as NSString).lastPathComponent) [\(line)]: \(message())")
      }
   }

   public func warn<T>(_ message: @autoclosure () -> T, filename: String = #file, line: Int = #line, function: String = #function) {
      let logLevel = OAuthLogLevel.warn
      if level.rawValue >= logLevel.rawValue {
         print("[WARN] \(self) = \((filename as NSString).lastPathComponent) [\(line)]: \(message())")
      }
   }

   public func error<T>(_ message: @autoclosure () -> T, filename: String = #file, line: Int = #line, function: String = #function) {
      let logLevel = OAuthLogLevel.error
      if level.rawValue >= logLevel.rawValue {
         print("[ERROR] \((filename as NSString).lastPathComponent) [\(line)]: \(message())")
      }

   }
}

public struct OAuthDebugLogger: OAuthLogProtocol {
   public let level: OAuthLogLevel
   init(_ level: OAuthLogLevel) {
      self.level = level
   }
}
