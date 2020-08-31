DATA SEGMENT
;键盘按键通断码 (QWERTYU, 1~0)
        keys    DB 10H, 11H, 12H, 13H, 14H, 15H, 16H, 02H, 03H, 04H, 05H, 06H, 07H, 08H, 09H, 0AH, 0BH
                DB 90H, 91H, 92H, 93H, 94H, 95H, 96H, 82H, 83H, 84H, 85H, 86H, 87H, 88H, 89H, 8AH, 8BH

;中断相关变量
        int_vect_timer EQU 08H
        irq_mask_timer EQU 11111110B
        int_vect_key EQU 09H
        irq_mask_key EQU 11111101B
        irq_mask EQU 11111111B
        CSreg_timer DW 0
        IPreg_timer DW 0
        CSreg_key DW 0
        IPreg_key DW 0
        ESreg DW 0

;I/O相关变量
        freq DW 262, 294, 330, 349, 392, 440, 494, 523, 587, 659, 698, 784, 880, 988, 1046, 1175, 1318
        index DW 0              ;当前按键对应的频率序号
        keyPressed DB 0         ;最后按下的键的键值
        keyReleased DB 0        ;最后松开的键的键值
        isKey DB 0              ;是否按下了键值表中的按键 (0-未按下, 1-按下)
        isESC DB 0              ;是否按下ESC键
        keyState DB 17 DUP(0)   ;各按键当前状态, 用于解决长按导致的重复输入问题
        lastKey DW 0            ;自动模式下最后一个按下的按键, 功能类似于keyPressed

;时间键值对读写相关变量
        counter_1 DW 0          ;玩家模式和录音模式定时器计数绝对值
        counter_2 DW 0          ;自动模式定时器计数绝对值
        record_counter DW 256 DUP(0)    ;定时器计数数组, 用于录音功能
        record_key DW 256 DUP(0)        ;键值数组, 用于录音功能
        dataPtr DW 0            ;读写指针
        recordLen DW 0          ;录音长度, 用于判断是否终止

;主界面UI相关变量
        mode DB 0               ;当前工作模式 (0-玩家模式, 1-录音模式, 2-自动回放模式, 0FFH-退出)
        str_space DB ' ', '$'
        str_info DB 0DH, 0AH, '               Welcome to Digital Piano Program !$'
        str_credit DB 0DH, 0AH, '               Ver. 1.0      by Starry Night$'
        str_help DB 0DH, 0AH, '     Press Q W E R T Y U 1 2 3 4 5 6 7 8 9 0 for Bass C ~ Treble E$'
        str_option_A DB 0DH, 0AH, '             -A-             Manual Mode$'
        str_option_B DB 0DH, 0AH, '             -B-             Recording Mode$'
        str_option_C DB 0DH, 0AH, '             -C-             Auto-replay Mode', 0DH, 0AH, '$'

;定时相关变量
        time DW 6 DUP(0)
        isCounting DB 0         ;是否正在计数

;定时器UI相关变量
        pos_digit DW 184, 200, 224, 240, 264, 280               ;数码管位置 (以左上角为基准, 每行为160)
        pos_colon DW 218, 258   ;冒号位置
        color_digit     DB 04H, 00H, 04H, 00H, 0EH, 00H         ;数码管的颜色 (由于为字节定义, 相邻两个数码管直接插入空白颜色项, 以共用DI指针)
                        DB 0EH, 00H, 03H, 00H, 03H, 00H
        hgt DB 0                ;当前矩阵的绘制高度, 用于dispMatrix过程
        len DB 0                ;当前矩阵的绘制宽度, 用于dispMatrix过程

