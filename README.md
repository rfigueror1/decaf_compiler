Compiler for Decaf programming Language

ITAM, Mexico City. Spring 2019.

How to compile the project:

1. `make` to buid files.
2. `g++ -o dpp dpp.yy.o dppmain.o utility.o errors.o -lc -lm -ll` to compile the Preprocessor
3. `./dpp < [TEST].txt` to give some input files to the Preprocessor. 
4. `g++ -o dcc lex.yy.o  errors.o  utility.o  main.o  -lc -lm -ll` to compile the scanner
5. `./dcc < [ANY FILE]` to run the scanner. 

Based on Maggie Johnson and Julie Zelenski Stanford CS143 projects.