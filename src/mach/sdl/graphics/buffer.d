module mach.sdl.graphics.buffer;

private:

import derelict.opengl;

import mach.sdl.error : GLException;
import mach.sdl.glenum : GLVertexAttributePointerType;
import mach.sdl.glenum : GLBufferUsage, GLBindBufferTarget;

public:


/// https://www.khronos.org/opengl/wiki/Buffer_Object
struct GLBuffer {
    alias Target = GLBindBufferTarget;
    alias Usage = GLBufferUsage;
    
    GLuint handle = 0;
    
    this(in GLuint handle) {
        this.handle = handle;
    }
    
    void initialize() {
        assert(this.handle == 0);
        glGenBuffers(1, &this.handle);
    }
    
    void free() {
        glDeleteBuffers(1, &this.handle);
        this.handle = 0;
    }
    
    void bind(in Target target) const {
        assert(this.handle != 0);
        glBindBuffer(target, this.handle);
    }
    
    /// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glBufferData.xhtml
    void set(T)(in Usage usage, in T[] data) {
        assert(this.handle != 0);
        glNamedBufferData(this.handle, data.length * T.sizeof, data.ptr, usage);
    }
    
    /// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glBufferSubData.xhtml
    /// https://www.khronos.org/opengl/wiki/Buffer_Object#Data_Specification
    void update(T)(in T[] data, in GLintptr offset = 0) {
        assert(this.handle != 0);
        glNamedBufferSubData(this.handle, offset, data.length * T.sizeof, data.ptr);
    }
    
    /// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glBufferData.xhtml
    static void setBufferData(T)(in Target target, in Usage usage, in T[] data) {
        glBufferData(target, data.length * T.sizeof, data.ptr, usage);
    }
    
    /// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glBufferSubData.xhtml
    static void updateBufferData(T)(in Target target, in T[] data, in GLintptr offset) {
        glBufferSubData(target, offset, data.length * T.sizeof, data.ptr);
    }
    
    bool opCast(T: bool)() const {
        return this.handle != 0;
    }
}
