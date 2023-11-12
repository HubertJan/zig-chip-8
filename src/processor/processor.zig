const std = @import("std");

const Register = struct {
    content: u8,
};

const Stack = struct { content: [16]u16 };

const MemoryAddress = struct { content: [3]u8 };

const Instruction = struct {
    content: [4]u8,

    pub fn build(content: [4]u8) Instruction {
        return Instruction{ .content = content };
    }
};

const Chip8Opcode = enum {
    clearScreen,
    jump,
    subroutine,
    ret,
    skipIfEqual,
    skipIfUnequal,
    skipIfEqualRegisters,
    skipIfUnequalReigsters,
    set,
    add,
    display,
    setIndexRegister,
};

const RegisterAddress = struct {};

const RegisterAndMemoryAddress = struct {
    registerAddress: RegisterAddress,
    memoryAddress: MemoryAddress,
};

const TwoRegisterAddresses = struct {
    oneAddress: RegisterAddress,
    anotherAddress: RegisterAddress,
};

const DisplayOperands = struct {
    pixelsToDraw: u8,
    xPosition: RegisterAddress,
    yPositiom: RegisterAddress,
};

const Chip8Instruction = union(Chip8Opcode) {
    clearScreen: void,
    jump: MemoryAddress,
    subroutine: MemoryAddress,
    ret: void,
    skipIfEqual: RegisterAndMemoryAddress,
    skipIfUnequal: RegisterAndMemoryAddress,
    skipIfEqualRegisters: TwoRegisterAddresses,
    skipIfUnequalReigsters: TwoRegisterAddresses,
    set: RegisterAndMemoryAddress,
    add: TwoRegisterAddresses,
    display: DisplayOperands,
    setIndexRegister: u24,
};

fn encodeInstruction(instruction: Instruction) Chip8Instruction {
    _ = instruction;
}

test "test instructions" {
    const inst = Chip8Instruction.clearScreen;
    _ = inst;
}
