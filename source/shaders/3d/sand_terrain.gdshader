// Desert sand ground: two tiling noise lookups in world space (large dune patches + grain)
// and wind ripples. Cheap enough for the Compatibility renderer on integrated GPUs.
shader_type spatial;
render_mode diffuse_lambert, specular_disabled;

uniform vec4 sand_light : source_color = vec4(0.74, 0.66, 0.54, 1.0);
uniform vec4 sand_dark : source_color = vec4(0.6, 0.52, 0.41, 1.0);
uniform vec4 sand_pale : source_color = vec4(0.8, 0.76, 0.67, 1.0);
uniform vec4 pebble_color : source_color = vec4(0.47, 0.39, 0.3, 1.0);
uniform sampler2D large_noise : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D small_noise : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float large_scale = 0.025;
uniform float small_scale = 0.45;
uniform vec2 wind_direction = vec2(0.8, 0.6);
uniform float ripple_frequency = 5.0;
uniform float ripple_strength = 0.05;

varying vec3 world_position;

void vertex()
{
  world_position = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment()
{
  vec2 p = world_position.xz;
  float large = texture(large_noise, p * large_scale).r;
  float medium = texture(large_noise, p * large_scale * 3.7 + vec2(0.37, 0.71)).r;
  float grain = texture(small_noise, p * small_scale).r;
  float ripple =
      sin(dot(p, normalize(wind_direction)) * ripple_frequency + large * 14.0) * 0.5 + 0.5;

  float fine = texture(small_noise, p * small_scale * 3.1 + vec2(0.13, 0.57)).r;
  float pebbles = smoothstep(0.72, 0.8, texture(small_noise, p * small_scale * 1.9).r);

  // gentle large-scale variation (no strong blotches), pale wind-swept patches
  vec3 color = mix(sand_dark.rgb, sand_light.rgb, 0.3 + 0.55 * smoothstep(0.2, 0.8, large));
  color = mix(color, sand_pale.rgb, smoothstep(0.55, 0.85, medium) * 0.3);
  // grain at two scales and scattered darker pebbles
  color *= 0.9 + 0.12 * grain + 0.08 * fine;
  color = mix(color, pebble_color.rgb, pebbles * 0.45);
  color *= 1.0 - ripple_strength + ripple_strength * ripple;
  ALBEDO = color;
  ROUGHNESS = 1.0;
}
