module main;

import std, raylib6;

const int SQUARE_SIZE   = 32;
const int SCREEN_WIDTH  = 800;
const int SCREEN_HEIGHT = 450;
const int COLS          = SCREEN_WIDTH / SQUARE_SIZE;
const int ROWS          = SCREEN_HEIGHT / SQUARE_SIZE;
const int MAX_SNAKE     = COLS * ROWS;
const float MOVE_SPEED  = 0.15f;

enum Direction : int (Vec2 dir)
{
	UP    { { 0.0f, (float)-SQUARE_SIZE } },
	DOWN  { { 0.0f, (float)SQUARE_SIZE } },
	LEFT  { { (float)-SQUARE_SIZE, 0.0f } },
	RIGHT { { (float)SQUARE_SIZE, 0.0f } }
}

fn bool is_opposite_dir(Direction a, Direction b) =>
	(a.dir.x + b.dir.x == 0.0f) && (a.dir.y + b.dir.y == 0.0f);

fn int grid_idx(Vec2 pos, Vec2 min_b) =>
	(int)((pos.y - min_b.y) / SQUARE_SIZE) * COLS + (int)((pos.x - min_b.x) / SQUARE_SIZE);

fn void draw_centered(ZString text, int y, int size, RLColor col) =>
	rl::draw_text(text, SCREEN_WIDTH / 2 - rl::measure_text(text, size) / 2, y, size, col);

RLSound eat_sound;
RLAudioStream music_stream;
ulong music_timer = 0;
float music_phase = 0.0f;
float bass_phase  = 0.0f;
int last_bar      = -1;
bool glitch_bar   = false;

const float[16] MELODY = {
	110.0f, 0.0f, 110.0f, 0.0f,
	130.81f, 0.0f, 110.0f, 146.83f,
	110.0f, 0.0f, 110.0f, 0.0f,
	130.81f, 123.47f, 110.0f, 0.0f
};

fn float drum_env(float t, float len) => math::max(0.0f, 1.0f - t / len);
fn float noise(uint i, uint seed)     => (float)(i % seed) / (float)seed - 0.5f;

fn void audio_reset()
{
	music_timer = 0;
	music_phase = 0.0f;
	bass_phase  = 0.0f;
	last_bar    = -1;
}

fn void audio_callback(void* data, uint frames)
{
	float* out = (float*)data;

	if (g.waiting_for_start || g.game_over || g.paused)
	{
		out[0..frames] = 0.0f;
		return;
	}

	const float STEP_TIME   = 0.15f;
	const float BAR_TIME    = STEP_TIME * 16.0f;
	const float SAMPLE_RATE = 44100.0f;
	const float TAU         = (float)math::TAU;

	for (uint i = 0; i < frames; i++)
	{
		float time   = (float)music_timer / SAMPLE_RATE;
		int step     = (int)(time / STEP_TIME);
		int bar      = (int)(time / BAR_TIME);
		int phrase   = bar / 4;
		int step_bar = step % 16;
		float stime  = time - (float)step * STEP_TIME;

		if (bar != last_bar)
		{
			last_bar   = bar;
			glitch_bar = (phrase >= 2) && (((bar * 17 + 11) % 10) < 6);
		}

		float mixed = 0.0f;
		float env   = drum_env(stime, STEP_TIME);
		float atk   = math::min(1.0f, stime / 0.002f);
		float freq  = MELODY[step_bar];

		if (freq > 0.0f)
		{
			music_phase += (freq * TAU) / SAMPLE_RATE;
			if (music_phase > TAU) music_phase -= TAU;
			bass_phase  += (freq * 0.5f * TAU) / SAMPLE_RATE;
			if (bass_phase > TAU) bass_phase -= TAU;
		}

		if (phrase >= 1)
		{
			bool intense = (phrase >= 3);
			if (step_bar == 0 || step_bar == 8)
			{
				float k_env = drum_env(stime, 0.12f);
				mixed += math::sin(stime * (150.0f * k_env + (intense ? 20.0f : 30.0f)) * TAU) * k_env * (intense ? 1.4f : 0.8f);
			}
			if (step_bar == 4 || step_bar == 12)
			{
				mixed += noise(i, 1237) * drum_env(stime, 0.10f) * 0.5f;
			}
			if (intense && step_bar == 11)
			{
				mixed += noise(i, 71) * math::max(0.0f, 0.4f - stime / 0.08f) * 0.3f;
			}
			if ((step_bar % 4 == 2) || (intense && (step_bar % 2 != 0)))
			{
				mixed += noise(i, 71) * drum_env(stime, 0.04f) * 0.25f;
			}
		}

		if ((bar % 4 == 1 || bar % 4 == 3) && glitch_bar)
		{
			mixed += (math::sin(music_phase * (0.6f + 0.15f * math::sin(time * 12.0f))) + (float)(i % 500) / 500.0f * 0.05f) * env;
		}
		else if (freq > 0.0f)
		{
			mixed += math::sin(music_phase) * env * atk * 0.5f;
			if (phrase >= 1) mixed += math::sin(bass_phase) * env * atk * 0.7f;
		}

		float boost = mixed * 2.5f;
		out[i] = (boost / (1.0f + math::abs(boost))) * 0.9f;
		music_timer++;
	}
}

