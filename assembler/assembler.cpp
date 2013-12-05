#include <crtdbg.h>
#include <map>
#include <string>
#include "assembler.h"

extern FILE *yyin, *yyout;

static int const MaximumImmediate= 0x0001ffff;
static int const MaximumAdjustment= 0x000003ff;

static std::map<std::string, int> the_map;
static int ip;

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

int compose_non_zero(int operation, char* flags) {
	return 0x80000000 | compose_zero(operation, flags);
}

int compose_zero(int operation, char* flags) {
	for(char const *p= flags; *p; ++p) {
		switch(tolower(*p)) {
		case 'c':
			operation |= 0x40000000;
			break;
		case 'n':
			operation |= 0x20000000;
			break;
		case 'v':
			operation |= 0x10000000;
			break;
		case 'z':
			operation |= 0x08000000;
			break;
		default:
			fprintf(stderr, "invalid flags '%s'\n", flags);
			free(flags);
			return 0x80000000;
		}
	}
	free(flags);
	return operation;
}

int compose_shift(int shift_type, int adjustment) {
	if(adjustment < 1 || adjustment > 16) {
		fprintf(stderr, "invalid shift %d\n", adjustment);
		return 0x80000000;
	}
	return (shift_type << 4) | ((adjustment - 1) & 0x0000000f);
}

void add_immediate(int operation, int target_register, int value) {
	if(value < int(~MaximumImmediate) || value > MaximumImmediate) {
		fprintf(stderr, "invalid value %d\n", value);
		operation= 0x80000000;
	} else {
		operation |= target_register << 18;
		operation |= value & MaximumImmediate;
	}
	fprintf(yyout, "0x%08x 0x%08x\n", ip, operation);
	ip += 4;
}

void add_register(int operation, int target_register, int left_register, int right_register, int shift_value) {
		operation |= target_register << 18;
		operation |= 1 << 17;
		operation |= left_register << 12;
		operation |= right_register << 6;
		operation |= shift_value;
		fprintf(yyout, "0x%08x 0x%08x\n", ip, operation);
		ip += 4;
}

void add_from_memory(int operation, int target_register, int address_register, int adjustment) {
	if(adjustment < int(~MaximumAdjustment) || adjustment > MaximumAdjustment) {
		fprintf(stderr, "invalid adjustment %d\n", adjustment);
		operation= 0x80000000;
	} else {
		operation |= target_register << 18;
		operation |= 1 << 17;
		operation |= address_register << 12;
		operation |= 1 << 11;
		operation |= adjustment & MaximumAdjustment;
	}
	fprintf(yyout, "0x%08x 0x%08x\n", ip, operation);
	ip += 4;
}

void add_to_memory(int operation, int address_register, int adjustment, int source_register) {
	if(adjustment < int(~MaximumAdjustment) || adjustment > MaximumAdjustment) {
		fprintf(stderr, "invalid adjustment %d\n", adjustment);
		operation= 0x80000000;
	} else {
		operation |= address_register << 18;
		operation |= 1 << 17;
		operation |= source_register << 12;
		operation |= 3 << 10;
		operation |= adjustment & MaximumAdjustment;
	}
	fprintf(yyout, "0x%08x 0x%08x\n", ip, operation);
	ip += 4;
}
