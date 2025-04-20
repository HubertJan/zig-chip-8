default: 
    just --list

# Build Zig Chip 8 and run the binary with passed in arguments
[positional-arguments]
run args:
    @zig build
    @zig-out/bin/zig-chip-8 "$@"