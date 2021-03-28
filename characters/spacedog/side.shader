shader_type canvas_item;

uniform sampler2D palette_tex;
uniform float skin;
uniform int frame;


void fragment() {
	float yval = (skin+.5)/17f;
	vec4 col = texture(palette_tex,vec2(0.54,yval));
	vec4 tcol = texture(TEXTURE, UV);
	if (tcol.a > .5) {
		COLOR = col;
		COLOR.a = float(9-frame)/ 9.;
	} else {
		COLOR = vec4(0,0,0,0);
	}
}