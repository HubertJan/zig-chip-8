const std = @import("std");
const SDLScreen = @import("sdl-renderer/sdl-screen.zig");
const extractFilePathFromArguments = @import("io/program-arguments.zig").extractFilePathFromArguments;
const readRomFromFilePath = @import("io/read-rom.zig").readRomFromFilePath;
const Emulator = @import("emulator/emulator.zig");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();
    const allocator = arena.allocator();
    const path = try extractFilePathFromArguments(allocator);
    const rom = try readRomFromFilePath(path, allocator);
    defer rom.deinit();

    try Emulator.emulateRom(rom.items);
}
