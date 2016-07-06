//
//  SwiftPing.swift
//  SwiftPing
//
//  Created by Ankit Thakur on 20/06/16.
//  Copyright © 2016 Ankit Thakur. All rights reserved.
//

import Foundation
import Darwin

func getIPv4AddressFromHost(host:String, error:AutoreleasingUnsafeMutablePointer<NSError?>) -> Data?{

	var streamError:CFStreamError = CFStreamError()
	let cfhost = CFHostCreateWithName(nil, host).takeRetainedValue()
	let status = CFHostStartInfoResolution(cfhost, .addresses, &streamError)

	var data:Data?

	if status == false {

		if Int32(streamError.domain)  == kCFStreamErrorDomainNetDB {
			error.pointee = NSError(domain: kCFErrorDomainCFNetwork as String, code: Int(CFNetworkErrors.cfHostErrorUnknown.rawValue) , userInfo: [kCFGetAddrInfoFailureKey as NSObject : "error in host name or address lookup"])
		}
		else{
			error.pointee = NSError(domain: kCFErrorDomainCFNetwork as String, code: Int(CFNetworkErrors.cfHostErrorUnknown.rawValue) , userInfo: nil)
		}
	}
	else{
		var success: DarwinBoolean = false
		guard let addresses = CFHostGetAddressing(cfhost, &success)?.takeUnretainedValue() as NSArray? else
		{
			error.pointee = NSError(domain: kCFErrorDomainCFNetwork as String, code: Int(CFNetworkErrors.cfHostErrorHostNotFound.rawValue) , userInfo: [NSLocalizedDescriptionKey:"failed to retrieve the known addresses from the given host"])
			return nil
		}

		for address in addresses {

			let addressData = address as! NSData
			let addrin = UnsafePointer<sockaddr>(addressData.bytes).pointee
			if addressData.length >= sizeof(sockaddr) && addrin.sa_family == UInt8(AF_INET) {
				data = addressData as Data
				break
			}
		}

		if data?.count == 0 || data == nil {
			error.pointee = NSError(domain: kCFErrorDomainCFNetwork as String, code: Int(CFNetworkErrors.cfHostErrorHostNotFound.rawValue) , userInfo: nil)
		}
	}

	return data

}

public class SwiftPing: NSObject {

	var host:String?
	var ip:String?
	var configuration:PingConfiguration?

	var observer:((ping:SwiftPing, response:PingResponse) -> Void)?

	var errorClosure:((ping:SwiftPing, error:NSError) -> Void)?

	var identifier:UInt32?

	private var hasScheduledNextPing:Bool = false
	private var ipv4address:Data?
	private var socket:CFSocket?
	private var socketSource:CFRunLoopSource?

	private var isPinging:Bool = false
	private var currentSequenceNumber:UInt64 = 0
	private var currentStartDate:Date?

	private var timeoutBlock:((Void) -> Void)?

	private var currentQueue:DispatchQueue?

	// MARK: Public APIs

	/// pinging to the host url, with provided configuration.
	///
	/// - parameters:
	///   - host: url string, to ping.
	///   - configuration: PingConfiguration object so as to define ping interval, time interval
	///   - completion: Closure of the format `(ping:SwiftPing?, error:NSError?) -> Void` format

	public class func ping(host:String, configuration:PingConfiguration, queue:DispatchQueue, completion:(ping:SwiftPing?, error:NSError?) -> Void) -> Void{

		print(queue)
		DispatchQueue.global().async{
			var error:NSError?;
			let ipv4Address:Data? = getIPv4AddressFromHost(host:host, error: &error)

			queue.async {
				if (error != nil) {
					completion(ping: nil, error: error)
				}
				else{
					completion(ping: SwiftPing(host: host, ipv4Address: ipv4Address!, configuration: configuration, queue: queue), error: nil)
				}
			}

		}
	}

	/// pinging to the host url only once, with provided configuration 
	///
	/// - parameters:
	///   - host: url string, to ping.
	///   - configuration: PingConfiguration object so as to define ping interval, time interval
	///   - completion: Closure of the format `(ping:SwiftPing?, error:NSError?) -> Void` format

	public class func pingOnce(host:String, configuration:PingConfiguration, queue:DispatchQueue, completion:(response:PingResponse) -> Void) -> Void{

		let date = Date()

		SwiftPing.ping(host: host, configuration: configuration, queue: queue) { (ping, error) in
			if error != nil {
				let response = PingResponse(id: 0, ipAddress: nil, sequenceNumber: 1, duration: Date().timeIntervalSince(date), error: error)

				completion(response: response);
			}
			else {
				let ping:SwiftPing = ping!

				// add observer to stop the ping, if already recieved once.
				// start the ping.
				ping.observer = {(ping:SwiftPing, response:PingResponse) -> Void in
					ping.stop()
					ping.observer = nil
					completion(response: response);
				}
				ping.start()

			}
		}
	}

