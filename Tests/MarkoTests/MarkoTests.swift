import XCTest
@testable import Marko

final class MarkoTests: XCTestCase {
    func testBind() throws {
//        XCTAssertEqual("Hello, World!", "Hello, World!")
        
        let bind = UDPBind()
        try! bind.bind(host: "1.2.3.4", port: 5000)
        
        _ = Publisher<UDPBind>(socket: bind)
        _ = Subscriber<UDPBind>(socket: bind)
    }
    
    func testConnectUDP() throws {
        
        let conn = UDPConnect()
        conn.connect(host: "1.2.3.4", port: 5000, transport: .udp)
        
        _ = Publisher<UDPConnect>(socket: conn)
        _ = Subscriber<UDPConnect>(socket: conn)
    }
    
    func testConnectTCP() throws {
        
        let conn = UDPConnect()
        conn.connect(host: "1.2.3.4", port: 5000, transport: .tcp)
        
        _ = Publisher<UDPConnect>(socket: conn)
        _ = Subscriber<UDPConnect>(socket: conn)
    }
}
