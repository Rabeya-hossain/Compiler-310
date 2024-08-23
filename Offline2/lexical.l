%option noyywrap

%x number
%x decimal
%x exp
%x character
%x escChar
%x endChar
%x STRING
%x escStr
%x comment
%x escCmnt
%x multiCmnt
%{
#include<bits/stdc++.h>
using namespace std;
#include<stdlib.h>
#include<iostream>
#include<fstream>
#include "symbolTable.cpp"
SymbolTable *symbolTable=new SymbolTable(7);
ofstream tokenFile("output_token.txt");
string num;
string strLexeme,str;
string commentLexeme;
string characterLexeme;
string characterToken;
int error=0;
int initLine;
%}

Letter[a-zA-z_]
Digit[0-9]

%%

if {outFile<<"Line no "<<yylineno<<": "<<"Token <IF> lexeme if found"<<endl;
   tokenFile<<"<IF> ";
    }
for {outFile<<"Line no "<<yylineno<<": "<<"Token <FOR> lexeme for found"<<endl;
    tokenFile<<"<FOR> ";}
do {outFile<<"Line no "<<yylineno<<": "<<"Token <DO> lexeme do found"<<endl;
     tokenFile<<"<DO> ";}
int {outFile<<"Line no "<<yylineno<<": "<<"Token <INT> lexeme int found"<<endl;
   tokenFile<<"<INT> ";}
float {outFile<<"Line no "<<yylineno<<": "<<"Token <FLOAT> lexeme float found"<<endl;
     tokenFile<<"<FLOAT> ";}
void {outFile<<"Line no "<<yylineno<<": "<<"Token <VOID> lexeme void found"<<endl;
   tokenFile<<"<VOID> ";}
switch {outFile<<"Line no "<<yylineno<<": "<<"Token <SWITCH> lexeme switch found"<<endl;
    tokenFile<<"<SWITCH> ";}
default {outFile<<"Line no "<<yylineno<<": "<<"Token <DEFAULT> lexeme default found"<<endl;
      tokenFile<<"<DEFAULT> ";}
else {outFile<<"Line no "<<yylineno<<": "<<"Token <ELSE> lexeme else found"<<endl;
       tokenFile<<"<ELSE> ";}
while {outFile<<"Line no "<<yylineno<<": "<<"Token <WHILE> lexeme while found"<<endl;
     tokenFile<<"<WHILE> ";}
break {outFile<<"Line no "<<yylineno<<": "<<"Token <BREAK> lexeme break found"<<endl;
     tokenFile<<"<BREAK> ";}
char {outFile<<"Line no "<<yylineno<<": "<<"Token <CHAR> lexeme char found"<<endl;
     tokenFile<<"<CHAR> ";}
double {outFile<<"Line no "<<yylineno<<": "<<"Token <DOUBLE> lexeme double found"<<endl;
    tokenFile<<"<DOUBLE> ";}
return {outFile<<"Line no "<<yylineno<<": "<<"Token <RETURN> lexeme return found"<<endl;
        tokenFile<<"<RETURN> ";}
case {outFile<<"Line no "<<yylineno<<": "<<"Token <CASE> lexeme case found"<<endl;
        tokenFile<<"<CASE> ";}
continue {outFile<<"Line no "<<yylineno<<": "<<"Token <continue> lexeme continue found"<<endl;
    tokenFile<<"<continue> ";}

" " {num.clear();
          characterLexeme.clear();
		  characterToken.clear();
		  }
\t {num.clear();
          characterLexeme.clear();
		  characterToken.clear();
		  }
\v  {num.clear();
          characterLexeme.clear();
		  characterToken.clear();
		  }
\n {
	      num.clear();
          characterLexeme.clear();
		  characterToken.clear();
		  yylineno++;
		  }
{Digit}+ {
	BEGIN number;
	num+=yytext;
	}
<number>\. {BEGIN decimal;
    num+=yytext;
	}
<number>E {BEGIN exp;num+=yytext;}
<number>{Letter}+ {
	BEGIN INITIAL;
	num+=yytext;
	error++;
	outFile<<"Line no "<<yylineno<<": Invalid Suffix on numeric constant or invalid prefix on identifier for character sequence "<<num<<" found"<<endl;
	}
