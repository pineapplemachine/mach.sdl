module mach.sdl.gldebug;

private:

import derelict.opengl;

import mach.text.numeric.integrals : writeint;

import mach.sdl.glenum : GLDebugMessageType, GLDebugMessageSeverity;
import mach.sdl.glenum : GLDebugMessageSource;

public:

struct GLDebugMessage {
    GLDebugMessageSource source;
    GLDebugMessageType type;
    GLuint id;
    GLDebugMessageSeverity severity;
    string text;
    
    static string SourceToString(in GLDebugMessageSource source) {
        switch(source) {
            case GLDebugMessageSource.Api: return "API";
            case GLDebugMessageSource.WindowSystem: return "Window System";
            case GLDebugMessageSource.ShaderCompiler: return "Shader Compiler";
            case GLDebugMessageSource.ThirdParty: return "Third-Party";
            case GLDebugMessageSource.Application: return "Application";
            case GLDebugMessageSource.Other: return "Other";
            default: return "Source(" ~ writeint(cast(GLenum) source) ~ ")";
        }
    }
    
    static string TypeToString(in GLDebugMessageType type) {
        switch(type) {
            case GLDebugMessageType.Error: return "Error";
            case GLDebugMessageType.DeprecatedBehavior: return "Deprecated Behavior";
            case GLDebugMessageType.UndefinedBehavior: return "Undefined Behavior";
            case GLDebugMessageType.Portability: return "Portability";
            case GLDebugMessageType.Performance: return "Performance";
            case GLDebugMessageType.Marker: return "Marker";
            case GLDebugMessageType.PushGroup: return "Push Group";
            case GLDebugMessageType.PopGroup: return "Pop Group";
            case GLDebugMessageType.Other: return "Other";
            default: return "Type(" ~ writeint(cast(GLenum) type) ~ ")";
        }
    }
    
    static string SeverityToString(in GLDebugMessageSeverity severity) {
        switch(severity) {
            case GLDebugMessageSeverity.Low: return "Low";
            case GLDebugMessageSeverity.Medium: return "Medium";
            case GLDebugMessageSeverity.High: return "High";
            case GLDebugMessageSeverity.Notification: return "Notification";
            default: return "Severity(" ~ writeint(cast(GLenum) severity) ~ ")";
        }
    }
    
    static string getLog(in GLuint count = 64, in size_t bufferSize = 4096) {
        string log = "";
        const messages = typeof(this).getLogMessages(count, bufferSize);
        foreach(message; messages) {
            if(log.length) {
                log ~= '\n';
            }
            log ~= message.toString();
        }
        return log;
    }
    
    static GLDebugMessage[] getLogMessages(
        in GLuint count = 64, in size_t bufferSize = 4096
    ) {
        GLenum[] sources = new GLenum[count];
        GLenum[] types = new GLenum[count];
        GLuint[] ids = new GLuint[count];
        GLenum[] severities = new GLenum[count];
        GLsizei[] lengths = new GLsizei[count];
        char[] buffer = new char[bufferSize];
        const actualCount = glGetDebugMessageLog(
            count, cast(GLsizei) buffer.length,
            sources.ptr, types.ptr, ids.ptr,
            severities.ptr, lengths.ptr, buffer.ptr
        );
        GLDebugMessage[] messages = new GLDebugMessage[cast(size_t) actualCount];
        size_t bufferOffset = 0;
        for(size_t i = 0; i < messages.length; i++) {
            messages[i] = GLDebugMessage(
                cast(GLDebugMessageSource) sources[i],
                cast(GLDebugMessageType) types[i], ids[i],
                cast(GLDebugMessageSeverity) severities[i],
                cast(string) buffer[bufferOffset .. bufferOffset + lengths[i]]
            );
            bufferOffset += lengths[i];
        }
        return messages;
    }
    
    string toString() const {
        return (this.text ~ "(" ~
           GLDebugMessage.SourceToString(this.source) ~ ", " ~
           GLDebugMessage.TypeToString(this.type) ~ ", " ~
           GLDebugMessage.SeverityToString(this.severity) ~
        ")");
    }
}