	// MARK: PRIVATE
	func socketCallback(socket: CFSocket!, type:CFSocketCallBackType, address:CFData!, data:UnsafePointer<Void>, info:UnsafeMutablePointer<Void>) {
		// Conditional cast from 'SwiftPing' to 'SwiftPing' always succeeds

		// 1
		var info:UnsafeMutablePointer<Void> = info
		guard let ping:SwiftPing = (withUnsafePointer(&info) { (temp) in
			return unsafeBitCast(temp, to: SwiftPing.self)
			})else{
				print("ping callback object is nil")
				return
		}

		if (type as CFSocketCallBackType) == CFSocketCallBackType.dataCallBack {

			let fData = UnsafePointer<UInt8>(data)
			let bytes = UnsafeBufferPointer<UInt8>(start: fData, count: sizeof(UInt8))
			let cfdata:Data = Data(buffer: bytes)
			ping.socket(socket: socket, didReadData: cfdata)
		}
	}

	func initialize(host:String, ipv4Address:Data, configuration:PingConfiguration, queue:DispatchQueue){


		self.host = host;
		self.ipv4address = ipv4Address;
		self.configuration = configuration;
		self.identifier = arc4random();
		self.currentQueue = queue

		let socketAddress:sockaddr_in = UnsafePointer<sockaddr_in>((ipv4Address as NSData).bytes).pointee
		self.ip = String(cString: inet_ntoa(socketAddress.sin_addr), encoding: String.Encoding.ascii)!


		var context = CFSocketContext()
		context.version = 0
		context.info = unsafeBitCast(self, to: UnsafeMutablePointer<Void>.self);


		self.socket = CFSocketCreate(kCFAllocatorDefault, AF_INET, SOCK_DGRAM, IPPROTO_ICMP, CFSocketCallBackType.dataCallBack.rawValue,  {
			(socket, type, address, data, info )  in

			var info:UnsafeMutablePointer<Void> = info!
			guard let ping:SwiftPing = (withUnsafePointer(&info) { (temp) in
				return unsafeBitCast(temp, to: SwiftPing.self)
				})else{
					print("ping callback object is nil")
					return
			}

			if (type as CFSocketCallBackType) == CFSocketCallBackType.dataCallBack {

				let fData = UnsafePointer<UInt8>(data)
				let bytes = UnsafeBufferPointer<UInt8>(start: fData, count: sizeof(UInt8))
				let cfdata:Data = Data(buffer: bytes)
				ping.socket(socket: socket!, didReadData: cfdata)
			}

			}, &context )


		self.socketSource = CFSocketCreateRunLoopSource(nil, self.socket, 0)
		CFRunLoopAddSource(CFRunLoopGetMain(), self.socketSource, CFRunLoopMode.commonModes)
	}

	// Designated Intializer

	init(host:String, ipv4Address:Data, configuration:PingConfiguration, queue:DispatchQueue){

		super.init()
		self.initialize(host: host, ipv4Address: ipv4Address, configuration: configuration, queue: queue)
	}

	convenience init(ipv4Address:String, config configuration:PingConfiguration, queue:DispatchQueue) {

		var socketAddress:sockaddr_in?
		memset(&socketAddress, 0, sizeof(sockaddr_in))

		socketAddress!.sin_len = UInt8(sizeof(sockaddr_in))
		socketAddress!.sin_family = UInt8(AF_INET)
		socketAddress!.sin_port = 0
		socketAddress!.sin_addr.s_addr = inet_addr(ipv4Address.cString(using: String.Encoding.utf8))
		let data = NSData(bytes: &socketAddress, length: sizeof(sockaddr_in))

		// calling designated initializer
		self.init(host: ipv4Address, ipv4Address: data as Data, configuration: configuration, queue: queue)

	}

	deinit {
		CFRunLoopSourceInvalidate(socketSource)
		socketSource = nil
		socket = nil
	}

	// MARK: Start and Stop the pings

	func start(){

		if isPinging == false{
			isPinging = true
			currentSequenceNumber = 0
			currentStartDate = nil
			sendPing()
		}
	}

	func stop(){
		isPinging = false
		currentSequenceNumber = 0
		currentStartDate = nil

		if timeoutBlock != nil {
			timeoutBlock = nil
		}

	}

