# Modbus TCP Клиент Kawasaki

Этот проект представляет собой реализацию Modbus TCP клиента на AS, который может работать в локальной сети и обрабатывать кастомные запросы.
ВНИМАНИЕ, ПРОЕКТ НАХОДИТСЯ В РАЗРАБОТКЕ.
На данный момент программно протестировано и работает всё описанное ниже

## Особенности

- Поддержка всех стандартных функций Modbus
- Поддержка различных типов регистров (Coils, Discrete Inputs, Holding Registers, Input Registers)

## Установка
Клиент:
1. Просто загрузите в робота AS файл

Python-сервер для тестов:
1. Клонируйте репозиторий
2. Установите зависимости:
```bash
pip install -r requirements.txt
```

## Конфигурация
Настройки клиента хранятся в программе initModbus.pc
Установка IP адреса робота осуществляется отдельно
> На роботе, R 812, или через терминал

Настройки сервера хранятся в файле `.env`:
- MODBUS_HOST - IP-адрес для прослушивания (по умолчанию 0.0.0.0)
- MODBUS_PORT - порт для прослушивания (по умолчанию 502)

## Запуск
Клиент:
Запустить ModbusTCP.pc в одном из PC-слотов

Сервер:
```bash
python modbus_server.py
```

## Использование
Клиент после запуска pc-программы поддерживает вызов таких функций как:
- Чтение Discrete Input
- Чтение Discrete Output
- Чтение Analog Input
- Чтение Analog Output
- Запись одного Discrete Output
- Запись одного Analog Output
- Запись нескольких Discrete Output
- Запись нескольких Analog Output

Сервер поддерживает следующие типы регистров:
- 'co' - Coils (дискретные выходы)
- 'di' - Discrete Inputs (дискретные входы)
- 'hr' - Holding Registers (регистры хранения)
- 'ir' - Input Registers (регистры ввода)

### Пример работы с регистрами
Клиент:
- Пример чтения и изменения регистров находится в программе Example
- Пример отправки кастомного сообщения находится в программе ManualExample.pc
Сервер:
```python
# Обновление значения регистра
server.update_register('hr', 0, 100)  # Установка значения 100 в holding register по адресу 0

# Получение значения регистра
value = server.get_register('hr', 0)  # Получение значения из holding register по адресу 0
```

## Логирование
Клиент:
В разработке
Сервер:
Логи сохраняются в файл `modbus_server.log` с ежедневной ротацией и хранением в течение 7 дней. 
