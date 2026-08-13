module main;
import std;

const int BUFFER_SIZE    = 1024;
const double SAMPLE_RATE = 44100.0;
const int STEP_SAMPLES   = 4900;
const float TWO_PI       = 6.2831853f;

const float[16] BASS_NOTES = {
	55.0f, 55.0f, 110.0f, 55.0f,
	65.4f, 65.4f, 130.8f, 65.4f,
	82.4f, 82.4f, 164.8f, 82.4f,
	73.4f, 73.4f, 146.8f, 73.4f
};

const float[*] SOLO_SCALE = { 220.0f, 261.6f, 293.7f, 329.6f, 392.0f, 440.0f, 523.3f };

float[BUFFER_SIZE] audio_buffer;

float[<4>] amp;
float[<4>] decay = 0.9994f;
float[<4>] phase;

float solo_amp, solo_phase, solo_freq, solo_target_freq;

int sample_count;
int step;
float lfo_phase;

fn float* update_audio(int samples) @export("update_audio")
{
	for (int i = 0; i < samples; i++)
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

		lfo_phase += (TWO_PI * 1.5f) / SAMPLE_RATE;
		if (lfo_phase > TWO_PI) lfo_phase -= TWO_PI;

		solo_freq += (solo_target_freq - solo_freq) * 0.003f;
		float modulated_solo = solo_freq + math::sin(lfo_phase * 6.0f) * (solo_amp * 40.0f);

		float lead_base = BASS_NOTES[step];
		switch (bar)
		{
			case 4..5: lead_base *= 2.0f;
			case 6: lead_base *= 1.5f;
		}

		float lead_freq = lead_base + math::sin(lfo_phase) * 2.5f;

		float[<4>] phase_inc = { 150.0f * amp.x, 0.0f, BASS_NOTES[step], lead_freq };
		phase += phase_inc / SAMPLE_RATE;
		phase -= (int[<4>])phase;

		solo_phase += modulated_solo / SAMPLE_RATE;
		if (solo_phase > 1.0f) solo_phase -= 1.0f;

		float lead_wave = math::abs(phase.w * 2.0f - 1.0f) * 2.0f - 1.0f;
		float solo_wave = (solo_phase < 0.25f ? 0.6f : -0.6f) * solo_amp;

		float[<4>] voice_out = {
			math::sin(phase.x * TWO_PI),
			(float)rnd() * 2.0f - 1.0f,
			(phase.z < 0.5f ? 1.0f : -1.0f),
			lead_wave
		};

		voice_out *= amp;
		audio_buffer[i] = voice_out.sum() + solo_wave;
	}
	return &audio_buffer;
}

fn int main()
{
	io::printn("Audio engine active.");
	return 0;
}
