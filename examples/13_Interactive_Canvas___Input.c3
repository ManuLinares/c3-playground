module main;
import std;

alias Rgba = char[<4>];

enum EventKind : char
{
	NONE,
	MOUSE_MOVE,
	MOUSE_DOWN,
	MOUSE_UP,
	MOUSE_WHEEL,
	KEY_DOWN,
	KEY_UP,
	CHAR_INPUT
}

struct Event
{
	EventKind kind;
	Vec2 mouse_pos;
	float wheel;
	int mouse_button;
	int key;
	Char32 character;
}

const int KEY_RIGHT = 262;
const int KEY_LEFT  = 263;
const int KEY_DOWN  = 264;
const int KEY_UP    = 265;

struct Particle
{
	Vec2 pos;
	Vec2 vel;
	float life;
	Rgba color;
}

const int MAX_PARTICLES = 256;
Particle[MAX_PARTICLES] particles;
int particle_count      = 0;

Vec2 player_pos    = { 320.0f, 240.0f };
Vec2 player_vel    = { 0.0f, 0.0f };
Vec2 mouse_pos     = { 320.0f, 240.0f };
bool is_mouse_down = false;

fn void spawn_particle(Vec2 pos)
{
	if (particle_count >= MAX_PARTICLES) return;
	float angle = (float)rnd() * (float)math::TWO_PI;
	float speed = 40.0f + (float)rnd() * 160.0f;
	particles[particle_count++] = {
		.pos = pos,
		.vel = { math::cos(angle) * speed, math::sin(angle) * speed },
		.life = 1.0f,
		.color = { (char)(100 + rnd() * 155), (char)(150 + rnd() * 105), 255, 255 }
	};
}

fn Rgba* update_canvas(int width, int height, float dt, Event[] events) @export("update_canvas")
{
	static Rgba[] pixels;
	if (pixels.len < width * height) pixels = mem::new_array(Rgba, width * height);

	foreach (event : events)
	{
		switch (event.kind)
		{
			case MOUSE_MOVE:
				mouse_pos = event.mouse_pos;
				if (is_mouse_down) spawn_particle(mouse_pos);

			case MOUSE_DOWN:
				is_mouse_down = true;
				mouse_pos = event.mouse_pos;
				for (int i = 0; i < 16; i++) spawn_particle(mouse_pos);

			case MOUSE_UP:
				is_mouse_down = false;

			case MOUSE_WHEEL:
				mouse_pos = event.mouse_pos;
				for (int i = 0; i < 8; i++) spawn_particle(mouse_pos);

			case KEY_DOWN:
				if (event.key == 'W' || event.key == 'w' || event.key == KEY_UP)    player_vel.y = -200.0f;
				if (event.key == 'S' || event.key == 's' || event.key == KEY_DOWN)  player_vel.y = 200.0f;
				if (event.key == 'A' || event.key == 'a' || event.key == KEY_LEFT)  player_vel.x = -200.0f;
				if (event.key == 'D' || event.key == 'd' || event.key == KEY_RIGHT) player_vel.x = 200.0f;
				if (event.key == ' ')
				{
					// Spacebar
					for (int i = 0; i < 32; i++) spawn_particle(player_pos);
				}

			case KEY_UP:
				if (event.key == 'W' || event.key == 'w' || event.key == KEY_UP || event.key == 'S' || event.key == 's'
					|| event.key == KEY_DOWN) player_vel.y = 0.0f;
				if (event.key == 'A' || event.key == 'a' || event.key == KEY_LEFT || event.key == 'D' || event.key == 'd'
					|| event.key == KEY_RIGHT) player_vel.x = 0.0f;

			default: break;
		}
	}

	player_pos += player_vel * dt;
	player_pos.x = math::clamp(player_pos.x, 10.0f, (float)width - 10.0f);
	player_pos.y = math::clamp(player_pos.y, 10.0f, (float)height - 10.0f);

	pixels[..] = (Rgba) { 15, 23, 42, 255 };

	int active_idx = 0;
	for (int i = 0; i < particle_count; i++)
	{
		particles[i].pos += particles[i].vel * dt;
		particles[i].life -= 1.2f * dt;

		if (particles[i].life > 0.0f)
		{
			int px = (int)particles[i].pos.x;
			int py = (int)particles[i].pos.y;
			if (px >= 0 && px < width && py >= 0 && py < height)
			{
				Rgba col = particles[i].color;
				col.w = (char)(particles[i].life * 255.0f);
				pixels[py * width + px] = col;
			}
			particles[active_idx++] = particles[i];
		}
	}
	particle_count = active_idx;

	int px = (int)player_pos.x;
	int py = (int)player_pos.y;
	for (int dy = -8; dy <= 8; dy++)
	{
		for (int dx = -8; dx <= 8; dx++)
		{
			int ix = px + dx;
			int iy = py + dy;
			if (ix >= 0 && ix < width && iy >= 0 && iy < height)
			{
				pixels[iy * width + ix] = { 56, 189, 248, 255 };
			}
		}
	}

	int mx          = (int)mouse_pos.x;
	int my          = (int)mouse_pos.y;
	Rgba cursor_col = is_mouse_down ? (Rgba) { 244, 63, 94, 255 } : (Rgba) { 250, 204, 21, 255 };
	for (int dy = -4; dy <= 4; dy++)
	{
		for (int dx = -4; dx <= 4; dx++)
		{
			if (dx * dx + dy * dy <= 16)
			{
				int ix = mx + dx;
				int iy = my + dy;
				if (ix >= 0 && ix < width && iy >= 0 && iy < height)
				{
					pixels[iy * width + ix] = cursor_col;
				}
			}
		}
	}

	return pixels;
}

fn int main()
{
	io::printn("Interactive Canvas Engine Active!");
	io::printn("Controls: Move with WASD or Arrow Keys.");
	io::printn("Click/Drag mouse to spawn particles! Scroll wheel or Spacebar explodes particles.");
	return 0;
}
