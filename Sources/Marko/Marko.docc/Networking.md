# Networking

Overview of UDP networking

## Overview

![](udp-client-server.png)

## Netcat Testing

``` bash
nc -u -l 12345
```

## Open Source Interconnection (OSI) model

| No. | Layer        | Description ( in simple terms and not academic in nature )                 |
|-----|--------------|----------------------------------------------------------------------------|
| 7   | Application  | High level API(e.g HTTP, Websocket) |
| 6   | Presentation | This is where the data form the network is translated to the application (encoding,  compression, encryption). This is where TLS lives. |
| 5   | Session      | Where the sessions are established, think Sockets. |
| 4   | Transport    | Provides the means to send variable length data sequences. Think TCP, UDP. |
| 3   | Network      | Provides the capability to send data sequences between different networks. Think of routing of datagrams. |
| 2   | Data link    | This layer is in charge of the node to node data transfer. Directly connected nodes. |
| 1   | Physical     | In this layer data is transmitted/received to/from a physical device. |

![](udp-encapsulation.png)

## Packet Header

![](tcp-udp-headers.jpg)

### TCP (Transmission Control Protocol)

The Transmission Control Protocol (TCP) is a core protocol of the
Internet Protocol Suite. TCP provides reliable, ordered, and
error-checked delivery of a stream of octets between applications
running on hosts communicating over an IP network.


```
0                   1                   2                   3
0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|          Source Port          |       Destination Port        |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                        Sequence Number                        |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                    Acknowledgment Number                      |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|  Data |           |U|A|P|R|S|F|                               |
| Offset| Reserved  |R|C|S|S|Y|I|            Window             |
|       |           |G|K|H|T|N|N|                               |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|           Checksum            |         Urgent Pointer        |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                    Options                    |    Padding    |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                             data                              |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

TCP Port   | Service
---------- | -------------------------------------------------
21         | IRC
22         | SSH
25         | STMP
80         | Http
123        | Network Time Server
443        | Https
445        | SMB
548        | Apple File Protocol (AFP) over TCP
3689       | iTunes using the iTunes Library Sharing feature
5009       | Airport admin utility
9100       | HP Jet Direct

### UDP (User Datagram Protocol)

UDP uses a simple connectionless transmission model with a minimum of
protocol mechanism. It has no handshaking dialogues, and thus exposes
any unreliability of the underlying network protocol to the user\'s
program. There is no guarantee of delivery, ordering, or duplicate
protection. UDP provides checksums for data integrity, and port numbers
for addressing different functions at the source and destination of the
datagram.


```
0        7 8     15 16    23 24    31
+--------+--------+--------+--------+
|     Source      |   Destination   |
|      Port       |      Port       |
+--------+--------+--------+--------+
|                 |                 |
|     Length      |    Checksum     |
+--------+--------+--------+--------+
|
|          data octets ...
+---------------- ...
```

UDP Port  | Service
----------|---------------
67,68     |  DHCP
123       |  NTP
5353      |  mDNS, Bonjour
17500     |  Dropbox
