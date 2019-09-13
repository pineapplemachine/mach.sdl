import derelict.sdl2.sdl;
import derelict.opengl3.gl;
import mach.io;
import mach.text;

void main(){
    DerelictGL.load();
    DerelictSDL2.load();

    SDL_Init(SDL_INIT_VIDEO);

    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 2);
    SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);

    SDL_Window *window = SDL_CreateWindow("Test\0".ptr, 100, 100, 640, 480, SDL_WINDOW_OPENGL);
    SDL_GLContext context = SDL_GL_CreateContext(window);

    stdio.writeln(glGetString(GL_VERSION).fromcstring);
}
