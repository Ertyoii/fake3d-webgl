#include <metal_stdlib>
using namespace metal;

// Uniforms structure (must match Swift Uniforms struct exactly)
struct Uniforms {
    float4 resolution;    // width, height, scaleX, scaleY (16 bytes)
    float2 mouse;         // normalized mouse position (8 bytes)
    float2 threshold;     // horizontal and vertical threshold (8 bytes)
    float time;           // time for animations (4 bytes)
    float pixelRatio;     // device pixel ratio (4 bytes)
    float2 padding;       // padding to align to 16-byte boundary (8 bytes)
};

// Vertex input structure
struct VertexIn {
    float2 position [[attribute(0)]];
};

// Vertex output / Fragment input structure
struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

// Vertex shader
vertex VertexOut vertex_main(VertexIn in [[stage_in]]) {
    VertexOut out;
    out.position = float4(in.position, 0.0, 1.0);
    
    // Convert from clip space (-1 to 1) to texture coordinates (0 to 1)
    // Flip Y coordinate to fix upside-down issue
    out.texCoord = float2((in.position.x + 1.0) * 0.5, 1.0 - (in.position.y + 1.0) * 0.5);
    
    return out;
}

// Optimized helper function for mirrored texture sampling
float2 mirrored(float2 v) {
    float2 m = fmod(v, 2.0);
    // Use select for better performance on GPU
    return select(m, 2.0 - m, m >= 1.0);
}

// Fragment shader
fragment float4 fragment_main(VertexOut in [[stage_in]],
                             constant Uniforms& uniforms [[buffer(0)]],
                             texture2d<float> originalTexture [[texture(0)]],
                             texture2d<float> depthTexture [[texture(1)]]) {
    
    constexpr sampler textureSampler(mag_filter::linear,
                                   min_filter::linear,
                                   address::clamp_to_edge);
    
    // Apply aspect ratio scaling to maintain image proportions
    float2 uv = in.texCoord;
    float2 vUv = (uv - float2(0.5)) * uniforms.resolution.zw + float2(0.5);
    
    // Sample the depth map
    float4 depthSample = depthTexture.sample(textureSampler, mirrored(vUv));
    
    // Calculate fake 3D offset based on depth and mouse position
    float2 fake3d = float2(
        vUv.x + (depthSample.r - 0.5) * uniforms.mouse.x / uniforms.threshold.x,
        vUv.y + (depthSample.r - 0.5) * uniforms.mouse.y / uniforms.threshold.y
    );
    
    // Sample the original texture with the offset
    float4 finalColor = originalTexture.sample(textureSampler, mirrored(fake3d));
    
    return finalColor;
}
