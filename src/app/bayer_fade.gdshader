shader_type canvas_item;
// Transição das telas (007, animation-agent): cobre a tela com INK em padrão Bayer 4×4 — sem alpha.
uniform float level : hint_range(0.0, 1.0) = 0.0;
uniform vec4 ink : source_color;

const float BAYER[16] = float[](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);

void fragment() {
	ivec2 p = ivec2(floor(FRAGCOORD.xy)) % 4;
	float threshold = (BAYER[p.y * 4 + p.x] + 0.5) / 16.0;
	COLOR = vec4(ink.rgb, level > threshold ? 1.0 : 0.0);
}
