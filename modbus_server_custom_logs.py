#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Простой Modbus TCP сервер для отладки клиентов.
Теперь поддерживаются:
  - Coil (Read 1, Write 1, Write multiple)
  - Holding Register (Read 3, Write 6, Write multiple 16)
"""

import socketserver
import struct
import threading
import logging
import traceback
import os
from dotenv import load_dotenv

# --- Настройка логирования ---
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s [%(levelname)s] %(threadName)s %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)

# --- Хранилища и блокировки ---
coil_store     = {}               # адрес -> 0/1
register_store = {}               # адрес -> 0..65535
coil_lock      = threading.Lock()
reg_lock       = threading.Lock()

# Пример группировки
coil_groups = {
    'motors': [0, 1, 2],
    'valves': [10, 11, 12]
}
reg_groups = {
    'sensors': [0, 1, 2],
    'timers':  [100, 101]
}

# --- Вспомогательные функции для битов (coils) ---
def pack_bits(bits):
    result = bytearray((len(bits) + 7) // 8)
    for i, bit in enumerate(bits):
        if bit:
            result[i//8] |= 1 << (i%8)
    return bytes(result)

def unpack_bits(data, count):
    bits = []
    for i in range(count):
        bits.append((data[i//8] >> (i%8)) & 1)
    return bits

# --- Вспомогательные функции для регистров ---
def pack_regs(values):
    """Упаковать список 16-бит в big-endian байты."""
    return b''.join(struct.pack('>H', v & 0xFFFF) for v in values)

def unpack_regs(data, count):
    """Распаковать из байтов count регистров."""
    regs = []
    for i in range(count):
        regs.append(struct.unpack('>H', data[2*i:2*i+2])[0])
    return regs

# --- MBAP-заголовок ---
def build_mbap(tid, pid, uid, pdu):
    length = len(pdu) + 1
    return struct.pack('>HHHB', tid, pid, length, uid) + pdu

# --- Modbus-исключение ---
class ModbusException(Exception):
    def __init__(self, code, message=''):
        super().__init__(message)
        self.code = code

# --- Основная обработка PDU ---
def process_pdu(fc, data):
    # --- Coils ---
    if fc in (1,5,15):
        with coil_lock:
            # Read Coils
            if fc == 1:
                if len(data)!=4: raise ModbusException(3,'Неверная длина для Read Coils')
                addr, qty = struct.unpack('>HH', data)
                if not (1<=qty<=2000): raise ModbusException(3,'Qty вне 1..2000')
                bits = [coil_store.get(i,0) for i in range(addr, addr+qty)]
                bb = pack_bits(bits)
                return struct.pack('>BB',1,len(bb)) + bb

            # Write Single Coil
            if fc == 5:
                if len(data)!=4: raise ModbusException(3,'Неверная длина для Write Single Coil')
                addr, val = struct.unpack('>HH', data)
                if val not in (0x0000,0xFF00): raise ModbusException(3,'Неправильное значение coil')
                coil_store[addr] = 1 if val==0xFF00 else 0
                return struct.pack('>BHH',5,addr,val)

            # Write Multiple Coils
            if fc == 15:
                if len(data)<5: raise ModbusException(3,'Слишком короткий для Write Multiple Coils')
                addr, qty, bc = struct.unpack('>HHB', data[:5])
                raw = data[5:]
                if bc != len(raw): raise ModbusException(3,'Byte count mismatch')
                bits = unpack_bits(raw, qty)
                for i, b in enumerate(bits):
                    coil_store[addr+i] = b
                return struct.pack('>BHH',15,addr,qty)

    # --- Holding Registers ---
    elif fc in (3,6,16):
        with reg_lock:
            # Read Holding Registers
            if fc == 3:
                if len(data)!=4: raise ModbusException(3,'Неверная длина для Read Registers')
                addr, qty = struct.unpack('>HH', data)
                if not (1<=qty<=125): raise ModbusException(3,'Qty вне 1..125')
                vals = [register_store.get(i,0) for i in range(addr, addr+qty)]
                rb = pack_regs(vals)
                return struct.pack('>BB',3,len(rb)) + rb

            # Write Single Register
            if fc == 6:
                if len(data)!=4: raise ModbusException(3,'Неверная длина для Write Single Register')
                addr, val = struct.unpack('>HH', data)
                register_store[addr] = val
                return struct.pack('>BHH',6,addr,val)

            # Write Multiple Registers
            if fc == 16:
                if len(data)<5: raise ModbusException(3,'Слишком короткий для Write Multiple Registers')
                addr, qty, bc = struct.unpack('>HHB', data[:5])
                raw = data[5:]
                if bc != len(raw): raise ModbusException(3,'Byte count mismatch')
                vals = unpack_regs(raw, qty)
                for i, v in enumerate(vals):
                    register_store[addr+i] = v
                return struct.pack('>BHH',16,addr,qty)

    # --- Неподдерживаемая функция ---
    raise ModbusException(1, f'Функция {fc} не поддерживается')

# --- TCP Handler ---
class ModbusTCPHandler(socketserver.BaseRequestHandler):
    def handle(self):
        client = self.client_address[0]
        logging.info(f'Подключился {client}')
        try:
            while True:
                hdr = self.request.recv(7)
                if not hdr:
                    logging.info(f'{client} отключился')
                    break
                tid, pid, length, uid = struct.unpack('>HHHB', hdr)
                pdu = self.request.recv(length-1)
                if not pdu: raise ModbusException(4,'Пустой PDU')
                fc = pdu[0]; body = pdu[1:]
                logging.debug(f'REQ from {client}: TID={tid} FC={fc} DATA={body.hex()}')
                try:
                    resp_pdu = process_pdu(fc, body)
                except ModbusException as me:
                    logging.warning(f'ModbusException: FC={fc} Code={me.code} {me}')
                    resp_pdu = struct.pack('>BB', fc|0x80, me.code)
                resp = build_mbap(tid, pid, uid, resp_pdu)
                self.request.sendall(resp)
                logging.debug(f'RESP to {client}: {resp.hex()}')
        except Exception as e:
            logging.error(f'Handler error for {client}: {e}')
            traceback.print_exc()

# --- CLI для ручной работы ---
class CoilCLI(threading.Thread):
    def __init__(self):
        super().__init__(daemon=True, name='CoilCLI')
    def run(self):
        print('CLI> help — список команд')
        while True:
            try:
                parts = input('CLI> ').split()
                if not parts: continue
                cmd = parts[0]
                # Coils
                if cmd == 'show':
                    with coil_lock:
                        print('Coils:', coil_store)
                elif cmd == 'set' and len(parts)==3:
                    a, v = int(parts[1]), int(parts[2])
                    with coil_lock:
                        coil_store[a] = 1 if v else 0
                    print(f'coil[{a}]={coil_store[a]}')
                elif cmd == 'toggle' and len(parts)==2:
                    a = int(parts[1])
                    with coil_lock:
                        coil_store[a] = 0 if coil_store.get(a,0) else 1
                    print(f'coil[{a}] now {coil_store[a]}')
                elif cmd == 'groups':
                    print('Coil groups:', coil_groups)

                # Registers
                elif cmd == 'showregs':
                    with reg_lock:
                        print('Registers:', register_store)
                elif cmd == 'setreg' and len(parts)==3:
                    a, v = int(parts[1]), int(parts[2])
                    with reg_lock:
                        register_store[a] = v & 0xFFFF
                    print(f'reg[{a}]={register_store[a]}')
                elif cmd == 'reggroups':
                    print('Reg groups:', reg_groups)

                elif cmd == 'help':
                    print(
                        'Commands:\n'
                        '  show               — показать coils\n'
                        '  set <addr> <0|1>   — установить coil\n'
                        '  toggle <addr>      — переключить coil\n'
                        '  groups             — показать coil-группы\n'
                        '  showregs           — показать registers\n'
                        '  setreg <addr> <v>  — установить register\n'
                        '  reggroups          — показать reg-группы\n'
                        '  help               — это меню'
                    )
                else:
                    print('Неизвестная команда, help для списка')
            except Exception as ex:
                print('Ошибка в CLI:', ex)

# --- Запуск ---
def start_server(host='192.168.0.41', port=12389):
    load_dotenv()

    host = os.getenv('MODBUS_HOST', '0.0.0.0')
    port = int(os.getenv('MODBUS_PORT', 502))
    
    CoilCLI().start()
    srv = socketserver.ThreadingTCPServer((host, port), ModbusTCPHandler)
    logging.info(f'Server started on {host}:{port}')
    srv.serve_forever()

if __name__ == '__main__':
    start_server()
