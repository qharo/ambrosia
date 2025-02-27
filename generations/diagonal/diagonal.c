#include <stdio.h>
#include <stdbool.h>
#include <emscripten.h>

// Export the function for JavaScript to call
EMSCRIPTEN_KEEPALIVE
int generate_image(
    unsigned int width,
    unsigned int height,
    unsigned int row_tiles,
    unsigned int col_tiles,
    const char* format,
    char* out_buffer,
    unsigned int buffer_len
) {
    // Unused parameter
    (void)format;
    
    // Cap dimensions to max allowed
    if (width > 3840) width = 3840;
    if (height > 2160) height = 2160;
    
    // Cap tile count based on dimensions (height/20 and width/20) and to avoid buffer overflow
    unsigned int max_row_tiles = height / 20;
    unsigned int max_col_tiles = width / 20;
    
    if (row_tiles > max_row_tiles) row_tiles = max_row_tiles;
    if (col_tiles > max_col_tiles) col_tiles = max_col_tiles;
    
    unsigned int tile_width = width / col_tiles;
    unsigned int tile_height = height / row_tiles;
    
    // Write SVG header (more compact format)
    int offset = snprintf(out_buffer, buffer_len, 
        "<svg width=\"%u\" height=\"%u\" xmlns=\"http://www.w3.org/2000/svg\" style=\"background-color:white\">", 
        width, height);
    
    if (offset < 0 || (unsigned int)offset >= buffer_len) return -1;
    
    // Generate random seed
    unsigned int seed = width * height + row_tiles + col_tiles;
    
    // Generate diagonal lines
    for (unsigned int row = 0; row < row_tiles; row++) {
        for (unsigned int col = 0; col < col_tiles; col++) {
            unsigned int x = col * tile_width;
            unsigned int y = row * tile_height;
            
            // Simple pseudorandom number generation
            seed = seed * 1103515245 + 12345;
            bool left_to_right = ((seed >> 16) & 1) == 1;
            
            // Write line element (more compact format to save space)
            int line_len;
            if (left_to_right) {
                line_len = snprintf(out_buffer + offset, buffer_len - offset,
                    "<line x1=\"%u\" y1=\"%u\" x2=\"%u\" y2=\"%u\" stroke=\"black\" stroke-width=\"2\"/>",
                    x, y, x + tile_width, y + tile_height);
            } else {
                line_len = snprintf(out_buffer + offset, buffer_len - offset,
                    "<line x1=\"%u\" y1=\"%u\" x2=\"%u\" y2=\"%u\" stroke=\"black\" stroke-width=\"2\"/>",
                    x + tile_width, y, x, y + tile_height);
            }
            
            if (line_len < 0 || (unsigned int)(offset + line_len) >= buffer_len) return -1;
            offset += line_len;
        }
    }
    
    // Write SVG footer
    int footer_len = snprintf(out_buffer + offset, buffer_len - offset, "</svg>");
    if (footer_len < 0 || (unsigned int)(offset + footer_len) >= buffer_len) return -1;
    offset += footer_len;
    
    return offset;
}

// Dummy main function to satisfy emcc
int main() {
    return 0;
}