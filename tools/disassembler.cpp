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
	"ldi", "xorih", "ld", "st"
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
			int is_memory= extract_field<17>(value);
			int is_not_load= is_memory ? extract_field<11>(value) : extract_field<16>(value);
			unsigned mem_operation= (is_memory << 1) | is_not_load;
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
				unsigned tr= extract_field<22, 18>(value);
				if(mem_operation == 0) {
					// ldi
					signed immediate_value= extract_signed<15>(value);
					fout << 'r' << tr << ", " << immediate_value;
				} else if(mem_operation == 1) {
					// xorih
					unsigned immediate_value= extract_field<15, 0>(value);
					fout << 'r' << tr << ", " << immediate_value;
				} else if(mem_operation == 2) {
					// ld
					unsigned lr= extract_field<16, 12>(value);
					signed adjustment= extract_signed<10>(value);
					fout << 'r' << tr << ", [r" << lr << ", " << adjustment << "]";
				} else if(mem_operation == 3) {
					// st
					unsigned lr= extract_field<16, 12>(value);
					signed adjustment= extract_signed<10>(value);
					fout << "[r" << tr << ", " << adjustment << "], r" << lr;
				}
			} else if(operation == 15) {
				// SPECIAL
				unsigned tr= extract_field<22, 18>(value);
				unsigned lr= extract_field<16, 12>(value);
				unsigned rr= extract_field<11, 7>(value);
				unsigned cr= extract_field<6, 2>(value);
				fout << 'r' << tr << ", [r" << lr << "], r" << cr << ", r" << rr;
			} else {
				// STANDARD
				unsigned tr= extract_field<22, 18>(value);
				bool is_register= extract_field<17>(value);
				unsigned lr= extract_field<16, 12>(value);
				if(is_register) {
					unsigned rr= extract_field<11, 7>(value);
					unsigned shift_operation= extract_field<6, 5>(value);
					fout << 'r' << tr << ", r" << lr << ", r" << rr;
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
					fout << 'r' << tr << ", r" << lr << ", " << extract_signed<11>(value);
				}
			}
		}
		fout << std::endl;
	}
	return 0;
}