;数码管矩阵
        digit_0 DB 00H, 0FEH, 0FEH, 0FEH, 0FEH, 0FEH, 00H
                DB 0FEH, 00H, 00H, 00H, 00H, 00H, 0FEH
                DB 0FEH, 00H, 00H, 00H, 00H, 0FEH, 0FEH
                DB 0FEH, 00H, 00H, 00H, 0FEH, 00H, 0FEH
                DB 0FEH, 00H, 00H, 0FEH, 00H, 00H, 0FEH
                DB 0FEH, 00H, 0FEH, 00H, 00H,00H,0FEH
                DB 0FEH, 0FEH, 00H, 00H, 00H, 00H, 0FEH
                DB 0FEH, 00H, 00H, 00H, 00H, 00H, 0FEH
                DB 00H, 0FEH, 0FEH, 0FEH, 0FEH, 0FEH, 00H
        digit_1 DB 00H, 00H, 0FEH, 0FEH, 00H, 00H, 00H
                DB 00H, 0FEH, 00H, 0FEH, 00H, 00H, 00H
                DB 0FEH, 00H, 00H, 0FEH, 00H,00H, 00H
                DB 00H, 00H, 00H, 0FEH, 00H, 00H, 00H
                DB 00H, 00H, 00H, 0FEH, 00H, 00H, 00H
                DB 00H, 00H, 00H, 0FEH, 00H, 00H, 00H
                DB 00H, 00H, 00H, 0FEH, 00H, 00H, 00H
                DB 00H, 00H, 00H, 0FEH, 00H, 00H, 00H
                DB 0FEH, 0FEH, 0FEH, 0FEH, 0FEH, 0FEH, 0FEH
        digit_2 DB 00H, 0FEH, 0FEH, 0FEH, 0FEH, 0FEH, 00H
                DB 0FEH, 00H, 00H, 00H, 00H, 00H, 0FEH
                DB 00H, 00H, 00H, 00H, 00H, 00H, 0FEH
                DB 00H, 00H, 00H, 00H, 00H, 0FEH, 00H
                DB 00H, 00H, 00H, 0FEH, 0FEH, 00H, 00H
                DB 00H, 00H, 0FEH, 00H, 00H, 00H, 00H
                DB 00H, 0FEH, 00H, 00H, 00H, 00H, 00H
                DB 0FEH, 00H, 00H, 00H, 00H, 00H, 00H
                DB 0FEH, 0FEH, 0FEH, 0FEH, 0FEH, 0FEH, 0FEH
        digit_3 DB 00H, 0FEH, 0FEH, 0FEH, 0FEH, 0FEH, 00H
                DB 0FEH, 00H, 00H, 00H, 00H, 00H, 0FEH
                DB 00H, 00H, 00H, 00H, 00H, 00H, 0FEH
                DB 00H, 00H, 00H, 00H, 00H, 00H, 0FEH
                DB 00H, 00H, 0FEH, 0FEH, 0FEH, 0FEH, 00H
                DB 00H, 00H, 00H, 00H, 00H, 00H, 0FEH
                DB 00H, 00H, 00H, 00H, 00H, 00H, 0FEH
                DB 0FEH, 00H, 00H, 00H, 00H, 00H, 0FEH
                DB 00H, 0FEH, 0FEH, 0FEH, 0FEH, 0FEH, 00H
        digit_4 DB 00H, 00H, 00H, 00H, 00H, 0FEH, 00H
                DB 00H, 00H, 00H, 00H, 0FEH, 0FEH, 00H
                DB 00H, 00H, 00H, 0FEH, 00H, 0FEH, 00H
                DB 00H, 00H, 0FEH, 00H, 00H, 0FEH, 00H
                DB 00H, 0FEH, 00H, 00H, 00H, 0FEH, 00H
                DB 0FEH, 0FEH, 0FEH, 0FEH, 0FEH, 0FEH, 0FEH
                DB 00H, 00H, 00H, 00H, 00H, 0FEH, 00H
                DB 00H, 00H, 00H, 00H, 00H, 0FEH, 00H
                DB 00H, 00H, 00H, 00H, 00H, 0FEH, 00H
        digit_5 DB 0FEH, 0FEH, 0FEH, 0FEH, 0FEH, 0FEH, 0FEH
                DB 0FEH, 00H, 00H, 00H, 00H, 00H, 00H
                DB 0FEH, 00H, 00H, 00H, 00H, 00H, 00H
                DB 0FEH, 00H, 00H, 00H, 00H, 00H, 00H
                DB 0FEH, 0FEH, 0FEH, 0FEH, 0FEH, 0FEH, 00H
                DB 00H, 00H, 00H, 00H, 00H, 00H, 0FEH
                DB 00H, 00H, 00H, 00H, 00H, 00H, 0FEH
                DB 0FEH, 00H, 00H, 00H, 00H, 00H, 0FEH
                DB 00H, 0FEH, 0FEH, 0FEH, 0FEH, 0FEH, 00H
        digit_6 DB 00H, 0FEH, 0FEH, 0FEH, 0FEH, 0FEH, 00H
                DB 0FEH, 00H, 00H, 00H, 00H, 00H, 0FEH
                DB 0FEH, 00H, 00H, 00H, 00H, 00H, 00H
                DB 0FEH, 00H, 00H, 00H, 00H, 00H, 00H
                DB 0FEH, 0FEH, 0FEH, 0FEH, 0FEH, 0FEH, 00H
                DB 0FEH, 00H, 00H, 00H, 00H, 00H, 0FEH
                DB 0FEH, 00H, 00H, 00H, 00H, 00H, 0FEH
                DB 0FEH, 00H, 00H, 00H, 00H, 00H, 0FEH
                DB 00H, 0FEH, 0FEH, 0FEH, 0FEH, 0FEH, 00H
        digit_7 DB 0FEH, 0FEH, 0FEH, 0FEH, 0FEH, 0FEH, 0FEH
                DB 0FEH, 00H, 00H, 00H, 00H, 00H, 0FEH
                DB 00H, 00H, 00H, 00H, 00H, 0FEH, 00H
                DB 00H, 00H, 00H, 00H, 0FEH, 00H, 00H
                DB 00H, 00H, 00H, 0FEH, 00H, 00H, 00H
                DB 00H, 00H, 0FEH, 00H, 00H, 00H, 00H
                DB 00H, 00H, 0FEH, 00H, 00H, 00H, 00H
                DB 00H, 00H, 0FEH, 00H, 00H, 00H, 00H
                DB 00H, 00H, 0FEH, 00H, 00H, 00H, 00H
        digit_8 DB 00H, 0FEH, 0FEH, 0FEH, 0FEH, 0FEH, 00H
                DB 0FEH, 00H, 00H, 00H, 00H, 00H, 0FEH
                DB 0FEH, 00H, 00H, 00H, 00H, 00H, 0FEH
                DB 0FEH, 00H, 00H, 00H, 00H, 00H, 0FEH
                DB 00H, 0FEH, 0FEH, 0FEH, 0FEH, 0FEH, 00H
                DB 0FEH, 00H, 00H, 00H, 00H, 00H, 0FEH
                DB 0FEH, 00H, 00H, 00H, 00H, 00H, 0FEH
                DB 0FEH, 00H, 00H, 00H, 00H, 00H, 0FEH
                DB 00H, 0FEH, 0FEH, 0FEH, 0FEH, 0FEH, 00H
        digit_9 DB 00H, 0FEH, 0FEH, 0FEH, 0FEH, 0FEH, 0FEH
                DB 0FEH, 00H, 00H, 00H, 00H, 00H, 0FEH
                DB 0FEH, 00H, 00H, 00H, 00H, 00H, 0FEH
                DB 0FEH, 00H, 00H, 00H, 00H, 00H, 0FEH
                DB 00H, 0FEH, 0FEH, 0FEH, 0FEH, 0FEH, 0FEH
                DB 00H, 00H, 00H, 00H, 00H, 00H, 0FEH
                DB 00H, 00H, 00H, 00H, 00H, 00H, 0FEH
                DB 0FEH, 00H, 00H, 00H, 00H, 00H, 0FEH
                DB 00H, 0FEH, 0FEH, 0FEH, 0FEH, 0FEH, 00H
        digit_A DB 00H, 0FEH, 0FEH, 0FEH, 00H, 00H, 00H
                DB 0FEH, 0FEH, 00H, 0FEH, 0FEH, 00H, 00H
                DB 0FEH, 0FEH, 00H, 0FEH, 0FEH, 00H, 00H
                DB 0FEH, 0FEH, 0FEH, 0FEH, 0FEH, 00H, 00H
                DB 0FEH, 0FEH, 00H, 0FEH, 0FEH, 00H, 00H
                DB 0FEH, 0FEH, 00H, 0FEH, 0FEH, 00H, 00H
                DB 0FEH, 0FEH, 00H, 0FEH, 0FEH, 00H, 00H
                DB 00H, 00H, 00H, 00H, 00H, 00H, 00H
                DB 00H, 00H, 00H, 00H, 00H, 00H, 00H
        digit_B DB 0FEH, 0FEH, 0FEH, 0FEH, 00H, 00H, 00H
                DB 0FEH, 0FEH, 00H, 0FEH, 0FEH, 00H, 00H
                DB 0FEH, 0FEH, 00H, 0FEH, 0FEH, 00H, 00H
                DB 0FEH, 0FEH, 0FEH, 0FEH, 00H, 00H, 00H
                DB 0FEH, 0FEH, 00H, 0FEH, 0FEH, 00H, 00H
                DB 0FEH, 0FEH, 00H, 0FEH, 0FEH, 00H, 00H
                DB 0FEH, 0FEH, 00H, 0FEH, 00H, 00H, 00H
                DB 00H, 00H, 00H, 00H, 00H, 00H, 00H
                DB 00H, 00H, 00H, 00H, 00H, 00H, 00H
        digit_C DB 00H, 0FEH, 0FEH, 0FEH, 00H, 00H, 00H
                DB 0FEH, 0FEH, 00H, 0FEH, 0FEH, 00H, 00H
                DB 0FEH, 0FEH, 00H, 00H, 00H, 00H, 00H
                DB 0FEH, 0FEH, 00H, 00H, 00H, 00H, 00H
                DB 0FEH, 0FEH, 00H, 00H, 00H, 00H, 00H
                DB 0FEH, 0FEH, 00H, 0FEH, 0FEH, 00H, 00H
                DB 00H, 0FEH, 0FEH, 0FEH, 00H, 00H, 00H
                DB 00H, 00H, 00H, 00H,00H, 00H, 00H
                DB 00H, 00H, 00H, 00H,00H, 00H, 00H
        digit_D DB 0FEH, 0FEH, 0FEH, 0FEH, 00H, 00H, 00H
                DB 0FEH, 0FEH, 00H, 0FEH, 0FEH, 00H, 00H
                DB 0FEH, 0FEH, 00H, 0FEH, 0FEH, 00H, 00H
                DB 0FEH, 0FEH, 00H, 0FEH, 0FEH, 00H, 00H
                DB 0FEH, 0FEH, 00H, 0FEH, 0FEH, 00H, 00H
                DB 0FEH, 0FEH, 00H, 0FEH, 0FEH, 00H, 00H
                DB 0FEH, 0FEH, 00H, 0FEH, 00H, 00H, 00H
                DB 00H, 00H, 00H,00H, 00H, 00H, 00H
                DB 00H, 00H, 00H,00H, 00H, 00H, 00H
                
        ;数码管矩阵地址数组
        digitAddr       DW OFFSET digit_0, OFFSET digit_1, OFFSET digit_2, OFFSET digit_3, OFFSET digit_4
                        DW OFFSET digit_5, OFFSET digit_6, OFFSET digit_7, OFFSET digit_8, OFFSET digit_9
        ;冒号矩阵
        colon DB 00H, 00H, 0FEH, 00H, 00H, 00H, 0FEH, 00H, 00H

