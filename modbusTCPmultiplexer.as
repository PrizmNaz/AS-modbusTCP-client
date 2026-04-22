.AUXDATA
N_INT5    "IO_hmi_d1_send|"
N_INT7    "IO_hmi_d2_send|"
N_INT9    "IO_reconn_dev|"
N_INT10    "IO_interf_blink|"
N_INT11    "IO_hmi_rec_div|"
N_INT12    "IO_devman_blink|"
N_INT13    "IO_multi_blink|"
N_INT14    "IO_d2_output|"
N_INT15    "IO_d2_par2_o|"
N_INT17    "IO_d1_output|"
N_INT18    "IO_d1_connect|"
N_INT19    "IO_d2_connect|"
N_INT21    "IO_d2_send|"
N_INT31    "IO_d2_par2_i|"
N_INT33    "IO_d1_send|"
.END
.INTER_PANEL_D
0,1,"interface","","","manager",10,0,4,3,2010,0
1,1,"tcp-ip","","","manager",10,0,4,3,2013,0
2,1,"device","","","manager",10,0,4,3,2012,0
3,3,"","reconnect","devices","",10,3,15,0,0,2011,2009,0
5,1,"connect","device 1","","",10,15,4,0,2018,0
6,1,"connect","device 2","","",10,15,4,0,2019,0
7,10,"","Restart","blinker 1","",10,4,0,1,"pcexecute 1:interface_m.pc",0
8,10,"","Restart","blinker 2","",10,4,0,2,"pcexecute 2:multiplexer.pc",0
9,10,"","Restart","blinker 3","",10,4,0,3,"pcexecute 3:device_man.pc",0
12,1,"output","device 1","","",10,15,4,0,2017,0
13,1,"output","device 2","","",10,15,3,0,2014,0
17,8,"d1_float_o","d1 float","output",10,0,4,2,0
18,3,"set params","to","device 1","",10,4,15,0,0,2005,2033,0
19,8,"d1_par1_i","d1","param 1",10,15,4,2,0
20,8,"d1_par2_i","d1","param 2",10,15,4,2,0
24,8,"d2_float_o","d2 float","output",10,0,4,2,0
25,3,"set params","to","device 2","",10,4,15,0,0,2007,2021,0
26,8,"d2_par1_i","d2","param 1",10,15,4,2,0
27,4,1,"d2","param 2","flag","",10,4,2,2031,0,0
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
.PROGRAM example ()
  ;
  ;device 1 send data to queue
  ;
  d1_par1_i = 111
  d1_par2_i = 222
  SIG IO_d1_send
  ;
  ;send device 2 flag
  ;
  SIG IO_d2_par2_i
  ;
  ;
  ;device 2 send data to queue
  ;
  d2_par1_i = 1001
  SIG IO_d2_send
  ;
  ; === doing something ===
  ;
  TWAIT 5
  ;
  ;device 1 send data to queue and wait for confirmation
  ;
  d1_par1_i = 333
  d1_par2_i = 444
  SIG IO_d1_send
  SWAIT -IO_d1_send
  ;
  ;send device 2 flag
  ;
  SIG -IO_d2_par2_i
  ;
  ;device 2 send data to queue
  ;
  d2_par1_i = 2002
  SIG IO_d2_send
  ;
  ; === doing something ===
  ;
  TWAIT 5
  ;
.END
.PROGRAM tester.pc ()
  .ip[0] = 192
  .ip[1] = 168
  .ip[2] = 1
  .ip[3] = 12
  .port = 9000
  .socket = 0
  .ret = 0
  ;
  ; 2. check socket
  CALL init_sockets.pc
  ;
  ;  
  ; 4. connection
  TCP_CONNECT .ret, .port, .ip[0], 1       
  IF .ret <= 0 THEN
    call slog.pc ("Error TCP_CONNECT to device " + $ENCODE(12) + ": ")
    call rlog.pc(.ret)
  ELSE
    call slog.pc ("TCP_CONNECTED to device " + $ENCODE(12) + ": ")
    call rlog.pc(.ret)
  END
.END
.PROGRAM interface_m.pc ()
  .temp = 0
  ;
  WHILE TRUE DO
    ;
    IF mp_stats[d1_device_id] == 1 THEN
      SIG IO_d1_connect
    ELSE 
      SIG -IO_d1_connect
    END
    ;
    IF mp_stats[d2_device_id] == 1 THEN
      SIG IO_d2_connect
    ELSE 
      SIG -IO_d2_connect
    END
    ;
    IF SIG(IO_hmi_d1_send) THEN
      SIG IO_d1_send
    END
    ;
    IF SIG(IO_hmi_d2_send) THEN
      SIG IO_d2_send
    END
    ;
    IF SIG(IO_hmi_rec_div) THEN
      SIG IO_reconn_dev
    END
    ;
    TWAIT 0.05
    .temp = .temp + 1
    IF .temp >=10 THEN
      .temp = 0
      IF SIG (IO_interf_blink) THEN
        sig -IO_interf_blink
      ELSE
        sig IO_interf_blink
      END
    END
    
  END
  
.END
.PROGRAM device_man.pc () ; manager of devices
  debug = TRUE
  mbap[0]  = 0      ; TransactionID high byte
  mbap[1]  = 0      ; TransactionID low byte
  mbap[2]  = ^H01   ; Unit ID
  ;
  temp_IO_d2_par2 = sig (IO_d2_par2_i)
  ;
  
  CALL init_device1.pc (1)
  CALL init_device2.pc (2)
  WHILE TRUE DO
    ;
    IF SIG(IO_d1_send) THEN
      CALL send_d1_pars.pc
    END
    ;
    IF SIG (IO_d2_send) THEN
      CALL send_d2_pars.pc
    END
    ;
    ;
    IF SIG (IO_reconn_dev) THEN
      CALL reconn_reset.pc
      SIG -IO_reconn_dev
    END
    ;
    IF SIG (IO_d2_par2_i) !=temp_IO_d2_par2 THEN
      CALL send_d2_flag.pc
    END
    ;
    ;== receiving data ==
    CALL d1_recv_sta.pc
    CALL d2_recv_sta.pc
    ;
    ; blink
    IF SIG (IO_devman_blink) THEN
      sig -IO_devman_blink
    ELSE
      sig IO_devman_blink
    END
    ;
    TWAIT 0.1
  END
.END
.PROGRAM multiplexer.pc ()
  ; === a program to handle multiple tcp/ip  connections
  ;
  ; 1. Initialize devices
  call init_mp.pc
  WHILE TRUE DO
    IF mp_len < 1 THEN
      BREAK
    END
    FOR .i = 1 TO mp_len
      .device_id = mp_ids[.i]
      CALL device_graph.pc (.device_id)
      TWAIT 0.1
    END
    ;
    IF SIG (IO_multi_blink) THEN
      sig -IO_multi_blink
    ELSE
      sig IO_multi_blink
    END
  END
.END
.PROGRAM init_mp.pc ()
  ; === preparations before communication
  ;
  ; 1. clearing all global arrays
  call init_arrays.pc
  ;
  ; 2. configuring all devices
  CALL init_device.pc (1, "192.168.100.10:9000", 0, 1)  ;device 1
  CALL init_device.pc (2, "192.168.100.20:11111", 0, 1) ;device 2
  ;
  ; 3. clearing all active sockets
  CALL init_sockets.pc
