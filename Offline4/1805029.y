
%{
#include<bits/stdc++.h>
using namespace std;
#include<stdlib.h>
#include<iostream>
#include<fstream>
#include  "symbolTable.cpp"
#include  "carrier.cpp"
//#include "optimization.h"
#define fi first
#define se second

ofstream logFile;
ofstream errorFile;
ofstream fout;
ofstream opfout;


int line_count=1;
int error_count=0 ;
int sp=0,func_sp=0;

int labelCount=0;
int tempCount=0;

int mainf=0,seen_main=0;

string label1,label2;


char *newLabel()
{
	char *lb= new char[4];
	strcpy(lb,"L");
	char b[3];
	sprintf(b,"%d", labelCount);
	labelCount++;
	strcat(lb,b);
	return lb;
}

char *newTemp()
{
	char *t= new char[4];
	strcpy(t,"t");
	char b[3];
	sprintf(b,"%d", tempCount);
	tempCount++;
	strcat(t,b);
	return t;
}

int yyparse(void);
int yylex(void);
extern FILE *yyin;

//SymbolTable *table;
SymbolTable *symbolTable=new SymbolTable(7);

void yyerror(char *s)
{
	//write your code
}

void rule_matched(string rule)
{
    logFile<<"Line "<<line_count<<": "<<rule<<endl<<endl; 
	//errorFile<<"Line "<<": "<<rule<<"\n"<<endl; 
}



vector<string> splitString(string line, char delim)
{
    stringstream ss(line);
    vector<string> tokens;
    string intermediate;

    while (getline(ss, intermediate, delim))
    {
        tokens.push_back(intermediate);
    }
    return tokens;
}
string white_space(string str)
{
	int i=0;
	for(i=0;i<str.size();i++)
	{
		if(str[i]!=' ') break;  
	}
	string tmp;
	for( ;i<str.size();i++)
	{
		if(str[i]==' ')
		{
			tmp+=str[i];
			while(i<str.size() && str[i]==' ') i++;
			i--;
		}
		else tmp+=str[i];
	}
	return tmp;
}

void optimize_code()
{
     vector<string> code_line;
    

    ifstream file_in("code.asm");
    string tmp, tmp2;
    while (getline(file_in, tmp))
    {
        code_line.push_back(tmp);
    }
	//cout<<code_line.size()<<endl;
    for(int i=0;i<code_line.size()-1;i++)
    {
        tmp=code_line[i];
        tmp2=code_line[i+1];
        if(tmp.size()==0 || tmp[0]==';') {
			//opfout<<tmp<<endl;
			continue;
		}
		tmp=white_space(tmp);
        vector<string> token_tmp = splitString(tmp, ' ');
		//cout<<tmp<<' ';
		//cout<<token_tmp.size()<<' ';
        vector<string> token2_tmp;
        if (token_tmp.size() == 2)
        {
            token2_tmp = splitString(token_tmp[1], ',');
        }
         else
        {
            opfout << tmp << endl;
            continue;
        }
        while (i+1<code_line.size())
        {
            tmp2=code_line[i+1];
			if(tmp2.size()==0|| tmp2[0]==';') {
                i++;
				continue;
			}
			tmp2=white_space(tmp2);
			//cout<<tmp2<<endl;
            vector<string> token_tmp2 = splitString(tmp2, ' ');
			vector<string> token2_tmp2;
			if(token_tmp[0]=="JMP")
			{
                token_tmp2=splitString(tmp2, ':');
				if(token_tmp[1]==token_tmp2[0])
				{
					opfout<<";"<<tmp<<endl;
					opfout<<tmp2<<endl;
					i++;
				}
				else
				{
					opfout<<tmp<<endl;
					break;

				}
			}
			else
			{
                if (token_tmp2.size() == 2)
            {
                 token2_tmp2 = splitString(token_tmp2[1], ',');
            }
			else
			{
				 opfout << tmp << endl;
                //opfout  << tmp2 << endl;
				//i++;
				break;
			}
            if (token2_tmp2.size() == 1&& token2_tmp.size() == 1)
            {
                if (token_tmp[0] == "PUSH" && token_tmp2[0] == "POP" && token2_tmp[0] == token2_tmp2[0])
                {
                    opfout << ";" << tmp << endl;
                    opfout << ";" << tmp2 << endl;
                }
				else
				{
					opfout<<tmp<<endl;
					break;
				}
            }
            else if (token2_tmp2.size() == 2 && token2_tmp.size() == 2)
            {
                if (token_tmp[0] == "MOV" && token_tmp2[0] == "MOV" && token2_tmp[0] == token2_tmp2[1] && token2_tmp[1] == token2_tmp2[0])
                {
                    opfout << tmp << endl;
                    opfout << ";" << tmp2 << endl;
                }
				else
				{
					opfout<<tmp<<endl;
					break;
				}
            }
            else
            {
                opfout << tmp << endl;
				break;
               // opfout  << tmp2 << endl;
            }
            i++;
			break;
			}
            
        }

    }
}


%}


%union{
   SymbolInfo* symbol_info;
   container* abc;
    
}

%token IF FOR DO INT FLOAT VOID SWITCH DEFAULT ELSE WHILE BREAK CHAR DOUBLE RETURN CASE CONTINUE INCOP DECOP NOT 
%token LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON PRINTLN ASSIGNOP
%token <symbol_info> ID  ADDOP MULOP RELOP LOGICOP CONST_INT CONST_FLOAT error_FLOAT 

%type <abc> type_specifier declaration_list var_declaration unit program start variable unary_expression factor term simple_expression rel_expression logic_expression expression
%type <abc> expression_statement statements statement func_definition func_declaration compound_statement parameter_list arguments argument_list left_curl right_curl 
%type <abc> func_compound_statement final_parameter_list conditional conditional_statement while_epsilon while_conditional 
%type <abc> for_expression1 for_expression2 for_expression3 

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

start : program
	{
		//write your code in this block in all the similar blocks below
		rule_matched("start:program");
		$$=new container();
		$$=$1;
		if(seen_main)
		{
            fout<<"OUTPUT PROC  \nPUSH AX  \nPUSH BX\nPUSH CX\nPUSH DX\nXOR CX,CX\n CHAR_IN_STACK:\n CMP AX,0\nJNL POSITIVE\n MOV BX,AX ;SAVING AX\n"<<
		"MOV DL,45\nMOV AH,2\nINT 21H \n MOV AX,BX ;RESTORING AX\nCMP AX,8000H\nJE POSITIVE\nNEG AX \nJMP CHAR_IN_STACK\nPOSITIVE: \n XOR DX,DX\n MOV BX,10\n DIV BX\n"<<
      " PUSH DX\n INC CX\n CMP AX,0\n JNE CHAR_IN_STACK\n JCXZ END_OUTPUT\n MOV AH,2\n CHAR_OUTPUT:\n   POP DX \nADD DX,48\nINT 21H \nLOOP CHAR_OUTPUT\n"<<
       "END_OUTPUT: \nPOP DX\nPOP CX  \nPOP BX\nPOP AX\n RET \n OUTPUT ENDP \n\n\n";
	   fout<<"NEWLINE PROC \nMOV AH, 2\n MOV DL, CR\n INT 21H\n MOV DL, LF\n INT 21H\n RET\n NEWLINE ENDP\n\n\n END MAIN\n ";
		}
		else
		{
			fout<<"START:\n ";
		}
		
		logFile<<$$->text<<endl<<endl;
	}
	;

program : program unit 
     {
		rule_matched("program:program unit ");
		$$=new container();
		$$=$1;
		$$->text+=$2->text;
        logFile<<$$->text<<endl<<endl;
	 }
	| unit
	{
		rule_matched("program:unit");
		$$=new container();
		
		$$=$1;
		//$$->code+=$1->code;
		//$$->text+=$1->text;
        logFile<<$$->text<<endl<<endl;
	}
	;

