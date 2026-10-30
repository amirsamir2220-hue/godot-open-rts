// Desert sand ground: two tiling noise lookups in world space (large dune patches + grain)
// and wind ripples. Cheap enough for the Compatibility renderer on integrated GPUs.
shader_type spatial;
render_mode diffuse_lambert, specular_disabled;

uniform vec4 sand_light : source_color = vec4(0.74, 0.66, 0.54, 1.0);
uniform vec4 sand_dark : source_color = vec4(0.6, 0.52, 0.41, 1.0);
uniform vec4 sand_pale : source_color = vec4(0.8, 0.76, 0.67, 1.0);
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

  vec3 color = mix(sand_dark.rgb, sand_light.rgb, smoothstep(0.15, 0.85, large));
  color = mix(color, sand_pale.rgb, smoothstep(0.55, 0.85, medium) * 0.3);
  color *= 0.92 + 0.16 * grain;
  color *= 1.0 - ripple_strength + ripple_strength * ripple;
  ALBEDO = color;
  ROUGHNESS = 1.0;
}
