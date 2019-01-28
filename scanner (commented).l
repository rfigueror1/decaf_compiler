/* File:  scanner.l
 * ----------------
 * Lex inupt file to generate the scanner for the compiler.
 */

%{

/* The text within this first region delimited by %{ and %} is assumed to
 * be C/C++ code and will be copied verbatim to the lex.yy.c file ahead
 * of the definitions of the yylex() function. Add other header file inclusions
 * or C++ variable declarations/prototypes that are needed by your code here.
 */

#include <string.h>
#include "scanner.h"
#include "utility.h" // for PrintDebug()
#include "errors.h"
#include "list.h"
#include <string>
using namespace std;

/* Global variable: yylval
 * -----------------------
 * This global variable is how we get attribute information about the token
 * just scanned to the client. The scanner sets the global variable
 * appropriately and since it's global the client can just read it.  In the
 * future, this variable will be declared for us in the y.tab.c file
 * produced by Yacc, but for now, we declare it manually.
 */
YYSTYPE yylval;  // manually declared for pp1, later Yacc provides

/* Global variable: yylloc
 * -----------------------
 * This global variable is how we get position information about the token
 * just scanned to the client. (Operates similarly to yylval above)
 */
struct yyltype yylloc; // manually dclared for pp1, later Yacc provides

/* Macro: YY_USER_ACTION 
 * ---------------------
 * This flex built-in macro can be defined to provide an action which is
 * always executed prior to any matched rule's action. Basically, it is
 * a way of having a piece of code common to all actions factored out to
 * this routine.  We already defined it for you and left the empty
 * function DoBeforeEachAction ready for your use as needed. It will
 * be called once for each pattern scanned from the file, before
 * executing its action.
 */
static void DoBeforeEachAction(); 
#define YY_USER_ACTION DoBeforeEachAction();
int lineno, colno; //line number and column number to printt
List<const char*> savedlines; //saved lines to print in the future, imported from file 'list.h' 
%}

 /* The section before the first %% is the Definitions section of the lex
  * input file. Here is where you set options for the scanner, define lex
  * states, and can set up definitions to give names to regular expressions
  * as a simple substitution mechanism that allows for more readable
  * entries in the Rules section later. 
  */


INTEGER_DECIMAL [0-9]+  			//any_of_or_none(0-9)
HEXADECIMAL (0[xX][0-9a-fA-F]+) 	//0 any_of_or_none(x,X) any_of_or_none(0-9,a-f,A-F)
DECIMAL ([0-9]+)					//any_of_or_none(0-9)
BEG_STRING         (\"[^"\n]*)		// escapes('"') zero_or_more(any_of(not("),new_line))
STRING ({BEG_STRING}\")				// BEG_STRING escapes(")
INTEGER ({DECIMAL}|{HEXADECIMAL})	// or(DECIMAL, HEXADECIMAL) 

//DECIMAL escapes('.') could_be(DECIMAL)  could_be(or(E,e) could_be(or(escapes('+'),escapes('-'))) DECIMAL)

// DECIMAL escapes('.') could_be(DECIMAL) could_be(or(E,e) could_be(or(escapes('+'),escapes('-') could_be(DECIMAL))
DOUBLE ({DECIMAL}\.{DECIMAL}?((E|e)(\+|\-)?{DECIMAL})?) 

// or(true, false)
BOOLEAN (true|false)

any_of_or_none(a-z, A-Z) any_of_or_none(a-z, A-Z, 0-9,_)
IDENTIFIER ([a-zA-Z][a-zA-Z0-9_]*)

/* exclusive start conditions are declared. A start condition is
activated using the BEGIN action. Until the next BEGIN action is executed
 If it is exclusive, then only rules qualified with the start condition will be active.
*/

%x COPY COMMENT 

/*
to use condition stacks, your scanner must include this directive
*/
%option stack

%%             /* BEGIN RULES SECTION */
 /* All patterns and actions should be placed between the start and stop
  * %% markers which delimit the Rules section. 
  */ 

//COPY condition is on and any text
<COPY>.* {
	//keep saving any text found 
	savedlines.Append(strdup(yytext));  
    colno = 1; //set colno to 1

    /*
    pops the top of the stack
    and switches to it via BEGIN. 
    */
    yy_pop_state();
    
    /*
    returns all but the first 0 characters
     of the current token back to the input 
     stream, where they will will be rescanned 
     when they will be rescanned when the scanner looks
     for the next match
     This lets information be saved in the scanner.
    */
    yyless(0); 
}

// //COPY condition is on 'End of file'
<COPY><<EOF>> { yy_pop_state(); }


// An '\n' on any start condition
<*>\n   { 
	// increase line number, reset column number
	colno = 1; lineno++;

	// start copying in any case
    if (YYSTATE == COPY)
    	savedlines.Append("");
    else 
    	yy_push_state(COPY);
}

// a tab on any start condition
/*
increase column number by the size of
TAB 
*/ 
<*>[\t] { colno += 8 - colno % 8 + 1; }

