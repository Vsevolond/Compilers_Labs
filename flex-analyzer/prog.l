%option noyywrap bison-bridge bison-locations

%{
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>

#define TAG_IDENT 1
#define TAG_NUMBER 2
#define TAG_ERROR 3

int ident_code = 0;

char *tag_names[] = {
    "END_OF_PROGRAM", "IDENT", "NUMBER", "ERROR"
};

struct Position {
    int line, pos, index;
};

void print_pos(struct Position *p) {
    printf ("(%d,%d)", p->line,p->pos);
}

struct Fragment {
    struct Position starting, following;
};

typedef struct Fragment YYLTYPE;

void print_frag(struct Fragment *f) {
    print_pos(&(f->starting));
    printf("-");
    print_pos(&(f->following));
    printf(": ");
}

union Token {
    char *ident;
    long num;
};

typedef union Token YYSTYPE;
int continued;
struct Position cur;


#define YY_USER_ACTION {                \
       int i;                           \
       if (!continued)                  \
           yylloc->starting = cur;      \
       continued = 0;                   \
       for ( i = 0; i < yyleng; i++){   \
           if (yytext[i] == '\n') {     \
               cur.line++;              \
               cur.pos = 1;             \
           }                            \
           else                         \
               cur.pos++;               \
           cur.index++;                 \
       }                                \
       yylloc->following = cur;         \
} 

void init_scanner (char* program) {
       continued = 0;
       cur.line = 1;
       cur.pos = 1;
       cur.index = 0;
       yy_scan_string(program);
}

void err(char* msg){
       printf("Error");
       print_pos(&cur);
       printf(":%s\n", msg);
}

long valueByChar(char ch) {
    if (ch == 'I' || ch == 'i') return 1;
    if (ch == 'V' || ch == 'v') return 5;
    if (ch == 'X' || ch == 'x') return 10;
    if (ch == 'L' || ch == 'l') return 50;
    if (ch == 'C' || ch == 'c') return 100;
    if (ch == 'D' || ch == 'd') return 500;
    if (ch == 'M' || ch == 'm') return 1000;
    return 0;
}

long convertToNum(char *str) {
    if (strcmp(str, "NIHIL") == 0 || strcmp(str, "nihil") == 0) {
        return 0;
    }

    long result = 0;
    int i;
    
    for (i = 0; str[i] != '\0'; i++) {
        long current = valueByChar(str[i]);
        long next = valueByChar(str[i + 1]);
        
        if (next > current) {
            result += (next - current);
            i++;
        } else {
            result += current;
        }
    }
    
    return result;
}

%}

DIGIT [0-9]
IDENT {DIGIT}+
ROMAN [XVILCDMxvilcdm]
NUMBER {ROMAN}+|NIHIL|nihil

%% 

[\n\t\r ]+

{IDENT}       {
                     yylval->ident = yytext;
                     return TAG_IDENT;
              }
{NUMBER}      {
                     yylval->num = convertToNum(yytext);
                     return TAG_NUMBER;
              }
              
.             err("unexpected character");
<<EOF>>       return 0;

%%
int main () {
    int tag;

    YYSTYPE value;
    YYLTYPE coords;
    FILE *file;

    union Token token;
    file = fopen("input.txt", "r");
    char *str;
    int ch;
    size_t len = 0;
    int size = 256;

    str = realloc(NULL, sizeof(*str)*size);
    while (EOF != (ch=fgetc(file))) {
        str[len++] = ch;
        if (len == size) {
            str = realloc(str, sizeof(*str)*(size*=2));
            if (!str) break;
        }
    }
    str[len++]='\0';

    str = realloc(str, sizeof(*str)*len);
    init_scanner(str);

    do {
        tag = yylex(&value, &coords);
        printf("%s ", tag_names[tag]);

        if (tag == 0) break;
        print_frag(&coords);

        if (tag == TAG_IDENT) {
            printf("%s", value.ident);

        } else if (tag == TAG_NUMBER) {
            printf("%ld", value.num);
        }
        printf("\n");
    }
    while (tag != 0);
    return 0;
}