module main;
import std;
import raylib6;

alias Rgba = char[<4>];

struct Rect
{
	int x;
	int y;
	int w;
	int h;
}

// --- Canvas Object & Type Methods ---
struct Canvas
{
	Rgba[] pixels;
	int width;
	int height;
}

fn void Canvas.clear(&self, Rgba col)
{
	self.pixels[..] = col;
}

fn void Canvas.draw_pixel(&self, int x, int y, Rgba col)
{
	if (x >= 0 && x < self.width && y >= 0 && y < self.height)
	{
		self.pixels[y * self.width + x] = col;
	}
}

fn void Canvas.draw_rect(&self, Rect r, Rgba col)
{
	int min_x = math::clamp(r.x, 0, self.width);
	int max_x = math::clamp(r.x + r.w, 0, self.width);
	int min_y = math::clamp(r.y, 0, self.height);
	int max_y = math::clamp(r.y + r.h, 0, self.height);

	for (int y = min_y; y < max_y; y++)
	{
		for (int x = min_x; x < max_x; x++)
		{
			self.pixels[y * self.width + x] = col;
		}
	}
}

fn void Canvas.draw_circle(&self, Vec2 center, float r, Rgba col)
{
	int min_x = math::clamp((int)(center.x - r), 0, self.width);
	int max_x = math::clamp((int)(center.x + r + 1.0f), 0, self.width);
	int min_y = math::clamp((int)(center.y - r), 0, self.height);
	int max_y = math::clamp((int)(center.y + r + 1.0f), 0, self.height);

	float r_sq = r * r;
	for (int y = min_y; y < max_y; y++)
	{
		for (int x = min_x; x < max_x; x++)
		{
			Vec2 p    = { (float)x, (float)y };
			Vec2 diff = p - center;
			if (diff.x * diff.x + diff.y * diff.y <= r_sq)
			{
				self.pixels[y * self.width + x] = col;
			}
		}
	}
}

fn void Canvas.draw_line(&self, Vec2 start, Vec2 end, Rgba col)
{
	int x0 = (int)start.x;
	int y0 = (int)start.y;
	int x1 = (int)end.x;
	int y1 = (int)end.y;

	int dx  =  math::abs(x1 - x0);
	int sx  =  x0 < x1 ? 1 : -1;
	int dy  = -math::abs(y1 - y0);
	int sy  =  y0 < y1 ? 1 : -1;
	int err =  dx + dy;

	while (true)
	{
		self.draw_pixel(x0, y0, col);
		if (x0 == x1 && y0 == y1) break;
		int e2 = 2 * err;
		if (e2 >= dy)
		{
			err += dy;
			x0 += sx;
		}
		if (e2 <= dx)
		{
			err += dx;
			y0 += sy;
		}
	}
}

fn void Canvas.draw_line_dashed(&self, Vec2 start, Vec2 end, Rgba col, int dash_len)
{
	int x0 = (int)start.x;
	int y0 = (int)start.y;
	int x1 = (int)end.x;
	int y1 = (int)end.y;

	int dx         =  math::abs(x1 - x0);
	int sx         =  x0 < x1 ? 1 : -1;
	int dy         = -math::abs(y1 - y0);
	int sy         =  y0 < y1 ? 1 : -1;
	int err        =  dx + dy;
	int step_count =  0;

	while (true)
	{
		if ((step_count / dash_len) % 2 == 0)
		{
			self.draw_pixel(x0, y0, col);
		}
		step_count++;
		if (x0 == x1 && y0 == y1) break;
		int e2 = 2 * err;
		if (e2 >= dy)
		{
			err += dy;
			x0 += sx;
		}
		if (e2 <= dx)
		{
			err += dx;
			y0 += sy;
		}
	}
}

fn void Canvas.draw_grid(&self, Vec2 offset, int size, Rgba col)
{
	int off_x = (int)offset.x % size;
	int off_y = (int)offset.y % size;

	for (int x = off_x; x < self.width; x += size)
	{
		self.draw_line((Vec2) { (float)x, 0.0f }, (Vec2) { (float)x, (float)self.height }, col);
	}
	for (int y = off_y; y < self.height; y += size)
	{
		self.draw_line((Vec2) { 0.0f, (float)y }, (Vec2) { (float)self.width, (float)y }, col);
	}
}

