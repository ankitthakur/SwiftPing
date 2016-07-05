//
//  PingConfiguration.swift
//  SwiftPing
//
//  Created by Ankit Thakur on 20/06/16.
//  Copyright © 2016 Ankit Thakur. All rights reserved.
//

import Foundation

public class PingConfiguration: NSObject {

	var pingInterval:TimeInterval = 1 // default ping interval is 1 sec.
	var timeOutInterval:TimeInterval = 5 // default timeout interval is 5 secs.
	var payloadSize:UInt64 = 64 // default payload size is 64 bytes.

	public init(interval:TimeInterval) {
		pingInterval = interval
	}

	public init(pInterval:TimeInterval, withTimeout tInterval:TimeInterval) {
		pingInterval = pInterval
		timeOutInterval = tInterval
	}

	public init(pInterval:TimeInterval, withTimeout tInterval:TimeInterval, withPayloadSize size:UInt64) {
		pingInterval = pInterval
		timeOutInterval = tInterval
		payloadSize = size
	}


}
