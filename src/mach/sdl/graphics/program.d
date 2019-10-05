module mach.sdl.graphics.program;

private:

import derelict.opengl;

import mach.math.vector : Vector;
import mach.text.cstring : tocstring;

import mach.sdl.error : GLException;
import mach.sdl.graphics.attribute : GLAttribute, GLAttributes;
import mach.sdl.graphics.shader : GLShader;
import mach.sdl.graphics.uniform : GLUniform, GLUniforms;
import mach.sdl.glenum : GLPrimitive, GLProgramParameter;
import mach.sdl.glenum : GLProgramActiveAttributeType, GLProgramActiveUniformType;

public:

/// Represents an OpenGL program, to which shaders are attached.
/// TODO: More exhaustive support of program features
struct GLProgram {
    alias Parameter = GLProgramParameter;
    
    /// Exception type thrown when program linking fails.
    class LinkException: GLException{
        this(string message, size_t line = __LINE__, string file = __FILE__){
            super("\n" ~ message, null, line, file);
        }
    }
    
    GLuint handle;
    GLAttributes attributes;
    GLUniforms uniforms;
    
    this(GLuint handle) {
        this.handle = handle;
    }
    /// Create a new program with the given shaders attached to it, and then
    /// link the program.
    this(in const(GLShader)[] shaders...){
        this.initialize();
        foreach(shader; shaders) this.addShader(shader);
    }
    
    /// Create a new, empty program.
    void initialize(){
        this.handle = glCreateProgram();
        if(this.handle == 0) throw new GLException("Failed to create program.");
    }
    
    /// Detach shaders then delete the program from memory.
    void free(){
        if(this.handle == 0) return;
        this.removeShaders();
        glDeleteProgram(this.handle);
        this.handle = 0;
    }
    
    /// True when the object refers to an existing program.
    /// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glIsProgram.xhtml
    bool opCast(To: bool)() const{
        return cast(bool) glIsProgram(this.handle);
    }
    
    /// Link the program. Throws a LinkException if linking fails.
    /// Automatically compiles any not-yet-compiled shaders.
    /// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glLinkProgram.xhtml
    void link(){
        foreach(shader; this.shaders) {
            if(!shader.compileStatus) {
                shader.compile();
            }
        }
        glLinkProgram(this.handle);
        if(!this.linkStatus) {
            throw new LinkException(this.info);
        }
        this.attributes = this.getActiveAttributes();
        this.uniforms = this.getActiveUniforms();
    }
    
    /// Use this program for the current rendering state.
    /// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glUseProgram.xhtml
    void use(){
        assert(this.handle);
        glUseProgram(this.handle);
        GLException.enforce("Failed to use program.");
    }
    
    /// Bind an attribute index to an `in` variable name.
    /// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glBindAttribLocation.xhtml
    void bind(in GLuint index, in string name) {
        assert(this.handle);
        glBindAttribLocation(this.handle, index, name.tocstring);
        GLException.enforce("Failed to bind vertex attribute index.");
    }
    
    /// Get the program's info log, generated upon linking.
    /// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glGetProgramInfoLog.xhtml
    @property string info(){
        assert(this.handle);
        auto length = this.infoLogLength;
        if(length == 0) return "";
        char[] result = new char[length - 1];
        glGetProgramInfoLog(this.handle, cast(GLsizei) result.length, null, result.ptr);
        return cast(string) result;
    }
    
    /// Get attached shaders.
    /// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glGetAttachedShaders.xhtml
    @property auto shaders(){
        assert(this.handle);
        auto length = this.attachedShaders;
        GLShader[] result = new GLShader[length];
        // This works because the GLShader struct contains only a GLuint field
        // and nothing else. (If that changes, this will need to be revised.)
        glGetAttachedShaders(this.handle, length, null, cast(GLuint*) result.ptr);
        return result;
    }
    
    /// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glGetProgram.xhtml
    auto parameter(in Parameter parameter) const{
        assert(this.handle);
        assert(parameter != Parameter.WorkGroupSize,
            "Parameter unsupported by this method; use workgroupsize instead."
        );
        GLint result = -1;
        glGetProgramiv(this.handle, parameter, &result);
        // If result wasn't modified, indicates an error occurred.
        // (-1 should never be a valid result.)
        if(result == -1) throw new GLException("Failed to get program parameter.");
        return result;
    }
    
    /// Get the size of a program's compute work group as a three-dimensional vector.
    /// OpenGL Superbible p. 674
    @property auto workGroupSize(){
        assert(this.handle);
        auto size = Vector!(3, GLint)(-1, -1, -1);
        glGetProgramiv(this.handle, Parameter.WorkGroupSize, cast(GLint*) &size);
        if(size.x == -1) throw new GLException("Failed to get program parameter.");
        return size;
    }
    
