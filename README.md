# Disclamer
This is unofficial independent project for interoperability/testing purposes. Not affiliated with or endorsed by Kawasaki Heavy Industries, Kawasaki Robotics, or the Modbus Organization
# Modbus TCP Client for Kawasaki Robots
This project provides a Modbus TCP client implementation for Kawasaki robots using the standard AS language environment.
It is intended for practical integration, interoperability, and testing in local network setups.

## Project Status

This project is currently a work in progress.
The functionality described below has been tested and implemented in various cells.
Before using it in a production environment, validate the behavior on your target controller, network, and target Modbus device.

## Features

- Modbus TCP client implemented in Kawasaki AS language
- Support for the main Modbus TCP data models:
  - Coils
  - Discrete Inputs
  - Holding Registers
  - Input Registers
- Support for core read/write Modbus TCP operations
- Python-based test server for local validation
- Example AS program for basic read/write interaction
- Basic debug logging on the robot side

## Supported Function Codes

| Function Code | AS Program   | Description |
|---|---|---|
| `0x01` | `ReadDO.pc`   | Read Coils |
| `0x02` | `ReadDI.pc`   | Read Discrete Inputs |
| `0x03` | `ReadAO.pc`   | Read Holding Registers |
| `0x04` | `ReadAI.pc`   | Read Input Registers |
| `0x05` | `WriteSDO.pc` | Write Single Coil |
| `0x06` | `WriteSAO.pc` | Write Single Holding Register |
| `0x0F` | `WriteMDO.pc` | Write Multiple Coils |
| `0x10` | `WriteMAO.pc` | Write Multiple Holding Registers |

## Connection Model

The robot acts as a TCP client and opens an outbound connection to a Modbus TCP server.

Important details:

- The **client-side source port** on the robot is assigned dynamically by the controller when the TCP connection is created.
- The **server listening port** must be configured explicitly.
- In this setup, the **server port must be within the range `8192-65535`**.
- The server port configured in `initModbus.pc` must match the listening port configured on the server side.

In other words, the robot-side source port is not configured manually, while the target server port is part of the client configuration.

## Repository Structure

- `modbusTCP.as` — main AS implementation, helper routines, initialization, and example program
- `modbus_server.py` — asynchronous Python Modbus TCP test server
- `modbus_server_custom_logs.py` — logging setup for the Python test server
- `test_modbus_client.py` — simple smoke test for the test server
- `requirements.txt` — Python dependencies for the test environment

## Installation

### Robot Client

1. Upload `modbusTCP.as` to the robot controller.
2. Make sure the programs are available on the controller after import.

### Python Test Environment

1. Clone the repository.
2. Install the dependencies:

```bash
pip install -r requirements.txt
```

## Configuration

### Robot Client

Client settings are defined in `initModbus.pc` inside `modbusTCP.as`.
Update these values before running the client:

- `ip[0..3]` — target Modbus TCP server IP address
- `port` — target Modbus TCP server listening port (`8192-65535`)
- `mbap[2]` — Modbus Unit ID

Robot controller network settings such as the robot IP address are configured separately on the controller side.
Robot controller and modbus server device must be in one subnet

### Python Test Server

Server settings can be provided through a `.env` file:

```env
MODBUS_HOST=0.0.0.0
MODBUS_PORT=12000
```

Use a server port in the range `8192-65535`.
Make sure it matches the port configured in `initModbus.pc`.

## Running

### Python Test Server

```bash
python modbus_server.py
```

### Robot Client

Start `ModbusTCP.pc` in a free PC slot.
The included `Example()` program can be used as a reference for basic read/write interaction.

## Usage

After `ModbusTCP.pc` is running, the following AS programs are available for read/write operations:

- `ReadDO.pc`
- `ReadDI.pc`
- `ReadAO.pc`
- `ReadAI.pc`
- `WriteSDO.pc`
- `WriteSAO.pc`
- `WriteMDO.pc`
- `WriteMAO.pc`

## Python Test Server Register Types

The Python test server supports the following register groups:

- `co` — Coils
- `di` — Discrete Inputs
- `hr` — Holding Registers
- `ir` — Input Registers

Example:

```python
# Update a register value
server.update_register('hr', 0, 100)

# Read a register value
value = server.get_register('hr', 0)
```

## Example

A basic usage example is included in the `Example()` AS program.
It demonstrates:

- reading coils and discrete inputs
- reading holding and input registers
- writing a single coil / holding register
- writing multiple coils / holding registers

## Logging

### Robot Side

Basic debug output is implemented through:

- `slog.pc`
- `rlog.pc`

Logging is controlled by the boolean variable `debug`.

### Python Server Side

Server logs are written to `modbus_server.log` with daily rotation and 7-day retention.

## Notes

- Terminology inside the AS source uses `DO/DI/AO/AI` naming, while this README maps those calls to standard Modbus terminology.
- The repository is intended for practical interoperability and testing.
- If you use this project in a production environment, validate behavior on the actual controller and target Modbus device.
