module mach.sdl.graphics.vertexbuffer;

private:

//

public:

// Reference: http://antongerdelan.net/opengl/vertexbuffers.html

struct VertexBuffer{
    uint vbo;
    uint vao;
    size_t length;
    this(T)(Vector2!T vectors...){
        glGenBuffers(1, &this.vbo);
        glGenVertexArrays(1, &this.vao);
        glEnableVertexAttribArray(this.vao);
        this.set(vectors);
    }
    void set(Vector2!T vectors...){
        this.length = vectors.length;
        glBindVertexArray(this.vao);
        glBindBuffer(GL_ARRAY_BUFFER, this.vbo);
        glBufferData(GL_ARRAY_BUFFER, vectors.length * Vector2!T.sizeof, vectors.ptr, GL_DYNAMIC_DRAW);
        glVertexAttribPointer(this.vbo, 2, getvertextype!T, GL_FALSE, 0, null);
    }
    void draw(GLPrimitive primitive){
        glBindVertexArray(this.vao);
        glDrawArrays(primitive, 0, this.length;
    }
}