.END
.PROGRAM send_d1_pars.pc ()
  .adr = 1
  .addr[0] = (.adr - .adr % 256)/256
  .addr[1] = .adr % 256
  .res[0] = 0
  .err = 0
  .state[0] = d1_par1_i
  .state[1] = d1_par2_i
  CALL WriteMAO.pc (.addr[], .res[], .state[], 2, .err, d1_device_id)
  IF .err == 0 THEN
    SIG -IO_d1_send
  END
.END
.PROGRAM init_device1.pc (.device_id)
  d1_device_id = .device_id
  CALL send_d1_pars.pc
.END
.PROGRAM d1_recv_sta.pc ()
  .adr = 1
  .addr[0] = (.adr - .adr % 256)/256
  .addr[1] = .adr % 256
  .res[0] = 0
  .err = 0
  CALL ReadDO.pc(.addr[], .res[], 1, .err, d1_device_id)
  IF .res[0] == 1 AND .err == 0 THEN
    SIG IO_d2_output
  ELSE
    SIG -IO_d2_output
  END
  ;
  ;
  ; state
  .adr = 16392
  .addr[0] = (.adr - .adr % 256)/256
  .addr[1] = .adr % 256
  .res[0] = 0
  .err = 0
  CALL ReadAO.pc(.addr[], .res[], 1, .err, d1_device_id)
  IF .err == 0 THEN
    d1_float_o = .res[0]
  END
.END
.PROGRAM ReadDO.pc (.addr[],.res[],.count,.err,.device_id) ; 0x01 Read Coils
  ; === 0x01 Read Coils ===
  ;
  IF NOT (mp_free_devices[.device_id] == TRUE) THEN
    .err = -1
    RETURN
  END
  mp_free_devices[.device_id] = FALSE
  ; MBAP header
  .req[0] = mbap[0]                          ; Transaction ID high byte
  .req[1] = mbap[1]                          ; Transaction ID low byte
  .req[2] = 0                                ; Protocol ID high byte
  .req[3] = 0                                ; Protocol ID low byte
  .req[4] = 0                                ; Length high byte
  .req[5] = 6                                ; Length low byte
  .req[6] = 1                          ; Unit ID
  ;
  ; PDU fields
  .req[7] = 1                                ; Function code 0x01 Read Coils
  .req[8] = .addr[0]                         ; Starting address high byte
  .req[9] = .addr[1]                         ; Starting address low byte
  .req[10] = (.count - .count % 256)/ 256    ; Quantity of coils high byte
  .req[11] = (.count % 256)                  ; Quantity of coils low byte
  ;
  ; === send data ===
  mp_send_len[.device_id] = 12
  ;
  FOR .i = 0 to (mp_send_len[.device_id] -1)
    $mp_send[.device_id, .i] = $CHR (.req[.i])
  END
  ;
  mp_readiness[.device_id, 1] = FALSE
  mp_readiness[.device_id, 0] = TRUE
  ;
  ; === wait for answer ===
  .temp = 0
  DO
    TWAIT 0.1
    .temp = .temp + 1
  UNTIL  mp_readiness[.device_id, 1] OR .temp > 5
  ;
  IF .temp > 5 THEN
    .err = -2
    call slog_mb.pc ("modbus ReadDO device "+ $ENCODE (.device_id) + " recv: NOTHING")
    mp_free_devices[.device_id] = TRUE
    RETURN
  END
  ;
  IF mp_recv_len[.device_id] <= 0 THEN
    .err = -3
    mp_free_devices[.device_id] = TRUE
    call slog_mb.pc ("Modbus ReadDO device recv 0 packages " + $ENCODE (.device_id) + " :")
    RETURN
  END
  ;
  ; === extract data ===
  FOR .i = 0 to mp_recv_len[.device_id]
    .ans[.i] = ASC ($mp_recv[.device_id, .i])
  end
  mp_free_devices[.device_id] = TRUE
  ;
  ; === Exception handling ===
  IF (.ans[7] BAND 128) <> 0 THEN              ; If MSB of function code is set
    .err = .ans[8]                             ; Read exception code from next byte
    call slog_mb.pc ("Error modbus ReadDO device " + $ENCODE (.device_id) + " :")
    call rlog_mb.pc (.err)
    RETURN
  END
  ;
  ; === Increment Transaction ID ===
  .temp = mbap[0] * 256 + mbap[1] + 1
  if .temp >= 65535 THEN
    .temp = 1
  END
  mbap[1] = .temp % 256
  mbap[0] = (.temp - mbap[1]) / 256
  ;
  ; === Extract coil status  ===
  FOR .i = 0 TO .ans[8] - 1
    FOR .j = 0 TO 7
      .res[.i * 8 + .j] = (.ans[9 + .i] BAND 2^.j) / 2^.j
    END
  END
.END
.PROGRAM ReadAI.pc (.addr[],.res[],.count,.err,.device_id) ; 0x04 Read Analog Inputs
  ; === 0x04 Read Analog Inputs ===
  ;
  IF NOT (mp_free_devices[.device_id] == TRUE) THEN
    .err = -1
    RETURN
  END
  mp_free_devices[.device_id] = FALSE
  ; MBAP header
  .req[0] = mbap[0]                          ; Transaction ID high byte
  .req[1] = mbap[1]                          ; Transaction ID low byte
  .req[2] = 0                                ; Protocol ID high byte
  .req[3] = 0                                ; Protocol ID low byte
  .req[4] = 0                                ; Length high byte
  .req[5] = 6                                ; Length low byte
  .req[6] = 1                          ; Unit ID
  ;
  ; PDU fields
  .req[7] = 4                                ; Function code 0x04 Read AO
  .req[8] = .addr[0]                         ; Starting address high byte
  .req[9] = .addr[1]                         ; Starting address low byte
  .req[10] = (.count - .count % 256)/ 256    ; Quantity of AI high byte
  .req[11] = (.count % 256)                  ; Quantity of AI low byte
  ;
  ; === send data ===
  mp_send_len[.device_id] = 12
  ;
  FOR .i = 0 to mp_send_len[.device_id] -1
    $mp_send[.device_id, .i] = $CHR (.req[.i])
  END
  ;
  mp_readiness[.device_id, 1] = FALSE
  mp_readiness[.device_id, 0] = TRUE
  ;
  ; === wait for answer ===
  .temp = 0
  DO
    TWAIT 0.1
    .temp = .temp + 1
  UNTIL  mp_readiness[.device_id, 1] OR .temp > 5
  ;
  IF .temp > 5 THEN
    .err = -2
    call slog_mb.pc ("modbus ReadAI device "+ $ENCODE (.device_id) + " recv: *NOTHING*")
    mp_free_devices[.device_id] = TRUE
    RETURN
  END
  ;
  IF mp_recv_len[.device_id] <= 0 THEN
    .err = -3
    mp_free_devices[.device_id] = TRUE
    call slog_mb.pc ("Modbus ReadAI device recv 0 packages " + $ENCODE (.device_id) + " :")
    RETURN
  END
  ;
  ; === extract data ===
  FOR .i = 0 to mp_recv_len[.device_id]
    .ans[.i] = ASC ($mp_recv[.device_id, .i])
  end
  mp_free_devices[.device_id] = TRUE
  ;
  ; === Exception handling ===
  IF (.ans[7] BAND 128) <> 0 THEN            ; If MSB of function code is set
    .err = .ans[8]                           ; Read exception code from next byte
    call slog_mb.pc ("Error modbus ReadAI device " + $ENCODE (.device_id) + " :")
    call rlog_mb.pc (.err)
    RETURN
  END
  ;
  ; === Increment Transaction ID ===
  .temp = mbap[0] * 256 + mbap[1] + 1
  if .temp >= 65535 THEN
    .temp = 1
  END
  mbap[1] = .temp % 256
  mbap[0] = (.temp - mbap[1]) / 256
  ;
  ; === Extract input status  ===
  FOR .i = 0 TO .count - 1
    .res[.i] = (.ans[9 + .i * 2] * 256) BOR .ans[10 + .i * 2]
  END
