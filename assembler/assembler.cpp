#include <crtdbg.h>
#include <map>
#include <string>
#include "scanner.h"
#include "assembler.h"

extern FILE *yyin, *yyout;

static std::map<std::string, int> the_map;
static int ip;

static int as_mem_op(int value) {
	return value & (0xe06 << 15);
}

template<unsigned highest>
static bool is_in_bit_range(int value) {
	int upper_bound= 1 << highest;
	int min_value = -upper_bound;
	return value >= min_value && value < upper_bound;
}

template<unsigned highest, unsigned lowest>
static int as_field(int value) {
	unsigned mask= (2 << highest) - 1;
	unsigned u= static_cast<unsigned>(value);
	u= (u << lowest) & mask;
	return static_cast<int>(u);
}

void set_ip(int value) {
	ip= value;
}

void add_value(int value) {
	fprintf(yyout, "0x%08x 0x%08x\n", ip, value);
	ip += 4;
}

void add_symbol(char* symbol) {
	the_map[symbol]= ip;
	free(symbol);
}

void add_symbol(char* symbol, int value) {
	the_map[symbol]= value;
	free(symbol);
}

int get_value(char* symbol) {
	std::string s= symbol;
	free(symbol);
	return the_map[s];
}

int compose_non_zero(char* flags) {
	return 0x80000000 | compose_zero(flags);
}

int compose_zero(char* flags) {
	int condition= 0;
	for(char const *p= flags; *p; ++p) {
		switch(tolower(*p)) {
		case 'c':
			condition |= 0x40000000;
			break;
		case 'n':
			condition |= 0x20000000;
			break;
		case 'v':
			condition |= 0x10000000;
			break;
		case 'z':
			condition |= 0x08000000;
			break;
		default:
			fprintf(stderr, "invalid flags '%s'\n", flags);
			free(flags);
			return 0x80000000;
		}
	}
	free(flags);
	return condition;
}

int compose_shift(int shift_type, int adjustment) {
	if(shift_type == 0 ? is_in_bit_range<4>(adjustment) : static_cast<unsigned>(adjustment) < 32) {
		return as_field<6, 5>(shift_type) | as_field<4, 0>(adjustment);
	} else {
		fprintf(stderr, "invalid shift %d\n", adjustment);
		return 0x80000000;
	}
}

void add_immediate(int operation, int target_register, int source_register, int value) {
	if(is_in_bit_range<11>(value)) {
		operation |= target_register << 18;
		operation |= source_register << 12;
		operation |= as_field<11, 0>(value);
	} else {
		fprintf(stderr, "invalid value %d\n", value);
		operation= 0x80000000;
	}
	fprintf(yyout, "0x%08x 0x%08x\n", ip, operation);
	ip += 4;
}

void add_register(int operation, int target_register, int left_register, int right_register, int shift_value) {
	operation |= target_register << 18;
	operation |= 1 << 17;
	operation |= left_register << 12;
	operation |= right_register << 7;
	operation |= shift_value;
	fprintf(yyout, "0x%08x 0x%08x\n", ip, operation);
	ip += 4;
}

void add_from_memory(int operation, int target_register, int address_register, int adjustment) {
	if(as_mem_op(operation) != LD) {
		fprintf(stderr, "invalid load operation %#x\n", operation);
		operation= 0x80000000;
	} else if(is_in_bit_range<10>(adjustment)) {
		operation |= target_register << 18;
		operation |= address_register << 11;
		operation |= as_field<10, 0>(adjustment);
	} else {
		fprintf(stderr, "invalid adjustment %d\n", adjustment);
		operation= 0x80000000;
	}
	fprintf(yyout, "0x%08x 0x%08x\n", ip, operation);
	ip += 4;
}

void add_immediate(int operation, int target_register, int value) {
	if(as_mem_op(operation) != LDI && as_mem_op(operation) != ORI) {
		fprintf(stderr, "invalid immediate operation %#x\n", operation);
		operation= 0x80000000;
	} else if(as_mem_op(operation) == LDI ? is_in_bit_range<15>(value) : static_cast<unsigned>(value) < (1 << 16)) {
		operation |= target_register << 18;
		operation |= as_field<15, 0>(value);
	} else {
		fprintf(stderr, "invalid value %d\n", value);
		operation= 0x80000000;
	}
	fprintf(yyout, "0x%08x 0x%08x\n", ip, operation);
	ip += 4;
}

void add_to_memory(int operation, int address_register, int adjustment, int source_register) {
	if(as_mem_op(operation) != ST) {
		fprintf(stderr, "invalid store operation %#x\n", operation);
		operation= 0x80000000;
	} else if(is_in_bit_range<10>(adjustment)) {
		operation |= source_register << 18;
		operation |= address_register << 11;
		operation |= as_field<10, 0>(adjustment);
	} else {
		fprintf(stderr, "invalid adjustment %d\n", adjustment);
		operation= 0x80000000;
	}
	fprintf(yyout, "0x%08x 0x%08x\n", ip, operation);
	ip += 4;
}

void add_special(int operation, int target_register, int address_register, int compare_register, int source_register) {
	if((operation & CX) != CX) {
		fprintf(stderr, "invalid special operation %#x\n", operation);
		operation= 0x80000000;
	} else {
		operation |= target_register << 18;
		operation |= compare_register << 12;
		operation |= source_register << 7;
		operation |= address_register << 2;
	}
	fprintf(yyout, "0x%08x 0x%08x\n", ip, operation);
	ip += 4;
}
