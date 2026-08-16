module main;
import std, raylib6;

const int SCREEN_WIDTH  = 640;
const int SCREEN_HEIGHT = 480;

RLShader shader;
int u_time_loc;
int frame_count = 0;

fn void update_draw_frame()
{
	frame_count++;
	float time = (float)frame_count;
	shader.set_value(u_time_loc, &time, FLOAT);

	rl::@drawing()
	{
		rl::clear_background(rl::BLACK);

		rl::@shader_mode(shader)
		{
			rl::draw_rectangle(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT, rl::WHITE);
		};

		rl::draw_text("C3 + Raylib - Psychedelic Vortex", 20, 20, 20, rl::RAYWHITE);
		rl::draw_fps(SCREEN_WIDTH - 90, 20);
	};
}

fn int main(String[] args) @winmain
{
	rl::init_window(SCREEN_WIDTH, SCREEN_HEIGHT, "Vortex - C3 & Raylib");

	shader = rl::load_shader_from_memory(VERT_SHADER, FRAG_SHADER);
	u_time_loc = shader.get_location("u_time");

	Vec2 res = { SCREEN_WIDTH, SCREEN_HEIGHT };
	shader.set_value(shader.get_location("u_resolution"), &res, VEC2);

	$if env::WASM:
		emscripten_set_main_loop(&update_draw_frame, 60, 1);
	$else
		rl::set_target_fps(60);
		while (!rl::window_should_close()) update_draw_frame();
		rl::unload_shader(shader);
		rl::close_window();
	$endif

	return 0;
}

alias Em_callback_func = fn void();
extern fn void emscripten_set_main_loop(Em_callback_func func, int fps, int simulate_infinite_loop);

const String VERT_SHADER = `#version 300 es
in vec3 vertexPosition;
in vec2 vertexTexCoord;
out vec2 fragTexCoord;
uniform mat4 mvp;

void main() {
    fragTexCoord = vertexTexCoord;
    gl_Position = mvp * vec4(vertexPosition, 1.0);
}
`;

const String FRAG_SHADER = `#version 300 es
precision highp float;
in vec2 fragTexCoord;
out vec4 finalColor;

uniform vec2 u_resolution;
uniform float u_time;

void main() {
    vec2 pos = gl_FragCoord.xy - u_resolution * 0.5;
    pos.y = -pos.y;
    float d = length(pos);

    vec4 waves = vec4(
        sin(pos.x * 0.05 + u_time * 0.05) + sin(d * 0.05),
        cos(pos.y * 0.05 - u_time * 0.03) + cos(d * 0.05),
        sin((pos.x + pos.y) * 0.03 + d * 0.04),
        2.0
    );

    finalColor = vec4(waves.rgb * 0.25 + 0.5, 1.0);
}
`;