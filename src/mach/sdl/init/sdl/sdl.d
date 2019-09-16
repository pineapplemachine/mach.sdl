module mach.sdl.init.sdl.sdl;

private:

import derelict.util.exception;

import mach.text : text;

import mach.sdl.error : SDLException;
import mach.sdl.init.sdl.core;
import mach.sdl.init.sdl.image;
import mach.sdl.init.sdl.mixer;
import mach.sdl.init.sdl.ttf;
import mach.sdl.init.sdl.net;

import mach.io : log;

public:


struct SDLLoaded {
    /// Whether each component has been loaded.
    bool core = false;
    bool image = false;
    bool mixer = false;
    bool ttf = false;
    bool net = false;
    
    /// Store errors encountered while loading.
    DerelictException coreerror = null;
    DerelictException imageerror = null;
    DerelictException mixererror = null;
    DerelictException ttferror = null;
    DerelictException neterror = null;
    
    /// Determine whether anything has been loaded.
    @property bool anyloaded() const{
        return this.core | this.image | this.mixer | this.ttf | this.net;
    }
    
    /// Unload everything that has been loaded.
    void unload() const{
        if(this.core) Core.unload();
        if(this.image) Image.unload();
        if(this.mixer) Mixer.unload();
        if(this.ttf) TTF.unload();
        if(this.net) Net.unload();
    }
    
    /// Throw any errors that were encountered while loading.
    void enforce() const{
        if(this.coreerror !is null) throw this.coreerror;
        if(this.imageerror !is null) throw this.imageerror;
        if(this.mixererror !is null) throw this.mixererror;
        if(this.ttferror !is null) throw this.ttferror;
        if(this.neterror !is null) throw this.neterror;
    }
    
    string toString() const{
        string status(in bool loaded, in DerelictException exception){
            if(exception !is null) log(exception.msg);
            if(exception !is null) return "Error";
            else if(loaded) return "Loaded";
            else return "Not Loaded";
        }
        return text(
            "Core: ", status(this.core, this.coreerror), ", ",
            "Image: ", status(this.image, this.imageerror), ", ",
            "Mixer: ", status(this.mixer, this.mixererror), ", ",
            "TTF: ", status(this.ttf, this.ttferror), ", ",
            "Net: ", status(this.net, this.neterror)
        );
    }
}

struct SDLSupport {
    static enum Enable{
        Yes, No, Auto
    }
    static bool enabledbool(Enable enabled, bool loaded){
        return enabled is Enable.Yes || (enabled is Enable.Auto && loaded);
    }
    
    static enum typeof(this) All = {
        image: Enable.Auto,
        mixer: Enable.Auto,
        ttf: Enable.Auto,
        net: Enable.Auto,
        coresystems: Core.Systems.Default,
        imageformats: Image.Formats.Default,
        mixerformats: Mixer.Formats.Default,
    };
    
    alias Default = All;
    
    Enable image; /// Whether the image library should be initialized.
    Enable mixer; /// Whether the mixer library should be initialized.
    Enable ttf; /// Whether the TTF library should be initialized.
    Enable net; /// Whether the network library should be initalized.
    Core.Systems coresystems; /// Core systems that should be initialized.
    Image.Formats imageformats; /// Image libraries that should be loaded.
    Mixer.Formats mixerformats; /// Mixer libraries that should be loaded.
    Mixer.Audio audiosettings; /// Settings with which mixer audio should be opened.

    /// Attempt to initialize SDL with the given options.
    void initialize() const{
        if(enabledbool(Enable.Yes, SDL.loaded.core)){
            log("Initializing core bindings");
            if(!SDL.loaded.core) throw new SDLException(
                "Failed to initialize core because it has not been loaded."
            );
            Core.initialize(this.coresystems);
        }
        if(enabledbool(this.image, SDL.loaded.image)){
            log("Initializing image bindings");
            if(!SDL.loaded.image) throw new SDLException(
                "Failed to initialize image library because it has not been loaded."
            );
            Image.initialize(this.imageformats);
        }
        if(enabledbool(this.mixer, SDL.loaded.mixer)){
            log("Initializing mixer bindings");
            if(!SDL.loaded.mixer) throw new SDLException(
                "Failed to initialize mixer library because it has not been loaded."
            );
            Mixer.initialize(this.mixerformats);
            this.audiosettings.open();
        }
        if(enabledbool(this.ttf, SDL.loaded.ttf)){
            log("Initializing ttf bindings");
            if(!SDL.loaded.ttf) throw new SDLException(
                "Failed to initialize TTF library because it has not been loaded."
            );
            TTF.initialize();
        }
        if(enabledbool(this.net, SDL.loaded.net)){
            log("Initializing net bindings");
            if(!SDL.loaded.net) throw new SDLException(
                "Failed to initialize net library because it has not been loaded."
            );
            Net.initialize();
        }
    }
    
    /// Quit SDL things.
    void quit() const{
        if(SDL.loaded.core) Core.quit();
        if(this.image && SDL.loaded.image) Image.quit();
        if(this.mixer && SDL.loaded.mixer){Mixer.Audio.close(); Mixer.quit();}
        if(this.ttf && SDL.loaded.ttf) TTF.quit();
        if(this.net && SDL.loaded.net) Net.quit();
    }
}

struct SDL{
    alias Core = .Core;
    alias Image = .Image;
    alias Mixer = .Mixer;
    alias TTF = .TTF;
    alias Net = .Net;
    
    alias Loaded = SDLLoaded;
    alias Support = SDLSupport;
    
    /// Represents which derelict bindings have been successfully loaded
    static Loaded loaded;
    
    static Support support = Support.All;
    
    /// Load bindings.
    static auto load(
        bool core = true, bool image = true, bool mixer = true,
        bool ttf = true, bool net = true
    ) {
        assert(!loaded.anyloaded, "Unload before attempting to load again.");
        log("Loading dynamic libraries.");
        loaded = Loaded.init;
        if(core){
            try{
                Core.load();
            }catch(DerelictException exception){
                loaded.coreerror = exception;
            }
            loaded.core = loaded.coreerror is null;
            log("Loaded core bindings: ", loaded.core);
        }
        if(image){
            try{
                Image.load();
            }catch(DerelictException exception){
                loaded.imageerror = exception;
            }
            loaded.image = loaded.imageerror is null;
            log("Loaded image bindings: ", loaded.image);
        }
        if(mixer){
            try{
                Mixer.load();
            }catch(DerelictException exception){
                loaded.mixererror = exception;
            }
            loaded.mixer = loaded.mixererror is null;
            log("Loaded mixer bindings: ", loaded.mixer);
        }
        if(ttf){
            try{
                TTF.load();
            }catch(DerelictException exception){
                loaded.ttferror = exception;
            }
            loaded.ttf = loaded.ttferror is null;
            log("Loaded ttf bindings: ", loaded.ttf);
        }
        if(net){
            try{
                Net.load();
            }catch(DerelictException exception){
                loaded.neterror = exception;
            }
            loaded.net = loaded.neterror is null;
            log("Loaded net bindings: ", loaded.net);
        }
        log("Status of dynamic library loading:\n", loaded);
        return loaded;
    }
    static void unload(){
        this.loaded.unload();
    }
    
    /// Attempt to initialize SDL with the given options. Returns a list of
    /// errors that occurred, if any.
    static auto initialize(){
        return support.initialize();
    }
    
    /// Quit SDL things.
    static void quit(){
        support.quit();
    }
}
