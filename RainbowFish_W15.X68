*-----------------------------------------------------------
* Title      :Rainbow Fish Dissassembler
* Written by :Drew Byland, Herb Traut, Joey Guinasso
* Date       :3/13/2015
* Description:RainbowFish's Disassembler for CSS 422
*             This disassembler deconstructs the required
*             instructions for the Winter 2015 quarter
*-----------------------------------------------------------
    ORG    $1000
START:

*-----------------------------------------------------------
*Locations to store inportant items used throught the code
*-----------------------------------------------------------
BEGINNING   EQU $2E00       The address (given to us by the user) to start at
END         EQU $2E10       The address (given to us by the user) to end at
OPCODE      EQU $2E20       The OPcode
DESTREG     EQU $2E30       The Destination Register
DESTMODE    EQU $2E40       The Destination Mode
SOURCEREG   EQU $2E50       The Source Register
SOURCEMODE  EQU $2E60       The Source Mode
ISFIRST     EQU $2E70       A boolean to help with fencepost dilemma
LOOPCOUNTER EQU $2E80       A counter used to stop loops
CURRENTADD  EQU $2E90       The current address
TRUE        EQU $2EA0       A multipurpose boolean
     
*-----------------------------------------------------------
*START OF PROGRAM
*PRINT BANNER & WELCOME
*-----------------------------------------------------------
PROGSTART
*CLEAR ALL REGISTERS
    CLR.L D0                Clear data register 0                                        
    CLR.L D1                Clear data register 1        
    CLR.L D2                Clear data register 2        
    CLR.L D3                Clear data register 3        
    CLR.L D4                Clear data register 4        
    CLR.L D5                Clear data register 5        
    CLR.L D6                Clear data register 6            
    CLR.L D7                Clear data register 7       
    
    LEA     TRUE,A2         Load "TRUE" into A2 
    MOVE.B  #0,(A2)         Move '0' into "TRUE" (boolean set to false)
    
    LEA     LOOPCOUNTER,A2  Load "LOOPCOUNTER" into A2
    MOVE.W  #0,(A2)         Loop counter set to zero
    
    LEA     BANNER,A1       Print Welcome Message
    MOVE.B  #14,D0          Use trap task 14
    TRAP    #15
    
    LEA     WELCOME,A1      Print Welcome Message
    MOVE.B  #14,D0          Use trap task 14
    TRAP    #15
    
*-----------------------------------------------------------
*INPUT1
*Recieve Starting Address
*-----------------------------------------------------------    
INPUT1    
    LEA     STARTADD,A1     Prompt user for a starting address
    JSR     PRINTLINE
    
    CLR.L   D7              Clear data register 7
    CLR.L   D5              Clear data register 5
    CLR.L   BEGINNING       Clear the "BEGINNING" variable
    LEA     BEGINNING,A1    Load "BEGINNING" into A1
    MOVE.B  #2,D0           Store starting address at BEGINNING
    TRAP    #15
    JSR     CONVERTER       Convert the input into hex
    MOVE.L  D7,BEGINNING    Store input in the "BEGINNING" variable
    JSR     CHECKRANGE      Validate range
    JSR     CHECKODD        Make sure input is not odd

*-----------------------------------------------------------
*INPUT2
*Recieve Ending Address
*-----------------------------------------------------------   
INPUT2    
    LEA     ENDADD,A1       Prompt user for an ending address
    JSR     PRINTLINE       
    
    CLR.L   D7              Clear data register 7
    CLR.L   D5              Clear data register 5
    CLR.L   END             Clear the "END" variable
    LEA     END,A1          Load "END" into A1
    MOVE.B  #2,D0           Store ending address at END
    TRAP    #15
    JSR     CONVERTER       Convert the input into hex
    MOVE.L  D7,END          Store input in the "END" variable
    JSR     CHECKRANGE      Validate range
    JSR     CHECKODD        Make sure input is not odd
    JSR     CHECKVSBEG      Make sure END is not after START

    BRA     OPC             Branch to OPcode

*-----------------------------------------------------------
*CHECKRANGE
*Validate range
*-----------------------------------------------------------    
CHECKRANGE
    CMP.B   #8,D1           CHECKS TO MAKE SURE THAT THE LENGTH IS NOT GREATER THAN A LONG
    BGT     BADADD          IF IT IS, BRANCH AND REQUEST NEW INPUT
    RTS
    
*-----------------------------------------------------------
*CHECKODD
*Make sure input is not odd
*----------------------------------------------------------- 
CHECKODD
    MOVE.B  #31,D1          LOAD NUMBER TO SHIFT ALL BUT LSB
    LSL.L   D1,D7           SHIFT THE BITS SO THAT ONLY THE LSB REMAIN
    LSR.L   D1,D7           SHIFT THE BIT BACK TO ORIGINAL LOCATION
    CMP.B   #1,D7           IF BIT = 1, THEN ODD ADDRESS
    BEQ     BADADD          REQUEST NEW INPUT
    RTS
    
*-----------------------------------------------------------
*CHECKVSBEG
*Make sure END is not after START
*----------------------------------------------------------- 
CHECKVSBEG
    MOVE.L  BEGINNING,A1    STORE BEG AT A1
    MOVE.L  END,A2          STORE END AT A2
    CMP.L   A1,A2           COMPARE THE TWO ADDRESSES
    BLE     BADADD          REQUEST NEW INPUT
    RTS

*-----------------------------------------------------------
*GET OPCODE   
*-----------------------------------------------------------
OPC    
    MOVE.L  BEGINNING,A6    MOVE BEGINNING ADD TO D7
