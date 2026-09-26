shader_type canvas_item;
// Flash de acerto (T017): troca a cor dos pixels opacos pela flash_color. Sem mistura parcial,
// para não criar cores fora da paleta (Princípio VII).

uniform vec4 flash_color : source_color = vec4(1.0);
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;

void fragment() {
	vec4 tex = texture(TEXTURE, UV) * COLOR;
	COLOR = flash_amount > 0.5 ? vec4(flash_color.rgb, tex.a) : tex;
}
