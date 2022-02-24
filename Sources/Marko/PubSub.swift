//


import Network
import Foundation



class Publisher<ItemType> where ItemType: MSocket {
    var sock: ItemType?
    
    init(socket: ItemType){
        self.sock = socket
    }
    
    public func publish(_ data: Data){
        print(data)
        self.sock?.send(data)
    }
}

class Subscriber<ItemType> where ItemType: MSocket {
    var sock: ItemType?
    
    init(socket: ItemType){
        self.sock = socket
    }
    
    func subscribe(topic: String){
        guard let d = "s:\(topic)".data(using: String.Encoding.utf8) else { return }
        self.sock?.send(d)
    }
    
    public func loop(closure: (Data)->Void){
        var data: Data?
        self.sock?.receive(){d in
            data = d
        }
        if let d = data, !d.isEmpty {
            closure(d)
        }
    }
}

func test(){
    let sock = UDPBind()
    try! sock.bind(host: "1.2.3.4", port: 5000)
    let pub = Publisher<UDPBind>(socket: sock)
    pub.publish("hi".data(using: String.Encoding.utf8)!)
}
