#include <crtdbg.h>
#include <iostream>

static char const* opcodes[]= {
	"add", "addc", "sub", "subb",
	"mul", "umul", "div", "udiv",
	"and", "or", "nand", "nor",
	"xor", "xnor", "cx", "opf"
};

int main(int argc, char* argv[]) {
	argc, argv;
	unsigned value;
	while(std::cin >> std::hex >> value) {
		if((value & 0xf8000000) == 0x80000000)
			std::cout << "nop";
		else {
			std::cout << opcodes[(value & 0x07800000) >> 23];
			if(value & 0x78000000) {
				char active= value & 0x80000000 ? '?' : '!';
				std::cout << active;
				if(value & 0x40000000)
					std::cout << 'c';
				if(value & 0x20000000)
					std::cout << 'n';
				if(value & 0x10000000)
					std::cout << 'v';
				if(value & 0x08000000)
					std::cout << 'z';
			}
			std::cout << ' ';
			unsigned dr= (value & 0x007c0000) >> 18;
			if(value & 0x00020000) {
				unsigned sr1= (value & 0x0001f000) >> 12;
				if(value & 0x00000800) {
					// indirect
					unsigned adjustment= value & 0x000003ff;
					if(adjustment & 0x00000200)
						adjustment |= 0xfffffc00;
					if(value & 0x00000400) {
						// to memory
						std::cout << "[r" << dr << ", " << (int)adjustment << "], r" << sr1;
					} else {
						// from memory
						std::cout << "r" << dr << ", [r" << sr1 << ", " << (int)adjustment << "]";
					}
				} else {
					// two source registers with shift
					unsigned sr2= (value & 0x000007c0) >> 6;
					std::cout << 'r' << dr << ", r" << sr1 << ", r" << sr2;
					unsigned shift= 1 + (value & 0x0000000f);
					switch(value & 0x00000030) {
					case 0:
						break;
					case 0x10: // left
						std::cout << " << " << shift;
						break;
					case 0x20: // logical right
						std::cout << " >> " << shift;
						break;
					case 0x30: // arithmetic right
						std::cout << " >>> " << shift;
						break;
					}
				}
			} else {
				// immediate
				std::cout << 'r' << dr;
				if(value & 0x00010000)
					value |= 0xffff0000;
				else
					value &= 0x0000ffff;
				std::cout << ", #" << (int)value;
			}
		}
		std::cout << std::endl;
	}
	return 0;
}
