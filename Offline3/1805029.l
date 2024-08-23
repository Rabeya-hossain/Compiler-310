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
#include  "symbolTable.cpp"
#include  "carrier.cpp"
#include "y.tab.h"
string num;
string strLexeme,str;
string commentLexeme;
string characterLexeme;
string characterToken;


int initLine;

extern YYSTYPE yylval;
//extern SymbolTable *sym_tab;
void yyerror(char *);

extern ofstream logFile;
extern ofstream errorFile;
extern int line_count;
extern int error_count;

%}

Digit[0-9]

%%

if {return IF;}
for {return FOR;}
do {return DO;}
int {return INT;}
float {return FLOAT;}
void {return VOID;}
switch {return SWITCH;}
default {return DEFAULT;}
else {return ELSE;}
while {return WHILE;}
break {return BREAK;}
char {return CHAR;}
double {return DOUBLE;}
return {return RETURN;}
case {return CASE;}
continue {return CONTINUE;}
printf {return PRINTLN;}

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
		   line_count++;
		   //return NEWLINE;
		  }
{Digit}+ {
	BEGIN number;
	num+=yytext;
	}
<number>\. {BEGIN decimal;
    num+=yytext;
	}
<number>E {BEGIN exp;num+=yytext;}
<number>[a-zA-Z]+ {
	BEGIN INITIAL;
	num+=yytext;
	error_count++;
	logFile<<"Error at ine no "<<line_count<<": Invalid Suffix on numeric constant or invalid prefix on identifier for character sequence "<<num<<" found"<<endl;
	errorFile<<"Error at ine no "<<line_count<<": Invalid Suffix on numeric constant or invalid prefix on identifier for character sequence "<<num<<" found"<<endl;
	}
<number>. {
	yyless(0);
	BEGIN INITIAL;
    SymbolInfo* s=new SymbolInfo;
	s->set_type("CONST_INT");
	s->set_name(num);
	yylval.symbol_info=s;
	num.clear();
	return CONST_INT;
	//symbolTable->insert(num,"INT");
	//symbolTable->print_allScp();
	}
<number><<EOF>> {
	BEGIN INITIAL;
    SymbolInfo* s=new SymbolInfo;
	s->set_type("CONST_INT");
	s->set_name(num);
	yylval.symbol_info=s;
	num.clear();
	return CONST_INT;
	//symbolTable->insert(num,"INT");
	//symbolTable->print_allScp();
	}	
<decimal>{Digit}+ {num+=yytext;}
<decimal>\.[^ \t\v\n,;]* {
	BEGIN INITIAL;
	num+=yytext;
	error_count++;
	logFile<<"Error at line no "<<line_count<<": Too many decimal point error for character sequence "<<num<<" found"<<endl;
	errorFile<<"Error at line no "<<line_count<<": Too many decimal point error for character sequence "<<num<<" found"<<endl;
	num.clear();
	//if(yytext=="\n") line_count++;
	}
<decimal>E {
	BEGIN exp;
    num+=yytext;
	}
<decimal>. {
	yyless(0);
	BEGIN INITIAL;
    SymbolInfo* s=new SymbolInfo;
	s->set_type("CONST_FLOAT");
	s->set_name(num);
	yylval.symbol_info=s;
	num.clear();
	return CONST_FLOAT;
	}	
<decimal><<EOF>> {
	BEGIN INITIAL;
    SymbolInfo* s=new SymbolInfo;
	s->set_type("CONST_FLOAT");
	s->set_name(num);
	yylval.symbol_info=s;
	num.clear();
	return CONST_FLOAT;
	//symbolTable->insert(num,"INT");
	//symbolTable->print_allScp();
	}	
<exp>[+-] {num+=yytext;}
<exp>{Digit}*\.[^\n,;]* {
	BEGIN INITIAL;
	num+=yytext;
	error_count++;
	logFile<<"Error at line no "<<line_count<<": Ill formed number "<<num<<" found"<<endl;
	errorFile<<"Error at line no "<<line_count<<": Ill formed number "<<num<<" found"<<endl;;
	num.clear();
	}
<exp>{Digit}+ {
	BEGIN INITIAL;
	num+=yytext;
	SymbolInfo* s=new SymbolInfo;
	s->set_type("CONST_FLOAT");
	s->set_name(num);
	yylval.symbol_info=s;
	num.clear();
	return CONST_FLOAT;
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
	error_count++;
	logFile<<"Error at line no "<<line_count<<": empty character const"<<endl;
	errorFile<<"Error at line no "<<line_count<<": empty character const"<<endl;
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
	if(tmp=="\n") line_count++;
    }
<escChar>[^\\naftvbr0] {
	BEGIN INITIAL;
	characterLexeme.clear();
	characterToken.clear();
	error_count++;
	logFile<<"Error at line no "<<line_count<<": unknown escape character"<<endl;
	errorFile<<"Error at line no "<<line_count<<": unknown escape character"<<endl;
    }
<endChar>['] {
	BEGIN INITIAL;
	characterLexeme+=yytext;
	SymbolInfo* s=new SymbolInfo;
	s->set_type("CONST_CHAR");
	s->set_name(characterToken);
	yylval.symbol_info=s;
	characterLexeme.clear();
	characterToken.clear();
	return CONST_FLOAT;
	
    }