// 3x5 Pixel Font Bitmap Map
fn ushort get_char_bitmap(char c)
{
	char uppercase = c;
	if (c >= 'a' && c <= 'z') uppercase -= 32;

	switch (uppercase)
	{
		case 'A': return 0b010_101_111_101_101;
		case 'B': return 0b110_101_110_101_110;
		case 'C': return 0b011_100_100_100_011;
		case 'D': return 0b110_101_101_101_110;
		case 'E': return 0b111_100_110_100_111;
		case 'F': return 0b111_100_110_100_100;
		case 'G': return 0b011_100_101_101_011;
		case 'H': return 0b101_101_111_101_101;
		case 'I': return 0b111_010_010_010_111;
		case 'J': return 0b001_001_001_101_010;
		case 'K': return 0b101_101_110_101_101;
		case 'L': return 0b100_100_100_100_111;
		case 'M': return 0b101_111_101_101_101;
		case 'N': return 0b111_101_101_101_101;
		case 'O': return 0b010_101_101_101_010;
		case 'P': return 0b110_101_110_100_100;
		case 'Q': return 0b010_101_101_110_011;
		case 'R': return 0b110_101_110_101_101;
		case 'S': return 0b011_100_010_001_110;
		case 'T': return 0b111_010_010_010_010;
		case 'U': return 0b101_101_101_101_011;
		case 'V': return 0b101_101_101_101_010;
		case 'W': return 0b101_101_101_111_101;
		case 'X': return 0b101_101_010_101_101;
		case 'Y': return 0b101_101_010_010_010;
		case 'Z': return 0b111_001_010_100_111;
		case '0': return 0b010_101_101_101_010;
		case '1': return 0b010_110_010_010_111;
		case '2': return 0b111_001_111_100_111;
		case '3': return 0b111_001_011_001_111;
		case '4': return 0b101_101_111_001_001;
		case '5': return 0b111_100_111_001_111;
		case '6': return 0b011_100_111_101_011;
		case '7': return 0b111_001_010_100_100;
		case '8': return 0b010_101_010_101_010;
		case '9': return 0b011_101_011_001_110;
		case ':': return 0b000_010_000_010_000;
		case '!': return 0b010_010_010_000_010;
		case '-': return 0b000_000_111_000_000;
		case ' ': return 0b000_000_000_000_000;
		default: return 0b000_000_000_000_000;
	}
}

fn void Canvas.draw_text(&self, int x, int y, String str, int scale, Rgba col)
{
	int cur_x = x;
	foreach (c : str)
	{
		ushort bits = get_char_bitmap(c);
		for (int row = 0; row < 5; row++)
		{
			for (int col_idx = 0; col_idx < 3; col_idx++)
			{
				int bit_pos = 14 - (row * 3 + col_idx);
				if ((bits & (1 << bit_pos)) != 0)
				{
					self.draw_rect((Rect) { cur_x + col_idx * scale, y + row * scale, scale, scale }, col);
				}
			}
		}
		cur_x += 4 * scale;
	}
}

fn void Canvas.draw_number(&self, int x, int y, int num, int scale, Rgba col)
{
	if (num == 0)
	{
		self.draw_text(x, y, "0", scale, col);
		return;
	}
	int temp         = num;
	int digits_count = 0;
	char[10] d;
	while (temp > 0 && digits_count < 10)
	{
		d[digits_count++] = (char)('0' + (temp % 10));
		temp /= 10;
	}
	int offset_x = x;
	for (int i = digits_count - 1; i >= 0; i--)
	{
		char[1] s = { d[i] };
		self.draw_text(offset_x, y, (String)s[..], scale, col);
		offset_x += 4 * scale;
	}
}

// --- Game Constants & State ---
enum GameState
{
	START,
	PLAYING,
	GAMEOVER
}

GameState game_state = START;

struct Player
{
	Vec2 pos;
	Vec2 vel;
	float angle;
	float hp;
	float max_hp;
	int weapon;
	float shoot_cooldown;
}

struct Bullet
{
	bool active;
	Vec2 pos;
	Vec2 vel;
	float radius;
	float life;
	Rgba color;
	bool is_enemy;
	float damage;
}

struct Enemy
{
	bool active;
	Vec2 pos;
	Vec2 vel;
	float hp;
	float max_hp;
	int type; // 0: Chaser, 1: Swarmer, 2: Brute
	float size;
	float shoot_cooldown;
	float anim_timer;
}

struct Particle
{
	bool active;
	Vec2 pos;
	Vec2 vel;
	float life;
	float max_life;
	float size;
	Rgba color;
}

const int MAX_BULLETS   = 128;
const int MAX_ENEMIES   = 48;
const int MAX_PARTICLES = 256;

