module main;

import std, raylib6;
import std::math::geometry;

alias Rgba = char[<4>];
alias IRect = Rectangle{int};

struct Canvas
{
	Rgba[] pixels;
	int width;
	int height;
}

const Rect SCREEN_BOUNDS = { 0.0f, 0.0f, 640.0f, 480.0f };
const Rect PLAY_BOUNDS   = { 12.0f, 12.0f, 616.0f, 456.0f };

const Rgba[3] ENEMY_COLORS = {
	{ 239, 68, 68, 255 },
	{ 168, 85, 247, 255 },
	{ 245, 158, 11, 255 }
};

const Rgba[3] WEAPON_COLORS = {
	{ 56, 189, 248, 255 },
	{ 244, 63, 94, 255 },
	{ 250, 204, 21, 255 }
};

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

fn void Canvas.draw_rect(&self, IRect r, Rgba col)
{
	int min_x = math::clamp(r.x, 0, self.width);
	int max_x = math::clamp(r.x + r.width, 0, self.width);
	int min_y = math::clamp(r.y, 0, self.height);
	int max_y = math::clamp(r.y + r.height, 0, self.height);
	int len   = max_x - min_x;
	if (len <= 0) return;

	for (int y = min_y; y < max_y; y++)
	{
		self.pixels[y * self.width + min_x : len] = col;
	}
}

fn void Canvas.draw_circle(&self, Vec2 center, float r, Rgba col)
{
	int min_x  = math::clamp((int)(center.x - r), 0, self.width);
	int max_x  = math::clamp((int)(center.x + r + 1.0f), 0, self.width);
	int min_y  = math::clamp((int)(center.y - r), 0, self.height);
	int max_y  = math::clamp((int)(center.y + r + 1.0f), 0, self.height);
	float r_sq = r * r;

	for (int y = min_y; y < max_y; y++)
	{
		float dy_sq = ((float)y - center.y) * ((float)y - center.y);
		int row = y * self.width;
		for (int x = min_x; x < max_x; x++)
		{
			float dx = (float)x - center.x;
			if (dx * dx + dy_sq <= r_sq)
			{
				self.pixels[row + x] = col;
			}
		}
	}
}

fn void Canvas.draw_line(&self, Vec2 start, Vec2 end, Rgba col)
{
	int x0  = (int)start.x;
	int y0  = (int)start.y;
	int x1  = (int)end.x;
	int y1  = (int)end.y;
	int dx  = math::abs(x1 - x0);
	int sx  = x0 < x1 ? 1 : -1;
	int dy  = -math::abs(y1 - y0);
	int sy  = y0 < y1 ? 1 : -1;
	int err = dx + dy;

	while (true)
	{
		self.draw_pixel(x0, y0, col);
		if (x0 == x1 && y0 == y1) break;
		int e2 = 2 * err;
		if (e2 >= dy) { err += dy; x0 += sx; }
		if (e2 <= dx) { err += dx; y0 += sy; }
	}
}

fn void Canvas.draw_line_dashed(&self, Vec2 start, Vec2 end, Rgba col, int dash_len)
{
	int x0   = (int)start.x;
	int y0   = (int)start.y;
	int x1   = (int)end.x;
	int y1   = (int)end.y;
	int dx   = math::abs(x1 - x0);
	int sx   = x0 < x1 ? 1 : -1;
	int dy   = -math::abs(y1 - y0);
	int sy   = y0 < y1 ? 1 : -1;
	int err  = dx + dy;
	int step = 0;

	while (true)
	{
		if ((step / dash_len) % 2 == 0) self.draw_pixel(x0, y0, col);
		step++;
		if (x0 == x1 && y0 == y1) break;
		int e2 = 2 * err;
		if (e2 >= dy) { err += dy; x0 += sx; }
		if (e2 <= dx) { err += dx; y0 += sy; }
	}
}

fn void Canvas.draw_grid(&self, Vec2 offset, int size, Rgba col)
{
	int off_x = (int)offset.x % size;
	int off_y = (int)offset.y % size;

	for (int x = off_x; x < self.width; x += size)
	{
		self.draw_line({ (float)x, 0.0f }, { (float)x, (float)self.height }, col);
	}
	for (int y = off_y; y < self.height; y += size)
	{
		self.draw_line({ 0.0f, (float)y }, { (float)self.width, (float)y }, col);
	}
}

fn ushort get_char_bitmap(char c)
{
	switch (c)
	{
		case 'a'..'z': return get_char_bitmap(c - 32);
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
		default:  return 0;
	}
}

