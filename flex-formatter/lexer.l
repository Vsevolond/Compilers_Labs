%option reentrant noyywrap bison-bridge bison-locations
%option extra-type="struct Extra *"

/* Подавление предупреждений для -Wall */
%option noinput nounput

%{

#include <stdio.h>
#include <stdlib.h>
#include "lexer.h"
#include "parser.tab.h"  /* файл генерируется Bison’ом */

#define YY_USER_ACTION \
  { \
    int i; \
    struct Extra *extra = yyextra; \
    if (! extra->continued ) { \
      yylloc->first_line = extra->cur_line; \
      yylloc->first_column = extra->cur_column; \
    } \
    extra->continued = false; \
    for (i = 0; i < yyleng; ++i) { \
      if (yytext[i] == '\n') { \
        extra->cur_line += 1; \
        extra->cur_column = 1; \
      } else { \
        extra->cur_column += 1; \
      } \
    } \
    yylloc->last_line = extra->cur_line; \
    yylloc->last_column = extra->cur_column; \
  }

void yyerror(YYLTYPE *loc, yyscan_t scanner, long env[26], const char *message) {
    printf("Error (%d,%d): %s\n", loc->first_line, loc->first_column, message);
}

%}

%%

[\r\t\n ]+
"(*"([^*]|[*][^)])*"*)"

TYPE    return TYPE_KW;
RECORD  return RECORD_KW;
END     return END_KW;
VAR     return VAR_KW;
BEGIN   return BEGIN_KW;
NEW     return NEW_KW;
WHILE   return WHILE_KW;
DO      return DO_KW;
IF      return IF_KW;
THEN    return THEN_KW;
ELSE    return ELSE_KW;
POINTER return POINTER_KW;
TO      return TO_KW;

"="     return TYPE_ASSIGNMENT_OP;
":="    return VAR_ASSIGNMENT_OP;
"^"     return DEREFERENCE_OP;

DIV     return DIV_OP;
MOD     return MOD_OP;
AND     return AND_OP;
NOT     return NOT_OP;
OR      return OR_OP;
"+"     return ADDITION_OP;
"-"     return SUBSTRACTION_OP;
"*"     return MULTIPLICATION_OP;
"/"     return DIVISION_OP;

"=="    return EQUAL_OP;
"<"     return LESS_OP;
"<="    return LESS_OR_EQUAL_OP;
">"     return GREATER_OP;
">="    return GREATER_OR_EQUAL_OP;
"#"     return NOT_EQUAL_OP;

"."     return DOT_SYM;
","     return COMMA_SYM;
":"     return COLON_SYM;
";"     return SEMICOLON_SYM;
"("     return OPEN_BRACKET_SYM;
")"     return CLOSE_BRACKET_SYM;

INTEGER return INTEGER_TYPE;
REAL    return REAL_TYPE;
BOOLEAN return BOOLEAN_TYPE;

TRUE {
    yylval->booleanConst = true;
    return BOOLEAN_CONST;
}

FALSE {
    yylval->booleanConst = false;
    return BOOLEAN_CONST;
}

[a-z][a-zA-Z0-9]* {
    char *ident = malloc(yyleng + 1);
    strcpy(ident, yytext);
    yylval->ident = ident;
    return IDENT;
}

[A-Z][a-zA-Z0-9]* {
    char *localType = malloc(yyleng + 1);
    strcpy(localType, yytext);
    yylval->localType = localType;
    return LOCAL_TYPE;
}

[0-9]+"."[0-9]+ {
    yylval->realConst = atof(yytext);
    return REAL_CONST;
}

[1-9][0-9]* {
    yylval->integerConst = atoi(yytext);
    return INTEGER_CONST;
}

%%

void init_scanner(FILE *input, yyscan_t *scanner, struct Extra *extra) {
    extra->continued = false;
    extra->cur_line = 1;
    extra->cur_column = 1;

    yylex_init(scanner);
    yylex_init_extra(extra, scanner);
    yyset_in(input, *scanner);
}

void destroy_scanner(yyscan_t scanner) {
    yylex_destroy(scanner);
}