const std = @import("std");

const chip80processor = @import("processor.zig");
const chip80decode = @import("decode.zig");
const Chip8Opcode = chip80processor.Chip8Opcode;
const Chip8Instruction = chip80processor.Chip8Instruction;
const Chip80Processor = chip80processor.Chip80Processor;
const Instruction = chip80processor.Instruction;

fn isBitSet(pixelsToDraw: u8, xOffset: u3) bool {
    return ((pixelsToDraw >> (7 - xOffset)) & 1) == 1;
}

fn drawPixels(processor: *const Chip80Processor, startX: u8, startY: u8, spriteByteAmount: u8) void {
    for (0..spriteByteAmount) |spriteByteIndex| {
        const pixelsToDraw = processor.readIndexedMemory(@intCast(spriteByteIndex));
        const yPixelPos: u8 = startY + @as(u8, @intCast(spriteByteIndex));
        if (yPixelPos >= 32) {
            break;
        }
        for (0..8) |bitIndex| {
            const xPixelPos = startX + @as(u3, @intCast(bitIndex));
            if (xPixelPos >= 64) {
                break;
            }

            // Pixel can only be on or off
            const displayPixelState = processor.display.getPixel(xPixelPos, yPixelPos);
            const spritePixelState = isBitSet(pixelsToDraw, @as(u3, @intCast(bitIndex)));

            if (spritePixelState and displayPixelState) {
                processor.setFlagRegister(true);
                processor.display.drawPixel(xPixelPos, yPixelPos, false);
            } else if (spritePixelState) {
                processor.display.drawPixel(xPixelPos, yPixelPos, true);
            }
        }
    }
}

pub fn executeInstruction(instruction: Chip8Instruction, processor: *Chip80Processor) void {
    switch (instruction) {
        .addToRegister => |data| {
            processor.registers[data.address.content].content += data.value;
        },
        .clearScreen => {
            processor.display.clear();
        },
        .display => |operands| {
            const pixelAmountToDraw = operands.pixelsToDraw;
            const startX = processor.readVariableRegister(operands.xPosition) % 64;
            const startY = processor.readVariableRegister(operands.yPosition) % 32;
            processor.setFlagRegister(false);
            drawPixels(processor, startX, startY, pixelAmountToDraw);
        },
        .jump => |data| {
            processor.programCounter = chip80processor.MemoryAddress{ .content = data.content };
        },
        .set => |data| {
            processor.registers[data.address.content].content = data.value;
        },
        .setIndexRegister => |data| {
            processor.indexRegister = data;
        },
        .skipIfEqual => |data| {
            const is_equal = processor.readMemory(data.memoryAddress) == processor.readVariableRegister(data.registerAddress);
            if (is_equal) {
                processor.programCounter.content += 2;
            }
        },
        .skipIfEqualRegisters => |data| {
            const is_equal = processor.readVariableRegister(data.oneAddress) == processor.readVariableRegister(data.anotherAddress);
            if (is_equal) {
                processor.programCounter.content += 2;
            }
        },
        .skipIfUnequal => |data| {
            const is_equal = processor.readMemory(data.memoryAddress) == processor.readVariableRegister(data.registerAddress);
            if (!is_equal) {
                processor.programCounter.content += 2;
            }
        },
        .skipIfUnequalReigsters => |data| {
            const is_equal = processor.readVariableRegister(data.oneAddress) == processor.readVariableRegister(data.anotherAddress);
            if (!is_equal) {
                processor.programCounter.content += 2;
            }
        },
        .subroutine => |data| {
            processor.stack.content[processor.stack.stackPointer] = processor.programCounter.content;
            processor.stack.stackPointer += 1;
            processor.programCounter.content = data.content;
        },
        .ret => {
            processor.stack.stackPointer -= 1;
            processor.programCounter = chip80processor.MemoryAddress{ .content = @as(u12, @intCast(processor.stack.content[processor.stack.stackPointer])) };
        },
        .setToRegister => {},
    }
}

test "Test addToRegister instruction" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var processor = try Chip80Processor.init(allocator);
    try std.testing.expect(
        processor.programCounter.content == 0,
    );
    const instruction = chip80decode.decodeInstruction(Instruction.build(0x7112));
    try std.testing.expect(instruction != null);
    executeInstruction(
        instruction.?,
        &processor,
    );
    var res = processor.registers[1].content;
    try std.testing.expect(
        res == 0x12,
    );
    executeInstruction(
        instruction.?,
        &processor,
    );
    res = processor.registers[1].content;
    try std.testing.expect(
        res == 0x24,
    );
}

test "Test display instruction" {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    var processor = try Chip80Processor.init(allocator);
    processor.display.debugPrint();
    const indexInstruction = chip80decode.decodeInstruction(Instruction.build(0xA000));
    executeInstruction(indexInstruction.?, &processor);

    std.debug.print("\n", .{});
    const displayInstruction = chip80decode.decodeInstruction(Instruction.build(0xD002));
    executeInstruction(displayInstruction.?, &processor);
    processor.display.debugPrint();
}
