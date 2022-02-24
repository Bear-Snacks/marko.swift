//

import Network
import Foundation


public enum MarkoError: Error {
    case noError
    case noData
    case incompleteData
    case invalidContext
    case sendError
    case receiveError
}

/// Creates a UDP socket.
@available(macOS 10.14, iOS 13, *)
public class UDPConnect: MSocket {
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
    
    /// Initialize the socket given an existing `NWConnection`
    /// - Parameters:
    ///     - connection: an existing `NWConnection`
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
    
    /// Receives data from connection
    /// - Returns: `Data`?
    public func receive() -> Data? {
        if self.connection?.state != .ready { return nil }
        
        var retData: Data? = nil
        self.receive(){ data in
            retData = data
        }
        
        return retData
    }
    
    /// Stops this socket by cancelling it
    public func stop(){
        if connection?.stateUpdateHandler != nil {
            connection?.stateUpdateHandler = nil
            connection?.cancel()
        }
    }
}

