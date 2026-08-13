module main;
import std;

alias Rgba = char[<4>];

const int MAP_SIZE  = 256;
const int MAP_MASK  = MAP_SIZE - 1;
const int NUM_STARS = 300;

const int BUFFER_SIZE   = 1024;
const float SAMPLE_RATE = 44100.0f;
const int STEP_SAMPLES  = 15 * 44100 / 128;

const float[8] BASS_ROOTS = { 55.0f, 55.0f, 43.65f, 43.65f, 65.41f, 65.41f, 49.00f, 49.00f };

const float[8][4] CHORD_ARPS = {
	{ 220.0f, 261.63f, 329.63f, 440.0f, 523.25f, 440.0f, 329.63f, 261.63f },
	{ 174.61f, 220.0f, 261.63f, 349.23f, 440.0f, 349.23f, 261.63f, 220.0f },
	{ 261.63f, 329.63f, 392.00f, 523.25f, 659.25f, 523.25f, 392.00f, 329.63f },
	{ 196.00f, 246.94f, 293.66f, 392.00f, 493.88f, 392.00f, 293.66f, 246.94f }
};

struct Star
{
	float x;
	float y;
	float z;
}

Star[NUM_STARS] stars;
float[BUFFER_SIZE] audio_buffer;

char[MAP_SIZE][MAP_SIZE] height_map;
Rgba[MAP_SIZE][MAP_SIZE] color_map;

bool map_initialized = false;

float cam_x      = 0.0f;
float cam_y      = 0.0f;
float cam_angle  = 0.0f;
float cam_height = 50.0f;
float cam_roll   = 0.0f;
float cam_pitch  = 0.0f;

int frame_count  = 0;
int sample_count = 0;
int step         = 0;

float kick_pulse        = 0.0f;
float[<4>] amp;
float[<4>] phase;
float bass_phase_2      = 0.0f;
float lead_delay_buffer = 0.0f;

fn float sample_height(float fx, float fy)
{
	int x0 = (int)math::floor(fx) & MAP_MASK;
	int y0 = (int)math::floor(fy) & MAP_MASK;
	int x1 = (x0 + 1) & MAP_MASK;
	int y1 = (y0 + 1) & MAP_MASK;

	float tx = fx - math::floor(fx);
	float ty = fy - math::floor(fy);

	float h00 = height_map[y0][x0];
	float h10 = height_map[y0][x1];
	float h01 = height_map[y1][x0];
	float h11 = height_map[y1][x1];

	return (h00 + (h10 - h00) * tx) * (1.0f - ty) + (h01 + (h11 - h01) * tx) * ty;
}

fn void init_map()
{
	for (int i = 0; i < NUM_STARS; i++)
	{
		stars[i] = {
			.x = ((float)rnd() - 0.5f) * 1200.0f,
			.y = (float)rnd() * 170.0f,
			.z = (float)rnd() * 0.8f + 0.2f
		};
	}

	float tau = math::TWO_PI / MAP_SIZE;

	for (int y = 0; y < MAP_SIZE; y++)
	{
		for (int x = 0; x < MAP_SIZE; x++)
		{
			float fx = x * tau;
			float fy = y * tau;

			float h = math::sin(
				fx
			) * 34.0f + math::cos(
				fy
			) * 34.0f + math::sin(fx + fy) * 26.0f + math::sin(fx * 3.0f + fy * 2.0f) * 12.0f + 100.0f;
			h = math::clamp(h * 0.82f, 0.0f, 255.0f);
			height_map[y][x] = (char)h;

			float nh = h / 255.0f;
			if (h < 52)
			{
				color_map[y][x] = { 15, 30, 90, 255 };
			}
			else
			{
				color_map[y][x] = { (char)(20 + nh * 210), (char)(10 + nh * 80), (char)(140 - nh * 70), 255 };
			}
		}
	}
	map_initialized = true;
}

