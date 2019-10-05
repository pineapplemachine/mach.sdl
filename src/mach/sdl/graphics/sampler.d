module mach.sdl.graphics.sampler;

private:

import derelict.opengl;

import core.exception : RangeError;

import mach.traits : isNumeric;

import mach.sdl.error : GLException;
import mach.sdl.graphics.color : Color;
import mach.sdl.graphics.texture : GLTexture;
import mach.sdl.glenum : GLTextureWrap, GLTextureFilter, GLSamplerParameter;
import mach.sdl.glenum : GLTextureMinFilter, GLTextureMagFilter;
import mach.sdl.glenum : GLTextureCompareMode, GLTextureCompareFunction;

public:

/// https://www.khronos.org/opengl/wiki/Sampler_Object
struct GLSampler {
    /// Enumeration of wrapping modes.
    alias Wrap = GLTextureWrap;
    /// Enumeration of filter modes available for both min and mag filters.
    alias Filter = GLTextureFilter;
    /// Enumeration of filter modes available when an image is scaled down.
    alias MinFilter = GLTextureMinFilter;
    /// Enumeration of filter modes available when an image is scaled up.
    alias MagFilter = GLTextureMagFilter;
    
    alias Parameter = GLSamplerParameter;
    
    /// https://www.khronos.org/opengl/wiki/GLAPI/glSamplerParameter
    alias CompareMode = GLTextureCompareMode;
    /// https://www.khronos.org/opengl/wiki/GLAPI/glSamplerParameter
    alias CompareFunction = GLTextureCompareFunction;
    
    GLuint handle = 0;
    
    this(GLuint handle){
        this.handle = handle;
    }
    /// Create a sampler and bind a texture to it.
    this(T)(in GLTexture texture, in T texunit = GLuint(0)) if(isNumeric!T){
        this.initialize();
        this.bind(texture, texunit);
    }
    
    /// Create a new, empty sampler.
    void initialize(){
        assert(this.handle == 0);
        glGenSamplers(1, &this.handle);
    }
    
    /// Delete the sampler.
    /// https://www.khronos.org/opengl/wiki/GLAPI/glDeleteSamplers
    void free(){
        glDeleteSamplers(1, &this.handle);
        this.handle = 0;
    }
    
    /// True when the object refers to an existing sampler.
    /// https://www.khronos.org/opengl/wiki/GLAPI/glIsSampler
    bool opCast(To: bool)() const{
        return cast(bool) glIsSampler(this.handle);
    }
    
    /// Bind a texture to this sampler. When binding multiple textures,
    /// differing values of `texunit` must be used.
    /// `texunit` must be at least zero and less than the value returned
    /// by `GLSampler.texunits`. Defaults to zero.
    /// https://www.khronos.org/opengl/wiki/Sampler_(GLSL)#Binding_textures_to_samplers
    /// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glBindSampler.xhtml
    void bind(T)(in GLTexture texture, in T texunit = GLuint(0)) if(isNumeric!T){
        this.bind(texture.name, cast(GLuint) texunit);
    }
    /// Ditto
    void bind(in GLuint texture, in GLuint texunit){
        assert(this.handle != 0);
        glActiveTexture(GL_TEXTURE0 + texunit);
        glBindTexture(GL_TEXTURE_2D, texture);
        glBindSampler(texture, this.handle);
    }
    
    /// Get the number of available texture units. The number varies widely
    /// by platform.
    /// https://www.khronos.org/opengl/wiki/Common_Mistakes#Texture_Unit
    /// https://www.opengl.org/discussion_boards/showthread.php/174926-when-to-use-glActiveTexture
    /// https://www.khronos.org/registry/OpenGL-Refpages/es3.0/html/glGet.xhtml
    static @property auto texunits(){
        GLint value = void;
        glGetIntegerv(GL_MAX_COMBINED_TEXTURE_IMAGE_UNITS, &value);
        GLException.enforce("Failed to get number of texture units.");
        return value;
    }
    