	func scheduleNextPing()
	{

		if (hasScheduledNextPing == false) {
			return;
		}

		hasScheduledNextPing = true
		if (self.timeoutBlock != nil) {
			self.timeoutBlock = nil;
		}

		let dispatchTime: DispatchTime = DispatchTime.now() + Double(Int64((self.configuration?.pingInterval)! * Double(NSEC_PER_SEC)))


		self.currentQueue!.after(when: dispatchTime) {
			self.hasScheduledNextPing = false
			//			self.sendPing()
		}
	}


	func socket(socket:CFSocket, didReadData data:Data?){

		var ipHeaderData:NSData?
		var ipData:NSData?
		var icmpHeaderData:NSData?
		var icmpData:NSData?

		let extractIPAddressBlock: (Void) -> String? = {
			if ipHeaderData == nil {
				return nil
			}

			var bytes:UnsafePointer<Void> = (ipHeaderData?.bytes)!
			guard let ipHeader:IPHeader = (withUnsafePointer(&bytes) { (temp) in
				return unsafeBitCast(temp, to: IPHeader.self)
				})else{
					print("ipheader data is nil")
					return nil
			}

			let sourceAddr:[UInt8] = ipHeader.sourceAddress

			return "\(sourceAddr[0]).\(sourceAddr[1]).\(sourceAddr[2]).\(sourceAddr[3])"
		}

		if !ICMPExtractResponseFromData(data: data!, ipHeaderData: &ipHeaderData, ipData: &ipData, icmpHeaderData: &icmpHeaderData, icmpData: &icmpData) {
			if (ipHeaderData != nil && self.ip == extractIPAddressBlock()) {
				return
			}
		}

		let error = NSError(domain: NSURLErrorDomain, code: NSURLErrorCannotDecodeRawData, userInfo: nil)
		let response:PingResponse = PingResponse(id: self.identifier!, ipAddress: nil, sequenceNumber: Int64(currentSequenceNumber), duration: Date().timeIntervalSince(currentStartDate!), error: error)
		if observer != nil {
			observer!(ping: self, response: response)
		}

		return scheduleNextPing()

	}

	func sendPing()
	{


		if (!self.isPinging) {
			return;
		}

		self.currentSequenceNumber += 1;
		self.currentStartDate = Date();

		let icmpPackage:NSData = ICMPPackageCreate(identifier: UInt16(self.identifier!), sequenceNumber: UInt16(self.currentSequenceNumber), payloadSize: UInt32(self.configuration!.payloadSize))!;

		let socketError:CFSocketError = CFSocketSendData(socket!, self.ipv4address as! CFData, icmpPackage as CFData, self.configuration!.timeOutInterval)

		if socketError == CFSocketError.error {
			let error = NSError(domain: NSURLErrorDomain, code:NSURLErrorCannotFindHost, userInfo: [:])
			let response:PingResponse = PingResponse(id: self.identifier!, ipAddress: nil, sequenceNumber: Int64(currentSequenceNumber), duration: Date().timeIntervalSince(currentStartDate!), error: error)
			if observer != nil {
				observer!(ping: self, response: response)
			}

			return self.scheduleNextPing()
		}
		else if socketError == CFSocketError.timeout {

			let error = NSError(domain: NSURLErrorDomain, code:NSURLErrorTimedOut, userInfo: [:])
			let response:PingResponse = PingResponse(id: self.identifier!, ipAddress: nil, sequenceNumber: Int64(currentSequenceNumber), duration: Date().timeIntervalSince(currentStartDate!), error: error)
			if observer != nil {
				observer!(ping: self, response: response)
			}

			return self.scheduleNextPing()

		}

		let sequenceNumber:UInt64 = self.currentSequenceNumber;
		self.timeoutBlock = { () -> Void in
			if (sequenceNumber != self.currentSequenceNumber) {
				return;
			}

			self.timeoutBlock = nil
			let error = NSError(domain: NSURLErrorDomain, code:NSURLErrorTimedOut, userInfo: [:])
			let response:PingResponse = PingResponse(id: self.identifier!, ipAddress: nil, sequenceNumber: Int64(self.currentSequenceNumber), duration: Date().timeIntervalSince(self.currentStartDate!), error: error)
			if self.observer != nil {
				self.observer!(ping: self, response: response)
			}
			self.scheduleNextPing()
  }

  typealias Block = @convention(block) () -> ()
  let block = self.timeoutBlock as! Block
		let dispatchTime: DispatchTime = DispatchTime.now() + Double(Int64((self.configuration?.pingInterval)! * Double(NSEC_PER_SEC)))
		
		self.currentQueue?.after(when: dispatchTime, execute: block)
		
		
	}
}
