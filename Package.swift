// swift-tools-version:5.0
// Package.swift
/*
 The MIT License (MIT)
 Copyright (c) 2019 Eric Marchand (phimage) & Dongri Jin <dongriat@gmail.com>
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

import PackageDescription

let package = Package(
    name: "OAuthSwift",
    products: [
        .library(name: "OAuthSwift", targets: ["OAuthSwift"]),
    ],
    dependencies: [
        .package(url: "https://github.com/phimage/Erik.git", .upToNextMajor(from: "5.0.0")),
        .package(url: "https://github.com/tid-kijyun/Kanna.git", .upToNextMajor(from: "5.2.4")),
        .package(url: "https://github.com/httpswift/swifter.git", .upToNextMajor(from: "1.5.0"))
    ],
    targets: [
        .target(name: "OAuthSwift", dependencies: [], path: "Sources"),
        .testTarget(name: "OAuthSwiftTests", dependencies: ["OAuthSwift", "Erik", "Kanna", "Swifter"], path: "OAuthSwiftTests"),
    ]
)

#if os(Linux)
package.dependencies.append(.package(url: "https://github.com/apple/swift-crypto.git", from: "1.0.0"))
package.targets[0].dependencies.append("Crypto")
#endif