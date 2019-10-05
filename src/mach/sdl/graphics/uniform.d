module mach.sdl.graphics.uniform;

private:

import derelict.opengl;

import core.exception : RangeError;

import mach.types.tuple : tupleFromArray;
import mach.traits.primitives : isNumeric;
import mach.math.vector : Vector, isVector, isVector2, isVector3, isVector4;
import mach.math.matrix : Matrix, isMatrix;
import mach.meta.ctint : ctint;

import mach.sdl.glenum : GLProgramActiveUniformType, GLSamplerParameter;
import mach.sdl.graphics.color : Color;
import mach.sdl.graphics.sampler : GLSampler;

public:

private string getUniformFunction(uint size, string suffix) {
    return "glUniform" ~ ctint(size) ~ suffix;
}

private string getUniformMatrixFunction(uint width, uint height, string suffix) {
    if(width == height) {
        return "glUniformMatrix" ~ ctint(width) ~ suffix;
    }
    else {
        return "glUniformMatrix" ~ ctint(width) ~ `x` ~ ctint(height) ~ suffix;
    }
}

/// Example: uniforms["u_position"] = vector(1.0, 2.0, 3.0);
struct GLUniforms {
    GLUniform[] uniforms;
    
    GLUniform opIndex(in size_t index) {
        static const error = new RangeError();
        if(index >= this.uniforms.length) throw error;
        return this.uniforms[index];
    }
    
    GLUniform opIndex(in string name) {
        static const error = new RangeError();
        foreach(uniform; this.uniforms) {
            if(uniform.name == name) {
                return uniform;
            }
        }
        throw error;
    }
}

/// https://www.khronos.org/registry/OpenGL-Refpages/gl4/html/glGetActiveUniform.xhtml
struct GLUniform {
    GLuint index;
    string name;
    GLuint size;
    GLProgramActiveUniformType type;
    
    /// Wraps glUniform1f
    void setf(T)(in T value) if(isNumeric!T) {
        glUniform1f(this.index, cast(GLfloat) value);
    }
    
    /// Wraps glUniform1d
    void setd(T)(in T value) if(isNumeric!T) {
        glUniform1d(this.index, cast(GLdouble) value);
    }
    
    /// Wraps glUniform1i
    void seti(T)(in T value) if(isNumeric!T) {
        glUniform1i(this.index, cast(GLint) value);
    }
    /// Ditto
    void seti(in GLSampler sampler) {
        glUniform1i(this.index, sampler.handle);
    }
    
    /// Wraps glUniform1ui
    void setui(T)(in T value) if(isNumeric!T) {
        glUniform1ui(this.index, cast(GLuint) value);
    }
    
    /// Wraps glUniform[N]f
    void setf(T, size_t N)(in T[N] vector) if(isNumeric!T) {
        mixin(`alias setUniform = ` ~ getUniformFunction(N, "f") ~ `;`);
        setUniform(this.index, tupleFromArray(cast(GLfloat[N]) vector).expand);
    }
    /// Ditto
    void setf(T)(in T vector) if(isVector!T) {
        mixin(`alias setUniform = ` ~ getUniformFunction(T.size, "f") ~ `;`);
        setUniform(this.index, (cast(Vector!(T.size, GLfloat)) vector).values);
    }
    
    /// Wraps glUniform[N]d
    void setd(T, size_t N)(in T[N] vector) if(isNumeric!T) {
        mixin(`alias setUniform = ` ~ getUniformFunction(N, "d") ~ `;`);
        setUniform(this.index, tupleFromArray(cast(GLdouble[N]) vector).expand);
    }
    /// Ditto
    void setd(T)(in T vector) if(isVector!T) {
        mixin(`alias setUniform = ` ~ getUniformFunction(T.size, "d") ~ `;`);
        setUniform(this.index, (cast(Vector!(T.size, GLdouble)) vector).values);
    }
    
