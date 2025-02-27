const std = @import("std");

// Export the function to WebAssembly with a simple C-style ABI
export fn generate_image(
    width: u32,
    height: u32,
    row_tiles: u32,
    col_tiles: u32,
    format: [*]const u8, // Pointer to a null-terminated string
    out_buffer: [*]u8, // Output buffer to write the SVG string
    buffer_len: u32, // Length of the output buffer
) i32 {
    _ = format; // Unused, included for compatibility with the original API

    // Calculate tile dimensions
    const tile_width = width / col_tiles;
    const tile_height = height / row_tiles;

    // SVG header
    const svg_header = std.fmt.bufPrint(out_buffer[0..buffer_len], "<svg width=\"{}\" height=\"{}\" xmlns=\"http://www.w3.org/2000/svg\" style=\"background-color: white;\">", .{ width, height }) catch return -1; // Return -1 on buffer overflow or error
    var offset: usize = svg_header.len;

    // Simple PRNG for randomness (linear congruential generator)
    var seed: u32 = width * height + row_tiles + col_tiles; // Simplified seed calculation
    seed = seed * 1103515245 + 12345; // Common LCG parameters

    // Generate lines for each tile
    for (0..row_tiles) |row| {
        for (0..col_tiles) |col| {
            const x = col * tile_width;
            const y = row * tile_height;

            // Randomly decide line direction (true = left-to-right, false = right-to-left)
            seed = seed * 1103515245 + 12345;
            const left_to_right = (seed >> 16) & 1 == 1;

            const line = if (left_to_right)
                std.fmt.bufPrint(out_buffer[offset..buffer_len], "<line x1=\"{}\" y1=\"{}\" x2=\"{}\" y2=\"{}\" stroke=\"black\" stroke-width=\"2\"/>", .{ x, y, x + tile_width, y + tile_height })
            else
                std.fmt.bufPrint(out_buffer[offset..buffer_len], "<line x1=\"{}\" y1=\"{}\" x2=\"{}\" y2=\"{}\" stroke=\"black\" stroke-width=\"2\"/>", .{ x + tile_width, y, x, y + tile_height });

            const line_str = line catch return -1; // Return -1 on buffer overflow
            offset += line_str.len;
        }
    }

    // SVG footer
    const footer = std.fmt.bufPrint(out_buffer[offset..buffer_len], "</svg>", .{}) catch return -1;
    offset += footer.len;

    // Return the length of the generated string
    return @intCast(offset);
}

// Export memory for WebAssembly (modern Zig style)
pub export const __wasm_memory: [*]u8 linksection(".export") = undefined;

// Minimal allocator stub (not used, but required by some WASM runtimes)
pub export fn __wasm_allocate(size: usize) ?[*]u8 {
    _ = size;
    return null; // No dynamic allocation in this code
}
