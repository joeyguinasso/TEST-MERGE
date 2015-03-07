*-----------------------------------------------------------
* Title      :
* Written by :
* Date       :
* Description:
*-----------------------------------------------------------
    ORG    $1000
START:

BEGINNING   EQU $9000
END         EQU $90A0
OPCODE      EQU $400
DESTREG     EQU $410
DESTMODE    EQU $420
SOURCEREG   EQU $430
SOURCEMODE  EQU $440
     
*-----------------------------------------------------------
*START OF PROGRAM
*PRINT BANNER & WELCOME
*ASK USER FOR INPUT
*-----------------------------------------------------------

    MOVE.W  #$0C39,$A750 *PUT GENERATED HEX VALUE HERE
    MOVE.L  #$000FDCA4,$A752
    CMPI.B  #$F,$DCA4 *FOR GENERATING HEX VALUES
    
    LEA     BANNER,A1      *Print Welcome Message
    MOVE.B  #14,D0          
    TRAP    #15
    
    LEA     WELCOME,A1      *Print Welcome Message
    MOVE.B  #14,D0          
    TRAP    #15
    
    LEA     STARTADD,A1     *Print Input Message1
    JSR     PRINTLINE
    
    LEA     BEGINNING,A1
    MOVE.B  #2,D0           *Store starting address at BEGINNING
    TRAP    #15
    JSR     CONVERTER
    MOVE.L  D7,BEGINNING    
    
    LEA     ENDADD,A1     *Print Input Message2
    JSR     PRINTLINE
    
    CLR.L   D7
    CLR.L   D5
    LEA     END,A1
    MOVE.B  #2,D0           *Store ending address at END
    TRAP    #15
    JSR     CONVERTER
    MOVE.L  D7,END
    
    BRA     OPC

*-----------------------------------------------------------
*GET OPCODE   
*-----------------------------------------------------------
OPC    
    MOVE.L  BEGINNING,A6
    MOVE.W  (A6),D7
    MOVE.W  D7,D1
    MOVE.L  #12,D2
    MOVE.L  #4,D3
    JSR     BITMASK
    MOVE.L  D0,D2
    JSR     OPCODECOMPARE
    BRA     DONE
    
RETURN
    RTS
    
CONVERTER
    ADDI.B  #1,D5
    CMP.B   D1,D5
    BGT     RETURN
    MOVE.B  (A1)+,D6
    CMP.B   D5,D6
    BEQ     DONE
    CMP.B   #70,D6      *MAX LETTER VALUE
    BGT     DONE
    CMP.B   #64,D6      *MIN-1 LETTER VALUE
    BGT     LET
    CMP.B   #57,D6      *MAX NUMBER VALUE
    BGT     DONE
    CMP.B   #47,D6      *MIN-1 NUMBER VALUE
    BGT     NUM
    RTS
    
LET
    SUBI.B  #55,D6      *ASCII TO HEX FOR LETTER CONVERSION
    BRA     CONVERTED
    
NUM
    SUBI.B  #48,D6      *ASCII TO HEX FOR NUMBER CONVERSION
    BRA     CONVERTED

CONVERTED
    ASL.L   #4,D7
    ADD.B   D6,D7
    BRA     CONVERTER
      
*-----------------------------------------------------------
*BIT MASK
*D1- WHOLE 16 BITS/D2-START BIT/D3-NUMBER OF BITS
*-----------------------------------------------------------
BITMASK
    MOVEM.L D1-D4,-(SP)
    MOVE.L  D1,D0
    
    CLR     D4
    MOVE.L  #1,D4
    LSL     D3,D4
    SUB     #1,D4
    
    LSR.L   D2,D0
    AND.L   D4,D0
    
    MOVEM.L (SP)+,D1-D4
    RTS

OPCODECOMPARE
    CMP.B   #%0000,D2
    BEQ     OPC0000
    CMP.B   #%0001,D2
    BEQ     OPC0001
    CMP.B   #%0010,D2
    BEQ     OPC0010
    CMP.B   #%0011,D2
    BEQ     OPC0011
    CMP.B   #%0100,D2
    BEQ     OPC0100
    CMP.B   #%0101,D2
    BEQ     OPC0101
    CMP.B   #%0110,D2
    BEQ     OPC0110
    CMP.B   #%0111,D2
    BEQ     OPC0111
    CMP.B   #%1000,D2
    BEQ     OPC1000
    CMP.B   #%1001,D2
    BEQ     OPC1001
    CMP.B   #%1011,D2
    BEQ     OPC1011
    CMP.B   #%1100,D2
    BEQ     OPC1100
    CMP.B   #%1101,D2
    BEQ     OPC1101
    CMP.B   #%1110,D2
    BEQ     OPC1110
    CMP.B   #%0000,D2
    BEQ     OPC0000
    BRA     DONE        *INVALID
    
