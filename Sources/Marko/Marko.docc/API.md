# API

Overview of the API

## Usage

### Connect

``` swift
func toBytes() -> [UInt8] {
    // convert something to bytes ...
}

let socket = UDPConnect()
socket.connect(host: "1.2.3.4", port: 9000)

let msg: [UInt8] = toBytes()
socket.send(msg)

let msg2: String = "Hello" // unicode only, no emoji
socket.send(msg2)
```


``` swift
let conn: NWConnection = getConnection()

let socket = UDPConnect(connection: conn)
```

### Bind

``` swift
let ip = getIPAddress()
let server = UDPBind()
server.bind(host: ip, port: 9500)
```

### Converting to a Byte Array

``` swift
struct Bob {
    let a: Double
    let b: Int16
    
    func pack() -> [UInt8] {
        var buffer: [UInt8] = []
        buffer.append(0xfe)
        buffer.append(contentsOf: toByteArray(self.a))
        buffer.append(contentsOf: toByteArray(self.b))
        
        print("buffer size: \(buffer.count)")
        return buffer
    }
}
```
