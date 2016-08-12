//
//  PingResponse.swift
//  SwiftPing
//
//  Created by Ankit Thakur on 20/06/16.
//  Copyright © 2016 Ankit Thakur. All rights reserved.
//

import Foundation

public class PingResponse: NSObject {

	public var identifier:UInt32
	public var ipAddress:String?
	public var sequenceNumber:Int64
	public var duration:TimeInterval
	public var error:NSError?

	public init(id:UInt32, ipAddress addr:String?, sequenceNumber number:Int64, duration dur:TimeInterval, error err:NSError?) {
		identifier = id
		ipAddress = addr
		sequenceNumber = number
		duration = dur
		error = err
	}

}