MOVEDECODE
    LEA     OPCODE,A2
    MOVE.B  D2,(A2)
    
    MOVE.L  D7,D1               *RETRIEVE SOURCE MODE
    MOVE.L  #3,D2
    MOVE.L  #3,D3
    JSR     BITMASK
    LEA     SOURCEMODE,A2
    MOVE.B  D0,(A2)
    MOVE.B  D0,D6
    
    MOVE.L  D7,D1               *RETRIEVE SOURCE REG
    MOVE.L  #0,D2
    MOVE.L  #3,D3
    JSR     BITMASK
    LEA     SOURCEREG,A2
    MOVE.B  D0,(A2)
    MOVE.B  D0,D5

    JSR     CHECKDN             *CHECK MODES
    JSR     CHECKAN
    JSR     CHECKANPAREN
    JSR     CHECKANPLUS
    JSR     CHECKMINUSAN
    JSR     CHECKDATA
    
    LEA     COMMA,A1            *THIS IS FOR COMMAS
    JSR     PRINTLINE
    
    MOVE.L  D7,D1               *RETRIEVE DESTINATION MODE
    MOVE.L  #6,D2               
    MOVE.L  #3,D3    
    JSR     BITMASK          
    LEA     DESTMODE,A2
    MOVE.B  D0,(A2)
    MOVE.B  D0,D6
        
    MOVE.L  D7,D1               *RETRIEVE DESTINATION REG
    MOVE.L  #9,D2
    MOVE.L  #3,D3
    JSR     BITMASK
    LEA     DESTREG,A2
    MOVE.B  D0,(A2)
    MOVE.B  D0,D5
    
    JSR     CHECKDN             *CHECKMODES
    JSR     CHECKANPAREN
    JSR     CHECKANPLUS
    JSR     CHECKMINUSAN
    JSR     CHECKDATA
    
    BRA     DONE
    
ANDDECODE
    
    LEA     ANDMSG,A1      *PRINT MOVE
    JSR     PRINTLINE
    
    *SHOULD ALREADY HAVE OPMODE IN D6
    *FROM CHECKING IF MULS OR AND 
    *USE OPMODE TO DETERMINE IF BYTE,WORD,LONG 
    *THEN USE OPMODE TO DETERMINE <EA>,DN |OR| DN,<EA>
    JSR     EAORDEST
    BRA     DONE
    
*WHAT HERB ADDED*******************************************************************************
PRINTANDI
    LEA     ANDIMSG,A1
    JSR     PRINTLINE
    RTS
PRINTEORI
    LEA     EORIMSG,A1
    JSR     PRINTLINE
    RTS
PRINTCMPI
    LEA     CMPIMSG,A1
    JSR     PRINTLINE
    RTS
PRINTXXXI
    CMP.B   #$02,D0
    BEQ     PRINTANDI
    CMP.B   #$0A,D0
    BEQ     PRINTEORI
    CMP.B   #$0C,D0
    BEQ     PRINTCMPI
    BRA     DONE        ****INVALID******
XXXIDECODE
    JSR     PRINTXXXI
    
    
    
    MOVE.L  D7,D1               *RETRIEVE SIZE OF OPERATION
    MOVE.L  #6,D2
    MOVE.L  #2,D3
    JSR     BITMASK
    MOVE.L  D0,D4
    
    
    ADDA.W  #$03,A6             *PREP TO PRINT IMMEDIATE DATA
    MOVEA.L A6,A3
    
    JSR     PRINTSIZE2BITS      
    MOVEA.L A3,A6
    SUBA.L  #$02,A6
    
    LEA     COMMA,A1
    JSR     PRINTLINE
    
    MOVE.L  D7,D1               *RETRIEVE EA MODE
    MOVE.L  #3,D2
    MOVE.L  #3,D3
    JSR     BITMASK
    LEA     SOURCEMODE,A2
    MOVE.B  D0,(A2)
    MOVE.L  D0,D6
    
    MOVE.L  D7,D1               *RETRIEVE EA REG
    MOVE.L  #0,D2
    MOVE.L  #3,D3
    JSR     BITMASK
    LEA     SOURCEREG,A2
    MOVE.B  D0,(A2)
    MOVE.L  D0,D5
    
    CMP.B   #%100,D6            *TO AVOID IMMEDIATE DATA AS EA MODE*
    BEQ     DONE                ****INVALID**************************

    JSR     CHECKDN             *CHECKMODES
    JSR     CHECKANPAREN
    JSR     CHECKANPLUS
    JSR     CHECKMINUSAN
    JSR     CHECKDATA

    BRA     DONE

