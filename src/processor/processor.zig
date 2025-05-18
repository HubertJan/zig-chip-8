const std = @import("std");
const Decode = @import("decode.zig");
const Execute = @import("execute.zig");
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;

pub const VariableRegister = struct {
    content: u8,
    pub fn init() VariableRegister {
        return VariableRegister{ .content = 0 };
    }
};

pub const Display = struct {
    content: []bool,
    pub fn init(allocator: Allocator) !Display {
        const content = try allocator.alloc(bool, 64 * 32);

        return Display{
            .content = content,
        };
    }

    pub fn clear(self: Display) void {
        for (0..64 * 32) |i| {
            self.content[i] = false;
        }
    }

    pub fn drawPixel(self: Display, x: u8, y: u8, value: bool) void {
        const index: usize = @as(usize, x) + @as(usize, y) * 64;
        self.content[index] = value;
    }

    pub fn getPixel(self: Display, x: u8, y: u8) bool {
        const index: usize = @as(usize, x) + @as(usize, y) * 64;
        return self.content[index];
    }

    pub fn debugPrintPixels(self: Display, y: u8) void {
        std.debug.print("\nMonitor:\n", .{});
        for (0..8) |x| {
            const xS: u8 = @intCast(x);
            std.debug.print("{}\n", .{self.getPixel(xS, y)});
        }
    }

    pub fn debugPrint(self: Display) void {
        std.debug.print("\nMonitor:\n", .{});
        for (0..32) |y| {
            var row = [_]u8{' '} ** 64;
            for (0..64) |x| {
                const xS: u8 = @intCast(x);
                const yS: u8 = @intCast(y);
                row[xS] = if (self.getPixel(xS, yS)) '1' else '0';
            }
            std.debug.print("{s}\n", .{row});
        }
    }
};

pub const Stack = struct {
    content: [16]u16,
    stackPointer: u4,

    pub fn init() Stack {
        return Stack{ .content = [_]u16{0} ** 16, .stackPointer = 0 };
    }
};

pub const MemoryAddress = struct { content: u12 };

pub const Instruction = struct {
    content: u16,

    pub fn build(content: u16) Instruction {
        return Instruction{ .content = content };
    }
};

pub const Chip8Opcode = enum {
    clearScreen,
    jump,
    subroutine,
    ret,
    skipIfEqual,
    skipIfUnequal,
    skipIfEqualRegisters,
    skipIfUnequalRegisters,
    set,
    setToRegister,
    addToRegister,
    display,
    setIndexRegister,
    binaryOr,
    binaryAnd,
    binaryXor,
    add,
    subtract,
    reversedSubtract,
};

pub const RegisterAddress = struct {
    content: u4,
};

pub const RegisterAndMemoryAddress = struct {
    registerAddress: RegisterAddress,
    memoryAddress: MemoryAddress,
};

pub const TwoRegisterAddresses = struct {
    oneAddress: RegisterAddress,
    anotherAddress: RegisterAddress,
};

pub const DisplayOperands = struct {
    pixelsToDraw: u8,
    xPosition: RegisterAddress,
    yPosition: RegisterAddress,
};

pub const RegisterAndValue = struct {
    address: RegisterAddress,
    value: u8,
};

pub const Chip8Instruction = union(Chip8Opcode) {
    clearScreen: void,
    jump: MemoryAddress,
    subroutine: MemoryAddress,
    ret: void,
    skipIfEqual: RegisterAndMemoryAddress,
    skipIfUnequal: RegisterAndMemoryAddress,
    skipIfEqualRegisters: TwoRegisterAddresses,
    skipIfUnequalRegisters: TwoRegisterAddresses,
    set: RegisterAndValue,
    setToRegister: TwoRegisterAddresses,
    addToRegister: RegisterAndValue,
    display: DisplayOperands,
    setIndexRegister: u12,

    binaryOr: TwoRegisterAddresses,
    binaryAnd: TwoRegisterAddresses,
    binaryXor: TwoRegisterAddresses,
    add: TwoRegisterAddresses,
    subtract: TwoRegisterAddresses,
    reversedSubtract: TwoRegisterAddresses,
};

pub const Chip80Processor = struct {
    registers: []VariableRegister,
    indexRegister: u16,
    memory: []u8,
    keyPadKeys: []u8,
    stack: Stack,
    programCounter: MemoryAddress,
    display: Display,
    allocator: Allocator,

    pub fn init(allocator: Allocator) !Chip80Processor {
        const registers = try allocator.alloc(VariableRegister, 16);
        for (0..16) |i| {
            registers[i] = VariableRegister.init();
        }
        const memory = try allocator.alloc(u8, 4096);
        for (0..4096) |i| {
            memory[i] = 0;
        }
        const keyPadKeys = try allocator.alloc(u8, 16);
        for (0..16) |i| {
            keyPadKeys[i] = 0;
        }
        memory[0] = 0xFF;
        memory[1] = 0xF0;
        return Chip80Processor{
            .registers = registers,
            .stack = Stack.init(),
            .programCounter = MemoryAddress{ .content = 512 },
            .display = try Display.init(allocator),
            .memory = memory,
            .indexRegister = 0,
            .allocator = allocator,
            .keyPadKeys = keyPadKeys,
        };
    }
    pub fn deinit(self: Chip80Processor) void {
        const allocator = self.allocator;
        allocator.free(self.registers);
        allocator.free(self.memory);
    }

    pub fn loadProgram(self: Chip80Processor, program: []u8) void {
        for (0..program.len) |i| {
            self.memory[i + 512] = program[i];
        }
    }

    pub fn readIndexedMemory(self: Chip80Processor, offset: u16) u8 {
        assert(self.indexRegister + offset < 4096);
        return self.memory[self.indexRegister + offset];
    }

    pub fn readVariableRegister(self: Chip80Processor, address: RegisterAddress) u8 {
        return self.registers[address.content].content;
    }

    pub fn readMemory(self: Chip80Processor, address: MemoryAddress) u8 {
        return self.memory[address.content];
    }

    pub fn readStack(self: Chip80Processor) u16 {
        return self.stack.content[self.stack.stackPointer];
    }
    pub fn setFlagRegister(self: Chip80Processor, value: bool) void {
        _ = value;
        const v = if (true) 1 else 0;
        self.registers[0xF].content = v;
    }

    pub fn cycle(self: *Chip80Processor) void {
        const instructionAddress = self.programCounter;
        const firstHalfinstruction = @as(u16, self.readMemory(instructionAddress)) << 8;
        const secondHalfinstruction = @as(u16, self.readMemory(MemoryAddress{ .content = instructionAddress.content + 1 }));
        const instruction = Instruction{ .content = firstHalfinstruction + secondHalfinstruction };
        const opcode = Decode.decodeInstruction(instruction);
        self.programCounter = MemoryAddress{ .content = instructionAddress.content + 2 };
        Execute.executeInstruction(opcode.?, self);
    }
};