Player player;
Bullet[MAX_BULLETS] bullets;
Enemy[MAX_ENEMIES] enemies;
Particle[MAX_PARTICLES] particles;

int score                = 0;
int wave                 = 1;
int enemies_left_in_wave = 0;
float wave_spawn_timer   = 0.0f;
float screen_shake       = 0.0f;
int frame_count          = 0;

Vec2 mouse_pos  = { 320.0f, 240.0f };
bool mouse_down = false;

// Audio SFX Timers
float sfx_laser     = 0.0f;
float sfx_explosion = 0.0f;

// --- Particle System ---
fn void spawn_particle(Vec2 pos, Vec2 vel, float life, float size, Rgba color)
{
	for (int i = 0; i < MAX_PARTICLES; i++)
	{
		if (!particles[i].active)
		{
			particles[i] = {
				.active = true,
				.pos = pos,
				.vel = vel,
				.life = life,
				.max_life = life,
				.size = size,
				.color = color
			};
			break;
		}
	}
}

fn void create_explosion(Vec2 pos, Rgba color, int count)
{
	sfx_explosion = 0.35f;
	screen_shake = math::clamp(screen_shake + (float)count * 0.15f, 0.0f, 12.0f);
	for (int i = 0; i < count; i++)
	{
		float angle = (float)rnd() * (float)math::TWO_PI;
		float speed = 30.0f + (float)rnd() * 220.0f;
		Vec2 vel    = { math::cos(angle) * speed, math::sin(angle) * speed };
		spawn_particle(pos, vel, 0.2f + (float)rnd() * 0.5f, 2.0f + (float)rnd() * 3.0f, color);
	}
}

// --- Game Reset & Spawning ---
fn void reset_game()
{
	player = {
		.pos = { 320.0f, 240.0f },
		.vel = { 0.0f, 0.0f },
		.angle = 0.0f,
		.hp = 100.0f,
		.max_hp = 100.0f,
		.weapon = 0,
		.shoot_cooldown = 0.0f
	};

	for (sz i = 0; i < bullets.len; i++) bullets[i].active = false;
	for (sz i = 0; i < enemies.len; i++) enemies[i].active = false;
	for (sz i = 0; i < particles.len; i++) particles[i].active = false;

	mouse_down = false;

	score = 0;
	wave = 1;
	enemies_left_in_wave = 6;
	wave_spawn_timer = 0.0f;
	game_state = PLAYING;
}

fn void spawn_enemy()
{
	int type   = 0;
	float roll = (float)rnd();
	if (wave >= 2 && roll > 0.6f) type = 1;
	if (wave >= 3 && roll > 0.85f) type = 2;

	Vec2 pos;
	if (rnd() < 0.5f)
	{
		pos.x = rnd() < 0.5f ? -20.0f : 660.0f;
		pos.y = (float)rnd() * 480.0f;
	}
	else
	{
		pos.x = (float)rnd() * 640.0f;
		pos.y = rnd() < 0.5f ? -20.0f : 500.0f;
	}

	float hp         = type == 2 ? 60.0f : (type == 1 ? 15.0f : 25.0f);
	float size       = type == 2 ? 14.0f : (type == 1 ? 7.0f : 9.0f);
	float wave_bonus = (float)wave * 3.0f;

	for (int i = 0; i < MAX_ENEMIES; i++)
	{
		if (!enemies[i].active)
		{
			enemies[i] = {
				.active = true,
				.pos = pos,
				.vel = { 0.0f, 0.0f },
				.hp = hp + wave_bonus,
				.max_hp = hp + wave_bonus,
				.type = type,
				.size = size,
				.shoot_cooldown = (float)rnd() * 2.0f,
				.anim_timer = (float)rnd() * 10.0f
			};
			break;
		}
	}
}

