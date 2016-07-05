// SwiftPing iOS Playground

import UIKit
import SwiftPing

var str = "Hello, playground"


let pingInterval:TimeInterval = 3
let timeoutInterval:TimeInterval = 4
let configuration = PingConfiguration(pInterval:pingInterval, withTimeout:  timeoutInterval)

SwiftPing.ping(host: "google.com", configuration: configuration, queue: DispatchQueue.main) { (ping, error) in
	print("\(ping)")
	print("\(ping)")
}

