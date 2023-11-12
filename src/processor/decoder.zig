const std = @import("std");

const processor = @import("processor.zig");
const Instruction = processor.Instruction;
const Chip8Instruction = processor.Chip8Instruction;
const Chip8Opcode = processor.Chip8Opcode;
const MemoryAddress = processor.MemoryAddress;

const decoder_op = *const (fn (instruction: processor.Instruction) ?Chip8Instruction);

fn checkByOpcodeMask(
    instruction: Instruction,
    opcode_nulled: u16,
    opcode_mask: u16,
) bool {
    const filtered = instruction.content & opcode_mask;
    return filtered == opcode_nulled;
}

fn decodeClearScreen(instruction: Instruction) ?Chip8Instruction {
    if (checkByOpcodeMask(
        instruction,
        0x00E0,
        0xFFFF,
    )) {
        return Chip8Opcode.clearScreen;
    }
    return null;
}

test "test decode ClearScreen" {
    const clearScreenInstruction = Instruction.build(0x00E0);
    const result = decodeInstruction(clearScreenInstruction);
    const instruction = result.?;
    try std.testing.expect(
        @as(Chip8Opcode, instruction) == Chip8Opcode.clearScreen,
    );
}

fn decodeJump(instruction: Instruction) ?Chip8Instruction {
    if (!checkByOpcodeMask(
        instruction,
        0x1000,
        0xF000,
    )) {
        return null;
    }
    const address = @as(
        u12,
        @truncate(
            instruction.content,
        ),
    );
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

fn decodeSet(instruction: Instruction) ?Chip8Instruction {
    if (!checkByOpcodeMask(
        instruction,
        0x6000,
        0xF000,
    )) {
        return null;
    }
    const registerAddressNum = @as(
        u4,
        @truncate(
            instruction.content >> 8,
        ),
    );
    const value = @as(
        u8,
        @truncate(
            instruction.content,
        ),
    );
    return Chip8Instruction{ .set = processor.RegisterAndValue{
        .address = processor.RegisterAddress{
            .content = registerAddressNum,
        },
        .value = value,
    } };
}

fn decodeAddToRegister(instruction: Instruction) ?Chip8Instruction {
    if (!checkByOpcodeMask(
        instruction,
        0x7000,
        0xF000,
    )) {
        return null;
    }
    const registerAddressNum = @as(
        u4,
        @truncate(
            instruction.content >> 8,
        ),
    );
    const value = @as(
        u8,
        @truncate(
            instruction.content,
        ),
    );
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

fn decodeSetIndexRegister(instruction: Instruction) ?Chip8Instruction {
    if (!checkByOpcodeMask(
        instruction,
        0xA000,
        0xF000,
    )) {
        return null;
    }
    const value = @as(
        u12,
        @truncate(
            instruction.content,
        ),
    );
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

fn decodeDisplay(instruction: Instruction) ?Chip8Instruction {
    if (!checkByOpcodeMask(
        instruction,
        0xD000,
        0xF000,
    )) {
        return null;
    }

    const registerAddressX = @as(
        u4,
        @truncate(
            instruction.content >> 8,
        ),
    );

    const registerAddressY = @as(
        u4,
        @truncate(
            instruction.content >> 4,
        ),
    );
    const pixelsToDraw = @as(
        u4,
        @truncate(
            instruction.content,
        ),
    );
    return Chip8Instruction{ .display = processor.DisplayOperands{
        .pixelsToDraw = pixelsToDraw,
        .xPosition = processor.RegisterAddress{ .content = registerAddressX },
        .yPosition = processor.RegisterAddress{ .content = registerAddressY },
    } };
}

test "test decode display" {
    const clearScreenInstruction = Instruction.build(0xD123);
    const result = decodeInstruction(clearScreenInstruction);
    const instruction = result.?;
    try std.testing.expect(
        instruction.display.xPosition.content == 0x1 and
            instruction.display.yPosition.content == 0x2 and
            instruction.display.pixelsToDraw == 0x3,
    );
}

const decoderFunctions = [_]decoder_op{
    decodeClearScreen,
    decodeJump,
    decodeSet,
    decodeAddToRegister,
    decodeSetIndexRegister,
    decodeDisplay,
};

fn decodeInstruction(instruction: Instruction) ?Chip8Instruction {
    for (decoderFunctions) |decode| {
        const result = decode(instruction);
        if (result != null) {
            return result.?;
        }
    }

    return null;
}