// --- Player Shooting Logic ---
fn void fire_weapon()
{
	if (player.shoot_cooldown > 0.0f) return;

	Vec2 dir  = mouse_pos - player.pos;
	float len = dir.length();
	if (len < 0.001f) return;
	dir /= len;

	sfx_laser = 0.12f;

	switch (player.weapon)
	{
		case 0: // Pulse Blaster
			player.shoot_cooldown = 0.12f;
			for (int i = 0; i < MAX_BULLETS; i++)
			{
				if (!bullets[i].active)
				{
					bullets[i] = {
						.active = true,
						.pos = player.pos + dir * 4.0f,
						.vel = dir * 550.0f,
						.radius = 3.0f,
						.life = 1.2f,
						.color = { 56, 189, 248, 255 },
						.is_enemy = false,
						.damage = 18.0f
					};
					break;
				}
			}

		case 1: // Plasma Spread
			player.shoot_cooldown = 0.28f;
			float[3] angles = { -0.22f, 0.0f, 0.22f };
			foreach (spread : angles)
			{
				float base_a    = math::atan2(dir.y, dir.x) + spread;
				Vec2 spread_dir = { math::cos(base_a), math::sin(base_a) };

				for (int i = 0; i < MAX_BULLETS; i++)
				{
					if (!bullets[i].active)
					{
						bullets[i] = {
							.active = true,
							.pos = player.pos + spread_dir * 4.0f,
							.vel = spread_dir * 460.0f,
							.radius = 2.5f,
							.life = 1.0f,
							.color = { 244, 63, 94, 255 },
							.is_enemy = false,
							.damage = 14.0f
						};
						break;
					}
				}
			}

		case 2: // Devastator Cannon
			player.shoot_cooldown = 0.55f;
			screen_shake += 2.5f;
			for (int i = 0; i < MAX_BULLETS; i++)
			{
				if (!bullets[i].active)
				{
					bullets[i] = {
						.active = true,
						.pos = player.pos + dir * 4.0f,
						.vel = dir * 320.0f,
						.radius = 7.0f,
						.life = 1.8f,
						.color = { 250, 204, 21, 255 },
						.is_enemy = false,
						.damage = 65.0f
					};
					break;
				}
			}
	}
}