PRINTSIZE2BITS
    CMP.B   #%00,D4
    BEQ     PRINTB
    CMP.B   #%01,D4
    BEQ     PRINTW
    CMP.B   #%10,D4
    BEQ     PRINTL
    BRA     DONE    *INVALID*
PRINTB
    LEA     BYTEMSG,A1
    JSR     PRINTLINE
    LEA     POUND,A1
    JSR     PRINTLINE
    LEA     DOLLA,A1
    JSR     PRINTLINE
    MOVE.L  #2,D4
    CLR     D1
    CLR     D2
    JSR     GETBYTE
    JSR     PRINTLOOP
    ADDA.W  #$01,A3
    RTS    
PRINTW
    LEA     LONGMSG,A1
    JSR     PRINTLINE
    LEA     POUND,A1
    JSR     PRINTLINE
    LEA     DOLLA,A1
    JSR     PRINTLINE
    MOVE.L  #4,D4
    CLR     D1
    CLR     D2
    JSR     GETWORD
    JSR     PRINTLOOP
    ADDA.W  #$03,A3
    RTS  
PRINTL
    LEA     LONGMSG,A1
    JSR     PRINTLINE
    LEA     POUND,A1
    JSR     PRINTLINE
    LEA     DOLLA,A1
    JSR     PRINTLINE
    MOVE.L  #8,D4
    CLR     D1
    CLR     D2
    JSR     GETLONG
    JSR     PRINTLOOP
    ADDA.W  #$07,A3
    RTS  
    
RTSDECODE
    LEA     RTSMSG,A1
    JSR     PRINTLINE
    BRA     DONE
JSRDECODE
    LEA     JSRMSG,A1
    JSR     PRINTLINE
    
    MOVE.L  D7,D1               *RETRIEVE EA MODE
    MOVE.L  #3,D2
    MOVE.L  #3,D3
    JSR     BITMASK
    LEA     SOURCEMODE,A2
    MOVE.B  D0,(A2)
    MOVE.B  D0,D6
    
    MOVE.L  D7,D1               *RETRIEVE EA REG
    MOVE.L  #0,D2
    MOVE.L  #3,D3
    JSR     BITMASK
    LEA     SOURCEREG,A2
    MOVE.B  D0,(A2)
    MOVE.B  D0,D5
    
    LEA     SPACE,A1
    JSR     PRINTLINE
    
    JSR     CHECKANPAREN
    JSR     CHECKDATA
    
    BRA     DONE
*END WHAT HERB ADDED***************************************************************************
ISEA
    MOVE.L  D7,D1               *RETRIEVE SOURCE MODE
    MOVE.L  #3,D2
    MOVE.L  #3,D3
    JSR     BITMASK
    LEA     SOURCEMODE,A2
    MOVE.B  D0,(A2)
    MOVE.B  D0,D6
    
    MOVE.L  D7,D1               *RETRIEVE SOURCE REG
    MOVE.L  #0,D2
    MOVE.L  #3,D3
    JSR     BITMASK
    LEA     SOURCEREG,A2
    MOVE.B  D0,(A2)
    MOVE.B  D0,D5

    JSR     CHECKDN             *CHECK MODES
    JSR     CHECKANPAREN
    JSR     CHECKANPLUS
    JSR     CHECKMINUSAN
    JSR     CHECKDATA
    
    RTS
