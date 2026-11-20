# Shopping list

## Network

- [ ] Ziggo/Vodafone SmartWifi pod (Marktplaats, ~€15) or TP-Link TL-WA850RE repeater (~€20)
  - Extends WiFi to the boiler/smart-meter spot; needed by the P1 meter and the EMS-ESP ESP32 (both 2.4GHz only).

## Home Assistant

- [ ] [HomeWizard Wi-Fi P1 meter](https://www.bol.com/nl/nl/p/wi-fi-energie-monitor-p1-meter-inzicht-in-je-stroomverbruik-via-app/9300000005832994/) (~€34)
  - Reads the smart meter P1 port: live power (W), import/export per tariff, gas.
  - Local-only API, native HA integration (`homewizard`).
  - Setup: connect to WiFi via HomeWizard app, give it a DHCP reservation/static IP.

- [ ] [Sonoff ZBDongle Plus MG24](https://sonoff.tech/en-us/products/sonoff-zigbee-thread-usb-dongle-dongle-plus-mg24) (~€25)
  - EFR32MG24, runs as Thread RCP for the OpenThread Border Router.
  - Dedicated to Thread/Matter devices; existing Sonoff dongle stays Zigbee-only.
  - Needs RCP firmware; the OTBR flashes this automatically on startup.
  - Alternative: [Home Assistant Connect ZBT-2](https://www.seeedstudio.com/Home-Assistant-Connect-ZBT-2-p-6573.html) (official reference hardware, ~€40 + shipping from Seeed).

## Heating

Connects the Bosch 24 HRC Compact 3 (2011, EMS bus) to HA via EMS-ESP over MQTT.
Boiler has an EMS service jack on the front right of the display.

- [ ] [EMS interface board V3.1](https://bbqkees-electronics.nl/product/ems-interface-board-v3-1/) (€34,95)
- [ ] [EMS service cable 50cm](https://bbqkees-electronics.nl/product/ems-service-cable-50cm/) (€4,95)
- [ ] ESP32-S3 devkit with PSRAM, e.g. Wemos Lolin S3 N16R8 (~€11)
  - EMS-ESP recommends ESP32-S3; RX=GPIO5, TX=GPIO8 on the Lolin S3.
  - No soldering: 4 jumper wires to the interface board, USB power supply needed (spare phone charger works).
  - Firmware: flash EMS-ESP32 from https://emsesp.github.io/docs/ via the browser.
