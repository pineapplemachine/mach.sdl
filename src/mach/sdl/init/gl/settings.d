module mach.sdl.init.gl.settings;

private:

import derelict.sdl2.sdl;

import mach.text.cstring : fromcstring;
import mach.sdl.error : GLException;
import mach.sdl.init.gl.versions;

import mach.io.log;

public:



class GLAttributeException: GLException{
    this(string message, string file = __FILE__, size_t line = __LINE__){
        super("Failed to set OpenGL attribute: " ~ message, null, line, file);
    }
}



struct GLSettings {
    static immutable GLSettings Default = GLSettings(GLVersions.DefaultVersion);

    static enum Profile{
        /// Depends on platform
        Default,
        /// Deprecated functions are allowed
        Compatibility,
        /// Deprecated functions disabled
        Core,
        /// Only a subset of base functionality is available
        ES
    }
    
    static enum DefaultProfile = Profile.Core; // Previously Profile.Compatibility
    
    static enum Antialias : ubyte {
        None = 0,
        X2 = 2,
        X4 = 4,
        X8 = 8,
        X16 = 16
    }
    
    alias Version = GLVersions.Version;
    
    Version glversion;
    Antialias antialias = Antialias.None;
    Profile profile = DefaultProfile;
    
    this(
        Version glversion,
        Antialias antialias = Antialias.None,
        Profile profile = DefaultProfile
    ){
        this.antialias = antialias;
        this.glversion = glversion;
        this.profile = profile;
    }
    
    static void apply(SDL_GLattr attribute, int value){
        if(SDL_GL_SetAttribute(attribute, value) != 0){
            throw new GLAttributeException(SDL_GetError().fromcstring);
        }
    }
    void apply() const{
        int major = GLVersions.major(this.glversion);
        int minor = GLVersions.minor(this.glversion);
        
        if(major != 0){
            log("Applying OpenGL version ", major, ".", minor);
            apply(SDL_GL_CONTEXT_MAJOR_VERSION, major);
            apply(SDL_GL_CONTEXT_MINOR_VERSION, minor);
        }
        
        log("Applying OpenGL profile ", this.profile);
        final switch(this.profile){
            case Profile.Core:
                apply(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);
                apply(SDL_GL_CONTEXT_FLAGS, SDL_GL_CONTEXT_FORWARD_COMPATIBLE_FLAG);
                break;
            case Profile.Compatibility:
                apply(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_COMPATIBILITY);
                break;
            case Profile.ES:
                apply(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_ES);
                break;
            case Profile.Default:
                break;
        }
        
        if(this.antialias > 0){
            apply(SDL_GL_MULTISAMPLEBUFFERS, 1);
            apply(SDL_GL_MULTISAMPLESAMPLES, antialias);
        }
        
        apply(SDL_GL_DOUBLEBUFFER, 1);
        apply(SDL_GL_ACCELERATED_VISUAL, 1);
    }
    
}
