
%{
#include<bits/stdc++.h>
using namespace std;
#include<stdlib.h>
#include<iostream>
#include<fstream>
#include  "symbolTable.cpp"
#include  "carrier.cpp"
#define fi first
#define se second

ofstream logFile;
ofstream errorFile;

int line_count=1;
int error_count=0 ;

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
%type <abc> func_compound_statement final_parameter_list

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

start : program
	{
		//write your code in this block in all the similar blocks below
		rule_matched("start:program");
		$$=new container();
		$$=$1;
		//logFile<<$$->text<<endl<<endl;
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
		//$$->text+=$2->text;
        logFile<<$$->text<<endl<<endl;
	}
	;

unit : var_declaration
     {
		rule_matched("unit:var_declaration");
		$$=new container();
		$$=$1;
        logFile<<$$->text<<endl<<endl;

	 }
     | func_declaration
	 {
		rule_matched("unit:func_declaration");
		$$=new container();
		$$=$1;
        logFile<<$$->text<<endl<<endl;

	 }
     | func_definition
	 {
		rule_matched("unit:func_definition");
		$$=new container();
		$$=$1;
        logFile<<$$->text<<endl<<endl;

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
			for(auto x:$3->param)
			{symbolTable->insert(x.se,x.fi);	
			}
			
		} func_compound_statement
		{
			rule_matched("func_definition:type_specifier ID final_parameter_list func_compound_statement");
			$$=new container();
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
		}func_compound_statement
		{
			rule_matched("func_definition:type_specifier ID LPAREN RPAREN compound_statement");
			$$=new container();
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
					for(auto x:$2->v){
					bool inserted=symbolTable->insert(x.first,$1->type,x.second);
					if(!inserted) {
						errorFile<<"error at line "<<$2->line<<": multiple declaration of "<<x.first<<endl<<endl;
						error_count++;
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
			 logFile<<$$->text<<endl<<endl;

		  }
 		  | ID LTHIRD CONST_INT RTHIRD
		  {
			rule_matched("declaration_list:ID LTHIRD CONST_INT RTHIRD");
			$$=new container();
			$$->text+=$1->get_name()+"["+$3->get_name()+']';
			$$->v.push_back({$1->get_name(),stoi($3->get_name())});
			$$->line=line_count;
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
		$$=$1;
		$$->line=line_count;
		logFile<<$$->text<<endl<<endl;
	   }
	   | statements statement
	   {
		rule_matched("statements:statements statement");
		$$=new container();
		$$->text+=$1->text;
		$$->text+=$2->text;
		$$->line=line_count;
        logFile<<$$->text<<endl<<endl;
	   }
	   ;
	   
statement : var_declaration
       {
		rule_matched("statement:var_declaration");
		$$=new container();
		$$=$1;
		$$->line=line_count;
        logFile<<$$->text<<endl<<endl;
	   }
	  | expression_statement
	  {
		rule_matched("statement:expression_statement");
		$$=new container();
		$$=$1;
		$$->line=line_count;
        logFile<<$$->text<<endl<<endl;
	  }
	  | compound_statement
	  {
          rule_matched("statement:compound_statement");
		$$=new container();
		$$=$1;
		$$->line=line_count;
        logFile<<$$->text<<endl<<endl;
	  }
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement
	  {
		rule_matched("statement:FOR LPAREN expression_statement expression_statement expression RPAREN statement");
		$$=new container();
		$$->text+="for(";
		$$->text+=$3->text;
		$$->text+=$4->text;
		$$->text+=$5->text;
		$$->text+=")";
		$$->text+=$7->text;
		$$->line=line_count;
        logFile<<$$->text<<endl<<endl;
	  }
	  | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
	  {
		rule_matched("statement:IF LPAREN expression RPAREN statement");
		$$=new container();
		$$->text+="if(";
		$$->text+=$3->text;
		$$->text+=")";
		$$->text+=$5->text;
		$$->line=line_count;
        logFile<<$$->text<<endl<<endl;
	  }
	  | IF LPAREN expression RPAREN statement ELSE statement
	  {
		rule_matched("statement:IF LPAREN expression RPAREN statement ELSE statement");
		$$=new container();
		$$->text+="if(";
		$$->text+=$3->text;
		$$->text+=")";
		$$->text+=$5->text;
		$$->text+=" else";
		$$->text+=$7->text;
		$$->line=line_count;
        logFile<<$$->text<<endl<<endl;
	  }
	  | WHILE LPAREN expression RPAREN statement
	  {
		rule_matched("statement:WHILE LPAREN expression RPAREN statement");
		$$=new container();
		$$->text+="while(";
		$$->text+=$3->text;
		$$->text+=")";
		$$->text+=$5->text;
		$$->line=line_count;
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
		logFile<<$$->text<<endl<<endl;
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
		       $$->text+=$1->text+";"+"\n";
			   $$->line=line_count;
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
		logFile<<$$->text<<endl<<endl;
		
	  }	
	 ;
 
 expression : logic_expression	
        {
			rule_matched("expression:logic_expression ");
			$$=new container();
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
			errorFile<<"error at line "<<line_count<<": Type mismatch "<<endl<<endl;
			error_count++;
			}
		if($3->type=="void") 
		{
			errorFile<<"error at line "<<line_count<<": Void function used in expression"<<endl<<endl;
			error_count++;
			}
		logFile<<$$->text<<endl<<endl;

	   }	
	   ;
			
logic_expression : rel_expression 	
         {
			rule_matched("logic_expression:rel_expression");
			$$=new container();
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
			logFile<<$$->text<<endl<<endl;
		 }
		 ;
rel_expression	: simple_expression 
        {
			rule_matched("rel_expression:simple_expression");
			$$=new container();
	        $$=$1;
			$$->line=line_count;
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
	}
	| variable INCOP 
	{
		rule_matched("factor:variable INCOP");
       $$=new container();
	   $$->text+=$1->text;
	   $$->text+="++";
	   logFile<<$$->text<<endl<<endl;
	}
	| variable DECOP
	{
		rule_matched("factor:variable DECOP");
       $$=new container();
	   $$->text+=$1->text;
	   $$->text+="--";
	   $$->line=line_count;
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

    yyin=fin;
	yyparse();

    symbolTable->print_allScp();
    cout<<endl<<endl;
    logFile<<"Total lines: "<<line_count<<endl;
    logFile<<"Total errors: "<<error_count<<endl;

    fclose(yyin);

    //logout.close();
	//errout.close();

    exit(0);
}

