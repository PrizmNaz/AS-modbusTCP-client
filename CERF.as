.INTER_PANEL_D
.END
.INTER_PANEL_TITLE
"",0
"",0
"",0
"",0
"",0
"",0
"",0
"",0
"",0
"",0
"",0
"",0
"",0
"",0
"",0
"",0
.END
.INTER_PANEL_COLOR_D
182,3,224,244,28,159,252,255,251,255,0,31,2,241,52,219,
.END
.PROGRAM Example ()
  result[0] = 0
  addr[0] = 0
  addr[1] = 0
  count = 3
  warn = 0
  PRINT "################################ "
  PRINT "--------- Read first ---------"
  CALL ReadDO.pc(addr[], result[], count, warn)
  ;
  PRINT "ReadDO sent. Err: ", warn
  if warn == 0 THEN
    for i=0 TO count -1
      PRINT "DO#", i, " = ", result[i]
    END
  END
  ;
  CALL ReadDI.pc(addr[], result[], count, warn)
  ;
  PRINT "ReadDI sent. Err: ", warn
  if warn == 0 THEN
    for i=0 TO count -1
      PRINT "DI#", i, " = ", result[i]
    END
  END
  ;
  CALL ReadAO.pc(addr[], result[], count, warn)
  ;
  PRINT "ReadAO sent. Err: ", warn
  if warn == 0 THEN
    for i=0 TO count -1
      PRINT "AO#", i, " = ", result[i]
    END
  END
  ;
  CALL ReadAI.pc(addr[], result[], count, warn)
  ;
  PRINT "ReadAI sent. Err: ", warn
  if warn == 0 THEN
    for i=0 TO count -1
      PRINT "AI#", i, " = ", result[i]
    END
  END
  ;
  ;
  ;
  PRINT "--------- Single change ---------"
  CALL WriteSDO.pc(addr[], result[], 1, warn)
  ;
  PRINT "WriteSDO sent. Err: ", warn
  if warn == 0 THEN
    PRINT "DO_state", i, " = ", result[0]
  END
  ;
  CALL WriteSAO.pc(addr[], result[], 10002, warn)
  ;
  PRINT "ReadAO sent. Err: ", warn
  if warn == 0 THEN
    PRINT "AO_state", i, " = ", result[0]
  END
  ;
  ;
  ;
  CALL ReadDO.pc(addr[], result[], count, warn)
  ;
  PRINT "ReadDO sent. Err: ", warn
  if warn == 0 THEN
    for i=0 TO count -1
      PRINT "DO#", i, " = ", result[i]
    END
  END
  ;
  CALL ReadDI.pc(addr[], result[], count, warn)
  ;
  PRINT "ReadDI sent. Err: ", warn
  if warn == 0 THEN
    for i=0 TO count -1
      PRINT "DI#", i, " = ", result[i]
    END
  END
  ;
  CALL ReadAO.pc(addr[], result[], count, warn)
  ;
  PRINT "ReadAO sent. Err: ", warn
  if warn == 0 THEN
    for i=0 TO count -1
      PRINT "AO#", i, " = ", result[i]
    END
  END
  ;
  CALL ReadAI.pc(addr[], result[], count, warn)
  ;
  PRINT "ReadAI sent. Err: ", warn
  if warn == 0 THEN
    for i=0 TO count -1
      PRINT "AI#", i, " = ", result[i]
    END
  END
  ;
  ;
  ;
  PRINT "--------- Multiple change ---------"
  state[0] = 0
  state[1] = 0
  state[2] = 1
  CALL WriteMDO.pc(addr[], result[], state[], 3, warn)
  ;
  PRINT "WriteSDO sent. Err: ", warn
  if warn == 0 THEN
    PRINT "DO_wrote_cnt", i, " = ", result[0]
  END
  ;
  state[0] = 0
  state[1] = 10
  state[2] = 100
  CALL WriteMAO.pc(addr[], result[],state[], 3, warn)
  ;
  PRINT "ReadAO sent. Err: ", warn
  if warn == 0 THEN
    PRINT "AO_wrote_cnt", i, " = ", result[0]
  END
  ;
  CALL ReadDO.pc(addr[], result[], count, warn)
  ;
  PRINT "ReadDO sent. Err: ", warn
  if warn == 0 THEN
    for i=0 TO count -1
      PRINT "DO#", i, " = ", result[i]
    END
  END
  ;
  CALL ReadAO.pc(addr[], result[], count, warn)
  ;
  PRINT "ReadAO sent. Err: ", warn
  if warn == 0 THEN
    for i=0 TO count -1
      PRINT "AO#", i, " = ", result[i]
    END
  END
  ;
