const c = @cImport({
    @cInclude("SDL2/SDL.h");
});

const window_width = 640;
const window_height = 320;

pub const SDLError = error{
    UnableToInitializeSDL,
    UnableToCreateWindowAndRenderer,
    UnableToSetRenderDrawColor,
    UnableToRenderClear,
    UnableToRenderDrawPoint,
};

pub const Color = struct {
    r: u8,
    g: u8,
    b: u8,
    a: u8,
};

pub const DrawPoint = struct {
    x: u32,
    y: u32,
};

pub const EventType = enum { nothing, quit, keyUp, keyDown };

pub const Event = union(EventType) {
    nothing: void,
    quit: void,
    keyUp: u8,
    keyDown: u8,
};

const keymap: [16]c_int = [_]c_int{
    c.SDL_SCANCODE_X,
    c.SDL_SCANCODE_1,
    c.SDL_SCANCODE_2,
    c.SDL_SCANCODE_3,
    c.SDL_SCANCODE_Q,
    c.SDL_SCANCODE_W,
    c.SDL_SCANCODE_E,
    c.SDL_SCANCODE_A,
    c.SDL_SCANCODE_S,
    c.SDL_SCANCODE_D,
    c.SDL_SCANCODE_Z,
    c.SDL_SCANCODE_C,
    c.SDL_SCANCODE_4,
    c.SDL_SCANCODE_R,
    c.SDL_SCANCODE_F,
    c.SDL_SCANCODE_V,
};

pub fn pollLatestEvent() Event {
    var event: c.SDL_Event = undefined;
    if (c.SDL_PollEvent(&event) != 0) {
        switch (event.type) {
            c.SDL_QUIT => return Event.quit,
            c.SDL_KEYDOWN => {
                if (event.key.keysym.scancode == c.SDL_SCANCODE_ESCAPE) {
                    return Event.quit;
                }
                var i: u8 = 0;
                while (i < 16) : (i += 1) {
                    if (event.key.keysym.scancode == keymap[i]) {
                        return Event{ .keyDown = i };
                    }
                }
            },
            c.SDL_KEYUP => {
                var i: u8 = 0;
                while (i < 16) : (i += 1) {
                    if (event.key.keysym.scancode == keymap[i]) {
                        return Event{ .keyUp = i };
                    }
                }
            },
            else => {
                return Event.nothing;
            },
        }
    }
    return Event.nothing;
}

pub const WindowDisplay = struct {
    window: *c.SDL_Window,
    renderer: *c.SDL_Renderer,

    pub fn init() SDLError!WindowDisplay {
        if (c.SDL_Init(c.SDL_INIT_VIDEO) != 0) {
            c.SDL_Log("Unable to initialize SDL: %s", c.SDL_GetError());
            return SDLError.UnableToInitializeSDL;
        }

        var window: ?*c.SDL_Window = null;
        var renderer: ?*c.SDL_Renderer = null;

        if (c.SDL_CreateWindowAndRenderer(window_width, window_height, 0, &window, &renderer) != 0) {
            c.SDL_Log("Unable to create window and renderer: %s", c.SDL_GetError());
            return SDLError.UnableToInitializeSDL;
        }
        c.SDL_RenderPresent(renderer);
        return WindowDisplay{ .window = window.?, .renderer = renderer.? };
    }

    pub fn fillWithColor(self: WindowDisplay, color: Color) SDLError!void {
        if (c.SDL_SetRenderDrawColor(self.renderer, color.r, color.g, color.b, color.a) != 0) {
            c.SDL_Log("Unable to create window and renderer: %s", c.SDL_GetError());
            return SDLError.UnableToSetRenderDrawColor;
        }

        if (c.SDL_RenderClear(self.renderer) != 0) {
            c.SDL_Log("Unable to create window and renderer: %s", c.SDL_GetError());
            return SDLError.UnableToRenderClear;
        }
    }

    pub fn draw(self: WindowDisplay, color: Color, point: DrawPoint) SDLError!void {
        if (c.SDL_SetRenderDrawColor(self.renderer, color.r, color.g, color.b, color.a) != 0) {
            c.SDL_Log("c", c.SDL_GetError());
            return SDLError.UnableToSetRenderDrawColor;
        }

        if (c.SDL_RenderDrawPoint(self.renderer, @as(c_int, @intCast(point.x)), @as(c_int, @intCast(point.y))) != 0) {
            c.SDL_Log("", c.SDL_GetError());
            return SDLError.UnableToRenderDrawPoint;
        }
    }

    pub fn hasReceivedQuitEvent(_: WindowDisplay) bool {
        var event: c.SDL_Event = undefined;
        if (c.SDL_PollEvent(&event) != 0) {
            switch (event.type) {
                c.SDL_QUIT => return true,
                else => return false,
            }
        }
        return false;
    }

    pub fn update(self: WindowDisplay) void {
        c.SDL_RenderPresent(self.renderer);
    }
};
