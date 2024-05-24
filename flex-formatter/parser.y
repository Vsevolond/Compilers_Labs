%{
#include <stdio.h>
#include "lexer.h"
#include <string.h>
#include <stdlib.h>
#include <stdbool.h>

#define INDENT_SIZE 2

int indent_level = 0;

void increase_indent() {
    indent_level++;
}

void decrease_indent() {
    if (indent_level > 0) {
        indent_level--;
    }
}

char* get_indent() {
    int total_spaces = indent_level * INDENT_SIZE;
    char* indent_str = (char*)malloc((total_spaces + 1) * sizeof(char));
    memset(indent_str, ' ', total_spaces);
    indent_str[total_spaces] = '\0';
    return indent_str;
}

%}

%define api.pure
%locations
%lex-param {yyscan_t scanner}
%parse-param {yyscan_t scanner}
%parse-param {long env[26]}

%union {
    char* ident;
    char* localType;
    float realConst;
    int integerConst;
    bool booleanConst;
}

%token TYPE_KW RECORD_KW END_KW VAR_KW BEGIN_KW NEW_KW WHILE_KW DO_KW IF_KW THEN_KW ELSE_KW POINTER_KW TO_KW
%token TYPE_ASSIGNMENT_OP VAR_ASSIGNMENT_OP DEREFERENCE_OP
%token DIV_OP MOD_OP AND_OP NOT_OP OR_OP ADDITION_OP SUBSTRACTION_OP MULTIPLICATION_OP DIVISION_OP
%token EQUAL_OP LESS_OP LESS_OR_EQUAL_OP GREATER_OP GREATER_OR_EQUAL_OP NOT_EQUAL_OP
%token DOT_SYM COMMA_SYM COLON_SYM SEMICOLON_SYM OPEN_BRACKET_SYM CLOSE_BRACKET_SYM
%token INTEGER_TYPE REAL_TYPE BOOLEAN_TYPE

%token <localType> LOCAL_TYPE
%token <integerConst> INTEGER_CONST
%token <realConst> REAL_CONST
%token <booleanConst> BOOLEAN_CONST
%token <ident> IDENT
%token <comment> COMMENT

%type <ident> program typeDefs varDefs statements
%type <ident> varsDef varNames varChain varType type
%type <ident> typeDef typeCommonDef typeExtendDef 
%type <ident> statement expr arithmExpr
%type <ident> cmpOp addOp mulOp
%type <ident> term factor const

%{
int yylex(YYSTYPE *yylval_param, YYLTYPE *yylloc_param, yyscan_t scanner);
void yyerror(YYLTYPE *loc, yyscan_t scanner, long env[26], const char *message);
%}

%%

program: 
    TYPE_KW { increase_indent(); } typeDefs VAR_KW varDefs BEGIN_KW statements { decrease_indent(); }END_KW DOT_SYM {
      printf("TYPE\n%s\nVAR\n%s\nBEGIN\n%s\nEND.\n", $3, $5, $7);
    };

typeDefs: 
    typeDef SEMICOLON_SYM {
      asprintf(&$$, "%s", $1); 
    }
    | typeDef SEMICOLON_SYM typeDefs {
      asprintf(&$$, "%s\n%s", $1, $3); 
    };

varDefs: 
    varsDef SEMICOLON_SYM { 
      asprintf(&$$, "%s", $1); 
    }
    | varsDef SEMICOLON_SYM varDefs { 
      asprintf(&$$, "%s\n%s", $1, $3); 
    };

varsDef: 
    varNames COLON_SYM varType { 
      char* indent = get_indent();
      asprintf(&$$, "%s%s : %s;", indent, $1, $3); 
    };

varNames: 
    IDENT { 
      asprintf(&$$, "%s", $1); 
    }
    | IDENT COMMA_SYM varNames { 
      asprintf(&$$, "%s, %s", $1, $3); 
    };

varChain: 
    IDENT { 
      asprintf(&$$, "%s", $1); 
    }
    | IDENT DOT_SYM varChain { 
      asprintf(&$$, "%s.%s", $1, $3); 
    };

varType: 
    type { 
      asprintf(&$$, "%s", $1); 
    }
    | POINTER_KW TO_KW type { 
      asprintf(&$$, "POINTER TO %s", $3); 
    };

type: 
    INTEGER_TYPE { 
      asprintf(&$$, "INTEGER"); 
    }
    | REAL_TYPE { 
      asprintf(&$$, "REAL"); 
    }
    | BOOLEAN_TYPE { 
      asprintf(&$$, "BOOLEAN"); 
    }
    | LOCAL_TYPE { 
      asprintf(&$$, "%s", $1); 
    };

typeDef: typeCommonDef | typeExtendDef;

typeCommonDef: 
    LOCAL_TYPE TYPE_ASSIGNMENT_OP RECORD_KW { increase_indent(); } varDefs { decrease_indent(); } END_KW {
      char* indent = get_indent();
      asprintf(&$$, "%s%s = RECORD\n%s\n%sEND;", indent, $1, $5, indent);
    };