fn void Canvas.draw_char(&self, int x, int y, char c, int scale, Rgba col)
{
	ushort bits = get_char_bitmap(c);
	for (int row = 0; row < 5; row++)
	{
		for (int col_idx = 0; col_idx < 3; col_idx++)
		{
			if ((bits & (1 << (14 - (row * 3 + col_idx)))) != 0)
			{
				self.draw_rect({ x + col_idx * scale, y + row * scale, scale, scale }, col);
			}
		}
	}
}

fn void Canvas.draw_text(&self, int x, int y, String str, int scale, Rgba col)
{
	foreach (i, c : str)
	{
		self.draw_char(x + (int)i * 4 * scale, y, c, scale, col);
	}
}

fn void Canvas.draw_centered_text(&self, int y, String str, int scale, Rgba col)
{
	self.draw_text(self.width / 2 - ((int)str.len * 4 * scale) / 2, y, str, scale, col);
}

fn void Canvas.draw_number(&self, int x, int y, int num, int scale, Rgba col)
{
	char[16] buf;
	int len  = 0;
	int temp = num;
	if (temp == 0) buf[len++] = '0';
	while (temp > 0 && len < buf.len)
	{
		buf[len++] = (char)('0' + (temp % 10));
		temp /= 10;
	}
	for (int i = len - 1; i >= 0; i--)
	{
		self.draw_char(x + (len - 1 - i) * 4 * scale, y, buf[i], scale, col);
	}
}

enum State : int { START, PLAYING, GAMEOVER }

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
	int type;
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

struct GameState
{
	State state;
	Player player;
	Bullet[MAX_BULLETS] bullets;
	Enemy[MAX_ENEMIES] enemies;
	Particle[MAX_PARTICLES] particles;
	int score;
	int wave;
	int enemies_left;
	float spawn_timer;
	float screen_shake;
	int frame_count;
	Vec2 mouse_pos;
	bool mouse_down;
	float sfx_laser;
	float sfx_explosion;
}

GameState g;

fn void GameState.reset(&self)
{
	*self = {
		.state        = PLAYING,
		.player       = { .pos = { 320.0f, 240.0f }, .hp = 100.0f, .max_hp = 100.0f },
		.wave         = 1,
		.enemies_left = 6
	};
}

fn void GameState.spawn_particle(&self, Vec2 pos, Vec2 vel, float life, float size, Rgba color)
{
	foreach (&p : self.particles)
	{
		if (!p.active)
		{
			*p = { .active = true, .pos = pos, .vel = vel, .life = life, .max_life = life, .size = size, .color = color };
			break;
		}
	}
}

fn void GameState.create_explosion(&self, Vec2 pos, Rgba color, int count)
{
	self.sfx_explosion = 0.35f;
	self.screen_shake  = math::clamp(self.screen_shake + (float)count * 0.15f, 0.0f, 12.0f);
	for (int i = 0; i < count; i++)
	{
		float a   = (float)rnd() * (float)math::TAU;
		float spd = 30.0f + (float)rnd() * 220.0f;
		self.spawn_particle(pos, { math::cos(a) * spd, math::sin(a) * spd }, 0.2f + (float)rnd() * 0.5f, 2.0f + (float)rnd() * 3.0f, color);
	}
}

fn void GameState.spawn_bullet(&self, Vec2 pos, Vec2 vel, float radius, float life, Rgba color, float damage, bool is_enemy = false)
{
	foreach (&b : self.bullets)
	{
		if (!b.active)
		{
			*b = { .active = true, .pos = pos, .vel = vel, .radius = radius, .life = life, .color = color, .damage = damage, .is_enemy = is_enemy };
			break;
		}
	}
}

fn void GameState.spawn_enemy(&self)
{
	int type   = 0;
	float roll = (float)rnd();
	if (self.wave >= 2 && roll > 0.6f) type = 1;
	if (self.wave >= 3 && roll > 0.85f) type = 2;

	Vec2 pos = (rnd() < 0.5f)
		? (Vec2) { rnd() < 0.5f ? -20.0f : 660.0f, (float)rnd() * 480.0f }
		: (Vec2) { (float)rnd() * 640.0f, rnd() < 0.5f ? -20.0f : 500.0f };

	float hp   = (type == 2 ? 60.0f : (type == 1 ? 15.0f : 25.0f)) + (float)self.wave * 3.0f;
	float size = type == 2 ? 14.0f : (type == 1 ? 7.0f : 9.0f);

	foreach (&e : self.enemies)
	{
		if (!e.active)
		{
			*e = {
				.active = true, .pos = pos, .hp = hp, .max_hp = hp, .type = type,
				.size = size, .shoot_cooldown = (float)rnd() * 2.0f, .anim_timer = (float)rnd() * 10.0f
			};
			break;
		}
	}
}

