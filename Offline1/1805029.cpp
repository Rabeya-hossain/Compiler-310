#include<bits/stdc++.h>
#include<iostream>
#include<fstream>
#include<list>
using namespace std;
#define pb push_back
#define gap ' '
#define inf 1e9

int get_hash(string name,int mod)
{
    unsigned long hash = 0;
    int c;

    for(int i=0; i<name.size(); i++)
    {
        c=name[i];
        hash = c + (hash << 6) + (hash << 16) - hash;
    }

    return hash%mod;
}

void print_id(vector<int> id)
{
    cout<<"# ";
    for(int i=0;i<id.size()-1;i++)
        cout<<id[i]<<".";
    cout<<id.back()<<gap;
}

class SymbolInfo
{
    string name;
    string type;
    SymbolInfo *nxt=NULL;
public:

    string get_name()
    {
        return name;
    }
    void set_name(string name)
    {
        this->name=name;
    }
    string get_type()
    {
        return type;
    }
    void set_type(string type)
    {
        this->type=type;
    }
    SymbolInfo* get_nxt()
    {
        return nxt;
    }
    void set_nxt(SymbolInfo* nxt_p)
    {
        nxt=nxt_p;
    }
    ~SymbolInfo()
    {
       // cout<<"destroying symbolInfo"<<endl;
    }

};



class ScopeTable
{
    SymbolInfo **Hash;
    vector<int> id;
    int bucket;
    ScopeTable *parentScope;
public:
    ScopeTable(int n,vector<int> id)
    {
        Hash=new SymbolInfo*[n];
        for(int i=0;i<n;i++) Hash[i]=NULL;
        this->id=id;
        bucket=n;
        parentScope=NULL;
    }
    ScopeTable* get_parentScope()
    {
        return parentScope;
    }
    void set_parentScope(ScopeTable* parScp)
    {
        parentScope=parScp;
    }
    bool insert(string name,string type)
    {
       int indx=get_hash(name,bucket);
       SymbolInfo *current=Hash[indx];
       SymbolInfo * pre=NULL;
       int pos=0;
       while(current!=NULL)
       {
           if(current->get_name()==name)
           {
               cout<<name<<" already exists"<<endl;
               return false;
           }

           pre=current;
           current=current->get_nxt();
           pos++;
       }
       if(pre==NULL)
       {
           SymbolInfo *obj=new SymbolInfo;
           obj->set_name(name);
           obj->set_type(type);
           obj->set_nxt(NULL);
           Hash[indx]=obj;
       }
       else
       {
           SymbolInfo *obj=new SymbolInfo;
           obj->set_name(name);
           obj->set_type(type);
           obj->set_nxt(NULL);

           pre->set_nxt(obj);
       }
       cout<<"inserted at scope table ";
       print_id(id);
       cout<<" at position "<<indx<<" , "<<pos<<endl;
       return true;

    }
    SymbolInfo* lookup(string name)
    {
        int indx=get_hash(name,bucket);
       SymbolInfo *current=Hash[indx];
       int pos=0;
       while(current!=NULL)
       {
           if(current->get_name()==name){
            cout<<"Found in scopeTable ";
           print_id(id);
           cout<<" at position "<<indx<<" , "<<pos<<endl;
           return current;
           }
           current=current->get_nxt();
           pos++;
       }
       return  current;
    }
    bool Delete(string name)
    {
        int indx=get_hash(name,bucket);

       SymbolInfo *current=Hash[indx];
       SymbolInfo * pre=NULL;
       int pos=0;
       while(current!=NULL && current->get_name()!=name)
       {
           pre=current;
           current=current->get_nxt();
           pos++;
       }
       if(current==NULL) {
            cout<<"Not found"<<endl;
            return false;
       }
       if(pre==NULL)
       {
           Hash[indx]=current->get_nxt();
           cout<<"Found in scopetable ";
           print_id(id);
           cout<<"at position "<<indx<<" , "<<pos<<endl;
           cout<<"deleted entry "<<indx<<" , "<<pos<<" from current scope table"<<endl;
           delete current;
           return true;
       }
       else
       {
           pre->set_nxt(current->get_nxt());
           delete current;
           return true;
       }
    }

