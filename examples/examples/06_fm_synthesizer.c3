module main;

import std, raylib6;

const int SCREEN_WIDTH  = 640;
const int SCREEN_HEIGHT = 480;
const uint SAMPLE_RATE  = 44100;
const int STEP_SAMPLES  = 4900;

const float[16] BASS_NOTES = {
	55.0f, 55.0f, 110.0f, 55.0f,
	65.4f, 65.4f, 130.8f, 65.4f,
	82.4f, 82.4f, 164.8f, 82.4f,
	73.4f, 73.4f, 146.8f, 73.4f
};

const float[*] SOLO_SCALE = { 220.0f, 261.6f, 293.7f, 329.6f, 392.0f, 440.0f, 523.3f };

float[<4>] amp;
float[<4>] decay = 0.9994f;
float[<4>] phase;

float solo_amp, solo_phase, solo_freq, solo_target_freq;
int sample_count, step;
float lfo_phase;

float[512] scope_buffer;
int scope_write_idx = 0;

fn void audio_callback(void* buffer, uint frames)
{
	float* samples = (float*)buffer;

	for (uint i = 0; i < frames; i++)
	{
		int bar = (sample_count / (STEP_SAMPLES * 16)) % 8;

		if (sample_count % STEP_SAMPLES == 0)
		{
			switch (step % 4)
			{
				case 0: if (bar != 7) { amp.x = 0.7f; phase.x = 0.0f; }
				case 2: if (bar >= 1) amp.y = 0.20f;
				case 1:
				case 3: if (bar >= 1 && bar != 6) amp.y = 0.08f;
			}

			if (bar >= 2 && bar != 6) amp.z = 0.18f;
			if (bar >= 3 && step % 3 == 2) amp.w = 0.15f;

			if ((bar == 4 || bar == 5 || bar == 7) && rnd() < 0.70)
			{
				solo_target_freq = SOLO_SCALE[(int)(rnd() * SOLO_SCALE.len)];
				solo_amp = 0.30f;
			}

			step = (step + 1) % 16;
		}
		sample_count++;

		amp *= decay;
		solo_amp *= 0.9995f;

		lfo_phase += ((float)math::TAU * 1.5f) / (float)SAMPLE_RATE;
		if (lfo_phase > (float)math::TAU) lfo_phase -= (float)math::TAU;

		solo_freq += (solo_target_freq - solo_freq) * 0.003f;
		float modulated_solo = solo_freq + math::sin(lfo_phase * 6.0f) * (solo_amp * 40.0f);

		float lead_base = BASS_NOTES[step];
		switch (bar)
		{
			case 4..5: lead_base *= 2.0f;
			case 6:    lead_base *= 1.5f;
		}

		float lead_freq = lead_base + math::sin(lfo_phase) * 2.5f;

		float[<4>] phase_inc = { 150.0f * amp.x, 0.0f, BASS_NOTES[step], lead_freq };
		phase += phase_inc / (float)SAMPLE_RATE;
		phase -= (int[<4>])phase;

		solo_phase += modulated_solo / (float)SAMPLE_RATE;
		if (solo_phase > 1.0f) solo_phase -= 1.0f;

		float lead_wave = math::abs(phase.w * 2.0f - 1.0f) * 2.0f - 1.0f;
		float solo_wave = (solo_phase < 0.25f ? 0.6f : -0.6f) * solo_amp;

		float[<4>] voice_out = {
			math::sin(phase.x * (float)math::TAU),
			(float)rnd() * 2.0f - 1.0f,
			(phase.z < 0.5f ? 1.0f : -1.0f),
			lead_wave
		};

		voice_out *= amp;
		float val = voice_out.sum() * 0.3f + solo_wave * 0.3f;
		samples[i] = val;

		scope_buffer[scope_write_idx] = val;
		scope_write_idx = (scope_write_idx + 1) % (int)scope_buffer.len;
	}
}

RLAudioStream stream;

fn void update_draw_frame()
{
	int sw = rl::get_render_width();
	int sh = rl::get_render_height();
	float scale = (float)sh / 480.0f;

	rl::@drawing()
	{
		rl::clear_background((RLColor) { 10, 15, 30, 255 });

		rl::draw_text("C3 Retro FM Synthesizer (Raylib AudioStream)", 20, 20, 20, (RLColor) { 56, 189, 248, 255 });
		rl::draw_text("Real-time procedural audio synthesis running in WASM", 20, 50, 20, rl::GRAY);

		int center_y = sh / 2 + 30;
		rl::draw_line(20, center_y, sw - 20, center_y, (RLColor) { 30, 41, 59, 255 });

		for (int i = 0; i < scope_buffer.len - 1; i++)
		{
			int x1 = 20 + (i * (sw - 40)) / (int)scope_buffer.len;
			int x2 = 20 + ((i + 1) * (sw - 40)) / (int)scope_buffer.len;
			int y1 = center_y + (int)(scope_buffer[i] * 120.0f * scale);
			int y2 = center_y + (int)(scope_buffer[i + 1] * 120.0f * scale);
			rl::draw_line(x1, y1, x2, y2, (RLColor) { 244, 63, 94, 255 });
		}

		rl::draw_fps(sw - 80, 20);
	};
}

fn int main(String[] args) @winmain
{
	rl::set_config_flags(WINDOW_RESIZABLE);
	rl::init_window(SCREEN_WIDTH, SCREEN_HEIGHT, "FM Synthesizer - C3 & Raylib");
	rl::init_audio_device();

	stream = rl::load_audio_stream(SAMPLE_RATE, 32, 1);
	stream.set_callback(&audio_callback);
	rl::play_audio_stream(stream);

	$if env::WASM:
		emscripten_set_main_loop(&update_draw_frame, 60, 1);
	$else
		rl::set_target_fps(60);
		while (!rl::window_should_close()) update_draw_frame();
		rl::unload_audio_stream(stream);
		rl::close_audio_device();
		rl::close_window();
	$endif

	return 0;
}

alias Em_callback_func = fn void();
extern fn void emscripten_set_main_loop(Em_callback_func func, int fps, int simulate_infinite_loop);