    /// https://www.khronos.org/opengl/wiki/GLAPI/glGetSamplerParameter
    auto parameter(in Parameter parameter) const{
        assert(this.handle != 0);
        assert(parameter != Parameter.BorderColor,
            "Parameter unsupported by this method; use bordercolor instead."
        );
        GLint result = void;
        glGetSamplerParameteriv(this.handle, parameter, &result);
        return result;
    }
    /// https://www.khronos.org/opengl/wiki/GLAPI/glSamplerParameter
    auto parameter(in Parameter parameter, in GLint value){
        assert(this.handle != 0);
        assert(parameter != Parameter.BorderColor,
            "Parameter unsupported by this method; use bordercolor instead."
        );
        glSamplerParameteri(this.handle, parameter, value);
    }
    
    /// Get the sampler border color.
    /// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glGetSamplerParameter.xhtml
    @property auto bordercolor() const{
        assert(this.handle != 0);
        Color color;
        glGetSamplerParameterfv(this.handle, Parameter.BorderColor, cast(GLfloat*) &color);
        return color;
    }
    /// Set the sampler border color.
    /// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glSamplerParameter.xhtml
    @property void bordercolor(in Color color){
        assert(this.handle != 0);
        glSamplerParameterfv(this.handle, Parameter.BorderColor, cast(const(GLfloat)*) &color);
    }
    
    /// Get minification filter.
    @property auto minfilter() const{
        return cast(MinFilter) this.parameter(Parameter.MinFilter);
    }
    /// Set minification filter.
    @property void minfilter(in MinFilter filter){
        this.parameter(Parameter.MinFilter, cast(GLint) filter);
    }
    /// Get magnification filter.
    @property auto magfilter() const{
        return cast(MagFilter) this.parameter(Parameter.MagFilter);
    }
    /// Set magnification filter.
    @property void magfilter(in MagFilter filter){
        this.parameter(Parameter.MagFilter, cast(GLint) filter);
    }
    /// Set both min and mag filter settings at once.
    @property void filter(in Filter filter){
        this.minfilter = cast(MinFilter) filter;
        this.magfilter = cast(MagFilter) filter;
    }
    
    /// Get the minimum level of detail value.
    @property auto minlod() const{
        return this.parameter(Parameter.MinLOD);
    }
    /// Set the minimum level of detail value.
    @property void minlod(T)(in T value) if(isNumeric!T){
        this.parameter(Parameter.MinLOD, cast(GLint) value);
    }
    /// Get the maximum level of detail value.
    @property auto maxlod() const{
        return this.parameter(Parameter.MaxLOD);
    }
    /// Set the maximum level of detail value.
    @property void maxlod(T)(in T value) if(isNumeric!T){
        this.parameter(Parameter.MaxLOD, cast(GLint) value);
    }
    
    /// Get texture wrap setting on the X axis.
    @property auto wrapx() const{
        return cast(Wrap) this.parameter(Parameter.WrapX);
    }
    /// Set texture wrap setting on the X axis.
    @property void wrapx(in Wrap wrap){
        this.parameter(Parameter.WrapX, cast(GLint) wrap);
    }
    /// Get texture wrap setting on the Y axis.
    @property auto wrapy() const{
        return cast(Wrap) this.parameter(Parameter.WrapY);
    }
    /// Set texture wrap setting on the Y axis.
    @property void wrapy(in Wrap wrap){
        this.parameter(Parameter.WrapY, cast(GLint) wrap);
    }
    /// Get texture wrap setting on the Z axis.
    @property auto wrapz() const{
        return cast(Wrap) this.parameter(Parameter.WrapZ);
    }
    /// Set texture wrap setting on the Z axis.
    @property void wrapz(in Wrap wrap){
        this.parameter(Parameter.WrapZ, cast(GLint) wrap);
    }
    /// Set X, Y, and Z wrap settings all at once.
    @property void wrap(in Wrap wrap){
        this.wrapx = wrap;
        this.wrapy = wrap;
        this.wrapz = wrap;
    }
}
