   pxl_42_color	      SAMPLER    +         PXL_42_LIGHTNESS                     PXL_42_CONTRAST                     PXL_42_COLOR_BALANCE_SHADOW                            PXL_42_COLOR_BALANCE_MIDTONES                            PXL_42_COLOR_BALANCE_HIGHLIGHTS                         
   PXL_42_HUE                     PXL_42_SATURATION                     PXL_42_VALUE                     postprocess_base.vs?   attribute vec3 POSITION;
attribute vec2 TEXCOORD0;

varying vec2 PS_TEXCOORD0;

void main()
{
	gl_Position = vec4( POSITION.xyz, 1.0 );
	PS_TEXCOORD0.xy = TEXCOORD0.xy;
}    pxl_42_color.ps?  #if defined( GL_ES )
precision mediump float;
#endif

varying vec2 PS_TEXCOORD0;
uniform sampler2D SAMPLER[1];

#define SRC_IMAGE SAMPLER[0]

uniform float PXL_42_LIGHTNESS;
uniform float PXL_42_CONTRAST;

uniform vec3 PXL_42_COLOR_BALANCE_SHADOW;
uniform vec3 PXL_42_COLOR_BALANCE_MIDTONES;
uniform vec3 PXL_42_COLOR_BALANCE_HIGHLIGHTS;

uniform float PXL_42_HUE;
uniform float PXL_42_SATURATION;
uniform float PXL_42_VALUE;

#define CYAN_RED_SHADOW PXL_42_COLOR_BALANCE_SHADOW.r
#define CYAN_RED_MIDTONES PXL_42_COLOR_BALANCE_MIDTONES.r
#define CYAN_RED_HIGHLIGHTS PXL_42_COLOR_BALANCE_HIGHLIGHTS.r

#define MAGENTA_GREEN_SHADOW PXL_42_COLOR_BALANCE_SHADOW.g
#define MAGENTA_GREEN_MIDTONES PXL_42_COLOR_BALANCE_MIDTONES.g
#define MAGENTA_GREEN_HIGHLIGHTS PXL_42_COLOR_BALANCE_HIGHLIGHTS.g

#define YELLOW_BLUE_SHADOW PXL_42_COLOR_BALANCE_SHADOW.b
#define YELLOW_BLUE_MIDTONES PXL_42_COLOR_BALANCE_MIDTONES.b
#define YELLOW_BLUE_HIGHLIGHTS PXL_42_COLOR_BALANCE_HIGHLIGHTS.b

vec3 colorbalance_transfer(float i)
{
    vec3 weight;
    weight.r = clamp((i - 85.0) / -64.0 + 0.5, 0.0, 1.0) * 1.785;
    weight.g = clamp((i - 85.0) / 64.0 + 0.5, 0.0, 1.0) * clamp((i + 85.0 - 255.0) / -64.0 + 0.5, 0.0, 1.0) * 1.785;
    weight.b = clamp(((255.0 - i) - 85.0) / -64.0 + 0.5, 0.0, 1.0) * 1.785;
    return weight;
}

vec3 rgb2hsv(vec3 rgb)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(rgb.bg, K.wz), vec4(rgb.gb, K.xy), step(rgb.b, rgb.g));
    vec4 q = mix(vec4(p.xyw, rgb.r), vec4(rgb.r, p.yzx), step(p.x, rgb.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv2rgb(vec3 hsv)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(hsv.xxx + K.xyz) * 6.0 - K.www);
    return hsv.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), hsv.y);
}

void main() 
{
    vec4 color = texture2D(SRC_IMAGE, PS_TEXCOORD0);
	color.rgb = clamp(color.rgb + PXL_42_LIGHTNESS, 0.0, 1.0);
	vec3 gray = vec3(0.5, 0.5, 0.5);
    color.rgb = clamp(mix(gray, color.rgb, PXL_42_CONTRAST), 0.0, 1.0);
    vec3 rgb = color.rgb * 255.0;

    vec3 weight_r = colorbalance_transfer(rgb.r);
    vec3 weight_g = colorbalance_transfer(rgb.g);
    vec3 weight_b = colorbalance_transfer(rgb.b);

    rgb.r += CYAN_RED_SHADOW * weight_r.r;
    rgb.r += CYAN_RED_MIDTONES * weight_r.g;
    rgb.r += CYAN_RED_HIGHLIGHTS * weight_r.b;

    rgb.g += MAGENTA_GREEN_SHADOW * weight_g.r;
    rgb.g += MAGENTA_GREEN_MIDTONES * weight_g.g;
    rgb.g += MAGENTA_GREEN_HIGHLIGHTS * weight_g.b;

    rgb.b += YELLOW_BLUE_SHADOW * weight_b.r;
    rgb.b += YELLOW_BLUE_MIDTONES * weight_b.g;
    rgb.b += YELLOW_BLUE_HIGHLIGHTS * weight_b.b;

    rgb.r = clamp(rgb.r, 0.0, 255.0);
    rgb.g = clamp(rgb.g, 0.0, 255.0);
    rgb.b = clamp(rgb.b, 0.0, 255.0);
	
	rgb /= 255.0;

    vec3 hsv1 = rgb2hsv(color.rgb);
    vec3 hsv2 = rgb2hsv(rgb);
    hsv2.z = hsv1.z;
	
	hsv2.x += PXL_42_HUE;
	hsv2.x = mod(hsv2.x, 1.0);
	hsv2.y *= PXL_42_SATURATION;
	//hsv2.y = min(hsv2.y, 1.0);
	hsv2.z *= PXL_42_VALUE;
	//hsv2.z = min(hsv2.z, 1.0);

    gl_FragColor = vec4(hsv2rgb(hsv2), color.a);
}     	                               