typeExtendDef: 
    LOCAL_TYPE TYPE_ASSIGNMENT_OP RECORD_KW OPEN_BRACKET_SYM type CLOSE_BRACKET_SYM { increase_indent(); } varDefs { decrease_indent(); } END_KW {
      char* indent = get_indent();
      asprintf(&$$, "%s%s = RECORD(%s)\n%s\n%sEND;", indent, $1, $5, $8, indent);
    };

statements: 
    statement SEMICOLON_SYM {
      asprintf(&$$, "%s;", $1); 
    }
    | statement SEMICOLON_SYM statements { 
      asprintf(&$$, "%s;\n%s", $1, $3); 
    };

statement: 
    varChain VAR_ASSIGNMENT_OP expr {
      char* indent = get_indent();
      asprintf(&$$, "%s%s := %s", indent, $1, $3); 
    }
    | varChain DEREFERENCE_OP VAR_ASSIGNMENT_OP expr {
      char* indent = get_indent(); 
      asprintf(&$$, "%s%s^ := %s", indent, $1, $4); 
    }
    | NEW_KW OPEN_BRACKET_SYM varChain CLOSE_BRACKET_SYM {
      char* indent = get_indent();
      asprintf(&$$, "%sNEW(%s)", indent, $3); 
    }
    | IF_KW expr THEN_KW { increase_indent(); } statements ELSE_KW statements { decrease_indent(); } END_KW {
      char* indent = get_indent();
      asprintf(&$$, "%sIF %s THEN\n%s\n%sELSE\n%s\n%sEND", indent, $2, $5, indent, $7, indent);
    }
    | WHILE_KW expr DO_KW { increase_indent(); } statements { decrease_indent(); } END_KW {
      char* indent = get_indent();
      increase_indent();
      asprintf(&$$, "%sWHILE %s DO\n%s\n%sEND", indent, $2, $5, indent);
      decrease_indent();
    };

expr: 
    arithmExpr { 
      asprintf(&$$, "%s", $1); 
    }
    | arithmExpr cmpOp arithmExpr { 
      asprintf(&$$, "%s %s %s", $1, $2, $3);
    };

cmpOp: 
    LESS_OP { asprintf(&$$, "<"); }
    | GREATER_OP { asprintf(&$$, ">"); }
    | LESS_OR_EQUAL_OP { asprintf(&$$, "<="); }
    | GREATER_OR_EQUAL_OP { asprintf(&$$, ">="); }
    | NOT_EQUAL_OP { asprintf(&$$, "#"); }
    | EQUAL_OP { asprintf(&$$, "=="); };

arithmExpr: 
    term { 
      asprintf(&$$, "%s", $1); 
    }
    | arithmExpr addOp term { 
      asprintf(&$$, "%s %s %s", $1, $2, $3);
    };

addOp: 
    ADDITION_OP { asprintf(&$$, "+"); }
    | SUBSTRACTION_OP { asprintf(&$$, "-"); }
    | OR_OP { asprintf(&$$, "OR"); };

term: 
    factor { 
      asprintf(&$$, "%s", $1);
    }
    | term mulOp factor { 
      asprintf(&$$, "%s %s %s", $1, $2, $3);
    };

mulOp: 
    MULTIPLICATION_OP { asprintf(&$$, "*"); }
    | DIVISION_OP { asprintf(&$$, "/"); }
    | DIV_OP { asprintf(&$$, "DIV"); }
    | MOD_OP { asprintf(&$$, "MOD"); }
    | AND_OP { asprintf(&$$, "AND"); };

factor: 
    NOT_OP factor { 
      asprintf(&$$, "NOT %s", $2); 
    }
    | const { 
      asprintf(&$$, "%s", $1); 
    }
    | varChain { 
      asprintf(&$$, "%s", $1); 
    }
    | OPEN_BRACKET_SYM expr CLOSE_BRACKET_SYM { 
      asprintf(&$$, "(%s)", $2);
    };

const: 
    INTEGER_CONST { asprintf(&$$, "%d", $1); }
    | REAL_CONST { asprintf(&$$, "%f", $1); }
    | BOOLEAN_CONST { asprintf(&$$, "%s", $1 ? "TRUE" : "FALSE"); };

%%

int main(int argc, char *argv[]) {
    FILE *input = 0;
    long env[26] = { 0 };
    yyscan_t scanner;
    struct Extra extra;
    if (argc > 1) {
        printf("Read file %s\n", argv[1]);
        input = fopen(argv[1], "r");
    } else {
        printf("No file in command line, use stdin\n");
        input = stdin;
    }

    init_scanner(input, &scanner, &extra);
    yyparse(scanner, env);
    destroy_scanner(scanner);

    if (input != stdin) {
        fclose(input);
    }
    return 0;
}
