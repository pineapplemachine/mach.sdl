module mach.sdl.init.gl.gl;

private:

import derelict.opengl;

import mach.sdl.error : GLException;
import mach.sdl.init.gl.settings;
import mach.sdl.init.gl.versions;

import mach.io.log;

public:

struct GL{
    static load(){
        DerelictGL3.load();
    }
    static reload(){
        Version.reload();
    }
    static unload(){
        DerelictGL3.unload();
    }
    
    alias Settings = GLSettings;
    alias Version = GLVersions;
    
    static void initialize(GLSettings settings) {
        log("Initializing OpenGL");
        Version.reload();
        Version.verify();
        settings.initialize();
        
        //glDisable(GL_DITHER);
        //glDisable(GL_LIGHTING); // Deprecated
        
        //glDisable(GL_ALPHA_TEST); // Deprecated

        //glEnable(GL_TEXTURE_2D); // Deprecated..?
        
        //glEnable(GL_BLEND);
        //glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA); // TODO: Does this work?
        
        //glEnable(GL_MULTISAMPLE);
        
        // http://stackoverflow.com/questions/11806823/glenableclientstate-deprecated
        //glEnableClientState(GL_VERTEX_ARRAY);
        //glEnableClientState(GL_COLOR_ARRAY);
        //glEnableClientState(GL_TEXTURE_COORD_ARRAY);
        
        GLException.enforce("Failed to initialize OpenGL.");
    }
}
