/*========================================
 MIT License
 
 Copyright (c) 2019 Kevin J. Walchko
=========================================*/

import Network
import Foundation

/// Sleep function in seconds
///
/// - Parameters:
///    - sec: seconds to sleep for
public func sleeps(_ sec: Double){
    usleep(UInt32(sec * 1000000))
}

/// Generate an array of `Int` from 0 to `upto`.
///
/// - Parameters
///     - upto: max value
public func range(_ upto: Int) -> [Int] {
    return Array(0 ..< upto)
}

/// Coverts an object to a byte array formated as [LSB ... MSB]
/// 
/// Ref [stackoverflow](https://stackoverflow.com/questions/26953591/how-to-convert-a-double-into-a-byte-array-in-swift)
public func toByteArray<T>(_ value: T) -> [UInt8] {
    var value = value
    return withUnsafeBytes(of: &value) { Array($0) }
}

/// Coverts an object from struct Data
///
public func fromByteArray<T>(_ buffer:Data) -> T {
    let converted:T = buffer.withUnsafeBytes { $0.load(as: T.self) }
    return converted
}

//func toByteArray<T>(_ value: [T]) -> [UInt8] {
//    var darray: [UInt8] = []
//    for d in value {
//        darray.append(contentsOf: toByteArray(d))
//    }
//    return darray
//}

/// Returns the IP address of the machine for wifi and wired connections.
/// Reference:  [stackoverflow](https://stackoverflow.com/a/56342010/5374768)
/// - Returns: IP address as a `String`
public func getIPAddress() -> String {
    var address: String?
    var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil
    if getifaddrs(&ifaddr) == 0 {
        var ptr = ifaddr
        while ptr != nil {
            defer { ptr = ptr?.pointee.ifa_next }
            
            guard let interface = ptr?.pointee else { return "" }
            let addrFamily = interface.ifa_addr.pointee.sa_family
            if addrFamily == UInt8(AF_INET) || addrFamily == UInt8(AF_INET6) {
                
                // wifi = ["en0"]
                // wired = ["en2", "en3", "en4"]
                // cellular = ["pdp_ip0","pdp_ip1","pdp_ip2","pdp_ip3"]
                
                let name: String = String(cString: (interface.ifa_name))
                if  name == "en0" || name == "en2" || name == "en3" || name == "en4" /*|| name == "pdp_ip0" || name == "pdp_ip1" || name == "pdp_ip2" || name == "pdp_ip3"*/ {
                    var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                    getnameinfo(interface.ifa_addr, socklen_t((interface.ifa_addr.pointee.sa_len)), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST)
                    address = String(cString: hostname)
                }
            }
        }
        freeifaddrs(ifaddr)
    }
    return address ?? ""
}


//============================================================================

protocol MSocket {
//    var mtu: Int { get }
    func send(_ content: String)
    func send(_ data: Data)
    func receive(closure: @escaping (Data) -> Void)
//    func receive(closure: @autoclosure () -> Void)
}