.END
.PROGRAM ReadDI.pc (.addr[],.res[],.count,.err,.device_id) ; 0x02 Read Discrete Inputs
  ; === 0x02 Read Inputs ===
  ;
  IF NOT (mp_free_devices[.device_id] == TRUE) THEN
    .err = -1
    RETURN
  END
  mp_free_devices[.device_id] = FALSE
  ; MBAP header
  .req[0] = mbap[0]                          ; Transaction ID high byte
  .req[1] = mbap[1]                          ; Transaction ID low byte
  .req[2] = 0                                ; Protocol ID high byte
  .req[3] = 0                                ; Protocol ID low byte
  .req[4] = 0                                ; Length high byte
  .req[5] = 6                                ; Length low byte
  .req[6] = 1                          ; Unit ID
  ;
  ; PDU fields
  .req[7] = 2                                ; Function code 0x02 Read Inputs
  .req[8] = .addr[0]                         ; Starting address high byte
  .req[9] = .addr[1]                         ; Starting address low byte
  .req[10] = (.count - .count % 256)/ 256    ; Quantity of inputs high byte
  .req[11] = (.count % 256)                  ; Quantity of inputs low byte
  ;
  ; === send data ===
  mp_send_len[.device_id] = 12
  ;
  FOR .i = 0 to mp_send_len[.device_id] -1
    $mp_send[.device_id, .i] = $CHR (.req[.i])
  END
  ;
  mp_readiness[.device_id, 1] = FALSE
  mp_readiness[.device_id, 0] = TRUE
  ;
  ; === wait for answer ===
  .temp = 0
  DO
    TWAIT 0.1
    .temp = .temp + 1
  UNTIL  mp_readiness[.device_id, 1] OR .temp > 5
  ;
  IF .temp > 5 THEN
    .err = -2
    call slog_mb.pc ("modbus ReadDI device "+ $ENCODE (.device_id)+ " recv: *NOTHING*")
    mp_free_devices[.device_id] = TRUE
    RETURN
  END
  ;
  IF mp_recv_len[.device_id] <= 0 THEN
    .err = -3
    mp_free_devices[.device_id] = TRUE
    call slog_mb.pc ("Modbus ReadDI device recv 0 packages " + $ENCODE (.device_id) + " :")
    RETURN
  END
  ;
  ; === extract data ===
  FOR .i = 0 to mp_recv_len[.device_id]
    .ans[.i] = ASC ($mp_recv[.device_id, .i])
  end
  mp_free_devices[.device_id] = TRUE
  ;
  ; === Exception handling ===
  IF (.ans[7] BAND 128) <> 0 THEN            ; If MSB of function code is set
    .err = .ans[8]                           ; Read exception code from next byte
    call slog_mb.pc ("Error modbus ReadDI device " + $ENCODE (.device_id) + " :")
    call rlog_mb.pc (.err)
    RETURN
  END
  ;
  ; === Increment Transaction ID ===
  .temp = mbap[0] * 256 + mbap[1] + 1
  if .temp >= 65535 THEN
    .temp = 1
  END
  mbap[1] = .temp % 256
  mbap[0] = (.temp - mbap[1]) / 256
  ;
  ; === Extract input status  ===
  FOR .i = 0 TO .ans[8] - 1
    FOR .j = 0 TO 7
      .res[.i * 8 + .j] = (.ans[9 + .i] BAND 2^.j) / 2^.j
    END
  END
.END
.PROGRAM ReadAO.pc (.addr[],.res[],.count,.err,.device_id) ; 0x03 Read Analog Outputs
  ; === 0x03 Read Analog Outputs ===
  ;
  IF NOT (mp_free_devices[.device_id] == TRUE) THEN
    .err = -1
    RETURN
  END
  mp_free_devices[.device_id] = FALSE
  ; MBAP header
  .req[0] = mbap[0]                          ; Transaction ID high byte
  .req[1] = mbap[1]                          ; Transaction ID low byte
  .req[2] = 0                                ; Protocol ID high byte
  .req[3] = 0                                ; Protocol ID low byte
  .req[4] = 0                                ; Length high byte
  .req[5] = 6                                ; Length low byte
  .req[6] = 1                          ; Unit ID
  ;
  ; PDU fields
  .req[7] = 3                                ; Function code 0x03 Read AO
  .req[8] = .addr[0]                         ; Starting address high byte
  .req[9] = .addr[1]                         ; Starting address low byte
  .req[10] = (.count - .count % 256)/ 256    ; Quantity of AO high byte
  .req[11] = (.count % 256)                  ; Quantity of AO low byte
  ;
  ; === send data ===
  mp_send_len[.device_id] = 12
  ;
  FOR .i = 0 to mp_send_len[.device_id] -1
    $mp_send[.device_id, .i] = $CHR (.req[.i])
  END
  ;
  mp_readiness[.device_id, 1] = FALSE
  mp_readiness[.device_id, 0] = TRUE
  ;
  ; === wait for answer ===
  .temp = 0
  DO
    TWAIT 0.1
    .temp = .temp + 1
  UNTIL  mp_readiness[.device_id, 1] OR .temp > 5
  ;
  IF .temp > 5 THEN
    .err = -2
    call slog_mb.pc ("modbus ReadAO device "+ $ENCODE (.device_id)+ " recv: *NOTHING*")
    mp_free_devices[.device_id] = TRUE
    RETURN
  END
  ;
  ;
  IF mp_recv_len[.device_id] <= 0 THEN
    .err = -3
    mp_free_devices[.device_id] = TRUE
    call slog_mb.pc ("Modbus ReadAO device recv 0 packages " + $ENCODE (.device_id) + " :")
    RETURN
  END
  ;
  ; === extract data ===
  FOR .i = 0 to mp_recv_len[.device_id]
    .ans[.i] = ASC ($mp_recv[.device_id, .i])
  end
  mp_free_devices[.device_id] = TRUE
  ;
  ; === Exception handling ===
  IF (.ans[7] BAND 128) <> 0 THEN            ; If MSB of function code is set
    .err = .ans[8]                           ; Read exception code from next byte
    call slog_mb.pc ("Error modbus ReadAO device " + $ENCODE (.device_id) + " :")
    call rlog_mb.pc (.err)
    RETURN
  END
  ;
  ; === Increment Transaction ID ===
  .temp = mbap[0] * 256 + mbap[1] + 1
  if .temp >= 65535 THEN
    .temp = 1
  END
  mbap[1] = .temp % 256
  mbap[0] = (.temp - mbap[1]) / 256
  ;
  ; === Extract input status  ===
  FOR .i = 0 TO .count - 1
    .res[.i] = (.ans[9 + .i * 2] * 256) BOR .ans[10 + .i * 2]
  END