    /// Wraps glUniform[N]i
    void seti(T, size_t N)(in T[N] vector) if(isNumeric!T) {
        mixin(`alias setUniform = ` ~ getUniformFunction(N, "i") ~ `;`);
        setUniform(this.index, tupleFromArray(cast(GLint[N]) vector).expand);
    }
    /// Ditto
    void seti(T)(in T vector) if(isVector!T) {
        mixin(`alias setUniform = ` ~ getUniformFunction(T.size, "i") ~ `;`);
        setUniform(this.index, (cast(Vector!(T.size, GLint)) vector).values);
    }
    
    /// Wraps glUniform[N]ui
    void setui(T, size_t N)(in T[N] vector) if(isNumeric!T) {
        mixin(`alias setUniform = ` ~ getUniformFunction(N, "ui") ~ `;`);
        setUniform(this.index, tupleFromArray(cast(GLuint[N]) vector).expand);
    }
    /// Ditto
    void setui(T)(in T vector) if(isVector!T) {
        mixin(`alias setUniform = ` ~ getUniformFunction(T.size, "ui") ~ `;`);
        setUniform(this.index, (cast(Vector!(T.size, GLuint)) vector).values);
    }
    
    /// Wraps glUniformMatrix[X]fv / glUniformMatrix[W]x[H]fv
    void setf(T)(in T matrix) if(isMatrix!T) {
        mixin(`alias setUniform = ` ~ getUniformMatrixFunction(T.width, T.height, "fv") ~ `;`);
        immutable useMatrix = cast(Matrix!(T.width, T.height, GLfloat)) matrix;
        setUniform(this.index, 1, false, &useMatrix);
    }
    /// Wraps glUniformMatrix[X]fv
    void setf(T, size_t N)(in T[N] matrix) if(isNumeric!T) {
        static if(N == 4) alias setUniform = glUniformMatrix2fv;
        else static if(N == 9) alias setUniform = glUniformMatrix3fv;
        else static if(N == 16) alias setUniform = glUniformMatrix4fv;
        else static assert("Invalid matrix size.");
        immutable useMatrix = tupleFromArray(cast(GLfloat[N]) matrix);
        setUniform(this.index, 1, false, &useMatrix);
    }
    
    /// Wraps glUniformMatrix[X]dv / glUniformMatrix[W]x[H]dv
    void setd(T)(in T matrix) if(isMatrix!T) {
        mixin(`alias setUniform = ` ~ getUniformMatrixFunction(T.width, T.height, "dv") ~ `;`);
        immutable useMatrix = cast(Matrix!(T.width, T.height, GLdouble)) matrix;
        setUniform(this.index, 1, false, &useMatrix);
    }
    /// Wraps glUniformMatrix[X]dv
    void setf(T, size_t N)(in T[N] matrix) if(isNumeric!T) {
        static if(N == 4) alias setUniform = glUniformMatrix2dv;
        else static if(N == 9) alias setUniform = glUniformMatrix3dv;
        else static if(N == 16) alias setUniform = glUniformMatrix4dv;
        else static assert("Invalid matrix size.");
        immutable useMatrix = tupleFromArray(cast(GLdouble[N]) matrix);
        setUniform(this.index, 1, false, &useMatrix);
    }
    
    /// Wraps glUniform1fv
    void setf(T...)(in T values) if(T.length > 1) {
        glUniform1fv(this.index, cast(GLsizei) values.length, &vector(values));
    }
    /// Ditto
    void setf(in GLfloat[] values) {
        glUniform1fv(this.index, cast(GLsizei) values.length, values.ptr);
    }
    
    /// Wraps glUniform1dv
    void setd(T...)(in T values) if(T.length > 1) {
        glUniform1dv(this.index, cast(GLsizei) values.length, &vector(values));
    }
    /// Ditto
    void setd(in GLdouble[] values) {
        glUniform1dv(this.index, cast(GLsizei) values.length, values.ptr);
    }
    
    /// Wraps glUniform1iv
    void seti(T...)(in T values) if(T.length > 1) {
        glUniform1iv(this.index, cast(GLsizei) values.length, &vector(values));
    }
    /// Ditto
    void seti(in GLint[] values) {
        glUniform1iv(this.index, cast(GLsizei) values.length, values.ptr);
    }
    
