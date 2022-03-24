shader_type canvas_item;

uniform int strength: hint_range(1, 10) = 1;

const float PI = 3.14159265358979323846;
const float STD = 1.5;


float gauss(int x, int y){
	return exp(-float(x * x + y * y) / (2. * STD * STD)) / (2. * PI * STD * STD);
}


void fragment() {
	int x = int(UV.x / TEXTURE_PIXEL_SIZE.x);
	int y = int(UV.y / TEXTURE_PIXEL_SIZE.y);
	int i_min = max(x - strength, 0);
	int i_max = min(x + strength + 1, int(1./TEXTURE_PIXEL_SIZE.x));
	int i_diff = i_max - i_min;
	int j_min = max(y - strength, 0);
	int j_max = min(y + strength + 1, int(1./TEXTURE_PIXEL_SIZE.y));
	int j_diff = j_max - j_min;
	// Should be equal to (strength * 2 + 1)^2
	vec4 weights[9];
	vec4 total = vec4(0., 0., 0., 0.);
	for(int i = i_min; i < i_max; i++){
		for(int j = j_min; j < j_max; j++){
			vec4 weight = vec4(
				gauss(i-x, y-j),
				gauss(i-x, y-j),
				gauss(i-x, y-j),
				gauss(i-x, y-j)
			);
			weights[j-j_min + (i-i_min) * (j_max-j_min)] = weight;
			total += weight;
		}
	}
	vec4 color_total = vec4(0., 0., 0., 0.);
	for(int k = 0; k < weights.length(); k++){
		weights[k] /= total;
		weights[k] *= texture(TEXTURE, (UV / TEXTURE_PIXEL_SIZE + vec2(float(k / i_diff), float(k % i_diff))) * TEXTURE_PIXEL_SIZE);
		color_total += weights[k];
	}
	COLOR = color_total;
}