unit : var_declaration
     {
		rule_matched("unit:var_declaration");
		$$=new container();
		$$=$1;
        logFile<<$$->text<<endl<<endl;
		$$->code+=$1->code;

	 }
     | func_declaration
	 {
		rule_matched("unit:func_declaration");
		$$=new container();
		$$=$1;
        logFile<<$$->text<<endl<<endl;
		//$$->code+=$1->code;

	 }
     | func_definition
	 {
		rule_matched("unit:func_definition");
		$$=new container();
		$$=$1;
        logFile<<$$->text<<endl<<endl;
		//$$->code+=$1->code;

	 }
     ;

func_declaration : type_specifier ID final_parameter_list SEMICOLON
        {
			rule_matched("func_declaration:type_specifier ID final_parameter_list SEMICOLON");
			$$=new container();
			$$->text+=$1->text;
			$$->text+=$2->get_name();
			$$->text+=$3->text;
			$$->text+=";";
			$$->text+="\n";
			$$->param=$3->param;
            symbolTable->EnterScope();
			if(symbolTable->grandScp())
			{
				errorFile<<"error at line "<<line_count<<": invalid scoping of "<<$2->get_name()<<endl<<endl;
				error_count++;
			}

			SymbolInfo* ptr=symbolTable->LookUp($2->get_name());
			bool ok=true;
			if(ptr!=NULL)
			{
				errorFile<<"error at line "<<line_count<<": multiple declaration of "<<$2->get_name()<<endl<<endl;
				error_count++;
				ok=false;
			}
			else
			{
				for(int i=0;i<$3->param.size();i++)
			    {
				    for(int j=0;j<i;j++)
				    if($3->param[i].se==$3->param[j].se)
				         {
					          errorFile<<"error at line "<<$3->line<<": Multiple declaration of "<<$3->param[j].se<<" in parameter "<<endl<<endl;
					          //ok=false;
							  error_count++;
				        }
			    }
			}
            if(ok) symbolTable->insert($2->get_name(),$1->type,-2,$$->param);
			symbolTable->ExitScope();
			logFile<<$$->text<<endl<<endl;
		}
		| type_specifier ID LPAREN RPAREN SEMICOLON
		{
			rule_matched("func_declaration:type_specifier ID LPAREN RPAREN SEMICOLON");
			$$=new container();
			$$->text+=$1->text;
			$$->text+=$2->get_name();
			$$->text+="(";
			$$->text+=")";
			$$->text+=";";
			$$->text+="\n";
             symbolTable->EnterScope();
			if(symbolTable->grandScp())
			{
				errorFile<<"error at line "<<line_count<<": invalid scoping of "<<$2->get_name()<<endl<<endl;
				error_count++;
			}
			SymbolInfo* ptr=symbolTable->LookUp($2->get_name());
			bool ok=true;
			if(ptr!=NULL)
			{
				errorFile<<"error at line "<<line_count<<": multiple declaration of "<<$2->get_name()<<endl<<endl;
				ok=false;
				error_count++;
			}
			else symbolTable->insert($2->get_name(),$1->type,-2,$$->param);
			symbolTable->ExitScope();
			logFile<<$$->text<<endl<<endl;
		}
		;
		 
func_definition : type_specifier ID final_parameter_list
        {
			//rule_matched("func_definition : type_specifier ID LPAREN parameter_list RPAREN  ");
			SymbolInfo* ptr=symbolTable->LookUp($2->get_name());
			bool ok=true;
			if(ptr!=NULL) 
			{
				ok=false;
				if(ptr->get_size()!=-2)
				{
					errorFile<<"error at line "<<$1->line<<": multiple declaration of "<<$2->get_name()<<endl<<endl;
					ok=false;
					error_count++;
				}
				else
				{
					if($1->type!=ptr->get_type()) 
				{
					ok=false;
					error_count++;
					errorFile<<"error at line "<<$1->line<<": Return type mismatch with function declaration in function "<<$2->get_name()<<endl<<endl;
				}	
				//cout<<line_count<<" :"<<ptr->param_list.size()<<" "<<$4->param.size()<<endl;
				if(ptr->param_list.size()!=$3->param.size())
				{
					ok=false;
					error_count++;
					errorFile<<"error at line "<<$3->line<<": Total number of arguments mismatch with declaration in function "<<$2->get_name()<<endl<<endl;

				}
				
				else
				{
					for(int i=0;i<$3->param.size();i++)
					{
						if($3->param[i].fi!=ptr->param_list[i].fi)
						{
							ok=false;
							error_count++;
							errorFile<<"error at line "<<$3->line<<": "<< i+1<<"th argument mismatch in function "<<$2->get_name()<<endl<<endl;

						}
						
					}
				}
				}
				
			}
			else 
			{
				for(int i=0;i<$3->param.size();i++)
			    {
				    for(int j=0;j<i;j++)
				       if($3->param[i].se==$3->param[j].se)
				          {
					          //ok=false;
							  error_count++;
					          errorFile<<"error at line "<<$3->line<<": Multiple declaration of "<<$3->param[j].se<<" in parameter "<<endl<<endl;
				          }
			    }
				if(ok)
			    symbolTable->insert($2->get_name(),$1->type,-2,$3->param);
			}
			symbolTable->EnterScope();
			func_sp=0;
			vector<pair<string,string> >dummy;
			for(int i=0;i<$3->param.size();i++)
			{symbolTable->insert($3->param[i].se,$3->param[i].fi,-1,dummy,func_sp);
			func_sp-=2;	
			}
            //func_sp-=4;
			sp=func_sp;
			int offset=$3->param.size();
			//offset+=4;
			fout<<$2->get_name()<<" PROC\n";
            //fout<<" MOV BP,SP\n MOV BX,"<<param_size<<"\n ADD BP,BX\n  ";
			if($2->get_name()!="main")fout<<"MOV BP,SP\n";
			//fout<<"MOV AX,6\n SUB BP,AX\n";
			fout<<";ordering the stack values, BP in bottom return address on top of it and the the parameters\n";
			for(int i=0;i<$3->param.size();i++)
			{
				fout<<"MOV AX,[BP]\n MOV BX,[BP+2]\n MOV CX,[BP+4]\n MOV [BP],CX\n MOV [BP+2],AX\n MOV [BP+4],BX\n";
				fout<<"MOV BX,2\n ADD BP,BX\n";
				//fout<<"MOV AX,[BP+2]\n  MOV [BP+2],[BP]\n MOV [BP],[BP-2]\n MOV [BP-2],AX\n MOV AX,2\n SUB BP,AX\n";
			}
           fout<<"MOV AX,2\n SUB BP,AX\n\n";
			
		} func_compound_statement
		{
			rule_matched("func_definition:type_specifier ID final_parameter_list func_compound_statement");
			$$=new container();
			$$->code+=$5->code;
			$$->text+=$1->text;
			$$->text+=$2->get_name();
			$$->text+=$3->text;
			$$->text+="\n";
			$$->text+=$5->text+"\n";
			$$->param=$3->param;
            $$->line=$3->line;
			if(symbolTable->grandScp())
			{
				errorFile<<"error at line "<<$1->line<<": invalid scoping of "<<$2->get_name()<<endl<<endl;
				error_count++;
				//errorFile<<$2->get_name()<<" "<<symbolTable->get_idSize()<<endl;
			}
			//symbolTable->print_allScp();
			symbolTable->ExitScope();
				//SymbolInfo* ptr=symbolTable->LookUp($2->get_name());
			//int ret=$3->param.size();
			//fout<<"RET \n"<<$2->get_name()<<" ENDP\n";
			fout<<$2->get_name()<<" ENDP\n\n\n";
            logFile<<$$->text<<endl<<endl;
		}
		| type_specifier ID LPAREN RPAREN 
		{
			

			SymbolInfo* ptr=symbolTable->LookUp($2->get_name());
			bool ok=true;
			if(ptr!=NULL) 
			{
				ok=false;
				if($1->type!=ptr->get_type()) 
				{
					ok=false;
					error_count++;
					errorFile<<"error at line "<<$1->line<<": Return type mismatch with function declaration in function "<<$2->get_name()<<endl<<endl;
					}
				if(ptr->param_list.size()!=0)
				{
					ok=false;
					error_count++;
					errorFile<<"error at line "<<$1->line<<": Total number of arguments mismatch with declaration in function "<<$2->get_name()<<endl<<endl;
				}
			}  
			if(ptr==NULL) symbolTable->insert($2->get_name(),$1->type,-2);
			symbolTable->EnterScope();
            sp=0;
			if($2->get_name()!="main")fout<<$2->get_name()<<" PROC\n MOV BP,SP\n";
			if($2->get_name()=="main") {
				fout<<"START:\n MAIN PROC\n MOV AX,@DATA \n MOV DS,AX\n  MOV BP,SP\n";
				mainf=1;
				seen_main=1;
				}
		}func_compound_statement
		{
			rule_matched("func_definition:type_specifier ID LPAREN RPAREN func_compound_statement");
			$$=new container();
			$$->code+=$6->code;
			cout<<$$->code<<endl;
			$$->text+=$1->text;
			$$->text+=$2->get_name();
			$$->text+="(";
			$$->text+=")";
			$$->text+="\n";
			$$->text+=$6->text+"\n";
			if(symbolTable->grandScp())
			{
				errorFile<<"error at line "<<$1->line<<": invalid scoping of "<<$2->get_name()<<endl<<endl;
				error_count++;	
			}
            //symbolTable->print_allScp();
			symbolTable->ExitScope();
			if($2->get_name()=="main") fout<<"MOV AH,4CH\n INT 21H \n";
			fout<<$2->get_name()<<" ENDP\n\n\n";
			//else fout<<"RET \n "<<$2->get_name()<<" ENDP\n";
			logFile<<$$->text<<endl<<endl;

		}
 		;				
