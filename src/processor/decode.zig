const std = @import("std");

const processor = @import("processor.zig");
const Instruction = processor.Instruction;
const Chip8Instruction = processor.Chip8Instruction;
const Chip8Opcode = processor.Chip8Opcode;
const MemoryAddress = processor.MemoryAddress;

const decoder_op = *const (fn (instruction: processor.Instruction) ?Chip8Instruction);

pub fn decodeInstruction(instruction: Instruction) ?Chip8Instruction {
    for (decodeIfFunctions) |decodeIfMatches| {
        const result = decodeIfMatches(instruction);
        if (result != null) {
            return result.?;
        }
    }

    return null;
}

const decodeIfFunctions = [_]decoder_op{
    decodeIfClearScreen,
    decodeIfJump,
    decodeIfSetRegisterRegister,
    decodeIfSetRegisterToValue,
    decodeIfAddToRegister,
    decodeIfSetIndexRegister,
    decodeIfDisplay,
};

fn decodeIfBinaryOr(instruction: Instruction) ?Chip8Instruction {
    if (!checkByOpcodeMask(
        instruction,
        0x8001,
        0xF00F,
    )) {
        return null;
    }
    const registerAddressNum = decodeFirstRegisterNumber(instruction);
    const otherRegisterAddressNum = decodeSecondRegisterNumber(
        instruction,
    );
    return Chip8Instruction{ .binaryOr = processor.TwoRegisterAddresses{
        .oneAddress = processor.RegisterAddress{
            .content = registerAddressNum,
        },
        .anotherAddress = processor.RegisterAddress{
            .content = otherRegisterAddressNum,
        },
    } };
}

fn decodeIfBinaryAnd(instruction: Instruction) ?Chip8Instruction {
    if (!checkByOpcodeMask(
        instruction,
        0x8001,
        0xF00F,
    )) {
        return null;
    }
    const registerAddressNum = decodeFirstRegisterNumber(instruction);
    const otherRegisterAddressNum = decodeSecondRegisterNumber(
        instruction,
    );
    return Chip8Instruction{ .binaryAnd = processor.TwoRegisterAddresses{
        .oneAddress = processor.RegisterAddress{
            .content = registerAddressNum,
        },
        .anotherAddress = processor.RegisterAddress{
            .content = otherRegisterAddressNum,
        },
    } };
}

fn decodeIfBinaryXor(instruction: Instruction) ?Chip8Instruction {
    if (!checkByOpcodeMask(
        instruction,
        0x8003,
        0xF00F,
    )) {
        return null;
    }
    const registerAddressNum = decodeFirstRegisterNumber(instruction);
    const otherRegisterAddressNum = decodeSecondRegisterNumber(
        instruction,
    );
    return Chip8Instruction{ .binaryXor = processor.TwoRegisterAddresses{
        .oneAddress = processor.RegisterAddress{
            .content = registerAddressNum,
        },
        .anotherAddress = processor.RegisterAddress{
            .content = otherRegisterAddressNum,
        },
    } };
}

fn decodeIfAdd(instruction: Instruction) ?Chip8Instruction {
    if (!checkByOpcodeMask(
        instruction,
        0x8004,
        0xF00F,
    )) {
        return null;
    }
    const registerAddressNum = decodeFirstRegisterNumber(instruction);
    const otherRegisterAddressNum = decodeSecondRegisterNumber(
        instruction,
    );
    return Chip8Instruction{ .add = processor.TwoRegisterAddresses{
        .oneAddress = processor.RegisterAddress{
            .content = registerAddressNum,
        },
        .anotherAddress = processor.RegisterAddress{
            .content = otherRegisterAddressNum,
        },
    } };
}

fn decodeIfSubtract(instruction: Instruction) ?Chip8Instruction {
    if (!checkByOpcodeMask(
        instruction,
        0x8005,
        0xF00F,
    )) {
        return null;
    }
    const registerAddressNum = decodeFirstRegisterNumber(instruction);
    const otherRegisterAddressNum = decodeSecondRegisterNumber(
        instruction,
    );
    return Chip8Instruction{ .subtract = processor.TwoRegisterAddresses{
        .oneAddress = processor.RegisterAddress{
            .content = registerAddressNum,
        },
        .anotherAddress = processor.RegisterAddress{
            .content = otherRegisterAddressNum,
        },
    } };
}

fn decodeIfReversedSubtract(instruction: Instruction) ?Chip8Instruction {
    if (!checkByOpcodeMask(
        instruction,
        0x8007,
        0xF00F,
    )) {
        return null;
    }
    const registerAddressNum = decodeFirstRegisterNumber(instruction);
    const otherRegisterAddressNum = decodeSecondRegisterNumber(
        instruction,
    );
    return Chip8Instruction{ .reversedSubtract = processor.TwoRegisterAddresses{
        .oneAddress = processor.RegisterAddress{
            .content = registerAddressNum,
        },
        .anotherAddress = processor.RegisterAddress{
            .content = otherRegisterAddressNum,
        },
    } };
}

fn decodeIfClearScreen(instruction: Instruction) ?Chip8Instruction {
    if (!checkByOpcodeMask(
        instruction,
        0x00E0,
        0xFFFF,
    )) {
        return null;
    }

    return Chip8Opcode.clearScreen;
}

test "test decode ClearScreen" {
    const clearScreenInstruction = Instruction.build(0x00E0);
    const result = decodeInstruction(clearScreenInstruction);
    const instruction = result.?;
    try std.testing.expect(
        @as(Chip8Opcode, instruction) == Chip8Opcode.clearScreen,
    );
}