ISDEST    
    MOVE.L  D7,D1               *RETRIEVE DESTINATION MODE
    MOVE.L  #6,D2               
    MOVE.L  #3,D3    
    JSR     BITMASK          
    LEA     DESTMODE,A2
    MOVE.B  D0,(A2)
    MOVE.B  D0,D6
        
    MOVE.L  D7,D1               *RETRIEVE DESTINATION REG
    MOVE.L  #9,D2
    MOVE.L  #3,D3
    JSR     BITMASK
    LEA     DESTREG,A2
    MOVE.B  D0,(A2)
    MOVE.B  D0,D5
    *NOT SURE BUT SHOULD ALWAYS BE A DATA REG
    *EXAMPLE TEST: 
    *AND.W #4,(A4) IS 0254 0004
    *REDIRECTS TO ANDI.W #4,(A4)
    *OPCODE IS 0000 0010 FOR ANDI
    *IF IT DIDNT IT SHOULD BE 
    *1100 100 001 111 100 -> C87C 0004
    LEA     TXTD,A1         
    JSR     PRINTLINE
    MOVE.L  D5,D1           *PRINT OUT REGISTER
    ADD.B   #$30,D1
    MOVE.B  #6,D0
    TRAP    #15

    *SHOULDNT NEED THESE BUT MIGHT LATER
    *JSR     CHECKDN             *CHECKMODES
    *JSR     CHECKANPAREN
    *JSR     CHECKANPLUS
    *JSR     CHECKMINUSAN
    *JSR     CHECKDATA
    RTS
EAORDEST
*STRUCTURE:
    *CHECK <EA>,DN TYPE(1)
    *BRANCH IF EQUAL
    *CHECK DN,<EA> TYPE(2)
    *BRANCH IF EQUAL
*BYTE SIZE
    CMP.B   #%000,D6
    BEQ     BYTE1
    CMP.B   #%100,D6
    BEQ     BYTE2
*WORD SIZE
    CMP.B   #%001,D6
    BEQ     WORD1
    CMP.B   #%101,D6
    BEQ     WORD2
*LONG SIZE
    CMP.B   #%010,D6
    BEQ     LONG1
    CMP.B   #%110,D6
    BEQ     LONG2
    BRA     DONE            **********INVALID********************************************************************
BYTE1       
    LEA     BYTEMSG,A1      *PRINT SIZE
    JSR     PRINTLINE    
    MOVE.B  #2,D4
    JSR     ISEA
    LEA     COMMA,A1            *THIS IS FOR COMMAS
    JSR     PRINTLINE
    JSR     ISDEST
    RTS
BYTE2
    LEA     BYTEMSG,A1      *PRINT SIZE
    JSR     PRINTLINE    
    MOVE.B  #2,D4
    JSR     ISDEST
    LEA     COMMA,A1            *THIS IS FOR COMMAS
    JSR     PRINTLINE
    JSR     ISEA
    RTS
WORD1
    LEA     WORDMSG,A1      *PRINT SIZE
    JSR     PRINTLINE    
    MOVE.B  #4,D4
    JSR     ISEA
    LEA     COMMA,A1            *THIS IS FOR COMMAS
    JSR     PRINTLINE
    JSR     ISDEST
    RTS
WORD2
    LEA     WORDMSG,A1      *PRINT SIZE
    JSR     PRINTLINE    
    MOVE.B  #4,D4
    JSR     ISDEST
    LEA     COMMA,A1            *THIS IS FOR COMMAS
    JSR     PRINTLINE
    JSR     ISEA
    RTS
LONG1
    LEA     LONGMSG,A1      *PRINT SIZE
    JSR     PRINTLINE    
    MOVE.B  #8,D4
    JSR     ISEA
    LEA     COMMA,A1            *THIS IS FOR COMMAS
    JSR     PRINTLINE
    JSR     ISDEST
    RTS
LONG2
    LEA     LONGMSG,A1      *PRINT SIZE
    JSR     PRINTLINE    
    MOVE.B  #8,D4
    JSR     ISDEST
    LEA     COMMA,A1            *THIS IS FOR COMMAS
    JSR     PRINTLINE
    JSR     ISEA
    RTS

MULDECODE
    
    BRA DONE

PRINTDATAREG
    MOVE.L  D7,D1               *RETRIEVE DATA REGISTER
    MOVE.L  #9,D2
    MOVE.L  #3,D3
    JSR     BITMASK
    LEA     SOURCEMODE,A2
    MOVE.B  D0,(A2)
    MOVE.B  D0,D6

    LEA     TXTD,A1
    JSR     PRINTLINE
    MOVE.L  D6,D1           *PRINT OUT REGISTER
    ADD.B   #$30,D1
    MOVE.B  #6,D0
    TRAP    #15
    RTS

PRINTSIZE
    CMP.B   #%00,D4
    BEQ     PRINTBYTE
    CMP.B   #%01,D4
    BEQ     PRINTWORD
    CMP.B   #%10,D4
    BEQ     PRINTLONG
    RTS