.END
.PROGRAM BurnSocks.pc ()
  TCP_STATUS sta, ports[0], sockets[0], err[0], sub_err[0], $ips[0]
  for i=0 to sta-1
    TCP_CLOSE ret, sockets[i]
  END
.END
.PROGRAM ManualExample ()
  ; === Настройка IP контроллера ===
  ip[0] = 192   ; 1-й байт IP-адреса
  ip[1] = 168     ; 2-й байт
  ip[2] = 0     ; 3-й байт
  ip[3] = 41     ; 4-й байт  (localhost)
  ;
  call BurnSocks.pc
  ;
  TCP_CONNECT ret, 12389, ip[0], 5    ; клиентское соединение
  IF ret < 0 THEN
    PRINT "Ошибка TCP_CONNECT:", ret
    GOTO cleanup
  END
  sock_id = ret
  ;
  ; === Read 1 Holding Register (Function 0x03) ===
  ; MBAP Header (TransactionID=1, ProtocolID=0, )
  req[0]  = 0   ;===TransactionID
  req[1]  = 5   ;TransactionID=5
  req[2]  = 0   ;===ProtocolID
  req[3]  = 0   ;ProtocolID=0
  req[4]  = 0   ;===Length
  req[5]  = 6    ; Length=6
  req[6]  = 1    ; Unit ID
  ;
  ; PDU 
  req[7]  = 3    ; Function=0x03
  req[8]  = 0    ; ===Address
  req[9]  = 0    ; Address=0x0000
  req[10] = 0    ; Num=0 
  req[11] = 1    ; Count=1
  
  ans[0] = 0
  ;
  CALL ManualCast.pc(req[], ans[], 12)
  for i=0 to 12-1
    PRINT "recv", i, " = ", ans[i]
  END
  ;
  ;
  ; === Закрыть соединение ===
cleanup:
  TCP_CLOSE ret, sock_id
  TWAIT 2  ; закрыть socket
.END
.PROGRAM ManualCast.pc (.send[],.recv[],.len)
  .recv[0] = -1
  ;
  .$send[0] = ""
  .$recv[0] = ""
  ;
  ; === Send request ===
  FOR i = 0 TO .len -1
    .$send[i] =$CHR (.send[i])
  END
  ;
  TCP_SEND ret, sock_id, .$send[0], .len, 1
  IF ret < 0 THEN
    PRINT "Ошибка TCP_SEND:", ret
    RETURN
  END
  ;
  ; === Get answer ===
  TCP_RECV ret, sock_id, .$recv[0], .count, 1, 1
  IF ret < 0 THEN
    PRINT "Ошибка TCP_RECV:", ret
    RETURN
  END
  ;
  FOR i = 0 TO .count -1
    .recv[i] = ASC (.$recv[i])
  END
.END
.PROGRAM initModbus.pc ()
  ; === Set constants ===
  SIGNAL -2099      ; Connection status sig
  SIGNAL -2100      ; Message is forming sig
  SIGNAL -2101      ; Message is casting sig
  SIGNAL -2102      ; Answer is ready sig
  ;
  ip[0] = 192       ; IP address
  ip[1] = 168    
  ip[2] = 0    
  ip[3] = 41    
  ;
  port = 12389      ; IP port
  ;
  mbap[0]  = 0      ; TransactionID high byte
  mbap[1]  = 0      ; TransactionID low byte
  mbap[2]  = ^H01   ; Unit ID
.END
.PROGRAM receiverTCP.pc ()
  ; === Get answer ===
  .$recv[0] = ""
  TCP_RECV ret, sock_id, .$recv[0], .count, 1, 1
  ;
  IF ret >= 0 THEN
    FOR i = 0 TO .count -1
      ans[i] = ASC (.$recv[i])
    END
  END
.END
.PROGRAM senderTCP.pc ()
  ; === Send request ===
  .$send[0] = ""
  .reps = 0
  FOR i = 0 TO req_len -1
    .$send[i] =$CHR (req[i])
  END
  ;
  DO
    TCP_SEND ret, sock_id, .$send[0], req_len, 1
    .reps = .reps + 1
  UNTIL ret >=0 OR .reps >=4
  
