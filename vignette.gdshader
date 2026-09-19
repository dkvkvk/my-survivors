shader_type canvas_item;

// 轻量暗角后期：边缘压暗聚焦画面中心，纯透明黑叠加实现，
// 不采样屏幕纹理，兼容性渲染器（gl_compatibility）无压力。
uniform float strength = 0.38;
uniform float radius = 0.52;

void fragment() {
	vec2 d = UV - vec2(0.5);
	// 横向拉伸补偿宽屏比例，让暗角接近圆形
	float vig = smoothstep(radius, radius + 0.5, length(d * vec2(1.78, 1.0)));
	COLOR = vec4(0.0, 0.0, 0.0, vig * strength);
}
