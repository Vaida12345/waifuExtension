//
//  Calculation.metal
//  waifuExtension
//
//  Created by Vaida on 11/28/21.
//

#include <metal_stdlib>
using namespace metal;

constant int block_size [[function_constant(0)]];
constant int shrink_size [[function_constant(1)]];
constant int expwidth [[function_constant(2)]];
constant int expheight [[function_constant(3)]];
constant int x [[function_constant(4)]];
constant int y [[function_constant(5)]];

/// This is a Metal Shading Language (MSL) function equivalent to the add_arrays() C function, used to perform the calculation on a GPU.
kernel void Calculation(device const float* expanded,
                       device float* multi,
                       uint2 index [[thread_position_in_grid]]) {
    // the for-loop is replaced with a collection of threads, each of which
    // calls this function.
    
    int x_exp = index.x + x;
    int y_exp = index.y + y;
    
    if (x_exp * y_exp > 3 * (block_size + 2 * shrink_size) * (block_size + 2 * shrink_size)) {
        return;
    }
    
    int x_new = x_exp - x;
    int y_new = y_exp - y;
    
    multi[y_new * (block_size + 2 * shrink_size) + x_new] = expanded[y_exp * expwidth + x_exp];
    multi[y_new * (block_size + 2 * shrink_size) + x_new + (block_size + 2 * shrink_size) * (block_size + 2 * shrink_size)] = expanded[y_exp * expwidth + x_exp + expwidth * expheight];
    multi[y_new * (block_size + 2 * shrink_size) + x_new + (block_size + 2 * shrink_size) * (block_size + 2 * shrink_size) * 2] = expanded[y_exp * expwidth + x_exp + expwidth * expheight * 2];
}

//var y_exp = y
//
//while y_exp < (y + self.block_size + 2 * self.shrink_size) {
//
//    var x_exp = x
//    while x_exp < (x + self.block_size + 2 * self.shrink_size) {
//        let x_new = x_exp - x
//        let y_new = y_exp - y
//        multi[y_new * (self.block_size + 2 * self.shrink_size) + x_new] = NSNumber(value: expanded[y_exp * expwidth + x_exp])
//        multi[y_new * (self.block_size + 2 * self.shrink_size) + x_new + (self.block_size + 2 * self.shrink_size) * (self.self.block_size + 2 * self.shrink_size)] = NSNumber(value: expanded[y_exp * expwidth + x_exp + expwidth * expheight])
//        multi[y_new * (self.block_size + 2 * self.shrink_size) + x_new + (self.block_size + 2 * self.shrink_size) * (self.block_size + 2 * self.shrink_size) * 2] = NSNumber(value: expanded[y_exp * expwidth + x_exp + expwidth * expheight * 2])
//
//        x_exp += 1
//    }
//
//    y_exp += 1
//}
