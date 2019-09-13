import mach.sdl;
import mach.math;
import derelict.opengl.gl;
import mach.io;

class FragShader: Application{
    GLVertexArray vao;
    
    GLProgram program;
    GLShader vertshader;
    GLShader fragshader;
    
    static immutable vertsource = `
    #version 330 core
    uniform vec2 resolution;
    in vec2 position;
    void main(){
        vec2 pos = (position * 2.0 / resolution) - vec2(1.0);
        gl_Position = vec4(pos.x, -pos.y, 0.0, 1.0);
    }
    `;
    static immutable fragsource = `
    #version 330 core
    uniform vec4 tintcolor;
    out vec4 fragcolor;
    void main(){
        fragcolor = tintcolor;
    }
    `;
    
    override void initialize(){
        // SDL window and OpenGL context creation gets handled automagically
        window = new Window("FragShader", 200, 200);
    }
    
    override void postinitialize(){
        // By the time we're here, we have a workable OpenGL context
        
        vao.initialize(); // Calls glGenVertexArrays
        vao.bind(); // Calls glBindVertexArray
        
        // Calls glCreateShader, glShaderSource, and glCompileShader
        vertshader = GLShader(GLShader.Type.Vertex, vertsource);
        fragshader = GLShader(GLShader.Type.Fragment, fragsource);
        
        // Calls glCreateProgram, glAttachShader, and glLinkProgram
        program = GLProgram(vertshader, fragshader);
        program.use(); // Calls glUseProgram
        
        GLint posattrib = glGetAttribLocation(program.program, "position");
        GLVertexArray.enable(posattrib); // Calls glEnableVertexAttribArray
        
        auto verts = GLBuffer(GLBuffer.Target.Array); // Calls glGenBuffers
        // Calls glBindBuffer, glBufferData, and glVertexAttribPointer
        verts.setdata(
            posattrib, GLBuffer.Target.Array, GLBuffer.Usage.StaticDraw,
            // 0 1
            // 2 3
            [
                Vector2!float(10, 50), Vector2!float(10, 10),
                Vector2!float(50, 50), Vector2!float(50, 10),
                //Vector2!float(10, 10), Vector2!float(50, 10),
                //Vector2!float(10, 50), Vector2!float(50, 50),
            ]
        );
        
        program.setuniformf("resolution", window.size); // Calls glUniform2f
        program.setuniformf("tintcolor", Color.Red); // Calls glUniform4f
    }
    
    override void conclude(){
        // Call glDeleteSomething
        program.free();
        vertshader.free();
        fragshader.free();
        vao.free();
    }
    
    override void main(){
        // This is a main loop
        clear();
        glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
        swap();
    }
}

void main(){
    new FragShader().begin;
}