fn Rgba* update_canvas(int width, int height) @export("update_canvas")
{
	static Rgba[] pixels;
	if (pixels.len < width * height)
	{
		pixels = mem::new_array(Rgba, width * height);
	}
	if (!map_initialized) init_map();

	frame_count++;
	cam_roll = math::sin(frame_count * 0.012f) * 0.22f;
	cam_angle += cam_roll * 0.018f;

	cam_x += math::cos(cam_angle) * 1.6f;
	cam_y += math::sin(cam_angle) * 1.6f;

	float current_h = sample_height(cam_x, cam_y);
	float ahead_x   = cam_x + math::cos(cam_angle) * 22.0f;
	float ahead_y   = cam_y + math::sin(cam_angle) * 22.0f;
	float ahead_h   = sample_height(ahead_x, ahead_y);
	float ground_h  = (ahead_h > current_h) ? ahead_h : current_h;

	float target_h = ground_h + (ground_h < 52 ? 22 : 36);
	cam_height += (target_h - cam_height) * ((target_h > cam_height) ? 0.15f : 0.03f);
	if (cam_height < current_h + 12) cam_height = current_h + 12;

	cam_pitch += ((target_h - cam_height) * 0.4f - cam_pitch) * 0.1f;
	float current_horizon = 175 + cam_pitch;

	// Sky Gradient
	for (int y = 0; y < height; y++)
	{
		float t = y / current_horizon;
		Rgba sky_color;
		if (t < 1.0f)
		{
			sky_color = { .x = (char)(12 + t * 110), .y = (char)(6 + t * 20), .z = (char)(40 + t * 110), .w = 255 };
		}
		else
		{
			sky_color = {
				.x = (char)math::clamp(122 - (t - 1) * 180, 0, 255),
				.y = (char)math::clamp(26 - (t - 1) * 60, 0, 255),
				.z = (char)math::clamp(150 - (t - 1) * 200, 0, 255),
				.w = 255
			};
		}
		for (int x = 0; x < width; x++)
		{
			pixels[y * width + x] = sky_color;
		}
	}

	// Stars
	float fw = width;
	for (int i = 0; i < NUM_STARS; i++)
	{
		float sx = stars[i].x - cam_angle * 300.0f;
		while (sx < -fw) sx += fw * 2.0f;
		while (sx > fw * 2.0f) sx -= fw * 2.0f;

		int px = (int)(sx * 0.5f + fw * 0.5f);
		int py = (int)(stars[i].y + cam_pitch * 0.4f);
		if (px >= 0 && px < width && py >= 0 && py < current_horizon - 10)
		{
			char b = (char)(180.0f * stars[i].z + math::sin(frame_count * 0.1f + i) * 60.0f);
			pixels[py * width + px] = { b, b, (char)(b * 0.9f), 255 };
		}
	}

	// Moon
	int moon_cx = width / 2 - (int)(math::sin(cam_angle) * 160.0f);
	int moon_cy = 110 + (int)(cam_pitch * 0.8f);
	int moon_r  = 44;
	int max_r   = 66;

	for (int dy = -max_r; dy <= max_r; dy++)
	{
		int py = moon_cy + dy;
		if (py < 0 || py >= current_horizon) continue;

		for (int dx = -max_r; dx <= max_r; dx++)
		{
			int px = moon_cx + dx;
			if (px < 0 || px >= width) continue;
			int d2 = dx * dx + dy * dy;

			if (d2 > moon_r * moon_r)
			{
				if (d2 <= max_r * max_r)
				{
					float gt = 1.0f - (math::sqrt((float)d2) - moon_r) / 22.0f;
					if (gt > 0.0f)
					{
						gt *= gt;
						Rgba bg = pixels[py * width + px];
						pixels[py * width + px] = {
							(char)math::clamp((bg.x & 255) + gt * 60, 0, 255),
							(char)math::clamp((bg.y & 255) + gt * 160, 0, 255),
							(char)math::clamp((bg.z & 255) + gt * 220, 0, 255),
							255
						};
					}
				}
				continue;
			}

			float nx    = dx / 44.0f;
			float ny    = dy / 44.0f;
			float nz    = math::sqrt(math::clamp(1.0f - nx * nx - ny * ny, 0.0f, 1.0f));
			float light = math::clamp(nz * 0.75f - nx * 0.3f - ny * 0.35f + 0.25f, 0.25f, 1.0f);

			float crater    = math::sin(nx * 7.0f) * math::cos(ny * 7.0f) * 0.12f;
			float intensity = math::clamp(light + crater, 0.2f, 1.0f);

			pixels[py * width + px] = {
				(char)math::clamp(140 * intensity + 60, 0, 255),
				(char)math::clamp(200 * intensity + 45, 0, 255),
				(char)math::clamp(235 * intensity + 20, 0, 255),
				255
			};
		}
	}

	// VoxelSpace Terrain Raycaster
	float dz = 0.35f;
	for (int x = 0; x < width; x++)
	{
		float h_line    = current_horizon + (x - width * 0.5f) * math::tan(cam_roll);
		float ray_angle = cam_angle + (x - width * 0.5f) / width;
		float ray_cos   = math::cos(ray_angle);
		float ray_sin   = math::sin(ray_angle);

		int max_y = height;
		dz = 0.35f;

		for (float z = 1.0f; z < 400.0f; z += dz, dz += 0.005f)
		{
			int map_x = (int)math::floor(cam_x + ray_cos * z) & MAP_MASK;
			int map_y = (int)math::floor(cam_y + ray_sin * z) & MAP_MASK;

			float h  = height_map[map_y][map_x];
			Rgba col = color_map[map_y][map_x];

			if (h < 52)
			{
				float wave = math::sin(
					map_x * 0.18f + frame_count * 0.08f
				) + math::cos(map_y * 0.18f - frame_count * 0.06f);
				float spec = math::clamp(1.0f - math::abs(x - moon_cx) / 160.0f, 0.0f, 1.0f) * (0.6f + wave * 0.2f);
				col = {
					(char)(20 + spec * 235),
					(char)(15 + spec * 180 + wave * 25),
					(char)(80 + spec * 100 + wave * 40),
					255
				};
			}
			else
			{
				float slope = (h - height_map[map_y][(map_x + 1) & MAP_MASK])
					+ (h - height_map[(map_y + 1) & MAP_MASK][map_x]);
				float light = math::clamp(1.0f + slope * 0.02f, 0.2f, 1.8f);
				col.x = (char)math::clamp(col.x * light, 0, 255);
				col.y = (char)math::clamp(col.y * light, 0, 255);
				col.z = (char)math::clamp(col.z * light, 0, 255);
			}

			if (z > 260.0f)
			{
				float f = math::clamp((z - 260.0f) / 140.0f * 2.8f, 0.0f, 1.0f);
				col.x = (char)(col.x * (1 - f) + 122 * f);
				col.y = (char)(col.y * (1 - f) + 26 * f);
				col.z = (char)(col.z * (1 - f) + 150 * f);
			}

			int sy = math::clamp((int)((cam_height - h) / z * 190.0f + h_line), 0, height);
			if (sy < max_y)
			{
				for (int y = sy; y < max_y; y++)
				{
					pixels[y * width + x] = col;
				}
				max_y = sy;
			}
			if (max_y <= 0) break;
		}
	}

	// Oscilloscope
	for (int sx = 0; sx < 120; sx++)
	{
		int sy = 35 + (int)(audio_buffer[(sx * BUFFER_SIZE) / 120] * 22.0f);
		if (sy >= 10 && sy < 80 && (width - 140 + sx) < width)
		{
			pixels[sy * width + (width - 140 + sx)] = { 0, 255, 230, 255 };
		}
	}

	// Vignette Border
	for (int y = 0; y < height; y += 4)
	{
		float dy = (y - height * 0.5f) / (height * 0.5f);
		for (int x = 0; x < width; x += 4)
		{
			float dist_sq = ((x - width * 0.5f) / (width * 0.5f)) * ((x - width * 0.5f) / (width * 0.5f)) + dy * dy;
			if (dist_sq > 0.65f)
			{
				float vig = math::clamp(1.0f - (dist_sq - 0.65f) * 0.9f, 0.3f, 1.0f);
				for (int vy = 0; vy < 4 && (y + vy) < height; vy++)
				{
					for (int vx = 0; vx < 4 && (x + vx) < width; vx++)
					{
						int idx = (y + vy) * width + (x + vx);
						pixels[idx].x = (char)(pixels[idx].x * vig);
						pixels[idx].y = (char)(pixels[idx].y * vig);
						pixels[idx].z = (char)(pixels[idx].z * vig);
					}
				}
			}
		}
	}

	return pixels;
}

