#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Простой Modbus TCP сервер для отладки клиентов.
Поддерживаются функции:
  - 1 (Read Coils)
  - 5 (Write Single Coil)
  - 15 (Write Multiple Coils)
При ошибках возвращаются соответствующие Modbus-исключения.
"""

import socketserver
import struct
import threading
import logging
import traceback

# --- Настройка логирования ---
logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s [%(levelname)s] %(threadName)s %(message)s',
    datefmt='%Y-%m-%d %H:%M:%S'
)

# --- Глобальное хранилище coil с блокировкой для потоков ---
coil_store = {}             # адрес -> 0/1
coil_lock = threading.Lock()

# Пример группировки coil
coil_groups = {
    'motors': [0, 1, 2],
    'valves': [10, 11, 12]
}

# --- Вспомогательные функции для упаковки/распаковки битов ---
def pack_bits(bits):
    """Превращает список 0/1 в байты по Modbus-стандарту."""
    result = bytearray((len(bits) + 7) // 8)
    for i, bit in enumerate(bits):
        if bit:
            result[i // 8] |= 1 << (i % 8)
    return bytes(result)

def unpack_bits(data, count):
    """Превращает байты в список битов длины count."""
    bits = []
    for i in range(count):
        byte = data[i // 8]
        bits.append((byte >> (i % 8)) & 1)
    return bits

# --- Построение MBAP-заголовка ---
def build_mbap(transaction_id, protocol_id, unit_id, pdu):
    length = len(pdu) + 1  # +1 байт Unit ID
    return struct.pack('>HHHB', transaction_id, protocol_id, length, unit_id) + pdu

# --- Обработка PDU (Modbus Protocol Data Unit) ---
def process_pdu(function_code, data):
    with coil_lock:
        # Функция 1: Read Coils
        if function_code == 1:
            if len(data) != 4:
                raise ModbusException(3, 'Неверная длина запроса для Read Coils')
            addr, qty = struct.unpack('>HH', data)
            if qty < 1 or qty > 2000:
                raise ModbusException(3, 'Количество вне диапазона (1-2000)')
            bits = [coil_store.get(i, 0) for i in range(addr, addr + qty)]
            byte_count = len(bits) // 8 + (1 if len(bits) % 8 else 0)
            byte_data = pack_bits(bits)
            return struct.pack('>BB', 1, byte_count) + byte_data

        # Функция 5: Write Single Coil
        elif function_code == 5:
            if len(data) != 4:
                raise ModbusException(3, 'Неверная длина запроса для Write Single Coil')
            addr, value = struct.unpack('>HH', data)
            if value not in (0x0000, 0xFF00):
                raise ModbusException(3, 'Недопустимое значение Coil (0x0000 или 0xFF00)')
            coil_store[addr] = 1 if value == 0xFF00 else 0
            return struct.pack('>BHH', 5, addr, value)

        # Функция 15: Write Multiple Coils
        elif function_code == 15:
            if len(data) < 5:
                raise ModbusException(3, 'Слишком короткий запрос для Write Multiple Coils')
            addr, qty, byte_count = struct.unpack('>HHB', data[:5])
            raw = data[5:]
            if len(raw) != byte_count:
                raise ModbusException(3, 'Byte count не соответствует данным')
            bits = unpack_bits(raw, qty)
            for i, bit in enumerate(bits):
                coil_store[addr + i] = bit
            return struct.pack('>BHH', 15, addr, qty)

        else:
            raise ModbusException(1, f'Функция {function_code} не поддерживается')

# --- Исключение для Modbus-ошибок ---
class ModbusException(Exception):
    def __init__(self, code, message=''):
        super().__init__(message)
        self.code = code

# --- Обработчик каждого TCP-соединения ---
class ModbusTCPHandler(socketserver.BaseRequestHandler):
    def handle(self):
        client = self.client_address[0]
        logging.info(f'Новое подключение от {client}')
        try:
            while True:
                # Читаем MBAP-заголовок (7 байт)
                header = self.request.recv(7)
                if not header:
                    logging.info(f'Клиент {client} отключился')
                    break
                tid, pid, length, uid = struct.unpack('>HHHB', header)
                # Читаем PDU
                pdu = self.request.recv(length - 1)
                if len(pdu) < 1:
                    raise ModbusException(4, 'Пустой PDU')
                fc = pdu[0]
                body = pdu[1:]
                logging.debug(f'Получен запрос от {client}: TID={tid}, FUNC={fc}, BODY={body.hex()}')
                try:
                    resp_pdu = process_pdu(fc, body)
                except ModbusException as me:
                    # Формируем исключительный ответ
                    logging.warning(f'ModbusException: Code={me.code}, {me}')
                    resp_pdu = struct.pack('>BB', fc + 0x80, me.code)
                resp = build_mbap(tid, pid, uid, resp_pdu)
                self.request.sendall(resp)
                logging.debug(f'Отправлен ответ клиенту {client}: {resp.hex()}')
        except Exception as e:
            logging.error(f'Ошибка в обработчике {client}: {e}')
            traceback.print_exc()

# --- Консольный интерфейс для управления coil на лету ---
class CoilCLI(threading.Thread):
    def __init__(self):
        super().__init__(daemon=True, name='CoilCLI')
    def run(self):
        print('CLI> введите "help" для списка команд')
        while True:
            cmd = input('CLI> ').strip().split()
            if not cmd: continue
            if cmd[0] == 'show':
                with coil_lock:
                    print('Coil state:', coil_store)
            elif cmd[0] == 'set' and len(cmd) == 3:
                addr, val = int(cmd[1]), int(cmd[2])
                with coil_lock:
                    coil_store[addr] = 1 if val else 0
                print(f'Установлен coil[{addr}] = {coil_store[addr]}')
            elif cmd[0] == 'toggle' and len(cmd) == 2:
                addr = int(cmd[1])
                with coil_lock:
                    coil_store[addr] = 0 if coil_store.get(addr,0) else 1
                print(f'Coil[{addr}] теперь {coil_store[addr]}')
            elif cmd[0] == 'groups':
                print('Группы:', coil_groups)
            elif cmd[0] == 'help':
                print('Команды: show, set <addr> <0|1>, toggle <addr>, groups, help')
            else:
                print('Неизвестная команда. help для справки.')

# --- Запуск сервера ---
def start_server(host='0.0.0.0', port=5020):
    CoilCLI().start()
    server = socketserver.ThreadingTCPServer((host, port), ModbusTCPHandler)
    logging.info(f'Modbus TCP сервер запущен на {host}:{port}')
    server.serve_forever()

if __name__ == '__main__':
    start_server()