final_parameter_list: LPAREN parameter_list RPAREN
                    {
						rule_matched("final_parameter_list: LPAREN parameter_list RPAREN");
			           $$=new container();
					   $$->text+="(";
			           $$->text+=$2->text;
			           $$->text+=")";
		               for(auto x:$2->param) $$->param.push_back(x);
			          $$->line=line_count;
			          logFile<<$$->text<<endl<<endl;
					}
					| LPAREN parameter_list error RPAREN
					{
						rule_matched("final_parameter_list: LPAREN parameter_list error RPAREN");
			           $$=new container();
					   $$->text+="(";
			           $$->text+=$2->text;
			           $$->text+=")";
		               for(auto x:$2->param) $$->param.push_back(x);
			          $$->line=line_count;
					  logFile<<"error at line "<<line_count<<": syntax error "<<endl<<endl;
			          logFile<<$$->text<<endl<<endl;
					  errorFile<<"error at line "<<line_count<<": syntax error "<<endl<<endl;
				      error_count++;
					}
					| LPAREN error RPAREN
					{
						rule_matched("final_parameter_list: LPAREN parameter_list error RPAREN");
			           $$=new container();
					   $$->text+="(";
			           $$->text+=")";
			          $$->line=line_count;

			          logFile<<"error at line "<<line_count<<": syntax error "<<endl<<endl;
			          logFile<<$$->text<<endl<<endl;
					  errorFile<<"error at line "<<line_count<<": syntax error "<<endl<<endl;
				      error_count++;
					}
					;

parameter_list  : parameter_list COMMA type_specifier ID
        {
			rule_matched("parameter_list:parameter_list COMMA type_specifier ID");
			$$=new container();
			$$->text+=$1->text;
			$$->text+=",";
			$$->text+=$3->text;
			$$->text+=$4->get_name();
		    for(auto x:$1->param) $$->param.push_back(x);
			//$$->param=$1->param;
			$$->param.push_back({$3->type,$4->get_name()});
			$$->line=line_count;
			logFile<<$$->text<<endl<<endl;
		}
		| parameter_list COMMA type_specifier
		{
			rule_matched("parameter_list:parameter_list COMMA type_specifier");
			$$=new container();
			$$->text+=$1->text;
			$$->text+=",";
			$$->text+=$3->text;
			for(auto x:$1->param) $$->param.push_back(x);
			$$->param.push_back({$1->type,""});
			$$->line=line_count;
			logFile<<$$->text<<endl<<endl;
		}
 		| type_specifier ID
		{
			rule_matched("parameter_list:type_specifier ID");
			$$=new container();
			$$->text+=$1->text;
			$$->text+=$2->get_name();
			$$->param.push_back({$1->type,$2->get_name()});
			logFile<<"here in "<<$1->name<<endl;
			$$->line=line_count;
			logFile<<$$->text<<endl<<endl;
		}
		| type_specifier
		{
			rule_matched("parameter_list:type_specifier");
			$$=new container();
			$$->text+=$1->text;
			$$->param.push_back({$1->type,""});
			$$->line=line_count;
			logFile<<$$->text<<endl<<endl;
		}
 		;

 	
compound_statement : left_curl statements right_curl 
            {
				rule_matched("compound_statement:left_curl statements right_curl");
	            $$=new container();
				$$->code+=$2->code;
				$$->text+="{";
		        $$->text+=$2->text;
				$$->text+="}";
				$$->text+="\n";
				logFile<<$$->text<<endl<<endl;
				symbolTable->print_allScp();
				cout<<endl<<endl;

			}
 		    | left_curl right_curl
			{
				rule_matched("compound_statement:left_curl right_curl");
	            $$=new container();
				$$->text+="{";
				$$->text+="}";
				$$->text+="\n";
				logFile<<$$->text<<endl<<endl;
				symbolTable->print_allScp();
				cout<<endl<<endl;
			}
 		    ;
func_compound_statement : LCURL statements RCURL
                        {
							rule_matched("func_compound_statement:LCURL statements RCURL");
	                        $$=new container();
							$$->code+=$2->code;
				            $$->text+="{";
							$$->text+="\n";
		                    $$->text+=$2->text;
				            $$->text+="}";
				            $$->text+="\n";
				            logFile<<$$->text<<endl<<endl;
							symbolTable->print_allScp();
							cout<<endl<<endl;
      
						}
						|LCURL RCURL
						{
							rule_matched("func_compound_statement:LCURL RCURL");
	                        $$=new container();
				            $$->text+="{";
							$$->text+="\n";
				            $$->text+="}";
				            $$->text+="\n";
				            logFile<<$$->text<<endl<<endl;
                              symbolTable->print_allScp();
							  cout<<endl<<endl;
						}
						;
left_curl : LCURL
           {
			rule_matched("left_curl:LCURL");
             $$=new container();
			 $$->text+="{";
			 $$->text+="\n";
            symbolTable->EnterScope();
			logFile<<$$->text<<endl<<endl;
		   };
right_curl : RCURL
           {
              rule_matched("left_curl:LCURL");
              $$=new container();
			  $$->text+="}";
			  $$->text+="\n";
              symbolTable->ExitScope();
			  logFile<<$$->text<<endl<<endl;
		   };	   
