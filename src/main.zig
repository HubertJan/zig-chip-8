const chip80processor = @import("processor/processor.zig");
const Chip80Processor = chip80processor.Chip80Processor;
const std = @import("std");
const SDLScreen = @import("sdl-renderer/sdl-screen.zig");

const ProgramError = error{
    WrongAmountOfArguments,
};

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
            const lowerX: u32 = @intCast(xS * 4);
            const lowerY: u32 = @intCast(yS * 4);
            const upperX: u32 = lowerX + 4;
            const upperY: u32 = lowerY + 4;
            for (lowerX..upperX) |x1| {
                for (lowerY..upperY) |y1| {
                    const xS1: u8 = @intCast(x1);
                    const yS1: u8 = @intCast(y1);
                    const p = SDLScreen.DrawPoint{ .x = xS1, .y = yS1 };
                    try window.draw(redColor, p);
                }
            }
        }
    }
    window.update();
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();

    const args = try std.process.argsAlloc(allocator);
    if (args.len != 2) {
        std.log.err(
            "Incorrect number of arguments: wanted 2, got {d}",
            .{args.len},
        );
        return ProgramError.WrongAmountOfArguments;
    }
    const filename = args[1];

    var path_buffer: [std.fs.MAX_PATH_BYTES]u8 = undefined;
    const path = try std.fs.realpathZ(filename, &path_buffer);

    const file = try std.fs.openFileAbsolute(path, .{});
    defer file.close();

    var buffered_file = std.io.bufferedReader(file.reader());
    var buffer: [1]u8 = undefined;
    var rom = std.ArrayList(u8).init(allocator);
    while (true) {
        const number_of_read_bytes = try buffered_file.read(&buffer);

        if (number_of_read_bytes == 0) {
            break;
        }
        try rom.append(buffer[0]);
    }
    var processor = try Chip80Processor.init(allocator);
    processor.loadProgram(rom.items);
    const display = try SDLScreen.WindowDisplay.init();
    while (true) {
        processor.cycle();
        try renderCurrentDisplay(&processor.display, &display);
        if (display.hasReceivedQuitEvent()) {
            break;
        }
        std.time.sleep(1000 * 1000 * 100);
    }
}