    /// Get the length in characters of the program's info log.
    @property auto infoLogLength() const{
        return this.parameter(Parameter.InfoLogLength);
    }
    /// Get the the number of shaders attached to this program.
    @property auto attachedShaders() const{
        return this.parameter(Parameter.AttachedShaders);
    }
    /// Get whether the program has been successfully linked.
    @property bool linkStatus() const{
        return cast(bool) this.parameter(Parameter.LinkStatus);
    }
    /// Get whether the program has been flagged for deletion.
    @property bool deleteStatus() const{
        return cast(bool) this.parameter(Parameter.DeleteStatus);
    }
    
    /// Get the number of active attribute variables.
    @property GLint activeAttributes() const{
        return cast(GLint) this.parameter(Parameter.ActiveAttributes);
    }
    /// Longest name of any active attribute variable,
    /// including a null terminator.
    @property GLint activeAttributeMaxLength() const{
        return cast(GLint) this.parameter(Parameter.ActiveAttributeMaxLength);
    }
    /// Get the number of active uniform variables.
    @property GLint activeUniforms() const{
        return cast(GLint) this.parameter(Parameter.ActiveUniforms);
    }
    /// Longest name of any active uniform variable,
    /// including a null terminator.
    @property GLint activeUniformMaxLength() const{
        return cast(GLint) this.parameter(Parameter.ActiveUniformMaxLength);
    }
    
    /// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glGetActiveAttrib.xhtml
    GLAttribute getActiveAttribute(in GLuint index) {
        assert(this.handle);
        const maxLength = this.activeAttributeMaxLength;
        char[] nameBuffer = new char[maxLength];
        GLsizei nameLength = void;
        GLint size;
        GLenum type;
        glGetActiveAttrib(
            this.handle, index, cast(GLint) nameBuffer.length,
            &nameLength, &size, &type, nameBuffer.ptr
        );
        GLException.enforce("Failed to get program attribute.");
        return GLAttribute(
            index, cast(string) nameBuffer[0 .. nameLength], size,
            cast(GLProgramActiveAttributeType) type,
        );
    }
    
    auto getActiveAttributes() {
        const attributesCount = this.activeAttributes;
        auto attributes = new GLAttribute[attributesCount];
        for(uint i = 0; i < attributes.length; i++) {
            attributes[i] = this.getActiveAttribute(i);
        }
        return GLAttributes(attributes);
    }
    
    /// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glGetActiveUniform.xhtml
    auto getActiveUniform(in GLuint index) {
        assert(this.handle);
        const maxLength = this.activeUniformMaxLength;
        char[] nameBuffer = new char[maxLength];
        GLsizei nameLength = void;
        GLint size;
        GLenum type;
        glGetActiveUniform(
            this.handle, index, cast(GLint) nameBuffer.length,
            &nameLength, &size, &type, nameBuffer.ptr
        );
        GLException.enforce("Failed to get program attribute.");
        return GLUniform(
            index, cast(string) nameBuffer[0 .. nameLength], size,
            cast(GLProgramActiveUniformType) type,
        );
    }
    
    auto getActiveUniforms() {
        const uniformsCount = this.activeUniforms;
        auto uniforms = new GLUniform[uniformsCount];
        for(uint i = 0; i < uniforms.length; i++) {
            uniforms[i] = this.getActiveUniform(i);
        }
        return GLUniforms(uniforms);
    }
    
    /// Attach a shader to this program.
    /// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glAttachShader.xhtml
    void addShader(in GLuint shader) {
        glAttachShader(this.handle, shader);
    }
    /// Ditto
    void addShader(in GLShader shader) {
        this.addShader(shader.handle);
    }
    /// Detach a shader from this program.
    /// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glDetachShader.xhtml
    void removeShader(in GLuint shader) {
        glDetachShader(this.handle, shader);
    }
    /// Ditto
    void removeShader(in GLShader shader) {
        this.removeShader(shader.handle);
    }
    /// Deatch all attached shaders from this program.
    void removeShaders() {
        foreach(shader; this.shaders) this.removeShader(shader);
    }
    
    ///
    void drawArrays(in GLPrimitive primitive, in GLint offset, in GLsizei count) {
        this.use();
        glDrawArrays(primitive, offset, count);
        GLException.enforce("Failed to draw arrays.");
    }
    
    bool opCast(T: bool)() const {
        return this.handle != 0;
    }
}
