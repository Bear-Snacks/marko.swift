import Network
import SwiftUI

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

public enum MarkoError: Error {
    case noError
    case noData
    case incompleteData
    case invalidContext
    case sendError /** Error during send */
    case receiveError
}

/// Creates a UDP socket.
@available(macOS 10.14, iOS 13, *)
public class UDPConnect {
    var connection: NWConnection? = nil
    var data: Data? = nil
    var state: MarkoError = .noError
    var mtu: Int
    
    /// Initializer
    /// - Parameters:
    ///     - mtu: how big the packet is, default is max size (65535)
    public init(mtu: Int = 65535) {
        self.mtu = mtu
    }
    
    /// Initialize the socket given an existing `NWConnect`
    /// - Parameters:
    ///     - connection: an existing `NWConnect`
    ///     - mtu: how big the packet is, default is max size (65535)
    public init(_ connection: NWConnection, mtu: Int = 65535){
        self.mtu = mtu
        self.connection = connection
        self.finishSetup()
    }
    
    /// Connects the socket to a host:port
    public func connect(host: NWEndpoint.Host, port: NWEndpoint.Port) {
        guard connection != nil else { return }
        
        self.connection = NWConnection(
            host: host,
            port: port,
            using: .udp)
        
        self.finishSetup()
    }
    
    private func finishSetup(){
        self.connection?.stateUpdateHandler = { (state) in
            switch (state) {
            case .ready:
                let endpt = self.connection?.endpoint
                let local = self.connection?.currentPath?.localEndpoint
                print("  UDPConnect ready remote: \(String(describing: endpt))")
                print("  UDPConnect ready local: \(String(describing: local))")
            case .setup:
                print("UDPConnect: setup")
            case .cancelled:
                print("UDPConnect: cancelled")
            case .preparing:
                print("UDPConnect: preparing")
            default:
                print("waiting or failed")
            }
        }
        
        self.connection?.start(queue: .global())
    }
    
    /// Send `String`, on error, this stop the socket
    public func send(_ content: String) {
        guard let d = content.data(using: String.Encoding.utf8) else { return }
        self.send(d)
    }
    
    /// Send `Data`, on error, this stop the socket
    public func send(_ data: Data) {
        if self.connection?.state != .ready { return }
        self.connection?.send(
            content: data,
            completion: .contentProcessed(){ error in
                if (error != nil) {
                    print("*** UDPConnect send() error: \(error!) ***")
                    self.stop()
                }
            })
    }
    
    /// Receives data from connection and sends it to the closure.
    public func receive(closure: @escaping (Data) -> Void){
        if self.connection?.state != .ready { return }
        
        self.connection?.receive(minimumIncompleteLength: 1, maximumLength: self.mtu) { (data, context, isComplete, error) in
            if (error != nil) {
                print("*** \(String(describing: error)) ***")
                self.stop()
                return
            }
            
            else if (isComplete == false){
                self.state = .incompleteData
                return
            }
            
            guard let d: Data = data, !d.isEmpty else {
                self.state = .noData
                return
            }
            
            self.state = .noError
            closure(d)
        }
    }
    
    /// Stops this socket by cancelling it
    public func stop(){
        if connection?.stateUpdateHandler != nil {
            connection?.stateUpdateHandler = nil
            connection?.cancel()
        }
    }
}


//----------------------------------------------------------------------------

/// Creates a UDP socket that is bound to an ip:port.
@available(macOS 10.14, iOS 13, *)
public class UDPBind {
    private var listener: NWListener?
    private static var counterID: Int = 0
    private var connectionsByID: [Int: ClientConnection] = [:]
    
    public init() { }
    
    /// This actually creates the `NWListener` socket and binds to the host:port given
    /// - Parameters:
    ///     - host: host ip address
    ///     - port: port to use
    /// - Throws: NWListener.NWError
    public func bind(host: NWEndpoint.Host, port: NWEndpoint.Port) throws {
        let parameters = NWParameters.udp.copy()
        parameters.requiredLocalEndpoint = .hostPort(host: host, port: port)
        parameters.allowLocalEndpointReuse = true
        parameters.acceptLocalOnly = false
        parameters.includePeerToPeer = true
        
        listener = try NWListener(using:parameters)
        
        listener?.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                print("Server ready.")
            case .failed(let error):
                print("Server failure, error: \(error.localizedDescription)")
                exit(EXIT_FAILURE)
            case .setup:
                print("Server setup")
            default:
                print(String(describing: self?.listener?.state))
                break
            }
        }
        
        listener?.newConnectionHandler = { [weak self] nwConnection in
            print("didAccept")
            let connection = ClientConnection(id: UDPBind.counterID, connection: nwConnection)
            UDPBind.counterID += 1
            self?.connectionsByID[connection.id] = connection
        }

        listener?.start(queue: .main)
        print(">> \(String(describing: listener?.state))")
    }
    
    /// Sends data to each connected client
    public func send(_ data: Data){
        for client in self.connectionsByID.values {
            if client.connection.connection?.state == .cancelled {
                self.connectionsByID.removeValue(forKey: client.id)
                continue
            }
            client.connection.send(data)
        }
    }
}

@available(macOS 10.14, iOS 13, *)
struct ClientConnection {
    let id: Int
    let connection: UDPConnect
    
    public init (id: Int, connection: NWConnection){
        self.id = id
        self.connection = UDPConnect(connection)
        print(">> New ClientConnection -----------------")
    }
    
    public func send(_ data: Data){
        self.connection.send(data)
    }
    
    public func recv(){
        self.connection.receive(){ data in
            
        }
    }
}
