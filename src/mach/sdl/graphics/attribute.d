module mach.sdl.graphics.attribute;

private:

import derelict.opengl;

import core.exception : RangeError;

import mach.sdl.error : GLException;
import mach.sdl.glenum : GLProgramActiveAttributeType;
import mach.sdl.glenum : GLVertexAttributePointerType;
import mach.sdl.graphics.buffer : GLBuffer;

public:

struct GLAttributes {
    GLAttribute[] attributes;
    
    GLAttribute opIndex(in size_t index) {
        static const error = new RangeError();
        if(index >= this.attributes.length) throw error;
        return this.attributes[index];
    }
    
    GLAttribute opIndex(in string name) {
        static const error = new RangeError();
        foreach(attribute; this.attributes) {
            if(attribute.name == name) {
                return attribute;
            }
        }
        throw error;
    }
}

/// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glGetActiveAttrib.xhtml
struct GLAttribute {
    GLuint index;
    string name;
    GLuint size;
    GLenum type;
    
    void set(in GLAttributeBuffer attributeBuffer) {
        import mach.io.log;
        assert(attributeBuffer.buffer);
        attributeBuffer.bind();
        glEnableVertexAttribArray(this.index);
        log(this);
        log(attributeBuffer);
        glVertexAttribPointer(
            this.index, attributeBuffer.components,
            attributeBuffer.componentType,
            attributeBuffer.normalized ? GL_TRUE : GL_FALSE,
            attributeBuffer.stride,
            cast(GLvoid*) attributeBuffer.offset
        );
        GLException.enforce("Failed to set vertix attribute pointer.");
    }
}

struct GLAttributeBuffer {
    alias Target = GLBuffer.Target;
    alias Usage = GLBuffer.Usage;
    
    GLint components;
    GLenum componentType;
    bool normalized = false;
    GLsizei stride = 0;
    size_t offset = 0;
    Usage usage = Usage.StaticDraw;
    Target target = Target.ArrayBuffer;
    GLBuffer buffer;
    
    void initialize() {
        this.buffer.initialize();
    }
    
    void free() {
        this.buffer.free();
    }
    
    void bind() const {
        assert(this.buffer);
        this.buffer.bind(this.target);
    }
    
    void set(T)(in T[] data) {
        assert(this.buffer);
        this.buffer.bind(GLBuffer.Target.ArrayBuffer);
        GLBuffer.setBufferData(this.target, this.usage, data);
        GLException.enforce("Failed to set buffer data.");
    }
    
    void update(T)(in T[] data) {
        assert(this.buffer);
        this.buffer.bind(GLBuffer.Target.ArrayBuffer);
        GLBuffer.updateBufferData(this.target, this.usage, data);
        GLException.enforce("Failed to update buffer data.");
    }
}