var_declaration : type_specifier declaration_list SEMICOLON
            {
				rule_matched("var_declaration:type_specifier declaration_list SEMICOLON");
				$$=new container();
				$$->text=$1->text+$2->text+";"+"\n";
				$$->line=line_count;
				//cout<<"debugging"<<endl;
				//cout<<$2->array.size()<<endl;
				if($1->type=="void")
				{
					errorFile<<"error at line "<<$1->line<<": Variable type cannot be void "<<endl<<endl;
					error_count++;
					}
				else
				{
					vector<pair<string,string> > vec;
					for(auto x:$2->v){
					bool inserted=symbolTable->insert(x.first,$1->type,x.second,vec,sp);
					if(!inserted) {
						errorFile<<"error at line "<<$2->line<<": multiple declaration of "<<x.first<<endl<<endl;
						error_count++;
						}
					else {
						//fout<<"PUSH AX\n";
						sp-=2;
						for(int i=0;i<x.second-1;i++) sp-2;
 
					}

				}
                //symbolTable->print_currentScp();
					
				}
				
				logFile<<$$->text<<endl<<endl;
                
			}
			| type_specifier declaration_list error SEMICOLON
			{
				rule_matched("var_declaration:type_specifier declaration_list error SEMICOLON");
				$$=new container();
				$$->text=$1->text+$2->text+";"+"\n";
				$$->line=line_count;
				//cout<<"debugging"<<endl;
				//cout<<$2->array.size()<<endl;
				if($1->type=="void")
				{
					errorFile<<"error at line "<<$1->line<<": Variable type cannot be void "<<endl<<endl;
					error_count++;
					}
				else
				{
					for(auto x:$2->v){
					bool inserted=symbolTable->insert(x.first,$1->type,x.second);
					if(!inserted) {
						errorFile<<"error at line "<<$2->line<<": multiple declaration of "<<x.first<<endl<<endl;
						error_count++;
						}

				}
                //symbolTable->print_currentScp();
					
				}
				logFile<<"error at line "<<$2->line<<": syntax error"<<endl<<endl;
				logFile<<$$->text<<endl<<endl;
				errorFile<<"error at line "<<$2->line<<": syntax error"<<endl<<endl;
				error_count++;
			}

 		 ;
	 
type_specifier	: INT 
            {
				rule_matched("type_specifier:INT");
				$$=new container();
				$$->type="int";
				$$->text+="int ";
				$$->line=line_count;
                logFile<<$$->text<<endl<<endl;

		    }
 		| FLOAT
		{
			rule_matched("type_specifier:FOLAT");
				$$=new container();
				$$->type="float";
				$$->text+="float ";
				$$->line=line_count;
				logFile<<$$->text<<endl<<endl;
		}
 		| VOID
		{
			rule_matched("type_specifier:VOID");
				$$=new container();
				$$->type="void";
				$$->text+="void ";
				$$->line=line_count;
				logFile<<$$->text<<endl<<endl;
		}
 		;
 		
declaration_list : declaration_list COMMA ID
           {
			  rule_matched("declaration_list:declaration_list COMMA ID");
			  $$=new container();
			  $$=$1;
			  $$->text+=",";
			  $$->text+=$3->get_name();
			  $$->v.push_back({$3->get_name(),-1});
			  $$->line=line_count;
			  fout<<"PUSH AX\n";
			  logFile<<$$->text<<endl<<endl;

		   }
		   | declaration_list error COMMA
		   {
			  rule_matched("declaration_list:declaration_list error COMMA");
			  $$=new container();
			  $$=$1;
			  $$->text+=",";
			  $$->line=line_count;
			  logFile<<"error at line "<<line_count<<": syntax error"<<endl<<endl;
			  logFile<<$$->text<<endl<<endl;
		    	errorFile<<"error at line "<<line_count<<": syntax error"<<endl<<endl;
				error_count++;
				yyerrok;

		   }
		   | declaration_list ID  ///if want to handle error like x-y,a[90] then have to add declaration_list ID LTHIRD CONST_INT RTHIRD
		   {
			rule_matched("declaration_list:declaration_list ID");
			  $$=new container();
			  $$=$1;
			  $$->text+=$2->get_name();
			  $$->v.push_back({$2->get_name(),-1});
			  $$->line=line_count;
			   fout<<"PUSH AX\n";
			  logFile<<$$->text<<endl<<endl;
		   }
 		  | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
		  {
			rule_matched("declaration_list:declaration_list COMMA ID LTHIRD CONST_INT RTHIRD");
			  $$=new container();
			  $$=$1;
			  $$->text+=",";
			  $$->text+=$3->get_name();
		      $$->text+="[";
			  $$->text+=$5->get_name();
			  $$->text+="]";
			  $$->v.push_back({$3->get_name(),stoi($5->get_name())});
			  $$->line=line_count;
			  int sz=stoi($5->get_name());
			  for(int i=0;i<sz;i++){
				fout<<"PUSH AX\n";
			  }
			  logFile<<$$->text<<endl<<endl;
		  }
		  | declaration_list COMMA ID LTHIRD CONST_FLOAT RTHIRD
		  {
			rule_matched("declaration_list:declaration_list COMMA ID LTHIRD CONST_FLOAT RTHIRD");
			  $$=new container();
			  $$=$1;
			  $$->text+=",";
			  $$->text+=$3->get_name();
		      $$->text+="[";
			  $$->text+=$5->get_name();
			  $$->text+="]";
			  $$->line=line_count;
			  //$$->v.push_back({$3->get_name(),$5->get_name()});
			  errorFile<<"error at line "<<line_count<<": invalid array size "<<$5->get_name()<<endl<<endl;
			  error_count++;
			  logFile<<$$->text<<endl<<endl;


		  }
 		  | ID
		  {
			rule_matched("declaration_list:ID");
			 $$=new container();
			 $$->text+=$1->get_name();
			 $$->v.push_back({$1->get_name(),-1});
			 $$->line=line_count;
			  fout<<"PUSH AX\n";
			 logFile<<$$->text<<endl<<endl;

		  }
 		  | ID LTHIRD CONST_INT RTHIRD
		  {
			rule_matched("declaration_list:ID LTHIRD CONST_INT RTHIRD");
			$$=new container();
			$$->text+=$1->get_name()+"["+$3->get_name()+']';
			$$->v.push_back({$1->get_name(),stoi($3->get_name())});
			$$->line=line_count;
			int sz=stoi($3->get_name());
			 for(int i=0;i<sz;i++){
				fout<<"PUSH AX\n";
				
			  }
			logFile<<$$->text<<endl<<endl;

		  }
		  | ID LTHIRD CONST_FLOAT RTHIRD
		  {
			rule_matched("declaration_list:ID LTHIRD CONST_FLOAT RTHIRD");
			$$=new container();
			$$->text+=$1->get_name()+"["+$3->get_name()+']';
			$$->line=line_count;
			//$$->array.push_back({$1->get_name(),$3->get_name()});
			errorFile<<"error at line "<<line_count<<": invalid array size "<<$1->get_name()<<endl<<endl;
			error_count++;
			logFile<<$$->text<<endl<<endl;

		  }
 		  ;
		  
statements : statement
       {
		rule_matched("statements:statement");
		$$=new container();
		$$->code+=$1->code;
		$$=$1;
		$$->line=line_count;
		logFile<<$$->text<<endl<<endl;
	   }
	   | statements statement
	   {
		rule_matched("statements:statements statement");
		$$=new container();
		$$->code+=$1->code;
		$$->code+=$2->code;
		$$->text+=$1->text;
		$$->text+=$2->text;
		$$->line=line_count;
        logFile<<$$->text<<endl<<endl;
	   }
	   ;
conditional:IF LPAREN expression RPAREN
           {
			$$=new container();
	    	$$->text+="if(";
		   $$->text+=$3->text;
		   $$->text+=")";
			label1=newLabel();
			$$->label1=label1;
		   fout<<"POP AX\n MOV CX,1 ; assuming true expression\n CMP ax,0\n JE "<<label1<<"\n";
		   sp+=2;
		   };
conditional_statement:conditional statement
         {
			$$=new container();
			$$->text+=$1->text;
		    $$->text+=$2->text;
			label2=newLabel();
			$$->label2=label2;
			$$->label1=$1->label1;
            fout<<"JMP "<<label2<<"\n"<<$1->label1<<":\n";
         };
while_epsilon:
        {
			label1=newLabel();
			fout<<label1<<":\n";
			$$=new container();
			$$->label1=label1;
			rule_matched("while_epsilon: epsilon");
			fout<<";implementing while loop\n";
		};
