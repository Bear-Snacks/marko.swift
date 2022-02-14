import Network

public func sleeps(sec: Double){
    usleep(UInt32(sec * 1000000))
}

@available(macOS 10.14, *)
public class UDPSocket {
    var connection: NWConnection?
    var msg: String = "None"
    
    public init(ip: NWEndpoint.Host, port: NWEndpoint.Port) {
        
        self.connection = NWConnection(
            host: ip,
            port: port,
            using: .udp)
        
        self.connection?.stateUpdateHandler = { (state) in
            switch (state) {
            case .ready:
                print("UDPSocket: ready")
            case .setup:
                print("UDPSocket: setup")
            case .cancelled:
                print("UDPSocket: cancelled")
            case .preparing:
                print("UDPSocket: preparing")
            default:
                print("waiting or failed")
            }
        }
        
        self.connection?.start(queue: .global())
    }
    
    deinit {
        self.connection?.cancel()
    }
    
    public func send(_ content: String) {
        let contentToSendUDP = content.data(using: String.Encoding.utf8)
        self.connection?.send(
            content: contentToSendUDP,
            completion: NWConnection.SendCompletion.contentProcessed({ NWError in
                if (NWError != nil) {
                    print("*** UDPSocket send() error: \(NWError!)")
                }
            }))
    }
    
    public func receive() -> String {
        self.connection?.receiveMessage { (data, context, isComplete, error) in
            if (isComplete) {
                if (data != nil) {
                    self.msg = String(decoding: data!, as: UTF8.self)
                } else {
                    print("Data == nil")
                }
            }
        }
        return self.msg
    }
    
    public func printAddresses() {
        var addrList : UnsafeMutablePointer<ifaddrs>?
        guard
            getifaddrs(&addrList) == 0,
            let firstAddr = addrList
        else { return }
        defer { freeifaddrs(addrList) }
        for cursor in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interfaceName = String(cString: cursor.pointee.ifa_name)
            let addrStr: String
            var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
            if
                let addr = cursor.pointee.ifa_addr,
                getnameinfo(addr, socklen_t(addr.pointee.sa_len), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST) == 0,
                hostname[0] != 0
            {
                addrStr = String(cString: hostname)
            } else {
                addrStr = "?"
            }
            print(interfaceName, addrStr)
        }
        return
    }
    
    //    public func requestAuthorization(completion: @escaping (Bool) -> Void) {
    //        self.completion = completion
    //
    //        // Create parameters, and allow browsing over peer-to-peer link.
    //        let parameters = NWParameters()
    //        parameters.includePeerToPeer = true
    //
    //        // Browse for a custom service type.
    //        let browser = NWBrowser(for: .bonjour(type: "_bonjour._tcp", domain: nil), using: parameters)
    //        self.browser = browser
    //        browser.stateUpdateHandler = { newState in
    //            switch newState {
    //            case .failed(let error):
    //                print(error.localizedDescription)
    //            case .ready, .cancelled:
    //                break
    //            case let .waiting(error):
    //                print("Local network permission has been denied: \(error)")
    //                self.reset()
    //                self.completion?(false)
    //            default:
    //                break
    //            }
    //        }
    //
    //        self.netService = NetService(domain: "local.", type:"_lnp._tcp.", name: "LocalNetworkPrivacy", port: 1100)
    //        self.netService?.delegate = self
    //
    //        self.browser?.start(queue: .main)
    //        self.netService?.publish()
    //    }
}