PRINTBYTE
    LEA     BYTEMSG,A1
    JSR     PRINTLINE
    RTS
    
PRINTWORD
    LEA     WORDMSG,A1
    JSR     PRINTLINE
    RTS

PRINTLONG
    LEA     LONGMSG,A1
    JSR     PRINTLINE
    RTS

*BCHG/ANDI/EORI/CMPI
OPC0000
*WHAT HERB ADDED******************************************************************************    
    MOVE.L  D7,D1       *RETRIEVE BITS 6-15
    MOVE.L  #6,D2
    MOVE.L  #9,D3
    JSR     BITMASK
    MOVE.L  D0,D1       *D1 CONTAINS BITS IF BCHG
    ANDI.B  #$7,D1      *TO GET LEAST SIGNIF BITS 101
    
    CMP.B   #%101,D1     *COMPARE BITS 6-8
    *BEQ     BCHGDECODE  *BRANCH TO BCHGDECODE
    
    MOVE.L  D7,D1       *RETRIEVE BITS 8-15
    MOVE.L  #8,D2
    MOVE.L  #7,D3
    JSR     BITMASK
                        *D0 CONTAINS BITS IF XXXI
    BRA     XXXIDECODE  *BRANCH TO XXXIDECODE
   *IF ILLEGAL XXXIDECODE WILL HANDLE
   
*WHAT HERB ADDED******************************************************************************END    

*MOVE.B
OPC0001
    
    LEA     MOVEMSG,A1      *PRINT MOVE
    JSR     PRINTLINE
    LEA     BYTEMSG,A1      *PRINT SIZE
    JSR     PRINTLINE    
    MOVE.B  #2,D4
    BRA     MOVEDECODE      *DECODE MOVE
    

*MOVE.L
OPC0010

    LEA     MOVEMSG,A1      *PRINT MOVE
    JSR     PRINTLINE
    LEA     LONGMSG,A1      *PRINT SIZE
    JSR     PRINTLINE    
    MOVE.B  #8,D4
    BRA     MOVEDECODE      *DECODE MOVE
    
*MOVE.W
OPC0011

    LEA     MOVEMSG,A1      *PRINT MOVE
    JSR     PRINTLINE
    LEA     WORDMSG,A1      *PRINT SIZE
    JSR     PRINTLINE    
    MOVE.B  #4,D4
    BRA     MOVEDECODE      *DECODE MOVE
    
*LEA/CLR/MOVEM/RTS/JSR
OPC0100
*WHAT HERB ADDED******************************************************************************
    CMP.W #$4E75,D7 *RTS COMPARE
    BEQ   RTSDECODE
    
    *JSR COMPARE
    MOVE.L  D7,D1   *RETRIEVE BITS 6-15
    MOVE.L  #6,D2
    MOVE.L  #9,D3
    JSR     BITMASK
    CMP.W   #$13A,D0
    BEQ     JSRDECODE
    
    *
    
    BRA     DONE            **********INVALID*****************************************************
*WHAT HERB ADDED******************************************************************************END
*ADDQ
OPC0101

*BCC
OPC0110

*MOVEQ
OPC0111

*DIVS
OPC1000

    LEA     DIVSMSG,A1
    JSR     PRINTLINE
    LEA     WORDMSG,A1
    JSR     PRINTLINE
    
    MOVE.L  D7,D1               *RETRIEVE EA MODE
    MOVE.L  #3,D2
    MOVE.L  #3,D3
    JSR     BITMASK
    LEA     SOURCEMODE,A2
    MOVE.B  D0,(A2)
    MOVE.B  D0,D6

    MOVE.L  D7,D1               *RETRIEVE EA REG
    MOVE.L  #0,D2
    MOVE.L  #3,D3
    JSR     BITMASK
    LEA     SOURCEREG,A2
    MOVE.B  D0,(A2)
    MOVE.B  D0,D5
    
    JSR     CHECKDN             *CHECK MODES
    JSR     CHECKAN
    JSR     CHECKANPLUS
    JSR     CHECKMINUSAN

    LEA     COMMA,A1            *THIS IS FOR COMMAS
    JSR     PRINTLINE
    
    JSR     PRINTDATAREG
    
    BRA     DONE
    
