# Raspberry Pi MQTT Monitor

[![GitHub release (latest by date)](https://img.shields.io/github/v/release/danmrossi/rpi-mqtt-monitor-v2)](https://github.com/danmrossi/rpi-mqtt-monitor-v2/releases)
[![GitHub repo size](https://img.shields.io/github/repo-size/danmrossi/rpi-mqtt-monitor-v2)](https://github.com/danmrossi/rpi-mqtt-monitor-v2)
[![GitHub issues](https://img.shields.io/github/issues/danmrossi/rpi-mqtt-monitor-v2)](https://github.com/danmrossi/rpi-mqtt-monitor-v2/issues)
[![GitHub closed issues](https://img.shields.io/github/issues-closed/danmrossi/rpi-mqtt-monitor-v2)](https://github.com/danmrossi/rpi-mqtt-monitor-v2/issues?q=is%3Aissue+is%3Aclosed)
[![GitHub language count](https://img.shields.io/github/languages/count/danmrossi/rpi-mqtt-monitor-v2)](https://github.com/danmrossi/rpi-mqtt-monitor-v2)
[![GitHub top language](https://img.shields.io/github/languages/top/danmrossi/rpi-mqtt-monitor-v2)](https://github.com/danmrossi/rpi-mqtt-monitor-v2)

<p align="center">
  <img src="./images/rpi-mqtt-monitor-v2-2-min.png" alt="Raspberry Pi MQTT Monitor" />
</p>

My variant of https://github.com/hjelev/rpi-mqtt-monitor as of v1.2.3 - A multitude of stability fixes and coding improvements for running on various platforms.

The easiest way to track your Raspberry Pi or Ubuntu computer system health and performance in Home Assistant.

Python 3 is required to run this project.

* Start Monitoring your System in just a few minutes
* Monitor: CPU Load, CPU Temperature, Free Space, Used Memory, Swap Usage, Uptime, WFi Signal Quality, Network IO, Voltage, RPi Power Health, RPi5 Fan Speed, APT Updates available on HOST, External Sensors, HDD/SSD Temperature and System Clock Speed
* Remotely Restart / Shutdown your system and control your monitors
* Automatic HASS Configuration: Supports discovery messages, so no manual configuration in [Home Assistant](https://www.home-assistant.io/) configuration.yaml is needed
* Automated Installation and Configuration: You can install it and schedule it with a service or cron job with just one command from shell
* Easy Removal, just run rpi-mqtt-monitor-v2 --uninstall
* Configurable: You can select what is monitored and how the message(s) are sent (separately or as one csv message)
* Easy update: Run `rpi-mqtt-monitor-v2 --version` to check for updates and install them, or call `rpi-mqtt-monitor-v2 --update` directly or via Home Assistant UI
* Support multiple languages: English, German and Bulgarian

## Installation

### Automated

Run this command to use the automated installation:

```bash
bash <(curl -s https://raw.githubusercontent.com/danmrossi/rpi-mqtt-monitor-v2/master/remote_install.sh)
```

Raspberry Pi MQTT Monitor will be installed in the location where the installer is called, inside a folder named rpi-mqtt-monitor-v2.

The auto-installer needs the following software below and will install it if its not found:

* git
* python3
* python3-pip
* python3-venv
* paho-mqtt (python module)
* requests (python module)

The auto-installer will attempt to install Python 3 and its required packages if they are missing.
It will also help you configure the host and credentials for the mqtt server in config.py and create the service or cronjob configuration for you.
It is recommended to run the script as a service, this way you can use the restart, shutdown and display control buttons in Home Assistant.


## Uninstallation

To uninstall Raspberry Pi MQTT Monitor, run the following command:

```bash
rpi-mqtt-monitor-v2 --uninstall
```

## CLI arguments

```
usage: rpi-mqtt-monitor-v2 [-h] [-H] [-d] [-s] [-v] [-u] [-w] [--uninstall]

Monitor CPU Load, temperature, frequency, free space, etc., and publish the data to an MQTT server or Home Assistant API.

options:
  -h, --help       show this help message and exit
  -H, --hass_api   send readings via Home Assistant API (not via MQTT)
  -d, --display    display values on screen
  -s, --service    run script as a service, sleep interval is configurable in config.py
  -v, --version    show installed and latest version, optionally update
  -u, --update     update script and config then exit
  -w, --hass_wake  display Home assistant wake on lan configuration
  --uninstall      uninstall rpi-mqtt-monitor-v2 and remove all related files

```

## Home Assistant Integration

If you are using discovery_messages, then this step is not required as a new MQTT device will be automatically created in Home Assistant and all you need to do is add it to a dashboard.

Use '''rpi-mqtt-monitor-v2 --hass_wake''' to display the configuration for Home Assistant wake on lan switch.

