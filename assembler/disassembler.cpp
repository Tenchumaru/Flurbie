#include <crtdbg.h>
#include <iostream>
#include <fstream>

static char const* operations[]= {
	"add", "addc", "sub", "subb",
	"mul", "umul", "div", "udiv",
	"and", "nand", "or", "nor",
	"xor", "xnor", nullptr, "cx"
};

static char const* mem_operations[]= {
	"ld", "ldi", "xorih", "st"
};

template<unsigned highest, unsigned lowest>
static unsigned extract_field(unsigned value) {
	unsigned ones= static_cast<unsigned>(-1);
	unsigned mask= ones << lowest;
	unsigned mask2= ones << (highest + 1);
	value &= mask & ~mask2;
	return value >> lowest;
}

template<unsigned bit>
static bool extract_field(unsigned value) {
	return (value & (1 << bit)) != 0;
}

template<unsigned highest>
static signed extract_signed(unsigned value) {
	unsigned ones= static_cast<unsigned>(-1);
	unsigned mask= ones << (highest + 1);
	bool is_negative= (value & (1 << highest)) != 0;
	return is_negative ? mask | value : value & ~mask;
}

int main(int argc, char* argv[]) {
	// Creat the input and output file streams.
	std::ifstream fsin;
	std::istream& fin= argc < 2 ? std::cin : (fsin.open(argv[1]), fsin);
	if(!fin) {
		std::cerr << "cannot open " << argv[1] << std::endl;
		return 1;
	}
	std::ofstream fsout;
	std::ostream& fout= argc < 3 ? std::cout : (fsout.open(argv[2]), fsout);
	if(!fout) {
		std::cerr << "cannot open " << argv[2] << std::endl;
		return 1;
	}

	// Disassemble the input to the output.
	unsigned value;
	while(fin >> std::hex >> value) {
		bool is_active= extract_field<31>(value);
		unsigned flags= extract_field<30, 27>(value);
		if(is_active && flags == 0)
			// All instructions with an active flag mask of zero map to NOP.
			fout << "nop";
		else {
			unsigned operation= extract_field<26, 23>(value);
			unsigned mem_operation= extract_field<17, 16>(value);
			if(operation == 14) {
				// MEM
				fout << mem_operations[mem_operation];
			} else {
				// STANDARD or SPECIAL
				fout << operations[operation];
			}
			if(flags != 0) {
				char active= is_active ? '?' : '!';
				fout << active;
				if(flags & 0x8)
					fout << 'c';
				if(flags & 0x4)
					fout << 'n';
				if(flags & 0x2)
					fout << 'v';
				if(flags & 0x1)
					fout << 'z';
			}
			fout << ' ';
			if(operation == 14) {
				// MEM
				unsigned r= extract_field<22, 18>(value);
				if(mem_operation == 0) {
					// ld
					unsigned ar= extract_field<15, 11>(value);
					signed adjustment= extract_signed<10>(value);
					fout << 'r' << r << ", [r" << ar << ", " << adjustment << "]";
				} else if(mem_operation == 1) {
					// ldi
					signed immediate_value= extract_signed<15>(value);
					fout << 'r' << r << ", " << immediate_value;
				} else if(mem_operation == 2) {
					// ori
					unsigned immediate_value= extract_field<15, 0>(value);
					fout << 'r' << r << ", " << immediate_value;
				} else if(mem_operation == 3) {
					// st
					unsigned ar= extract_field<15, 11>(value);
					signed adjustment= extract_signed<10>(value);
					fout << "[r" << ar << ", " << adjustment << "], r" << r;
				}
			} else if(operation == 15) {
				// SPECIAL
				unsigned dr= extract_field<22, 18>(value);
				unsigned sr1= extract_field<16, 12>(value);
				unsigned sr2= extract_field<11, 7>(value);
				unsigned ar= extract_field<6, 2>(value);
				fout << 'r' << dr << ", [r" << ar << "], r" << sr1 << ", r" << sr2;
			} else {
				// STANDARD
				unsigned dr= extract_field<22, 18>(value);
				bool is_register= extract_field<17>(value);
				unsigned sr1= extract_field<16, 12>(value);
				if(is_register) {
					unsigned sr2= extract_field<11, 7>(value);
					unsigned shift_operation= extract_field<6, 5>(value);
					fout << 'r' << dr << ", r" << sr1 << ", r" << sr2;
					unsigned adjustment= extract_field<4, 0>(value);
					if(adjustment != 0) {
						switch(shift_operation) {
						case 0: // add signed
							fout << ", " << extract_signed<4>(value);
							break;
						case 1: // left
							fout << " << " << adjustment;
							break;
						case 2: // logical right
							fout << " >> " << adjustment;
							break;
						case 3: // arithmetic right
							fout << " >>> " << adjustment;
							break;
						}
					}
				} else {
					// immediate operand
					fout << 'r' << dr << ", r" << sr1 << ", " << extract_signed<11>(value);
				}
			}
		}
		fout << std::endl;
	}
	return 0;
}