*SUB/SUBA
OPC1001

    MOVE.L  D7,D1               *DETERMINE SUB VS SUBA
    MOVE.L  #6,D2
    MOVE.L  #2,D3
    JSR     BITMASK
    
    CMP.B   #%11,D0             *BRANCH APPROPRIATELY
    BEQ     SUBA
    MOVE.B  D0,D4               *D4 CONTAINS SIZE INFO
    
    
    LEA     SUBMSG,A1
    JSR     PRINTLINE
    
    JSR     PRINTSIZE
    
    MOVE.L  D7,D1               *DETERMINE SOURCE/DESTINATION ORDER
    MOVE.L  #8,D2
    MOVE.L  #1,D3
    JSR     BITMASK
    CMP.B   #%1,D0
    BEQ     SUB2

*Dn - <EA>
SUB1
    JSR     PRINTDATAREG
    
    LEA     COMMA,A1            *THIS IS FOR COMMAS
    JSR     PRINTLINE
    
    JSR     SUBEA
    BRA     DONE
    
SUBEA
    MOVE.L  D7,D1               *RETRIEVE EA MODE
    MOVE.L  #3,D2
    MOVE.L  #3,D3
    JSR     BITMASK
    LEA     SOURCEMODE,A2
    MOVE.B  D0,(A2)
    MOVE.B  D0,D6

    MOVE.L  D7,D1               *RETRIEVE EA REG
    MOVE.L  #0,D2
    MOVE.L  #3,D3
    JSR     BITMASK
    LEA     SOURCEREG,A2
    MOVE.B  D0,(A2)
    MOVE.B  D0,D5

    JSR     CHECKDN
    JSR     CHECKAN
    JSR     CHECKANPAREN
    JSR     CHECKANPLUS
    JSR     CHECKMINUSAN
    RTS
    
*<EA> - Dn 
SUB2
    JSR     SUBEA
    
    LEA     COMMA,A1
    JSR     PRINTLINE
    
    JSR     PRINTDATAREG
    BRA     DONE


SUBA
    MOVE.B  D0,D4               *D4 CONTAINS SIZE INFO
    BRA     DONE



*EOR/CMP/CMPA *HERB DID THIS**********************************************************************
OPC1011
    MOVE.L  D7,D1               *RETRIEVE OPMODE MODE
    MOVE.L  #6,D2
    MOVE.L  #3,D3
    JSR     BITMASK
    LEA     SOURCEMODE,A2
    MOVE.B  D0,(A2)
    MOVE.B  D0,D6
    
    JSR     ISCMPEORCMPA
    JSR     EAORDEST
    BRA     DONE

ISCMPEORCMPA
*BYTE SIZE
    CMP.B   #%000,D6            *CMP
    BEQ     CMPPRINT
    CMP.B   #%100,D6            *EOR
    BEQ     EORPRINT
*WORD SIZE
    CMP.B   #%001,D6            *CMP
    BEQ     CMPPRINT
    CMP.B   #%101,D6            *EOR
    BEQ     EORPRINT
    CMP.B   #%011,D6            *CMPA
    BEQ     CMPAPRINT
*LONG SIZE
    CMP.B   #%010,D6            *CMP
    BEQ     CMPPRINT
    CMP.B   #%110,D6            *EOR
    BEQ     EORPRINT
    CMP.B   #%111,D6            *CMPA
    BEQ     CMPAPRINT
    BRA     DONE                *INVALID*
CMPPRINT
    LEA     CMPMSG,A1
    JSR     PRINTLINE
    RTS
EORPRINT
    LEA     EORMSG,A1
    JSR     PRINTLINE
    RTS
CMPAPRINT
    LEA     CMPAMSG,A1
    JSR     PRINTLINE
    JSR     EAORAN
    BRA     DONE
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
    BRA     DONE     ****INVALID******************************************
WORD3
    LEA     WORDMSG,A1      *PRINT SIZE
    JSR     PRINTLINE    
    MOVE.B  #4,D4
    JSR     ISEA
    LEA     COMMA,A1            *THIS IS FOR COMMAS
    JSR     PRINTLINE
    JSR     ISAN
    RTS
LONG3    
    LEA     LONGMSG,A1      *PRINT SIZE
    JSR     PRINTLINE    
    MOVE.B  #4,D4
    JSR     ISEA
    LEA     COMMA,A1            *THIS IS FOR COMMAS
    JSR     PRINTLINE
    JSR     ISAN
    RTS
