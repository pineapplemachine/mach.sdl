module mach.sdl.init.gl.settings;

private:

import derelict.sdl2.sdl;
import derelict.opengl;

import mach.text.cstring : fromcstring;

import mach.sdl.graphics.color : Color;
import mach.sdl.error : GLException;
import mach.sdl.glenum : GLBlendFactor, GLCullFaceMode;
import mach.sdl.glenum : GLDepthFunction, GLFrontFaceMode;
import mach.sdl.init.gl.versions;

import mach.io.log;

public:



class GLAttributeException: GLException{
    this(string message, string file = __FILE__, size_t line = __LINE__){
        super("Failed to set OpenGL attribute: " ~ message, null, line, file);
    }
}

/// https://wiki.libsdl.org/SDL_GLprofile
enum SDLGLProfile : SDL_GLprofile {
    Core = SDL_GL_CONTEXT_PROFILE_CORE,
    Compatibility = SDL_GL_CONTEXT_PROFILE_COMPATIBILITY,
    ES = SDL_GL_CONTEXT_PROFILE_ES,
}

/// https://wiki.libsdl.org/SDL_GLcontextFlag
enum SDLGLContextFlag : SDL_GLcontextFlag {
    Debug = SDL_GL_CONTEXT_DEBUG_FLAG,
    ForwardCompatible = SDL_GL_CONTEXT_FORWARD_COMPATIBLE_FLAG,
    RobustAccess = SDL_GL_CONTEXT_ROBUST_ACCESS_FLAG,
    ResetIsolation = SDL_GL_CONTEXT_RESET_ISOLATION_FLAG,
}

/// https://wiki.libsdl.org/SDL_GL_SetAttribute
enum SDLGLAttribute : SDL_GLattr {
    RedSize = SDL_GL_RED_SIZE,
    GreenSize = SDL_GL_GREEN_SIZE,
    BlueSize = SDL_GL_BLUE_SIZE,
    AlphaSize = SDL_GL_ALPHA_SIZE,
    FrameBufferSize = SDL_GL_BUFFER_SIZE,
    DoubleBuffer = SDL_GL_DOUBLEBUFFER,
    DepthSize = SDL_GL_DEPTH_SIZE,
    StencilSize = SDL_GL_STENCIL_SIZE,
    AccumRedSize = SDL_GL_ACCUM_RED_SIZE,
    AccumGreenSize = SDL_GL_ACCUM_GREEN_SIZE,
    AccumBlueSize = SDL_GL_ACCUM_BLUE_SIZE,
    AccumAlphaSize = SDL_GL_ACCUM_ALPHA_SIZE,
    Stereo = SDL_GL_STEREO,
    MultisampleBuffers = SDL_GL_MULTISAMPLEBUFFERS,
    MultisampleSamples = SDL_GL_MULTISAMPLESAMPLES,
    AcceleratedVisual = SDL_GL_ACCELERATED_VISUAL,
    //RetainedBacking = SDL_GL_RETAINED_BACKING, // Deprecated
    ContextMajorVersion = SDL_GL_CONTEXT_MAJOR_VERSION,
    ContextMinorVersion = SDL_GL_CONTEXT_MINOR_VERSION,
    ContextFlags = SDL_GL_CONTEXT_FLAGS,
    ContextProfileMask = SDL_GL_CONTEXT_PROFILE_MASK,
    ShareWithCurrentContext = SDL_GL_SHARE_WITH_CURRENT_CONTEXT,
    Framebuffer_SRGB_CAPABLE = SDL_GL_FRAMEBUFFER_SRGB_CAPABLE,
    ContextReleaseBehavior = SDL_GL_CONTEXT_RELEASE_BEHAVIOR,
    //ContextEGL = SDL_GL_CONTEXT_EGL, // Deprecated
}

struct GLSettings {
    static immutable GLSettings Default = GLSettings();
    
    alias Attribute = SDLGLAttribute;

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
    GLBlendFactor sourceBlendFactor = GLBlendFactor.One;
    GLBlendFactor destinationBlendFactor = GLBlendFactor.Zero;
    Color blendColor = Color(0, 0, 0, 0);
    
    bool enableDepthTest = false;
    GLDepthFunction depthFunction = GLDepthFunction.Default;
    // Invoke glDepthRange with these inputs if not 0 and 1 respectively.
    GLdouble nearDepthRange = 0;
    GLdouble farDepthRange = 1;
    
