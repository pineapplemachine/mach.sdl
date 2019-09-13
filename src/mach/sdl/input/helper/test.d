import std.stdio;

struct Test{
    bool state;
    bool opCast(T: bool)() const{
        return this.state;
    }
}

unittest{
    if(Test(true)) writeln("ok");
    if(Test(false)) writeln("not ok");
}
