/*
 * file:  dpp.l
 * ------------
 * Lex inupt file to generate the scanner for the preprocessor.
 * If you decide to use lex for the preprocesor, put your rules
 * here, otherwise the file can remain empty.
 */

%{

/* Inclusion of external resources
Maps are associative containers that store elements formed by
a combination of a key value and mapped value
following an specific order
*/

#include <map>
#include <string>
#include "errors.h"

/* Here we can see that more than one variables are being
used without reporting any error. 
That is because they are declared in the  
different namespaces and scopes. 
*/

using namespace std;

// Definition of a map with its key-value pair
std::map<std::string, std::string> mapOfMacros;

// Definition of line number to keep track of the line number
int line_num = 1;

/* definition of a helper function to count the
number of characters equal to an specific character
in a string
*/
int count_chars(string s, char c) {
  int count = 0;

  for (int i = 0; i < s.size(); i++)
    if (s[i] == c) count++;

  return count;
}

%}

/* Start conditions are declared 
*/
%x COMMENT_STATE

/* Flex provides a mechanism for controlling
options within the scanner specification itself
using the 'stack' directive enables the use of
start condition stack.
*/ 
%option stack


BEGIN_COMMENT \/\*		//escapes the / and escapes *
ONELINE_COMMENT \/\/.*	//escapes the / and escapes / and anything in that line (.*) 


/*
zero_or_more(
	escapes('/')
	escapes('*') 
	or(
		not(*),
		\n,
		one_or_more(escapes('*')) or(not('*/'), \n)
		)
)
one_or_more(escapes(*))
escapes('/')
*/

MULTILINE_COMMENT \/\*([^*]|[\n]|(\*+([^*/]|[\n])))*\*+\/

NAME [A-Z]+
MACRO_DECLARATION "#define"\ {NAME}\ .*				// a macro declaration has the form '#define identifier replacement'
MACRO_USAGE \#{NAME} 								// Whenever 'NAME' is found

%%

/* Increases the line count and prints the 
new line. c_str() gets the actual value of the pointer gotten
by invoking 'strdup'
*/
\n {line_num++;
	string texto = strdup(yytext);
	printf("%s", texto.c_str());
}

/* When the 'BEGIN_COMMENT' pattern is found, 
we start up the 'COMMENT_STATE' state and push it to the 'start options' stack
*/
{BEGIN_COMMENT} {
	BEGIN(COMMENT_STATE);
	yy_push_state(COMMENT_STATE);
}

/* If the 'COMMENT_STATE' is on and we have reached the end of file, 
We report the unterminated comment error and pop from the options stack
*/
<COMMENT_STATE><<EOF>> {
	ReportError::UntermComment(); 	
	yy_pop_state();
}

/* 
If we find a one line comment, we simply print a new line.
*/
{ONELINE_COMMENT} { /* printf("%s", "\n"); */ }

/* 
If we find a multi-line comment, we count the number of lines of the multi-line
comment found and print a new line each number of lines
*/
{MULTILINE_COMMENT} { 

	string texto = strdup(yytext);
	int num_lineas = count_chars(texto, '\n');

	for(int i = 0; i < num_lineas; i++){
		printf("%s", "\n");
	}

}

/* 
If we find a macro declaration
we declare 4 string variables
*/
{MACRO_DECLARATION} { 
	
	string name_replacement, name, replacement, texto;
	int find_space;

	texto = strdup(yytext);

	name_replacement = texto.substr(8); // NAME replacement es el #define
	find_space = name_replacement.find(" "); // ubica dónde está el primer espacio en name_replacement
	name = name_replacement.substr(0, find_space); //obtiene el nombre empezando por el primer espacio
	replacement = name_replacement.substr(find_space); //obtiene el replacement efectivamente desde que termina el name
	mapOfMacros.insert(make_pair(name, replacement)); // mapOfMacros[name]=replacement; inserta en el map of macros el key value pair
}

{MACRO_USAGE} {
	string texto, name, replacement;
	texto = strdup(yytext);
	
	name = texto.substr(1);
	if(mapOfMacros.find(name) == mapOfMacros.end()){ //if not found
		ReportError::InvalidDirective(line_num); 
	} else {
		replacement = mapOfMacros.find(name)->second; //means '(*mapOfMacros.find(name)).second' get the second element in a map  
		printf("%s", replacement.substr(1).c_str()); //print the replacement found previously
	}
}

/*
If we find a define without name
*/
#define[^\n]* {
	ReportError::InvalidDirective(line_num); 
}


// ECHO everything.
. {
	string texto = strdup(yytext);
	printf("%s", texto.c_str());
}

%%
