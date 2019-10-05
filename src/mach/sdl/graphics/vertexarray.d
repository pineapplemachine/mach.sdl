module mach.sdl.graphics.vertexarray;

private:

import derelict.opengl;

import mach.traits : isString, isNumeric, isIntegral, isArrayOf;
import mach.math.vector : Vector, isVector, isVector2, isVector3, isVector4;
import mach.math.matrix : Matrix, isMatrix;
import mach.text.cstring : tocstring;
import mach.range.asarray : asarray;
import mach.io.file.path : Path;

import mach.sdl.error : GLException;

public:

/// https://www.khronos.org/opengl/wiki/Vertex_Specification#Vertex_Array_Object
struct GLVertexArray {
    GLuint handle = 0;
    
    void initialize() {
        assert(this.handle == 0);
        glGenVertexArrays(1, &this.handle);
    }
    
    void free() {
        glDeleteVertexArrays(1, &this.handle);
        this.handle = 0;
    }
    
    /// https://www.khronos.org/opengl/wiki/GLAPI/glBindVertexArray
    void bind() {
        assert(this.handle != 0);
        glBindVertexArray(this.handle);
    }
    
    bool opCast(T: bool)() const {
        return this.handle != 0;
    }
}