fn void audio_init()
{
	rl::init_audio_device();
	audio_reset();

	float[44100 / 15] samples;
	foreach (i, &s : samples)
	{
		float t = (float)i / 44100.0f;
		float freq = 880.0f - ((float)i / (float)samples.len) * 440.0f;
		*s = math::sin(t * freq * (float)math::TAU) * (1.0f - (float)i / (float)samples.len) * 0.2f;
	}

	eat_sound = rl::load_sound_from_wave({
		.frameCount  = (uint)samples.len,
		.sample_rate = 44100,
		.sample_size = 32,
		.channels    = 1,
		.data        = &samples
	});

	music_stream = rl::load_audio_stream(44100, 32, 1);
	music_stream.set_callback(&audio_callback);
	rl::play_audio_stream(music_stream);
}

fn void audio_deinit()
{
	rl::unload_sound(eat_sound);
	rl::unload_audio_stream(music_stream);
	rl::close_audio_device();
}

struct GameState @align(64)
{
	Vec2[MAX_SNAKE] snake;
	Direction[2] queue;
	Direction dir;
	Vec2 fruit;
	Vec2 remainder;
	int head_idx;
	int tail_count;
	int queue_count;
	float move_timer;
	bool fruit_active;
	bool game_over;
	bool paused;
	bool waiting_for_start;
	bool[MAX_SNAKE] occupied;
}

GameState g;
RLRenderTexture2D render_target;

fn void GameState.init(&self)
{
	*self = {
		.tail_count = 1,
		.dir        = RIGHT,
		.remainder  = { (float)(SCREEN_WIDTH % SQUARE_SIZE), (float)(SCREEN_HEIGHT % SQUARE_SIZE) }
	};

	Vec2 center = { (float)((COLS / 2) * SQUARE_SIZE), (float)((ROWS / 2) * SQUARE_SIZE) };
	self.snake[0] = self.remainder * 0.5f + center;
	self.occupied[grid_idx(self.snake[0], self.remainder * 0.5f)] = true;

	audio_reset();
	self.spawn_fruit();
}

fn void GameState.spawn_fruit(&self)
{
	int[MAX_SNAKE] empty;
	int count = 0;
	foreach (i, occ : self.occupied) if (!occ) empty[count++] = (int)i;
	if (count == 0) return;

	int cell = empty[rl::get_random_value(0, count - 1)];
	self.fruit = self.remainder * 0.5f + (Vec2) { (float)(cell % COLS), (float)(cell / COLS) } * (float)SQUARE_SIZE;
	self.fruit_active = true;
}