;琴键UI相关变量
        ;琴键矩阵
        keyboard        DB 0FEH, 0FEH, 0FEH
                        DB 0FEH, 0FEH, 0FEH
                        DB 0FEH, 0FEH, 0FEH
                        DB 0FEH, 0FEH, 0FEH
                        DB 0FEH, 0FEH, 0FEH
                        DB 0FEH, 0FEH, 0FEH
                        DB 0FEH, 0FEH, 0FEH
                        DB 0FEH, 0FEH, 0FEH
                        DB 0FEH, 0FEH, 0FEH
                        DB 0FEH, 0FEH, 0FEH
        color_key       DB 77H, 77H, 77H, 77H, 77H, 77H, 77H, 77H, 77H
                        DB 77H, 77H, 77H, 77H, 77H, 77H, 77H, 77H
DATA ENDS

STACKS SEGMENT STACK
    DW 256 DUP(?)
STACKS ENDS

CODE SEGMENT
ASSUME CS:CODE, DS:DATA, SS:STACKS

Main PROC FAR
        START:
                MOV AX, DATA
                MOV DS, AX
                MOV AX, STACKS
                MOV SS, AX
                MOV SP, 256

        OPTIONS:
                CALL dispEntrance
                MOV AL, mode
                CMP AL, 0
                JZ MANUAL_MODE
                CMP AL, 1
                JZ RECORDER_MODE
                CMP AL, 2
                JZ AUTO_MODE
                CMP AL, 0FFH
                JZ EXIT
                JMP OPTIONS
        MANUAL_MODE:
                CALL ManualProc
                JMP OPTIONS
        RECORDER_MODE:
                CALL RecorderProc
                JMP OPTIONS
        AUTO_MODE:
                CALL AutoProc
                JMP OPTIONS
        EXIT:
                MOV AX, 4C00H
                INT 21H