// 1 or more empty spaces, do nothing
[ ]+ ;

// Return each of the token names from 'scanner.h' 
"void"	{ return T_Void; }
"int"	{ return T_Int; }
"double"	{ return T_Double; }
"bool"	{ return T_Bool; }
"string"	{ return T_String; }
"class"	{ return T_Class; }
"interface"	{ return T_Interface; }
"null"	{ return T_Null; }
"this"	{ return T_This; }
"extends"	{ return T_Extends; }
"implements"	{ return T_Implements; }
"for"	{ return T_For; }
"while"	{ return T_While; }
"if"	{ return T_If; }
"else"	{ return T_Else; }
"return"	{ return T_Return; }
"break"	{ return T_Break; }
"New"	{ return T_New; }
"NewArray" { return T_NewArray; }

"+" { return '+'; }
"-" { return '-'; }
"*" { return '*'; }
"/" { return '/'; }
"%" { return '%'; }
"<" { return '<'; }
"<=" { return T_LessEqual; }
"&&" { return T_And; }
"||" { return T_Or; }
"!" { return '!'; }
";" { return ';'; }
"," { return ','; }
"." { return '.'; }
"[" { return '['; }
">" { return '>'; }
"]" { return ']'; }
">=" { return T_GreaterEqual; }
"=" { return '='; }
"==" { return T_Equal; }
"!=" { return T_NotEqual; }
"(" { return '('; }
")" { return ')'; }
"{" { return '{'; }
"}" { return '}'; }

// if 'DECIMAL' pattern is found, set 'yylval.integerConstant' to a long integer found @ text pattern
{DECIMAL}	{ 
	yylval.integerConstant = strtol(yytext, NULL, 10); return T_IntConstant; 
}

// if 'HEXADECIMAL' pattern is found, set 'yylval.integerConstant' to a long integer found @ text pattern
{HEXADECIMAL} {
	yylval.integerConstant = strtol(yytext, NULL, 16); 
	return T_IntConstant;
}

// if 'DOUBLE' pattern is found, set 'yylval.doubleConstant' to a double found @ text pattern
{DOUBLE} { 
	yylval.doubleConstant = atof(yytext); return T_DoubleConstant; 
}

// if 'STRING' pattern is found, set 'yylval.stringConstant' to @ text pattern, return T_StringConstant 
{STRING}	{ 
	yylval.stringConstant = strdup(yytext);
    return T_StringConstant;
}

// IF unclosed string is found, report error at the yylloc address
{BEG_STRING} {
	ReportError::UntermString(&yylloc, yytext);       
}

// if boolean is found check if it is true, then set yylval to true else
{BOOLEAN}	{ 
	if (strcmp("true", yytext) == 0){
		yylval.boolConstant = true;
	}
	else{
		yylval.boolConstant = false;
	}
	return T_BoolConstant;
}

/*
if and identifier pattern is found check if 
length is ok, if not, report error.
sets yylval.identifier to yytext and the last character
*/ 
{IDENTIFIER}	{ 
	if (yyleng > 31) //check if the identifier length is greater than 31
		ReportError::LongIdentifier(&yylloc, yytext); //report error using the address of yyloc and the text identified
	strncpy(yylval.identifier, yytext, MaxIdentLen); //Copies the first MaxIdentLen characters of source to destination
	yylval.identifier[MaxIdentLen] = '\0'; //sets the last character of yylval.identifier to '\0'
	return T_Identifier;
}


/*
any other pattern rather than the previous patterns report 'unrecognized character'
error
*/ 
. { 
	ReportError::UnrecogChar(&yylloc, yytext[0]);     
}

%%
/* The closing %% above marks the end of the Rules section and the beginning
 * of the User Subroutines section. All text from here to the end of the
 * file is copied verbatim to the end of the generated lex.yy.c file.
 * This section is where you put definitions of helper functions.
 */

/* Function: InitScanner
 * ---------------------
 * This function will be called before any calls to yylex().  It is designed
 * to give you an opportunity to do anything that must be done to initialize
 * the scanner (set global variables, configure starting state, etc.). One
 * thing it already does for you is assign the value of the global variable
 * yy_flex_debug that controls whether flex prints debugging information
 * about each token and what rule was matched. If set to false, no information
 * is printed. Setting it to true will give you a running trail that might
 * be helpful when debugging your scanner. Please be sure the variable is
 * set to false when submitting your final version.
 */

// start scanner
void InitScanner()
{
    PrintDebug("lex", "Initializing scanner");
    yy_flex_debug = false;
    lineno = 1;
	colno = 1;
}


/* Function: DoBeforeEachAction()
 * ------------------------------
 * This function is installed as the YY_USER_ACTION. This is a place
 * to group code common to all actions.
 */
static void DoBeforeEachAction()
{
	yylloc.first_line = yylloc.last_line = lineno;
 	yylloc.first_column = colno;
 	yylloc.last_column = colno + yyleng - 1;
	colno = colno + yyleng;
}