fn void GameState.queue_move(&self, Direction d)
{
	Direction last = self.queue_count > 0 ? self.queue[self.queue_count - 1] : self.dir;
	if (d == last || is_opposite_dir(d, last)) return;
	if (self.queue_count < self.queue.len) self.queue[self.queue_count++] = d;
}

fn void update_game()
{
	if (g.waiting_for_start)
	{
		if (rl::get_key_pressed() != RLKeyboardKey.NONE || rl::is_mouse_button_pressed(LEFT)) g.waiting_for_start = false;
		return;
	}
	if (g.game_over)
	{
		if ((rl::get_key_pressed() != RLKeyboardKey.NONE && !rl::is_key_pressed(F)) || rl::is_mouse_button_pressed(LEFT)) g.init();
		return;
	}

	if (rl::is_key_pressed(P)) g.paused = !g.paused;
	if (g.paused) return;

	if (rl::is_key_pressed(UP)    || rl::is_key_pressed(W)) g.queue_move(UP);
	if (rl::is_key_pressed(DOWN)  || rl::is_key_pressed(S)) g.queue_move(DOWN);
	if (rl::is_key_pressed(LEFT)  || rl::is_key_pressed(A)) g.queue_move(LEFT);
	if (rl::is_key_pressed(RIGHT) || rl::is_key_pressed(D)) g.queue_move(RIGHT);

	g.move_timer += math::min(rl::get_frame_time(), 0.1f);
	if (g.move_timer < MOVE_SPEED) return;

	g.move_timer -= MOVE_SPEED;
	if (g.queue_count > 0)
	{
		g.dir = g.queue[0];
		g.queue[0] = g.queue[1];
		g.queue_count--;
	}

	Vec2 new_head = g.snake[g.head_idx] + g.dir.dir;
	Vec2 min_b    = g.remainder * 0.5f;
	Vec2 max_b    = (Vec2) { (float)SCREEN_WIDTH, (float)SCREEN_HEIGHT } - min_b;

	if (new_head.x < min_b.x || new_head.y < min_b.y || new_head.x >= max_b.x || new_head.y >= max_b.y)
	{
		g.game_over = true;
		return;
	}

	int bit = grid_idx(new_head, min_b);
	int next_idx = (g.head_idx + 1) % MAX_SNAKE;
	bool is_fruit = (new_head.x == g.fruit.x && new_head.y == g.fruit.y);

	if (!is_fruit)
	{
		Vec2 tail = g.snake[(g.head_idx - (g.tail_count - 1) + MAX_SNAKE) % MAX_SNAKE];
		g.occupied[grid_idx(tail, min_b)] = false;
	}

	if (g.occupied[bit])
	{
		g.game_over = true;
		return;
	}

	if (is_fruit)
	{
		g.tail_count = math::min(g.tail_count + 1, MAX_SNAKE);
		g.fruit_active = false;
		if (rl::is_audio_device_ready()) rl::play_sound(eat_sound);
	}

	g.head_idx = next_idx;
	g.snake[g.head_idx] = new_head;
	g.occupied[bit] = true;

	if (!g.fruit_active) g.spawn_fruit();
}

