#include <crtdbg.h>
#include <cstdlib>
#include <fstream>
#include <iostream>
#include <iomanip>
#include "scanner.h"

int main(int argc, char* argv[]) {
	std::ofstream fs;
	std::ostream& fout= argc < 2 ? std::cout : (fs.open(argv[1]), fs);
	if(!fout) {
		std::cerr << "cannot open " << argv[1] << std::endl;
		return 1;
	}
	int count= argc < 3 ? 999 : atoi(argv[2]);
	if(&fout != &std::cout)
		fout << std::hex;
	std::cout << std::showbase << std::hex;
	srand(argc < 4 ? 1 : atoi(argv[3]));
	for(int i= 0; i < count; ++i) {
		int value= (rand() << 20) | (rand() << 10) | rand();
		if((value & 0xf8000000) == 0x80000000)
			value= 0x80000000; // Produce a single nop.
		if((value & CX) < (14 << 23) && (value & 0x20000) && (value & 0x1f) == 0)
			value &= 0xfffffff80; // Produce no shift operation for no adjustment.
		if((value & CX) == CX)
			value &= ~0x00020003; // Zero unused bits.
		if(&fout != &std::cout)
			fout << "0x" << std::setfill('0') << std::setw(8) << (i * 4) << " 0x" << std::setfill('0') << std::setw(8) << value << std::endl;
		std::cout << value << std::endl;
	}
	return 0;
}