.END
.PROGRAM ReadDO.pc (.addr[],.res[],.count,.err) ; 0x01 Read Coils
  ; === 0x01 Read Coils ===
  ;
  SWAIT -2100
  SIGNAL 2100 
  ans[0] = 0
  ; MBAP header
  req[0] = mbap[0]                          ; Transaction ID high byte
  req[1] = mbap[1]                          ; Transaction ID low byte
  req[2] = 0                                ; Protocol ID high byte
  req[3] = 0                                ; Protocol ID low byte
  req[4] = 0                                ; Length high byte
  req[5] = 6                                ; Length low byte
  req[6] = mbap[2]                          ; Unit ID
  ;
  ; PDU fields
  req[7] = 1                                ; Function code 0x01 Read Coils
  req[8] = .addr[0]                         ; Starting address high byte
  req[9] = .addr[1]                         ; Starting address low byte
  req[10] = (.count - .count % 256)/ 256    ; Quantity of coils high byte
  req[11] = (.count % 256)                  ; Quantity of coils low byte
  ;
  req_len = 12
  SIGNAL 2101                               ; Cast request
  SWAIT 2102                                ; Wait answer
  SIGNAL -2102
  SIGNAL -2100
  ;
  ; === Exception handling ===
  IF (ans[7] BAND 128) <> 0 THEN              ; If MSB of function code is set
    .err = ans[8]                           ; Read exception code from next byte
    RETURN
  END
  ;
  ; === Increment Transaction ID ===
  .temp = mbap[0] * 256 + mbap[1] + 1
  mbap[1] = .temp % 256
  mbap[0] = (.temp - mbap[1]) / 256
  ;
  ; === Extract coil status  ===
  FOR i = 0 TO ans[8] - 1
    FOR j = 0 TO 7
      .res[i * 8 + j] = (ans[9 + i] BAND 2^j) / 2^j
    END
  END
.END
.PROGRAM ReadAI.pc (.addr[],.res[],.count,.err) ; 0x04 Read Analog Inputs
  ; === 0x04 Read Analog Inputs ===
  ;
  SWAIT -2100
  SIGNAL 2100
  ans[0] = 0
  ; MBAP header
  req[0] = mbap[0]                          ; Transaction ID high byte
  req[1] = mbap[1]                          ; Transaction ID low byte
  req[2] = 0                                ; Protocol ID high byte
  req[3] = 0                                ; Protocol ID low byte
  req[4] = 0                                ; Length high byte
  req[5] = 6                                ; Length low byte
  req[6] = mbap[2]                          ; Unit ID
  ;
  ; PDU fields
  req[7] = 4                                ; Function code 0x04 Read AO
  req[8] = .addr[0]                         ; Starting address high byte
  req[9] = .addr[1]                         ; Starting address low byte
  req[10] = (.count - .count % 256)/ 256    ; Quantity of AI high byte
  req[11] = (.count % 256)                  ; Quantity of AI low byte
  ;
  req_len = 12
  SIGNAL 2101                               ; Cast request
  SWAIT 2102                                ; Wait answer
  SIGNAL -2102
  SIGNAL -2100
  ;
  ; === Exception handling ===
  IF (ans[7] BAND 128) <> 0 THEN              ; If MSB of function code is set
    .err = ans[8]                           ; Read exception code from next byte
    RETURN
  END
  ;
  ; === Increment Transaction ID ===
  .temp = mbap[0] * 256 + mbap[1] + 1
  mbap[1] = .temp % 256
  mbap[0] = (.temp - mbap[1]) / 256
  ;
  ; === Extract input status  ===
  FOR i = 0 TO .count - 1
    .res[i] = (ans[9+i*2]*256) BOR ans[10+i*2]
  END
