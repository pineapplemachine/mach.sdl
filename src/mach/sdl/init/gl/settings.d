module mach.sdl.init.gl.settings;

private:

import derelict.sdl2.sdl;
import derelict.opengl;

import mach.text.cstring : fromcstring;

import mach.sdl.graphics.color : Color;
import mach.sdl.error : GLException;
import mach.sdl.glenum : BlendFactor, CullFaceMode, DepthFunction, FrontFaceMode;
import mach.sdl.init.gl.versions;

import mach.io.log;

public:



class GLAttributeException: GLException{
    this(string message, string file = __FILE__, size_t line = __LINE__){
        super("Failed to set OpenGL attribute: " ~ message, null, line, file);
    }
}



struct GLSettings {
    static immutable GLSettings Default = GLSettings();

    static enum Profile : ubyte {
        Default = Core,
        /// Platform default
        Platform = 0,
        /// Deprecated functions are allowed
        Compatibility = 1,
        /// Deprecated functions disabled
        Core = 2,
        /// Only a subset of base functionality is available
        ES = 3,
    }
    
    static enum Antialias : ubyte {
        None = 0,
        X2 = 2,
        X4 = 4,
        X8 = 8,
        X16 = 16,
    }
    
    alias Version = GLVersions.Version;
    
    Version glversion = Version.none;
    Antialias antialias = Antialias.None;
    Profile profile = Profile.Default;
    
    bool enableBlending = false;
    BlendFactor sourceBlendFactor = BlendFactor.One;
    BlendFactor destinationBlendFactor = BlendFactor.Zero;
    Color blendColor = Color(0, 0, 0, 0);
    
    bool enableDepthTest = false;
    DepthFunction depthFunction = DepthFunction.Default;
    // Invoke glDepthRange with these inputs if not 0 and 1 respectively.
    GLdouble nearDepthRange = 0;
    GLdouble farDepthRange = 1;
    
    bool enableCullFace = false;
    CullFaceMode cullFaceMode = CullFaceMode.Default;
    FrontFaceMode frontFaceMode = FrontFaceMode.Default;
    
    this(Version glversion, Profile profile = Profile.Default) {
        this.antialias = antialias;
        this.profile = profile;
    }
    
    static void apply(SDL_GLattr attribute, int value) {
        if(SDL_GL_SetAttribute(attribute, value) != 0){
            throw new GLAttributeException(SDL_GetError().fromcstring);
        }
    }
    
    void apply() const {
        auto useGlVersion = (this.glversion is Version.none ?
            GLVersions.DefaultVersion : this.glversion
        );
        
        log("Applying settings. GLVersion setting is: ", this.glversion);
        log("Using GLVersion setting: ", useGlVersion);
        log("Default GLVersion setting is: ", GLVersions.DefaultVersion);
        
        int major = GLVersions.major(useGlVersion);
        int minor = GLVersions.minor(useGlVersion);
        
        if(major != 0) {
            log("Applying OpenGL version ", major, ".", minor);
            apply(SDL_GL_CONTEXT_MAJOR_VERSION, major);
            apply(SDL_GL_CONTEXT_MINOR_VERSION, minor);
        }
        
        log("Applying OpenGL profile ", this.profile);
        final switch(this.profile) {
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
            case Profile.Platform:
                break;
        }
        
        apply(SDL_GL_DOUBLEBUFFER, 1);
        apply(SDL_GL_ACCELERATED_VISUAL, 1);
        
        if(this.antialias > 0) {
            apply(SDL_GL_MULTISAMPLEBUFFERS, 1);
            apply(SDL_GL_MULTISAMPLESAMPLES, antialias);
        }
    }
    
    void initialize() {
        // Configure the depth buffer
        if(this.enableDepthTest) {
            glEnable(GL_DEPTH_TEST);
        }
        else {
            glDisable(GL_DEPTH_TEST);
        }
        if(this.depthFunction !is DepthFunction.Default) {
            glDepthFunc(this.depthFunction);
        }
        if(this.nearDepthRange != 0 || this.farDepthRange != 1) {
            glDepthRange(this.nearDepthRange, this.farDepthRange);
        }
        // Configure blending
        if(this.enableBlending) {
            glEnable(GL_BLEND);
        }
        else {
            glDisable(GL_BLEND);
        }
        if(
            this.sourceBlendFactor !is BlendFactor.One ||
            this.destinationBlendFactor !is BlendFactor.Zero
        ) {
            glBlendFunc(this.sourceBlendFactor, this.destinationBlendFactor);
        }
        if(this.blendColor != Color(0, 0, 0, 0)) {
            glBlendColor(
                this.blendColor.red,
                this.blendColor.green,
                this.blendColor.blue,
                this.blendColor.alpha,
            );
        }
        // Configure face culling
        if(this.enableCullFace) {
            glEnable(GL_CULL_FACE);
        }
        else {
            glDisable(GL_CULL_FACE);
        }
        if(this.cullFaceMode !is CullFaceMode.Default) {
            glCullFace(this.cullFaceMode);
        }
        if(this.frontFaceMode !is FrontFaceMode.Default) {
            glFrontFace(this.frontFaceMode);
        }
    }
}
