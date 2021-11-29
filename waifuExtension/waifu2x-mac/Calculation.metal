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
constant int fullLength [[function_constant(4)]];

/// This is a Metal Shading Language (MSL) function
kernel void Calculation(device const float* expanded,
                        device const int* xArray,
                        device const int* yArray,
                        device float* multi,
                        uint3 index [[thread_position_in_grid]]) {
    // the for-loop is replaced with a collection of threads, each of which calls this function.
    
    int x = xArray[index.z];
    int y = yArray[index.z];
    
    int x_exp = index.x + x;
    int y_exp = index.y + y;
    
    int x_new = x_exp - x;
    int y_new = y_exp - y;
    
    multi[y_new * (block_size + 2 * shrink_size) + x_new + fullLength * index.z] = expanded[y_exp * expwidth + x_exp];
    multi[y_new * (block_size + 2 * shrink_size) + x_new + (block_size + 2 * shrink_size) * (block_size + 2 * shrink_size) + fullLength * index.z] = expanded[y_exp * expwidth + x_exp + expwidth * expheight];
    multi[y_new * (block_size + 2 * shrink_size) + x_new + (block_size + 2 * shrink_size) * (block_size + 2 * shrink_size) * 2 + fullLength * index.z] = expanded[y_exp * expwidth + x_exp + expwidth * expheight * 2];
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
