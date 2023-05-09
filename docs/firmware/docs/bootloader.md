# coneRGB STM32 Bootloader

To facilitate over the air updates, coneRGB implements a custom bootloader.

```puml
@startuml
(*) --> "Power On Reset"

if "Update Status" then
  -left-> [started]"Enter Bootloader"
  --> copy update into flash
  -right->[jump to main application] (*)
else
  ->[no update] "Increment boot counter"
  -->[jump to main application] (*)
endif

@enduml
```

## Over The Air Update Procedure

* Initiate a firmware update over a supported transport (BLE, CAN)
* Write the entire update binary
* Initiate a reset
* The bootloader will now copy the update payload into flash
