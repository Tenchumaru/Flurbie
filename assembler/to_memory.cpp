#include <crtdbg.h>
#include <cstdlib>
#include <fstream>
#include <iostream>
#include <iomanip>

static int usage(char const* prog) {
	std::cerr << "usage: " << prog << " [-f val] [-p N] [input.s [output.hex]]" << std::endl;
	std::cerr << "\t-f val\tfill empty space with val (default -1)" << std::endl;
	std::cerr << "\t-p N\tpad the output to N bytes" << std::endl;
	return 2;
}

static int reverse(int value) {
	return ((value >> 24) & 0xff) | ((value >> 8) & 0xff00) | ((value << 8) & 0xff0000) | ((value << 24) & 0xff000000);
}

int main(int argc, char* argv[]) {
	// Set the program name.
	char const* prog= strrchr(argv[0], '\\');
	if(prog)
		++prog;
	else
		prog= argv[0];

	// Collect the options.
	unsigned fill= ~0u, padding= 0;
	while(argc > 1 && argv[1][0] == '-' && argv[1][1] != '\0') {
		switch(argv[1][1]) {
		case 'f':
			// Set fill value.
			if(argc < 3) {
				std::cerr << prog << ": padding not given" << std::endl;
				return 1;
			}
			fill= strtoul(argv[2], nullptr, 0);
			fill= reverse(fill);
			--argc, ++argv;
			break;
		case 'p':
			// Pad the output.
			padding= argc > 2 ? strtoul(argv[2], nullptr, 0) : 0;
			if(padding < 1) {
				std::cerr << prog << ": invalid padding" << std::endl;
				return 1;
			}
			--argc, ++argv;
			break;
		default:
			return usage(prog);
		}
		--argc, ++argv;
	}

	// Set the input and output files.
	std::ifstream fsin;
	std::istream& fin= argc < 2 ? std::cin : (fsin.open(argv[1]), fsin);
	if(!fin) {
		std::cerr << "cannot open '" << argv[1] << "' for reading" << std::endl;
		return 1;
	}
	std::ofstream fsout;
	std::ostream& fout= argc < 3 ? std::cout : (fsout.open(argv[2]), fsout);
	if(!fout) {
		std::cerr << "cannot open '" << argv[2] << "' for writing" << std::endl;
		return 1;
	}

	unsigned max_address= 0, address, value;
	fin >> std::hex;
	fout << std::hex << std::setfill('0');
	while(fin >> address >> value) {
		while(max_address < address) {
			fout << std::setw(8) << fill;
			max_address += 4;
		}
		fout << std::setw(8) << reverse(value);
		max_address += 4;
	}

	// If there is any padding, use it.
	while(address += 4, address < padding) {
		fout << std::setw(8) << fill;
	}

	return 0;
}