<endChar>[\n\t\v,;]  {
	BEGIN INITIAL;	
	error_count++;
	logFile<<"Error at line no "<<line_count<<":unfinished character "<<characterLexeme<<" found"<<endl;
	errorFile<<"Error at line no "<<line_count<<":unfinished character "<<characterLexeme<<" found"<<endl;
	characterLexeme.clear();
	characterToken.clear();
	string tmp=yytext;
	if(tmp=="\n") line_count++;
	if(tmp==",")  {return COMMA;}
    if(tmp==";") {return SEMICOLON;}
    }
<endChar>[^\n,;] {
	BEGIN INITIAL;	
	characterLexeme+=yytext;
	error_count++;
	logFile<<"Error at line no "<<line_count<<":multicharacter constant "<<characterLexeme<<" found"<<endl;
	errorFile<<"Error at line no "<<line_count<<":multicharacter constant "<<characterLexeme<<" found"<<endl;
	characterLexeme.clear();
	characterToken.clear();
    }


[+-] {SymbolInfo* s=new SymbolInfo;
	s->set_type("ADDOP");
	s->set_name(yytext);
	yylval.symbol_info=s;
	return ADDOP;}
[*/%] {SymbolInfo* s=new SymbolInfo;
	s->set_type("MULOP");
	s->set_name(yytext);
	yylval.symbol_info=s;
	return MULOP;}
"++" {return INCOP;}
"--" {return DECOP;}
(<)|(<=)|(>)|(>=)|(==)|(!=) {SymbolInfo* s=new SymbolInfo;
	s->set_type("RELOP");
	s->set_name(yytext);
	yylval.symbol_info=s;
	return RELOP;}
[=] {return ASSIGNOP;}
"&&"|"||" {SymbolInfo* s=new SymbolInfo;
	s->set_type("LOGICOP");
	s->set_name(yytext);
	yylval.symbol_info=s;
	return LOGICOP;}
"!" {return NOT;}
"(" {return LPAREN;}
")" {return RPAREN;}
"{" {return LCURL;}
"}" {return RCURL;}
"[" {return LTHIRD;}
"]" {return RTHIRD;}
"," {return COMMA;}
";" {return SEMICOLON;}

[a-zA-Z_][a-zA-Z0-9_]* {
	SymbolInfo* s=new SymbolInfo;
	s->set_type("ID");
	s->set_name(yytext);
	yylval.symbol_info=s;
	return ID;
	//symbolTable->insert(yytext,"ID");
	//symbolTable->print_allScp();
	} 

"\"" {
	BEGIN STRING;
	initLine=line_count;
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
	strLexeme.clear();
	str.clear();
    }
<STRING>"\n" {
	BEGIN INITIAL;
	error_count++;
    logFile<<"Error at line no "<<initLine<<": Unfinished String found"<<endl; 
	errorFile<<"Error at line no "<<initLine<<": Unfinished String found"<<endl; 
	strLexeme.clear();
	str.clear();
	string tmp=yytext;
	if(tmp=="\n") line_count++;
    }
<escStr>"\n" {
	BEGIN STRING;
    str+='\t';
	strLexeme+='\n';
	string tmp=yytext;
	if(tmp=="\n") line_count++;
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


"//" {BEGIN comment;commentLexeme+=yytext;initLine=line_count;}
<comment>"\\" {
	BEGIN escCmnt;
	commentLexeme+=yytext;
	}
<comment>[^\\\n]* {commentLexeme+=yytext;}
<comment>[\n] {
	BEGIN INITIAL;
	commentLexeme.clear();
	string tmp=yytext;
	if(tmp=="\n") line_count++;
    }
<escCmnt>[\n] {
    BEGIN comment;
	commentLexeme+=yytext;
	string tmp=yytext;
	if(tmp=="\n") line_count++;
    }
<escCmnt>[^\n] {
	BEGIN INITIAL;
	commentLexeme+=yytext;
	commentLexeme.clear();
    }
"/*" {
	BEGIN multiCmnt;
    commentLexeme+=yytext;
    }
<multiCmnt>"*/" {
	BEGIN INITIAL;
	commentLexeme+=yytext;
	commentLexeme.clear();
	}

<multiCmnt>[^(*/)] {
	commentLexeme+=yytext;
	string tmp=yytext;
	if(tmp=="\n") line_count++;
	}

. {logFile<<"Error at line "<<line_count<<": unrecognized character "<<yytext<<endl<<endl;
errorFile<<"Error at liine "<<line_count<<": unrecognized character "<<yytext<<endl<<endl;
error_count++;
 }
<multiCmnt><<EOF>> {
	BEGIN INITIAL;
	error_count++;
       logFile<<"Error at liine "<<line_count<<" unfinished comment"<<commentLexeme<<" found"<<endl;
	   errorFile<<"Error at liine "<<line_count<<" unfinished comment"<<commentLexeme<<" found"<<endl;
  }
<<EOF>> {
	   return 0;
	   
       }

%%