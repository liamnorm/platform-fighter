shader_type canvas_item;

uniform sampler2D palette_tex; //Palette to reference, this should be a 1-pixel tall texture containing your palette info
uniform vec4 outline_col : hint_color; //Outline color
uniform float skin;
uniform bool outofgame;

void fragment() {
    
    //Get red value and sample palette based on it
    float pal_sample = texture(TEXTURE,UV).r;
	float yval = (skin+.5)/17f;
    vec4 col = texture(palette_tex,vec2(pal_sample,yval));
    
    //Get alpha val of adjacent pixels
    vec2 p = TEXTURE_PIXEL_SIZE;
    
    float a = texture(TEXTURE,UV+vec2(p.x,0)).a;
    a += texture(TEXTURE,UV+vec2(-p.x,0)).a;
    a += texture(TEXTURE,UV+vec2(0,p.y)).a;
    a += texture(TEXTURE,UV+vec2(0,-p.y)).a;
    
    //Using found alpha value, determine the opacity of the outline
    
    a = step(a,.5);//Clamp the a value
    col.rgb = mix(outline_col.xyz, col.rgb, col.a);
    col.a = step(a, col.a);
	if (col.a == 1. && outofgame) {
		col.a = 0.25;
	}
	
	float w = 0.0;
	
	col += vec4(w,w,w,0);
    
    //Get palette color
    COLOR = col;

}