.END
.PROGRAM ReadDI.pc (.addr[],.res[],.count,.err) ; 0x02 Read Discrete Inputs
  ; === 0x02 Read Inputs ===
  ;
  SWAIT -2100
  SIGNAL 2100
  ans[0] = 0
  ; MBAP header
  req[0] = mbap[0]                          ; Transaction ID high byte
  req[1] = mbap[1]                          ; Transaction ID low byte
  req[2] = 0                                ; Protocol ID high byte
  req[3] = 0                                ; Protocol ID low byte
  req[4] = 0                                ; Length high byte
  req[5] = 6                                ; Length low byte
  req[6] = mbap[2]                          ; Unit ID
  ;
  ; PDU fields
  req[7] = 2                                ; Function code 0x02 Read Inputs
  req[8] = .addr[0]                         ; Starting address high byte
  req[9] = .addr[1]                         ; Starting address low byte
  req[10] = (.count - .count % 256)/ 256    ; Quantity of inputs high byte
  req[11] = (.count % 256)                  ; Quantity of inputs low byte
  ;
  req_len = 12
  SIGNAL 2101                               ; Cast request
  SWAIT 2102                                ; Wait answer
  SIGNAL -2102
  SIGNAL -2100
  ;
  ; === Exception handling ===
  IF (ans[7] BAND 128) <> 0 THEN              ; If MSB of function code is set
    .err = ans[8]                           ; Read exception code from next byte
    RETURN
  END
  ;
  ; === Increment Transaction ID ===
  .temp = mbap[0] * 256 + mbap[1] + 1
  mbap[1] = .temp % 256
  mbap[0] = (.temp - mbap[1]) / 256
  ;
  ; === Extract input status  ===
  FOR i = 0 TO ans[8] - 1
    FOR j = 0 TO 7
      .res[i * 8 + j] = (ans[9 + i] BAND 2^j) / 2^j
    END
  END
.END
.PROGRAM ReadAO.pc (.addr[],.res[],.count,.err) ; 0x03 Read Analog Outputs
  ; === 0x03 Read Analog Outputs ===
  ;
  SWAIT -2100
  SIGNAL 2100
  ans[0] = 0
  ; MBAP header
  req[0] = mbap[0]                          ; Transaction ID high byte
  req[1] = mbap[1]                          ; Transaction ID low byte
  req[2] = 0                                ; Protocol ID high byte
  req[3] = 0                                ; Protocol ID low byte
  req[4] = 0                                ; Length high byte
  req[5] = 6                                ; Length low byte
  req[6] = mbap[2]                          ; Unit ID
  ;
  ; PDU fields
  req[7] = 3                                ; Function code 0x03 Read AO
  req[8] = .addr[0]                         ; Starting address high byte
  req[9] = .addr[1]                         ; Starting address low byte
  req[10] = (.count - .count % 256)/ 256    ; Quantity of AO high byte
  req[11] = (.count % 256)                  ; Quantity of AO low byte
  ;
  req_len = 12
  SIGNAL 2101                               ; Cast request
  SWAIT 2102                                ; Wait answer
  SIGNAL -2102
  SIGNAL -2100
  ;
  ; === Exception handling ===
  IF (ans[7] BAND 128) <> 0 THEN              ; If MSB of function code is set
    .err = ans[8]                           ; Read exception code from next byte
    RETURN
  END
  ;
  ; === Increment Transaction ID ===
  .temp = mbap[0] * 256 + mbap[1] + 1
  mbap[1] = .temp % 256
  mbap[0] = (.temp - mbap[1]) / 256
  ;
  ; === Extract input status  ===
  FOR i = 0 TO .count - 1
    .res[i] = (ans[9+i*2]*256) BOR ans[10+i*2]
  END