<number>[ \t\v\n,;] {
	BEGIN INITIAL;
	outFile<<"Line no "<<yylineno<<": "<<"Token <CONST_INT> lexeme "<<num<<" found"<<endl;
	tokenFile<<"<CONST_INT"<<","<<num<<"> ";
	symbolTable->insert(num,"INT");
	symbolTable->print_allScp();
	num.clear();
	string tmp=yytext;
	if(tmp=="\n") yylineno++;
	if(tmp==",")  {outFile<<"Line no "<<yylineno<<": "<<"Token <COMMA> lexeme "<<yytext<<" found"<<endl;
	tokenFile<<"<COMMA> ";}
    if(tmp==";") {outFile<<"Line no "<<yylineno<<": "<<"Token <SEMICOLON> lexeme "<<yytext<<" found"<<endl;
	tokenFile<<"<SEMICOLON> ";}

	
	}	
<decimal>{Digit}+ {num+=yytext;}
<decimal>[ \t\v\n,;] {
	BEGIN INITIAL;
	outFile<<"Line no "<<yylineno<<": "<<"Token <CONST_FLOAT> lexeme "<<num<<" found"<<endl;
	tokenFile<<"<CONST_FLOAT"<<","<<num<<"> ";
	symbolTable->insert(num,"FLOAT");
	symbolTable->print_allScp();
	num.clear();
	string tmp=yytext;
	if(tmp=="\n") yylineno++;
	if(tmp==",")  {outFile<<"Line no "<<yylineno<<": "<<"Token <COMMA> lexeme "<<yytext<<" found"<<endl;
	tokenFile<<"<COMMA> ";}
    if(tmp==";") {outFile<<"Line no "<<yylineno<<": "<<"Token <SEMICOLON> lexeme "<<yytext<<" found"<<endl;
	tokenFile<<"<SEMICOLON> ";}
	}	
<decimal>\.[^ \t\v\n,;]* {
	BEGIN INITIAL;
	num+=yytext;
	error++;
	outFile<<"Line no "<<yylineno<<": Too many decimal point error for character sequence "<<num<<" found"<<endl;
	num.clear();
	//if(yytext=="\n") yylineno++;
	}
<decimal>E {
	BEGIN exp;
    num+=yytext;
	}
<exp>[+-] {num+=yytext;}
<exp>{Digit}*\.[^\n,;]* {
	BEGIN INITIAL;
	num+=yytext;
	error++;
	outFile<<"Line no "<<yylineno<<": Ill formed number "<<num<<" found"<<endl;
	num.clear();
	}
<exp>{Digit}+ {
	BEGIN INITIAL;
	num+=yytext;
	outFile<<"Line no "<<yylineno<<": "<<"Token <CONST_FLOAT> lexeme "<<num<<" found"<<endl;
	tokenFile<<"<CONST_FLOAT"<<","<<num<<"> ";
	symbolTable->insert(num,"FLOAT");
	symbolTable->print_allScp();
	num.clear();
	}


['] {
	BEGIN character;
	characterLexeme+=yytext;
    }
<character>[\\] {
	BEGIN escChar;
	characterLexeme+=yytext;
    }
<character>[^\\\'] {
	BEGIN endChar;
	characterToken+=yytext;
	characterLexeme+=yytext;
    }
<character>['] {
	BEGIN INITIAL;
	characterLexeme.clear();
	characterToken.clear();
	error++;
	{outFile<<"Erroe at line no "<<yylineno<<": empty character const"<<endl;}
    }
<escChar>[\\nt\'afvrb0]  {
	BEGIN endChar;
	characterLexeme+=yytext;
	char ch=yytext[0];
	switch(ch){
		case '\\':
		characterToken+='\\';
		break;
		case '\'':
		characterToken+='\"';
		break;
		case 'a':
		characterToken+='\a';
		break;
		case 't':
		characterToken+='\t';
		break;
		case 'f':
		characterToken+='\f';
		break;
		case 'v':
		characterToken+='\v';
		break;
		case 'n':
		characterToken+='\n';
		break;
		case 'r':
		characterToken+='\r';
		break;
		case '0':
		characterToken+='\0';
		break;
    }
	string tmp=yytext;
	if(tmp=="\n") yylineno++;
    }
<escChar>[^\\naftvbr0] {
	BEGIN INITIAL;
	characterLexeme.clear();
	characterToken.clear();
	error++;
	{outFile<<"Error at line no "<<yylineno<<": unknown escape character"<<endl;}
    }
<endChar>['] {
	BEGIN INITIAL;
	characterLexeme+=yytext;
	tokenFile<<"<CONOST_CHAR"<<","<<characterLexeme<<"> ";
	{outFile<<"Line no "<<yylineno<<": "<<"Token <CONST_CHAR> lexeme "<<characterLexeme<<" found ----><CHAR_CONST,"<<characterToken<<">"<<endl;}
	symbolTable->insert(characterToken,"CONST_CHAR");
	symbolTable->print_allScp();
	characterLexeme.clear();
	characterToken.clear();
    }
