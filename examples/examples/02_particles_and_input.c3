module main;

import std, raylib6;

struct Particle
{
	Vec2 pos;
	Vec2 vel;
	float life;
	RLColor color;
}

const int SCREEN_WIDTH  = 640;
const int SCREEN_HEIGHT = 480;
const int MAX_PARTICLES = 512;

Particle[MAX_PARTICLES] particles;
int particle_count = 0;

Vec2 player_pos = { 320, 240 };

fn void spawn_particles(Vec2 pos, int count)
{
	for (int i = 0; i < count; i++)
	{
		if (particle_count >= MAX_PARTICLES) return;
		float angle = (float)rnd() * math::TAU;
		float speed = 40.0f + (float)rnd() * 160.0f;
		particles[particle_count++] = {
			.pos = pos,
			.vel = { math::cos(angle) * speed, math::sin(angle) * speed },
			.life = 1.0f,
			.color = (RLColor) { (char)(100 + rnd() * 155), (char)(150 + rnd() * 105), 255, 255 }
		};
	}
}

fn void update_draw_frame()
{
	float dt = rl::get_frame_time();

	// 1. Movement
	Vec2 dir = { 0, 0 };
	if (rl::is_key_down(W) || rl::is_key_down(UP)) dir.y--;
	if (rl::is_key_down(S) || rl::is_key_down(DOWN)) dir.y++;
	if (rl::is_key_down(A) || rl::is_key_down(LEFT)) dir.x--;
	if (rl::is_key_down(D) || rl::is_key_down(RIGHT)) dir.x++;

	player_pos += dir * (220.0f * dt);
	player_pos.x = math::clamp(player_pos.x, 15.0f, (float)SCREEN_WIDTH - 15.0f);
	player_pos.y = math::clamp(player_pos.y, 15.0f, (float)SCREEN_HEIGHT - 15.0f);

	// 2. Spawning
	Vec2 mouse_pos = rl::get_mouse_position();
	if (rl::is_mouse_button_down(LEFT)) spawn_particles(mouse_pos, 4);
	if (rl::is_key_pressed(SPACE) || rl::get_mouse_wheel_move() != 0) spawn_particles(player_pos, 32);

	// 3. Update Particles
	int active = 0;
	for (int i = 0; i < particle_count; i++)
	{
		particles[i].pos += particles[i].vel * dt;
		particles[i].life -= 1.2f * dt;

		if (particles[i].life > 0)
		{
			particles[active++] = particles[i];
		}
	}
	particle_count = active;

	// 4. Render
	rl::@drawing()
	{
		rl::clear_background((RLColor) { 15, 23, 42, 255 });

		// Particles
		for (int i = 0; i < particle_count; i++)
		{
			RLColor c = particles[i].color;
			c.a = (char)(particles[i].life * 255.0f);
			rl::draw_circle((int)particles[i].pos.x, (int)particles[i].pos.y, 3.0f * particles[i].life, c);
		}

		// Player & Cursor
		rl::draw_rectangle((int)player_pos.x - 10, (int)player_pos.y - 10, 20, 20, (RLColor) { 56, 189, 248, 255 });
		RLColor cursor_col = rl::is_mouse_button_down(LEFT) ? (RLColor) { 244, 63, 94, 255 }
			: (RLColor) { 250, 204, 21, 255 };
		rl::draw_circle((int)mouse_pos.x, (int)mouse_pos.y, 6.0f, cursor_col);

		// Overlay
		rl::draw_text("WASD/Arrows to Move  |  Click/Drag to Spawn  |  SPACE to Burst", 20, 20, 18, rl::RAYWHITE);
		// rl::draw_fps(SCREEN_WIDTH - 80, 20);
	};
}

fn int main(String[] args) @winmain
{
	rl::init_window(SCREEN_WIDTH, SCREEN_HEIGHT, "Interactive Particles - C3 & Raylib");
	rl::hide_cursor();

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