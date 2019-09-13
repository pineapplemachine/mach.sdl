// This program displays a pineapple graphic loaded from an external image
// file, and the graphic can be moved using the WASD keys.

import mach.sdl;
import mach.math;
import mach.json;

struct Script{
    struct Argument{
        string name;
        string description;
    }
    
    string name;
    string description;
    string[] authors;
    Argument[] arguments;
    
    typeof(this) fromjson(Json.Value json){
        string[] authors;
        if("author" in json){
            if(json.isstring){
                authors = [cast(string) json];
            }else if(json.isarray){
                authors = json.
            }
        }
        return Script(
            "name" in json ? cast(string) json["name"] : "unnamed",
            "description" in json ? cast(string) json["description"] : "No description.",
            
        );
    }
}


struct ScriptList{
    
}
struct ScriptListItem{
    string text;
}

class PyDwarf: Application{
    
    override void initialize(){
        window = new Window("PyDwarf Helper", 600, 600,
            Window.StyleFlag.Shown | Window.StyleFlag.Resizable
        );
    }
    
    override void postinitialize(){
        updateelements();
    }
    
    override void conclude(){
        //
    }
    
    override void main(){
        clear();
        
        swap();
    }
    
    override void onresize(Event event){
        super.onresize(event);
        updateelements();
    }
    
    void updateelements(){
        //
    }
}

void main(){
    // This is what makes the application start when the program is run.
    new PyDwarf().begin;
}