while_conditional:WHILE LPAREN while_epsilon expression RPAREN
        {
			rule_matched("statement:WHILE LPAREN while_epsilon expression RPAREN");
		   $$=new container();
		   $$->text+="while(";
		  $$->text+=$3->text;
		   $$->text+=")";
			label2=newLabel();
			$$->label2=label2;
			$$->label1=$3->label1;
			fout<<"POP AX\n CMP AX,0\n JZ "<<label2<<" ; checking condition\n";
			sp+=2;
			logFile<<$$->text<<endl;
		};

for_expression1:expression_statement
          {
            label1=newLabel();
		$$=new container();
		$$->text+=$1->text;
		$$->label1=label1;
		fout<<label1<<":;label for condition checking\n";
		  };
for_expression2:for_expression1 expression_statement
          {
			$$=new container();
             $$->text+=$1->text;
			 $$->text+=$2->text;
	  label2=newLabel();
	  string label3=newLabel();
	  string label4=newLabel();
	  $$->label1=$1->label1;
	  $$->label2=label2;
	  $$->label3=label3;
	  $$->label4=label4;
	  fout<<" ;didn't do any pop as after semicolon it was already pooped into AX\n CMP AX,0\n JZ "<<label4<<"\n ;out of for loop\n JMP "<<label2<<";for loop body\n"<<label3<<":\n";
	  
		  };
for_expression3:for_expression2 expression
         {
			$$=new container();
            $$->text+=$1->text;
			 $$->text+=$2->text;
			$$->label1=$1->label1;
	  $$->label2=$1->label2;
	  $$->label3=$1->label3;
	  $$->label4=$1->label4;
		 fout<<"POP Ax\n JMP "<<$$->label1<<";after operation on loop variable jump to condition checking\n "<<$$->label2<<":\n";
		 sp+=2;
		 };
statement : var_declaration
       {
		rule_matched("statement:var_declaration");
		$$=new container();
		$$->code+=$1->code;
		$$=$1;
		$$->line=line_count;
		$$->code+=$1->code;
        logFile<<$$->text<<endl<<endl;
	   }
	  | expression_statement
	  {
		rule_matched("statement:expression_statement");
		$$=new container();
		$$->code+=$1->code;
		
		$$=$1;
		cout<<"expression "<<$$->code<<endl;
		$$->line=line_count;
		$$->code+=$1->code;
        logFile<<$$->text<<endl<<endl;
	  }
	  | compound_statement
	  {
          rule_matched("statement:compound_statement");
		$$=new container();
		$$->code+=$1->code;
		$$=$1;
		$$->line=line_count;
        logFile<<$$->text<<endl<<endl;
	  }
	  | FOR LPAREN for_expression3 RPAREN statement
	  {
		rule_matched("statement:FOR LPAREN expression_statement expression_statement expression RPAREN statement");
		$$=new container();
		$$->text+="for(";
		$$->text+=$3->text;
		//$$->text+=$4->text;
		//$$->text+=$5->text;
		$$->text+=")";
		$$->text+=$5->text;
		$$->line=line_count;

		$$->label1=$3->label1;
	  $$->label2=$3->label2;
	  $$->label3=$3->label3;
	  $$->label4=$3->label4;
		fout<<"JMP "<<$$->label3<<"\n "<<$$->label4<<":\n";
        logFile<<$$->text<<endl<<endl;
	  }
	  | ///IF LPAREN expression RPAREN {
		//label1=newLabel();
		//fout<<"POP AX\n MOV CX,1 ; assuming true expression\n CMP ax,0\n JE "<<label1<<"\n";
	  //}
	  conditional_statement %prec LOWER_THAN_ELSE
	  {
		rule_matched("statement:IF LPAREN expression RPAREN statement");
		$$=new container();
		$$=$1;
		$$->line=line_count;

		fout<<$1->label2<<":\n";
        logFile<<$$->text<<endl<<endl;
	  }
	  //| IF LPAREN expression RPAREN statement ELSE statement
	  |conditional_statement ELSE statement{
		$$=new container();
		$$->text+=$1->text;
		$$->text+=" else";
		$$->text+=$3->text;
		$$->line=line_count;
		fout<<$1->label2<<":\n";
        logFile<<$$->text<<endl<<endl;
	  }
	  | while_conditional statement
	  {
		rule_matched("statement:WHILE LPAREN expression RPAREN statement");
		$$=new container();
		$$->text+=$1->text;
		$$->text+=$2->text;
		$$->line=line_count;
		fout<<"JMP "<<$1->label1<<"\n"<<$1->label2<<":\n";
        logFile<<$$->text<<endl<<endl;
	  }
	  | PRINTLN LPAREN ID RPAREN SEMICOLON
	  {
		rule_matched("statement:PRINTLN LPAREN ID RPAREN SEMICOLON");
		$$=new container();
		$$->text+="printf";
		$$->text+="(";
		$$->text+=$3->get_name();
		$$->text+=");";
		$$->text+="\n";
		$$->line=line_count;
		SymbolInfo* ptr=symbolTable->LookUp($3->get_name());
		if(ptr==NULL)
		{
			errorFile<<"error at line "<<line_count<<": undeclared variable "<<$3->get_name()<<endl<<endl;
			error_count++;
			}
		string stack_pointer=to_string(ptr->get_sp());
		fout<<"MOV AX,[BP+"+stack_pointer+"]\n  CALL OUTPUT\n CALL NEWLINE\n\n";
	  }
	  | RETURN expression SEMICOLON
	  {
		rule_matched("statement:RETURN expression SEMICOLON");
		$$=new container();
		$$->text+="return ";
		$$->text+=$2->text;
		$$->text+=";";
		$$->text+="\n";
		$$->line=line_count;
		if(!mainf)
		{
            fout<<";return "<<$2->text<<"\n";
		fout<<"POP BX\n ;the expression evaluated in the return statement now will be in bX\n";
		//int sz=symbolTable->scp_size(); /// have to change
		//for(int i=0;i<sz;i++)
		//{
		//	fout<<"POP AX\n";
		//	sp+=2;
		//} 
		//sp+=2;
		 label1=newLabel();
		 label2=newLabel();
		
		fout<<label1<<":\n MOV AX,BP\n MOV CX,SP\n CMP AX,CX\n JE "<<label2<<"\n POP AX\n ;popping off element to keep retuen address on top\nJMP "<<label1<<"\n"<<label2<<":\n POP AX\n";
		fout<<"RET \n\n";
		//sp+=2;
		}
		else mainf=0;
		
		logFile<<$$->text<<endl<<endl;
	  }
	  |func_definition
	  {
		rule_matched("statement:func_definition");
		$$=new container();
		$$=$1;
		$$->line=line_count;
		logFile<<$$->text<<endl<<endl;

	  }
	  | func_declaration
	  {
		rule_matched("statement:func_declaration");
		$$=new container();
		$$=$1;
		$$->line=line_count;
		logFile<<$$->text<<endl<<endl;

	  }
	  ;
	  
expression_statement 	: SEMICOLON			
            {
				rule_matched("expression_statement:SEMICOLON");
				$$=new container();
		       $$->text+=";";
			   $$->line=line_count;
			   logFile<<$$->text<<endl<<endl;
			}
			| expression SEMICOLON 
			{
				rule_matched("expression_statement:expression SEMICOLON");
				$$=new container();
				$$->code+=$1->code;
		       $$->text+=$1->text+";"+"\n";
			   $$->line=line_count;
			   fout<<"POP AX\n";
			   sp+=2;
			   logFile<<$$->text<<endl<<endl;
			}
			;
	  
