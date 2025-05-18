from pymodbus.server import StartAsyncTcpServer
from pymodbus.datastore import ModbusSequentialDataBlock, ModbusSlaveContext, ModbusServerContext
from pymodbus.device import ModbusDeviceIdentification
from loguru import logger
import asyncio
import os
from dotenv import load_dotenv

class ModbusTCPServer:
    def __init__(self, host="0.0.0.0", port=502):
        """
        Инициализация Modbus TCP сервера
        
        Args:
            host (str): IP-адрес для прослушивания
            port (int): Порт для прослушивания
        """
        self.host = host
        self.port = port
        self.context = None
        self.server = None
        self._setup_datastore()
        self._setup_identification()

    def _setup_datastore(self):
        """Настройка хранилища данных Modbus"""
        # Инициализация блоков данных для разных типов регистров
        self.store = ModbusSlaveContext(
            di=ModbusSequentialDataBlock(0, [0] * 100),  # Discrete Inputs
            co=ModbusSequentialDataBlock(0, [0] * 100),  # Coils
            hr=ModbusSequentialDataBlock(0, [0] * 100),  # Holding Registers
            ir=ModbusSequentialDataBlock(0, [0] * 100)   # Input Registers
        )
        self.context = ModbusServerContext(slaves=self.store, single=True)

    def _setup_identification(self):
        """Настройка идентификации устройства"""
        self.identity = ModbusDeviceIdentification()
        self.identity.VendorName = 'Custom Modbus Server'
        self.identity.ProductCode = 'CMS'
        self.identity.VendorUrl = 'http://github.com/your-repo'
        self.identity.ProductName = 'Modbus TCP Server'
        self.identity.ModelName = 'Modbus TCP Server'
        self.identity.MajorMinorRevision = '1.0'

    async def start(self):
        """Запуск сервера"""
        try:
            logger.info(f"Запуск Modbus TCP сервера на {self.host}:{self.port}")
            self.server = await StartAsyncTcpServer(
                context=self.context,
                identity=self.identity,
                address=(self.host, self.port)
            )
        except Exception as e:
            logger.error(f"Ошибка при запуске сервера: {e}")
            raise

    def update_register(self, register_type, address, value):
        """
        Обновление значения регистра
        
        Args:
            register_type (str): Тип регистра ('di', 'co', 'hr', 'ir')
            address (int): Адрес регистра
            value (int): Новое значение
        """
        try:
            self.store.setValues(register_type, address, [value])
            logger.info(f"Обновлен регистр {register_type} по адресу {address}: {value}")
        except Exception as e:
            logger.error(f"Ошибка при обновлении регистра: {e}")

    def get_register(self, register_type, address):
        """
        Получение значения регистра
        
        Args:
            register_type (str): Тип регистра ('di', 'co', 'hr', 'ir')
            address (int): Адрес регистра
            
        Returns:
            int: Значение регистра
        """
        try:
            return self.store.getValues(register_type, address, 1)[0]
        except Exception as e:
            logger.error(f"Ошибка при получении значения регистра: {e}")
            return None

async def main():
    """Основная функция запуска сервера"""
    # Загрузка конфигурации из .env файла
    load_dotenv()
    
    # Получение настроек из переменных окружения или использование значений по умолчанию
    host = os.getenv('MODBUS_HOST', '0.0.0.0')
    port = int(os.getenv('MODBUS_PORT', 502))
    
    # Создание и запуск сервера
    server = ModbusTCPServer(host=host, port=port)
    await server.start()
    
    # Держим сервер запущенным
    while True:
        await asyncio.sleep(1)

if __name__ == "__main__":
    # Настройка логирования
    logger.add("modbus_server.log", rotation="1 day", retention="7 days")
    
    # Запуск сервера
    asyncio.run(main()) 