.END
.PROGRAM WriteMDO.pc (.addr[],.res[],.state[],.count,.err,.device_id) ; 0x0F Write Multiple Discrete Output
  ; === 0x0F Write Multiple Discrete Output ===
  ;
  IF NOT (mp_free_devices[.device_id] == TRUE) THEN
    .err = -1
    RETURN
  END
  mp_free_devices[.device_id] = FALSE
  ; Bytes for MDO
  .bytes = (.count - .count%8) / 8 + 1
  ; MBAP header
  .req[0] = mbap[0]                          ; Transaction ID high byte
  .req[1] = mbap[1]                          ; Transaction ID low byte
  .req[2] = 0                                ; Protocol ID high byte
  .req[3] = 0                                ; Protocol ID low byte
  .req[4] = 0                                ; Length high byte
  .req[5] = 7 + .bytes                       ; Length low byte
  .req[6] = 1                          ; Unit ID
  ;
  ; PDU fields
  .req[7] = 15                               ; Function code 0x0F write multiple DO
  .req[8] = .addr[0]                         ; Starting address high byte
  .req[9] = .addr[1]                         ; Starting address low byte
  .req[10] = (.count - .count%256) / 256         ; DO quantity high byte
  .req[11] = .count%256                      ; DO quantity low byte
  .req[12] = .bytes                          ; DO bytes quantity
  FOR .i = 0 TO .bytes - 1
    .temp = 0
    FOR .j = 0 TO 7
      IF .i * 8 + .j < .count THEN
        .temp = .temp + .state[.i * 8 + .j] * 2^.j
      END
    END
    .req[13 + .i] = .temp
  END
  ;
  ; === send data ===
  mp_send_len[.device_id] = 7 + .bytes + 6
  ;
  FOR .i = 0 to mp_send_len[.device_id] -1
    $mp_send[.device_id, .i] = $CHR (.req[.i])
  END
  ;
  mp_readiness[.device_id, 1] = FALSE
  mp_readiness[.device_id, 0] = TRUE
  ;
  ; === wait for answer ===
  .temp = 0
  DO
    TWAIT 0.1
    .temp = .temp + 1
  UNTIL  mp_readiness[.device_id, 1] OR .temp > 5
  ;
  IF .temp > 5 THEN
    .err = -2
    call slog_mb.pc ("modbus WriteMDO device "+ $ENCODE (.device_id)+ " recv: *NOTHING*")
    mp_free_devices[.device_id] = TRUE
    RETURN
  END
  ;
  IF mp_recv_len[.device_id] <= 0 THEN
    .err = -3
    mp_free_devices[.device_id] = TRUE
    call slog_mb.pc ("Modbus WriteMDO device recv 0 packages " + $ENCODE (.device_id) + " :")
    RETURN
  END
  ;
  ; === extract data ===
  FOR .i = 0 to mp_recv_len[.device_id]
    .ans[.i] = ASC ($mp_recv[.device_id, .i])
  end
  mp_free_devices[.device_id] = TRUE
  ;
  ; === Exception handling ===
  IF (.ans[7] BAND 128) <> 0 THEN            ; If MSB of function code is set
    .err = .ans[8]                           ; Read exception code from next byte
    call slog_mb.pc ("Error modbus WriteMDO device " + $ENCODE (.device_id) + " :")
    call rlog_mb.pc (.err)
    RETURN
  END
  ;
  ; === Increment Transaction ID ===
  .temp = mbap[0] * 256 + mbap[1] + 1
  if .temp >= 65535 THEN
    .temp = 1
  END
  mbap[1] = .temp % 256
  mbap[0] = (.temp - mbap[1]) / 256
  ;
  ; === Extract written DO quantity  ===
  .res[0] = (.ans[10] * 256) BOR .ans[11]
.END
.PROGRAM WriteSDO.pc (.addr[],.res[],.state,.err,.device_id) ; 0x05 Write Single Discrete Output
  ; === 0x05 Write Single Discrete Output ===
  ;
  IF NOT (mp_free_devices[.device_id] == TRUE) THEN
    .err = -1
    RETURN
  END
  mp_free_devices[.device_id] = FALSE
  ; MBAP header
  .req[0] = mbap[0]                          ; Transaction ID high byte
  .req[1] = mbap[1]                          ; Transaction ID low byte
  .req[2] = 0                                ; Protocol ID high byte
  .req[3] = 0                                ; Protocol ID low byte
  .req[4] = 0                                ; Length high byte
  .req[5] = 6                                ; Length low byte
  .req[6] = 1                          ; Unit ID
  ;
  ; PDU fields
  .req[7] = 5                                ; Function code 0x05 write single DO
  .req[8] = .addr[0]                         ; Starting address high byte
  .req[9] = .addr[1]                         ; Starting address low byte
  .req[10] = 255 * .state                      ; DO state high byte
  .req[11] = 0                               ; DO state low byte
  ;
  ; === send data ===
  mp_send_len[.device_id] = 12
  ;
  FOR .i = 0 to mp_send_len[.device_id] -1
    $mp_send[.device_id, .i] = $CHR (.req[.i])
  END
  ;
  mp_readiness[.device_id, 1] = FALSE
  mp_readiness[.device_id, 0] = TRUE
  ;
  ; === wait for answer ===
  .temp = 0
  DO
    TWAIT 0.1
    .temp = .temp + 1
  UNTIL  mp_readiness[.device_id, 1] OR .temp > 5
  ;
  IF .temp > 5 THEN
    .err = -2
    call slog_mb.pc ("modbus WriteSDO device "+ $ENCODE (.device_id)+ " recv: *NOTHING*")
    mp_free_devices[.device_id] = TRUE
    RETURN
  END
  ;
  IF mp_recv_len[.device_id] <= 0 THEN
    .err = -3
    mp_free_devices[.device_id] = TRUE
    call slog_mb.pc ("Modbus WriteSDO device recv 0 packages " + $ENCODE (.device_id) + " :")
    RETURN
  END
  ;
  ; === extract data ===
  FOR .i = 0 to mp_recv_len[.device_id]
    .ans[.i] = ASC ($mp_recv[.device_id, .i])
  end
  mp_free_devices[.device_id] = TRUE
  ;
  ; === Exception handling ===
  IF (.ans[7] BAND 128) <> 0 THEN            ; If MSB of function code is set
    .err = .ans[8]                           ; Read exception code from next byte
    call slog_mb.pc ("Error modbus WriteSDO device " + $ENCODE (.device_id) + " :")
    call rlog_mb.pc (.err)
    RETURN
  END
  ;
  ; === Increment Transaction ID ===
  .temp = mbap[0] * 256 + mbap[1] + 1
  if .temp >= 65535 THEN
    .temp = 1
  END
  mbap[1] = .temp % 256
  mbap[0] = (.temp - mbap[1]) / 256
  ;
  ; === Extract written coil status  ===
  .res[0] = .ans[10] / 255