// --- Frame Update and Render ---
fn void update_draw_frame()
{
	float dt   = rl::get_frame_time();
	int width  = 640;
	int height = 480;

	Rgba[] pixels   = ((Rgba*)canvas_image.data)[0..width * height];
	Canvas canvas   = { .pixels = pixels, .width = width, .height = height };
	Vec2 move_input = { 0.0f, 0.0f };

	// Input via Raylib
	RLVector2 rl_mouse = rl::get_mouse_position();
	$if env::WASM:
		float scale_x = (float)width / (float)rl::get_render_width();
		float scale_y = (float)height / (float)rl::get_render_height();
		mouse_pos = { rl_mouse.x * scale_x, rl_mouse.y * scale_y };
	$else
		mouse_pos = { rl_mouse.x, rl_mouse.y };
	$endif
	mouse_down = rl::is_mouse_button_down(RLMouseButton.LEFT);

	if (rl::is_mouse_button_pressed(RLMouseButton.LEFT) || rl::is_key_pressed(RLKeyboardKey.SPACE))
	{
		if (game_state == START || game_state == GAMEOVER) reset_game();
	}

	float wheel = rl::get_mouse_wheel_move();
	if (game_state == PLAYING)
	{
		if (wheel > 0) player.weapon = (player.weapon + 1) % 3;
		if (wheel < 0) player.weapon = (player.weapon + 2) % 3;
		if (rl::is_key_pressed(RLKeyboardKey.ONE)) player.weapon = 0;
		if (rl::is_key_pressed(RLKeyboardKey.TWO)) player.weapon = 1;
		if (rl::is_key_pressed(RLKeyboardKey.THREE)) player.weapon = 2;
	}

	// Update Timers & Shake
	sfx_laser = math::clamp(sfx_laser - dt, 0.0f, 1.0f);
	sfx_explosion = math::clamp(sfx_explosion - dt, 0.0f, 1.0f);
	screen_shake = math::clamp(screen_shake - dt * 10.0f, 0.0f, 20.0f);

	Vec2 shake_offset = { 0.0f, 0.0f };
	if (screen_shake > 0.05f)
	{
		shake_offset = { ((float)rnd() - 0.5f) * screen_shake, ((float)rnd() - 0.5f) * screen_shake };
	}

	// --- Gameplay Updates ---
	if (game_state == PLAYING)
	{
		// Player movement vector
		if (rl::is_key_down(RLKeyboardKey.W) || rl::is_key_down(RLKeyboardKey.UP)) move_input.y -= 1.0f;
		if (rl::is_key_down(RLKeyboardKey.S) || rl::is_key_down(RLKeyboardKey.DOWN)) move_input.y += 1.0f;
		if (rl::is_key_down(RLKeyboardKey.A) || rl::is_key_down(RLKeyboardKey.LEFT)) move_input.x -= 1.0f;
		if (rl::is_key_down(RLKeyboardKey.D) || rl::is_key_down(RLKeyboardKey.RIGHT)) move_input.x += 1.0f;

		if (move_input.length() > 0.001f)
		{
			move_input = move_input.normalize();
			player.vel += move_input * 1400.0f * dt;
		}

		player.vel *= 0.88f; // Friction
		player.pos += player.vel * dt;
		player.pos.x = math::clamp(player.pos.x, 12.0f, (float)width - 12.0f);
		player.pos.y = math::clamp(player.pos.y, 12.0f, (float)height - 12.0f);

		// Player Aim Angle
		Vec2 aim_dir = mouse_pos - player.pos;
		player.angle = math::atan2(aim_dir.y, aim_dir.x);

		// Shooting
		if (player.shoot_cooldown > 0.0f) player.shoot_cooldown -= dt;
		if (mouse_down) fire_weapon();

		// Wave Spawner
		if (enemies_left_in_wave > 0)
		{
			wave_spawn_timer -= dt;
			if (wave_spawn_timer <= 0.0f)
			{
				spawn_enemy();
				enemies_left_in_wave--;
				wave_spawn_timer = 0.4f + (float)rnd() * 0.6f;
			}
		}
		else
		{
			bool active_found = false;
			foreach (e : enemies)
			{
				if (e.active)
				{
					active_found = true;
					break;
				}
			}
			if (!active_found)
			{
				wave++;
				enemies_left_in_wave = 6 + wave * 4;
				player.hp = math::clamp(player.hp + 25.0f, 0.0f, player.max_hp);
			}
		}

		// Enemy Logic
		for (int i = 0; i < MAX_ENEMIES; i++)
		{
			if (!enemies[i].active) continue;
			enemies[i].anim_timer += dt * 3.0f;

			Vec2 to_player = player.pos - enemies[i].pos;
			float dist     = to_player.length();
			Vec2 dir       = dist > 0.001f ? to_player / dist : (Vec2) { 0.0f, 0.0f };

			switch (enemies[i].type)
			{
				case 0: // Chaser
					enemies[i].pos += dir * (110.0f + (float)wave * 5.0f) * dt;

				case 1: // Swarmer
					Vec2 perp = { -dir.y, dir.x };
					Vec2 swarmer_dir = dir + perp * math::sin(enemies[i].anim_timer) * 0.8f;
					enemies[i].pos += swarmer_dir.normalize() * (160.0f + (float)wave * 6.0f) * dt;

				case 2: // Brute
					if (dist > 140.0f) enemies[i].pos += dir * 65.0f * dt;
					enemies[i].shoot_cooldown -= dt;
					if (enemies[i].shoot_cooldown <= 0.0f)
					{
						enemies[i].shoot_cooldown = 1.8f;
						for (int b = 0; b < MAX_BULLETS; b++)
						{
							if (!bullets[b].active)
							{
								bullets[b] = {
									.active = true,
									.pos = enemies[i].pos,
									.vel = dir * 210.0f,
									.radius = 4.0f,
									.life = 3.0f,
									.color = { 245, 158, 11, 255 },
									.is_enemy = true,
									.damage = 15.0f
								};
								break;
							}
						}
					}
			}

			// Enemy vs Player collision & exact smooth radius separation
			float min_dist = enemies[i].size + 8.0f;
			if (dist < min_dist)
			{
				player.hp -= 20.0f * dt;
				screen_shake += 0.8f;

				float overlap = min_dist - dist;
				if (dist > 0.001f)
				{
					enemies[i].pos -= dir * overlap;
				}
				else
				{
					enemies[i].pos.x += min_dist;
				}

				if (player.hp <= 0.0f)
				{
					create_explosion(player.pos, { 56, 189, 248, 255 }, 40);
					game_state = GAMEOVER;
				}
			}

			// Enemy vs Enemy crowding separation
			for (int j = i + 1; j < MAX_ENEMIES; j++)
			{
				if (!enemies[j].active) continue;
				Vec2 sep_d     = enemies[j].pos - enemies[i].pos;
				float sep_dist = sep_d.length();
				float min_sep  = enemies[i].size + enemies[j].size;
				if (sep_dist < min_sep && sep_dist > 0.001f)
				{
					Vec2 sep_dir      = sep_d / sep_dist;
					float sep_overlap = (min_sep - sep_dist) * 0.5f;
					enemies[i].pos -= sep_dir * sep_overlap;
					enemies[j].pos += sep_dir * sep_overlap;
				}
			}
		}

		// Bullet Updates & Collision
		for (int i = 0; i < MAX_BULLETS; i++)
		{
			if (!bullets[i].active) continue;
			bullets[i].pos += bullets[i].vel * dt;
			bullets[i].life -= dt;

			if (bullets[i].life <= 0.0f || bullets[i].pos.x < 0.0f || bullets[i].pos.x > (float)width
				|| bullets[i].pos.y < 0.0f
				|| bullets[i].pos.y > (float)height)
			{
				bullets[i].active = false;
				continue;
			}

			// Bullet trails
			if (rnd() < 0.4f)
			{
				spawn_particle(bullets[i].pos, { 0.0f, 0.0f }, 0.1f, bullets[i].radius * 0.7f, bullets[i].color);
			}

			if (bullets[i].is_enemy)
			{
				// Enemy Bullet vs Player
				if ((bullets[i].pos - player.pos).length() < (bullets[i].radius + 8.0f))
				{
					bullets[i].active = false;
					player.hp -= bullets[i].damage;
					screen_shake += 2.0f;
					create_explosion(bullets[i].pos, { 245, 158, 11, 255 }, 8);
					if (player.hp <= 0.0f) game_state = GAMEOVER;
				}
			}
			else
			{
				// Player Bullet vs Enemy
				for (int e = 0; e < MAX_ENEMIES; e++)
				{
					if (!enemies[e].active) continue;
					if ((bullets[i].pos - enemies[e].pos).length() < (bullets[i].radius + enemies[e].size))
					{
						enemies[e].hp -= bullets[i].damage;
						bullets[i].active = false;

						// Hit spark
						spawn_particle(bullets[i].pos, bullets[i].vel * -0.2f, 0.15f, 3.0f, { 255, 255, 255, 255 });

						if (enemies[e].hp <= 0.0f)
						{
							enemies[e].active = false;
							score += (enemies[e].type + 1) * 100;
							Rgba exp_col = enemies[e].type == 2 ? (Rgba) { 245, 158, 11, 255 }
								: (enemies[e].type == 1 ? (Rgba) { 168, 85, 247, 255 } : (Rgba) { 239, 68, 68, 255 });
							create_explosion(enemies[e].pos, exp_col, 16 + enemies[e].type * 8);
						}
						break;
					}
				}
			}
		}

		// Particles
		for (int i = 0; i < MAX_PARTICLES; i++)
		{
			if (!particles[i].active) continue;
			particles[i].pos += particles[i].vel * dt;
			particles[i].life -= dt;
			if (particles[i].life <= 0.0f) particles[i].active = false;
		}
	}

	// --- RENDER PASS ---
	// Background Clear & Grid
	canvas.clear({ 10, 15, 26, 255 });
	canvas.draw_grid(shake_offset, 40, { 20, 30, 50, 255 });

	if (game_state == PLAYING)
	{
		// Particles
		foreach (p : particles)
		{
			if (!p.active) continue;
			canvas.draw_circle(p.pos + shake_offset, p.size, p.color);
		}

		// Bullets
		foreach (b : bullets)
		{
			if (!b.active) continue;
			canvas.draw_circle(b.pos + shake_offset, b.radius, b.color);
		}

		// Enemies
		foreach (e : enemies)
		{
			if (!e.active) continue;
			Vec2 e_pos = e.pos + shake_offset;
			Rgba e_col = e.type == 2 ? (Rgba) { 245, 158, 11, 255 }
				: (e.type == 1 ? (Rgba) { 168, 85, 247, 255 } : (Rgba) { 239, 68, 68, 255 });
			canvas.draw_circle(e_pos, e.size, e_col);

			// HP bar for Brutes
			if (e.type == 2)
			{
				float hp_ratio = math::clamp(e.hp / e.max_hp, 0.0f, 1.0f);
				canvas.draw_rect((Rect) { (int)e_pos.x - 12, (int)e_pos.y - 18, 24, 3 }, { 50, 50, 50, 255 });
				canvas.draw_rect((Rect) { (int)e_pos.x - 12, (int)e_pos.y - 18, (int)(24.0f * hp_ratio), 3 }, e_col);
			}
		}

		// Player Ship
		Vec2 p_pos = player.pos + shake_offset;
		Vec2 fwd   = { math::cos(player.angle), math::sin(player.angle) };
		Vec2 right = { -fwd.y, fwd.x };

		Vec2 p1 = p_pos + fwd * 12.0f;
		Vec2 p2 = p_pos - fwd * 8.0f + right * 7.0f;
		Vec2 p3 = p_pos - fwd * 8.0f - right * 7.0f;

		// Short static thruster fixed directly behind ship
		float flame_len = 5.0f + (float)rnd() * 3.0f;
		Vec2 flame_tip  = p_pos - fwd * (8.0f + flame_len);
		Vec2 flame_l    = p_pos - fwd * 8.0f + right * 2.5f;
		Vec2 flame_r    = p_pos - fwd * 8.0f - right * 2.5f;
		Rgba flame_col  = rnd() < 0.5f ? (Rgba) { 251, 146, 60, 255 } : (Rgba) { 250, 204, 21, 255 };
		canvas.draw_line(flame_l, flame_tip, flame_col);
		canvas.draw_line(flame_r, flame_tip, flame_col);

		// Ship Body
		Rgba p_col = { 56, 189, 248, 255 };
		canvas.draw_line(p1, p2, p_col);
		canvas.draw_line(p2, p3, p_col);
		canvas.draw_line(p3, p1, p_col);

		// Dotted Aim Line
		canvas.draw_line_dashed(p_pos, mouse_pos, { 60, 90, 120, 255 }, 4);
		canvas.draw_circle(mouse_pos, 4.0f, { 250, 204, 21, 255 });

		// --- HUD Overlay ---
		// Health Bar
		canvas.draw_rect((Rect) { 16, 16, 150, 10 }, { 30, 41, 59, 255 });
		float hp_pct = math::clamp(player.hp / player.max_hp, 0.0f, 1.0f);
		Rgba hp_col  = hp_pct > 0.5f ? (Rgba) { 52, 211, 153, 255 }
			: (hp_pct > 0.25f ? (Rgba) { 251, 191, 36, 255 } : (Rgba) { 244, 63, 94, 255 });
		canvas.draw_rect((Rect) { 16, 16, (int)(150.0f * hp_pct), 10 }, hp_col);

		// 3-Slot Weapon Selector HUD [1] [2] [3]
		Rgba[3] weapon_colors = {
			{ 56, 189, 248, 255 }, // Slot 1: Pulse (Cyan)
			{ 244, 63, 94, 255 }, // Slot 2: Spread (Magenta)
			{ 250, 204, 21, 255 } // Slot 3: Devastator (Yellow)
		};

		for (int slot = 0; slot < 3; slot++)
		{
			int slot_x = 16 + slot * 22;
			int slot_y = 32;

			if (player.weapon == slot)
			{
				// Active Weapon: Highlighted White Border + Bright Colored Core
				canvas.draw_rect((Rect) { slot_x - 1, slot_y - 1, 18, 18 }, { 255, 255, 255, 255 });
				canvas.draw_rect((Rect) { slot_x, slot_y, 16, 16 }, weapon_colors[slot]);
			}
			else
			{
				// Inactive Weapon: Dark Slot + Small Color Pip
				canvas.draw_rect((Rect) { slot_x, slot_y, 16, 16 }, { 30, 41, 59, 255 });
				canvas.draw_rect((Rect) { slot_x + 3, slot_y + 3, 10, 10 }, weapon_colors[slot]);
			}
		}

		// Score & Wave Text
		canvas.draw_number(width - 110, 16, score, 2, { 248, 250, 252, 255 });
		canvas.draw_number(width / 2 - 10, 16, wave, 3, { 56, 189, 248, 255 });
	}
	else if (game_state == START)
	{
		// Title Screen
		String title = "NEON OVERDRIVE";
		int title_x  = width / 2 - ((int)title.len * 4 * 3) / 2;
		canvas.draw_text(title_x, height / 2 - 45, title, 3, { 56, 189, 248, 255 });

		String subtitle = "CYBER ARENA";
		int sub_x       = width / 2 - ((int)subtitle.len * 4 * 2) / 2;
		canvas.draw_text(sub_x, height / 2 - 15, subtitle, 2, { 168, 85, 247, 255 });

		// Pulsing Click prompt
		if ((int)(frame_count * 0.1f) % 2 == 0)
		{
			String prompt = "CLICK TO START";
			int prompt_x  = width / 2 - ((int)prompt.len * 4 * 2) / 2;
			canvas.draw_text(prompt_x, height / 2 + 40, prompt, 2, { 250, 204, 21, 255 });
		}
	}
	else if (game_state == GAMEOVER)
	{
		// Game Over Screen
		String go_text = "GAME OVER";
		int go_x       = width / 2 - ((int)go_text.len * 4 * 4) / 2;
		canvas.draw_text(go_x, height / 2 - 60, go_text, 4, { 244, 63, 94, 255 });

		String score_lbl = "FINAL SCORE";
		int lbl_x        = width / 2 - ((int)score_lbl.len * 4 * 2) / 2;
		canvas.draw_text(lbl_x, height / 2, score_lbl, 2, { 148, 163, 184, 255 });

		canvas.draw_number(width / 2 - 20, height / 2 + 20, score, 3, { 248, 250, 252, 255 });

		if ((int)(frame_count * 0.1f) % 2 == 0)
		{
			String restart_prompt = "CLICK TO RESTART";
			int restart_x         = width / 2 - ((int)restart_prompt.len * 4 * 2) / 2;
			canvas.draw_text(restart_x, height / 2 + 65, restart_prompt, 2, { 56, 189, 248, 255 });
		}
	}

	frame_count++;

	canvas_texture.update(canvas_image.data);
	rl::begin_drawing();
	rl::clear_background(rl::BLACK);
	rl::draw_texture(canvas_texture, 0, 0, rl::WHITE);
	// rl::draw_fps(width - 80, 20);
	rl::end_drawing();
}