Main ENDP

dispEntrance PROC NEAR
                PUSH AX
                PUSH BX
                PUSH DX
                XOR BX, BX
        ;清空屏幕
                MOV AX, 0003H
                INT 10H

        ;显示主页各条目
                LEA DX, str_info
                MOV AH, 09H
                INT 21H
                LEA DX, str_credit
                INT 21H
                MOV DX, 0500H
                MOV AH, 02H
                INT 10H
                LEA DX, str_help
                MOV AH, 09H
                INT 21H
                MOV DX, 0900H
                MOV AH, 02H
                INT 10H
                MOV AH, 09H
                LEA DX, str_option_A
                INT 21H
                LEA DX, str_option_B
                INT 21H
                LEA DX, str_option_C
                INT 21H

        ;等待键盘输入选项
        WAITING:
                MOV AH, 06H
                MOV DL, 0FFH
                INT 21H
                ;MOV AL, 'C'
                CMP AL, 'A'
                JZ OP_A
                CMP AL, 'a'
                JZ OP_A
                CMP AL, 'B'
                JZ OP_B
                CMP AL, 'b'
                JZ OP_B
                CMP AL, 'C'
                JZ OP_C
                CMP AL, 'c'
                JZ OP_C
                CMP AL, 1BH
                JZ OP_QUIT
                JMP WAITING
        OP_A:
                MOV AL, 0
                MOV mode, AL
                JMP BACK_ENTRANCE
        OP_B:
                MOV AL, 1
                MOV mode, AL
                JMP BACK_ENTRANCE
        OP_C:
                MOV AL, 2
                MOV mode, AL
                JMP BACK_ENTRANCE
        OP_QUIT:
                MOV AL, 0FFH
                MOV mode, AL
        BACK_ENTRANCE:
                POP DX
                POP BX
                POP AX
                RET
dispEntrance ENDP

;写入当前按键的信息
writeData PROC NEAR
                PUSH AX
                PUSH SI
                MOV SI, dataPtr
                MOV AX, index
                MOV record_key[SI], AX
                MOV AX, counter_1
                MOV record_counter[SI], AX
                ADD dataPtr, 2
                ADD recordLen, 2
                POP SI
                POP AX
                RET
writeData ENDP

;玩家模式主过程, 通过循环监测isESC判读是否按下退出键
ManualProc PROC NEAR
                PUSH AX
                CALL rstData
                CALL initKey
                CALL setDispMode
                CALL refreshTime
                CALL refreshKeyboard
                CALL dispColon
        LOOP_MANUAL:
                CMP isESC, 1
                JNZ LOOP_MANUAL
                XOR AX, AX
                MOV isESC, AL
                CALL Mute
                CALL rstDispMode
                CALL rstTimer
                CALL rstKey
                POP AX
                RET