fn void GameState.fire_weapon(&self)
{
	if (self.player.shoot_cooldown > 0.0f) return;

	Vec2 dir  = (self.mouse_pos - self.player.pos).normalize();
	self.sfx_laser = 0.12f;

	switch (self.player.weapon)
	{
		case 0:
			self.player.shoot_cooldown = 0.12f;
			self.spawn_bullet(self.player.pos + dir * 4.0f, dir * 550.0f, 3.0f, 1.2f, WEAPON_COLORS[0], 18.0f);
		case 1:
			self.player.shoot_cooldown = 0.28f;
			float[3] angles = { -0.22f, 0.0f, 0.22f };
			foreach (spread : angles)
			{
				Vec2 s_dir = { math::cos(self.player.angle + spread), math::sin(self.player.angle + spread) };
				self.spawn_bullet(self.player.pos + s_dir * 4.0f, s_dir * 460.0f, 2.5f, 1.0f, WEAPON_COLORS[1], 14.0f);
			}
		case 2:
			self.player.shoot_cooldown = 0.55f;
			self.screen_shake += 2.5f;
			self.spawn_bullet(self.player.pos + dir * 4.0f, dir * 320.0f, 7.0f, 1.8f, WEAPON_COLORS[2], 65.0f);
	}
}

fn void update_draw_frame()
{
	float dt   = rl::get_frame_time();
	int width  = 640;
	int height = 480;

	Rgba[] pixels = ((Rgba*)canvas_image.data)[0..width * height];
	Canvas canvas = { .pixels = pixels, .width = width, .height = height };
	Vec2 move_input = { 0.0f, 0.0f };

	float sw = (float)rl::get_render_width();
	float sh = (float)rl::get_render_height();
	float s  = math::min(sw / 640.0f, sh / 480.0f);
	Vec2 offset = { (sw - 640.0f * s) * 0.5f, (sh - 480.0f * s) * 0.5f };

	RLVector2 rl_mouse = rl::get_mouse_position();
	g.mouse_pos = {
		(rl_mouse.x - offset.x) / s,
		(rl_mouse.y - offset.y) / s
	};
	g.mouse_down = rl::is_mouse_button_down(RLMouseButton.LEFT);

	if (rl::is_mouse_button_pressed(RLMouseButton.LEFT) || rl::is_key_pressed(RLKeyboardKey.SPACE))
	{
		switch (g.state)
		{
			case START:
			case GAMEOVER:
				g.reset();
			case PLAYING:
				break;
		}
	}

	switch (g.state)
	{
		case PLAYING:
			float wheel = rl::get_mouse_wheel_move();
			if (wheel > 0) g.player.weapon = (g.player.weapon + 1) % 3;
			if (wheel < 0) g.player.weapon = (g.player.weapon + 2) % 3;
			if (rl::is_key_pressed(RLKeyboardKey.ONE)) g.player.weapon = 0;
			if (rl::is_key_pressed(RLKeyboardKey.TWO)) g.player.weapon = 1;
			if (rl::is_key_pressed(RLKeyboardKey.THREE)) g.player.weapon = 2;

			if (rl::is_key_down(RLKeyboardKey.W) || rl::is_key_down(RLKeyboardKey.UP)) move_input.y -= 1.0f;
			if (rl::is_key_down(RLKeyboardKey.S) || rl::is_key_down(RLKeyboardKey.DOWN)) move_input.y += 1.0f;
			if (rl::is_key_down(RLKeyboardKey.A) || rl::is_key_down(RLKeyboardKey.LEFT)) move_input.x -= 1.0f;
			if (rl::is_key_down(RLKeyboardKey.D) || rl::is_key_down(RLKeyboardKey.RIGHT)) move_input.x += 1.0f;

			g.sfx_laser     = math::clamp(g.sfx_laser - dt, 0.0f, 1.0f);
			g.sfx_explosion = math::clamp(g.sfx_explosion - dt, 0.0f, 1.0f);
			g.screen_shake  = math::clamp(g.screen_shake - dt * 10.0f, 0.0f, 20.0f);

			if (move_input.length_sq() > 0.001f)
			{
				g.player.vel += move_input.normalize() * 1400.0f * dt;
			}

			g.player.vel *= 0.88f;
			g.player.pos += g.player.vel * dt;
			g.player.pos  = PLAY_BOUNDS.clamp_point(g.player.pos);

			Vec2 aim_dir = g.mouse_pos - g.player.pos;
			g.player.angle = math::atan2(aim_dir.y, aim_dir.x);

			if (g.player.shoot_cooldown > 0.0f) g.player.shoot_cooldown -= dt;
			if (g.mouse_down) g.fire_weapon();

			if (g.enemies_left > 0)
			{
				g.spawn_timer -= dt;
				if (g.spawn_timer <= 0.0f)
				{
					g.spawn_enemy();
					g.enemies_left--;
					g.spawn_timer = 0.4f + (float)rnd() * 0.6f;
				}
			}
			else
			{
				bool active_found = false;
				foreach (e : g.enemies)
				{
					if (e.active) { active_found = true; break; }
				}
				if (!active_found)
				{
					g.wave++;
					g.enemies_left = 6 + g.wave * 4;
					g.player.hp = math::clamp(g.player.hp + 25.0f, 0.0f, g.player.max_hp);
				}
			}

			for (int i = 0; i < MAX_ENEMIES; i++)
			{
				if (!g.enemies[i].active) continue;
				g.enemies[i].anim_timer += dt * 3.0f;

				Vec2 to_player = g.player.pos - g.enemies[i].pos;
				float dist = to_player.length();
				Vec2 dir = dist > 0.001f ? to_player / dist : (Vec2) { 0.0f, 0.0f };

				switch (g.enemies[i].type)
				{
					case 0:
						g.enemies[i].pos += dir * (110.0f + (float)g.wave * 5.0f) * dt;
					case 1:
						Vec2 swarmer_dir = dir + (Vec2) { -dir.y, dir.x } * math::sin(g.enemies[i].anim_timer) * 0.8f;
						g.enemies[i].pos += swarmer_dir.normalize() * (160.0f + (float)g.wave * 6.0f) * dt;
					case 2:
						if (dist > 140.0f) g.enemies[i].pos += dir * 65.0f * dt;
						g.enemies[i].shoot_cooldown -= dt;
						if (g.enemies[i].shoot_cooldown <= 0.0f)
						{
							g.enemies[i].shoot_cooldown = 1.8f;
							g.spawn_bullet(g.enemies[i].pos, dir * 210.0f, 4.0f, 3.0f, ENEMY_COLORS[2], 15.0f, is_enemy: true);
						}
				}

				float min_dist = g.enemies[i].size + 8.0f;
				if (dist < min_dist)
				{
					g.player.hp -= 20.0f * dt;
					g.screen_shake += 0.8f;
					g.enemies[i].pos -= (dist > 0.001f ? dir : (Vec2) { 1.0f, 0.0f }) * (min_dist - dist);

					if (g.player.hp <= 0.0f)
					{
						g.create_explosion(g.player.pos, { 56, 189, 248, 255 }, 40);
						g.state = GAMEOVER;
					}
				}

				foreach (&other : g.enemies[i + 1..])
				{
					if (!other.active) continue;
					Vec2 sep_d = other.pos - g.enemies[i].pos;
					float sep_dist = sep_d.length();
					float min_sep = g.enemies[i].size + other.size;
					if (sep_dist < min_sep && sep_dist > 0.001f)
					{
						Vec2 shift = (sep_d / sep_dist) * ((min_sep - sep_dist) * 0.5f);
						g.enemies[i].pos -= shift;
						other.pos += shift;
					}
				}
			}

			foreach (&b : g.bullets)
			{
				if (!b.active) continue;
				b.pos += b.vel * dt;
				b.life -= dt;

				if (b.life <= 0.0f || !SCREEN_BOUNDS.contains_point(b.pos))
				{
					b.active = false;
					continue;
				}

				if (rnd() < 0.4f) g.spawn_particle(b.pos, { 0.0f, 0.0f }, 0.1f, b.radius * 0.7f, b.color);

				if (b.is_enemy)
				{
					if ((b.pos - g.player.pos).length_sq() < (b.radius + 8.0f) * (b.radius + 8.0f))
					{
						b.active = false;
						g.player.hp -= b.damage;
						g.screen_shake += 2.0f;
						g.create_explosion(b.pos, { 245, 158, 11, 255 }, 8);
						if (g.player.hp <= 0.0f) g.state = GAMEOVER;
					}
				}
				else
				{
					foreach (&e : g.enemies)
					{
						if (!e.active) continue;
						float hit_r = b.radius + e.size;
						if ((b.pos - e.pos).length_sq() < hit_r * hit_r)
						{
							e.hp -= b.damage;
							b.active = false;
							g.spawn_particle(b.pos, b.vel * -0.2f, 0.15f, 3.0f, { 255, 255, 255, 255 });

							if (e.hp <= 0.0f)
							{
								e.active = false;
								g.score += (e.type + 1) * 100;
								g.create_explosion(e.pos, ENEMY_COLORS[e.type], 16 + e.type * 8);
							}
							break;
						}
					}
				}
			}

			foreach (&p : g.particles)
			{
				if (!p.active) continue;
				p.pos += p.vel * dt;
				p.life -= dt;
				if (p.life <= 0.0f) p.active = false;
			}
		default:
			break;
	}

	Vec2 shake_offset = (g.screen_shake > 0.05f)
		? (Vec2) { ((float)rnd() - 0.5f) * g.screen_shake, ((float)rnd() - 0.5f) * g.screen_shake }
		: (Vec2) { 0.0f, 0.0f };

	canvas.clear({ 10, 15, 26, 255 });
	canvas.draw_grid(shake_offset, 40, { 20, 30, 50, 255 });

	switch (g.state)
	{
		case PLAYING:
			foreach (p : g.particles)
			{
				if (p.active) canvas.draw_circle(p.pos + shake_offset, p.size, p.color);
			}
			foreach (b : g.bullets)
			{
				if (b.active) canvas.draw_circle(b.pos + shake_offset, b.radius, b.color);
			}

			foreach (e : g.enemies)
			{
				if (!e.active) continue;
				Vec2 e_pos = e.pos + shake_offset;
				canvas.draw_circle(e_pos, e.size, ENEMY_COLORS[e.type]);

				if (e.type == 2)
				{
					float hp_ratio = math::clamp(e.hp / e.max_hp, 0.0f, 1.0f);
					canvas.draw_rect({ (int)e_pos.x - 12, (int)e_pos.y - 18, 24, 3 }, { 50, 50, 50, 255 });
					canvas.draw_rect({ (int)e_pos.x - 12, (int)e_pos.y - 18, (int)(24.0f * hp_ratio), 3 }, ENEMY_COLORS[2]);
				}
			}

			Vec2 p_pos = g.player.pos + shake_offset;
			Vec2 fwd   = { math::cos(g.player.angle), math::sin(g.player.angle) };
			Vec2 right = { -fwd.y, fwd.x };

			Vec2 p1 = p_pos + fwd * 12.0f;
			Vec2 p2 = p_pos - fwd * 8.0f + right * 7.0f;
			Vec2 p3 = p_pos - fwd * 8.0f - right * 7.0f;

			float flame_len = 5.0f + (float)rnd() * 3.0f;
			Rgba flame_col  = rnd() < 0.5f ? (Rgba) { 251, 146, 60, 255 } : (Rgba) { 250, 204, 21, 255 };
			canvas.draw_line(p_pos - fwd * 8.0f + right * 2.5f, p_pos - fwd * (8.0f + flame_len), flame_col);
			canvas.draw_line(p_pos - fwd * 8.0f - right * 2.5f, p_pos - fwd * (8.0f + flame_len), flame_col);

			Rgba p_col = { 56, 189, 248, 255 };
			canvas.draw_line(p1, p2, p_col);
			canvas.draw_line(p2, p3, p_col);
			canvas.draw_line(p3, p1, p_col);

			canvas.draw_line_dashed(p_pos, g.mouse_pos, { 60, 90, 120, 255 }, 4);
			canvas.draw_circle(g.mouse_pos, 4.0f, { 250, 204, 21, 255 });

			canvas.draw_rect({ 16, 16, 150, 10 }, { 30, 41, 59, 255 });
			float hp_pct = math::clamp(g.player.hp / g.player.max_hp, 0.0f, 1.0f);
			Rgba hp_col  = hp_pct > 0.5f ? (Rgba) { 52, 211, 153, 255 }
				: (hp_pct > 0.25f ? (Rgba) { 251, 191, 36, 255 } : (Rgba) { 244, 63, 94, 255 });
			canvas.draw_rect({ 16, 16, (int)(150.0f * hp_pct), 10 }, hp_col);

			for (int slot = 0; slot < 3; slot++)
			{
				int slot_x = 16 + slot * 22;
				if (g.player.weapon == slot)
				{
					canvas.draw_rect({ slot_x - 1, 31, 18, 18 }, { 255, 255, 255, 255 });
					canvas.draw_rect({ slot_x, 32, 16, 16 }, WEAPON_COLORS[slot]);
				}
				else
				{
					canvas.draw_rect({ slot_x, 32, 16, 16 }, { 30, 41, 59, 255 });
					canvas.draw_rect({ slot_x + 3, 35, 10, 10 }, WEAPON_COLORS[slot]);
				}
			}

			canvas.draw_number(width - 110, 16, g.score, 2, { 248, 250, 252, 255 });
			canvas.draw_number(width / 2 - 10, 16, g.wave, 3, { 56, 189, 248, 255 });

		case START:
			canvas.draw_centered_text(height / 2 - 45, "NEON OVERDRIVE", 3, { 56, 189, 248, 255 });
			canvas.draw_centered_text(height / 2 - 15, "CYBER ARENA", 2, { 168, 85, 247, 255 });
			if ((int)(g.frame_count * 0.1f) % 2 == 0)
			{
				canvas.draw_centered_text(height / 2 + 40, "CLICK OR SPACE TO START", 2, { 250, 204, 21, 255 });
			}

		case GAMEOVER:
			canvas.draw_centered_text(height / 2 - 60, "GAME OVER", 4, { 244, 63, 94, 255 });
			canvas.draw_centered_text(height / 2, "FINAL SCORE", 2, { 148, 163, 184, 255 });
			canvas.draw_number(width / 2 - 20, height / 2 + 20, g.score, 3, { 248, 250, 252, 255 });
			if ((int)(g.frame_count * 0.1f) % 2 == 0)
			{
				canvas.draw_centered_text(height / 2 + 65, "CLICK OR SPACE TO RESTART", 2, { 56, 189, 248, 255 });
			}
	}

	g.frame_count++;

	canvas_texture.update(canvas_image.data);
	rl::@drawing()
	{
		rl::clear_background(rl::BLACK);
		rl::draw_texture_pro(
			canvas_texture,
			{ 0.0f, 0.0f, 640.0f, 480.0f },
			{ offset.x, offset.y, 640.0f * s, 480.0f * s },
			{ 0.0f, 0.0f }, 0.0f, rl::WHITE
		);
	};
}

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
	float* samples = (float*)buffer;

	if (g.state != PLAYING)
	{
		samples[0..frames] = 0.0f;
		return;
	}

	int step_samples = 5512;

	for (uint i = 0; i < frames; i++)
	{
		int step        = (sample_count / step_samples) % 16;
		float step_prog = (float)(sample_count % step_samples) / (float)step_samples;
		float env       = (1.0f - step_prog) * (1.0f - step_prog);
		sample_count++;

		bass_phase += BASS_NOTES[step] / 44100.0f;
		if (bass_phase > 1.0f) bass_phase -= 1.0f;

		lead_phase += LEAD_NOTES[step] / 44100.0f;
		if (lead_phase > 1.0f) lead_phase -= 1.0f;

		float out = ((bass_phase < 0.4f ? 0.06f : -0.06f) + math::sin(lead_phase * (float)math::TAU) * 0.04f) * env;

		if (g.sfx_laser > 0.0f)
		{
			out += math::sin((float)sample_count * (800.0f * g.sfx_laser / 0.12f) * 0.0001f) * 0.18f;
		}

		if (g.sfx_explosion > 0.0f)
		{
			out += ((float)rnd() * 2.0f - 1.0f) * 0.25f * (g.sfx_explosion / 0.35f);
		}

		samples[i] = out;
	}
}

RLImage canvas_image;
RLTexture canvas_texture;
RLAudioStream audio_stream;

fn int main(String[] args) @winmain
{
	rl::set_config_flags(WINDOW_RESIZABLE);
	rl::init_window(640, 480, "NEON OVERDRIVE: CYBER ARENA - C3 & Raylib");
	rl::hide_cursor();
	rl::init_audio_device();

	canvas_image   = rl::gen_image_color(640, 480, rl::BLACK);
	canvas_texture = rl::load_texture_from_image(canvas_image);

	audio_stream = rl::load_audio_stream(44100, 32, 1);
	audio_stream.set_callback(&audio_callback);
	rl::play_audio_stream(audio_stream);

	$if env::WASM:
		emscripten_set_main_loop(&update_draw_frame, 60, 1);
	$else
		rl::set_target_fps(60);
		while (!rl::window_should_close()) update_draw_frame();
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