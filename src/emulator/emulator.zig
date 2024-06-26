const std = @import("std");
const SDLScreen = @import("../sdl-renderer/sdl-screen.zig");
const chip80processor = @import("../processor/processor.zig");
const Chip80Processor = chip80processor.Chip80Processor;

const pixelSize = 10;

fn renderCurrentDisplay(display: *const chip80processor.Display, window: *const SDLScreen.WindowDisplay) !void {
    const whiteColor = SDLScreen.Color{ .r = 255, .g = 255, .b = 255, .a = 255 };
    try window.fillWithColor(whiteColor);
    const redColor = SDLScreen.Color{ .r = 255, .g = 0, .b = 0, .a = 255 };
    for (0..32) |y| {
        for (0..64) |x| {
            const xS: u8 = @intCast(x);
            const yS: u8 = @intCast(y);

            const isOn = display.getPixel(xS, yS);
            if (!isOn) {
                continue;
            }
            const lowerX: u32 = @as(u32, @intCast(xS)) * pixelSize;
            const lowerY: u32 = @as(u32, @intCast(yS)) * pixelSize;
            const upperX: u32 = lowerX + pixelSize;
            const upperY: u32 = lowerY + pixelSize;
            for (lowerX..upperX) |x1| {
                for (lowerY..upperY) |y1| {
                    const xS1: u32 = @intCast(x1);
                    const yS1: u32 = @intCast(y1);
                    const p = SDLScreen.DrawPoint{ .x = xS1, .y = yS1 };
                    try window.draw(redColor, p);
                }
            }
        }
    }
    window.update();
}

const delayInMicroSecondsBetweenCycles = 300;

pub fn emulateRom(rom: []u8) !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    var processor = try Chip80Processor.init(allocator);
    defer processor.deinit();
    processor.loadProgram(rom);
    const display = try SDLScreen.WindowDisplay.init();
    var isRunning = true;
    var lastCycleTime = std.time.microTimestamp();
    while (isRunning) {
        const currentTime = std.time.microTimestamp();
        if (currentTime - lastCycleTime >= delayInMicroSecondsBetweenCycles) {
            processor.cycle();
            lastCycleTime = currentTime;
        }

        try renderCurrentDisplay(&processor.display, &display);
        var event = SDLScreen.pollLatestEvent();
        while (event != SDLScreen.Event.nothing) : (event = SDLScreen.pollLatestEvent()) {
            switch (event) {
                SDLScreen.Event.keyDown => {
                    processor.keyPadKeys[event.keyDown] = 1;
                },
                SDLScreen.Event.keyUp => {
                    processor.keyPadKeys[event.keyUp] = 0;
                },
                SDLScreen.Event.nothing => {},
                SDLScreen.Event.quit => {
                    isRunning = false;
                    continue;
                },
            }
        }
        if (display.hasReceivedQuitEvent()) {
            break;
        }
    }
}