STARTLOOP
    MOVE.B  #4,D4               
    LEA     CURRENTADD,A2   LOAD THE A6 (POINTER TO CURRENT INSTRUCTION)
    MOVE.L  A6,(A2)         INTO THE ADDRESS CURRENT ADD
    MOVEM.L A6,-(SP)        PUSH A6 ONTO THE STACK
    MOVE.L  A2,A6           MOVE CURRENT ADD INTO A6 FOR PRINTING
    MOVE.B  #8,D4           MOVE LONG SIZE(8) INTO D4
    JSR     PRINTTOHEX      CALL PRINTER TO DISPLAY THE CURRENT ADDRESS LOCATION
    MOVEM.L (SP)+,A6        POP A6 OFF THE STACK
    LEA     SPACE,A1        PRINT A SPCE
    JSR     PRINTLINE
    MOVE.W  (A6),D7         MOVE THE CURRENT OPERATION INTO D7
    MOVE.W  D7,D1           MOVE INTO D1 TO MANIPULATE
    MOVE.L  #12,D2          START BITMASK AT BIT 12
    MOVE.L  #4,D3           GRAB 4 BITS
    JSR     BITMASK         MASK SELECTED BITS
    MOVE.L  D0,D2           MOVE MASKED BITS INTO D2
    MOVE.B  D0,D6           MOVE MASKED BITS INTO D6(OPCODE STORAGE LOCATION
    JSR     OPCODECOMPARE   COMPARE OPCODE AGAINST OPCODE TABLE
    BRA     DONE
    
RETURN
    RTS                     USED FOR CONDITIONAL RETURNS

CONVERTER
    ADDI.B  #1,D5           D5 USED FOR THE LOOPER
    CMP.B   D1,D5           COMPARE TO SEE IF LOOP END
    BGT     RETURN          RETURN IF SO
    MOVE.B  (A1)+,D6        MOVE A1 TO D6 AND INCREMENT
    CMP.B   D5,D6               
    BEQ     DONE
    CMP.B   #70,D6          MAX LETTER VALUE
    BGT     BADADD
    CMP.B   #64,D6          MIN-1 LETTER VALUE
    BGT     LET
    CMP.B   #57,D6          MAX NUMBER VALUE
    BGT     BADADD
    CMP.B   #47,D6          MIN-1 NUMBER VALUE
    BGT     NUM
    BRA     BADADD          IF NOT A VALID NUMBER/LETTER. BRA TO BADADDRESS
    RTS
                     
*-----------------------------------------------------------
*BADADD
*USED TO REQUEST NEW INPUT 
*-----------------------------------------------------------    
BADADD                      
    LEA     BADADDS,A1      PRINT INPUT ERROR MESSAGE
    JSR     PRINTLINE
    BRA     INPUT1          BRANCH TO REQUEST NEW INPUT   
LET
    SUBI.B  #55,D6          ASCII TO HEX FOR LETTER CONVERSION
    BRA     CONVERTED    
NUM
    SUBI.B  #48,D6          ASCII TO HEX FOR NUMBER CONVERSION
    BRA     CONVERTED
    
*-----------------------------------------------------------
*CONVERTED
*SUCCESFULLY CONVERTED TO HEX   
*-----------------------------------------------------------
CONVERTED                   
    ASL.L   #4,D7
    ADD.B   D6,D7
    BRA     CONVERTER       BRANCH BACK TO LOOPER
      
*-----------------------------------------------------------
*BIT MASK
*D1- WHOLE 16 BITS/D2-START BIT/D3-NUMBER OF BITS
*-----------------------------------------------------------
BITMASK
    MOVEM.L D1-D4,-(SP)     STORE CURRENT DATA REGS ON STACK
    MOVE.L  D1,D0           MOVE FULL 16 BITS TO D0
    
    CLR     D4              CLR D4
    MOVE.L  #1,D4           MOVE #1 D4
    LSL     D3,D4           SHIFT THE BITS IN D4 THE NUMBETR OF BITS YOU WANT TO MASK
                            
    SUB     #1,D4           SUBTRACT 1
    
    LSR.L   D2,D0           SHIFT TO GET RID OF THE BITS YOU DONT WANT
    AND.L   D4,D0           AND TO MASK THE REAMINING BITS YOU WANT
    
    MOVEM.L (SP)+,D1-D4     POP THE VALUES OFF THE STACK
    RTS                     RETURN WITH D0 CONTAINING MASKED BITS
    
*------------------------------------------------------------
*CHECK MASKED BITS WITH LEGAL OPCODES
*BRANCH ACCORDINGLY
*------------------------------------------------------------
OPCODECOMPARE
    MOVE.B  D2,OPCODE       OPcode 0000
    CMP.B   #%0000,D2
    BEQ     OPC0000
    CMP.B   #%0001,D2       OPcode 0001    
    BEQ     OPC0001
    CMP.B   #%0010,D2       OPcode 0010
    BEQ     OPC0010
    CMP.B   #%0011,D2       OPcode 0011
    BEQ     OPC0011
    CMP.B   #%0100,D2       OPcode 0100
    BEQ     OPC0100
    CMP.B   #%0101,D2       OPcode 0101
    BEQ     OPC0101
    CMP.B   #%0110,D2       OPcode 0110
    BEQ     OPC0110
    CMP.B   #%0111,D2       OPcode 0111
    BEQ     OPC0111
    CMP.B   #%1000,D2       OPcode 1000
    BEQ     OPC1000
    CMP.B   #%1001,D2       OPcode 1001
    BEQ     OPC1001
    CMP.B   #%1011,D2       OPcode 1011
    BEQ     OPC1011
    CMP.B   #%1100,D2       OPcode 1100
    BEQ     OPC1100
    CMP.B   #%1101,D2       OPcode 1101
    BEQ     OPC1101
    CMP.B   #%1110,D2       OPcode 1110
    BEQ     OPC1110
    CMP.B   #%0000,D2       OPcode 0001
    BEQ     OPC0000
    BRA     INVALID         INVALID
    
*------------------------------------------------------------
*USED TO DECODE MOVE.B/MOVE.W/MOVE.L
*------------------------------------------------------------
MOVEDECODE
    LEA     OPCODE,A2       STORE OPCODE AT DETERMINED LOCATION
    MOVE.B  D2,(A2)
    
    MOVE.L  D7,D1           RETRIEVE SOURCE MODE
    MOVE.L  #3,D2           START MASK AT BIT 3
    MOVE.L  #3,D3           SELECT 3 BITS TO MASK
    JSR     BITMASK         RUN BITMASKER
    LEA     SOURCEMODE,A2
    MOVE.B  D0,(A2)         STORE MASKED BITS AT SOURCEMODE
    MOVE.B  D0,D6           MOVE TO D6
    
    MOVE.L  D7,D1           RETRIEVE SOURCE REG
    MOVE.L  #0,D2           START MASK AT 0
    MOVE.L  #3,D3           SELECT 3 BITS TO MASK
    JSR     BITMASK         RUN BITMASKER
    LEA     SOURCEREG,A2          
    MOVE.B  D0,(A2)         STORE BITS AT SOURCE REG
    MOVE.B  D0,D5           MOVE TO D5

    JSR     CHECKDN         CHECK SOURCE MODE Dn
    JSR     CHECKAN         CHECK SOURCE MODE An
    JSR     CHECKANPAREN    CHECK SOURCE MODE (An)
    JSR     CHECKANPLUS     CHECK SOURCE MODE (An)+
    JSR     CHECKMINUSAN    CHECK SOURCE MODE -(An)
    JSR     CHECKDATA       CHECK SOURCE MODE xxx.W,xxx.L,#<data>
    CMP.B   #1,TRUE         IF NONE ARE CALLED
    BNE     INVALID         BRANCH TO INVALID
    
    LEA     COMMA,A1        THIS IS FOR COMMAS
    JSR     PRINTLINE
    
    MOVE.B  #0,TRUE         RESET TRUE TO FALSE
    
    MOVE.L  D7,D1           RETRIEVE DESTINATION MODE
    MOVE.L  #6,D2           START MASK AT BIT 6
    MOVE.L  #3,D3           SELECT 3 BITS TO MASK
    JSR     BITMASK         RUN BITMASKER
    LEA     DESTMODE,A2     
    MOVE.B  D0,(A2)         STORE BITS AT DESTMODE
    MOVE.B  D0,D6           MOVE TO D6
        
    MOVE.L  D7,D1           RETRIEVE DESTINATION REG
    MOVE.L  #9,D2           START MASK AT BIT 9
    MOVE.L  #3,D3           SELECT 3 BITS TO MASK
    JSR     BITMASK         RUN BITMASKER
    LEA     DESTREG,A2          
    MOVE.B  D0,(A2)         STORE BITS AT DESTREG
    MOVE.B  D0,D5           MOVE TO D5
    
    JSR     CHECKDN         CHECK DESTINATION MODE Dn
    JSR     CHECKAN         CHECK DESTINATION MODE An
    JSR     CHECKANPAREN    CHECK DESTINATION MODE (An)
    JSR     CHECKANPLUS     CHECK DESTINATION MODE (An)+
    JSR     CHECKMINUSAN    CHECK DESTINATION MODE -(An)
    JSR     CHECKDATA       CHECK DESTINATION MODE xxx.W,xxx.L,#<data>
    CMP.B   #1,TRUE         IF NONE ARE CALLED
    BNE     INVALID         BRANCH TO INVALID
    
    ADD.W   #0,(A6)+        INCREMENT THE POINTER
    BRA     DONE            BRANCH TO DONE. OPCODE FINISHED

    MOVE.B  #$34,SOURCEREG      

*------------------------------------------------------------
*ANDDECODE
*USED TO DECODE AND FUNCTION
*SHOULD ALREADY HAVE OPMODE IN D6
*FROM CHECKING IF MULS OR AND 
*USE OPMODE TO DETERMINE IF BYTE,WORD,LONG 
*THEN USE OPMODE TO DETERMINE <EA>,DN |OR| DN,<EA>
*------------------------------------------------------------
ANDDECODE
    
    LEA     ANDMSG,A1       PRINT AND
    JSR     PRINTLINE
    
    MOVE.B  D7,D1           INVALID EFFECTIVE ADDRESSES
    MOVE.B  #3,D2
    MOVE.B  #3,D3
    JSR     BITMASK
    CMP.B   #1,D0           AN
    BEQ     INVALID
    
    JSR EAORDEST            JUMP TO SUBROUTINE THAT HANDLES BOTH LAYOUTS
    ADD.W   #0,(A6)+        INCREMENT THE POINTER
    BRA DONE                BRANCH TO DONE. OPCODE FINISHED
PRINTANDI
    LEA     ANDIMSG,A1      PRINT ANDI
    JSR     PRINTLINE
    RTS
PRINTEORI
    LEA     EORIMSG,A1      PRINT EORI
    JSR     PRINTLINE
    RTS
PRINTCMPI
    LEA     CMPIMSG,A1      PRINT CMP1
    JSR     PRINTLINE
    RTS
PRINTSUBI
    LEA     SUBIMSG,A1      PRINT SUBI
    JSR     PRINTLINE
    RTS
    
*------------------------------------------------------------
*PRINTXXXI
*USED TO PRINT ALL IMMEDIATE (ADDI,EORI,CMPI,SUBI) FUNCTIONS
*------------------------------------------------------------    
PRINTXXXI                   
    CMP.B   #$02,D0         Print ANDI
    BEQ     PRINTANDI
    CMP.B   #$0A,D0         Print EORI
    BEQ     PRINTEORI       
    CMP.B   #$0C,D0         Print CMPI
    BEQ     PRINTCMPI
    CMP.B   #$04,D0         Print SUBI
    BEQ     PRINTSUBI
    BRA     INVALID         Branch to invalid
    
*------------------------------------------------------------
*XXXIDECODE   
*USED FOR ALL IMMEDIATE DATA FUNCTION TYPES(ADDI,EORI,CMPI,SUBI)
*------------------------------------------------------------      
XXXIDECODE                  
    JSR     PRINTXXXI       PRINT THE ACTUAL FUNCTION
        
    MOVE.L  D7,D1           RETRIEVE SIZE OF OPERATION
    MOVE.L  #6,D2           START MASK AT BIT 6
    MOVE.L  #2,D3           SELECT 2 BITS TO MASK
    JSR     BITMASK         RUN BITMASKER
    MOVE.L  D0,D4           STORE MASKED BITS AT D4
    
    JSR     PRINTSIZE2BITS  PRINT EITHER .B/.W/.L BASED OFF SIZE STORED IN D4
    
    LEA     COMMA,A1        PRINT A COMMA
    JSR     PRINTLINE
    
    MOVE.L  D7,D1           RETRIEVE EA MODE
    MOVE.L  #3,D2           START MASK AT BIT 3
    MOVE.L  #3,D3           SELECT 3 BITS TO MASK
    JSR     BITMASK         RUN BITMASKER
    LEA     SOURCEMODE,A2   STORE MASKED BITS AT SOURCEMODE
    MOVE.B  D0,(A2)          
    MOVE.L  D0,D6           MOVE MASKED BITS TO D6
    
    MOVE.L  D7,D1           RETRIEVE EA REG
    MOVE.L  #0,D2           START MASK AT BIT 0
    MOVE.L  #3,D3           SELECT 3 BITS TO MASK
    JSR     BITMASK         RUN BITMASKER
    LEA     SOURCEREG,A2    STORE MASKED BITS IN SOURCEREG
    MOVE.B  D0,(A2)     
    MOVE.L  D0,D5           MOVE MASKED BITS TO D5
        
    CMP.B   #%100,D6        TO AVOID IMMEDIATE DATA AS EA MODE
    BEQ     INVALID         Branch to invalid

    JSR     CHECKDN         CHECK MODE Dn
    JSR     CHECKANPAREN    CHECK MODE (An)
    JSR     CHECKANPLUS     CHECK MODE (An)+
    JSR     CHECKMINUSAN    CHECK MODE -(An)
    JSR     CHECKIMMEDIATE  CHECK MODE xxx.W,xxx.L,#<data>
    CMP.B   #1,TRUE         IF NONE ARE CALLED
    BNE     INVALID         INVALID MODE CALLED
        
    BRA     DONE            BRANCH TO DONE. OPCODE FINISHED
    
*------------------------------------------------------------
*PRINTSIZE2BITS
*Will print a ".B",".W",".L"
*------------------------------------------------------------    
PRINTSIZE2BITS
    ADD.W   #0,(A6)+        Increment pointer
    CMP.B   #%00,D4         Compare size to %00
    BEQ     PRINTB          Branch to PRINTB if equal
    CMP.B   #%01,D4         Compare size to %01
    BEQ     PRINTW          Branch to PRINTW if equal
    CMP.B   #%10,D4         Compare size to %10    
    BEQ     PRINTL          Branch to PRINTL if equal
    BRA     INVALID         Branch to invalid, size not found
    
*------------------------------------------------------------
*PRINTB
*Will print a ".B"
*------------------------------------------------------------     
PRINTB
    LEA     BYTEMSG,A1      Loads ".B" into A1
    JSR     PRINTLINE       Print A1
    LEA     POUND,A1        Loads "#" into A1
    JSR     PRINTLINE       Print A1
    LEA     DOLLA,A1        Loads "$" into A1
    JSR     PRINTLINE       Print A1
    MOVE.L  #4,D4           Move size into D4
    CLR     D1              Clear data register 1
    CLR     D2              Clear data register 2
    JSR     PRINTTOHEX      Print size
    ADDA.W  #$01,A3         
    RTS                     Return
    
*------------------------------------------------------------
*PRINTW
*Will print a ".W"
*------------------------------------------------------------
PRINTW
    LEA     WORDMSG,A1      Loads ".W" into A1
    JSR     PRINTLINE       Print A1
    LEA     POUND,A1        Loads "#" into A1
    JSR     PRINTLINE       Print A1
    LEA     DOLLA,A1        Loads "$" into A1
    JSR     PRINTLINE       Print A1
    MOVE.L  #4,D4           Move size into D4
    CLR     D1              Clear data register 1
    CLR     D2              Clear data register 2
    JSR     PRINTTOHEX      Print size
    ADDA.W  #$03,A3         
    RTS                     Return
    
*------------------------------------------------------------
*PRINTL
*Will print a ".L"
*------------------------------------------------------------
PRINTL
    LEA     LONGMSG,A1      Loads ".L" into A1
    JSR     PRINTLINE       Print A1
    LEA     POUND,A1        Load "#" into A1
    JSR     PRINTLINE       Print A1
    LEA     DOLLA,A1        Load "$" into A1
    JSR     PRINTLINE       Print A1
    MOVE.L  #8,D4           Move size into D4
    CLR     D1              Clear D1
    CLR     D2              Clear D2
    JSR     PRINTTOHEX      Print size
    ADDA.W  #$07,A3         
    RTS                     Return
    
*------------------------------------------------------------
*RTSDECODE
*Will print a "RTS"
*------------------------------------------------------------    
RTSDECODE
    LEA     RTSMSG,A1       Load "RTS" into A1
    JSR     PRINTLINE       Print A1
    ADD.W   #0,(A6)+        Increment pointer
    BRA     DONE            Return
    
*------------------------------------------------------------
*JSRDECODE
*Code to handle JSR
*------------------------------------------------------------    
JSRDECODE
    LEA     JSRMSG,A1       Load "JSR" into A1
    JSR     PRINTLINE       Print A1
    
    MOVE.L  D7,D1           RETRIEVE EA MODE
    MOVE.L  #3,D2           Start at the 3rd bit
    MOVE.L  #3,D3           Look at the next 3 bits (inclusive)
    JSR     BITMASK         Mask selected bits
    LEA     SOURCEMODE,A2   Load "SOURCEMODE" into A2
    MOVE.B  D0,(A2)         Move the masked bits into "SOURCEMODE"
    MOVE.B  D0,D6           Move the bits into D6
    
    MOVE.L  D7,D1           RETRIEVE EA REG
    MOVE.L  #0,D2           Start at the 0th bit
    MOVE.L  #3,D3           Look at the next 3 bits (inclusive)
    JSR     BITMASK         Mask selected bits
    LEA     SOURCEREG,A2    Load "SOURCEREG" into A2
    MOVE.B  D0,(A2)         Move the masked bits into "SOURCEREG"
    MOVE.B  D0,D5           Move the bits into D5
    
    LEA     SPACE,A1        Load " " into A1
    JSR     PRINTLINE       Print A1
    
    JSR     CHECKANPAREN    Check (An)    
    JSR     CHECKDATA       Check xxx.W,xxx.L,#<data>
    CMP.B   #1,TRUE         Check if True set
    BNE     INVALID         Not set, branch to invalid
    ADD.W   #0,(A6)+        Incrememnt counter
    BRA     DONE            Branch to done
    
*------------------------------------------------------------
*ISEA 
*Find out which effective address applies
*------------------------------------------------------------ 
ISEA
    MOVE.L  D7,D1           RETRIEVE SOURCE MODE
    MOVE.L  #3,D2           Start at the 3rd bit
    MOVE.L  #3,D3           Look at the next 3 bits (inclusive)
    JSR     BITMASK         Mask selected bits
    LEA     SOURCEMODE,A2   Load "SOURCEMODE" into A2
    MOVE.B  D0,(A2)         Move the masked bits into "SOURCEMODE"
    MOVE.B  D0,D6           Move the bits into D6
    
    MOVE.L  D7,D1           RETRIEVE EA REG
    MOVE.L  #0,D2           Start at the 0th bit
    MOVE.L  #3,D3           Look at the next 3 bits (inclusive)
    JSR     BITMASK         Mask selected bits
    LEA     SOURCEREG,A2    Load "SOURCEREG" into A2
    MOVE.B  D0,(A2)         Move the masked bits into "SOURCEREG"
    MOVE.B  D0,D5           Move the bits into D5
    
    JSR     CHECKDN         Check Dn
    JSR     CHECKAN         Check An
    JSR     CHECKANPAREN    Check (An)
    JSR     CHECKANPLUS     Check (An)+
    JSR     CHECKMINUSAN    Check -(An)
    JSR     CHECKDATA       Check xxx.W,xxx.L,#<data>
    CMP.B   #1,TRUE         Check if an EA was found
    BNE     INVALID         If not, Branch to invalid
    
    RTS                     Return
    
*------------------------------------------------------------
*ISDEST
*Find out which destination applies
*------------------------------------------------------------     
ISDEST    
    MOVE.L  D7,D1           RETRIEVE DESTINATION MODE
    MOVE.L  #6,D2           Start at the 6th bit    
    MOVE.L  #3,D3           Look at the next 3 bits (inlcusive)
    JSR     BITMASK         Mask the selected bits    
    LEA     DESTMODE,A2     Load "DESTMODE" into A2
    MOVE.B  D0,(A2)         Move the masked bits into "DESTMODE"
    MOVE.B  D0,D6           Move the bits into D6
        
    MOVE.L  D7,D1           RETRIEVE DESTINATION REG
    MOVE.L  #9,D2           Start at the 9th bit
    MOVE.L  #3,D3           Look at the next 3 bits (inclusive)
    JSR     BITMASK         Mask the selected bits
    LEA     DESTREG,A2      Load "DESTREG" into A2
    MOVE.B  D0,(A2)         Move the masked bits into "DESTMODE"
    MOVE.B  D0,D5           Move the bits into D5
    
    LEA     TXTD,A1         Load "D" into A1
    JSR     PRINTLINE       Print A1
    MOVE.L  D5,D1           PRINT OUT REGISTER
    ADD.B   #$30,D1         Convert to Ascii
    MOVE.B  #6,D0           Use trap task 6
    TRAP    #15
    RTS                     Return

*------------------------------------------------------------
*EAORDEST
*Determine which operation is being used
*[TYPE 1] CHECK <EA>,DN 
*[TYPE 2] CHECK DN,<EA> 
*------------------------------------------------------------      
EAORDEST
*BYTE SIZE
    CMP.B   #%000,D6        Operation [TYPE 1] CHECK <EA>,DN
    BEQ     BYTE1           
    CMP.B   #%100,D6        Operation [TYPE 2] CHECK DN,<EA> 
    BEQ     BYTE2           
*WORD SIZE
    CMP.B   #%001,D6        Operation [TYPE 1] CHECK <EA>,DN
    BEQ     WORD1
    CMP.B   #%101,D6        Operation [TYPE 2] CHECK DN,<EA> 
    BEQ     WORD2
*LONG SIZE
    CMP.B   #%010,D6        Operation [TYPE 1] CHECK <EA>,DN
    BEQ     LONG1
    CMP.B   #%110,D6        Operation [TYPE 2] CHECK DN,<EA> 
    BEQ     LONG2
    BRA     INVALID         Operation type not found, Invalid

*------------------------------------------------------------
*BYTE1
*Print  Operation [TYPE 1] CHECK <EA>,DN for a byte of data
*------------------------------------------------------------  
BYTE1       
    LEA     BYTEMSG,A1      Load ".B" into A1
    JSR     PRINTLINE       Print A1
    MOVE.B  #4,D4           Move the size to D4
    JSR     ISEA            Determine Effective Address
    LEA     COMMA,A1        Load "," into A1
    JSR     PRINTLINE       Print A1
    JSR     ISDEST          Determine Destination
    RTS                     Return
    
*------------------------------------------------------------
*BYTE2
*Print  Operation [TYPE 2] CHECK DN,<EA> for a byte of data
*------------------------------------------------------------      
BYTE2
    LEA     BYTEMSG,A1      Load ".B" into A1
    JSR     PRINTLINE       Print A1
    MOVE.B  #4,D4           Move the size to D4
    JSR     ISDEST          Determine Destination
    LEA     COMMA,A1        Load "," into A1
    JSR     PRINTLINE       Print A1
    JSR     ISEA            Determine Effective Address
    RTS                     Return
    
*------------------------------------------------------------
*WORD1
*Print  Operation [TYPE 1] CHECK <EA>,DN for a word of data
*------------------------------------------------------------      
WORD1
    LEA     WORDMSG,A1      Load ".W" into A1
    JSR     PRINTLINE       Print A1
    MOVE.B  #4,D4           Move the size to D4
    JSR     ISEA            Determine Effective Address
    LEA     COMMA,A1        Load "," into A1
    JSR     PRINTLINE       Print A1
    JSR     ISDEST          Determine Destination
    RTS                     Return
    
*------------------------------------------------------------
*WORD2
*Print  Operation [TYPE 2] CHECK DN,<EA> for a word of data
*------------------------------------------------------------     
WORD2
    LEA     WORDMSG,A1      Load ".W" into A1
    JSR     PRINTLINE       Print A1
    MOVE.B  #4,D4           Move the size to D4
    JSR     ISDEST          Determine Destination
    LEA     COMMA,A1        Load "," into A1
    JSR     PRINTLINE       Print A1
    JSR     ISEA            Determine Effective Address
    RTS                     Return
    
*------------------------------------------------------------
*LONG1
*Print  Operation [TYPE 1] CHECK <EA>,DN for a longword of data
*------------------------------------------------------------    
LONG1
    LEA     LONGMSG,A1      Load ".L" into A1
    JSR     PRINTLINE       Print A1
    MOVE.B  #8,D4           Move the size into D4
    JSR     ISEA            Determine Effective Address
    LEA     COMMA,A1        Load "," into A1
    JSR     PRINTLINE       Print A1
    JSR     ISDEST          Determine Destination
    RTS                     Return
    
*------------------------------------------------------------
*LONG2
*Print  Operation [TYPE 2] CHECK DN,<EA> for a longword of data
*------------------------------------------------------------     
LONG2
    LEA     LONGMSG,A1      Load ".L" into A1
    JSR     PRINTLINE       Print A1
    MOVE.B  #8,D4           Move the size into D4
    JSR     ISDEST          Determine Destinaiton
    LEA     COMMA,A1        Load "," into A1
    JSR     PRINTLINE       Print A1
    JSR     ISEA            Determine Effective Address
    RTS                     Return

*------------------------------------------------------------
*MULDECODE
*Decode for MUL operations
*------------------------------------------------------------  
MULDECODE
    LEA     MULSMSG,A1      Load "MULS" into A1
    JSR     PRINTLINE       Print A1
    LEA     WORDMSG,A1      Load ".W" into A1
    JSR     PRINTLINE       Print A1

    JSR     MULSANDDIVS     BRANCH TO DETERMINE REGISTER AND EA
    ADD.W   #0,(A6)+        Increment Pointer
    BRA     DONE            Branch to DONE

*------------------------------------------------------------
*PRINTDATAREG
*Print data registers
*------------------------------------------------------------      
PRINTDATAREG
    MOVE.L  D7,D1           RETRIEVE DATA REGISTER
    MOVE.L  #9,D2           Start at the 9th bit             
    MOVE.L  #3,D3           Look at the next 3 bits (inclusive)
    JSR     BITMASK         Mask the selected bits
    LEA     SOURCEMODE,A2   Load "SOURCEMODE" into A2
    MOVE.B  D0,(A2)         Move the masked bits into "SOURCEMODE"
    MOVE.B  D0,D6           Move the bits to D6

    LEA     TXTD,A1         Load "D" into A1
    JSR     PRINTLINE       Print A1
    MOVE.L  D6,D1           PRINT OUT REGISTER
    ADD.B   #$30,D1
    MOVE.B  #6,D0
    TRAP    #15
    RTS                     Return
    
*------------------------------------------------------------
*PRINTADDREG
*Print address registers
*------------------------------------------------------------
PRINTADDREG
    MOVE.L  D7,D1           RETRIEVE DATA REGISTER
    MOVE.L  #9,D2           Start at the 9th bit
    MOVE.L  #3,D3           Look at the next 3 bits (inclusive)
    JSR     BITMASK         Mask the selected bits
    LEA     SOURCEMODE,A2   Load "SOURCEMODE" into A2
    MOVE.B  D0,(A2)         Move the masked bits into "SOURCEMODE"
    MOVE.B  D0,D6           Move the bits to D6

    LEA     TXTA,A1         Load "A" into A1
    JSR     PRINTLINE       Print A1
    MOVE.L  D6,D1           PRINT OUT REGISTER
    ADD.B   #$30,D1
    MOVE.B  #6,D0
    TRAP    #15
    RTS                     Return

*-----------------------------------------------------------
*PRINTSIZE
*DETERMINE SIZE BASED OFF OF D4 AND PRINT SIZE APPROPRIATELY
*-----------------------------------------------------------
PRINTSIZE
    CMP.B   #%00,D4         Compare size to 00
    BEQ     PRINTBYTE       If equal print ".B"
    CMP.B   #%01,D4         Compare size to 01
    BEQ     PRINTWORD       If equal print ".W"
    CMP.B   #%10,D4         Compare size to 10
    BEQ     PRINTLONG       If equal print ".L"    
    RTS                     Return
        
*-----------------------------------------------------------
*PRINTBYTE
*Print ".B"
*-----------------------------------------------------------
PRINTBYTE
    LEA     BYTEMSG,A1      Load ".B" into A1
    JSR     PRINTLINE       Print A1
    RTS                     Return
    
*-----------------------------------------------------------
*PRINTWORD
*Print ".W"
*-----------------------------------------------------------    
PRINTWORD
    LEA     WORDMSG,A1      Load ".W" int A1
    JSR     PRINTLINE       Print A1
    RTS                     Return
    
*-----------------------------------------------------------
*PRINTLONG                  
*Print ".L"                 
*-----------------------------------------------------------
PRINTLONG
    LEA     LONGMSG,A1      Load ".L" into A1     
    JSR     PRINTLINE       Print A1   
    RTS                     Return
    
*-----------------------------------------------------------
*PRINTBCHG                
*Print "BCHG"                 
*-----------------------------------------------------------    
PRINTBCHG
    LEA     BCHGMSG,A1      Load "BCHG" into A1
    JSR     PRINTLINE       Print A1
    RTS                     Return

*-----------------------------------------------------------
*PRINTBCHG                
*Handle Longword BCHG operations                 
*-----------------------------------------------------------      
BCHGL
    CMP.B   #%111,D6        ONLY DATA REGISTERS IF LONG
    BEQ     INVALID         Branch if equal to Invalid

    LEA     LONGMSG,A1      Load ".L" into A1
    JSR     PRINTLINE       Print A1
    LEA     POUND,A1        Load "#" into A1
    JSR     PRINTLINE       Print A1
    LEA     DOLLA,A1        Load "$" into A1
    JSR     PRINTLINE       Print A1
    MOVE.L  #4,D4           Move size to D4
    CLR     D1              Clear D1
    CLR     D2              Clear D2
    JSR     GETWORD         Move the pointer 1 word
    JSR     PRINTLOOP       Print data    
    RTS                     Return
    
*-----------------------------------------------------------
*BORLIMMEDIATE                
*Handle bytes of immediate data for BCHG operations
*Throws to BCHGL if Longword
*-----------------------------------------------------------          
BORLIMMEDIATE
    CMP.B   #%000,D6        Check to see if Long
    BEQ     BCHGL           Branch to BCHGL to handle longwords
    LEA     BYTEMSG,A1      Load ".B" into A1
    JSR     PRINTLINE       Print A1
    LEA     POUND,A1        Load "#" into A1
    JSR     PRINTLINE       Print A1
    LEA     DOLLA,A1        Load "$" into A1
    JSR     PRINTLINE       Print A1
    MOVE.L  #4,D4           Move size into D4
    CLR     D1              Clear D1
    CLR     D2              Clear D2
    JSR     GETWORD         Move the pointer 1 word
    JSR     PRINTLOOP       Print data
    RTS                     Return
    
*-----------------------------------------------------------
*BORLDN              
*Handle bytes of data for BCHG Dn operations
*-----------------------------------------------------------      
BORLDN
    CMP.B   #%000,D6        Check to see if long
    BEQ     BCHGLDN         Branch to BCHGLDN to handle longwords
    LEA     BYTEMSG,A1      Load ".B" into A1
    JSR     PRINTLINE       Print A1
    RTS                     Return
    
*-----------------------------------------------------------
*BCHGLDN             
*Handle longwords of data for BCHG Dn operations
*-----------------------------------------------------------      
BCHGLDN
    CMP.B   #%111,D6        Check to see if long
    BEQ     INVALID         Branch to invalid if not long
    LEA     LONGMSG,A1      Load ".L" into A1
    JSR     PRINTLINE       Print A1
    RTS                     Return
    
*-----------------------------------------------------------
*BCHGDECODE1             
*Prints the first half of BCHG Operations for Mode 1
*-----------------------------------------------------------    
BCHGDECODE1
    JSR PRINTBCHG           Print "BCHG"
    ADDA.W  #$02,A6         PREP TO PRINT IMMEDIATE DATA
    MOVEA.L A6,A3
    JSR     BORLIMMEDIATE   Print Data
    MOVEA.L A3,A6
    LEA     COMMA,A1        Load "," into A1
    JSR     PRINTLINE       Print A1

    MOVE.L  D7,D1           RETRIEVE EA MODE
    MOVE.L  #3,D2           Start at the 3rd bit
    MOVE.L  #3,D3           Look at the next 3 bits (inclusive)
    JSR     BITMASK         Mask selected bits
    LEA     SOURCEMODE,A2   Load "SOURCEMODE" into A2
    MOVE.B  D0,(A2)         Move selected bits into "SOURCEMODE"
    MOVE.L  D0,D6           Move bits to D6

*-----------------------------------------------------------
*BCHGHALF             
*Prints the second half of BCHG Operations
*-----------------------------------------------------------    
BCHGHALF       
    MOVE.L  D7,D1           RETRIEVE EA REG
    MOVE.L  #0,D2           Start at the 0th bit
    MOVE.L  #3,D3           Look at the next 3 bits (inclusive)
    JSR     BITMASK         Mask the selected bits
    LEA     SOURCEREG,A2    Load "SOURCEREG" into A2    
    MOVE.B  D0,(A2)         Move selected bits into "SOURCEREG"
    MOVE.L  D0,D5           Move bits to D5
    
    CMP.B   #%111,D6        AVOID IMMEDIATE DATA AS EA MODE
    BNE     BCHGBACK        Branch back to avoid invalid 
    JSR     NOTIMMDATA      Handle not immediate data
    
*-----------------------------------------------------------
*BCHGBACK            
*Handle BCHG paramaters that are not immediate data
*-----------------------------------------------------------     
BCHGBACK 
    JSR     CHECKDN         Check Dn
    JSR     CHECKANPAREN    Check (An)
    JSR     CHECKANPLUS     Check (An)+
    JSR     CHECKMINUSAN    Check -(An)
    JSR     CHECKDATA       Check xxx.W,xxx.L,#<data>
    CMP.B   #1,TRUE         Check if hit
    BNE     INVALID         If not, Invalid
    
    ADD.W   #0,(A6)+        Increment Pointer
    BRA     DONE            Branch to Done

*-----------------------------------------------------------
*NOTIMMDATA           
*Make sure immediate data is not used in this instance
*-----------------------------------------------------------
NOTIMMDATA
    CMP.B   #%100,D5        Check if immediate data
    BEQ     INVALID         If immediate data, Invalid
    RTS                     Return
    
*-----------------------------------------------------------
*BCHGDECODE2           
*Prints the first half of BCHG Operations for Mode 2
*-----------------------------------------------------------    
BCHGDECODE2
    JSR PRINTBCHG           Print BCHG
    MOVE.L  D7,D1           RETRIEVE EA MODE
    MOVE.L  #3,D2           Start at the 3rd bit
    MOVE.L  #3,D3           Look at the next 3 bits (inclusive)
    JSR     BITMASK         Mask selected bits
    LEA     SOURCEMODE,A2   Load "SOURCEMODE" into A2    
    MOVE.B  D0,(A2)         Move the masked bits into "SOURCEMODE"
    MOVE.L  D0,D6           Move bits to D6
    
    JSR     BORLDN          Determine if BYTE OR LONG
       
    MOVE.L  D7,D1           RETRIEVE DATA REGISTER OF BIT NUMBER
    MOVE.L  #9,D2           Start at the 9th bit    
    MOVE.L  #3,D3           Look at the next 3 bits    
    JSR     BITMASK         Mask selected bits
    LEA     SOURCEMODE,A2   Load "SOURCEMODE" into A2
    MOVE.B  D0,(A2)         Move the masked bits into "SOURCEMODE"
    MOVE.L  D0,D5           Move bits to D5
    
    MOVEM.L D6,-(SP)        Putting D6 on the stack
    MOVE.L  #0,D6           Increment pointer
    JSR     CHECKDN         Check if Dn
    MOVEM.L (SP)+,D6        Take D6 off of the stack
    
    LEA     COMMA,A1        Load "," into A1
    JSR     PRINTLINE       Print A1
    
    BRA     BCHGHALF        Branch to the second half of BCHG


*-----------------------------------------------------------
*BCHG/ANDI/EORI/CMPI/SUBI           
*OPCODE 0000
*-----------------------------------------------------------
OPC0000
    MOVE.L  D7,D1           RETRIEVE BITS 6-15
    MOVE.L  #6,D2           Start at the 6th bit
    MOVE.L  #9,D3           Look at the next 9 bits (inclusive)
    JSR     BITMASK         Mask the selected bits
    MOVE.L  D0,D1           D1 CONTAINS BITS IF BCHG
    
    CMP.L   #%000100001,D1  CASE WITH IMMEDIATE DATA AND NOT DN
    BEQ     BCHGDECODE1
    
    ANDI.B  #$7,D1          TO GET LEAST SIGN IF BITS 101 (CASE WITH DN)
    
    CMP.B   #%101,D1        COMPARE BITS 6-8
    BEQ     BCHGDECODE2     BRANCH TO BCHGDECODE
    
    MOVE.L  D7,D1           RETRIEVE BITS 8-15
    MOVE.L  #8,D2           Start at the 8th bit
    MOVE.L  #7,D3           Look at the next 7 bits (inclusive)
    JSR     BITMASK         Mask the selcted bits
                      
    BRA     XXXIDECODE      BRANCH TO XXXIDECODE
   
*-----------------------------------------------------------
*MOVE.B          
*OPCODE 0001
*-----------------------------------------------------------  
OPC0001
    LEA     MOVEMSG,A1      Load "Move" into A1
    JSR     PRINTLINE       Print A1
    LEA     BYTEMSG,A1      Load ".B" into A1
    JSR     PRINTLINE       Print A1
    MOVE.B  #4,D4           Move size into D4
    BRA     MOVEDECODE      DECODE MOVE
    
*-----------------------------------------------------------
*MOVE.L          
*OPCODE 0010
*----------------------------------------------------------- 
OPC0010
    LEA     MOVEMSG,A1      PRINT MOVE
    JSR     PRINTLINE
    LEA     LONGMSG,A1      PRINT SIZE
    JSR     PRINTLINE    
    MOVE.B  #8,D4
    BRA     MOVEDECODE      DECODE MOVE
    
*-----------------------------------------------------------
*MOVE.W         
*OPCODE 0011
*----------------------------------------------------------- 
OPC0011
    LEA     MOVEMSG,A1      PRINT MOVE
    JSR     PRINTLINE
    LEA     WORDMSG,A1      PRINT SIZE
    JSR     PRINTLINE    
    MOVE.B  #4,D4
    BRA     MOVEDECODE      DECODE MOVE

*-----------------------------------------------------------
*LEA/CLR/MOVEM/RTS/JSR          
*OPCODE 0100
*-----------------------------------------------------------     
OPC0100
    CMP.W #$4E75,D7         RTS COMPARE
    BEQ   RTSDECODE
    
    
    MOVE.L  D7,D1           JSR COMPARE
    MOVE.L  #6,D2           Start at the 6th bit
    MOVE.L  #9,D3           Look at the next 9 bits (inclusive)
    JSR     BITMASK         Mask selected bits
    CMP.W   #$13A,D0        Compare
    BEQ     JSRDECODE       Branch to JSR if equal
    
    
    MOVE.L  D7,D1           CLR COMPARE
    MOVE.L  #8,D2           Start at the 8th bit
    MOVE.L  #8,D3           Look at the next 8 bits
    JSR     BITMASK         Mask the selected bits
    CMP.W   #$42,D0         Compare
    BEQ     CLRDECODE       Branch to CLR if eqaul
    
    
    MOVE.B  D7,D1           LEA COMPARE
    MOVE.B  #8,D2           Start at the 8th bit
    MOVE.B  #1,D3           Look at it
    JSR     BITMASK         Mask selected bits
    CMP.B   #1,D0           Compare
    BEQ     LEADECODE       Branch to LEA if equal
    
           
    BRA     MOVEMDECODE     Branch to MOVEMCOMPARE    

*--------------------------------------------------------------
*MOVEM
*DETERMINES SIZE/DIRECTION/AND REGISTERS USED FOR FUNCTION
*--------------------------------------------------------------
MOVEMDECODE
    LEA     MOVEMMSG,A1     PRINT "MOVEM"
    JSR     PRINTLINE
    MOVE.B  D7,D1           DETERMINE SIZE
    MOVE.B  #6,D2           Start at the 6th bit
    MOVE.B  #1,D3           Look at it
    JSR     BITMASK         Mask the selected bit
    CMP.B   #0,D0           Compare for size
    BEQ     MOVEMW          Branch for word
    BRA     MOVEML          Branch for longword 

*--------------------------------------------------------------
*MOVECONTINUE
*Print Registers Used
*--------------------------------------------------------------    
MOVECONTINUE
    MOVE.B  D7,D1           DETERMINE DIRECTION
    MOVE.B  #10,D2          Start at the 10th bit
    MOVE.B  #1,D3           Look at it
    JSR     BITMASK         Mask the selected bit
    MOVE.B  D0,D4           STORE DIRECTION
    CMP.B   #1,D0           Compare for direction
    BEQ     REGFIRST        BRA PROPERLY TO PRINT CORRECTLY

    ADD.W   #0,(A6)+        INCREMENT "POINTER" TO MASKED BITS
    MOVE.W  (A6),D7
    JSR     PRINTMASKEDREGS BRA TO DETERMINE REGISTERS USED
    
    LEA     COMMA,A1        PRINT A COMMA
    JSR     PRINTLINE
    ADD.W   #0,-(A6)        MOVE THE "POINTER" BACK
    MOVE.W  (A6),D7
    JSR     MOVEMEA         DETERMINE EFFECTIVE ADDRESS
    
    JSR     CHECKANPAREN    Check if (An)
    JSR     CHECKMINUSAN    Check if -(An)
    JSR     CHECKNOTIMM     Check not immediate
    CMP.B   #1,TRUE         
    BNE     INVALID         If immediate branch to invalid
    
    ADD.L   #0,(A6)+        Increment pointer
    BRA     DONE            Branch to Done    

*--------------------------------------------------------------
*MOVEMEA
*Handle MOVEM Effective Addresses
*--------------------------------------------------------------    
MOVEMEA
    MOVE.L  D7,D1           RETRIEVE SOURCE MODE
    MOVE.L  #3,D2           Start at the 3rd bit
    MOVE.L  #3,D3           Look at the next 3 bits (inclusive)
    JSR     BITMASK         Mask the selected bits
    LEA     SOURCEMODE,A2   Load "SOURCEMODE" into A2    
    MOVE.B  D0,(A2)         Move the masked bits into "SOURCEMODE"
    MOVE.B  D0,D6           Move the bits to D6
    
    MOVE.L  D7,D1           RETRIEVE SOURCE REG
    MOVE.L  #0,D2           Start at the 0th bit
    MOVE.L  #3,D3           Look at the next 3 bits (inclusive)
    JSR     BITMASK         Mask the selected bits
    LEA     SOURCEREG,A2    Load "SOURCEREG" into A2    
    MOVE.B  D0,(A2)         Move the masked bits into "SOURCEREG"
    MOVE.B  D0,D5           Move the bits to D5
    RTS                     Return


*--------------------------------------------------------------
*REGFIRST
*PRINT REGISTERS
*--------------------------------------------------------------        
REGFIRST
    JSR     MOVEMEA         DETERMINE EFFECTIVE ADDRESS
    JSR     CHECKAN         Check if An
    JSR     CHECKANPLUS     Check if (An)+
    JSR     CHECKNOTIMM     Check if -(An)
    CMP.B   #1,TRUE         Check if true
    BNE     INVALID         Branch to invlid
    
    LEA     COMMA,A1        PRINT A COMMA
    JSR     PRINTLINE
    ADD.W   #0,(A6)+        INCREMENT "POINTER" TO MASKED BITS
    MOVE.W  (A6),D7
    JSR     PRINTMASKEDREGS BRA TO DETERMINE REGISTERS USED
    ADD.W   #0,(A6)+        Inrement pointer
    BRA     DONE            Branch to done

*--------------------------------------------------------------
*SETUP 1 & 2
*BASED ON DIRECTION, SETUP THE LOOPER CORRECTLY
*--------------------------------------------------------------   
SETUP
    CMP.B   #1,D4           Compare with direction
    BEQ     SETUP2          Branch to SETUP2
    MOVE.L  #15,D5          Do Setup 1
    RTS                     Return
SETUP2
    MOVE.L  #0,D5           Do Setup 2
    RTS                     Return

*--------------------------------------------------------------
*PRINTMASKEDREGS
*BASED ON DIRECTION, SETUP THE LOOPER CORRECTLY
*--------------------------------------------------------------     
PRINTMASKEDREGS
    LEA     ISFIRST,A2      Load boolean into A2
    CLR.L   D5              CLR D5 TO STORE LOOPCOUNT
    JSR     SETUP           Setup
    CLR.L   D6              D6 TO CONTAIN ASCII TO HEX ADDER
    MOVE.B  #48,D6      
    MOVE.B  #1,(A2)         Avoid fencepost dilemma
    
*--------------------------------------------------------------
*LOOPER
*Loops until instruction is finshed
*--------------------------------------------------------------     
LOOPER
    CMP.B   #0,D5           IF LOOP FINISHED DIRECTION1
    BLT     RETURN          If less than RTS 
    CMP.B   #15,D5          IF LOOP FINISHED DIRECTION2
    BGT     RETURN          If greater than RTS
    
BACK
    CMP.L   #7,D5           Compare D5 to 7
    BEQ     PRINTERSET      Set Printer if equal
    CMP.L   #8,D5           Comapre D5 to 8
    BEQ     PRINTERSET      Set Printer if equal
BACK2
    MOVE.L  D7,D1           
    MOVE.B  D5,D2           MASK THE BIT FOR THE CURRENT LOOP
    MOVE.B  #1,D3
    JSR     BITMASK
    CMP.B   #1,D0           CHECK TO SEE IF THIS REGISTER IS MASKED
    BEQ     PRINTER         BRA TO PRINTER IF SO
    JSR     INCDEC          INCREMENT OR DECREMENT PTR BASED ON DIRECTION
    ADD.B   #1,D6           INCREMENT ASCII ADDER
    BRA     LOOPER          KEEP LOOPING
    
PRINTER
    CMP.B   #1,D4           CHECK DIRECTION
    BEQ     REVERSE         PRINT REVERSE IF DIRECTION2
    CMP.B   #7,D5           IF DIRECTION1 AND GREATER THAN
    BGT     PRINTERD        PRINT DATA REGISTER 
                            *OTHERWISE PRINT ADD REGISTER
PRINTA
    LEA     SLASH,A1        Load " " into A1
    JSR     PRINTLINE       Print A1
    LEA     TXTA,A1         PRINT "A"
    JSR     PRINTLINE
    MOVE.B  D6,D1           PRINT CURRENT LOOP NUMBER
    MOVE.B  #6,D0
    TRAP    #15
    JSR     INCDEC          INCREMENT OR DECREMENT PTR BASED ON DIRECTION
    ADD.B   #1,D6           INCREMENT ASCII ADDER
    BRA     LOOPER          KEEP LOOPING
    
PRINTERSET
    CMP.B   #1,D4           Compare to #1
    BEQ     PRINTERSET2     Branch Printset2
    CMP.B   #7,D5           Compare to #7
    BNE     BACK2           Branch BACK2
    CLR.L   D6              Clear D6
    MOVE.B  #48,D6          RESET ASCII ADDER
    BRA     BACK2           Branch BACK2
    
PRINTERSET2
    CMP.B   #8,D5           Compare to #8
    BNE     BACK2           Branch BACK2
    CLR.L   D6              Clear d6
    MOVE.B  #48,D6          RESET ASCII ADDER
    BRA     BACK2           Branch BACK2
    
*--------------------------------------------------------------
*Reverse
*USED FOR DIRECTION2
*--------------------------------------------------------------     
REVERSE                 
    CMP.B   #7,D5           PRINT ADD REGISTER
    BGT     PRINTA          OTHERWISE PRINT DATA REGISTER
         
PRINTERD                
    CMP.B   #1,(A2)         Compare to #1
    BEQ     SKIPSLASH       Branch to SKIPSLASH
    LEA     SLASH,A1        PRINT SPACE
    JSR     PRINTLINE
SKIPSLASH
    LEA     TXTD,A1         PRINT D
    JSR     PRINTLINE
    MOVE.B  D6,D1           PRINT CURRENT LOOP NUMBER
    MOVE.B  #6,D0
    TRAP    #15
    JSR     INCDEC          INCREMENT OR DECREMENT PTR BASED ON DIRECTION
    ADD.B   #1,D6           
    MOVE.B  #0,(A2)
    BRA     LOOPER

INCDEC
    CMP.B   #1,D4           Compare to #1
    BEQ     INCDEC2         Branch INCDEC2
    SUB.B   #1,D5           Compare to #1
    RTS                     Return
INCDEC2
    ADD.B   #1,D5           
    RTS

MOVEMW
    LEA     WORDMSG,A1      Load ".W" A1
    JSR     PRINTLINE       Print A1
    BRA     MOVECONTINUE    Branch to MOVECONTINUE
    
MOVEML      
    LEA     LONGMSG,A1      Load ".L"
    JSR     PRINTLINE       Print A1
    BRA     MOVECONTINUE    Branch to MOVECONTINUE
    
CLRDECODE
    LEA     CLRMSG,A1       Load "CLR" into A1
    JSR     PRINTLINE       Print A1
    
    MOVE.B  D7,D1           Bitmask Prep
    MOVE.B  #6,D2           Start at the 6th bit
    MOVE.B  #2,D3           Look at the next 2 bits (inclusive)
    JSR     BITMASK         Mask the selected bits
    MOVE.B  D0,D4           Move the bits to D4
    JSR     PRINTSIZE       Print the size
    
    MOVE.L  D7,D1           RETRIEVE SOURCE MODE
    MOVE.L  #3,D2           Start at the 3rd bit
    MOVE.L  #3,D3           Look at the next 3 bits (inclusive)
    JSR     BITMASK         Mask the selected bits
    LEA     SOURCEMODE,A2   Load "SOURCEMODE" into A2
    MOVE.B  D0,(A2)         Move the masked bits into "SOURCEMODE"
    MOVE.B  D0,D6           Move the bits to D6
    
    CMP.B   #%001,D6        Compare check for invalid
    BEQ     INVALID
    
    MOVE.B  D7,D1           INVALID EFFECTIVE ADDRESSES
    MOVE.B  #3,D2           Start at the 3rd bit
    MOVE.B  #3,D3           Look at the next 3 bits (inclusive)
    JSR     BITMASK         Mask the selected bits
    CMP.B   #1,D0           CHECK AGAISNT An
    BEQ     INVALID         Invalid if An
    
    JSR     ALLEA           Jump to get effective addresses
    ADD.W   #0,(A6)+        Increment Pointer
    BRA     DONE            Branch to done
ALLEA
    MOVE.L  D7,D1           RETRIEVE SOURCE MODE
    MOVE.L  #3,D2           Start at the 3rd bit
    MOVE.L  #3,D3           Look at the next 3 bits (inclusive)
    JSR     BITMASK         Mask the selected bits
    LEA     SOURCEMODE,A2   Load "SOURCEMODE" into A2
    MOVE.B  D0,(A2)         Move the masked bits into "SOURCEMODE"
    MOVE.B  D0,D6           Move the bits to D6

    MOVE.L  D7,D1           RETRIEVE SOURCE REG
    MOVE.L  #0,D2           Start at the 0th bit
    MOVE.L  #3,D3           Look at the next 3 bits (inclusive)
    JSR     BITMASK         Mask the selected bits
    LEA     SOURCEMODE,A2   Load "SOURCEMODE" into A2
    MOVE.B  D0,(A2)         Move the masked bits into "SOURCEMODE"
    MOVE.B  D0,D5           Move the bits to D5
    
    JSR     CHECKDN         Check if Dn
    JSR     CHECKAN         Check if An
    JSR     CHECKANPAREN    Check if (An)
    JSR     CHECKANPLUS     Check if (An)+
    JSR     CHECKMINUSAN    Check if -(An)
    JSR     CHECKDATA       Check if xxx.W,xxx.L,#<data>
    CMP.B   #1,TRUE         Check if True
    BNE     INVALID         If false, branch invalid
        
    RTS                     Return

LEADECODE
    LEA     LEAMSG,A1       Load "LEA" into A1
    JSR     PRINTLINE       Print A1
    JSR     LEAEA           Jump to LEA EA subroutine
    JSR     CHECKANPAREN    Check if (An)
    JSR     CHECKNOTIMM     Check to makesure NOT immediate data
    CMP.B   #1,TRUE         Check if True
    BNE     INVALID         If false, branch invalid
    
    LEA     COMMA,A1        Load "," into A1
    JSR     PRINTLINE       Print A1
        
    JSR     PRINTADDREG     Print Address Register
    ADD.W   #0,(A6)+        Increment Pointer
    BRA     DONE            Branch to done

LEAEA
    MOVE.L  D7,D1           RETRIEVE SOURCE MODE
    MOVE.L  #3,D2           Start at the 3rd bit
    MOVE.L  #3,D3           Look at the next 3 bits (inclusive)
    JSR     BITMASK         Mask the selected bits
    LEA     SOURCEMODE,A2   Load "SOURCEMODE" into A2
    MOVE.B  D0,(A2)         Move the masked bits into "SOURCEMODE"
    MOVE.B  D0,D6           Move the bits to D6

    MOVE.L  D7,D1           RETRIEVE SOURCE REG
    MOVE.L  #0,D2           Start at the 0th bit
    MOVE.L  #3,D3           Look at the next 3 bits (inclusive)
    JSR     BITMASK         Mask the selected bits
    LEA     SOURCEMODE,A2   Load "SOURCEMODE" into A2
    MOVE.B  D0,(A2)         Move the masked bits into "SOURCEMODE"
    MOVE.B  D0,D5           Move the bits to D6
    RTS                     Return
    
*ADDQ
OPC0101
    LEA     ADDQMSG,A1      Load "ADDQ" into A1
    JSR     PRINTLINE       Print A1

    MOVE.B  D7,D1           
    MOVE.B  #9,D2           Start at the 9th bit
    MOVE.B  #3,D3           Look at the next 3 bits (inclusive)
    JSR     BITMASK         Mask the selected bits
    MOVE.B  D0,D5           Move the bits into D5
    CLR.L   D1              Clear D1
    CLR.L   D2              Clear D2
    LEA     POUND,A1        Load "#" into A1    
    JSR     PRINTLINE       Print A1
    LEA     DOLLA,A1        Load "$" into A1
    JSR     PRINTLINE       Print A1
    
    CMP.B   #0,D5           Compare masked bits to #0
    BEQ     PRINTEIGHT      Print as '8'    
    
    MOVE.B  #2,D4           Move size to D4
    JSR     PRINTLOOP       Print

EIGHTDONE    
    LEA     COMMA,A1        Load "," into A1
    JSR     PRINTLINE       Print A1
 
    JSR     ALLEA           Jumpe to Effective Addresses
    ADD.W   #0,(A6)+        Increment Count
    BRA     DONE            Branch to done

PRINTEIGHT
    LEA     EIGHT,A1        Load "8" into A1
    JSR     PRINTLINE       Print A1
    BRA     EIGHTDONE       Branch to EIGHTDONE

*BCC
OPC0110
    MOVE.L  D7,D1           RETRIEVE CONDITION
    MOVE.L  #8,D2           Start at the 8th bit
    MOVE.L  #4,D3           Look at the next 4 bits (inclusive)
    JSR     BITMASK         Mask the selected bits
*BCC(CARRY CLEAR)
    CMP.B   #%0100,D0       If masked bits match 
    BEQ     PRBCC
*BVS
    CMP.B   #%1001,D0       If masked bits match 
    BEQ     PRBVS
*BGT
    CMP.B   #%1110,D0       If masked bits match 
    BEQ     PRBGT
*BLE
    CMP.B   #%1111,D0       If masked bits match 
    BEQ     PRBLE
*INVALID
    BRA     INVALID         Invalid if reached
PRBCC
    LEA     BCCMSG,A1       PRINT MOVE
    JSR     PRINTLINE
    BRA     DECODEDISP      DECODE DISPLACEMENT
PRBGT
    LEA     BGTMSG,A1       PRINT MOVE
    JSR     PRINTLINE
    BRA     DECODEDISP      DECODE DISPLACEMENT
PRBVS   
    LEA     BVSMSG,A1       PRINT MOVE
    JSR     PRINTLINE
    BRA     DECODEDISP      DECODE DISPLACEMENT
PRBLE
    LEA     BLEMSG,A1       PRINT MOVE
    JSR     PRINTLINE 
    BRA     DECODEDISP      DECODE DISPLACEMENT
DECODEDISP
    LEA     SPACE,A1        PRINT A SPACE
    JSR     PRINTLINE
    LEA     DOLLA,A1
    JSR     PRINTLINE
    
    MOVE.L  D7,D1           RETRIEVE DISPLACEMENT
    MOVE.L  #0,D2           Start at the 0th bit
    MOVE.L  #8,D3           Look at the next 8 bits (inclusive)
    JSR     BITMASK         Mask the selected bits
    
    
    
    CMP.B   #$00,D0         Check if 16 bit displacement
    BEQ     BIT16DISP
    CMP.B   #$FF,D0         Check if 32 bit displacement
    BEQ     BIT32DISP   
    JSR     TWOSCOMP        DOESNT RETURN
    BRA     INVALID         SAFETY CATCH
BIT16DISP
    ADDA.W  #2,A6           GET NEXT 16 BITS SINCE 8BIT DISPLACEMENT IS $00
    MOVE.W  (A6),D0         STEP A6 PAST 16 BITS AND PLACE IN D0
    MOVE.L  D0,D1
    ROL.W   #1,D1           THE CARRY BIT WILL BE 1 FOR -,0 FOR +
    BCC     BIT16PLUS
    EORI.W  #$FFFF,D0       INVERSE THE NUMBER
    ADDI.W  #$01,D0         ADD 1, THIS IS THE DISTANCE TO MOVE
    BVS     BccERR          THERE WAS AN OVERFLOW
    MOVEA.L A6,A4           A4 WASNT USED SO I USED IT IDK WRITE A REAL COMMENT
    ADDA.W  #2,A6           STEP A6 TO WHERE PC SHOULD BE
    SUBA.L  D0,A6           AT THIS POINT A6 HAS THE ADDRESS TO BE PRINTED
    SUBA.L  #2,A6           OFF BY 2, THIS SHOULD FIX(NOT IDEAL FIX)
    MOVE.L  A6,D5           D5 IS FOR PRINTING
    MOVE.L  #4,D4           D4 IS THE SIZE FOR LOOPING IN PRINT
    JSR     PRINTLOOP
    MOVEA.L A4,A6           MOVE STARTING ADDRESS BACK TO A6
    ADDA.W  #2,A6           INCREMENT PAST INSTRUCTION TO NEXT INSTRUCTION
    BRA     DONE            Branch Done
BIT16PLUS
    MOVEA.L A6,A4           A4 WASNT USED SO I USED IT IDK WRITE A REAL COMMENT
    ADDA.L  D0,A6           AT THIS POINT A6 HAS THE ADDRESS TO BE PRINTED
    MOVE.L  A6,D5           D5 IS FOR PRINTING
    MOVE.L  #4,D4           D4 IS THE SIZE FOR LOOPING IN PRINT
    JSR     PRINTLOOP
    MOVEA.L A4,A6           MOVE STARTING ADDRESS BACK TO A6
    ADDA.W  #2,A6           INCREMENT PAST INSTRUCTION TO NEXT INSTRUCTION
    BRA     DONE            Branch DONE
BIT32DISP
    ADDA.W  #2,A6           GET NEXT 16 BITS SINCE 8BIT DISPLACEMENT IS $00
    MOVE.L  (A6),D0         STEP A6 PAST 16 BITS AND PLACE IN D0
    MOVE.L  D0,D1
    ROL.L   #1,D1           THE CARRY BIT WILL BE 1 FOR -,0 FOR +
    BCC     BIT32PLUS
    EORI.L  #$FFFFFFFF,D0   INVERSE THE NUMBER
    ADDI.L  #$01,D0         ADD 1, THIS IS THE DISTANCE TO MOVE
    BVS     BccERR          THERE WAS AN OVERFLOW
    MOVEA.L A6,A4           A4 WASNT USED SO I USED IT IDK WRITE A REAL COMMENT
    ADDA.W  #2,A6           STEP A6 TO WHERE PC SHOULD BE
    SUBA.L  D0,A6           AT THIS POINT A6 HAS THE ADDRESS TO BE PRINTED
    SUBA.L  #2,A6           OFF BY 2, THIS SHOULD FIX(NOT IDEAL FIX)
    MOVE.L  A6,D5           D5 IS FOR PRINTING
    MOVE.L  #8,D4           D4 IS THE SIZE FOR LOOPING IN PRINT
    JSR     PRINTLOOP
    MOVEA.L A4,A6           MOVE STARTING ADDRESS BACK TO A6
    ADDA.W  #4,A6           INCREMENT PAST INSTRUCTION TO NEXT INSTRUCTION
    BRA     DONE            Branch DONE
BIT32PLUS
    MOVEA.L A6,A4           A4 WASNT USED SO I USED IT IDK WRITE A REAL COMMENT
    ADDA.L  D0,A6           AT THIS POINT A6 HAS THE ADDRESS TO BE PRINTED
    MOVE.L  A6,D5           D5 IS FOR PRINTING
    MOVE.L  #8,D4           D4 IS THE SIZE FOR LOOPING IN PRINT
    JSR     PRINTLOOP
    MOVEA.L A4,A6           MOVE STARTING ADDRESS BACK TO A6
    ADDA.W  #4,A6           INCREMENT PAST INSTRUCTION TO NEXT INSTRUCTION
    BRA     DONE   
TWOSCOMP
    MOVE.L  D0,D1
    ROL.B   #1,D1           THE CARRY BIT WILL BE 1 FOR -,0 FOR +
    EORI.B  #$FF,D0         INVERSE THE NUMBER
    ADDI.B  #$01,D0         ADD 1, THIS IS THE DISTANCE TO MOVE
    BVS     BccERR          THERE WAS AN OVERFLOW
    MOVEA.L A6,A4           A4 WASNT USED SO I USED IT IDK WRITE A REAL COMMENT
    ADDA.W  #2,A6           STEP A6 TO WHERE PC SHOULD BE
    SUBA.L  D0,A6           AT THIS POINT A6 HAS THE ADDRESS TO BE PRINTED
    MOVE.L  A6,D5           D5 IS FOR PRINTING
    MOVE.L  #4,D4           D4 IS THE SIZE FOR LOOPING IN PRINT
    JSR     PRINTLOOP
    MOVEA.L A4,A6           MOVE STARTING ADDRESS BACK TO A6
    ADDA.W  #2,A6           INCREMENT PAST INSTRUCTION TO NEXT INSTRUCTION
    BRA     DONE
    
*FANCY OVERFLOW ERROR*
BccERR
    MOVE.L  #'OVER',A1      Print "OVER"
    MOVE.B  #14,D0
    TRAP    #15
    MOVE.L  #'FLOW',A1      Print "FLOW"
    MOVE.B  #13,D0
    TRAP    #15
    BRA     INVALID         Branch invalid

*MOVEQ
OPC0111
    LEA     MOVEQMSG,A1     Load "MOVEQ" into A1
    JSR     PRINTLINE       Print A1
    ADD.B   #0,(A6)+        Increment pointer
    MOVE.B  #4,D4           Move size into D4
    
    MOVE.B  D7,D1           Bitmask
    MOVE.B  #0,D2           Start at the 0th bit
    MOVE.B  #8,D3           Look at the next 8 bits (inclusive)
    JSR     BITMASK         Mask the selected bits
    MOVE.B  D0,D5           Move the bits to D5
    CLR.L   D1              Clear D1
    CLR.L   D2              Clear D2
    LEA     POUND,A1        Load "#" into A1
    JSR     PRINTLINE       Print A1
    LEA     DOLLA,A1        Load "$" into A1
    JSR     PRINTLINE       Print A1
    
    MOVE.B  #2,D4           Move the size to D4
    JSR     PRINTTOHEX      Print to Hex
  
    LEA     COMMA,A1        Load "," into A1
    JSR     PRINTLINE       Print A1
    
    JSR     PRINTDATAREG    Print Data Reg
    BRA     DONE            Branch to Done    
    

*DIVS
OPC1000
    LEA     DIVSMSG,A1      Load "DIVS" into A1
    JSR     PRINTLINE       Print A1
    LEA     WORDMSG,A1      Load ".W" into A1
    JSR     PRINTLINE       Print A1
    JSR     MULSANDDIVS     Print MULS and DIVS
    ADD.W   #0,(A6)+        Increment pointer
    BRA     DONE            Branch to Done

MULSANDDIVS
    MOVE.L  D7,D1           RETRIEVE EA MODE
    MOVE.L  #3,D2           Start at the 3rd bit
    MOVE.L  #3,D3           Look at the next 3 bits (inclusive)
    JSR     BITMASK         Mask the selected bits
    LEA     SOURCEMODE,A2   Load "SOURCEMODE" into A2
    MOVE.B  D0,(A2)         Move the masked bits into "SOURCEMODE"
    MOVE.B  D0,D6           Move the bits into D6

    MOVE.L  D7,D1           RETRIEVE EA REG
    MOVE.L  #0,D2           Start at the 0th bit
    MOVE.L  #3,D3           Look at the next 3 bits (inclusive)
    JSR     BITMASK         Mask the selected bits
    LEA     SOURCEREG,A2    Load "SOURCEREG" into A2    
    MOVE.B  D0,(A2)         Move the masked bits into "SOURCEREG"
    MOVE.B  D0,D5           Move the bits into D5
    
    *CHECK MODES
    JSR     CHECKDN         Check if Dn
    JSR     CHECKANPAREN    Check if (An)
    JSR     CHECKANPLUS     Check if (An)+
    JSR     CHECKMINUSAN    Check if -(An)
    JSR     CHECKDATA       xxx.W,xxx.L,#<data>
    CMP.B   #1,TRUE         Check if True
    BNE     INVALID         If not, branch invalid

    LEA     COMMA,A1        Print ","
    JSR     PRINTLINE
    
    JSR     PRINTDATAREG    Print Data Registers
    
    RTS                     Return
    
*SUB/SUBA
OPC1001

    MOVE.L  D7,D1           DETERMINE SUB VS SUBA
    MOVE.L  #6,D2           Start at the 6th bit
    MOVE.L  #2,D3           Look at the next 2 bits (inclusive)
    JSR     BITMASK         Mask the selected bits
    
    CMP.B   #%11,D0         BRANCH APPROPRIATELY
    BEQ     SUBA
    MOVE.B  D0,D4           D4 CONTAINS SIZE INFO
    
    
    LEA     SUBMSG,A1       Load "SUB" into A1
    JSR     PRINTLINE       Print A1
        
    MOVE.B  D7,D1           BITMASK
    MOVE.B  #6,D2           Start at the 6th bit
    MOVE.B  #3,D3           Look at the next 3 bits (inclusive)
    JSR     BITMASK         Mask the selected bits
    MOVE.B  D0,D6           Move the bits to D6
    
    JSR     EAORDEST        Jump to EAORDEST
    ADD.W   #0,(A6)+        Increment Counter
    BRA     DONE            Done
    
SUBA
    LEA     SUBAMSG,A1      Load "SUBA" into A1
    JSR     PRINTLINE       Print A1
        
    MOVE.B  D7,D1           BITMASK
    MOVE.B  #7,D2           Start at the 7th bit
    MOVE.B  #2,D3           Look at the next 2 bits (inclusive)
    JSR     BITMASK         Mask the selected bits
    CMP.B   #$1,D0          Compare for word or long
    BEQ     SUBAW           Word
    BRA     SUBAL           Long
    
SUBAPRINT    
    JSR     ALLEA           Jump to effective addresses
    
    LEA     COMMA,A1        Print ","
    JSR     PRINTLINE
    
    JSR     PRINTADDREG     Print data register
    ADD.W   #0,(A6)+        Increment Counter
    BRA     DONE            Done

SUBAW
    MOVE.B  #1,D4           
    JSR     PRINTSIZE       Print Size
    BRA     SUBAPRINT       Print SUBA
    
SUBAL
    MOVE.B  #2,D4
    JSR     PRINTSIZE       Print Size
    BRA     SUBAPRINT       Print SUBA
    
*EOR/CMP/CMPA
OPC1011
    MOVE.L  D7,D1           RETRIEVE OPMODE MODE
    MOVE.L  #6,D2           Start at the 6th bit  
    MOVE.L  #3,D3           Look at the next 3 bits (inclusive)
    JSR     BITMASK         Mask the selected bits
    LEA     SOURCEMODE,A2   Load "SOURCEMODE" into A2
    MOVE.B  D0,(A2)         Move the bits into "SOURCEMODE"
    MOVE.B  D0,D6           Move the bits into D6
    
    JSR     ISCMPEORCMPA    Determine between CMPE or CMPA
    JSR     EAORDEST        Determine EA or Destination
    ADD.W   #0,(A6)+        Increment pointer
    BRA     DONE            Done

ISCMPEORCMPA
*BYTE SIZE
    CMP.B   #%000,D6        CMP
    BEQ     CMPPRINT
    CMP.B   #%100,D6        EOR
    BEQ     EORPRINT
*WORD SIZE
    CMP.B   #%001,D6        CMP
    BEQ     CMPPRINT
    CMP.B   #%101,D6        EOR
    BEQ     EORPRINT
    CMP.B   #%011,D6        CMPA
    BEQ     CMPAPRINT
*LONG SIZE
    CMP.B   #%010,D6        CMP
    BEQ     CMPPRINT
    CMP.B   #%110,D6        EOR
    BEQ     EORPRINT
    CMP.B   #%111,D6        CMPA
    BEQ     CMPAPRINT
    BRA     INVALID  
       
CMPPRINT
    LEA     CMPMSG,A1       Load "CMP" into A1
    JSR     PRINTLINE       Print A1
    RTS                     Return
    
EORPRINT
    LEA     EORMSG,A1       Load "EOR" into A1
    JSR     PRINTLINE       Print A1
    
    MOVE.B  D7,D1           INVALID EFFECTIVE ADDRESSES
    MOVE.B  #3,D2           Start at the 3rd bit
    MOVE.B  #3,D3           Look at the next 3 bits (inclusive)
    JSR     BITMASK         Mask the selected bits
    CMP.B   #1,D0           An
    BEQ     INVALID
    RTS                     Return
    
CMPAPRINT
    LEA     CMPAMSG,A1      Load "CMPA" into A1
    JSR     PRINTLINE       Print A1
    JSR     EAORAN          Determine EA or An
    ADD.W   #0,(A6)+        Increment Pointer
    BRA     DONE            Done
    
******MAY NEED TO MERGE THIS WITH EAORDEST*************************************
EAORAN
*STRUCTURE:
    *CHECK <EA>,AN TYPE(1)
    *BRANCH IF EQUAL
    *CHECK AN,<EA> TYPE(2)
    *BRANCH IF EQUAL
*BYTE SIZE***********NO BYTE CASES KNOWN YET********
*    CMP.B   #%000,D6
*    BEQ     BYTE1
*    CMP.B   #%100,D6
*    BEQ     BYTE2
****************************************************
*WORD SIZE
    CMP.B   #%011,D6
    BEQ     WORD3
*    CMP.B   #%101,D6
*    BEQ     WORD2
*LONG SIZE
    CMP.B   #%111,D6
    BEQ     LONG3
*    CMP.B   #%110,D6
*    BEQ     LONG2
    BRA     INVALID         Invalid
WORD3
    LEA     WORDMSG,A1      PRINT SIZE
    JSR     PRINTLINE    
    MOVE.B  #4,D4
    JSR     ISEA
    LEA     COMMA,A1        Print Comma
    JSR     PRINTLINE
    JSR     ISAN            Determine is An
    RTS                     Return
LONG3    
    LEA     LONGMSG,A1      PRINT SIZE
    JSR     PRINTLINE    
    MOVE.B  #4,D4
    JSR     ISEA            Determine if EA
    LEA     COMMA,A1        THIS IS FOR COMMAS
    JSR     PRINTLINE
    JSR     ISAN            Determine if An
    RTS
ISAN
    MOVE.L  D7,D1           RETRIEVE DESTINATION MODE
    MOVE.L  #6,D2           Start at the 6th bit
    MOVE.L  #3,D3           Look at the next 3 bits (inclusive)
    JSR     BITMASK         Mask the selected bits
    LEA     DESTMODE,A2     Load "DESTMODE" into A2
    MOVE.B  D0,(A2)         Move the masked bits into "DESTMODE"
    MOVE.B  D0,D6           Move the bits into D6
        
    MOVE.L  D7,D1           RETRIEVE DESTINATION REG
    MOVE.L  #9,D2           Start at the 9th bit
    MOVE.L  #3,D3           Look at the next 3 bits (inclusive)
    JSR     BITMASK         Mask the selected bits
    LEA     DESTREG,A2      Load "DESTREG" into A2
    MOVE.B  D0,(A2)         Move the masked bits into "DESTREG"
    MOVE.B  D0,D5           Move the bits into D5
    
    *****ADDRESS REGISTER PRINT.CHECK TO SEE IF CAN MERGE WITH ISDEST***********
    LEA     TXTA,A1         Print "A"
    JSR     PRINTLINE
    MOVE.L  D5,D1           PRINT OUT REGISTER
    ADD.B   #$30,D1
    MOVE.B  #6,D0
    TRAP    #15
    RTS                     Return

*MULS/AND
OPC1100
    MOVE.L  D7,D1           RETRIEVE SOURCE MODE
    MOVE.L  #6,D2           Start at the 6th bit
    MOVE.L  #3,D3           Look at the next 3 bits (inclusive)
    JSR     BITMASK         Mask the selected bits
    LEA     SOURCEMODE,A2   Load "SOURCEMODE" into A2
    MOVE.B  D0,(A2)         Move the masked bits into "SOURCEMODE"
    MOVE.B  D0,D6           Move the bits into D6
    
    CMP.B   #%111,D6        IF EQUAL MULS, ELSE AND
    BEQ     MULDECODE       
    BNE     ANDDECODE
    
*ADD/ADDA
OPC1101
    MOVE.B  D7,D1           BITMASK
    MOVE.B  #6,D2           Start at the 6th bit
    MOVE.B  #2,D3           Look at the next 2 bits (inclusive)
    JSR     BITMASK         Mask the selected bits
    
    CMP.B   #%11,D0         Check if ADDA
    BEQ     ADDA
    
    LEA     ADDMSG,A1       Print "ADD"
    JSR     PRINTLINE
    
    MOVE.B  D7,D1           BITMASK
    MOVE.B  #6,D2           Start at the 6th bit
    MOVE.B  #3,D3           Look at the next 3 bits (inclusive)
    JSR     BITMASK         Mask the selected bits
    MOVE.B  D0,D6           Move the bits into D6
        
    JSR     EAORDEST        Determine EA or DEST
    ADD.W   #0,(A6)+        Increment pointer
    BRA     DONE            Done
    
ADDA
    LEA     ADDAMSG,A1      Print "ADD"
    JSR     PRINTLINE   
        
    MOVE.B  D7,D1           BITMASK
    MOVE.B  #7,D2           Start at the 7th bit
    MOVE.B  #2,D3           Look at the next 2 bits (inclusive)
    JSR     BITMASK         Mask the selected bits
    CMP.B   #$1,D0          Determine W or L
    BEQ     ADDAW           ADDA WORD
    BRA     ADDAL           ADDA LONG
    
ADDAPRINT    
    JSR     ALLEA           Jump to Effective Addresses
    
    LEA     COMMA,A1        Print Comma
    JSR     PRINTLINE
    
    JSR     PRINTADDREG     Print Address Register
    ADD.W   #0,(A6)+        Increment pointer
    BRA     DONE            Done

ADDAW
    MOVE.B  #1,D4           Print ".W"
    JSR     PRINTSIZE
    BRA     ADDAPRINT
    
ADDAL
    MOVE.B  #2,D4           Print ".L"
    JSR     PRINTSIZE
    BRA     ADDAPRINT

*LSL/LSR/ASL/ASR/ROL/ROR
OPC1110
    MOVE.L  D7,D1           RETRIEVE SIZE
    MOVE.L  #6,D2           Start at the 6th bit
    MOVE.L  #2,D3           Look at the next 2 bits (inclusive)
    JSR     BITMASK         Mask the selected bits
    CMP.B   #%11,D0         Determine if a memory shift or register shift
    BEQ     MEMORYSHIFTS    Memory Shift
    BRA     REGISTERSHIFTS  Register Shift   

MEMORYSHIFTS
    MOVE.L  D7,D1           DETERMINE ARITHMETIC, LOGIC, OR ROTATE 
    MOVE.L  #9,D2           START BIT MASK AT BIT 9
    MOVE.L  #3,D3           SELECT 3 BITS TO MASK
    JSR     BITMASK         RUN BITMASKER

    CMP.B   #0,D0           Arithmetic Memory Shift    
    BEQ     MEMARITHMETIC
    CMP.B   #%001,D0
    BEQ     MEMLOGIC        Logical Memory Shift
    CMP.B   #%011,D0
    BEQ     MEMROTATES      Rotation Memory Shift
    BRA     INVALID         Invalid
    
MEMARITHMETIC
    MOVE.L  D7,D1           RETRIEVE DIRECTION FIELD
    MOVE.L  #8,D2           Start at the 8th bit
    MOVE.L  #1,D3           Look at it
    JSR     BITMASK         Mask the selected bit
    
    CMP.B   #0,D0           Memory ASR
    BEQ     MEMASR
    CMP.B   #1,D0
    BEQ     MEMASL          Memory ASL
    BRA     INVALID         Invalid
MEMLOGIC
    MOVE.L  D7,D1           RETRIEVE DIRECTION FIELD
    MOVE.L  #8,D2           START BIT MASK AT BIT 8
    MOVE.L  #1,D3           SELCT 1 BIT TO MASK
    JSR     BITMASK         RUN BITMASKER
    
    CMP.B   #0,D0           Memory LSR
    BEQ     MEMLSR              
    CMP.B   #1,D0
    BEQ     MEMLSL          Memory LSL
    BRA     INVALID         Invalid
MEMROTATES
    MOVE.L  D7,D1           RETRIEVE DIRECTION FIELD
    MOVE.L  #8,D2           Start at the 8th bit
    MOVE.L  #1,D3           Look at it
    JSR     BITMASK         Mask the selected bit
    
    CMP.B   #0,D0           Memory ROR
    BEQ     MEMROR
    CMP.B   #1,D0           Memory ROL
    BEQ     MEMROL
    BRA     INVALID         Invalid
REGISTERSHIFTS    
    MOVE.L  D7,D1           DETERMINE ARITHMETIC, LOGIC, OR ROTATE 
    MOVE.L  #3,D2           Start at the 3rd bit
    MOVE.L  #2,D3           Look at the next 2 bits (inclusive)
    JSR     BITMASK         Mask the selected bits

    CMP.B   #00,D0          Arithmetic Register Shift
    BEQ     REGARITHMETIC
    CMP.B   #01,D0
    BEQ     REGLOGIC        Logical Register Shift
    CMP.B   #%11,D0
    BEQ     REGROTATES      Rotation Register Shift
    BRA     INVALID         Invalid
    
REGLOGIC
    MOVE.L  D7,D1           RETRIEVE DIRECTION FIELD
    MOVE.L  #8,D2           Start at the 8th bit
    MOVE.L  #1,D3           Look at it
    JSR     BITMASK         Mask the selected bits
    
    CMP.B   #0,D0           Register LSR
    BEQ     LSR
    CMP.B   #1,D0           Register LSL
    BEQ     LSL
    BRA     INVALID         Invalid
    
REGARITHMETIC
    MOVE.L  D7,D1           RETRIEVE DIRECTION FIELD
    MOVE.L  #8,D2           Start at the 8th bit
    MOVE.L  #1,D3           Look at it
    JSR     BITMASK         Mask the selected bits
    
    CMP.B   #0,D0           Register ASR
    BEQ     ASR
    CMP.B   #1,D0           Register ASL
    BEQ     ASL
    BRA     INVALID         Invalid
    
REGROTATES
    MOVE.L  D7,D1           RETRIEVE DIRECTION FIELD
    MOVE.L  #8,D2           Start at the 8th bit
    MOVE.L  #1,D3           Look at it
    JSR     BITMASK         Mask the selected bit
    
    CMP.B   #0,D0           Register ROR
    BEQ     ROR
    CMP.B   #1,D0           Register ROL
    BEQ     ROL
    BRA     INVALID         Invalid
    
MEMLSR
    LEA     LSRMSG,A1       PRINT LSR
    JSR     PRINTLINE
    BRA     MEMSHIFTS
MEMLSL
    LEA     LSLMSG,A1       PRINT LSL
    JSR     PRINTLINE
    BRA     MEMSHIFTS
MEMASR
    LEA     ASRMSG,A1       PRINT ASR
    JSR     PRINTLINE
    BRA     MEMSHIFTS
MEMASL
    LEA     ASLMSG,A1       PRINT ASL
    JSR     PRINTLINE
    BRA     MEMSHIFTS
MEMROR
    LEA     RORMSG,A1       PRINT ROR
    JSR     PRINTLINE
    BRA     MEMSHIFTS
MEMROL
    LEA     ROLMSG,A1       PRINT ROL
    JSR     PRINTLINE
    BRA     MEMSHIFTS
MEMSHIFTS
    LEA     SPACE,A1        PRINT SPACE
    JSR     PRINTLINE
    
    MOVE.L  D7,D1           RETRIEVE EA MODE
    MOVE.L  #3,D2           Start at the 3rd bit
    MOVE.L  #3,D3           Look at the next 3 bits (inclusive)
    JSR     BITMASK         Mask the selected bits
    LEA     SOURCEMODE,A2   Load "SOURCEMODE" into A2
    MOVE.B  D0,(A2)         Move the masked bits into "SOURCEMODE"
    MOVE.B  D0,D6           Move the bits into D6
    
    MOVE.L  D7,D1           RETRIEVE EA REG
    MOVE.L  #0,D2           Start at the 0th bit
    MOVE.L  #3,D3           Look at the next 3 bits (inclusive)
    JSR     BITMASK         Mask the selected bits
    LEA     SOURCEREG,A2    Load "SOURCEREG" into A2
    MOVE.B  D0,(A2)         Move the masked bits into "SOURCEREG"
    MOVE.B  D0,D5           Move the bits into D5

    JSR     CHECKANPAREN    Check if (An)
    JSR     CHECKANPLUS     Check if (An)+
    JSR     CHECKMINUSAN    Check if -(An)
    JSR     CHECKDATA       Check if xxx.W,xxx.L,#<data>
    CMP.B   #1,TRUE         Check if hit
    BNE     INVALID         Invalid
    
    ADD.W   #0,(A6)+        Increment
    BRA     DONE            Done
    
LSR
    LEA     LSRMSG,A1       PRINT LSR
    JSR     PRINTLINE
    BRA     FINISHSHIFTS
LSL
    LEA     LSLMSG,A1       PRINT LSL
    JSR     PRINTLINE
    BRA     FINISHSHIFTS
ASR
    LEA     ASRMSG,A1       PRINT ASR
    JSR     PRINTLINE
    BRA     FINISHSHIFTS
ASL
    LEA     ASLMSG,A1       PRINT ASL
    JSR     PRINTLINE
    BRA     FINISHSHIFTS
ROR
    LEA     RORMSG,A1       PRINT ROR
    JSR     PRINTLINE
    BRA     FINISHSHIFTS
ROL
    LEA     ROLMSG,A1       PRINT ROL
    JSR     PRINTLINE
    BRA     FINISHSHIFTS
FINISHSHIFTS   
    MOVE.L  D7,D1           RETRIEVE SIZE
    MOVE.L  #6,D2           Start at the 6th bit
    MOVE.L  #2,D3           Look at the next 2 bits (inclusive)
    JSR     BITMASK         Mask the selected bits
    MOVE.B  D0,D4           Move the size to D4
    
    JSR     PRINTSIZE       PRINT .B,.W.L
    
    
    LEA     SPACE,A1        PRINT SPACE
    JSR     PRINTLINE
    
    MOVE.L  D7,D1           RETRIEVE I/R
    MOVE.L  #5,D2           
    MOVE.L  #1,D3
    JSR     BITMASK
    
    CMP.B   #00,D0          IMMEDIATE SHIFT COUNT
    BEQ     IMMSHIFT
    CMP.B   #01,D0          REGISTER SHIFT COUNT
    BEQ     REGSHIFT
    BRA     INVALID         Invalid
    
IMMSHIFT
    LEA     POUND,A1        PRINT '#'
    JSR     PRINTLINE
    LEA     DOLLA,A1        PRINT '$'
    JSR     PRINTLINE
    LEA     ZERO,A1         PRINT A '0'
    JSR     PRINTLINE
    
    MOVE.L  D7,D1           RETRIEVE COUNT
    MOVE.L  #9,D2
    MOVE.L  #3,D3
    JSR     BITMASK
    
    CMP.B   #00,D0          REPLACE '0' WITH '8'
    BEQ     ZEROTOEIGHT     
    
    CLR     D1              PRINT COUNT
    MOVE.B  D0,D1
    MOVE.B  #3,D0    
    TRAP    #15
    BRA     LSLLSRREG

ZEROTOEIGHT
    LEA     EIGHT,A1        Print an 8 instead of 0
    JSR     PRINTLINE
    BRA     LSLLSRREG
 
REGSHIFT
    LEA     TXTD,A1         PRINT 'D'
    JSR     PRINTLINE

    MOVE.L  D7,D1           RETRIEVE COUNT
    MOVE.L  #9,D2
    MOVE.L  #3,D3
    JSR     BITMASK
    
    CLR     D1              PRINT COUNT
    MOVE.B  D0,D1
    MOVE.B  #3,D0    
    TRAP    #15
    BRA     LSLLSRREG
    
LSLLSRREG
    LEA     COMMA,A1        PRINT COMMA
    JSR     PRINTLINE
    LEA     TXTD,A1         PRINT 'D'
    JSR     PRINTLINE    
    
    MOVE.L  D7,D1           RETRIEVE EA REG
    MOVE.L  #0,D2
    MOVE.L  #3,D3
    JSR     BITMASK
    
    CLR     D1              PRINT REGISTER NUMBER
    MOVE.B  D0,D1
    MOVE.B  #3,D0    
    TRAP    #15
    ADD.W   #0,(A6)+
    BRA     DONE            Done
    
CHECKDN
    CMP.B   #%000,D6        CHECK IF Dn
    BNE     RETURN          RETURN IF NOT
    LEA     TXTD,A1         ELSE PRINT OUT D
    JSR     PRINTLINE
    MOVE.L  D5,D1           PRINT OUT REGISTER
    ADD.B   #$30,D1
    MOVE.B  #6,D0
    TRAP    #15
    MOVE.B  #1,TRUE
    RTS                     Return

CHECKAN
    CMP.B   #%001,D6        CHECK IF An
    BNE     RETURN          RETURN IF NOT
    LEA     TXTA,A1         ELSE PRINT OUT A
    JSR     PRINTLINE
    MOVE.L  D5,D1           PRINT OUT REGISTER
    ADD.B   #$30,D1
    MOVE.B  #6,D0
    TRAP    #15
    MOVE.B  #1,TRUE
    RTS                     Return

CHECKANPAREN
    CMP.B   #%010,D6        CHECK IF (An)
    BNE     RETURN          RETURN IF NOT
    LEA     PAREN1,A1       ELSE PRINT OUT APPROPROATE SYMBOLS
    JSR     PRINTLINE
    LEA     TXTA,A1         Print "A"
    JSR     PRINTLINE
    MOVE.L  D5,D1   
    ADD.B   #$30,D1         PRINT OUT REGISTER
    MOVE.B  #6,D0
    TRAP    #15
    LEA     PAREN2,A1       PRINT ")"
    JSR     PRINTLINE
    MOVE.B  #1,TRUE
    RTS                     Return
    
CHECKANPLUS
    CMP.B   #%011,D6        CHECK IF (An)+
    BNE     RETURN          RETURN IF NOT
    LEA     PAREN1,A1       ELSE PRINT OUT APPROPRIATE SYMBOLS
    JSR     PRINTLINE
    LEA     TXTA,A1         Print "A"
    JSR     PRINTLINE
    MOVE.L  D5,D1   
    ADD.B   #$30,D1         PRINT OUT REGISTER
    MOVE.B  #6,D0
    TRAP    #15
    LEA     PAREN2,A1       Print ")"
    JSR     PRINTLINE
    LEA     PLUS,A1         Print "+"
    JSR     PRINTLINE
    MOVE.B  #1,TRUE
    RTS                     Return
    
CHECKMINUSAN
    CMP.B   #%100,D6        CHECK IF -(An)
    BNE     RETURN          RETURN IF NOT
    LEA     MINUS,A1        ELSE PRINT OUT APPROPRIATE SYMBOLS
    JSR     PRINTLINE   
    LEA     PAREN1,A1       Print "("
    JSR     PRINTLINE
    LEA     TXTA,A1         Print "A"
    JSR     PRINTLINE
    MOVE.L  D5,D1           PRINT OUT REGISTER
    ADD.B   #$30,D1     
    MOVE.B  #6,D0
    TRAP    #15
    LEA     PAREN2,A1       Print ")"
    JSR     PRINTLINE
    MOVE.B  #1,TRUE
    RTS                     Return

CHECKDATA
    CMP.B   #%111,D6        
    BNE     RETURN
    CMP.B   #%000,D5
    BEQ     CHECKDATAW      Data W
    CMP.B   #%001,D5
    BEQ     CHECKDATAL      Data L
    CMP.B   #%100,D5
    BEQ     CHECKDATAIMM    Data Immediate 
    BRA     INVALID         Invalid
    
CHECKIMMEDIATE
    CMP.B   #%111,D6
    BNE     RETURN
    CMP.B   #%000,D5
    BEQ     CHECKDATAW      Data W
    CMP.B   #%001,D5
    BEQ     IMMEDIATEDATAL  Data Immediate
    BRA     INVALID         Invalid

CHECKNOTIMM
    CMP.B   #%111,D6
    BNE     RETURN
    CMP.B   #%000,D5
    BEQ     CHECKDATAW      Data W
    CMP.B   #%001,D5
    BEQ     CHECKDATAL      Data L
    BRA     INVALID         Invalid

CHECKDATAW
    MOVE.B  #4,D4           
    ADD.W   #0,(A6)+        Increment pointer
    LEA     DOLLA,A1        Print "$"
    JSR     PRINTLINE
    JSR     PRINTTOHEX      Print Word Data
    MOVE.B  #1,TRUE
    ADD.W   #0,-(A6)        Decrement pointer
    RTS                     Return
        
CHECKDATAL
    MOVE.B  #8,D4
    ADD.W   #0,(A6)+        Increment pointer
    LEA     DOLLA,A1        Print "$"
    JSR     PRINTLINE       
    MOVE.B  #8,D0
    JSR     PRINTTOHEX      Print Long Data
    MOVE.B  #1,TRUE
    ADD.W   #0,-(A6)        Decrement pointer
    RTS                     Return
    
IMMEDIATEDATAL
    MOVE.B  #8,D4       
    LEA     DOLLA,A1        Print "$"
    JSR     PRINTLINE       
    MOVE.B  #8,D0
    JSR     PRINTTOHEX      Print Immediate Data
    MOVE.B  #1,TRUE
    ADD.W   #0,-(A6)        Decrement pointer
    RTS                     Return
    
CHECKDATAIMM
    LEA     POUND,A1        Print "#"
    JSR     PRINTLINE
    LEA     DOLLA,A1        Print "$"
    JSR     PRINTLINE
    ADD.W   #0,(A6)+        Increment Pointer
    JSR     PRINTTOHEX      Print Data
    MOVE.B  #1,TRUE 
    ADD.W   #0,-(A6)        Decrement Pointer
    RTS                     Return
    
PRINTTOHEX
    JSR     GETSIZE         Get ".B,.W, or . L"
    CLR.L   D2              Clear D2
    CLR.L   D1              Clear D1
    
PRINTLOOP
    CMP.B   D4,D2           Keep looping?
    BEQ     RETURN          Return
    JSR     ROTATE          Jump to Rotate

    MOVE.B  D5,D3           
        
    AND.B   #$0F,D3
    CMPI.B  #9,D3
    BGT     PRINTLETTER     Print a letter
    
    ADDI.B  #$30,D3         Convert to Ascii
    MOVE.B  D3,D1           
    MOVE.B  #6,D0
    TRAP    #15
   
    ADDI.B  #1,D2
    BRA     PRINTLOOP       Loop again
    
PRINTLETTER
    ADDI.B  #$37,D3         Convert to Ascii
    MOVE.B  D3,D1           
    MOVE.B  #6,D0           Print Letter
    TRAP    #15
    ADDI.B  #1,D2   
    BRA     PRINTLOOP       Loop again

GETSIZE
    CMP.B   #2,D4           Byte Size
    BEQ     GETBYTE
    CMP.B   #4,D4           Word Size
    BEQ     GETWORD
    CMP.B   #8,D4           Long Size
    BEQ     GETLONG
    BRA     INVALID         Invalid
    
GETBYTE
    MOVE.B  (A6)+,D5
    RTS                     Return
    
GETWORD
    MOVE.W  (A6)+,D5
    RTS                     Return
    
GETLONG
    MOVE.L  (A6)+,D5
    RTS                     Return

ROTATE
    CMP.B   #2,D4           Byte Size
    BEQ     ROTATEBYTE
    CMP.B   #4,D4           Byte Size
    BEQ     ROTATEWORD
    CMP.B   #8,D4           Byte Size
    BEQ     ROTATELONG
    BRA     INVALID         Invalid
    
ROTATEBYTE
    ROL.B   #4,D5
    RTS                     Return
    
ROTATEWORD
    ROL.W   #4,D5
    RTS                     Return
    
ROTATELONG
    ROL.L   #4,D5
    RTS                     Return
    
PRINTLINE    
    MOVE.B  #14,D0          Print what is in A1
    TRAP    #15
    RTS


DONE
    MOVE.B  #00,TRUE        Initialize TRUE variable
    LEA     NEWLINE,A1      Load a new line into A1
    JSR     PRINTLINE       Print A1
    LEA     END,A2          Load "END" into A2
    MOVE.L  (A2),D0         Move END into D0
    MOVE.L  D0,A2           
    CMP.L   A6,A2           THIS IS WHERE WE CHECK IF WE ARE DONE
    BLT     RESTART         Prompt user to restart or quit
    LEA     LOOPCOUNTER,A3  Load Loop Counter into A3
    ADD.B   #1,(A3)         Increment Counter
    CMP.B   #30,(A3)        Compare to 30 to see if screen is full
    BEQ     SCREENFULL      If screen full
    BRA     STARTLOOP       Start over

RESTART
    LEA     RESTARTPRMT,A1  Prompt user if they want to restart
    JSR     PRINTLINE
    CLR.L   D1              Clear D1
    MOVE.B  #5,D0           
    TRAP    #15
    CMP.L   #$59,D1         Check if input "Y"
    BEQ     CLRSTART        User wants to continue
    CMP.B   #$79,D1         Check if input "y"
    BEQ     CLRSTART        User wants to continue
    CMP.L   #$4E,D1         Check if input "N"
    BEQ     QUIT            User does not want to continue
    CMP.B   #$6E,D1         Check if input "n"
    BEQ     QUIT            User does not want to continue
    BRA     RESTART         Restart

CLRSTART
    MOVE.B  #11,D0          Clear Screen
    MOVE.W  #$FF00,D1
    TRAP    #15
    BRA     PROGSTART       Branch to Start
    
SCREENFULL
    LEA     CONTPROMPT,A1   PRINT SCREENFULL MESSAGE
    JSR     PRINTLINE
    
    MOVE.B  #0,LOOPCOUNTER  Set loop counter to 0
    
    MOVE.B  #5,D0           PAUSE UNTIL ENTER IS PRESSED
    TRAP    #15
    CMP.B   #$0D,D1
    BEQ     CLRSCREEN       Clear the Screen
    
    BRA     SCREENFULL      ENTER NOT PRESSEFD
      
CLRSCREEN
    MOVE.B  #11,D0          Clear Screen
    MOVE.W  #$FF00,D1
    TRAP    #15
    MOVE.W  LOOPCOUNTER,A2  Reset LOOPCOUNTER
    MOVE.B  #0,(A2)
    BRA     STARTLOOP       Branch to loop more
    
INVALID
    LEA     NEWLINE,A1      Notify User of invalid data
    JSR     PRINTLINE
    MOVEM.L A6,-(SP)        Put A6 on the stack
    LEA     CURRENTADD,A2   Point the current address at A6
    MOVE.L  A2,A6           
    MOVE.B  #8,D4           Move pointer
    JSR     PRINTTOHEX      Print 
    MOVEM.L (SP)+,A6        Get the true current address off the stack

    LEA     INVALIDMSG,A1   Print invalid message
    JSR     PRINTLINE

    MOVEM.L A6,-(SP)        Put A6 on the stack
    MOVE.W  D7,(A6)         
    MOVE.B  #4,D4
    JSR     PRINTTOHEX      Print 
    MOVEM.L (SP)+,A6        Take the true current address off the stack
    ADD.L   #0,(A6)+        Increment the pointer
    BRA     DONE            done
  
QUIT
    MOVE.B  #9, D0          Shuts the program down
    TRAP    #15  
    SIMHALT

* Put variables and constants here
        
CR          EQU     $0D
LF          EQU     $0A
TAB         EQU     $09

WELCOME     DC.B        'WELCOME TO OUR DISSASSEMBLER!',CR,LF,0
STARTADD    DC.B        'Enter Starting Input Address:',CR,LF,0
ENDADD      DC.B        'Enter Ending Input Address:',CR,LF,0
INVALIDMSG  DC.B        ' INVALID COMMAND: $',0
CONTPROMPT  DC.B        'Press ENTER to continue.',CR,LF,0
RESTARTPRMT DC.B        'Would you like to Dissassemble again? (Y/N)',CR,LF,0
BADADDS     DC.B        'INVALID ADRESSES. RE-ENTER ADRESSES',CR,LF,0
NEWLINE     DC.B        '',CR,LF,0
BYTEMSG     DC.B        '.B  ',0
WORDMSG     DC.B        '.W  ',0
LONGMSG     DC.B        '.L  ',0
MOVEMSG     DC.B        'MOVE',0
MOVEQMSG    DC.B        'MOVEQ  ',0
MOVEMMSG    DC.B        'MOVEM',0
DIVSMSG     DC.B        'DIVS',0
ADDMSG      DC.B        'ADD',0
ADDAMSG     DC.B        'ADDA',0
ADDQMSG     DC.B        'ADDQ ',0
SUBMSG      DC.B        'SUB',0
SUBAMSG     DC.B        'SUBA',0
SUBIMSG     DC.B        'SUBI',0
MULSMSG     DC.B        'MULS',0
LEAMSG      DC.B        'LEA ',0
CLRMSG      DC.B        'CLR',0
ANDMSG      DC.B        'AND',0
ANDIMSG     DC.B        'ANDI',0
EORMSG      DC.B        'EOR',0
EORIMSG     DC.B        'EORI',0
ASLMSG      DC.B        'ASL',0
ASRMSG      DC.B        'ASR',0
ROLMSG      DC.B        'ROL',0
RORMSG      DC.B        'ROR',0
BCHGMSG     DC.B        'BCHG',0
CMPMSG      DC.B        'CMP',0
CMPAMSG     DC.B        'CMPA',0
JSRMSG      DC.B        'JSR',0
RTSMSG      DC.B        'RTS',0
SPACE       DC.B        ' ',0
CMPIMSG     DC.B        'CMPI',0

TXTD        DC.B        'D', 0
TXTA        DC.B        'A', 0
PAREN1      DC.B        '(', 0
PAREN2      DC.B        ')', 0
PLUS        DC.B        '+', 0
MINUS       DC.B        '-', 0
COMMA       DC.B        ',',0
DOLLA       DC.B        '$',0
POUND       DC.B        '#',0
SLASH       DC.B        '/',0
BCCMSG      DC.B        'BCC',0
BGTMSG      DC.B        'BGT',0
BLEMSG      DC.B        'BLE',0
BVSMSG      DC.B        'BVS',0
LSLMSG      DC.B        'LSL',0
LSRMSG      DC.B        'LSR',0
ZERO        DC.B        '0',0
EIGHT       DC.B        '8',0


BANNER  DC.B   'o   o',CR,LF
        DC.B   '            /^^^^^7               ___    _   ___ _  _ ___  _____      __',CR,LF
        DC.B   '"   "    ,oO))))))))Oo,          | _ \  /_\ |_ _| \| | _ )/ _ \ \    / /',CR,LF
        DC.B   '       ,"))))))))))))))), /{     |   / / _ \ | || .` | _ \ (_) \ \/\/ / ',CR,LF
        DC.B   '  "  ,"o  ))))))))))))))))={     |_|_\/_/ \_\___|_|\_|___/\___/ \_/\_/  ',CR,LF
        DC.B   '     >    ))))))))))))))))={               | __|_ _/ __| || |           ',CR,LF
        DC.B   '     `,   ))))))\ \)))))))={               | _| | |\__ \ __ |           ',CR,LF
        DC.B   '       "  ))))))))\/)))))"\{               |_| |___|___/_||_|           ',CR,LF
        DC.B   '         "*O))))))))O*"',CR,LF,CR,LF,0

    END    START        ; last line of source




*~Font name~Courier New~
*~Font size~10~
*~Tab type~1~
*~Tab size~4~
