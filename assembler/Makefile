#CFLAGS=-nologo -DNDEBUG -W4 -WX -O2 -Zc:wchar_t -Zc:forScope -EHsc -MD
CFLAGS=-nologo -D_DEBUG -W4 -WX -Od -Zc:wchar_t -Zc:forScope -ZI -EHsc -MDd

all: as.exe das.exe from_mem.exe to_mem.exe mktest.exe

as.exe: parser.obj scanner.obj assembler.obj
	cl $(CFLAGS) /Feas.exe parser.obj scanner.obj assembler.obj

parser.obj: parser.cpp
	cl $(CFLAGS) -c parser.cpp

scanner.obj: scanner.cpp
	cl $(CFLAGS) -c scanner.cpp

assembler.obj: assembler.cpp assembler.h
	cl $(CFLAGS) -c assembler.cpp

parser.cpp: parser.y assembler.h
	win_bison --defines=parser.h --output=parser.cpp parser.y

scanner.cpp: scanner.l
	win_flex --case-insensitive --fast --wincompat --outfile=scanner.cpp scanner.l

das.exe: disassembler.obj
	cl $(CFLAGS) /Fedas.exe disassembler.obj

disassembler.obj: disassembler.cpp
	cl $(CFLAGS) -c disassembler.cpp

from_mem.exe: from_memory.obj
	cl $(CFLAGS) /Fefrom_mem.exe from_memory.obj

from_memory.obj: from_memory.cpp
	cl $(CFLAGS) -c from_memory.cpp

to_mem.exe: to_memory.obj
	cl $(CFLAGS) /Feto_mem.exe to_memory.obj

to_memory.obj: to_memory.cpp
	cl $(CFLAGS) -c to_memory.cpp

mktest.exe: maketest.obj
	cl $(CFLAGS) /Femktest.exe maketest.obj

maketest.obj: maketest.cpp
	cl $(CFLAGS) -c maketest.cpp

test: mktest.exe das.exe as.exe
	mktest.exe l.txt 9999 9 | das.exe | as.exe > r.txt
	fc l.txt r.txt

clean:
	IF EXIST *.obj DEL /F /Q *.obj
	IF EXIST as.* DEL /F /Q as.*
	IF EXIST das.* DEL /F /Q das.*
	IF EXIST from_mem.* DEL /F /Q from_mem.*
	IF EXIST to_mem.* DEL /F /Q to_mem.*
	IF EXIST mktest.* DEL /F /Q mktest.*
	IF EXIST vc100.* DEL /F /Q vc100.*
	IF EXIST parser.cpp DEL /F /Q parser.cpp
	IF EXIST parser.h DEL /F /Q parser.h
	IF EXIST scanner.cpp DEL /F /Q scanner.cpp
