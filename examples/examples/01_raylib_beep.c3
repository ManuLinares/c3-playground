module main;

import std, raylib6;

const int SAMPLE_RATE  = 48000;
const int SAMPLES      = (int)(SAMPLE_RATE * 0.2);
const float PHASE_STEP = math::TAU * 440 / SAMPLE_RATE;

RLSound sound;
float radius = 50;

fn void update_draw_frame()
{
	if (rl::is_mouse_button_pressed(LEFT) || rl::is_key_pressed(SPACE))
	{
		rl::play_sound(sound);
		radius = 80;
	}

	if (radius > 50) radius--;

	rl::@drawing()
	{
		rl::clear_background(rl::RAYWHITE);
		rl::draw_circle(400, 225, radius, rl::MAROON);
		rl::draw_text("Click or press SPACE to beep", 260, 320, 20, rl::DARKGRAY);
	};
}

fn int main(String[] args) @winmain
{
	rl::init_window(800, 450, "BEEP");
	rl::init_audio_device();

	short[SAMPLES] pcm;
	for (int i = 0; i < SAMPLES; i++)
	{
		float decay = (float)(SAMPLES - i) / SAMPLES;
		pcm[i] = (short)(math::sin(i * PHASE_STEP) * decay * 16000.0f);
	}

	RLWave wave = { .frameCount = SAMPLES, .sample_rate = SAMPLE_RATE, .sample_size = 16, .channels = 1, .data = &pcm };
	sound = rl::load_sound_from_wave(wave);

	$if env::WASM:
		emscripten_set_main_loop(&update_draw_frame, 60, 1);
	$else
		rl::set_target_fps(60);
		while (!rl::window_should_close()) update_draw_frame();
		rl::unload_sound(sound);
		rl::close_audio_device();
		rl::close_window();
	$endif

	return 0;
}

alias Em_callback_func = fn void();
extern fn void emscripten_set_main_loop(Em_callback_func func, int fps, int simulate_infinite_loop);