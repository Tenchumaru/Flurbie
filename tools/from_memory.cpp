#include <crtdbg.h>
#include <cstdlib>
#include <fstream>
#include <iostream>
#include <iomanip>

int main(int argc, char* argv[]) {
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
	char s[9]= {};
	/*
		2 -> 6,7
		4 -> 4,5
		6 -> 2,3
		8 -> 0,1
	*/
	for(int i= 2; fin >> std::hex >> s[8 - i] >> s[9 - i]; i += 2) {
		if(i % 8 == 0) {
			i= 0;
			fout << s << '\n';
		}
	}
	return 0;
}
