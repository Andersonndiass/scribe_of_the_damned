shader_type canvas_item;
// Flash de acerto (T017): troca a cor dos pixels opacos pela flash_color. Sem mistura parcial,
// para não criar cores fora da paleta (Princípio VII).

uniform vec4 flash_color : source_color = vec4(1.0);
uniform float flash_amount : hint_range(0.0, 1.0) = 0.0;
// VAPOR (002): escriba oculto = xadrez 2×2 de 50%, preso ao pixel do jogo (não cintila). Sem alpha.
uniform float dither_hide : hint_range(0.0, 1.0) = 0.0;
// SPIRITUS (002): metade dos pixels opacos em xadrez 2×2 trocados pela tint_color (CHALK). Sem alpha.
uniform float dither_tint : hint_range(0.0, 1.0) = 0.0;
uniform vec4 tint_color : source_color = vec4(1.0);

varying vec2 world_pos;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
}

void fragment() {
	if (dither_hide > 0.5 && mod(floor(world_pos.x) + floor(world_pos.y), 2.0) < 1.0) {
		discard;
	}
	vec4 tex = texture(TEXTURE, UV) * COLOR;
	if (dither_tint > 0.5 && tex.a > 0.5 && mod(floor(world_pos.x) + floor(world_pos.y), 2.0) < 1.0) {
		tex = vec4(tint_color.rgb, tex.a);
	}
	COLOR = flash_amount > 0.5 ? vec4(flash_color.rgb, tex.a) : tex;
}
