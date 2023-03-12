
BIN_LIB=CMPSYS
LIBLIST=$(BIN_LIB) CLV1
SHELL=/QOpenSys/usr/bin/qsh

all: events.rpgle clevents.clle

%.rpgle:
	system -s "CHGATR OBJ('/home/CLV/events/qrpglesrc/$*.rpgle') ATR(*CCSID) VALUE(1252)"
	liblist -a $(LIBLIST);\
	system "CRTBNDRPG PGM($(BIN_LIB)/$*) SRCSTMF('/home/CLV/events/qrpglesrc/$*.rpgle') DBGVIEW(*ALL) OPTION(*EVENTF)"

%.clle:
	system -s "CHGATR OBJ('/home/CLV/events/qclsrc/$*.clle') ATR(*CCSID) VALUE(1252)"
	liblist -a $(LIBLIST);\
	system "CRTBNDCL PGM($(BIN_LIB)/$*) SRCSTMF('/home/CLV/events/qclsrc/$*.clle') DBGVIEW(*SOURCE) OPTION(*EVENTF)"