ManualProc ENDP

;录音模式主过程, 通过循环监测isESC判读是否按下退出键
;调用文件读写过程, 在transIndex中执行写文件
RecorderProc PROC NEAR
                PUSH AX
                CALL rstData
                CALL initKey
                CALL setDispMode
                CALL refreshTime
                CALL refreshKeyboard
                CALL dispColon
        LOOP_RECORDER:
                CMP isESC, 1
                JNZ LOOP_RECORDER
                CALL Mute
                CALL rstDispMode
                CALL rstTimer
                CALL rstKey
                POP AX
                RET
RecorderProc ENDP

AutoProc PROC NEAR
                PUSH AX
                PUSH DX
                CALL rstData
                CALL initTimer_Auto
                CALL setDispMode
                CALL refreshTime
                CALL refreshKeyboard
                CALL dispColon
        LOOP_AUTO:
                ;CMP isESC, 1
                ;JZ BACK_AUTO
                MOV AH, 07H
                INT 21H
                CMP AL, 1BH
                JNZ LOOP_AUTO
        BACK_AUTO:
                CALL Mute
                CALL rstRecord
                CALL rstTimer
                POP DX
                POP AX
                RET
AutoProc ENDP

;设置屏幕为 80 × 25 彩色文本显示模式
setDispMode PROC NEAR
                PUSH AX
                MOV AX, ES
                MOV ESreg, AX
                MOV AH, 0
                MOV AL, 03H
                INT 10H
                MOV AX, 0B800H
                MOV ES, AX
                POP AX
                RET
setDispMode ENDP

;恢复屏幕显示模式
rstDispMode PROC NEAR
                PUSH AX
                MOV AH, 06
                MOV AL, 0
                MOV BH, 7
                MOV CX, 0
                MOV DX, 184FH
                INT 10H
                ;MOV AX, ESreg
                ;MOV ES, AX
                POP AX
                RET
rstDispMode ENDP

;显示 hgt × len 的矩阵
dispMatrix PROC NEAR
                PUSH AX
                PUSH BX
                PUSH CX
                MOV CL, hgt
        DISP_1:
                MOV CH, len
                PUSH DI
        DISP_2:
                MOV AL, [BX]
                MOV ES:[DI], AX
                ADD DI, 2
                INC BX
                DEC CH
                JNZ DISP_2
                POP DI
                ADD DI, 160
                DEC CL
                JNZ DISP_1
                POP CX
                POP BX
                POP AX
                RET
dispMatrix ENDP

;显示两组冒号
dispColon PROC NEAR
                PUSH AX
                PUSH BX
                PUSH CX
                PUSH SI
                PUSH DI
                MOV SI, 0
                MOV CX, 2                       ;共2组冒号
        DISP_COLON:
                MOV AL, 9                       ;设置冒号矩阵显示高度9
                MOV hgt, AL
                MOV AL, 1                       ;设置冒号矩阵显示宽度1
                MOV len, AL
                MOV AL, 0
                MOV AH, 1*9
                MUL AH
                MOV BX, OFFSET colon            ;获取冒号冒号显示矩阵地址
                ADD BX, AX
                MOV DI, pos_colon[SI]
                MOV AH, 07H                     ;冒号以灰色显示
                CALL dispMatrix
                INC SI
                INC SI
                LOOP DISP_COLON
                POP DI
                POP SI
                POP CX
                POP BX
                POP AX
                RET
dispColon ENDP

refreshTime PROC NEAR
                PUSH AX
                PUSH BX
                PUSH CX
                PUSH DX
                PUSH SI
                PUSH DI
                ;显示6个数码管
                MOV SI, 0
                MOV CX, 6
        DISP_DIGIT:
                MOV AL, 9                       ;设置数码管矩阵显示高度9
                MOV hgt, AL
                MOV AL, 7                       ;设置数码管矩阵显示宽度7
                MOV len, AL
                MOV AL, 0
                MOV AH, 7*9
                MUL AH
                MOV DX, time[SI]                ;按位获取当前时间, 并用相应数码管显示
                ADD DX, DX                      ;time为字定义, 指针需要乘2
                PUSH SI                         ;利用SI指针寻址
                MOV SI, DX
                MOV BX, digitAddr[SI]           ;获取相应数码管的显示矩阵
                POP SI                          ;恢复SI
                ADD BX, AX
                MOV DI, pos_digit[SI]           ;DI为当前数码管的显示位置
                MOV AH, color_digit[SI]         ;AH为当前数码管的显示颜色
                CALL dispMatrix
                INC SI
                INC SI
                LOOP DISP_DIGIT
                POP DI
                POP SI
                POP DX
                POP CX
                POP BX
                POP AX
                RET
refreshTime ENDP