<endChar>[\n\t\v,;]  {
	BEGIN INITIAL;	
	error++;
	{outFile<<"Error at line no "<<yylineno<<":unfinished character "<<characterLexeme<<" found"<<endl;}
	characterLexeme.clear();
	characterToken.clear();
	string tmp=yytext;
	if(tmp=="\n") yylineno++;
	if(tmp==",")  {outFile<<"Line no "<<yylineno<<": "<<"Token <COMMA> lexeme "<<yytext<<" found"<<endl;
	tokenFile<<"<COMMA> ";}
    if(tmp==";") {outFile<<"Line no "<<yylineno<<": "<<"Token <SEMICOLON> lexeme "<<yytext<<" found"<<endl;
	tokenFile<<"<SEMICOLON> ";}
    }
<endChar>[^\n,;] {
	BEGIN INITIAL;	
	characterLexeme+=yytext;
	error++;
	{outFile<<"Error at line no "<<yylineno<<":multicharacter constant "<<characterLexeme<<" found"<<endl;}
	characterLexeme.clear();
	characterToken.clear();
    }


[+-] {outFile<<"Line no "<<yylineno<<": "<<"Token <ADDOP> lexeme "<<yytext<<" found"<<endl;tokenFile<<"<ADDOP"<<","<<yytext<<"> ";}
[*/%] {outFile<<"Line no "<<yylineno<<": "<<"Token <MULOP> lexeme "<<yytext<<" found"<<endl;tokenFile<<"<MULOP"<<","<<yytext<<"> ";}
"++"|"--" {outFile<<"Line no "<<yylineno<<": "<<"Token <INCOP> lexeme "<<yytext<<" found"<<endl;tokenFile<<"<INCOP"<<","<<yytext<<"> ";}
(<)|(<=)|(>)|(>=)|(==)|(!=) {outFile<<"Line no "<<yylineno<<": "<<"Token <RELOP> lexeme "<<yytext<<" found"<<endl;tokenFile<<"<RELOP"<<","<<yytext<<"> ";}
[=] {outFile<<"Line no "<<yylineno<<": "<<"Token <ASSIGNOP> lexeme "<<yytext<<" found"<<endl;tokenFile<<"<ASSIGNOP"<<","<<yytext<<"> ";}
"&&"|"||" {outFile<<"Line no "<<yylineno<<": "<<"Token <LOGICOP> lexeme "<<yytext<<" found"<<endl;tokenFile<<"<LOGICOP"<<","<<yytext<<"> ";}
"!" {outFile<<"Line no "<<yylineno<<": "<<"Token <NOT> lexeme "<<yytext<<" found"<<endl;tokenFile<<"<NOT"<<","<<yytext<<"> ";}
"(" {outFile<<"Line no "<<yylineno<<": "<<"Token <LPAREN> lexeme "<<yytext<<" found"<<endl;tokenFile<<"<LPAREN"<<","<<yytext<<"> ";}
")" {outFile<<"Line no "<<yylineno<<": "<<"Token <RPAREN> lexeme "<<yytext<<" found"<<endl;tokenFile<<"<RPAREN"<<","<<yytext<<"> ";}
"{" {outFile<<"Line no "<<yylineno<<": "<<"Token <LCURL> lexeme "<<yytext<<" found"<<endl;symbolTable->EnterScope();tokenFile<<"<LCURL"<<","<<yytext<<"> > ";}
"}" {outFile<<"Line no "<<yylineno<<": "<<"Token <RCURL> lexeme "<<yytext<<" found"<<endl;symbolTable->ExitScope();tokenFile<<"<RCURL"<<","<<yytext<<"> > ";}
"[" {outFile<<"Line no "<<yylineno<<": "<<"Token <LTHIRD> lexeme "<<yytext<<" found"<<endl;tokenFile<<"<LTHIRD"<<","<<yytext<<"> > ";}
"]" {outFile<<"Line no "<<yylineno<<": "<<"Token <RTHIRD> lexeme "<<yytext<<" found"<<endl;tokenFile<<"<RTHIRD"<<","<<yytext<<"> > ";}
"," {outFile<<"Line no "<<yylineno<<": "<<"Token <COMMA> lexeme "<<yytext<<" found"<<endl;tokenFile<<"<COMMA"<<","<<yytext<<"> > ";}
";" {outFile<<"Line no "<<yylineno<<": "<<"Token <SEMICOLON> lexeme "<<yytext<<" found"<<endl;tokenFile<<"<SEMICOLON"<<","<<yytext<<"> > ";}