fn void draw_game()
{
	rl::clear_background((RLColor) { 15, 15, 20, 255 });

	for (int i = 0; i <= COLS; i++)
	{
		float x = g.remainder.x * 0.5f + (float)i * SQUARE_SIZE;
		rl::draw_line_v({ x, g.remainder.y * 0.5f }, { x, (float)SCREEN_HEIGHT - g.remainder.y * 0.5f }, (RLColor) { 40, 40, 50, 255 });
	}
	for (int i = 0; i <= ROWS; i++)
	{
		float y = g.remainder.y * 0.5f + (float)i * SQUARE_SIZE;
		rl::draw_line_v({ g.remainder.x * 0.5f, y }, { (float)SCREEN_WIDTH - g.remainder.x * 0.5f, y }, (RLColor) { 40, 40, 50, 255 });
	}

	if (g.fruit_active) rl::draw_rectangle_v(g.fruit, { (float)SQUARE_SIZE, (float)SQUARE_SIZE }, rl::PINK);

	for (int i = 0; i < g.tail_count; i++)
	{
		Vec2 pos = g.snake[(g.head_idx - i + MAX_SNAKE) % MAX_SNAKE];
		float t  = g.tail_count > 1 ? (float)i / (float)(g.tail_count - 1) : 0.0f;
		RLColor col = i == 0 ? rl::SKYBLUE : (RLColor) { 0, (char)(255 - 175 * t), (char)(255 - 105 * t), 255 };

		rl::draw_rectangle_v(pos, { (float)SQUARE_SIZE, (float)SQUARE_SIZE }, col);
		rl::draw_rectangle_lines_ex({ pos.x, pos.y, (float)SQUARE_SIZE, (float)SQUARE_SIZE }, 1.0f, (RLColor) { 0, 0, 0, 150 });
	}

	if (g.paused) draw_centered("PAUSED", SCREEN_HEIGHT / 2 - 15, 30, rl::GRAY);
	rl::draw_text(rl::text_format("SCORE: %d", (g.tail_count - 1) * 100), 20, 20, 20, rl::GOLD);

	if (g.waiting_for_start) draw_centered("CLICK TO START", SCREEN_HEIGHT / 2 - 14, 28, rl::RAYWHITE);
	if (g.game_over)
	{
		draw_centered("GAME OVER", SCREEN_HEIGHT / 2 - 60, 40, rl::MAROON);
		draw_centered("CLICK/ANY KEY TO RESTART", SCREEN_HEIGHT / 2 + 10, 20, rl::RAYWHITE);
	}
}

fn void draw_letterboxed(RLTexture tex)
{
	float sw = (float)rl::get_render_width();
	float sh = (float)rl::get_render_height();
	float s  = math::min(sw / (float)SCREEN_WIDTH, sh / (float)SCREEN_HEIGHT);
	Vec2 size = { (float)SCREEN_WIDTH * s, (float)SCREEN_HEIGHT * s };
	Vec2 pos  = { (sw - size.x) * 0.5f, (sh - size.y) * 0.5f };

	rl::draw_texture_pro(
		tex,
		{ 0.0f, 0.0f, (float)SCREEN_WIDTH, (float)-SCREEN_HEIGHT },
		{ pos.x, pos.y, size.x, size.y },
		{ 0.0f, 0.0f }, 0.0f, rl::WHITE
	);
}

fn void update_draw_frame()
{
	update_game();
	rl::@texture_mode(render_target) { draw_game(); };
	rl::@drawing()
	{
		rl::clear_background(rl::BLACK);
		draw_letterboxed(render_target.texture);
	};
}

fn int main(String[] args) @winmain
{
	$if !env::WASM:
		rl::set_config_flags(WINDOW_RESIZABLE);
	$endif

	rl::init_window(SCREEN_WIDTH, SCREEN_HEIGHT, "C3 Snake");
	audio_init();

	render_target = rl::load_render_texture(SCREEN_WIDTH, SCREEN_HEIGHT);
	render_target.texture.set_filter(POINT);

	g.init();
	g.waiting_for_start = true;

	$if env::WASM:
		emscripten_set_main_loop(&update_draw_frame, 0, 1);
	$else
		rl::set_target_fps(60);
		while (!rl::window_should_close()) update_draw_frame();
		rl::unload_render_texture(render_target);
		audio_deinit();
		rl::close_window();
	$endif

	return 0;
}

alias Em_callback_func = fn void();
extern fn void emscripten_set_main_loop(Em_callback_func func, int fps, int simulate_infinite_loop);