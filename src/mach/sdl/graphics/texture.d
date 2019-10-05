module mach.sdl.graphics.texture;

private:

import derelict.opengl;

import mach.traits : isNumeric;
import mach.math.vector : Vector, Vector2;
import mach.math.box : Box;
import mach.sdl.error : GLException;
import mach.sdl.glenum : GLTextureTarget, GLTextureParameter;
import mach.sdl.glenum : GLPixelsType, GLPixelsFormat;
import mach.sdl.glenum : GLPrimitive, GLVertexType, getvertextype, validvertextype;
import mach.sdl.glenum : GLTextureWrap, GLTextureFilter;
import mach.sdl.glenum : GLTextureMinFilter, GLTextureMagFilter;
import mach.sdl.graphics.surface : SDLSurface;
import mach.sdl.graphics.pixelformat : SDLPixelFormat;
//import mach.sdl.graphics.vertex : Vertex, Vertexes, Vertexesf;

public:



struct GLTexture {
    /// Enumeration of wrapping modes.
    alias Wrap = GLTextureWrap;
    /// Enumeration of filter modes available for both min and mag filters.
    alias Filter = GLTextureFilter;
    /// Enumeration of filter modes available when an image is scaled down.
    alias MinFilter = GLTextureMinFilter;
    /// Enumeration of filter modes available when an image is scaled up.
    alias MagFilter = GLTextureMagFilter;
    
    alias Handle = GLuint;
    Handle handle;
    
    this(in Handle handle){
        this.handle = handle;
    }
    
    /// Load a texture from a path.
    this(in string path){
        auto surface = SDLSurface(path);
        this(surface);
    }
    
    /// Create a texture from a surface.
    this(SDLSurface surface){
        auto converted = surface.convert(SDLPixelFormat.Format.RGBA8888); // TODO: only convert when necessary
        this(converted.pixels, converted.width, converted.height, GLPixelsFormat.RGBA);
    }
    
    /// Create a texture given width, height, and raw pixel data.
    /// (You probably won't be calling this one directly.)
    this(
        in void* pixels, int width, int height,
        GLPixelsFormat format = GLPixelsFormat.RGBA
    ){
        assert(width > 0 && height > 0, "Invalid texture size.");
        glGenTextures(1, &this.handle);
        GLException.enforce("Failed to generate textures.");
        this.bind();
        this.wrap(Wrap.Repeat);
        this.filter(Filter.Nearest);
        glTexImage2D(
            GLTextureTarget.Texture2D, 0, format,
            width, height, 0, format, GL_UNSIGNED_INT_8_8_8_8, pixels
        );
        GLException.enforce("Failed to create texture.");
    }
    
    /// Immediately free the texture data, if it hasn't already been freed.
    void free(){
        glDeleteTextures(1, &this.handle);
        this.handle = 0;
    }
    /// Free multiple textures at once.
    static void free(GLTexture[] textures...){
        glDeleteTextures(cast(GLint) textures.length, cast(GLuint*) textures.ptr);
        foreach(texture; textures) texture.handle = 0;
    }
    
    /// True when the object refers to an existing texture.
    /// https://www.khronos.org/registry/OpenGL-Refpages/es1.1/xhtml/glIsTexture.xml
    bool opCast(To: bool)() const{
        return cast(bool) glIsTexture(this.handle);
    }
    
    /// Bind this texture; subsequent OpenGL calls will apply to this texture name.
    void bind() const nothrow{
        glBindTexture(GLTextureTarget.Texture2D, this.handle);
    }
    
    /// Unbind this texture.
    void unbind() const nothrow{
        glBindTexture(GLTextureTarget.Texture2D, 0);
    }
    
    /// Get the currently bound texture.
    static auto bound(){
        // Note: Texture names/handles are unsigned ints
        // but glGetIntegerv expects a signed int
        GLint handle;
        glGetIntegerv(GL_TEXTURE_BINDING_2D, &handle);
        return GLTexture(cast(Handle) handle);
    }
    
    /// True if this texture's name is currently bound.
    @property bool isBound() const{
        return GLTexture.bound().handle == this.handle;
    }
    
    /// Get the width of the texture.
    @property auto width() const{
        this.bind();
        GLint width;
        glGetTexLevelParameteriv(GL_TEXTURE_2D, 0, GL_TEXTURE_WIDTH, &width);
        return width;
    }
    /// Get the height of the texture.
    @property auto height() const {
        this.bind();
        GLint height;
        glGetTexLevelParameteriv(GL_TEXTURE_2D, 0, GL_TEXTURE_HEIGHT, &height);
        return height;
    }
    /// Get the size of the texture as a vector.
    @property Vector!(2, int) size() const {
        return Vector!(2, int)(this.width, this.height);
    }
    
    /// Set filter used when scaling the image.
    @property void filter(in Filter filter){
        this.bind();
        this.minfilter(cast(GLTextureMinFilter) filter);
        this.magfilter(cast(GLTextureMagFilter) filter);
    }
    /// Set filter used when scaling the image down.
    @property void minfilter(in MinFilter filter){
        this.bind();
        glTexParameteri(GLTextureTarget.Texture2D, GLTextureParameter.MinFilter, filter);
    }
    /// Set filter used when scaling the image up.
    @property void magfilter(in MagFilter filter){
        this.bind();
        glTexParameteri(GLTextureTarget.Texture2D, GLTextureParameter.MagFilter, filter);
    }
    
    /// Set how the texture wraps.
    @property void wrap(in Wrap wrap){
        this.bind();
        glTexParameteri(GLTextureTarget.Texture2D, GLTextureParameter.WrapS, wrap);
        glTexParameteri(GLTextureTarget.Texture2D, GLTextureParameter.WrapT, wrap);
    }
    
    void mipmap(){
        this.bind();
        // Doesn't work (Crashes because glGenerateMipmap isn't loaded)
        //glGenerateMipmapEXT(GLTextureTarget.Texture2D);
        // Not sure if this works or not honestly, but at least it doesn't crash
        //glTexParameteri(GLTextureTarget.Texture2D, GL_GENERATE_MIPMAP, true);
    }
    
    //void update(){
    //    auto formatted = FormattedSurface.make!convert(surface);
    //    scope(exit) formatted.conclude();
    //    this.update(
    //        formatted.pixels, Box!int(offset, offset + formatted.size),
    //        formatted.format
    //    );
    //}
    void update(
        in void* pixels, Box!int box, GLPixelsFormat format = GLPixelsFormat.RGBA
    ){
        assert(pixels, "Invalid pixel data.");
        this.bind();
        glTexSubImage2D(
            GLTextureTarget.Texture2D, 0,
            box.x, box.y, box.width, box.height,
            format, GLPixelsType.Ubyte, pixels
        );
        GLException.enforce("Failed to update texture.");
    }
}