ISAN
     MOVE.L  D7,D1               *RETRIEVE DESTINATION MODE
    MOVE.L  #6,D2               
    MOVE.L  #3,D3    
    JSR     BITMASK          
    LEA     DESTMODE,A2
    MOVE.B  D0,(A2)
    MOVE.B  D0,D6
        
    MOVE.L  D7,D1               *RETRIEVE DESTINATION REG
    MOVE.L  #9,D2
    MOVE.L  #3,D3
    JSR     BITMASK
    LEA     DESTREG,A2
    MOVE.B  D0,(A2)
    MOVE.B  D0,D5
    *****ADDRESS REGISTER PRINT.CHECK TO SEE IF CAN MERGE WITH ISDEST***********
    LEA     TXTA,A1         
    JSR     PRINTLINE
    MOVE.L  D5,D1           *PRINT OUT REGISTER
    ADD.B   #$30,D1
    MOVE.B  #6,D0
    TRAP    #15
    RTS

*MULS/AND   *GET MULS FROM DREW*
OPC1100
    MOVE.L  D7,D1               *RETRIEVE SOURCE MODE
    MOVE.L  #6,D2
    MOVE.L  #3,D3
    JSR     BITMASK
    LEA     SOURCEMODE,A2
    MOVE.B  D0,(A2)
    MOVE.B  D0,D6
    
    CMP.B   #%111,D6            *IF EQUAL MULS, ELSE AND
    BEQ     MULDECODE
    BNE     ANDDECODE
*HERB STOPPED HERE************************************************************************
*ADD/
OPC1101

*LSL/LSR/ASL/ASR/ROL/ROR
OPC1110


CHECKDN
    CMP.B   #%000,D6        *CHECK IF Dn
    BNE     RETURN          *RETURN IF NOT
    LEA     TXTD,A1         *ELSE PRINT OUT D
    JSR     PRINTLINE
    MOVE.L  D5,D1           *PRINT OUT REGISTER
    ADD.B   #$30,D1
    MOVE.B  #6,D0
    TRAP    #15
    RTS

CHECKAN
    CMP.B   #%001,D6        *CHECK IF An
    BNE     RETURN          *RETURN IF NOT
    LEA     TXTA,A1         *ELSE PRINT OUT A
    JSR     PRINTLINE
    MOVE.L  D5,D1           *PRINT OUT REGISTER
    ADD.B   #$30,D1
    MOVE.B  #6,D0
    TRAP    #15
    RTS    

CHECKANPAREN
    CMP.B   #%010,D6        *CHECK IF (An)
    BNE     RETURN          *RETURN IF NOT
    LEA     PAREN1,A1       *ELSE PRINT OUT APPROPROATE SYMBOLS
    JSR     PRINTLINE
    LEA     TXTA,A1
    JSR     PRINTLINE
    MOVE.L  D5,D1   
    ADD.B   #$30,D1         *PRINT OUT REGISTER
    MOVE.B  #6,D0
    TRAP    #15
    LEA     PAREN2,A1
    JSR     PRINTLINE
    RTS
    
CHECKANPLUS
    CMP.B   #%011,D6        *CHECK IF (An)+
    BNE     RETURN          *RETURN IF NOT
    LEA     PAREN1,A1       *ELSE PRINT OUT APPROPRIATE SYMBOLS
    JSR     PRINTLINE
    LEA     TXTA,A1
    JSR     PRINTLINE
    MOVE.L  D5,D1   
    ADD.B   #$30,D1         *PRINT OUT REGISTER
    MOVE.B  #6,D0
    TRAP    #15
    LEA     PAREN2,A1
    JSR     PRINTLINE
    LEA     PLUS,A1
    JSR     PRINTLINE
    RTS
    
CHECKMINUSAN
    CMP.B   #%100,D6        *CHECK IF -(An)
    BNE     RETURN          *RETURN IF NOT
    LEA     MINUS,A1        *ELSE PRINT OUT APPROPRIATE SYMBOLS
    JSR     PRINTLINE   
    LEA     PAREN1,A1
    JSR     PRINTLINE
    LEA     TXTA,A1
    JSR     PRINTLINE
    MOVE.L  D5,D1           *PRINT OUT REGISTER
    ADD.B   #$30,D1     
    MOVE.B  #6,D0
    TRAP    #15
    LEA     PAREN2,A1
    JSR     PRINTLINE
    RTS

