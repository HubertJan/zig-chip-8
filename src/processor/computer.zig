const std = @import("std");

const processor = @import("processor.zig");

const ZigProcessor = struct {
    registers: [16]processor.Register,
    stack: processor.Stack,
    programCounter: processor.ProgramCounter,
    display: processor.Display,
};
