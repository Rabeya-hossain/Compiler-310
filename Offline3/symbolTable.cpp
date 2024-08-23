#include <bits/stdc++.h>
#include <iostream>
#include <fstream>
#include <list>
using namespace std;
#define pb push_back
#define gap ' '
#define inf 1e9
extern ofstream logFile;

class SymbolInfo
{
    string name;
    string type;
    int size; // size=-1 for variable, -2 for function and positive for array
    // for function handling
    // for function name will be the name of the function and type will be the return type and size=-2 to indicate function
    SymbolInfo *nxt = NULL;

public:
    vector<pair<string, string>> param_list;
    // SymbolInfo();
    /*SymbolInfo(string name, string type)
    {
        this->name = name;
        this->type = type;
    }*/
    string get_name()
    {
        return name;
    }
    void set_name(string name)
    {
        this->name = name;
    }
    string get_type()
    {
        return type;
    }
    void set_type(string type)
    {
        this->type = type;
    }
    SymbolInfo *get_nxt()
    {
        return nxt;
    }
    void set_nxt(SymbolInfo *nxt_p)
    {
        nxt = nxt_p;
    }
    int get_size()
    {
        return size;
    }
    void set_size(int size)
    {
        this->size = size;
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

    int get_hash(string name, int mod)
    {
        unsigned long hash = 0;
        int c;

        for (int i = 0; i < name.size(); i++)
        {
            c = name[i];
            hash = c + (hash << 6) + (hash << 16) - hash;
        }

        return hash % mod;
    }

    void print_id(vector<int> id)
    {
        logFile << "# ";
        for (int i = 0; i < id.size() - 1; i++)
            logFile << id[i] << ".";
        logFile << id.back() << gap;
    }

public:
    ScopeTable(int n, vector<int> id)
    {
        Hash = new SymbolInfo *[n];
        for (int i = 0; i < n; i++)
            Hash[i] = NULL;
        this->id = id;
        bucket = n;
        parentScope = NULL;
    }
    ScopeTable *get_parentScope()
    {
        return parentScope;
    }
    void set_parentScope(ScopeTable *parScp)
    {
        parentScope = parScp;
    }
    bool insert(string name, string type, int size, vector<pair<string, string>> v)
    {
        int indx = get_hash(name, bucket);
        SymbolInfo *current = Hash[indx];
        SymbolInfo *pre = NULL;
        int pos = 0;
        while (current != NULL)
        {
            if (current->get_name() == name)
            {
                // outFile<<name<<" already exists"<<endl;
                return false;
            }

            pre = current;
            current = current->get_nxt();
            pos++;
        }
        if (pre == NULL)
        {
            SymbolInfo *obj = new SymbolInfo;
            obj->set_name(name);
            obj->set_type(type);
            obj->set_size(size);
            obj->param_list = v;
            obj->set_nxt(NULL);
            Hash[indx] = obj;
        }
        else
        {
            SymbolInfo *obj = new SymbolInfo;
            obj->set_name(name);
            obj->set_type(type);
            obj->set_size(size);
            obj->param_list = v;
            obj->set_nxt(NULL);

            pre->set_nxt(obj);
        }
        //       cout<<"inserted at scope table ";
        //       print_id(id);
        //       cout<<" at position "<<indx<<" , "<<pos<<endl;
        return true;
    }
    SymbolInfo *lookup(string name)
    {
        int indx = get_hash(name, bucket);
        SymbolInfo *current = Hash[indx];
        int pos = 0;
        while (current != NULL)
        {
            if (current->get_name() == name)
            {
                //            cout<<"Found in scopeTable ";
                //           print_id(id);
                //           cout<<" at position "<<indx<<" , "<<pos<<endl;
                return current;
            }
            current = current->get_nxt();
            pos++;
        }
        return current;
    }
    bool Delete(string name)
    {
        int indx = get_hash(name, bucket);

        SymbolInfo *current = Hash[indx];
        SymbolInfo *pre = NULL;
        int pos = 0;
        while (current != NULL && current->get_name() != name)
        {
            pre = current;
            current = current->get_nxt();
            pos++;
        }
        if (current == NULL)
        {
            // cout<<"Not found"<<endl;
            return false;
        }
        if (pre == NULL)
        {
            Hash[indx] = current->get_nxt();
            //           cout<<"Found in scopetable ";
            //           print_id(id);
            //           cout<<"at position "<<indx<<" , "<<pos<<endl;
            //           cout<<"deleted entry "<<indx<<" , "<<pos<<" from current scope table"<<endl;
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
        logFile << "ScopeTable ";
        print_id(id);
        logFile << endl;
        for (int i = 0; i < bucket; i++)
        {
            SymbolInfo *current = Hash[i];
            if (current == NULL)
                continue;
            logFile << i << "--> ";

            while (current != NULL)
            {
                logFile << "  < " << current->get_name() << " , " << current->get_type() << " >";
                current = current->get_nxt();
            }
            logFile << endl;
        }
    }
    ~ScopeTable()
    {
        // cout<<"destroying scope"<<endl;
        for (int i = 0; i < bucket; i++)
        {
            SymbolInfo *current = Hash[i];
            while (current != NULL)
            {
                SymbolInfo *tmp = current;
                current = tmp->get_nxt();
                delete tmp;
            }
        }
        delete Hash;
    }
};

class SymbolTable
{
    ScopeTable *cur_scope;
    int bucket;
    vector<int> id;
    bool close;

public:
    SymbolTable(int n)
    {
        bucket = n;
        id.pb(1);
        cur_scope = new ScopeTable(n, id);
        close = false;
    }
    void EnterScope()
    {
        if (close)
        {
            if (id.size())
                id.back()++;
            else
                id.pb(1);
        }
        else
            id.pb(1);
        ScopeTable *scp = new ScopeTable(bucket, id);
        scp->set_parentScope(cur_scope);
        cur_scope = scp;

        close = false;

        //        cout<<"New ScopeTable with id ";
        //        print_id(id);
        //        cout<<" created"<<endl;
    }
    void ExitScope()
    {
        if (cur_scope == NULL)
            logFile << "It is not currently under any scope" << endl;
        else
        {
            ScopeTable *pre = cur_scope->get_parentScope();
            delete cur_scope;
            cur_scope = pre;

            if (close)
                id.pop_back();
            //            cout<<"scope table with id ";
            //            print_id(id);
            //            cout<<"removed."<<endl;
        }

        close = true;
    }
    bool insert(string name, string type, int size = -1, vector<pair<string, string>> v = vector<pair<string, string>>())
    {
        if (cur_scope != NULL)
            return cur_scope->insert(name, type, size, v);
        else
        {
            id.clear();
            id.pb(1);
            cur_scope = new ScopeTable(bucket, id);
            close = false;
            cur_scope->insert(name, type, size, v);
        }
    }
    bool remove(string name)
    {
        if (cur_scope == NULL)
        {
            logFile << "Currently not under any scope table" << endl
                    << endl;
            return false;
        }
        return cur_scope->Delete(name);
    }
    SymbolInfo *LookUp(string name)
    {
        ScopeTable *tmp = cur_scope;
        SymbolInfo *obj = NULL;
        while (tmp != NULL)
        {
            obj = tmp->lookup(name);
            if (obj != NULL)
                break;
            tmp = tmp->get_parentScope();
        }
        // if (obj == NULL)
        //  cout << "Not found" << endl;
        return obj;
    }
    void print_currentScp()
    {
        if (cur_scope == NULL)
        {
            logFile << "Currently not under any scope table" << endl;
            return;
        }
        cur_scope->print();
        logFile << endl;
    }
    void print_allScp()
    {
        if (cur_scope == NULL)
        {
            logFile << "Currently not under any scope table" << endl
                    << endl;
            return;
        }
        ScopeTable *tmp = cur_scope;
        while (tmp != NULL)
        {
            tmp->print();
            // outFile << endl;
            tmp = tmp->get_parentScope();
        }
    }
    bool grandScp()
    {
        if (cur_scope == NULL)
            return false;
        if (cur_scope->get_parentScope() == NULL)
            return false;
        if (cur_scope->get_parentScope()->get_parentScope() == NULL)
            return false;
        return true;
    }
    ~SymbolTable()
    {
        ScopeTable *current = cur_scope;
        ScopeTable *tmp = current;
        // cout<<"destroying symbol"<<endl;
        while (current != NULL)
        {
            tmp = current;
            delete tmp;
            current = current->get_parentScope();
        }
    }
};
