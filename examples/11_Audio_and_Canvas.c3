module main;
import std;

alias Rgba = char[<4>];

const int BUFFER_SIZE    = 1024;
const double SAMPLE_RATE = 44100.0;

const float BPM        = 110.0f;
const int STEP_SAMPLES = (int)((15.0f / BPM) * SAMPLE_RATE);

const float[16] BASS_NOTES = {
	55.0f, 55.0f, 55.0f, 55.0f,
	65.4f, 65.4f, 65.4f, 65.4f,
	49.0f, 49.0f, 49.0f, 49.0f,
	43.65f, 43.65f, 43.65f, 43.65f
};

const float[*] SOLO_SCALE = { 293.7f, 329.6f, 392.0f, 440.0f, 523.3f, 587.3f, 659.3f };

float[BUFFER_SIZE] audio_buffer;

float[<4>] amp;
float[<4>] decay = 0.9994f;
float[<4>] phase;

float solo_amp, solo_phase, solo_freq, solo_target_freq;

int sample_count, step;
float lfo_phase;

fn Rgba* update_canvas(int width, int height) @export("update_canvas")
{
	static Rgba[] pixels;
	if (pixels.len < width * height) pixels = mem::new_array(Rgba, width * height);

	float kick_r      = amp.x * 120.0f;
	float hat_flash   = amp.y * 70.0f;
	float bass_w      = amp.z * 100.0f;
	float lead_r      = amp.w * 70.0f;
	float solo_height = solo_amp * 90.0f;

	for (int y = 0; y < height; y++)
	{
		for (int x = 0; x < width; x++)
		{
			Rgba p = pixels[y * width + x];
			p[0] = (char)(p[0] * 0.82f);
			p[1] = (char)(p[1] * 0.82f);
			p[2] = (char)(p[2] * 0.82f);
			p[3] = 255;

			if (x < bass_w || x > width - bass_w)
			{
				p = { 255, 20, 147, 255 };
			}

			float dx = x - width * 0.5f;
			float dy = y - height * 0.5f;
			float d  = math::sqrt(dx * dx + dy * dy);
			if (d < kick_r)
			{
				p = { 20, 80, 240, 255 };
			}

			if (lead_r > 2.0f && d < lead_r + 4.0f && d > lead_r - 2.0f)
			{
				p = { 0, 255, 255, 255 };
			}

			if (y < hat_flash || y > height - hat_flash)
			{
				p = { 240, 200, 20, 255 };
			}

			pixels[y * width + x] = p;
		}
	}

	for (int x = 0; x < width; x++)
	{
		float wave = math::sin(x * 0.08f + solo_phase * (float)math::TWO_PI) * solo_height;
		int y      = height / 2 + (int)wave;
		if (y >= 0 && y < height)
		{
			pixels[y * width + x] = { [0..3] = 255 };
		}
	}

	return pixels;
}

fn float* update_audio(int samples) @export("update_audio")
{
	for (int i = 0; i < samples; i++)
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

		lfo_phase += 1.5f / SAMPLE_RATE;
		solo_freq += (solo_target_freq - solo_freq) * 0.002f;
		float modulated_solo = solo_freq + math::sin(lfo_phase * (float)math::TWO_PI * 6.0f) * (solo_amp * 40.0f);

		float bass_root = BASS_NOTES[step];
		if (step % 2 == 1) bass_root *= 2.0f;

		float lead_base = BASS_NOTES[step];
		switch (bar)
		{
			case 4..5: lead_base *= 2.0f;
			case 6: lead_base *= 1.5f;
		}

		float lead_freq = lead_base + math::sin(lfo_phase * (float)math::TWO_PI * 2.5f) * 2.5f;

		float[<4>] phase_inc = { 350.0f * amp.x, 180.0f, bass_root, lead_freq };
		phase += phase_inc / SAMPLE_RATE;
		phase -= (int[<4>])phase;

		solo_phase += modulated_solo / SAMPLE_RATE;

		if (solo_phase > 1.0f) solo_phase -= 1.0f;
		if (lfo_phase > 1.0f) lfo_phase -= 1.0f;

		float kick_raw  = math::sin(phase.x * (float)math::TWO_PI);
		float kick_wave = kick_raw * (1.2f - 0.2f * kick_raw * kick_raw);

		float snare_wave = ((float)rnd() * 2.0f - 1.0f) * 0.7f + math::sin(phase.y * (float)math::TWO_PI) * 0.3f;

		float bass_mod  = math::sin(phase.z * (float)math::TWO_PI) * 1.5f;
		float bass_wave = math::sin(phase.z * (float)math::TWO_PI + bass_mod);

		float lead_wave = math::abs(phase.w * 2.0f - 1.0f) * 2.0f - 1.0f;

		float duty      = 0.5f + math::sin(lfo_phase * (float)math::TWO_PI * 2.0f) * 0.25f;
		float solo_wave = (solo_phase < duty ? 0.6f : -0.6f) * solo_amp;

		float[<4>] voice_out = { kick_wave, snare_wave, bass_wave, lead_wave };
		voice_out *= amp;
		audio_buffer[i] = voice_out.sum() + solo_wave;
	}
	return audio_buffer.[..];
}

fn int main()
{
	io::printn("Audio and canvas engines active.");
	return 0;
}
