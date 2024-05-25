const std = @import("std");
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;

pub const VariableRegister = struct {
    content: u8,
    pub fn init() VariableRegister {
        return VariableRegister{ .content = 0 };
    }
};

pub const ProgramCounter = struct {
    content: u16,
    pub fn init() ProgramCounter {
        return ProgramCounter{ .content = 0 };
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
        self.content[x + y * 64] = value;
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
    skipIfUnequalReigsters,
    set,
    addToRegister,
    display,
    setIndexRegister,
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
    skipIfUnequalReigsters: TwoRegisterAddresses,
    set: RegisterAndValue,
    addToRegister: RegisterAndValue,
    display: DisplayOperands,
    setIndexRegister: u12,
};

pub const Chip80Processor = struct {
    registers: []VariableRegister,
    indexRegister: u16,
    memory: []u8,
    stack: Stack,
    programCounter: ProgramCounter,
    display: Display,

    pub fn init(allocator: Allocator) !Chip80Processor {
        const registers = try allocator.alloc(VariableRegister, 16);
        for (0..16) |i| {
            registers[i] = VariableRegister.init();
        }
        const memory = try allocator.alloc(u8, 4096);
        for (0..4096) |i| {
            memory[i] = 0;
        }
        memory[0] = 0xFF;
        memory[1] = 0xF0;
        return Chip80Processor{
            .registers = registers,
            .stack = Stack.init(),
            .programCounter = ProgramCounter.init(),
            .display = try Display.init(allocator),
            .memory = memory,
            .indexRegister = 0,
        };
    }
    fn deinit(self: Chip80Processor) void {
        const allocator = self.allocator;
        allocator.free(self.registers);
        allocator.free(self.memory);
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
};
