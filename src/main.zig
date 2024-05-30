const chip80processor = @import("processor/processor.zig");
const Chip80Processor = chip80processor.Chip80Processor;
const std = @import("std");
const SDLScreen = @import("sdl-renderer/sdl-screen.zig");

const ProgramError = error{
    WrongAmountOfArguments,
};

pub fn main() !void {
    const display = try SDLScreen.WindowDisplay.init();
    const whiteColor = SDLScreen.Color{ .r = 255, .g = 255, .b = 255, .a = 255 };
    const redColor = SDLScreen.Color{ .r = 255, .g = 0, .b = 0, .a = 255 };
    try display.fillWithColor(whiteColor);
    const point = SDLScreen.DrawPoint{ .x = 100, .y = 100 };
    try display.draw(redColor, point);
    for (5..10) |i| {
        const p = SDLScreen.DrawPoint{ .x = 100, .y = @as(u8, @intCast(i)) };
        try display.draw(redColor, p);
    }
    for (0..300) |i| {
        const j = @as(u32, @intCast(i));
        const p = SDLScreen.DrawPoint{ .x = j, .y = j };
        try display.draw(redColor, p);
    }
    display.update();
    display.loop();
}