refreshKeyboard PROC NEAR
                PUSH AX
                PUSH BX
                PUSH CX
                PUSH DX
                PUSH SI
                PUSH DI
                PUSH DS
                MOV SI, 0
                MOV CX, 11H                     ;共11H=17D个琴键
                MOV DX, 160*14+12               ;初始位置
        DISP_KEY:
                MOV AL, 10
                MOV hgt, AL
                MOV AL, 3
                MOV len, AL
                MOV AL, 0
                MOV AH, 2*6
                MUL AH
                MOV BX, OFFSET keyboard
                ADD BX, AX
                MOV DI, DX
                MOV AH, color_key[SI]
                CALL dispMatrix
                ADD DX, 8                       ;琴键位置右移1位
                INC SI
                LOOP DISP_KEY
                POP DS
                POP DI
                POP SI
                POP DX
                POP CX
                POP BX
                POP AX
                RET
refreshKeyboard ENDP

;设置蜂鸣器选项, 发出声音
Beep PROC NEAR
                PUSH AX
                PUSH SI
                PUSH DI
                MOV SI, index
                MOV DI, freq[SI]
                MOV AL, 0B6H                    ;设置8253通道2为方式3二进制计数
                OUT 43H, AL
                MOV DX, 18
                MOV AX, 10352                   ;DX:AX为频率上限1.19MHz
                DIV DI                          ;(DX:AX)/DI, AX为商, DX为余数
                OUT 42H, AL                     ;设置8253通道2计数初值
                MOV AL, AH
                OUT 42H, AL
                IN AL, 61H                      ;读8255端口B
                MOV AH, AL
                OR AL, 0011B
                OUT 61H, AL
                POP DI
                POP SI
                POP AX
                RET
Beep ENDP

;关闭蜂鸣器声音
Mute PROC NEAR
                PUSH AX
                MOV AL, 0                       ;终止声音
                OUT 61H, AL
                POP AX
                RET
Mute ENDP

;定时中断服务程序
intProc_timer PROC NEAR
                STI
                INC counter_1
                CALL adjustTime
                MOV AL, 20H                     ;发送EOI
                OUT 0A0H, AL
                OUT 20H, AL
                IRET
intProc_timer ENDP

;定时中断服务程序 (自动模式)
intProc_timer_Auto PROC NEAR
                STI
                CALL adjustTime
                CALL checkTime
                INC counter_2
                MOV AL, 20H
                OUT 0A0H, AL
                OUT 20H, AL
                IRET
intProc_timer_Auto ENDP

;比较当前时间与下一次按键的时间是否相等
checkTime PROC NEAR
                PUSH AX
                PUSH CX
                PUSH SI
                MOV SI, dataPtr
                MOV AX, counter_2
                CMP AX, record_counter[SI]
                JNZ BACK_CHECK
                CALL Replay
                ADD dataPtr, 2
                MOV AX, recordLen
                CMP AX, dataPtr
                JNZ BACK_CHECK
                MOV AL, 1
                MOV isESC, AL
        BACK_CHECK:
                POP SI
                POP CX
                POP AX
                RET
checkTime ENDP

;根据record_key[SI]的值执行发出声音或静音, 并刷新键盘显示
Replay PROC NEAR
                PUSH AX
                PUSH SI
                MOV SI, dataPtr
                MOV AX, record_key[SI]
                MOV SI, AX
                CMP AX, 20H
                JA AUTO_MUTE
                MOV lastKey, AX
                MOV DI, freq[SI]
                MOV AL, 0B6H                    ;设置8253通道2为方式3二进制计数
                OUT 43H, AL
                MOV DX, 18
                MOV AX, 10352                   ;DX:AX为频率上限1.19MHz
                DIV DI                          ;(DX:AX)/DI, AX为商, DX为余数
                OUT 42H, AL                     ;设置8253通道2计数初值
                MOV AL, AH
                OUT 42H, AL
                IN AL, 61H                      ;读8255端口B
                MOV AH, AL
                OR AL, 0011B
                OUT 61H, AL
                MOV AL, 66H
                SHR SI, 1
                MOV color_key[SI], AL
                CALL refreshKeyboard
                JMP BACK_REPLAY
        AUTO_MUTE:
                MOV AL, 77H
                SHR SI, 1
                SUB SI, 11H
                MOV color_key[SI], AL
                CALL refreshKeyboard
                SHL SI, 1
                CMP SI, lastKey
                JNZ BACK_REPLAY
                CALL Mute
        BACK_REPLAY:
                POP SI
                POP AX
                RET
Replay ENDP

