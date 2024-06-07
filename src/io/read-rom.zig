const std = @import("std");
const Allocator = std.mem.Allocator;
const ArrayList = std.ArrayList;

pub fn readRomFromFilePath(filePath: [*:0]const u8, allocator: Allocator) !std.ArrayList(u8) {
    var path_buffer: [std.fs.MAX_PATH_BYTES]u8 = undefined;
    const path = try std.fs.realpathZ(filePath, &path_buffer);
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
    return rom;
}
