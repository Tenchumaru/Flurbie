%{
#include <cstdio>
#include <cstring>
#include "assembler.h"

int yylex();
void yyerror(char const* message);

#pragma warning(push)
#pragma warning(disable: 4127 4244 4702)
%}

%union {
	int value;
	char* id;
}

%token INT NOP
%token <value> OP REG VALUE ASR LSR SHL
%token <id> ID
%left '+' '-'
%left '&' '|' '^'
%left '*' '/' '%'
%precedence NEG /* negation:  unary minus */
%type <value> op expr shift optexpr

%%

input:
%empty
| input line '\n'
;

line:
%empty
| '.' '=' expr { set_ip($3); }
| '.' INT expr { add_value($3); }
| ID ':' { add_symbol($1); }
| ID '=' expr { add_symbol($1, $3); }
| NOP { add_immediate(0x80000000, 0, 0); }
| op REG ',' expr { add_immediate($1, $2, $4); }
| op REG ',' REG ',' REG shift { add_register($1, $2, $4, $6, $7); }
| op REG ',' '[' REG optexpr ']' { add_from_memory($1, $2, $5, $6); }
| op '[' REG optexpr ']' ',' REG { add_to_memory($1, $3, $4, $7); }
;

op:
OP { $$= $1; }
| OP '?' ID { $$= compose_non_zero($1, $3); }
| OP '!' ID { $$= compose_zero($1, $3); }
;

expr:
VALUE                { $$= $1;            }
| ID                 { $$= get_value($1); }
| expr '+' expr      { $$= $1 + $3;       }
| expr '-' expr      { $$= $1 - $3;       }
| expr '&' expr      { $$= $1 & $3;       }
| expr '|' expr      { $$= $1 | $3;       }
| expr '^' expr      { $$= $1 ^ $3;       }
| expr '*' expr      { $$= $1 * $3;       }
| expr '/' expr      { $$= $1 / $3;       }
| expr '%' expr      { $$= $1 % $3;       }
| '-' expr %prec NEG { $$= -$2;           }
| '(' expr ')'       { $$= $2;            }
;

shift:
%empty { $$= 0; }
| SHL expr { $$= compose_shift(1, $2); }
| LSR expr { $$= compose_shift(2, $2); }
| ASR expr { $$= compose_shift(3, $2); }
;

optexpr:
%empty { $$= 0; }
| ',' expr { $$= $2; }
;

%%
#pragma warning(pop)

void yyerror(char const* message) {
	fprintf(stderr, "problem: %s\n", message);
}

extern FILE *yyin, *yyout;
int pc_index= 30;

static int usage(char const* prog) {
	fprintf(stderr, "usage: %s [-p N] [input.s [output.hex]]\n", prog);
	fprintf(stderr, "\t-p N\tset the PC register index to N (default 30)\n", prog);
	return 2;
}

int main(int argc, char* argv[]) {
	// Set the program name.
	char const *prog= strrchr(argv[0], '\\');
	if(prog)
		++prog;
	else
		prog= argv[0];

	// Collect the options.
	while(argc > 1 && argv[1][0] == '-' && argv[1][1] != '\0') {
		switch(argv[1][1]) {
		case 'p':
			// Set PC register index.
			pc_index= argc > 2 ? atoi(argv[2]) : 0;
			if(pc_index < 1 || pc_index >= 32) {
				fprintf(stderr, "%s: invalid PC index\n", prog);
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
	if(argc > 1) {
		if(strcmp("-", argv[1]) && fopen_s(&yyin, argv[1], "rt")) {
			fprintf(stderr, "%s: cannot open '%s' for reading\n", prog, argv[1]);
			return 1;
		}
		if(argc > 2) {
			if(fopen_s(&yyout, argv[2], "wt")) {
				fprintf(stderr, "%s: cannot open '%s' for writing\n", prog, argv[2]);
				return 1;
			}
		}
	}

	// Print the PC register index and parse the input.
	fprintf(stderr, "The PC register index is %d.\n", pc_index);
	return yyparse();
}