CHECKDATA
    CMP.B   #%111,D6
    BNE     RETURN
    CMP.B   #%000,D5
    BEQ     CHECKDATAW
    CMP.B   #%001,D5
    BEQ     CHECKDATAL
    CMP.B   #%100,D5
    BEQ     CHECKDATAIMM
    BRA     DONE            **********INVALID********************************************************************

CHECKDATAW
    MOVE.B  #4,D4
    ADDA.W  #2,A6
    LEA     DOLLA,A1
    JSR     PRINTLINE
    
    JSR     PRINTTOHEX
    RTS
        
CHECKDATAL
    MOVE.B  #8,D4
    ADDA.W  #2,A6
    LEA     DOLLA,A1
    JSR     PRINTLINE
    MOVE.B  #8,D0
    JSR     PRINTTOHEX
    RTS
    
CHECKDATAIMM
    LEA     POUND,A1
    JSR     PRINTLINE
    LEA     DOLLA,A1
    JSR     PRINTLINE
    ADDA.W  #2,A6
    JSR     PRINTTOHEX
    RTS
    
    
PRINTTOHEX
    JSR     GETSIZE
    CLR.L   D2
    CLR.L   D1
PRINTLOOP
    CMP.B   D4,D2
    BEQ     RETURN
    JSR     ROTATE

    MOVE.B  D5,D3
    AND.B   #$0F,D3
    CMPI.B  #9,D3
    BGT     PRINTLETTER
    
    ADDI.B  #$30,D3
    MOVE.B  D3,D1
    MOVE.B  #6,D0
    TRAP    #15
    
    ADDI.B  #1,D2
    ADD.B   #0,(A6)+
    BRA     PRINTLOOP
    
PRINTLETTER
    ADDI.B  #$37,D3
    MOVE.B  D3,D1
    MOVE.B  #6,D0
    TRAP    #15
    ADDI.B  #1,D2
    ADD.B   #0,(A6)+
    BRA     PRINTLOOP

GETSIZE
    CMP.B   #2,D4
    BEQ     GETBYTE
    CMP.B   #4,D4
    BEQ     GETWORD
    CMP.B   #8,D4
    BEQ     GETLONG
    BRA     DONE            *****INVALID*****
    
GETBYTE
    MOVE.B  (A6),D5
    RTS
    
GETWORD
    MOVE.W  (A6),D5
    RTS
    
GETLONG
    MOVE.L  (A6),D5
    RTS

ROTATE
    CMP.B   #2,D4
    BEQ     ROTATEBYTE
    CMP.B   #4,D4
    BEQ     ROTATEWORD
    CMP.B   #8,D4
    BEQ     ROTATELONG
    BRA     DONE        *****INVALID*****
    
ROTATEBYTE
    ROL.B   #4,D5
    RTS
    
ROTATEWORD
    ROL.W   #4,D5
    RTS
    
ROTATELONG
    ROL.L   #4,D5
    RTS
    
PRINTLINE    
    MOVE.B  #14,D0
    TRAP    #15
    RTS


DONE

    SIMHALT

* Put variables and constants here
        
CR          EQU     $0D
LF          EQU     $0A

WELCOME     DC.B        'WELCOME TO OUR DISSASSEMBLER!',CR,LF,0
STARTADD    DC.B        'Enter Starting Input Address:',CR,LF,0
ENDADD      DC.B        'Enter Ending Input Address:',CR,LF,0
BYTEMSG     DC.B        '.B ',0
WORDMSG     DC.B        '.W ',0
LONGMSG     DC.B        '.L ',0
MOVEMSG     DC.B        'MOVE',0
DIVSMSG     DC.B        'DIVS',0
ADDMSG      DC.B        'ADD',0
ADDAMASG    DC.B        'ADDA',0
SUBMSG      DC.B        'SUB',0
SUBAMSG     DC.B        'SUBA',0
SUBIMSG     DC.B        'SUBI',0
MULSMSG     DC.B        'MULS',0
LEAMSG      DC.B        'LEA',0
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
*WHAT I ADDED CUZ WE NO HAVE
SPACE    DC.B        ' ',0
CMPIMSG  DC.B        'CMPI',0

*

TXTD    DC.B    'D', 0
TXTA    DC.B    'A', 0
PAREN1  DC.B    '(', 0
PAREN2  DC.B    ')', 0
PLUS    DC.B    '+', 0
MINUS   DC.B    '-', 0
COMMA   DC.B    ',',0
DOLLA   DC.B    '$',0
POUND   DC.B    '#',0

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
