PGM PARM(&LIBRARY &PROGRAM &COMMAND)

DCL &LIBRARY TYPE(*CHAR) LEN(10)
DCL &PROGRAM TYPE(*CHAR) LEN(10) 
DCL &COMMAND TYPE(*CHAR) LEN(10)
DCL &ERROR TYPE(*LGL)

/* It tries to compile the program, but without generating the */
/* program object. */
CRTBNDRPG PGM(&LIBRARY/&PROGRAM) SRCFILE(&LIBRARY/QRPGLESRC) +
SRCMBR(&PROGRAM) OPTION(*EVENTF *NOGEN) TGTRLS(*CURRENT)
MONMSG CPF0000

/* Then I use EVENTS to add my own compilation messages to the */
/* EVFEVENT file. Also, the program returns an error in case of */
/* it have to */
CALL CLV1/EVENTS01 PARM(&LIBRARY &PROGRAM &ERROR)
MONMSG CPF0000

/* If there were an error, it tries to compile the program */
IF (&ERROR *EQ '0') DO
    CRTBNDRPG PGM(&LIBRARY/&PROGRAM) SRCFILE(&LIBRARY/QRPGLESRC) +
    SRCMBR(&PROGRAM) OPTION(*EVENTF) TGTRLS(*CURRENT)
    MONMSG CPF0000
ENDDO


ENDPGM