.END
.PROGRAM WriteMDO.pc (.addr[],.res[],.state[],.count,.err) ; 0x0F Write Multiple Discrete Output
  ; === 0x0F Write Multiple Discrete Output ===
  ;
  SWAIT -2100
  SIGNAL 2100
  ans[0] = 0
  ; Bytes for MDO
  .bytes = (.count - .count%8)/8+1
  ; MBAP header
  req[0] = mbap[0]                          ; Transaction ID high byte
  req[1] = mbap[1]                          ; Transaction ID low byte
  req[2] = 0                                ; Protocol ID high byte
  req[3] = 0                                ; Protocol ID low byte
  req[4] = 0                                ; Length high byte
  req[5] = 7 + .bytes                       ; Length low byte
  req[6] = mbap[2]                          ; Unit ID
  ;
  ; PDU fields
  req[7] = 15                               ; Function code 0x0F write multiple DO
  req[8] = .addr[0]                         ; Starting address high byte
  req[9] = .addr[1]                         ; Starting address low byte
  req[10] = (.count-.count%256)/256         ; DO quantity high byte
  req[11] = .count%256                      ; DO quantity low byte
  req[12] = .bytes                          ; DO bytes quantity
  FOR i=0 TO .bytes - 1
    .temp = 0
    FOR j = 0 TO 7
      IF i*8 + j < .count THEN
        .temp = .temp + .state[i * 8 + j] * 2^j
      END
    END
    req[13+i] = .temp
  END  
  ;
  req_len = 13 + .bytes
  SIGNAL 2101                               ; Cast request
  SWAIT 2102                                ; Wait answer
  SIGNAL -2102
  SIGNAL -2100
  ;
  ; === Exception handling ===
  IF (ans[7] BAND 128) <> 0 THEN              ; If MSB of function code is set
    .err = ans[8]                           ; Read exception code from next byte
    RETURN
  END
  ;
  ; === Increment Transaction ID ===
  .temp = mbap[0] * 256 + mbap[1] + 1
  mbap[1] = .temp % 256
  mbap[0] = (.temp - mbap[1]) / 256
  ;
  ; === Extract written DO quantity  ===
  .res[0] = (ans[10]*256) BOR ans[11]
.END
.PROGRAM WriteSDO.pc (.addr[],.res[],.state,.err) ; 0x05 Write Single Discrete Output
  ; === 0x05 Write Single Discrete Output ===
  ;
  SWAIT -2100
  SIGNAL 2100
  ans[0] = 0
  ; MBAP header
  req[0] = mbap[0]                          ; Transaction ID high byte
  req[1] = mbap[1]                          ; Transaction ID low byte
  req[2] = 0                                ; Protocol ID high byte
  req[3] = 0                                ; Protocol ID low byte
  req[4] = 0                                ; Length high byte
  req[5] = 6                                ; Length low byte
  req[6] = mbap[2]                          ; Unit ID
  ;
  ; PDU fields
  req[7] = 5                                ; Function code 0x05 write single DO
  req[8] = .addr[0]                         ; Starting address high byte
  req[9] = .addr[1]                         ; Starting address low byte
  req[10] = 255*.state                      ; DO state high byte
  req[11] = 0                               ; DO state low byte
  ;
  req_len = 12
  SIGNAL 2101                               ; Cast request
  SWAIT 2102                                ; Wait answer
  SIGNAL -2102
  SIGNAL -2100
  ;
  ; === Exception handling ===
  IF (ans[7] BAND 128) <> 0 THEN              ; If MSB of function code is set
    .err = ans[8]                           ; Read exception code from next byte
    RETURN
  END
  ;
  ; === Increment Transaction ID ===
  .temp = mbap[0] * 256 + mbap[1] + 1
  mbap[1] = .temp % 256
  mbap[0] = (.temp - mbap[1]) / 256
  ;
  ; === Extract written coil status  ===
  .res[0] = ans[10]/255
.END
.PROGRAM WriteSAO.pc (.addr[],.res[],.state,.err) ; 0x06 Write Single Analog Output
  ; === 0x06 Write Single Analog Output ===
  ;
  SWAIT -2100
  SIGNAL 2100
  ans[0] = 0
  ; MBAP header
  req[0] = mbap[0]                          ; Transaction ID high byte
  req[1] = mbap[1]                          ; Transaction ID low byte
  req[2] = 0                                ; Protocol ID high byte
  req[3] = 0                                ; Protocol ID low byte
  req[4] = 0                                ; Length high byte
  req[5] = 6                                ; Length low byte
  req[6] = mbap[2]                          ; Unit ID
  ;
  ; PDU fields
  req[7] = 6                                ; Function code 0x06 write single AO
  req[8] = .addr[0]                         ; Starting address high byte
  req[9] = .addr[1]                         ; Starting address low byte
  req[10] = (.state - .state % 256)/ 256    ; AO state high byte
  req[11] = .state % 256                    ; AO state low byte
  ;
  req_len = 12
  SIGNAL 2101                               ; Cast request
  SWAIT 2102                                ; Wait answer
  SIGNAL -2102
  SIGNAL -2100
  ;
  ; === Exception handling ===
  IF (ans[7] BAND 128) <> 0 THEN              ; If MSB of function code is set
    .err = ans[8]                           ; Read exception code from next byte
    RETURN
  END
  ;
  ; === Increment Transaction ID ===
  .temp = mbap[0] * 256 + mbap[1] + 1
  mbap[1] = .temp % 256
  mbap[0] = (.temp - mbap[1]) / 256
  ;
  ; === Extract written analog status  ===
  .res[0] = (ans[10]*256) BOR ans[11]
