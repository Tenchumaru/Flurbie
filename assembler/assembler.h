#pragma once

void set_ip(int value);
void add_value(int value);
void add_symbol(char* symbol);
void add_symbol(char* symbol, int value);
int get_value(char* symbol);
int compose_non_zero(int operation, char* flags);
int compose_zero(int operation, char* flags);
int compose_shift(int shift_type, int adjustment);
void add_immediate(int operation, int target_register, int value);
void add_register(int operation, int target_register, int left_register, int right_register, int shift_value);
void add_from_memory(int operation, int target_register, int address_register, int adjustment);
void add_to_memory(int operation, int address_register, int source_register, int adjustment);
