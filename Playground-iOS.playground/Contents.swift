// SwiftPing iOS Playground

import UIKit
import SwiftPing

var str = "Hello, playground"


let pingInterval:TimeInterval = 3
let timeoutInterval:TimeInterval = 4
let configuration = PingConfiguration(pInterval:pingInterval, withTimeout:  timeoutInterval)

//print(configuration)

SwiftPing.ping(host: "google.com", configuration: configuration, queue: DispatchQueue.main) { (ping, error) in
    print("\(ping)")
    print("\(error)")
}


SwiftPing.pingOnce(host: "google.com", configuration: configuration, queue: DispatchQueue.global()) { (response: PingResponse) in
    print("\(response.duration)")
    print("\(response.ipAddress)")
    print("\(response.error)")
    
}

