shader_type canvas_item;
// Revelação do estágio novo em degraus (004 T422; animation-agent T420): dissolve ordenado em
// blocos de 2×2 px, Bayer 2×2 numa célula de 4×4, a página inteira ao mesmo tempo.
// Ordem dos blocos: (0,0) → (1,1) → (1,0) → (0,1). `level` 0..4 = quantos já apareceram.
// O texel vem do UV (nunca FRAGCOORD: a janela é escalada e a grade sairia do pixel da arte).

uniform int level = 4;
uniform vec2 size = vec2(640.0, 360.0);

void fragment() {
	vec2 texel = floor(UV * size);
	ivec2 b = ivec2(mod(floor(texel / 2.0), 2.0));
	int order = 3;
	if (b.x == 0 && b.y == 0) {
		order = 0;
	} else if (b.x == 1 && b.y == 1) {
		order = 1;
	} else if (b.x == 1) {
		order = 2;
	}
	if (order >= level) {
		discard;
	}
	COLOR = texture(TEXTURE, UV);
}
