const std = @import("std");
const Allocator = std.mem.Allocator;

const ArgumentError = error{
    WrongAmountOfArguments,
};

pub fn extractFilePathFromArguments(allocator: Allocator) ![*:0]const u8 {
    const args = try std.process.argsAlloc(allocator);
    if (args.len != 2) {
        std.log.err(
            "Incorrect number of arguments: wanted 2, got {d}",
            .{args.len},
        );
        return ArgumentError.WrongAmountOfArguments;
    }
    return args[1];
}