.END
.PROGRAM WriteMAO.pc (.addr[],.res[],.state[],.count,.err,.device_id) ; 0x10 Write Multiple Analog Output
  ; === 0x10 Write Multiple Discrete Output ===
  ;
  IF NOT (mp_free_devices[.device_id] == TRUE) THEN
    .err = -1
    RETURN
  END
  mp_free_devices[.device_id] = FALSE
  ; Bytes for MDO
  .bytes = .count * 2
  .PDU_len = 7 + .bytes
  ; MBAP header
  .req[0] = mbap[0]                          ; Transaction ID high byte
  .req[1] = mbap[1]                          ; Transaction ID low byte
  .req[2] = 0                                ; Protocol ID high byte
  .req[3] = 0                                ; Protocol ID low byte
  .req[4] = (.PDU_len - .PDU_len%256) / 256    ; Length high byte
  .req[5] = .PDU_len%256                     ; Length low byte
  .req[6] = 1                          ; Unit ID
  ;
  ; PDU fields
  .req[7] = 16                               ; Function code 0x10 write multiple AO
  .req[8] = .addr[0]                         ; Starting address high byte
  .req[9] = .addr[1]                         ; Starting address low byte
  .req[10] = (.count - .count%256) / 256     ; AO quantity high byte
  .req[11] = .count%256                      ; AO quantity low byte
  .req[12] = .bytes                          ; AO bytes quantity
  FOR .i = 0 TO .count - 1
    .req[13 + 2 * .i] = (.state[.i] - .state[.i]%256) / 256
    .req[14 + 2 * .i] = .state[.i]%256
  END
  ;
  ; === send data ===
  mp_send_len[.device_id] = .PDU_len + 6
  ;
  FOR .i = 0 to mp_send_len[.device_id] -1
    $mp_send[.device_id, .i] = $CHR (.req[.i])
  END
  ;
  mp_readiness[.device_id, 1] = FALSE
  mp_readiness[.device_id, 0] = TRUE
  ;
  ; === wait for answer ===
  .temp = 0
  DO
    TWAIT 0.1
    .temp = .temp + 1
  UNTIL  mp_readiness[.device_id, 1] OR .temp > 5
  ;
  IF .temp > 5 THEN
    .err = -2
    call slog_mb.pc ("modbus WriteMAO device "+ $ENCODE (.device_id)+ " recv: *NOTHING*")
    mp_free_devices[.device_id] = TRUE
    RETURN
  END
  ;
  IF mp_recv_len[.device_id] <= 0 THEN
    .err = -3
    mp_free_devices[.device_id] = TRUE
    call slog_mb.pc ("Modbus WriteMAO device recv 0 packages " + $ENCODE (.device_id) + " :")
    RETURN
  END
  ;
  ; === extract data ===
  FOR .i = 0 to mp_recv_len[.device_id]
    .ans[.i] = ASC ($mp_recv[.device_id, .i])
  end
  mp_free_devices[.device_id] = TRUE
  ;
  ; === Exception handling ===
  IF (.ans[7] BAND 128) <> 0 THEN            ; If MSB of function code is set
    .err = .ans[8]                           ; Read exception code from next byte
    call slog_mb.pc ("Error modbus WriteMAO device " + $ENCODE (.device_id) + " :")
    call rlog_mb.pc (.err)
    RETURN
  END
  ;
  ; === Increment Transaction ID ===
  .temp = mbap[0] * 256 + mbap[1] + 1
  if .temp >= 65535 THEN
    .temp = 1
  END
  mbap[1] = .temp % 256
  mbap[0] = (.temp - mbap[1]) / 256
  ;
  ; === Extract written DO quantity  ===
  .res[0] = (.ans[10] * 256) BOR .ans[11]
.END
.PROGRAM WriteSAO.pc (.addr[],.res[],.state,.err,.device_id) ; 0x06 Write Single Analog Output
  ; === 0x06 Write Single Analog Output ===
  ;
  IF NOT (mp_free_devices[.device_id] == TRUE) THEN
    .err = -1
    RETURN
  END
  mp_free_devices[.device_id] = FALSE
  ; MBAP header
  .req[0] = mbap[0]                          ; Transaction ID high byte
  .req[1] = mbap[1]                          ; Transaction ID low byte
  .req[2] = 0                                ; Protocol ID high byte
  .req[3] = 0                                ; Protocol ID low byte
  .req[4] = 0                                ; Length high byte
  .req[5] = 6                                ; Length low byte
  .req[6] = 1                                 ; Unit ID
  ;
  ; PDU fields
  .req[7] = 6                                ; Function code 0x06 write single AO
  .req[8] = .addr[0]                         ; Starting address high byte
  .req[9] = .addr[1]                         ; Starting address low byte
  .req[10] = (.state - .state % 256)/ 256    ; AO state high byte
  .req[11] = .state % 256                    ; AO state low byte
  ;
  ; === send data ===
  mp_send_len[.device_id] = 12
  ;
  FOR .i = 0 to mp_send_len[.device_id] -1
    $mp_send[.device_id, .i] = $CHR (.req[.i])
  END
  ;
  mp_readiness[.device_id, 1] = FALSE
  mp_readiness[.device_id, 0] = TRUE
  ;
  ; === wait for answer ===
  .temp = 0
  DO
    TWAIT 0.1
    .temp = .temp + 1
  UNTIL  mp_readiness[.device_id, 1] OR .temp > 5
  ;
  IF .temp > 5 THEN
    .err = -2
    call slog_mb.pc ("modbus WriteSAO device "+ $ENCODE (.device_id)+ " recv: *NOTHING*")
    mp_free_devices[.device_id] = TRUE
    RETURN
  END
  IF mp_recv_len[.device_id] <= 0 THEN
    .err = -3
    mp_free_devices[.device_id] = TRUE
    call slog_mb.pc ("Modbus WriteSAO device recv 0 packages " + $ENCODE (.device_id) + " :")
    RETURN
  END
  ;
  ; === extract data ===
  FOR .i = 0 to mp_recv_len[.device_id]
    .ans[.i] = ASC ($mp_recv[.device_id, .i])
  end
  mp_free_devices[.device_id] = TRUE
  ;
  ; === Exception handling ===
  IF (.ans[7] BAND 128) <> 0 THEN            ; If MSB of function code is set
    .err = .ans[8]                           ; Read exception code from next byte
    call slog_mb.pc ("Error modbus WriteSAO device " + $ENCODE (.device_id) + " :")
    call rlog_mb.pc (.err)
    RETURN
  END
  ;
  ; === Increment Transaction ID ===
  .temp = mbap[0] * 256 + mbap[1] + 1
  if .temp >= 65535 THEN
    .temp = 1
  END
  mbap[1] = .temp % 256
  mbap[0] = (.temp - mbap[1]) / 256
  ;
  ; === Extract written analog status  ===
  .res[0] = (.ans[10] * 256) BOR .ans[11]
.END
.PROGRAM slog_mb.pc (.$msg)
  IF debug THEN
    PRINT  $TIME + ": " + .$msg
  END
.END
.PROGRAM rlog_mb.pc (.num)
  IF debug THEN
    PRINT $TIME + ": " + $ENCODE (.num)
  END
