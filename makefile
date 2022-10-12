
BIN_LIB=CMPSYS
LIBLIST=$(BIN_LIB) CLV1
SHELL=/QOpenSys/usr/bin/qsh

all: events01.rpgle clevents01.clp

%.rpgle:
	system -s "CHGATR OBJ('/home/CLV/events/qrpglesrc/$*.rpgle') ATR(*CCSID) VALUE(1252)"
	liblist -a $(LIBLIST);\
	system "CRTBNDRPG PGM($(BIN_LIB)/$*) SRCSTMF('/home/CLV/events/qrpglesrc/$*.rpgle') DBGVIEW(*ALL) OPTION(*EVENTF)"

%.clp:
	system -s "CHGATR OBJ('/home/CLV/events/qclsrc/$*.clp') ATR(*CCSID) VALUE(1252)"
	liblist -a $(LIBLIST);\
	system "CRTBNDCL PGM($(BIN_LIB)/$*) SRCSTMF('/home/CLV/events/qclsrc/$*.clp') DBGVIEW(*SOURCE) OPTION(*EVENTF)"
