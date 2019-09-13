module mach.sdl.error.gl;

private:

import derelict.opengl;
import mach.error : ThrowableCtorMixin;

public:



/// Class for errors which occur interfacing with OpenGL.
class GLException: Exception{
    /// An enumeration of possible OpenGL error codes.
    static enum ErrorCode : uint{
        NoError = GL_NO_ERROR,
        InvalidEnum = GL_INVALID_ENUM,
        InvalidValue = GL_INVALID_VALUE,
        InvalidOperation = GL_INVALID_OPERATION,
        //StackOverflow = GL_STACK_OVERFLOW,
        //StackUnderflow = GL_STACK_UNDERFLOW,
        OutOfMemory = GL_OUT_OF_MEMORY,
        InvalidFramebuffer = GL_INVALID_FRAMEBUFFER_OPERATION,
        ContextLost = GL_CONTEXT_LOST,
        //TableTooLarge = GL_TABLE_TOO_LARGE,
    }
    
    ErrorCode[] errors;
    
    nothrow this(size_t line = __LINE__, string file = __FILE__){
        this(geterrors(), line, file);
    }
    nothrow this(ErrorCode error, size_t line = __LINE__, string file = __FILE__){
        this([error], line, file);
    }
    nothrow this(ErrorCode[] errors, size_t line = __LINE__, string file = __FILE__){
        this.errors = errors;
        super(errorstring(errors), file, line, null);
    }
    nothrow this(string message, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        this(message, geterrors(), next, line, file);
    }
    nothrow this(string message, ErrorCode[] errors, Throwable next = null, size_t line = __LINE__, string file = __FILE__){
        this.errors = errors;
        super(errors.length ? message ~ " " ~ errorstring(errors) : message, file, line, next);
    }
    
    /// Get a list of errors which have occurred and so far gone unhandled.
    static ErrorCode[] geterrors() nothrow{
        ErrorCode[] errors;
        while(true){
            ErrorCode error = cast(ErrorCode) glGetError();
            if(error == ErrorCode.NoError) break;
            errors ~= error;
        }
        return errors;
    }
    
    /// https://www.opengl.org/wiki/OpenGL_Error
    static errorstring(in ErrorCode code) @safe pure nothrow{
        final switch(code){
            case ErrorCode.NoError:
                return "GL_NO_ERROR: No error recorded.";
            case ErrorCode.InvalidEnum:
                return "GL_INVALID_ENUM: Enumeration parameter not legal for called function.";
            case ErrorCode.InvalidValue:
                return "GL_INVALID_VALUE: A numeric parameter is out of range for called function.";
            case ErrorCode.InvalidOperation:
                return "GL_INVALID_OPERATION: Operation is not allowed in the current state.";
            //case ErrorCode.StackOverflow:
            //    return "GL_STACK_OVERFLOW: Cannot perform operation because it would cause a stack overflow.";
            //case ErrorCode.StackUnderflow:
            //    return "GL_STACK_UNDERFLOW: Cannot perform operation because it would cause a stack underflow.";
            case ErrorCode.OutOfMemory:
                return "GL_OUT_OF_MEMORY: Insufficient memory available to perform operation.";
            case ErrorCode.InvalidFramebuffer:
                return "GL_INVALID_FRAMEBUFFER_OPERATION: Invalid attempt to read from or write to an incomplete framebuffer.";
            case ErrorCode.ContextLost:
                return "GL_CONTEXT_LOST: OpenGL context has been lost, probably because of a graphics card reset.";
            //case ErrorCode.TableTooLarge:
            //    return "GL_TABLE_TOO_LARGE: Specified table exceeds the maximum supported table size.";
        }
    }
    
    static string errorstring(in ErrorCode[] errors) nothrow{
        if(errors.length == 0){
            return errorstring([ErrorCode.NoError]);
        }else if(errors.length == 1){
            return errorstring(errors[0]);
        }else{
            string str = "";
            foreach(error; errors){
                if(str.length) str ~= " ";
                str ~= errorstring(error);
            }
            return "Encountered multiple errors: " ~ str;
        }
    }
    
    /// Check if any errors have occurred and, if so, throw a new GLException
    /// reporting them.
    static void enforce(size_t line = __LINE__, string file = __FILE__){
        ErrorCode[] errors = geterrors();
        if(errors.length) throw new GLException(errors, line, file);
    }
    /// Ditto
    static void enforce(string message, size_t line = __LINE__, string file = __FILE__){
        ErrorCode[] errors = geterrors();
        if(errors.length) throw new GLException(message, errors, null, line, file);
    }
}