    void print()
    {
        cout<<"ScopeTable ";
        print_id(id);
        cout<<endl;
        for(int i=0;i<bucket;i++)
        {
            cout<<i<<"--> ";
            SymbolInfo *current=Hash[i];
            while(current!=NULL)
            {
                cout<<"  < "<<current->get_name()<<" , "<<current->get_type()<<" >";
                current=current->get_nxt();
            }
            cout<<endl;
        }
    }
    ~ScopeTable()
    {
        //cout<<"destroying scope"<<endl;
        for(int i=0;i<bucket;i++) {
            SymbolInfo *current=Hash[i];
            while(current!=NULL)
            {
                SymbolInfo *tmp=current;
                current=tmp->get_nxt();
                delete tmp;
            }
        }
        delete Hash;
    }

};


class SymbolTable{
    ScopeTable *cur_scope;
    int bucket;
    vector<int> id;
    bool close;
public:
    SymbolTable(int n)
    {
        bucket=n;
        id.pb(1);
        cur_scope=new ScopeTable(n,id);
        close=false;
    }
    void EnterScope()
    {
        if(close)
            {
                if(id.size())
                id.back()++;
                else id.pb(1);
                }
        else id.pb(1);
        ScopeTable *scp=new ScopeTable(bucket,id);
        scp->set_parentScope(cur_scope);
        cur_scope=scp;

        close=false;

        cout<<"New ScopeTable with id ";
        print_id(id);
        cout<<" created"<<endl;
    }
    void ExitScope(){
        if(cur_scope==NULL) cout<<"It is not currently under any scope"<<endl;
        else
        {
            ScopeTable *pre=cur_scope->get_parentScope();
            delete cur_scope;
            cur_scope=pre;

            if(close)
            id.pop_back();
            cout<<"scope table with id ";
            print_id(id);
            cout<<"removed."<<endl;
        }

        close=true;
    }
    bool insert(string name,string type)
    {
        if(cur_scope!=NULL)
        return cur_scope->insert(name,type);
        else
        {
            id.clear();
           id.pb(1);
           cur_scope=new ScopeTable(bucket,id);
           close=false;
           cur_scope->insert(name,type);
        }
    }
    bool remove(string name)
    {
        if(cur_scope==NULL) {
            cout<<"Currently not under any scope table"<<endl;
            return false;
        }
        return cur_scope->Delete(name);
    }
    SymbolInfo* LookUp(string name)
    {
        ScopeTable *tmp=cur_scope;
        SymbolInfo *obj=NULL;
        while(tmp!=NULL)
        {
            obj=tmp->lookup(name);
            if(obj!=NULL)
            break;
            tmp=tmp->get_parentScope();
        }
        if(obj==NULL) cout<<"Not found"<<endl;
        return obj;
    }
    void print_currentScp()
    {
        if(cur_scope==NULL) {
            cout<<"Currently not under any scope table"<<endl;
            return ;
        }
        cur_scope->print();
        cout<<endl;
    }
    void print_allScp()
    {
        if(cur_scope==NULL) {
            cout<<"Currently not under any scope table"<<endl;
            return ;
        }
        ScopeTable *tmp=cur_scope;
        while(tmp!=NULL)
        {
            tmp->print();
            cout<<endl;
            tmp=tmp->get_parentScope();
        }

    }
    ~ SymbolTable()
    {
        ScopeTable *current=cur_scope;
        ScopeTable * tmp=current;
        //cout<<"destroying symbol"<<endl;
        while(current!=NULL)
        {
            tmp=current;
            delete tmp;
            current=current->get_parentScope();
        }
    }
};
int main()
{
    ifstream cin("input2.txt");
   int n;
   cin>>n;
   SymbolTable *symbolTable=new SymbolTable(n);
   while(!cin.eof())
   {
       char ch;
       cin>>ch;
       if(ch=='I')
       {
           string name,type;
           cin>>name>>type;
           symbolTable->insert(name,type);
       }
       else if(ch=='L')
       {
           string name;
           cin>>name;
           symbolTable->LookUp(name);
       }
       else if(ch=='D')
       {
           string name;
           cin>>name;
           symbolTable->remove(name);
       }
       else if(ch=='P')
       {
           char ch2;
           cin>>ch2;
           if(ch2=='A') symbolTable->print_allScp();
           else symbolTable->print_currentScp();
       }
       else if(ch=='S') symbolTable->EnterScope();
       else if(ch=='E') symbolTable->ExitScope();
       //cin>>ch;
   }
   delete symbolTable;
}

