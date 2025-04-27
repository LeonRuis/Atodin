#version 330

in vec3 fragPosition;
in vec2 fragTextCoord;
in vec4 fragColor;
in vec3 fragNormal;

uniform sampler2D texture0;
uniform vec4 colDiffuse;

out vec4 finalColor;

#define LIGHT_DIRECTIONAL 0
#define LIGHT_POINT 1

struct Light {
	int  enabled;
	int  type;
	vec3 position;
	vec3 target;
	vec4 color;
};

uniform Light the_light;
uniform vec4 ambient;
uniform vec3 viewPos;

void main() {
	vec4 texelColor = texture(texture0, fragTextCoord);
	vec3 lightDot = vec3(0.0);
	vec3 normal = normalize(fragNormal);
	vec3 viewD = normalize(viewPos - fragPosition);
	vec3 specular = vec3(0.0);

	vec4 tint = colDiffuse * fragColor;

	vec3 light = vec3(0.0);

	if (the_light.type == 0) {
		light = -normalize(the_light.target - the_light.position);
	}

	if (the_light.type == 1) {
		light = normalize(the_light.position - fragPosition);
	} 

	float NdotL = max(dot(normal, light), 0.0);
	lightDot += the_light.color.rgb * NdotL;

	float specCo = 0.0;
	if (NdotL > 0.0) specCo = pow(max(0.0, dot(viewD, reflect(-(light), normal))), 16.0);
	specular += specCo;

	finalColor = (texelColor * ((tint + vec4(specular, 1.0)) * vec4(lightDot, 1.0)));
	finalColor += texelColor * (ambient / 10.0) * tint;

	finalColor = pow(finalColor, vec4(1.0 / 2.2));
}