module main;

import std, raylib6;

const int SCREEN_WIDTH  = 800;
const int SCREEN_HEIGHT = 450;

RLCamera3D camera;
bool fps_mode = false;

fn void update_draw_frame()
{
	if (rl::is_key_pressed(SPACE) || rl::is_mouse_button_pressed(RIGHT))
	{
		fps_mode = !fps_mode;
		fps_mode ? rl::disable_cursor() : rl::enable_cursor();
	}

	if (fps_mode) rl::update_camera(&camera, FIRST_PERSON);

	rl::@drawing()
	{
		rl::clear_background((RLColor) { 15, 23, 42, 255 });

		rl::@mode3d(camera)
		{
			rl::draw_grid(20, 1.0f);
			rl::draw_cube({ 0, 1, 0 }, 2, 2, 2, rl::RED);
			rl::draw_cube_wires({ 0, 1, 0 }, 2, 2, 2, rl::MAROON);
			rl::draw_cube({ 3, 0.5f, 2 }, 1, 1, 1, rl::SKYBLUE);
			rl::draw_cube_wires({ 3, 0.5f, 2 }, 1, 1, 1, rl::BLUE);
		};

		ZString title = fps_mode ? "MODE: 3D FPS CAMERA (Mouse Locked)" : "MODE: FREE CURSOR (UI Mode)";
		ZString sub   = fps_mode ? "Move mouse to look | WASD to move | SPACE / Right-Click to unlock"
			: "Press SPACE or Right-Click to enter 3D FPS Mouse Look";
		RLColor col   = fps_mode ? rl::GREEN : rl::YELLOW;

		rl::draw_rectangle(15, 15, 480, 65, (RLColor) { 0, 0, 0, 180 });
		rl::draw_text(title, 25, 25, 20, col);
		rl::draw_text(sub, 25, 55, 14, rl::RAYWHITE);

		rl::draw_fps(SCREEN_WIDTH - 80, 20);
	};
}

fn int main(String[] args) @winmain
{
	rl::init_window(SCREEN_WIDTH, SCREEN_HEIGHT, "3D FPS Camera & Cursor Test");

	camera = {
		.position = { 0, 2, 4 },
		.target = { 0, 1, 0 },
		.up = { 0, 1, 0 },
		.fovy = 60.0f,
		.projection = PERSPECTIVE
	};

	$if env::WASM:
		emscripten_set_main_loop(&update_draw_frame, 60, 1);
	$else
		rl::set_target_fps(60);
		while (!rl::window_should_close()) update_draw_frame();
		rl::close_window();
	$endif

	return 0;
}

alias Em_callback_func = fn void();
extern fn void emscripten_set_main_loop(Em_callback_func func, int fps, int simulate_infinite_loop);