.END
.PROGRAM init_device.pc (.id,.$ip,.mode,.max_data_len)
  ; === splitting device data to global arrays ===
  ;
  ; id : 1-100, id of your device
  ; $ip : "ip.ip.ip.ip:port"
  ; mode : 0= send -> recv ; 1= only send; 2= only recv
  ; max_data_len : 1-255, max len in char for datapart (for modbus set 1)
  ; 
  ; 1. adding id number to id_array
  mp_len = mp_len + 1
  .idx = mp_len
  mp_ids[.idx] = .id
  ;
  ; 2. decode IP
  .$temp = $DECODE (.$ip, ".", 0)
  .$bin = $DECODE (.$ip, ".", 1)
  mp_ips[.id,0] = VAL (.$temp)
  ;
  .$temp = $DECODE (.$ip, ".", 0)
  .$bin = $DECODE (.$ip, ".", 1)
  mp_ips[.id,1] = VAL (.$temp)
  ;
  .$temp = $DECODE (.$ip, ".", 0)
  .$bin = $DECODE (.$ip, ".", 1)
  mp_ips[.id,2] = VAL (.$temp)
  ;
  .$temp = $DECODE (.$ip, ":", 0)
  .$bin = $DECODE (.$ip, ":", 1)
  mp_ips[.id,3] = VAL (.$temp)
  ;
  mp_ports[.id] = VAL (.$ip)
  ;
  ; 3. create element for socket
  mp_sockets[.id] = 0
  ;
  ; 4. create element for STATUS
  mp_stats[.id] = 0
  ;
  ; 5. set mode
  mp_modes[.id] = .mode
  ;
  ; 6. create element for send LEN
  mp_send_len[.id] = 0
  ;
  ; 7. create element for recv LEN
  mp_recv_len[.id] = 0
  ;
  ; 8. set max_data_len
  mp_max_recv_len[.id] = .max_data_len
  ; 
  ; 9. create element for send data
  $mp_send[.id,0] = "_"
  ;
  ; 10. create element for recv data
  $mp_recv[.id,0] = "_"
  ;
  ; 11. create readiness STATUS
  mp_readiness[.id,0] = FALSE
  IF .mode == 2 THEN
    mp_readiness[.id,1] = TRUE
  ELSE
    mp_readiness[.id,1] = FALSE
  END
  ;
  ; 12. add device to free for usage
  mp_free_devices[.id] = TRUE
  ;
  ; 13. add variable for connection retries
  mp_conn_retries[.id] = 0
  ;
  ; 14. check user's data
  IF (.id < 1) OR (.id > 100) THEN
    mp_stats[.id] = -2
  END
  ;
  FOR .i = 0 TO 3
    IF (mp_ips[.id,.i]< 0) OR (mp_ips[.id,.i] > 255) THEN
      mp_stats[.id] = -3
    END
  END
  ;
  IF (mp_ports[.id] < 8192) OR (mp_ports[.id] > 65535) THEN
    mp_stats[.id] = -4
  END
  ;
  IF (mp_modes[.id] < 0) OR (mp_modes[.id] > 2) THEN
    mp_stats[.id] = -5
  END
  ;
  IF (mp_max_recv_len[.id] < 1) OR (mp_max_recv_len[.id] > 255) THEN
    mp_stats[.id] = -6
  END
  ;
.END
.PROGRAM init_arrays.pc ()
  ; ===clear all global arrays===
  mp_len = 0            ; number of active devices
  mp_ids[0] = 0         ; id of the device[0-mp_len]
  mp_ips[0,0] = 0       ; ip of the device [id, 0-3]
  mp_ports[0] = 0       ; port of the device [id]
  mp_sockets[0] = 0     ; socket of the device [id]
  mp_stats[0] = 0       ; status [id]
  mp_modes[0] = 0       ; mode [id]
  mp_send_len[0] = 0    ; len of send array
  mp_recv_len[0] = 0    ; len of recv array
  mp_max_recv_len[0] = 0; max recv string len (1 for modbus)
  $mp_send[0,0] = " "   ; data to dend [id, 0-mp_send_len]
  $mp_recv[0,0] = " "   ; received data [id, 0-mp_recv_len]
  mp_readiness[0,0] = 0 ; readiness to 0:send 1:recv [id, 0-1]
  mp_free_devices[0] = FALSE ; is device free to start new send-recv cycle, or not
  mp_conn_retries[0] = 0     ; how many failed retries has been per device in a row
  mp_max_conn_retries = 0    ; max failed connection retries in a row
  ;
.END
.PROGRAM init_sockets.pc ()
  CALL slog.pc ("Initting tcp/ip sockets")
  TCP_STATUS .p1, .p2[0], .p3[0], .p4[0], .p5[0], .$p6[0]
  IF .p1 <> 0 THEN
    CALL slog.pc ("Found " + $ENCODE (.p1) + " active sockets:")
    FOR .i = 0 TO .p1 - 1
      CALL slog.pc ("1: " + " ---------->")
      CALL slog.pc ("Port: " + $ENCODE (.p2[.i]))
      CALL slog.pc ("Socket: " + $ENCODE (.p3[.i]))
      CALL slog.pc ("IP: " + .$p6[.i])
      ;
      IF .p3[.i] <> 0 THEN
        TCP_CLOSE .ret, .p3[.i]
        CALL slog.pc ("Socket closed")
      END
      CALL slog.pc ("----------")
    END
  ELSE
    CALL slog.pc ("Tcp/ip sockets OK")
  END
.END
.PROGRAM device_graph.pc (.id)
  ; === Realisation of status model ===
  ;
  ; 1. get status
  .status = mp_stats[.id]
  ;
  ; 2. graph
  CASE .status OF
    VALUE 0:
      ;disconnected
      CALL device_conn.pc(.id)
      ;
    VALUE 1:
      ;connected
      CALL data_graph.pc(.id)
      ;
    ANY:
      ;error status
      RETURN
  END
  ;
  ; 3. wait abit
  TWAIT 0.1
  ;
.END
.PROGRAM device_conn.pc (.id)
  ; === establishing  the connection to the device ===
  ;
  ; 0. checking retries
  IF mp_conn_retries[.id] > mp_max_conn_retries THEN
    RETURN
  END
  ;
  ; 1. getting variables
  .ip[0] = mp_ips[.id,0]
  .ip[1] = mp_ips[.id,1]
  .ip[2] = mp_ips[.id,2]
  .ip[3] = mp_ips[.id,3]
  .port = mp_ports[.id]
  .socket = mp_sockets[.id]
  .ret = 0
  ;
  ; 2. check socket
  IF .socket <> 0 THEN
    TCP_CLOSE .ret, .socket
  END
  ;
  ; 3. check closing STATUS
  IF .ret < 0 THEN
    mp_stats[.id] = 0
    RETURN
  ELSE
    mp_sockets[.id] = 0
  END
  
  ;  
  ; 4. connection
  TCP_CONNECT .ret, .port, .ip[0], 1       
  IF .ret <= 0 THEN
    call slog.pc ("Error TCP_CONNECT to device " + $ENCODE(.id) + ": ")
    call rlog.pc(.ret)
    mp_stats[.id] = 0
    mp_conn_retries[.id] = mp_conn_retries[.id] + 1
    IF .ret == 0 THEN
      CALL clear_socket.pc
    END
  ELSE
    call slog.pc ("TCP_CONNECTED to device " + $ENCODE(.id) + ": ")
    call rlog.pc(.ret)
    mp_sockets[.id] = .ret
    mp_stats[.id] = 1
    mp_conn_retries[.id] = 0
  END