variable : ID	
      {
		rule_matched("variable:ID");
		$$=new container();
		$$->text+=$1->get_name();
		$$->line=line_count;
		SymbolInfo* tmp=symbolTable->LookUp($1->get_name());
		$$->sp=tmp->get_sp();
		if(tmp==NULL) {
			errorFile<<"error at line "<<line_count<<": undeclared variable "<<$1->get_name()<<endl<<endl;
			error_count++;
		}
		else 
		{
			$$->type=tmp->get_type();
		$$->name=tmp->get_name();
		//$$->size=tmp->get_size();
		if(tmp->get_size() !=-1) {
			errorFile<<"error at line "<<line_count<<": type mismatch, "<<$1->get_name()<<" is an array"<<endl<<endl;
			error_count++;
			}

		}
		logFile<<$$->text<<endl<<endl;
		
	  }	
	 | ID LTHIRD expression RTHIRD 
	 {
		rule_matched("variable:ID LTHIRD expression RTHIRD");
		$$=new container();
		$$->text+=$1->get_name();
		$$->text+="[";
		$$->text+=$3->text;
		$$->text+="]";
        $$->line=line_count;
		SymbolInfo* tmp=symbolTable->LookUp($1->get_name());
		if(tmp==NULL) {
			errorFile<<"error at line "<<line_count<<": undeclared variable "<<$1->get_name()<<endl<<endl;
			error_count++;
			}
		else 
		{

		$$->type=tmp->get_type();
		$$->name=tmp->get_name();
		if(tmp->get_size() ==-1) errorFile<<"error at line "<<line_count<<": "<<$1->get_name()<<" is a variable"<<endl<<endl;
		if($3->type=="float" || $3->type=="CONST_FLOAT")
		{
			errorFile<<"error at line "<<line_count<<": Expression inside third brackets not an integer"<<endl<<endl;
			error_count++;
			}
		int dec_size=tmp->get_size();
		//int used_size=$3->val;
		//if(used_size-1>dec_size) errorFile<<"line : "<<$1->get_name()<<" index out of bounds";

		}
		$$->sp=tmp->get_sp();
		logFile<<$$->text<<endl<<endl;
		
	  }	
	 ;
 
 expression : logic_expression	
        {
			rule_matched("expression:logic_expression ");
			$$=new container();
			$$->code+=$1->code;
	        $$=$1;
			$$->line=line_count;
			logFile<<$$->text<<endl<<endl;
		}
	   | variable ASSIGNOP logic_expression 
	   {
		 rule_matched("expression:variable ASSIGNOP logic_expression");
		$$=new container();
		$$->text+=$1->text;
		$$->text+="=";
		$$->text+=$3->text;
		$$->line=line_count;
		if(($1->type=="float" && $3->type=="int")||($1->type=="float" && $3->type=="CONST_INT")||($1->type=="float" && $3->type=="CONST_FLOAT")||($1->type=="int" && $3->type=="CONST_INT"));
		else if($1->type!=$3->type && ($3->type=="CONST_INT" || $3->type=="CONST_FLOAT"))
		{
			errorFile<<"error at line "<<line_count<<": Type mismatch here 832"<<endl<<endl;
			error_count++;
			}
		if($3->type=="void") 
		{
			errorFile<<"error at line "<<line_count<<": Void function used in expression"<<endl<<endl;
			error_count++;
			}

		SymbolInfo* tmp=symbolTable->LookUp($1->name);
	   int stack_pointer;
	   stack_pointer=$1->sp;
	   fout<<";"<<$1->text<<" =="<<" "<<$3->text<<"\n";
	   if(tmp->get_size()==-1){
         fout<<"POP AX\n MOV [BP+"<<stack_pointer<<"],AX\n PUSH AX\n";
	   }
	   else
	   {
		fout<<"POP CX\n POP AX\n MOV BX,2\n IMUL BX\n SUB AX,"<<stack_pointer<<"\n NEG AX\n MOV BX,BP ;SAVING BP\nMOV BP,AX\n";
		fout<<"ADD BP,BX\n MOV [BP],CX\n PUSH CX\n MOV BP,BX ; RESTORING BP\n";
		sp+=2;
	   }
	   fout<<"\n";
	
		//cout<<"expression:logic exp \n"<<$$->code<<endl;
		logFile<<$$->text<<endl<<endl;

	   }	
	   ;
			
logic_expression : rel_expression 	
         {
			rule_matched("logic_expression:rel_expression");
			$$=new container();
			$$->code+=$1->code;
	        $$=$1;
			logFile<<$$->text<<endl<<endl;
		 }
		 | rel_expression LOGICOP rel_expression 	
		 {
			rule_matched("logic_expression:rel_expression LOGICOP rel_expression");
			$$=new container();
	        $$->text+=$1->text;
			$$->text+=$2->get_name();
			$$->text+=$3->text;
           //if($1->type!="int" || $3->type!="int") errorFile<<"error at line "<<line_count<<": type mismatch, "<<$5->get_name()<<"is an array"<<endl<<endl;
			if($1->type=="float" || $3->type=="float") $$->type="float";
			else if( $1->type=="CONST_FLOAT" || $3->type=="CONST_FLOAT" ) $$->type="CONST_FLOAT";
			else $$->type="int";
			//if($$->type=="float" || $$->type=="CONST_FLOAT")
			//errorFile<<"error at line "<<line_count<<": non-integer operand used in logical expression"<<endl<<endl;
			if($3->type=="void" || $1->type=="void") 
		    {errorFile<<"error at line "<<line_count<<": Void function used in expression"<<endl<<endl;
			error_count++;
			}
			fout<<";"<<$1->text<<" "<<$2->get_name()<<" "<<$3->text<<"\n";
			if($2->get_name()=="&&") {
				label1=newLabel();
				label2=newLabel();
				fout<<"POP AX\n POP BX\n CMP AX,0\n JE "<<label1<<"\n CMP BX,0\n JE "<<label1<<"\n MOV CX,1\n JMP "<<label2<<"\n"<<label1<<":\n MOV CX,0\n "<<label2<<":\n";
				fout<<"PUSH CX\n";
				}
			else {
				label1=newLabel();
				label2=newLabel();
				fout<<"POP AX\n POP BX\n CMP AX,0\n JNE "<<label1<<"\n CMP BX,0\n JNE "<<label1<<"\n MOV CX,0\n JMP "<<label2<<"\n"<<label1<<":\n MOV CX,1\n"<<label2<<":\n";
				fout<<"PUSH CX\n";
				//fout<<"POP AX\n POP BX\n OR AX,BX\n PUSH AX\n";
				}
			fout<<"\n";
			sp+=2;
			logFile<<$$->text<<endl<<endl;
		 }
		 ;
rel_expression	: simple_expression 
        {
			rule_matched("rel_expression:simple_expression");
			$$=new container();
	        $$=$1;
			$$->line=line_count;
			//cout<<"rel_exp\n"<<$$->code<<endl;
			logFile<<$$->text<<endl<<endl;
		}
		| simple_expression RELOP simple_expression	
		{
			rule_matched("rel_expression:simple_expression RELOP simple_expression ");
			$$=new container();
	        $$->text+=$1->text;
			$$->text+=$2->get_name();
			$$->text+=$3->text;
			$$->line=line_count;
           //if($1->type!="int" || $3->type!="int") errorFile<<"line : "<<" non-integer operand in relational operator "<<endl;
			//if($1->type!="float" || $3->type!="float") $$->type="float";
		    $$->type="int";
		    if($3->type=="void" || $1->type=="void") 
		    {
				errorFile<<"error at line "<<line_count<<": Void function used in expression"<<endl<<endl;
				error_count++;
				}
				fout<<";"<<$1->text<<" "<<$2->get_name()<<" "<<$3->text<<"\n";
            string label=newLabel();
			if($2->get_name()=="<") fout<<"MOV CX,1; assuming true relation\n POP AX\n POP BX\n CMP BX,AX\n JL "<<label<<"\n MOV CX,0\n"<<label<<":\n PUSH CX\n";
			else if($2->get_name()=="<=") fout<<"MOV CX,1; assuming true relation\n POP AX\n POP BX\n CMP BX,AX\n JLE "<<label<<"\n MOV CX,0\n"<<label<<":\n PUSH CX\n";
			else if($2->get_name()==">") fout<<"MOV CX,1; assuming true relation\n POP AX\n POP BX\n CMP BX,AX\n JG "<<label<<"\n MOV CX,0\n"<<label<<":\n PUSH CX\n";
			else if($2->get_name()==">=") fout<<"MOV CX,1; assuming true relation\n POP AX\n POP BX\n CMP BX,AX\n JGE "<<label<<"\n MOV CX,0\n"<<label<<":\n PUSH CX\n";
			else if($2->get_name()=="==") fout<<"MOV CX,1; assuming true relation\n POP AX\n POP BX\n CMP BX,AX\n JE "<<label<<"\n MOV CX,0\n"<<label<<":\n PUSH CX\n";
			else if($2->get_name()=="!=") fout<<"MOV CX,1; assuming true relation\n POP AX\n POP BX\n CMP BX,AX\n JNE "<<label<<"\n MOV CX,0\n"<<label<<":\n PUSH CX\n";
			sp+=2;
			fout<<"\n";
			logFile<<$$->text<<endl<<endl;

		}
		;	