fn float* update_audio(int samples) @export("update_audio")
{
	for (int i = 0; i < samples; i++)
	{
		if (sample_count % STEP_SAMPLES == 0)
		{
			int sub = step % 16;
			if (sub % 4 == 0)
			{
				amp.x = 0.98f;
				phase.x = 0.0f;
			}
			if (sub == 4 || sub == 12)
			{
				amp.y = 0.5f;
				phase.y = 0.0f;
			}
			else if (sub % 2 == 1)
			{
				amp.y = 0.15f;
				phase.y = 0.0f;
			}
			amp.z = 0.3f;
			if (sub % 2 == 0)
			{
				amp.w = 0.20f;
				phase.w = 0.0f;
			}
			step++;
		}
		sample_count++;
		kick_pulse = amp.x;
		amp *= { 0.9991f, 0.9980f, 0.9995f, 0.9990f };

		int chord = (step / 16) % 4;
		float[<4>] inc = {
			180.0f * (amp.x * amp.x) + 40.0f,
			350.0f,
			BASS_ROOTS[(step / 16) % 8],
			CHORD_ARPS[chord][(step * 3) % 8]
		};
		phase += inc / SAMPLE_RATE;
		phase -= math::floor(phase);

		bass_phase_2 += (BASS_ROOTS[(step / 16) % 8] * 1.006f) / SAMPLE_RATE;
		if (bass_phase_2 > 1.0f) bass_phase_2 -= 1.0f;

		lead_delay_buffer = lead_delay_buffer * 0.65f + (phase.w < 0.5f ? 0.75f
			: -0.75f) * (1.0f - amp.x * 0.65f) * 0.35f;

		float[<4>] voice_out = {
			math::sin(phase.x * (float)math::TWO_PI),
			((float)rnd() * 2.0f - 1.0f) * 0.85f + math::sin(phase.y * (float)math::TWO_PI) * 0.15f,
			((phase.z * 2.0f - 1.0f) + (bass_phase_2 * 2.0f - 1.0f)) * 0.5f,
			(phase.w < 0.5f ? 0.75f : -0.75f) * (1.0f - amp.x * 0.65f) + lead_delay_buffer * 0.4f
		};

		audio_buffer[i] = (voice_out * amp).sum();
	}
	return &audio_buffer;
}

fn int main()
{
	io::printn("Engine Active.");
	return 0;
}