fn decodeIfJump(instruction: Instruction) ?Chip8Instruction {
    if (!checkByOpcodeMask(
        instruction,
        0x1000,
        0xF000,
    )) {
        return null;
    }
    const address = decode12BitValue(instruction);
    return Chip8Instruction{ .jump = MemoryAddress{
        .content = address,
    } };
}

test "test decode Jump" {
    const clearScreenInstruction = Instruction.build(0x1123);
    const result = decodeInstruction(clearScreenInstruction);
    const instruction = result.?;
    try std.testing.expect(
        instruction.jump.content == 0x123,
    );
}

fn decodeIfSetRegisterToValue(instruction: Instruction) ?Chip8Instruction {
    if (!checkByOpcodeMask(
        instruction,
        0x6000,
        0xF000,
    )) {
        return null;
    }
    const registerAddressNum = decodeFirstRegisterNumber(instruction);
    const value = decode8BitValue(instruction);
    return Chip8Instruction{ .set = processor.RegisterAndValue{
        .address = processor.RegisterAddress{
            .content = registerAddressNum,
        },
        .value = value,
    } };
}

fn decodeIfAddToRegister(instruction: Instruction) ?Chip8Instruction {
    if (!checkByOpcodeMask(
        instruction,
        0x7000,
        0xF000,
    )) {
        return null;
    }
    const registerAddressNum = decodeFirstRegisterNumber(instruction);
    const value = decode8BitValue(instruction);

    return Chip8Instruction{ .addToRegister = processor.RegisterAndValue{
        .address = processor.RegisterAddress{
            .content = registerAddressNum,
        },
        .value = value,
    } };
}

test "test decode AddToRegister" {
    const clearScreenInstruction = Instruction.build(0x7112);
    const result = decodeInstruction(clearScreenInstruction);
    const instruction = result.?;
    try std.testing.expect(
        instruction.addToRegister.address.content == 0x1 and
            instruction.addToRegister.value == 0x12,
    );
}

fn decodeIfSetIndexRegister(instruction: Instruction) ?Chip8Instruction {
    if (!checkByOpcodeMask(
        instruction,
        0xA000,
        0xF000,
    )) {
        return null;
    }
    const value = decode12BitValue(instruction);
    return Chip8Instruction{ .setIndexRegister = value };
}

test "test decode SetIndexRegister" {
    const clearScreenInstruction = Instruction.build(0xA123);
    const result = decodeInstruction(clearScreenInstruction);
    const instruction = result.?;
    try std.testing.expect(
        instruction.setIndexRegister == 0x123,
    );
}

fn decodeIfDisplay(instruction: Instruction) ?Chip8Instruction {
    if (!checkByOpcodeMask(
        instruction,
        0xD000,
        0xF000,
    )) {
        return null;
    }

    const registerAddressX = decodeFirstRegisterNumber(instruction);
    const registerAddressY = decodeSecondRegisterNumber(instruction);
    const pixelsToDraw = decode4BitValue(instruction);

    return Chip8Instruction{ .display = processor.DisplayOperands{
        .pixelsToDraw = pixelsToDraw,
        .xPosition = processor.RegisterAddress{ .content = registerAddressX },
        .yPosition = processor.RegisterAddress{ .content = registerAddressY },
    } };
}

test "decode display" {
    const clearScreenInstruction = Instruction.build(0xD123);
    const result = decodeInstruction(clearScreenInstruction);
    const instruction = result.?;
    try std.testing.expect(
        instruction.display.xPosition.content == 0x1 and
            instruction.display.yPosition.content == 0x2 and
            instruction.display.pixelsToDraw == 0x3,
    );
}

fn decodeIfSetRegisterRegister(instruction: Instruction) ?Chip8Instruction {
    if (!checkByOpcodeMask(
        instruction,
        0x8000,
        0xF00F,
    )) {
        return null;
    }
    const registerAddressNum = decodeFirstRegisterNumber(instruction);
    const otherRegisterAddressNum = decodeSecondRegisterNumber(instruction);
    return Chip8Instruction{ .setToRegister = processor.TwoRegisterAddresses{
        .oneAddress = processor.RegisterAddress{
            .content = registerAddressNum,
        },
        .anotherAddress = processor.RegisterAddress{
            .content = otherRegisterAddressNum,
        },
    } };
}

fn checkByOpcodeMask(
    instruction: Instruction,
    opcode_nulled: u16,
    opcode_mask: u16,
) bool {
    const filtered = instruction.content & opcode_mask;
    return filtered == opcode_nulled;
}

fn decodeFirstRegisterNumber(instruction: Instruction) u4 {
    return @as(
        u4,
        @truncate(
            instruction.content >> 8,
        ),
    );
}

fn decodeSecondRegisterNumber(instruction: Instruction) u4 {
    return @as(
        u4,
        @truncate(
            instruction.content >> 4,
        ),
    );
}

fn decode12BitValue(instruction: Instruction) u12 {
    return @as(
        u12,
        @truncate(
            instruction.content,
        ),
    );
}

fn decode8BitValue(instruction: Instruction) u8 {
    return @as(
        u8,
        @truncate(
            instruction.content,
        ),
    );
}

fn decode4BitValue(instruction: Instruction) u4 {
    return @as(
        u4,
        @truncate(
            instruction.content,
        ),
    );
}