.END
.PROGRAM WriteMAO.pc (.addr[],.res[],.state[],.count,.err) ; 0x10 Write Multiple Analog Output
  ; === 0x10 Write Multiple Discrete Output ===
  ;
  SWAIT -2100
  SIGNAL 2100
  ans[0] = 0
  ; Bytes for MDO
  .bytes = .count*2
  .PDU_len = 7 + .bytes
  ; MBAP header
  req[0] = mbap[0]                          ; Transaction ID high byte
  req[1] = mbap[1]                          ; Transaction ID low byte
  req[2] = 0                                ; Protocol ID high byte
  req[3] = 0                                ; Protocol ID low byte
  req[4] = (.PDU_len - .PDU_len%256)/256    ; Length high byte
  req[5] = .PDU_len%256                     ; Length low byte
  req[6] = mbap[2]                          ; Unit ID
  ;
  ; PDU fields
  req[7] = 16                               ; Function code 0x10 write multiple AO
  req[8] = .addr[0]                         ; Starting address high byte
  req[9] = .addr[1]                         ; Starting address low byte
  req[10] = (.count-.count%256)/256         ; AO quantity high byte
  req[11] = .count%256                      ; AO quantity low byte
  req[12] = .bytes                          ; AO bytes quantity
  FOR i=0 TO .count - 1
    req[13 + 2*i] = (.state[i] - .state[i]%256)/256
    req[14 + 2*i] = .state[i]%256
  END  
  ;
  req_len = 13 + .bytes
  SIGNAL 2101                               ; Cast request
  SWAIT 2102                                ; Wait answer
  SIGNAL -2102
  SIGNAL -2100
  ;
  ; === Exception handling ===
  IF (ans[7] BAND 128) <> 0 THEN              ; If MSB of function code is set
    .err = ans[8]                           ; Read exception code from next byte
    RETURN
  END
  ;
  ; === Increment Transaction ID ===
  .temp = mbap[0] * 256 + mbap[1] + 1
  mbap[1] = .temp % 256
  mbap[0] = (.temp - mbap[1]) / 256
  ;
  ; === Extract written DO quantity  ===
  .res[0] = (ans[10]*256) BOR ans[11]
.END
.PROGRAM ModbusTCP.pc ()
  ; === Modbus TCP connection handler ===
  CALL initModbus.pc                    ; Set constants
  ;
connect:
  call BurnSocks.pc                    ; Close all sockets
  ;
  TCP_CONNECT ret, port, ip[0], 5       ; Connect to server
  IF ret < 0 THEN
    PRINT "Error TCP_CONNECT:", ret
    GOTO cleanup
  END
  sock_id = ret                         ; Get socketID
  ;
  SIGNAL 2099                           ; Connection established
  ;
  ; === Data sycle ===
  WHILE TRUE DO
    ;
    SWAIT 2101                          ; Package is ready for casting
    ; === Send request ===
    CALL senderTCP.pc                      ; Send package
    IF ret < 0 THEN 
      PRINT "Error TCP_SEND:", ret
      GOTO cleanup                      ; Sending fail, try to reconnect and send once again
    END
    ;
    ; === Get answer ===
    CALL receiverTCP.pc                    ; Catch answer
    IF ret < 0 THEN 
      PRINT "Error TCP_RECV:", ret
      GOTO cleanup                      ; Fail in catching, try to reconnect and send+catch once again
    END
    ;
    SIGNAL -2101                        ; Casting was successful, hold data sycle
    SIGNAL 2102                         ; Answer is ready
  END
  ;
  ;
  ; === Close connection ===
cleanup:
  SIGNAL -2099                          ; Connection is lost
  TCP_CLOSE ret, sock_id                ; Close socket
  TWAIT 2                               ; Wait for some magic
  GOTO connect                          ; Try to reconnect