    /// Wraps glUniform1uiv
    void setui(T...)(in T values) if(T.length > 1) {
        glUniform1uiv(this.index, cast(GLsizei) values.length, &vector(values));
    }
    /// Ditto
    void setui(in GLuint[] values) {
        glUniform1uiv(this.index, cast(GLsizei) values.length, values.ptr);
    }
    
    /// Wraps glUniform[N]fv
    void setf(size_t N)(in GLfloat[N][] vectors) {
        mixin(`alias setUniform = ` ~ getUniformFunction(T.size, "fv") ~ `;`);
        setUniform(this.index, vectors.length, vectors.ptr);
    }
    /// Ditto
    void setf(size_t x)(in Vector!(x, GLfloat)[] vectors) {
        mixin(`alias setUniform = ` ~ getUniformFunction(T.size, "fv") ~ `;`);
        setUniform(this.index, vectors.length, vectors.ptr);
    }
    
    /// Wraps glUniform[N]dv
    void setd(size_t N)(in GLdouble[N][] vectors) {
        mixin(`alias setUniform = ` ~ getUniformFunction(T.size, "dv") ~ `;`);
        setUniform(this.index, vectors.length, vectors.ptr);
    }
    /// Ditto
    void setd(size_t x)(in Vector!(x, GLdouble)[] vectors) {
        mixin(`alias setUniform = ` ~ getUniformFunction(T.size, "dv") ~ `;`);
        setUniform(this.index, vectors.length, vectors.ptr);
    }
    
    /// Wraps glUniform[N]iv
    void seti(size_t N)(in GLint[N][] vectors) {
        mixin(`alias setUniform = ` ~ getUniformFunction(T.size, "iv") ~ `;`);
        setUniform(this.index, vectors.length, vectors.ptr);
    }
    /// Ditto
    void seti(size_t x)(in Vector!(x, GLint)[] vectors) {
        mixin(`alias setUniform = ` ~ getUniformFunction(T.size, "iv") ~ `;`);
        setUniform(this.index, vectors.length, vectors.ptr);
    }
    
    /// Wraps glUniform[N]uiv
    void setui(size_t N)(in GLuint[N][] vectors) {
        mixin(`alias setUniform = ` ~ getUniformFunction(T.size, "uiv") ~ `;`);
        setUniform(this.index, vectors.length, vectors.ptr);
    }
    /// Ditto
    void setui(size_t x)(in Vector!(x, GLuint)[] vectors) {
        mixin(`alias setUniform = ` ~ getUniformFunction(T.size, "uiv") ~ `;`);
        setUniform(this.index, vectors.length, vectors.ptr);
    }
    
    /// Wraps glUniformMatrix[X]fv / glUniformMatrix[W]x[H]fv
    void setf(size_t x, size_t y)(in Matrix!(x, y, GLfloat) matrixes) {
        mixin(`alias setUniform = ` ~ getUniformMatrixFunction(T.width, T.height, "fv") ~ `;`);
        setUniform(this.index, matrixes.length, false, matrixes.ptr);
    }
    
    /// Wraps glUniformMatrix[X]dv / glUniformMatrix[W]x[H]dv
    void setd(size_t x, size_t y)(in Matrix!(x, y, GLdouble) matrixes) {
        mixin(`alias setUniform = ` ~ getUniformMatrixFunction(T.width, T.height, "dv") ~ `;`);
        setUniform(this.index, matrixes.length, false, matrixes.ptr);
    }
    
    /// 
    void set(in GLSampler sampler) {
        return this.seti(sampler.handle);
    }
    
    /// 
    void set(T)(in T value) if(is(T == bool) || isNumeric!T) {
        static const error = new Error();
        switch(this.type) {
            case GL_FLOAT: return this.setf(value);
            case GL_DOUBLE: return this.setd(value);
            case GL_INT: return this.seti(value);
            case GL_UNSIGNED_INT: return this.setui(value);
            case GL_BOOL: return this.seti(cast(bool) value ? 1 : 0);
            default: throw error;
        }
    }
    
