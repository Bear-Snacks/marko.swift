//
//  File.swift
//  
//
//  Created by Kevin Walchko on 2/23/22.
//

import Network
import Foundation


/// Creates a UDP socket that is bound to an ip:port.
@available(macOS 10.14, iOS 13, *)
public class UDPBind: MSocket {
    func send(_ content: String) {
        //
    }
    
    func receive(closure: @escaping (Data) -> Void) {
        //
    }
    
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
                //            case .setup:
                //                print("Server setup")
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
    
    public func receive() -> Data? { // FIXME
        return nil
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