.END
.PROGRAM sender.pc (.id)
  ; === Send data ===
  ;
  ; 1. getting variables
  .socket = mp_sockets[.id]
  .datalen = mp_send_len[.id]
  .$data[0] = ""
  ;
  ; 2. checking readiness
  IF NOT mp_readiness[.id,0] THEN
    RETURN
  END
  ;
  ; 3. getting data to send
  IF .datalen < 1 THEN
    mp_stats[.id] = -1 ;invalid datalen
    RETURN
  END
  ;
  ;
  FOR .i = 0 TO .datalen -1
    .$data[.i] = $mp_send[.id, .i]
  END
  ;
  ; 4. try to send data
  .ret = 0
  TCP_SEND .ret, .socket, .$data[0], .datalen, 1
  ;
  ; 5. checking STATUS
  IF .ret < 0 THEN
    mp_stats[.id] = 0 ; disconnected
    call slog.pc ("Error TCP_SEND to device " + $ENCODE(.id) + ": ")
    call rlog.pc(.ret)
    RETURN 
  ELSE 
    call slog.pc ("TCP_SEND to device " + $ENCODE(.id) + ": ")
    $mp_send[.id, 0] = "_" ; clearing for new data
    mp_readiness[.id,0] = FALSE
  END
.END
.PROGRAM receiver.pc (.id)
  ; === Recv data ===
  ;
  IF mp_readiness[.id,1] THEN
    RETURN
  END
  ; 1. getting variables
  .socket = mp_sockets[.id]
  .$data[0] = ""
  .max_len = mp_max_recv_len[.id]
  ;
  ; 2. updating readiness
  mp_readiness[.id,1] = FALSE
  ;
  ; 3. getting data to recv
  .ret = 0
  .datalen = 0
  TCP_RECV .ret, .socket, .$data[0], .datalen, 1, .max_len
  ;
  ; 4. checking STATUS
  IF .ret < 0 THEN
    call slog.pc ("Error TCP_RECV from device " + $ENCODE(.id) + ": ")
    call rlog.pc(.ret)
    mp_stats[.id] = 0 ; disconnected
    RETURN 
  ELSE 
    call slog.pc ("TCP_RECV from device " + $ENCODE(.id) + ": ")
  END
  ;
  ; 5. Writing data
  FOR .i = 0 TO .datalen -1
    $mp_recv[.id, .i] = .$data[.i]
  END
  .temp = .datalen -1
  mp_recv_len[.id] = .temp
  ;
  ; 6. updating readiness
  mp_readiness[.id,1] = TRUE
.END
.PROGRAM data_graph.pc (.id)
  ; === Realisation of data exchange mode ===
  ;
  ; 1. get mode
  .mode = mp_modes[.id]
  ;
  ; 2. graph
  CASE .mode OF
    VALUE 0:
      ;send -> recv
      CALL sender.pc(.id)
      CALL receiver.pc(.id)
    VALUE 1:
      ;only send
      CALL sender.pc(.id)
    VALUE 2:
      ;only recv
      CALL receiver.pc(.id)
  END
.END
.PROGRAM err_handler.pc (.id)
  ; === error handler and logger ===
  ;
  ; 1. get status
  .status = mp_stats[.id]
  ;
  ; 2. check status model
  IF .status > 1 THEN
    mp_stats[.id] = -1
    .status = -1
  END
  ;
  ; 3. creating error message
  CASE .status OF
  VALUE -1:
    ; invalid STATUS
    .$msg = "Multiplexer device ID "+ $ENCODE(.id)+ " error : " + $ENCODE(.status) + " invalid device status"
    mp_stats[.id] = -101
    ;
  VALUE -2:
    ; id out of range
    .$msg = "Multiplexer device ID "+ $ENCODE(.id)+ " error : " + $ENCODE(.status) + " ID is out of range"
    mp_stats[.id] = -102
    ;
  VALUE -3:
    ; invalid IP
    .$msg = "Multiplexer device ID "+ $ENCODE(.id)+ " error : " + $ENCODE(.status) + " invalid IP"
    mp_stats[.id] = -103
    ;
  VALUE -4:
    ; port is out of range
    .$msg = "Multiplexer device ID "+ $ENCODE(.id)+ " error : " + $ENCODE(.status) + " port is out of range"
    mp_stats[.id] = -104
    ;
  VALUE -5:
    ; invalid data cycle mode
    .$msg = "Multiplexer device ID "+ $ENCODE(.id)+ " error : " + $ENCODE(.status) + " invalid data cycle mode"
    mp_stats[.id] = -105
    ;
  VALUE -6:
    ; max data len is out of range
    .$msg = "Multiplexer device ID "+ $ENCODE(.id)+ " error : " + $ENCODE(.status) + " max data len is out of range"
    mp_stats[.id] = -106
    ;
  END
  ;
  ; 4. logging error
  CALL slog.pc(.$msg)
.END
.PROGRAM slog.pc(.$msg) #0;
  IF debug THEN
    PRINT  $TIME + ": " + .$msg
  END
.END
.PROGRAM rlog.pc(.num) #0
  IF debug THEN
    PRINT $TIME + ": " + $ENCODE (.num)
  END
.END
.PROGRAM clear_socket.pc ()
  TCP_STATUS .p1, .p2[0], .p3[0], .p4[0], .p5[0], .$p6[0]
  IF .p1 <> 0 THEN
    FOR .i = 0 TO .p1 - 1
      IF .p3[.i] <> 0 THEN
        .temp = TRUE
        FOR .j = 1 TO mp_len
          IF mp_sockets[.j] == .p3[.i] THEN
            .temp = FALSE
          END
        END
        IF .temp THEN
          TCP_CLOSE .ret, .p3[.i]
        END
      END
    END
  END
.END
.PROGRAM reconn_reset.pc ()
  FOR .j = 1 TO mp_len
    mp_conn_retries[.j] = 0
    mp_stats[.j] = 0
  END
.END
.PROGRAM d2_recv_sta.pc ()
  .adr = 1
  .addr[0] = (.adr - .adr % 256)/256
  .addr[1] = .adr % 256
  .res[0] = 0
  .err = 0
  CALL ReadDO.pc(.addr[], .res[], 1, .err, d1_device_id)
  IF .res[0] == 1 AND .err == 0 THEN
    SIG IO_d1_output
  ELSE
    SIG -IO_d1_output
  END
  ;
  ;
  ; state
  .adr = 16392
  .addr[0] = (.adr - .adr % 256)/256
  .addr[1] = .adr % 256
  .res[0] = 0
  .err = 0
  CALL ReadAO.pc(.addr[], .res[], 1, .err, d1_device_id)
  IF .err == 0 THEN
    d2_float_o = .res[0]
  END
.END
.PROGRAM send_d2_flag.pc ()
  .addr[0] = ^H0
  .addr[1] = ^H4
  .res[0] = 0
  .err = 0
  .state = -1 * SIG (IO_d2_par2_i)
  CALL WriteSDO.pc (.addr[], .res[], .state, .err, d2_device_id)
  IF .err == 0 THEN
    temp_IO_d2_par2 = SIG (IO_d2_par2_i)
  END
.END
.PROGRAM send_d2_pars.pc ()
  .adr = 1
  .addr[0] = (.adr - .adr % 256)/256
  .addr[1] = .adr % 256
  .res[0] = 0
  .err = 0
  .state = d2_par1_i
  CALL WriteSAO.pc (.addr[], .res[], .state, .err, d2_device_id)
  IF .err == 0 THEN
    SIG -IO_d2_send
  END
.END
.PROGRAM init_device2.pc (.id)
  d2_device_id = .id
  CALL send_d2_pars.pc
  CALL send_d2_flag.pc