    void set(in GLfloat[] values) {
        this.setf(values);
    }
    void set(in GLdouble[] values) {
        this.setd(values);
    }
    void set(in GLint[] values) {
        this.seti(values);
    }
    void set(in GLuint[] values) {
        this.setui(values);
    }
    
    void set(T)(in T vector) if(isVector!T) {
        static const error = new Error("Unknown uniform type.");
        switch(cast(GLenum) this.type) {
            case GL_FLOAT:
            case GL_FLOAT_VEC2:
            case GL_FLOAT_VEC3:
            case GL_FLOAT_VEC4:
                return this.setf(vector);
            case GL_DOUBLE:
            case GL_DOUBLE_VEC2:
            case GL_DOUBLE_VEC3:
            case GL_DOUBLE_VEC4:
                return this.setd(vector);
            case GL_INT:
            case GL_INT_VEC2:
            case GL_INT_VEC3:
            case GL_INT_VEC4:
                return this.seti(vector);
            case GL_UNSIGNED_INT:
            case GL_UNSIGNED_INT_VEC2:
            case GL_UNSIGNED_INT_VEC3:
            case GL_UNSIGNED_INT_VEC4:
                return this.setui(vector);
            case GL_BOOL:
            case GL_BOOL_VEC2:
            case GL_BOOL_VEC3:
            case GL_BOOL_VEC4:
                return this.seti(vector);
            default:
                throw error;
        }
    }
    
    void set(size_t N)(in Vector!(N, GLfloat)[] vectors) {
        return this.setf(vectors);
    }
    void set(size_t N)(in GLfloat[N][] vectors) {
        return this.setf(vectors);
    }
    void set(size_t N)(in Vector!(N, GLdouble)[] vectors) {
        return this.setd(vectors);
    }
    void set(size_t N)(in GLdouble[N][] vectors) {
        return this.setd(vectors);
    }
    void set(size_t N)(in Vector!(N, GLint)[] vectors) {
        return this.seti(vectors);
    }
    void set(size_t N)(in GLint[N][] vectors) {
        return this.seti(vectors);
    }
    void set(size_t N)(in Vector!(N, GLuint)[] vectors) {
        return this.setui(vectors);
    }
    void set(size_t N)(in GLuint[N][] vectors) {
        return this.setui(vectors);
    }
    
    void set(T)(in T matrix) if(isMatrix!T) {
        static const error = new Error();
        switch(cast(GLenum) this.type) {
            case GL_FLOAT_MAT2:
            case GL_FLOAT_MAT3:
            case GL_FLOAT_MAT4:
            case GL_FLOAT_MAT2x3:
            case GL_FLOAT_MAT2x4:
            case GL_FLOAT_MAT3x2:
            case GL_FLOAT_MAT3x4:
            case GL_FLOAT_MAT4x2:
            case GL_FLOAT_MAT4x3:
                return this.setf(matrix);
            case GL_DOUBLE_MAT2:
            case GL_DOUBLE_MAT3:
            case GL_DOUBLE_MAT4:
            case GL_DOUBLE_MAT2x3:
            case GL_DOUBLE_MAT2x4:
            case GL_DOUBLE_MAT3x2:
            case GL_DOUBLE_MAT3x4:
            case GL_DOUBLE_MAT4x2:
            case GL_DOUBLE_MAT4x3:
                return this.setd(matrix);
            default:
                throw error;
        }
    }
    
    void set(size_t N)(in GLfloat[N][] matrixes) {
        return this.setf(matrixes);
    }
    void set(size_t x, size_t y)(in Matrix!(x, y, GLfloat)[] matrixes) {
        return this.setf(matrixes);
    }
    
    void set(size_t N)(in GLdouble[N][] matrixes) {
        return this.setd(matrixes);
    }
    void set(size_t x, size_t y)(in Matrix!(x, y, GLdouble)[] matrixes) {
        return this.setd(matrixes);
    }
}