simple_expression : term 
          {
			rule_matched("simple_expression:term");
			$$=new container();
	        $$=$1;
			$$->line=line_count;
			logFile<<$$->text<<endl<<endl;
		  }
		  | simple_expression ADDOP term 
		  {
			rule_matched("simple_expression:simple_expression ADDOP term");
			$$=new container();
	        $$->text+=$1->text;
			$$->text+=$2->get_name();
			$$->text+=$3->text;
			$$->line=line_count;

			if($1->type=="float" || $3->type=="float") $$->type="float";
			else if( $1->type=="CONST_FLOAT" || $3->type=="CONST_FLOAT" ) $$->type="CONST_FLOAT";
			else $$->type="int";

			if($3->type=="void" || $1->type=="void") 
		    {
				errorFile<<"error at line "<<line_count<<": Void function used in expression"<<endl<<endl;
				error_count++;
				}
			logFile<<$$->text<<endl<<endl;
			//$$->code+=$1->code;
			fout<<";"<<$1->text<<" "<<$2->get_name()<<" "<<$3->text<<"\n";
			if($2->get_name()=="+") fout<<"POP AX\n POP BX\n ADD AX,BX\n PUSH AX\n";
			else fout<<"POP AX\n POP BX\n SUB BX,AX\n PUSH BX\n";
			fout<<"\n";
			//$$->code+=$3->code;
			sp+=2;

		  }
		  ;
					
term :	unary_expression
     {
		    rule_matched("term:unary_expression");
			$$=new container();
	        $$=$1;
			$$->line=line_count;
			logFile<<$$->text<<endl<<endl;
	 }
     |  term MULOP unary_expression
	 {
		rule_matched("term:term MULOP unary_expression");
			$$=new container();
	        $$->text=$1->text;
	        $$->text+=$2->get_name();
			$$->text+=$3->text;
			$$->line=line_count;
			if($2->get_name()=="%")
			{
				if(($1->type!="int" && $1->type!="CONST_INT") || ($3->type!="int" && $3->type!="CONST_INT")) {errorFile<<"error at line "<<line_count<<": Non-Integer operand on modulus operator"<<endl<<endl; error_count++;}
				if(($3->type=="CONST_INT" || $3->type=="CONST_FLOAT") && ($3->name=="0")) 
				{
					errorFile<<"error at line "<<line_count<<": Modulus by zero"<<endl<<endl;
					error_count++;
					}

			}
			if($2->get_name()=="/")
			{
				if(($1->type=="CONST_INT" || $3->type=="CONST_FLOAT") && ($3->name=="0")) 
				{
					errorFile<<"error at line "<<line_count<<": Division by zero"<<endl<<endl;
					error_count++;
					}

			}
            if($1->type=="float" || $3->type=="float") $$->type="float";
			else if( $1->type=="CONST_FLOAT" || $3->type=="CONST_FLOAT" ) $$->type="CONST_FLOAT";
			else $$->type="int";

			if($3->type=="void" || $1->type=="void") 
		    {
				errorFile<<"error at line "<<line_count<<": Void function used in expression"<<endl<<endl;
				error_count++;
				}
			fout<<";"<<$1->text<<" "<<$2->get_name()<<" "<<$3->text<<"\n";
			if($2->get_name()=="*")fout<<"POP AX\n POP BX\n IMUL BX\n PUSH AX\n";
			else if($2->get_name()=="/" ) fout<<"MOV DX,0 \n POP BX\n POP AX\n IDIV BX\n PUSH AX\n";
			else fout<<"MOV DX,0 \n POP BX\n POP AX\n IDIV BX\n PUSH DX\n";
			fout<<"\n";
			sp+=2;
			logFile<<$$->text<<endl<<endl;


	 }
     ;

unary_expression : ADDOP unary_expression  
         {
			rule_matched("unary_expression:ADDOP unary_expression");
			$$=new container();
	        $$->text=$1->get_name();
	        $$->text+=$2->text;
			$$->type=$2->type;
			$$->line=line_count;
			if($2->type=="void" ) 
		    {
				errorFile<<"error at line "<<line_count<<": Void function used in expression"<<endl<<endl;
				error_count++;
				}
			fout<<";ADDOP "<<$2->text<<"\n";
			if($1->get_name()=="-")fout<<"POP BX\n NEG BX\n PUSH BX\n\n";
			else fout<<"POP BX\n  PUSH BX\n\n";
			logFile<<$$->text<<endl<<endl;
		 }
		 | NOT unary_expression 
		 {
			rule_matched("unary_expression:NOT unary_expression");
			$$=new container();
	        $$->text="!";
	        $$->text+=$2->text;
			$$->type=$2->type;
			$$->line=line_count;
			if($2->type=="void" ) 
		    {errorFile<<"error at line "<<line_count<<": Void function used in expression"<<endl<<endl;
			error_count++;
			}
			fout<<";NOT "<<$2->text<<"\n";
			fout<<"POP BX\n NOT BX\n PUSH BX\n\n";
			logFile<<$$->text<<endl<<endl;
		 }
		 | factor 
		 {
			rule_matched("unary_expression:factor");
			$$=new container();
	        $$=$1;
			$$->line=line_count;
			logFile<<$$->text<<endl<<endl;
		 }
		 ;
	
