!IF "$(Configuration)" == "Debug"
CFLAGS=-nologo -D_DEBUG -W4 -WX -Od -Zc:wchar_t -Zc:forScope -ZI -EHsc -MDd
!ELSEIF "$(Configuration)" == "Release"
CFLAGS=-nologo -DNDEBUG -W4 -WX -O2 -Zc:wchar_t -Zc:forScope -EHsc -MD
!ELSE
!ERROR No configuration specified.
!ENDIF

RM=DEL /F /Q

all: $(Configuration)/as.exe $(Configuration)/das.exe $(Configuration)/from_mem.exe $(Configuration)/to_mem.exe $(Configuration)/mktest.exe

$(Configuration)/as.exe: $(Configuration)/parser.obj $(Configuration)/scanner.obj $(Configuration)/assembler.obj
	cl $(CFLAGS) -Fe$@ $**

$(Configuration)/parser.obj: parser.cpp assembler.h
	cl $(CFLAGS) -c -Fo$@ parser.cpp

$(Configuration)/scanner.obj: scanner.cpp scanner.h
	cl $(CFLAGS) -c -Fo$@ scanner.cpp

$(Configuration)/assembler.obj: assembler.cpp assembler.h scanner.h
	cl $(CFLAGS) -c -Fo$@ assembler.cpp

parser.cpp: parser.y
	win_bison --verbose --defines=parser.h --output=parser.cpp parser.y

scanner.cpp: scanner.l parser.cpp
	win_flex --case-insensitive --fast --wincompat --outfile=scanner.cpp scanner.l

$(Configuration)/das.exe: $(Configuration)/disassembler.obj
	cl $(CFLAGS) -Fe$@ $**

$(Configuration)/disassembler.obj: disassembler.cpp
	cl $(CFLAGS) -c -Fo$@ disassembler.cpp

$(Configuration)/from_mem.exe: $(Configuration)/from_memory.obj
	cl $(CFLAGS) -Fe$@ $**

$(Configuration)/from_memory.obj: from_memory.cpp
	cl $(CFLAGS) -c -Fo$@ from_memory.cpp

$(Configuration)/to_mem.exe: $(Configuration)/to_memory.obj
	cl $(CFLAGS) -Fe$@ $**

$(Configuration)/to_memory.obj: to_memory.cpp
	cl $(CFLAGS) -c -Fo$@ to_memory.cpp

$(Configuration)/mktest.exe: $(Configuration)/maketest.obj
	cl $(CFLAGS) -Fe$@ $**

$(Configuration)/maketest.obj: maketest.cpp scanner.h
	cl $(CFLAGS) -c -Fo$@ maketest.cpp

test: $(Configuration)/mktest.exe $(Configuration)/das.exe $(Configuration)/as.exe
	$(Configuration)\mktest.exe $(Configuration)\l.txt 9999 9 | $(Configuration)\das.exe | $(Configuration)\as.exe > $(Configuration)\r.txt
	fc $(Configuration)\l.txt $(Configuration)\r.txt

clean:
	IF EXIST $(Configuration) DEL /F /Q $(Configuration)
	IF EXIST *.obj DEL /F /Q *.obj
	IF EXIST as.* DEL /F /Q as.*
	IF EXIST das.* DEL /F /Q das.*
	IF EXIST from_mem.* DEL /F /Q from_mem.*
	IF EXIST to_mem.* DEL /F /Q to_mem.*
	IF EXIST mktest.* DEL /F /Q mktest.*
	IF EXIST vc100.* DEL /F /Q vc100.*
	IF EXIST parser.cpp DEL /F /Q parser.cpp
	IF EXIST parser.h DEL /F /Q parser.h
	IF EXIST parser.output DEL /F /Q parser.output
	IF EXIST scanner.cpp DEL /F /Q scanner.cpp