    bool enableCullFace = false;
    GLCullFaceMode cullFaceMode = GLCullFaceMode.Default;
    GLFrontFaceMode frontFaceMode = GLFrontFaceMode.Default;
    
    bool enableDoubleBuffer = true;
    
    int minRedBits = 3;
    int minGreenBits = 3;
    int minBlueBits = 2;
    int minAlphaBits = 0;
    int minDepthBits = 16;
    int minStencilBits = 0;
    
    /// Enable SDL_GL_CONTEXT_DEBUG_FLAG and GL_DEBUG_OUTPUT
    /// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glGetDebugMessageLog.xhtml
    bool debugContext = false;
    
    this(Version glversion, Profile profile = Profile.Default) {
        this.glversion = glversion;
        this.profile = profile;
    }
    
    static void apply(in SDLGLAttribute attribute, in int value) {
        if(SDL_GL_SetAttribute(attribute, value) != 0){
            throw new GLAttributeException(SDL_GetError().fromcstring);
        }
    }
    
    void apply() const {
        auto useGlVersion = (this.glversion is Version.none ?
            GLVersions.DefaultVersion : this.glversion
        );
        
        log("Applying settings. GLVersion setting is: ", this.glversion);
        log("Default GLVersion setting is: ", GLVersions.DefaultVersion);
        log("Using GLVersion setting: ", useGlVersion);
        
        int major = GLVersions.major(useGlVersion);
        int minor = GLVersions.minor(useGlVersion);
        
        if(major != 0) {
            log("Applying OpenGL version ", major, ".", minor);
            GLSettings.apply(SDLGLAttribute.ContextMajorVersion, major);
            GLSettings.apply(SDLGLAttribute.ContextMinorVersion, minor);
        }
        
        log("Applying OpenGL profile ", this.profile);
        final switch(this.profile) {
            case Profile.Core:
                GLSettings.apply(SDLGLAttribute.ContextProfileMask, SDLGLProfile.Core);
                GLSettings.apply(SDLGLAttribute.ContextFlags, SDLGLContextFlag.ForwardCompatible);
                break;
            case Profile.Compatibility:
                GLSettings.apply(SDLGLAttribute.ContextProfileMask, SDLGLProfile.Compatibility);
                break;
            case Profile.ES:
                GLSettings.apply(SDLGLAttribute.ContextProfileMask, SDLGLProfile.ES);
                break;
            case Profile.Platform:
                break;
        }
        
        if(this.debugContext) {
            log("applying debug context flag");
            GLSettings.apply(SDLGLAttribute.ContextFlags, SDLGLContextFlag.Debug);
        }
        
        GLSettings.apply(SDLGLAttribute.DoubleBuffer, this.enableDoubleBuffer ? 1 : 0);
        //GLSettings.apply(SDL_GL_ACCELERATED_VISUAL, 1);
        
        GLSettings.apply(SDLGLAttribute.RedSize, minRedBits);
        GLSettings.apply(SDLGLAttribute.GreenSize, minGreenBits);
        GLSettings.apply(SDLGLAttribute.BlueSize, minBlueBits);
        GLSettings.apply(SDLGLAttribute.AlphaSize, minAlphaBits);
        GLSettings.apply(SDLGLAttribute.DepthSize, minDepthBits);
        GLSettings.apply(SDLGLAttribute.StencilSize, minStencilBits);
        
        if(this.antialias > 0) {
            GLSettings.apply(SDLGLAttribute.MultisampleBuffers, 1);
            GLSettings.apply(SDLGLAttribute.MultisampleSamples, antialias);
        }
    }
    
    void initialize() {
        log("Initializing OpenGL context using these settings: ", this);
        // Configure debug message logging
        if(this.debugContext) {
            glEnable(GL_DEBUG_OUTPUT);
        }
        // Configure the depth buffer
        if(this.enableDepthTest) {
            glEnable(GL_DEPTH_TEST);
        }
        else {
            glDisable(GL_DEPTH_TEST);
        }
        if(this.depthFunction !is GLDepthFunction.Default) {
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
            this.sourceBlendFactor !is GLBlendFactor.One ||
            this.destinationBlendFactor !is GLBlendFactor.Zero
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
        if(this.cullFaceMode !is GLCullFaceMode.Default) {
            glCullFace(this.cullFaceMode);
        }
        if(this.frontFaceMode !is GLFrontFaceMode.Default) {
            glFrontFace(this.frontFaceMode);
        }
    }
}
