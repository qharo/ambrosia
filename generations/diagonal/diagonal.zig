const std = @import("std");

// Define and export memory with a unique name
export const wasm_memory: [65536]u8 = undefined; // Renamed from 'memory'

// Export the generate_image function
export fn generate_image(
    width: u32,
    height: u32,
    row_tiles: u32,
    col_tiles: u32,
    format: [*]const u8,
    out_buffer: [*]u8,
    buffer_len: u32,
) i32 {
    _ = format;

    const tile_width = width / col_tiles;
    const tile_height = height / row_tiles;

    const svg_header = std.fmt.bufPrint(out_buffer[0..buffer_len], "<svg width=\"{}\" height=\"{}\" xmlns=\"http://www.w3.org/2000/svg\" style=\"background-color: white;\">", .{ width, height }) catch return -1;
    var offset: usize = svg_header.len;

    var seed: u32 = width * height + row_tiles + col_tiles;
    seed = seed * 1103515245 + 12345;

    for (0..row_tiles) |row| {
        for (0..col_tiles) |col| {
            const x = col * tile_width;
            const y = row * tile_height;

            seed = seed * 1103515245 + 12345;
            const left_to_right = (seed >> 16) & 1 == 1;

            const line = if (left_to_right)
                std.fmt.bufPrint(out_buffer[offset..buffer_len], "<line x1=\"{}\" y1=\"{}\" x2=\"{}\" y2=\"{}\" stroke=\"black\" stroke-width=\"2\"/>", .{ x, y, x + tile_width, y + tile_height })
            else
                std.fmt.bufPrint(out_buffer[offset..buffer_len], "<line x1=\"{}\" y1=\"{}\" x2=\"{}\" y2=\"{}\" stroke=\"black\" stroke-width=\"2\"/>", .{ x + tile_width, y, x, y + tile_height });

            const line_str = line catch return -1;
            offset += line_str.len;
        }
    }

    const footer = std.fmt.bufPrint(out_buffer[offset..buffer_len], "</svg>", .{}) catch return -1;
    offset += footer.len;

    return @intCast(offset);
}