factor	: variable 
     {
		rule_matched("factor:variable");
       $$=new container();
	   $$=$1;
	   $$->line=line_count;
	   SymbolInfo* tmp=symbolTable->LookUp($1->name);
	   int stack_pointer;
	   stack_pointer=$1->sp;
	   
	   if(tmp->get_size()==-1){
		fout<<";storing "<<$1->text<<"\n\n";
		fout<<"MOV BX,[BP+"<<stack_pointer<<"]\n PUSH BX\n\n";
		sp-=2;
		}
	   else
	   {
		fout<<";storing "<<$1->text<<" calculating index offset\n\n";
		fout<<"POP AX\n MOV BX,2\n IMUL BX\n SUB AX,"<<stack_pointer<<"\n NEG AX\n MOV BX,BP ;SAVING BP\nMOV BP,AX\n";
		fout<<"ADD BP,BX\n MOV CX,[BP]\n PUSH CX\n MOV BP,BX ; RESTORING BP\n\n";
	   }
	   
	   
	   logFile<<$$->text<<endl<<endl;
     }
	| ID LPAREN argument_list RPAREN
	{
		rule_matched("factor:ID LPAREN argument_list RPAREN");
		$$=new container();
		$$->text+=$1->get_name();
		$$->text+="(";
		$$->text+=$3->text;
		$$->text+=")";
	    $$->argument=$3->argument;
		$$->line=line_count;
		SymbolInfo* ptr=symbolTable->LookUp($1->get_name());
			if(ptr!=NULL) 
			{
				$$->type=ptr->get_type();
			   // cout<<line_count<<" "<<ptr->param_list.size()<<" "<<$3->argument.size()<<endl;
				if(ptr->param_list.size()!=$3->argument.size())
				{
					errorFile<<"error at line "<<line_count<<": Total number of arguments mismatch in function "<<$1->get_name()<<endl<<endl;
					error_count++;
					}
				else
				{
					for(int i=0;i<$3->argument.size();i++)
					{
						string P=ptr->param_list[i].fi,A=$3->argument[i];
						cout<<"709:"<<$3->argument[i]<< " "<<ptr->param_list[i].fi<<endl;
						if((P=="float" && A=="int")||(P=="float" && A=="CONST_IINT")||(P=="float" && A=="CONST_FLOAT")||(P=="int" && A=="CONST_INT")); 
						else if(P!=A)
						{errorFile<<"error at line "<<line_count<<": "<< i+1<<"th argument mismatch in function "<<$1->get_name()<<endl<<endl;
						error_count++;
						}
					}
				}
			}
		   else 
		   {errorFile<<"error at line "<<line_count<<": undeclared function "<<$1->get_name()<<endl<<endl;
		   error_count++;
		   }
		int param_size=ptr->param_list.size();
		param_size*=2;
		//param_size-=2;
		//fout<<" MOV BP,SP\n MOV BX,"<<param_size<<"\n ADD BP,BX\n  ";
		//sp-2;
		fout<<";"<<$1->get_name()<<"("<<$3->text<<")\n";
		fout<<"MOV DX,BP\n PUSH DX\n ;saving BP before function call \n CALL "<<$1->get_name()<<"\n ";
		sp+=param_size;
		//sp-2;
		//fout<<"POP AX\n MOV BP,AX\n";
		//fout<<" MOV BP,SP\n MOV BX,"<<param_size<<"\n ADD BP,BX\n  ";
		//sp-=2;
		fout<<"POP AX\n MOV BP,AX\n PUSH BX ; functions wil keep their results in BX\n\n";	
		sp-=2;
		logFile<<$$->text<<endl<<endl;
	}
	| ID LPAREN error RPAREN
	{
		rule_matched("factor:LPAREN error RPAREN");
		 $$=new container();
		  $$->text+=$1->get_name();
		 $$->text+="(";
		 $$->text+=")";
	     $$->line=line_count;
	     logFile<<$$->text<<endl<<endl;
		 errorFile<<"error at line "<<line_count<<": syntax error"<<endl<<endl;
		   error_count++;
	}
	| LPAREN expression RPAREN
	{
		rule_matched("factor:LPAREN expression RPAREN");
            $$=new container();
			$$->text+="(";
	        $$->text+=$2->text;
			$$->text+=")";
			$$->line=line_count;
	        logFile<<$$->text<<endl<<endl;
	}
	| CONST_INT 
	{
		rule_matched("factor:CONST_INT");
       $$=new container();
	   $$->text+=$1->get_name();
	   $$->type="CONST_INT";
	   $$->name=$1->get_name();
	   $$->line=line_count;
	   //$$->code+="PUSH "+$1->get_name()+"\n";
	   //fout<<";"<<$1->get_name()<<"\n";
	   fout<<"PUSH "<<$1->get_name()<<"\n";
	   sp-=2;
	   logFile<<$$->text<<endl<<endl;
	}
	| CONST_FLOAT
	{
		rule_matched("factor:CONST_FLOAT");
       $$=new container();
	   $$->text+=$1->get_name();
	   $$->type="CONST_FLOAT";
	    $$->name=$1->get_name();
	   $$->line=line_count;
	   logFile<<$$->text<<endl<<endl;
	   errorFile<<"Float not supported\n";
	}
	| variable INCOP 
	{
		rule_matched("factor:variable INCOP");
       $$=new container();
	   $$->text+=$1->text;
	   $$->text+="++";

	   SymbolInfo* tmp=symbolTable->LookUp($1->name);
	   int stack_pointer;
	   stack_pointer=$1->sp;
	   fout<<";"<<$1->text<<"++\n";
	   if(tmp->get_size()==-1){
		
		fout<<"MOV BX,[BP+"<<stack_pointer<<"]\n  PUSH BX\n  INC BX\n MOV [BP+"<<stack_pointer<<"],BX\n";
		sp-2;
		}
	   else
	   {
		fout<<"POP AX\n MOV BX,2\n IMUL BX\n ADD AX,"<<stack_pointer<<"\n MOV BX,BP ;SAVING BP\n MOV BP,AX\n";
		fout<<"ADD BP,BX\n MOV CX,[BP]\n PUSH CX\n INC CX\n MOV [BP],CX\n MOV BP,BX ; RESTORING BP\n";
	   }
	   
	   fout<<"\n\n";
	   
	   logFile<<$$->text<<endl<<endl;
	}
	| variable DECOP
	{
		rule_matched("factor:variable DECOP");
       $$=new container();
	   $$->text+=$1->text;
	   $$->text+="--";
	   $$->line=line_count;
	   SymbolInfo* tmp=symbolTable->LookUp($1->name);
	   int stack_pointer;
	   stack_pointer=$1->sp;
	   fout<<";"<<$1->text<<"--\n";
	   if(tmp->get_size()==-1){
		
		fout<<"MOV BX,[BP+"<<stack_pointer<<"]\n  PUSH BX\n  DEC BX\n MOV [BP+"<<stack_pointer<<"],BX\n";
		sp-2;
		}
	   else
	   {
		fout<<"POP AX\n MOV BX,2\n IMUL BX\n ADD AX,"<<stack_pointer<<"\n MOV BX,BP ;SAVING BP\n MOV BP,AX\n";
		fout<<"ADD BP,BX\n MOV CX,[BP]\n PUSH CX\n DEC CX\n MOV [BP],CX\n MOV BP,BX ; RESTORING BP\n";
	   }
	   
	   fout<<"\n\n";
	   logFile<<$$->text<<endl<<endl;
	}
	;
	
argument_list : arguments
              {
				rule_matched("argument_list:arguments");
               $$=new container();
	           $$=$1;
			   $$->line=line_count;
	           logFile<<$$->text<<endl<<endl;
			  }
			  |
			  {
				rule_matched("argument_list:epsilon ");
               $$=new container();
			   $$->line=line_count;
	           //$$=$1;
	           logFile<<$$->text<<endl<<endl;
			  }
			  ;
	
arguments : arguments COMMA logic_expression
          {
			rule_matched("arguments:arguments COMMA logic_expression");
            $$=new container();
	        $$->text+=$1->text;
			$$->text+=",";
			$$->text+=$3->text;
			$$->argument=$1->argument;
			$$->argument.push_back($3->type);
			$$->line=line_count;
	        logFile<<$$->text<<endl<<endl;
		  }
	      | logic_expression
		  {
			rule_matched("arguments:logic_expression");
            $$=new container();
	        $$->text+=$1->text;
			$$->argument.push_back($1->type);
			$$->line=line_count;
	        logFile<<$$->text<<endl<<endl;
		  }
	      ;
 

%%
int main(int argc,char *argv[])
{

	 if(argc!=2){
		printf("Please provide input file name and try again\n");
		return 0;
	}
	
	FILE *fin=fopen(argv[1],"r");
	if(fin==NULL){
		printf("Cannot open specified file\n");
		return 0;
	}

    logFile.open("log.txt");
	errorFile.open("error.txt");
	fout.open("code.asm");
	fout<<".MODEL SMALL\n\n\n .STACK 400H\n\n\n .DATA\n\n\n CR EQU 0DH\n LF EQU 0AH\n\n  .CODE \n\n JMP START\n\n\n ";
    yyin=fin;
	yyparse();
	logFile.close();
	errorFile.close();
	fout.close();
	opfout.open("optimized_code.asm");
	optimize_code();

    symbolTable->print_allScp();
    cout<<endl<<endl;
    logFile<<"Total lines: "<<line_count<<endl;
    logFile<<"Total errors: "<<error_count<<endl;

    fclose(yyin);

    //logout.close();
	//errout.close();

    exit(0);
}

