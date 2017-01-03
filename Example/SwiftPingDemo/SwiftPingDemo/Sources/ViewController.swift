import UIKit
import SwiftPing

class ViewController: UIViewController {

  override func viewDidLoad() {
    super.viewDidLoad()
    view.backgroundColor = UIColor.red
		verifyPing()
  }

	func verifyPing() {

		let config:PingConfiguration = PingConfiguration(interval: 1)

		SwiftPing.ping(host: "google.com",
		               configuration: config, queue: DispatchQueue.global()) { (ping, error) in
										print(ping)
										print(error)
                        
                        // start the ping.
                        ping?.observer = {(ping:SwiftPing, response:PingResponse) -> Void in
                            ping.stop()
                            ping.observer = nil
                            
                        }
                        ping?.start()
		}
        
        SwiftPing.pingOnce(host: "www.google.com",
                           configuration: config,
                           queue: DispatchQueue.main){ (response: PingResponse) in
                            
                            print(response)
                            print(response.duration)
                            print(response.ipAddress)
                            print(response.error)
                            print(response.identifier)
        }
        
        
	}

}

