#include <bits/stdc++.h>
using namespace std;

class container
{
public:
    string text; // which will be printed
    string type; // data type
    string name;
    string code;
    string label1, label2, label3, label4;
    int sp;
    int line;
    bool global = true;
    vector<pair<string, int>> v;        // name and size of the variable(for array)
    vector<pair<string, string>> param; // type and name of the parameter;
    vector<string> argument;            // to store the types of the argument
};