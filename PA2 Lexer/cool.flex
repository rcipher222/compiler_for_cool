/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

#define MAX 100
int t_lines;
int print(){printf("Unrecognized string");return(ERROR);};
int value=0;

char *msg="comment error";

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;
extern YYSTYPE cool_yylval;


/*
 *  Add Your own definitions here
 */


%}

/*
 * Define names for regular expressions here.
 */


identifier	[a-zA-Z][a-zA-Z0-9]*
digits		[0-9]+
number		digit+
CLASS		(class|CLASS)
ELSE       	(else|ELSE)
FI    		(fi|FI)
IF 		(if|IF)
IN 		(in|IN)
INHERITS 	(inherits|INHERITS)
LET		(let|LET) 
LOOP		(loop|LOOP)
POOL		(pool|POOL) 
THEN 		(then|THEN)
WHILE		(while|WHILE) 
CASE		(case|CASE)   
ESAC 		(esac|ESAC)
OF		(of|OF) 
DARROW		=> 
NEW 		(new|NEW)
ISVOID		(isvoid|ISVOID) 
STR_CONST	(str_const|STR_CONST) 
BOOL_CONST	(true|false)
ASSIGN 		=
NOT 		~
x		[(]
y		[*]
z		[)]
LE 		<=
line		\n
open		[(][*]
close		[*][)]
str		["].*["]

		
%%

 /*
  *  Nested comments
  */

{open}		{ printf("hellobhatia");
	         if(value>=0) value++; else {yylval.error_msg=msg; print(); }
	         }
{close} 	 {
     		 if(value-1>=0) value--; else {yylval.error_msg=msg; print(); }
		 }

 /*
  *  The multiple-character operators.
  */
{CLASS}			{ return (CLASS); }
{FI}			{ return (FI);	   }
{IF}			{return (IF);	   } 
{IN}                    {return (IN);	   }
{INHERITS} 		{return (INHERITS);}
{LET}			{return (LET);     } 
{LOOP}			{return (LOOP);	   }
{POOL}                  {return (POOL);	   }
{THEN} 			{return (THEN);	   }
{WHILE}			{return (WHILE);   } 
{CASE} 			{return (CASE);	   }
{ESAC} 			{return (ESAC);	   }
{OF} 			{return (OF);	     }
{DARROW} 		{return (DARROW);    }
{NEW} 			{return (NEW);	     }
{ISVOID} 		{return (ISVOID);    }
{BOOL_CONST}		{return (BOOL_CONST);}
{ASSIGN}           	{return (ASSIGN);}
{NOT} 			{return (NOT);}
{LE} 			{return(LE);}
{digits}		{
                       cool_yylval.symbol = inttable.add_string(yytext);
		       return (INT_CONST);
		       }
 line		       {t_lines++;}

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */


 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */

 {str}		{printf("string");}

\"            { 
                    // "starting tag
                    BEGIN(STRING);
                }
<STRING>\"    { 
                    // Closing tag"
                    cool_yylval.symbol = stringtable.add_string(string_buf);
                    resetStr();
                    BEGIN(INITIAL);
                    return(STR_CONST);
                }
<STRING>(\0|\\\0) {
                      cool_yylval.error_msg = "String contains null character";
                      BEGIN(BROKENSTRING);
                      return(ERROR);
                }
<BROKENSTRING>.*[\"\n] {
                    //"//Get to the end of broken string
                    BEGIN(INITIAL);
                }
<STRING>\\\n      {   
                    // escaped slash
                    // printf("captured: %s\n", yytext);
                    if (strTooLong()) { return strLenErr(); }
                    curr_lineno++; 
                    addToStr("\n");
                    string_length++;
                    // printf("buffer: %s\n", string_buf);
                }
<STRING>\n      {   
                    // unescaped new line
                    curr_lineno++; 
                    BEGIN(INITIAL);
                    resetStr();
                    cool_yylval.error_msg = "Unterminated string constant";
                    return(ERROR);
                }

<STRING><<EOF>> {   
                    BEGIN(INITIAL);
                    cool_yylval.error_msg = "EOF in string constant";
                    return(ERROR);
                }

<STRING>\\n      {  // escaped slash, then an n
                    if (strTooLong()) { return strLenErr(); }
                    curr_lineno++; 
                    addToStr("\n");
                }

<STRING>\\t     {
                    if (strTooLong()) { return strLenErr(); }
                    string_length++;
                    addToStr("\t");
}
<STRING>\\b     {
                    if (strTooLong()) { return strLenErr(); }
                    string_length++;
                    addToStr("\b");
}
<STRING>\\f     {
                    if (strTooLong()) { return strLenErr(); }
                    string_length++;
                    addToStr("\f");
}
<STRING>\\.     {
                    //escaped character, just add the character
                    if (strTooLong()) { return strLenErr(); }
                    string_length++;
                    addToStr(&strdup(yytext)[1]);
                }
<STRING>.       {   
                    if (strTooLong()) { return strLenErr(); }
                    addToStr(yytext);
                    string_length++;
                }


 /*
  *  Catching all the rest including whitespace
  *
  */


\n          { curr_lineno++; }

[ \r\t\v\f] {}

.           {
              cool_yylval.error_msg = yytext;
              return(ERROR);
}

%%

/* USER SUBROUTINES
 * ======================================================================== */

void addToStr(char* str) {
    strcat(string_buf, str);
}

bool strTooLong() {
  if (string_length + 1 >= MAX_STR_CONST) {
      BEGIN(BROKENSTRING);
      return true;
    }
    return false;
}

void resetStr() {
    string_length = 0;
    string_buf[0] = '\0';
}

int strLenErr() {
  resetStr();
    cool_yylval.error_msg = "String constant too long";
    return ERROR;
}

%%				