.END
.PROGRAM Comment___ () ; Comments for IDE. Do not use.
  ; @@@ PROJECT @@@
  ; 
  ; @@@ PROJECTNAME @@@
  ; multiplexer_v2p1_for_LW_обезличивание
  ; @@@ HISTORY @@@
  ; 20.12.2025 19:21:58
  ; 
  ; 24.02.2026 16:52:40
  ; 
  ; 25.02.2026 09:51:02
  ; 
  ; 02.03.2026 12:14:40
  ; 
  ; 06.03.2026 10:36:10
  ; 
  ; @@@ INSPECTION @@@
  ; @@@ CONNECTION @@@
  ; KROSET R01
  ; 127.0.0.1
  ; 9105
  ; @@@ PROGRAM @@@
  ; 0:example:F
  ; 0:tester.pc:B
  ; .ip 
  ; .port 
  ; .socket 
  ; .ret 
  ; Group:main_tasks:1
  ; 1:interface_m.pc:B
  ; .temp 
  ; 1:device_man.pc:B
  ; 1:multiplexer.pc:B
  ; .i 
  ; .device_id 
  ; 1:init_mp.pc:B
  ; Group:device 1 :2
  ; 2:send_d1_pars.pc:B
  ; .mixer_spd 
  ; .disk_spd 
  ; .twait_before 
  ; .twait_after 
  ; .adr 
  ; .addr 
  ; .res 
  ; .err 
  ; .state 
  ; 2:init_device1.pc:B
  ; .device_id 
  ; 2:d1_recv_sta.pc:B
  ; .adr 
  ; .addr 
  ; .res 
  ; .err 
  ; Group:modbusCommands:3
  ; 3:ReadDO.pc:B
  ; .addr[] 
  ; .res[] 
  ; .count 
  ; .err 
  ; .device_id 
  ; .addr 
  ; .res 
  ; .req 
  ; .i 
  ; .temp 
  ; .ans 
  ; .j 
  ; 3:ReadAI.pc:B
  ; .addr[] 
  ; .res[] 
  ; .count 
  ; .err 
  ; .device_id 
  ; .addr 
  ; .res 
  ; .req 
  ; .i 
  ; .temp 
  ; .ans 
  ; 3:ReadDI.pc:B
  ; .addr[] 
  ; .res[] 
  ; .count 
  ; .err 
  ; .device_id 
  ; .addr 
  ; .res 
  ; .req 
  ; .i 
  ; .temp 
  ; .ans 
  ; .j 
  ; 3:ReadAO.pc:B
  ; .addr[] 
  ; .res[] 
  ; .count 
  ; .err 
  ; .device_id 
  ; .addr 
  ; .res 
  ; .req 
  ; .i 
  ; .temp 
  ; .ans 
  ; 3:WriteMDO.pc:B
  ; .addr[] 
  ; .res[] 
  ; .state[] 
  ; .count 
  ; .err 
  ; .device_id 
  ; .addr 
  ; .res 
  ; .state 
  ; .bytes 
  ; .req 
  ; .i 
  ; .temp 
  ; .j 
  ; .ans 
  ; 3:WriteSDO.pc:B
  ; .addr[] 
  ; .res[] 
  ; .state 
  ; .err 
  ; .device_id 
  ; .addr 
  ; .res 
  ; .req 
  ; .i 
  ; .temp 
  ; .ans 
  ; 3:WriteMAO.pc:B
  ; .addr[] 
  ; .res[] 
  ; .state[] 
  ; .count 
  ; .err 
  ; .device_id 
  ; .addr 
  ; .res 
  ; .state 
  ; .bytes 
  ; .PDU_len 
  ; .req 
  ; .i 
  ; .temp 
  ; .ans 
  ; 3:WriteSAO.pc:B
  ; .addr[] 
  ; .res[] 
  ; .state 
  ; .err 
  ; .device_id 
  ; .addr 
  ; .res 
  ; .req 
  ; .i 
  ; .temp 
  ; .ans 
  ; 3:slog_mb.pc:B
  ; 3:rlog_mb.pc:B
  ; .num 
  ; Group:multiplexer:4
  ; 4:init_device.pc:B
  ; .id 
  ; .$ip 
  ; .mode 
  ; .max_data_len 
  ; .idx 
  ; .i 
  ; 4:init_arrays.pc:B
  ; 4:init_sockets.pc:B
  ; .p1 
  ; .p2 
  ; .p3 
  ; .p4 
  ; .p5 
  ; .i 
  ; .ret 
  ; 4:device_graph.pc:B
  ; .id 
  ; .status 
  ; 4:device_conn.pc:B
  ; .id 
  ; .ip 
  ; .port 
  ; .socket 
  ; .ret 
  ; 4:sender.pc:B
  ; .id 
  ; .socket 
  ; .datalen 
  ; .i 
  ; .ret 
  ; 4:receiver.pc:B
  ; .id 
  ; .socket 
  ; .max_len 
  ; .ret 
  ; .datalen 
  ; .i 
  ; .temp 
  ; 4:data_graph.pc:B
  ; .id 
  ; .mode 
  ; 4:err_handler.pc:B
  ; .id 
  ; .status 
  ; 4:slog.pc:B
  ; 4:rlog.pc:B
  ; .num 
  ; 4:clear_socket.pc:B
  ; .p1 
  ; .p2 
  ; .p3 
  ; .p4 
  ; .p5 
  ; .i 
  ; .temp 
  ; .j 
  ; .ret 
  ; 4:reconn_reset.pc:B
  ; .j 
  ; Group:device 2:5
  ; 5:d2_recv_sta.pc:B
  ; .addr 
  ; .res 
  ; .err 
  ; .state 
  ; .st 
  ; 5:send_d2_flag.pc:B
  ; .addr 
  ; .res 
  ; .err 
  ; .state 
  ; 5:send_d2_pars.pc:B
  ; .mixer_spd 
  ; .disk_spd 
  ; .twait_before 
  ; .twait_after 
  ; .adr 
  ; .addr 
  ; .res 
  ; .err 
  ; .state 
  ; 5:init_device2.pc:B
  ; .id 
  ; @@@ TRANS @@@
  ; @@@ JOINTS @@@
  ; @@@ REALS @@@
  ; @@@ STRINGS @@@
  ; @@@ INTEGER @@@
  ; @@@ SIGNALS @@@
  ; IO_d1_send 
  ; IO_d2_output 
  ; IO_d2_par2_i 
  ; IO_d2_send 
  ; IO_d2_par2_o 
  ; IO_devman_blink 
  ; IO_d1_connect 
  ; IO_d2_connect 
  ; IO_interf_blink 
  ; IO_reconn_dev 
  ; IO_multi_blink 
  ; IO_d1_output 
  ; IO_hmi_d1_send 
  ; IO_hmi_d2_send 
  ; IO_hmi_rec_div 
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
IO_d1_send = 2033
debug = -1
d1_par2_i = 25
d1_par1_i = 80
d2_device_id = 2
d1_device_id = 1
d2_par1_i = 800
IO_d2_output = 2014
IO_d2_par2_i = 2031
IO_d2_send = 2021
IO_d2_par2_o = 2015
IO_devman_blink = 2012
IO_d1_connect = 2018
IO_d2_connect = 2019
IO_interf_blink = 2010
IO_reconn_dev = 2009
IO_multi_blink = 2013
IO_d1_output = 2017
IO_hmi_d1_send = 2005
IO_hmi_d2_send = 2007
IO_hmi_rec_div = 2011
.END
