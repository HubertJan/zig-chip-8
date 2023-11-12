const std = @import("std");

pub const Register = struct {
    content: u8,
};

pub const ProgramCounter = struct {};

pub const Display = struct {};

pub const Stack = struct { content: [16]u16 };

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