.END
.PROGRAM Comment___ () ; Comments for IDE. Do not use.
	; @@@ PROJECT @@@
	; @@@ PROJECTNAME @@@
	; CERF
	; @@@ HISTORY @@@
	; @@@ INSPECTION @@@
	; @@@ CONNECTION @@@
	; KROSET R01
	; 127.0.0.1
	; 9105
	; @@@ PROGRAM @@@
	; 0:Example:F
	; .sta 
	; .ports 
	; .sockets 
	; .err 
	; .sub_err 
	; Group:Utilities:1
	; 1:BurnSocks.pc:B
	; 1:ManualExample:B
	; 1:ManualCast.pc:B
	; .send[] 
	; .recv[] 
	; .num 
	; .len 
	; 1:initModbus.pc:B
	; 1:receiverTCP.pc:B
	; 1:senderTCP.pc:B
	; Group:Commands:2
	; 2:ReadDO.pc:B
	; .addr[] 
	; .quantity[] 
	; .res[] 
	; .coil_count 
	; .err 
	; .do_count 
	; .count 
	; 2:ReadAI.pc:B
	; .addr[] 
	; .res[] 
	; .count 
	; .err 
	; 2:ReadDI.pc:B
	; .addr[] 
	; .quantity[] 
	; .res[] 
	; .byte_count 
	; .err 
	; .di_coint 
	; .count 
	; 2:ReadAO.pc:B
	; .addr[] 
	; .res[] 
	; .count 
	; .err 
	; .di_coint 
	; 2:WriteMDO.pc:B
	; .addr[] 
	; .res[] 
	; .err 
	; .state 
	; .state[] 
	; .count 
	; 2:WriteSDO.pc:B
	; .addr[] 
	; .res[] 
	; .err 
	; .state 
	; .count 
	; 2:WriteSAO.pc:B
	; .addr[] 
	; .res[] 
	; .err 
	; .state 
	; .addr 
	; .res 
	; .temp 
	; 2:WriteMAO.pc:B
	; .addr[] 
	; .res[] 
	; .err 
	; .state 
	; .state[] 
	; .count 
	; 0:ModbusTCP.pc:B
	; @@@ TRANS @@@
	; @@@ JOINTS @@@
	; @@@ REALS @@@
	; @@@ STRINGS @@@
	; @@@ INTEGER @@@
	; @@@ SIGNALS @@@
	; @@@ TOOLS @@@
	; @@@ BASE @@@
	; @@@ FRAME @@@
	; @@@ BOOL @@@
	; @@@ DEFAULTS @@@
	; BASE: NULL
	; TOOL: NULL
	; @@@ WCD @@@
	; SIGNAME: sig1 sig2 sig3 sig4
	; SIGDIM: % % % %
.END
.REALS
ret = 0
sock_id = 696
ans[0] = 0
ans[1] = 0
ans[2] = 0
ans[3] = 0
ans[4] = 0
ans[5] = 5
ans[6] = 1
ans[7] = 1
ans[8] = 2
ans[9] = 0
ans[10] = 3
ans[11] = 0
count = 10
i = 11
ip[0] = 192
ip[1] = 168
ip[2] = 0
ip[3] = 41
p1 = -2
p2 = -2
recs[0] = 3
req[0] = 0
req[1] = 0
req[2] = 0
req[3] = 0
req[4] = 0
req[5] = 6
req[6] = 1
req[7] = 1
req[8] = 0
req[9] = 1
req[10] = 0
req[11] = 10
err[0] = 0
ports[0] = 12389
sockets[0] = 696
sta = 1
sub_err[0] = 0
addr[0] = 0
addr[1] = 1
mbap[0] = 0
mbap[1] = 0
mbap[2] = 1
port = 12389
req_len = 12
result[0] = 0
warn = 2
.END
.STRINGS
$req[0] = "\"
$req[1] = "\005"
$req[2] = "\"
$req[3] = "\"
$req[4] = "\"
$req[5] = "\006"
$req[6] = "\001"
$req[7] = "\005"
$req[8] = "\"
$req[9] = "\"
$req[10] = "�"
$req[11] = "\"
$resp[0] = "\"
$resp[1] = "\005"
$resp[2] = "\"
$resp[3] = "\"
$resp[4] = "\"
$resp[5] = "\006"
$resp[6] = "\001"
$resp[7] = "\005"
$resp[8] = "\"
$resp[9] = "\"
$resp[10] = "�"
$resp[11] = "\"
.END
