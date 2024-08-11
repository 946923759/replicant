shader_type canvas_item;

uniform vec4 color1: hint_color = vec4(1.0,0.0,0.0,1.0);
uniform vec4 color2: hint_color = vec4(0.0,1.0,0.0,1.0);

void fragment(){
	vec4 inputColor = texture(TEXTURE,UV);
	//COLOR.rgb = mix(color1,color2,UV.y).rgb;
	vec4 result = mix(color1,color2,UV.y);
	COLOR = vec4(result.rgb, inputColor.a*result.a);
	//COLOR.rgb = vec3(0.0, 0.0, 0.0);
	//COLOR.a = inputColor.a * result.a;
	//COLOR.a = 0.0;
}