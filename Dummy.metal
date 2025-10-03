//
//  Dummy.metal
//  ePleadingsMVP
//
//  Created by Peter Milligan on 03/10/2025.
//

#include <metal_stdlib>
using namespace metal;

kernel void dummyShader(uint2 gid [[thread_position_in_grid]]) { }

