module mach.sdl.graphics.shader;

private:

import derelict.opengl;

import mach.sdl.error : GLException;
import mach.sdl.glenum : GLShaderType, GLShaderParameter;

public:

/// Represents an OpenGL shader.
struct GLShader {
    alias Type = GLShaderType;
    alias Parameter = GLShaderParameter;
    
    /// Exception type thrown when shader compilation fails.
    class CompileException: GLException{
        this(string message, size_t line = __LINE__, string file = __FILE__){
            super("\n" ~ message, null, line, file);
        }
    }
    
    /// Stores a shader ID assigned upon creation.
    GLuint handle = 0;
    
    this(in GLuint handle){
        this.handle = handle;
    }
    
    /// Load a shader from a string literal.
    this(in Type type, in string source = "") {
        this.handle = glCreateShader(type);
        if(this.handle == 0) throw new GLException("Failed to create shader.");
        this.source = source;
    }
    
    static auto fragment(in string source = "") {
        return typeof(this)(Type.Fragment, source);
    }
    static auto vertex(in string source = "") {
        return typeof(this)(Type.Vertex, source);
    }
    
    /// Load a shader from a file path.
    //static auto load(S)(in Type type, in S path) if(isString!S){
    //    return typeof(this)(type, cast(string) Path(path).readall);
    //}
    
    /// Free a previously-created shader.
    void free(){
        glDeleteShader(this.handle);
        this.handle = 0;
    }
    
    /// True when the object refers to an existing shader.
    /// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glIsShader.xhtml
    bool opCast(To: bool)() const{
        return cast(bool) glIsShader(this.handle);
    }
    
    /// Set the shader's source code as a string.
    /// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glShaderSource.xhtml
    @property void source(in string source){
        assert(this.handle != 0);
        auto length = cast(GLint) source.length;
        auto ptr = source.ptr;
        glShaderSource(this.handle, 1, &ptr, &length);
    }
    /// Get the shader's source code.
    /// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glGetShaderSource.xhtml
    @property string source() const{
        assert(this.handle != 0);
        auto length = this.sourceLength;
        if(length == 0) return "";
        char[] result = new char[length - 1];
        glGetShaderSource(this.handle, cast(GLsizei) result.length, null, result.ptr);
        return cast(string) result;
    }
    
    /// Compile the shader. Throws a CompileException if compilation fails.
    /// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glCompileShader.xhtml
    void compile() {
        glCompileShader(this.handle);
        if(!this.compileStatus) {
            throw new CompileException(this.info);
        }
    }
    
    /// Get the shader's info log, generated upon compilation.
    /// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glGetShaderInfoLog.xhtml
    @property string info() const{
        assert(this.handle != 0);
        auto length = this.infoLogLength;
        if(length == 0) return "";
        char[] result = new char[length - 1];
        glGetShaderInfoLog(this.handle, cast(GLsizei) result.length, null, result.ptr);
        return cast(string) result;
    }
    
    /// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glGetShader.xhtml
    auto parameter(in Parameter parameter) const{
        assert(this.handle != 0);
        GLint result = -1;
        glGetShaderiv(this.handle, parameter, &result);
        // If result wasn't modified, indicates an error occurred.
        // (-1 should never be a valid result.)
        if(result == -1) throw new GLException("Failed to get shader parameter.");
        return result;
    }
    
    /// Get the length in characters of the shader's source.
    @property auto sourceLength() const{
        return this.parameter(Parameter.SourceLength);
    }
    /// Get the length in characters of the shader's info log.
    @property auto infoLogLength() const{
        return this.parameter(Parameter.InfoLogLength);
    }
    /// Get the shader type.
    @property Type type() const{
        return cast(Type) this.parameter(Parameter.Type);
    }
    /// Get whether the shader has been successfully compiled.
    @property bool compileStatus() const{
        return cast(bool) this.parameter(Parameter.CompileStatus);
    }
    /// Get whether the shader has been flagged for deletion.
    @property bool deleteStatus() const{
        return cast(bool) this.parameter(Parameter.DeleteStatus);
    }
}
