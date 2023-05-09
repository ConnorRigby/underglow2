# coneRGB BLE Profile

## Implemented Services

Each service is based on a root UUID: `000069XY-0000-1000-8000-00805F9B34FB`

Where XY encodes the `Service` and `Characteristic` respectively.

|service|characteristic|description|
|-|-|-|
|00006910||[RGB Channel 1](#rgb-channel-1-and-2)|
||00006911|[NZR Channel 1](#nzr-neopixel)|
||00006912|[RGB Channel 1](#rgb)|
||||
|00006920||[RGB Channel 2](#rgb-channel-1-and-2)|
||00006921|[NZR Channel 2](#nzr-neopixel)|
||00006922|[RGB Channel 2](#rgb)|
||||
|00006930||[sync config](#sync-config)|
||00006931|[Network ID](#network-id)|
||00006932|[Role](#role)|
||00006933|[Status](#status)|
||00006934|[Node ID](#node-id)|
||||
|00006940||[Programmable Input Config](#programmable-input)|
||00006941|[Programmable Input 1](#proogrammable-input-channel-config)|
||00006942|[Programmable Input 2](#proogrammable-input-channel-config)|
||00006943|[Programmable Input 3](#proogrammable-input-channel-config)|
||00006944|[Programmable Input 4](#proogrammable-input-channel-config)|

## RGB Channel 1 and 2

These services are both exactly the same, the only difference is the hardware configuration on the device.

### NZR (Neopixel)

**Payload size**: 4 bytes

byte|0|1|2|3|
|-|-|-|-|-|
||pattern|Red|Green|Blue|

|id|pattern|
|-|-|
|0x00|off|
|0x01|rainbow|
|0x02|snake|
|0x03|fill|

### RGB

**Payload size**: 3 bytes

|byte|0|1|2|
|-|-|-|-|
||red|green|blue|

## Sync Config

### Network ID

### Role

### Status

### Node ID

## Programmable Input

### Proogrammable Input Channel Config