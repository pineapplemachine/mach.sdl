module mach.sdl.framelimiter;

private:

import mach.time.duration : Duration;
import mach.time.monotonic : monotonicns;
import mach.time.sleep : sleep;

public:



/// Can be used to limit the maximum number of times a loop executes per second.
/// Uses thread sleep when a loop - generally a rendering frame - takes less
/// time than the imposed limit.
/// TODO: Is the current implementation vulnerable to this?
/// http://stackoverflow.com/questions/23258650/sleep1-and-sdl-delay1-takes-15-ms
struct FrameLimiter{
    /// Target milliseconds per frame.
    float mspflimit = 1000 / 60; // Default 60Hz
    /// Implementation detail to help maintain fractional mspf limits.
    float mspferror = 0;
    
    /// Estimated milliseconds recently spent rendering each frame.
    float rendermspf = 0;
    /// Most recent milliseconds spent rendering for a frame.
    uint lastrenderms = 0;
    /// Estimated milliseconds recently spent sleeping each frame.
    float sleepmspf = 0;
    /// Most recent milliseconds spent sleeping for a frame.
    uint lastsleepms = 0;
    
    /// Determine whether tracking has started. This indicates, for example,
    /// whether mspf estimations are available yet.
    bool tracking = false;
    
    /// Milliseconds on the clock when the previous frame ended.
    ulong lastframems = 0;
    
    /// Current frame number, incremented every time update is called.
    ulong frame = 0;
    
    this(in ulong fpslimit) {
        this.fpslimit = fpslimit;
    }
    
    /// Get target frames per second.
    @property ulong fpslimit() const {
        return cast(ulong)(1000 / this.mspflimit);
    }
    /// Set target frames per second.
    @property void fpslimit(ulong limit) {
        assert(limit >= 0);
        this.mspflimit = double(1000) / limit;
    }
    
    /// Estimated milliseconds recently spent each frame.
    @property auto actualmspf() const {
        return this.rendermspf + this.sleepmspf;
    }
    /// Most recent milliseconds spent for a frame.
    @property auto lastactualms() const {
        return this.lastrenderms + this.lastsleepms;
    }
    /// Estimated frame rate.
    @property auto actualfps() const {
        return 1000 / this.actualmspf;
    }
    
    /// To be called once per rendering loop. Keeps track of the amount of time
    /// spent rendering a frame and, if the rendering time was less than the
    /// limit, suspends the thread to eat up time.
    /// Probably best to call right after swapping buffers. Though that's more
    /// intuition and experience than any empirical advice, so take it with a
    /// grain of salt.
    void update() {
        assert(this.mspflimit >= 0);
        if(this.frame != 0) {
            const nowms = monotonicns() / 1000;
            const renderms = nowms - this.lastframems;
            this.lastrenderms = cast(uint) renderms;
            if(renderms < this.mspflimit) {
                uint imspflimit = cast(uint) this.mspflimit;
                this.mspferror += this.mspflimit - imspflimit;
                // Account for error caused by having a fractional mspf limit
                if(this.mspferror >= 1.0) {
                    this.mspferror--;
                    imspflimit++;
                }
                // Do the actual sleeping
                const sleepms = cast(uint) (imspflimit - renderms);
                this.lastsleepms = sleepms;
                this.sleep(sleepms);
            }
        }
        else {
            this.lastsleepms = 0;
        }
        this.lastframems = monotonicns() / 1000;
        this.frame++;
        if(this.tracking) {
            this.rendermspf = this.lastrenderms * 0.25 + this.rendermspf * 0.75;
            this.sleepmspf = this.lastrenderms * 0.25 + this.rendermspf * 0.75;
        }
        else {
            this.rendermspf = this.lastrenderms;
            this.sleepmspf = this.lastsleepms;
            this.tracking = true;
        }
    }
    
    /// Reset the frame limiter. (I'm not sure what you'd want to do this for,
    /// but here you go anyway.)
    void reset(){
        this.mspferror = 0;
        this.rendermspf = 0;
        this.lastrenderms = 0;
        this.sleepmspf = 0;
        this.lastsleepms = 0;
        this.tracking = false;
        this.lastframems = 0;
        this.frame = 0;
    }
    
    /// Sleep on the current thread for a given number of milliseconds.
    static void sleep(uint ms){
        .sleep(Duration!int.Milliseconds(cast(int) ms));
    }
}



private version(unittest) {
    import mach.test;
}

unittest{
    FrameLimiter fps;
    fps.fpslimit = 60;
    assert(fps.fpslimit == 60);
    fps.fpslimit = 30;
    assert(fps.fpslimit == 30);
    foreach(i; 0 .. 10){
        fps.sleep(2);
        // Values are not accurate until at least one frame has been evaluated
        if(fps.frame > 1){
            // Test correct recording of sleep ms
            assert(fps.lastsleepms > 0);
            // Test correct recording of render ms
            assert(fps.lastrenderms > 0);
            // Test that frame rate limiting is accurate within a margin of 2ms
            // Note: Possibly not 100% deterministic (Sorry)
            assert(fps.lastactualms - fps.mspflimit >= -2);
        }
        fps.update();
    }
}