[a-zA-Z_][a-zA-Z0-9_]* {
	
	outFile<<"Line no "<<yylineno<<": "<<"Token <ID> lexeme "<<yytext<<" found"<<endl;
	tokenFile<<"<ID"<<","<<yytext<<"> ";
	symbolTable->insert(yytext,"ID");
	symbolTable->print_allScp();
	} 

"\"" {
	BEGIN STRING;
	initLine=yylineno;
	strLexeme+=yytext;
      }
<STRING>[^\\\n\"]* {
	strLexeme+=yytext;
	str+=yytext;
	}
<STRING>"\\" {
	BEGIN escStr;
	strLexeme+=yytext;
	}
<STRING>"\"" {
	BEGIN INITIAL;
	strLexeme+=yytext;
    outFile<<"Line no "<<initLine<<": "<<"Token <STRING> lexeme "<<strLexeme<<" found ----><STRING,"<<str<<">"<<endl; 
	tokenFile<<"<STRING"<<","<<strLexeme<<"> ";
	strLexeme.clear();
	str.clear();
    }
<STRING>"\n" {
	BEGIN INITIAL;
	error++;
    outFile<<"Error at line no "<<initLine<<": Unfinished String found"<<endl; 
	strLexeme.clear();
	str.clear();
	string tmp=yytext;
	if(tmp=="\n") yylineno++;
    }
<escStr>"\n" {
	BEGIN STRING;
    str+='\t';
	strLexeme+='\n';
	string tmp=yytext;
	if(tmp=="\n") yylineno++;
    }
<escStr>[\\\"atfvnr0] {
	BEGIN STRING;
	char ch=yytext[0];
	switch(ch){
		case '\\':
		str+='\\';
		break;
		case '\"':
		str+='\"';
		break;
		case 'a':
		str+='\a';
		break;
		case 't':
		str+='\t';
		break;
		case 'f':
		str+='\f';
		break;
		case 'v':
		str+='\v';
		break;
		case 'n':
		str+='\n';
		break;
		case 'r':
		str+='\r';
		break;
		case '0':
		str+='\0';
		break;

	}
	  
	strLexeme+=yytext;
	
    }
<escStr>[^\\\"atfvnr0] {
	BEGIN STRING;
	str+=yytext;
	strLexeme+=yytext;
    }


"//" {BEGIN comment;commentLexeme+=yytext;initLine=yylineno;}
<comment>"\\" {
	BEGIN escCmnt;
	commentLexeme+=yytext;
	}
<comment>[^\\\n]* {commentLexeme+=yytext;}
<comment>[\n] {
	BEGIN INITIAL;
	outFile<<"Line no "<<initLine<<": "<<"Token <COMMENT> lexeme "<<commentLexeme<<" found "<<endl; 
	commentLexeme.clear();
	string tmp=yytext;
	if(tmp=="\n") yylineno++;
    }
<escCmnt>[\n] {
    BEGIN comment;
	commentLexeme+=yytext;
	string tmp=yytext;
	if(tmp=="\n") yylineno++;
    }
<escCmnt>[^\n] {
	BEGIN INITIAL;
	commentLexeme+=yytext;
	outFile<<"Line no "<<initLine<<": "<<"Token <COMMENT> lexeme "<<commentLexeme<<" found "<<endl; 
	commentLexeme.clear();
    }
"/*" {
	BEGIN multiCmnt;
    commentLexeme+=yytext;
    }
<multiCmnt>"*/" {
	BEGIN INITIAL;
	commentLexeme+=yytext;
	outFile<<"Line no "<<initLine<<": "<<"Token <COMMENT> lexeme "<<commentLexeme<<" found "<<endl; 
	commentLexeme.clear();
	}

<multiCmnt>[^(*/)] {
	commentLexeme+=yytext;
	string tmp=yytext;
	if(tmp=="\n") yylineno++;
	}

. {outFile<<"Error at liine "<<yylineno<<" unrecognized character"<<endl;
error++;
 }
<multiCmnt><<EOF>> {
	BEGIN INITIAL;
	error++;
       outFile<<"Error at liine "<<yylineno<<" unfinished comment"<<commentLexeme<<" found"<<endl;
  }
<<EOF>> {
       outFile<<"total line : "<<yylineno<<endl;
	   outFile<<"total error: "<<error<<endl;
	   return 0;
	   
       }

%%
int main(int argc,char *argv[]){
	
	if(argc!=2){
		printf("Please provide input file name and try again\n");
		return 0;
	}
	
	FILE *fin=fopen(argv[1],"r");
	if(fin==NULL){
		printf("Cannot open specified file\n");
		return 0;
	}
	

	yyin= fin;
    yylineno=1;
	yylex();
	fclose(yyin);
	return 0;
}