// --- Dynamic Synthwave Chiptune Audio Engine ---
float bass_phase = 0.0f;
float lead_phase = 0.0f;
int sample_count = 0;

const float[16] BASS_NOTES = {
	110.0f, 110.0f, 110.0f, 110.0f,
	130.81f, 130.81f, 130.81f, 130.81f,
	98.0f, 98.0f, 98.0f, 98.0f,
	87.31f, 87.31f, 87.31f, 87.31f
};

const float[16] LEAD_NOTES = {
	220.0f, 329.63f, 440.0f, 329.63f,
	261.63f, 392.00f, 523.25f, 392.00f,
	196.00f, 293.66f, 392.00f, 293.66f,
	174.61f, 261.63f, 349.23f, 261.63f
};

fn void audio_callback(void* buffer, uint frames)
{
	float* samples   = (float*)buffer;
	int step_samples = 5512; // 120 BPM 16th notes

	for (uint i = 0; i < frames; i++)
	{
		float out = 0.0f;

		if (game_state == PLAYING)
		{
			int step            = (sample_count / step_samples) % 16;
			float step_progress = (float)(sample_count % step_samples) / (float)step_samples;
			float env           = (1.0f - step_progress) * (1.0f - step_progress); // Exponential note pluck envelope
			sample_count++;

			bass_phase += BASS_NOTES[step] / 44100.0f;
			if (bass_phase > 1.0f) bass_phase -= 1.0f;

			lead_phase += LEAD_NOTES[step] / 44100.0f;
			if (lead_phase > 1.0f) lead_phase -= 1.0f;

			float bass_wave = (bass_phase < 0.4f ? 0.06f : -0.06f) * env;
			float lead_wave = math::sin(lead_phase * (float)math::TWO_PI) * env * 0.04f;

			out += bass_wave + lead_wave;

			// Laser SFX
			if (sfx_laser > 0.0f)
			{
				float laser_freq = 800.0f * (sfx_laser / 0.12f);
				out += math::sin((float)sample_count * laser_freq * 0.0001f) * 0.18f;
			}

			// Explosion SFX
			if (sfx_explosion > 0.0f)
			{
				out += ((float)rnd() * 2.0f - 1.0f) * 0.25f * (sfx_explosion / 0.35f);
			}
		}

		samples[i] = out;
	}
}

RLImage canvas_image;
RLTexture canvas_texture;
RLAudioStream audio_stream;

fn int main(String[] args) @winmain
{
	rl::init_window(640, 480, "NEON OVERDRIVE: CYBER ARENA - C3 & Raylib");
	rl::hide_cursor();
	rl::init_audio_device();

	canvas_image = rl::gen_image_color(640, 480, rl::BLACK);
	canvas_texture = rl::load_texture_from_image(canvas_image);

	audio_stream = rl::load_audio_stream(44100, 32, 1);
	audio_stream.set_callback(&audio_callback);
	rl::play_audio_stream(audio_stream);

	$if env::WASM:
		emscripten_set_main_loop(&update_draw_frame, 60, 1);
	$else
		rl::set_target_fps(60);
		while (!rl::window_should_close())
		{
			update_draw_frame();
		}
		rl::unload_audio_stream(audio_stream);
		rl::close_audio_device();
		rl::unload_texture(canvas_texture);
		rl::unload_image(canvas_image);
		rl::close_window();
	$endif

	return 0;
}

alias Em_callback_func = fn void();
extern fn void emscripten_set_main_loop(Em_callback_func func, int fps, int simulate_infinite_loop);