;调整时间变量time, 用于定时中断服务程序调整时间
adjustTime PROC NEAR
                PUSH AX
                INC time[0AH]
                MOV AX, time[0AH]
                CMP AX, 0AH
                JZ MSECOND
                JMP BACK_ADJUST
        MSECOND:
                XOR AX, AX
                MOV time[0AH], AX
                INC time[8]
                MOV AX, time[8]
                CMP AX, 0AH
                JZ SECOND_1
                JMP BACK_ADJUST
        SECOND_1:
                XOR AX, AX 
                MOV time[8], AX
                INC time[6]
                MOV AX, time[6]
                CMP AX, 0AH
                JZ SECOND_2
                JMP BACK_ADJUST
        SECOND_2:
                XOR AX, AX
                MOV time[6], AX
                INC time[4]
                MOV AX, time[4]
                CMP AX, 06H
                JZ MINUTE_1
                JMP BACK_ADJUST
        MINUTE_1:
                XOR AX, AX
                MOV time[4], AX
                INC time[2]
                MOV AX, time[2]
                CMP AX, 0AH
                JZ MINUTE_2
                JMP BACK_ADJUST
        MINUTE_2:
                XOR AX, AX
                MOV time[2], AX
                INC time[0]
        BACK_ADJUST:
                POP AX
                CALL refreshTime
                RET
adjustTime ENDP

;定时中断初始化程序
initTimer PROC NEAR
                PUSH AX
                PUSH ES
                PUSH SI
                CLI
                MOV AL, 1
                MOV isCounting, AL
                ;设置8253通道0计数初值2E7CH, 每个中断对应0.01s
                MOV AL, 36H
                OUT 43H, AL
                MOV AL, 7CH
                OUT 40H, AL
                MOV AL, 2EH
                OUT 40H, AL
                MOV AX, 0
                MOV ES, AX
                MOV AL, int_vect_timer
                MOV AH, 04H
                MUL AH
                MOV SI, AX
                MOV AX, ES:[SI+2]
                MOV CSreg_timer, AX
                MOV BX, ES:[SI]
                MOV IPreg_timer, BX
                MOV AX, CS
                MOV ES:[SI+2], AX
                MOV DX, OFFSET intProc_timer
                MOV ES:[SI], DX
                IN AL, 21H
                AND AL, irq_mask_timer
                OUT 21H, AL
                IN AL, 0A1H
                AND AL, irq_mask
                OUT 0A1H, AL
                POP SI
                POP ES
                POP AX
                STI
                RET
initTimer ENDP

initTimer_Auto PROC NEAR
                PUSH AX
                PUSH ES
                PUSH SI
                CLI
                MOV AL, 1
                MOV isCounting, AL
                ;设置8253通道0计数初值2E7CH, 每个中断对应0.01s
                MOV AL, 36H
                OUT 43H, AL
                MOV AL, 7CH
                OUT 40H, AL
                MOV AL, 2EH
                OUT 40H, AL
                MOV AX, 0
                MOV ES, AX
                MOV AL, int_vect_timer
                MOV AH, 04H
                MUL AH
                MOV SI, AX
                MOV AX, ES:[SI+2]
                MOV CSreg_timer, AX
                MOV BX, ES:[SI]
                MOV IPreg_timer, BX
                MOV AX, CS
                MOV ES:[SI+2], AX
                MOV DX, OFFSET intProc_timer_Auto
                MOV ES:[SI], DX
                IN AL, 21H
                AND AL, irq_mask_timer
                OUT 21H, AL
                IN AL, 0A1H
                AND AL, irq_mask
                OUT 0A1H, AL
                POP SI
                POP ES
                POP AX
                STI
                RET
initTimer_Auto ENDP

;定时中断重置程序
rstTimer PROC NEAR 
                CLI
                PUSH AX
                PUSH ES
                PUSH SI
                XOR AX, AX
                MOV isCounting, AL
                MOV BL, irq_mask_timer
                NOT BL
                IN AL, 21H
                OR AL, BL
                OUT 21H, AL
                MOV BL, irq_mask
                NOT BL
                IN AL, 0A1H
                OR AL, BL
                MOV AX, 0
                MOV ES, AX
                MOV SI, 20H
                MOV DX, IPreg_timer
                MOV ES:[SI], DX
                MOV AX, CSreg_timer
                MOV ES:[SI+2], AX
                POP SI
                POP ES
                POP AX
                STI
                RET
rstTimer ENDP

;按键中断服务程序
intProc_key PROC FAR
                CLI
                PUSH AX
                PUSH DS
                MOV AX, DATA
                MOV DS, AX
                IN AL, 60H                      ;读取当前按键键值
                CMP AL, 01H
                JZ ESCAPE
                CALL transIndex
                MOV AL, isKey
                CMP AL, 0
                JZ BACK_KEY
                MOV AX, index
                CMP AX, 20H                     ;判断按键是否松开
                JA STOP
                CALL Beep                       ;按键按下, 执行Beep
                JMP BACK_KEY
        STOP:
                MOV AL, keyReleased
                SUB AL, 80H
                CMP AL, keyPressed
                JNZ BACK_KEY
                CALL Mute                       ;按键松开, 执行Mute
                JMP BACK_KEY
        ESCAPE:
                MOV AL, 1
                MOV isESC, AL
        BACK_KEY:
                MOV AL, 20H                     ;发送EOI
                OUT 0A0H, AL
                OUT 20H, AL
                POP DS
                POP AX
                STI
                IRET
intProc_key ENDP

