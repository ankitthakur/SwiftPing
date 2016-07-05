# SwiftPing

[![CI Status](http://img.shields.io/travis/ankitthakur85/SwiftPing.svg?style=flat)](https://travis-ci.org/ankitthakur85/SwiftPing)
[![Version](https://img.shields.io/cocoapods/v/SwiftPing.svg?style=flat)](http://cocoadocs.org/docsets/SwiftPing)
[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![License](https://img.shields.io/cocoapods/l/SwiftPing.svg?style=flat)](http://cocoadocs.org/docsets/SwiftPing)
[![Platform](https://img.shields.io/cocoapods/p/SwiftPing.svg?style=flat)](http://cocoadocs.org/docsets/SwiftPing)
[![Coverage Status](https://coveralls.io/repos/realm/SwiftCov/badge.svg)](https://codecov.io/github/ankitthakur/SwiftPing)

## Description

**SwiftPing** ICMP Pinging in swift..

## Usage

```swift
let pingInterval:TimeInterval = 3
let timeoutInterval:TimeInterval = 4
let configuration = PingConfiguration(pInterval:pingInterval, withTimeout:  timeoutInterval)

print(configuration)

SwiftPing.ping(host: "google.com", configuration: configuration, queue: DispatchQueue.main) { (ping, error) in
print("\(ping)")
print("\(error)")
}
```

## Installation

ICMP Pinging in swift.

*Thanks to https://github.com/OliverLetterer/SPLPing. Migrated it to Swift 3 and added 1 enhancement.

Enhancement: Now pinging is supportable in any of the GCD Queue, where user wants.

**SwiftPing** is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'SwiftPing'
```

**SwiftPing** is also available through [Carthage](https://github.com/Carthage/Carthage).
To install just write into your Cartfile:

```ruby
github "ankitthakur85/SwiftPing"
```

## Todo

Test cases and usage needs to be added


## Author

Ankit Thakur, ankitthakur85@icloud.com

## Contributing

We would love you to contribute to **SwiftPing** and request you follow these guidelines.

 - [Raising issues](#raising-issues)
 - [Coding Standards](#coding-standards)


### Raising issues

Please raise any bug reports on the issue tracker. Be sure to
search the list to see if your issue has already been raised.

A good bug report is one that make it easy for us to understand what you were
trying to do and what went wrong. Provide as much context as possible so we can try to recreate the issue.

If you find a bug, please submit a pull request with a failing test case displaying the bug or create an issue. Please add tests alongside your pull requests.

### Coding standards

Please ensure you follow the coding standards used throughout the existing
code base. Some basic rules include:
 - all PRs must have passing builds for all operating systems.

## License

**SwiftPing** is available under the MIT license. See the [LICENSE](https://github.com/ankitthakur85/SwiftPing/blob/master/LICENSE.md) file for more info.
