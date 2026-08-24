module main;

import std, raylib6;

const int SCREEN_WIDTH  = 640;
const int SCREEN_HEIGHT = 480;
const uint SAMPLE_RATE  = 44100;
const float BPM         = 110.0f;
const int STEP_SAMPLES  = (int)((15.0f / BPM) * (float)SAMPLE_RATE);

const float[16] BASS_NOTES = {
	55.0f, 55.0f, 55.0f, 55.0f,
	65.4f, 65.4f, 65.4f, 65.4f,
	49.0f, 49.0f, 49.0f, 49.0f,
	43.65f, 43.65f, 43.65f, 43.65f
};

const float[*] SOLO_SCALE = { 293.7f, 329.6f, 392.0f, 440.0f, 523.3f, 587.3f, 659.3f };

float[<4>] amp;
float[<4>] decay = 0.9994f;
float[<4>] phase;

float solo_amp, solo_phase, solo_freq, solo_target_freq;
int sample_count, step;
float lfo_phase;

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
				case 0: if (step % 8 == 0 && bar != 7) { amp.x = 0.8f; phase.x = 0.0f; }
				case 2: if (bar >= 1) amp.y = 0.15f;
				case 1:
				case 3: if (bar >= 1 && bar != 6) amp.y = 0.06f;
			}

			if ((step == 4 || step == 12) && bar >= 2)
			{
				amp.y = 0.45f;
				phase.y = 0.0f;
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

		lfo_phase += 1.5f / (float)SAMPLE_RATE;
		solo_freq += (solo_target_freq - solo_freq) * 0.002f;
		float modulated_solo = solo_freq + math::sin(lfo_phase * (float)math::TAU * 6.0f) * (solo_amp * 40.0f);

		float bass_root = BASS_NOTES[step];
		if (step % 2 == 1) bass_root *= 2.0f;

		float lead_base = BASS_NOTES[step];
		switch (bar)
		{
			case 4..5: lead_base *= 2.0f;
			case 6:    lead_base *= 1.5f;
		}

		float lead_freq = lead_base + math::sin(lfo_phase * (float)math::TAU * 2.5f) * 2.5f;

		float[<4>] phase_inc = { 350.0f * amp.x, 180.0f, bass_root, lead_freq };
		phase += phase_inc / (float)SAMPLE_RATE;
		phase -= (int[<4>])phase;

		solo_phase += modulated_solo / (float)SAMPLE_RATE;

		if (solo_phase > 1.0f) solo_phase -= 1.0f;
		if (lfo_phase > 1.0f) lfo_phase -= 1.0f;

		float kick_raw  = math::sin(phase.x * (float)math::TAU);
		float kick_wave = kick_raw * (1.2f - 0.2f * kick_raw * kick_raw);

		float snare_wave = ((float)rnd() * 2.0f - 1.0f) * 0.7f + math::sin(phase.y * (float)math::TAU) * 0.3f;
		float bass_mod   = math::sin(phase.z * (float)math::TAU) * 1.5f;
		float bass_wave  = math::sin(phase.z * (float)math::TAU + bass_mod);
		float lead_wave  = math::abs(phase.w * 2.0f - 1.0f) * 2.0f - 1.0f;

		float duty      = 0.5f + math::sin(lfo_phase * (float)math::TAU * 2.0f) * 0.25f;
		float solo_wave = (solo_phase < duty ? 0.6f : -0.6f) * solo_amp;

		float[<4>] voice_out = { kick_wave, snare_wave, bass_wave, lead_wave };
		voice_out *= amp;
		samples[i] = (voice_out.sum() + solo_wave) * 0.35f;
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
		rl::clear_background((RLColor) { 15, 23, 42, 255 });

		float bass_w = amp.z * (float)sw * 0.25f;
		rl::draw_rectangle(0, 0, (int)bass_w, sh, (RLColor) { 255, 20, 147, 80 });
		rl::draw_rectangle(sw - (int)bass_w, 0, (int)bass_w, sh, (RLColor) { 255, 20, 147, 80 });

		float kick_r = amp.x * 120.0f * scale;
		rl::draw_circle(sw / 2, sh / 2, kick_r, (RLColor) { 20, 80, 240, 180 });

		float lead_r = amp.w * 90.0f * scale;
		if (lead_r > 2.0f)
		{
			rl::draw_circle_lines(sw / 2, sh / 2, lead_r, (RLColor) { 0, 255, 255, 220 });
		}

		float hat_flash = amp.y * 60.0f * scale;
		rl::draw_rectangle(0, 0, sw, (int)hat_flash, (RLColor) { 240, 200, 20, 120 });
		rl::draw_rectangle(0, sh - (int)hat_flash, sw, (int)hat_flash, (RLColor) { 240, 200, 20, 120 });

		float solo_height = solo_amp * 90.0f * scale;
		for (int x = 0; x < sw - 1; x += 4)
		{
			float w1 = math::sin((float)x * 0.08f + solo_phase * (float)math::TAU) * solo_height;
			float w2 = math::sin((float)(x + 4) * 0.08f + solo_phase * (float)math::TAU) * solo_height;
			rl::draw_line(x, sh / 2 + (int)w1, x + 4, sh / 2 + (int)w2, rl::WHITE);
		}

		rl::draw_text("C3 Audio & Visuals Synthesizer (Raylib)", 20, 20, 20, rl::RAYWHITE);
		rl::draw_fps(sw - 80, 20);
	};
}

fn int main(String[] args) @winmain
{
	$if !env::WASM:
		rl::set_config_flags(WINDOW_RESIZABLE);
	$endif
	rl::init_window(SCREEN_WIDTH, SCREEN_HEIGHT, "Audio and Visuals - C3 & Raylib");
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