;将按键通断码转换为频率序号
transIndex PROC NEAR
                PUSH AX
                PUSH CX
                PUSH DX
                PUSH SI
                MOV SI, 0
                MOV CL, AL
        TRAVERSE:
                CMP AL, keys[SI]
                JZ TRANS
                INC SI
                CMP SI, 22H
                JNZ TRAVERSE
                XOR DX, DX
                MOV isKey, DL                   ;按下的不是键值表中的按键, isKey=0
                JMP BACK_TRANSLATE              ;未在键值表中找到相应按键
        TRANS:
                MOV DL, 1                       ;按下的为键值表中的按键, isKey=1
                MOV isKey, DL
                CMP SI, 10H
                JA KEY_UP
                MOV DL, isCounting
                CMP DL, 1
                JZ KEY_DOWN
                CALL initTimer
        KEY_DOWN:
                MOV AL, keyState[SI]            ;判断当前按键状态, 避免因长按导致重复输入
                CMP AL, 1
                JZ BACK_TRANSLATE
                MOV AL, 1
                MOV keyState[SI], AL
                MOV keyPressed, CL              ;保存最后一个按下的按键键值, 用于判断是否停止声音
                MOV DL, 66H
                MOV color_key[SI], DL
                ADD SI, SI                      ;freq定义为字, 而index按字节计, 故需乘2
                MOV index, SI
                MOV AL, mode
                CMP AL, 1                       ;若为录音模式, 则保存此刻的按键和时间信息
                JNZ GO_KEY
                CALL writeData
        GO_KEY:
                CALL refreshKeyboard
                JMP BACK_TRANSLATE
        KEY_UP:
                JZ BACK_TRANSLATE
                MOV keyReleased, CL             ;保存最后一个松开的按键键值, 用于判断是否停止声音
                MOV DL, 77H
                SUB SI, 11H
                MOV color_key[SI], DL
                MOV AL, 0
                MOV keyState[SI], AL
                CALL refreshKeyboard
                ADD SI, 11H
                ADD SI, SI
                MOV index, SI
                MOV AL, mode
                CMP AL, 1                       ;若为录音模式, 则保存此刻的按键和时间信息
                JNZ GO_KEY
                CALL writeData
        BACK_TRANSLATE:
                POP SI
                POP DX
                POP CX
                POP AX
                RET
transIndex ENDP

;按键中断初始化程序
initKey PROC
                PUSH ES
                PUSH DS
                CLI
                MOV AL, int_vect_key
                MOV AH, 35H
                INT 21H
                MOV AX, ES
                MOV CSreg_key, AX
                MOV IPreg_key, BX
                MOV AX, CS
                MOV DS, AX
                MOV DX, OFFSET intProc_key
                MOV AL, int_vect_key
                MOV AH, 25H
                INT 21H
                IN AL, 21H
                AND AL, irq_mask_key
                OUT 21H, AL
                IN AL, 0A1H
                AND AL, irq_mask
                OUT 0A1H, AL
                POP DS
                POP ES
                STI
                RET
initKey ENDP

;按键中断重置程序
rstKey PROC
                CLI
                PUSH DS
                MOV BL, irq_mask_key
                NOT BL
                IN AL, 21H
                OR AL, BL
                ;OUT 21H, AL
                MOV BL, irq_mask
                NOT BL
                IN AL, 0A1H
                OR AL, BL
                OUT 0A1H, AL
                MOV DX, IPreg_key
                MOV AX, CSreg_key
                MOV DS, AX
                MOV AH, 25H
                MOV AL, int_vect_key
                INT 21H
                STI
                POP DS
                RET
rstKey ENDP

;将变量isESC, keyPressed, keyReleased, dataPtr, counter_1, counter_2, time和color_key复原
;用于从一种模式切换到另一种模式
rstData PROC NEAR
                PUSH AX
                PUSH CX
                PUSH SI
                XOR AX, AX
                MOV isESC, AL
                MOV keyPressed, AL
                MOV keyReleased, AL
                MOV dataPtr, AX
                MOV counter_1, AX
                MOV counter_2, AX
                MOV CX, 6
                MOV SI, 0
        LOOP_RSTTIME:
                MOV time[SI], AX
                ADD SI, 2
                LOOP LOOP_RSTTIME
                MOV CX, 17
                MOV SI, 0
                MOV AL, 77H
        LOOP_RSTCOLOR:
                MOV color_key[SI], AL
                INC SI
                LOOP LOOP_RSTCOLOR
                POP SI
                POP CX
                POP AX
                RET
rstData ENDP

;将变量recordLen, record_counter和record_key复原, 用于多次录音
rstRecord PROC NEAR
                PUSH AX
                PUSH CX
                PUSH SI
                MOV CX, 256
                MOV SI, 0
                XOR AX, AX
                MOV recordLen, AX
        LOOP_RSTRECORD:
                MOV record_counter[SI], AX
                MOV record_key[SI], AX
                ADD SI, 2
                LOOP LOOP_RSTRECORD
                POP SI
                POP CX
                POP AX
                RET
rstRecord ENDP

CODE ENDS
END START