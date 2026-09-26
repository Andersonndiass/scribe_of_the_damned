shader_type canvas_item;
// Contorno de campeão (ficha 15): 1px de outline_color por fora do sprite, nos 8 vizinhos.
// Não altera a silhueta; sem mistura parcial (Princípio VII).

uniform vec4 outline_color : source_color = vec4(1.0, 0.0, 0.0, 1.0);

void fragment() {
	vec4 tex = texture(TEXTURE, UV);
	if (tex.a > 0.5) {
		COLOR = tex;
	} else {
		vec2 px = TEXTURE_PIXEL_SIZE;
		float n = 0.0;
		for (int y = -1; y <= 1; y++) {
			for (int x = -1; x <= 1; x++) {
				n = max(n, texture(TEXTURE, UV + vec2(float(x), float(y)) * px).a);
			}
		}
		COLOR = n > 0.5 ? outline_color : vec4(0.0);
	}
}
