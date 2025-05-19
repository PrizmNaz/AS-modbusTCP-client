from pymodbus.client import AsyncModbusTcpClient
import asyncio
from loguru import logger

async def test_modbus_server():
    # Подключение к серверу
    client = AsyncModbusTcpClient('192.168.0.41', port=12389)
    await client.connect()
    
    try:
        # Тест чтения holding registers
        result = await client.read_holding_registers(0, 1)
        logger.info(f"Чтение holding register: {result.registers[0]}")
        
        # Тест записи holding register
        await client.write_register(0, 100)
        logger.info("Запись значения 100 в holding register")
        
        # Проверка записанного значения
        result = await client.read_holding_registers(0, 1)
        logger.info(f"Проверка записанного значения: {result.registers[0]}")
        
        # Тест чтения coils
        result = await client.read_coils(0, 1)
        logger.info(f"Чтение coil: {result.bits[0]}")
        
        # Тест записи coil
        await client.write_coil(0, True)
        logger.info("Запись True в coil")
        
        # Проверка записанного значения
        result = await client.read_coils(0, 1)
        logger.info(f"Проверка записанного значения coil: {result.bits[0]}")
        
    except Exception as e:
        logger.error(f"Ошибка при тестировании: {e}")
    finally:
        client.close()

if __name__ == "__main__":
    asyncio.run(test_modbus_server()) 