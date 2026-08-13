module main;
import std;

alias Rgba = char[<4>];

int frame_count = 0;

fn Rgba* update_canvas(int width, int height) @export("update_canvas")
{
	static Rgba[] pixels;
	if (pixels.len < width * height) pixels = mem::new_array(Rgba, width * height);

	frame_count++;
	Vec2 center = { width * 0.5f, height * 0.5f };

	for (int y = 0; y < height; y++)
	{
		for (int x = 0; x < width; x++)
		{
			Vec2 pos = { x, y } - center;
			float d  = pos.length();

			Vec4 waves = {
				math::sin(pos.x * 0.05f + frame_count * 0.05f) + math::sin(d * 0.05f),
				math::cos(pos.y * 0.05f - frame_count * 0.03f) + math::cos(d * 0.05f),
				math::sin((pos.x + pos.y) * 0.03f + d * 0.04f),
				2.0f
			};

			pixels[y * width + x] = (Rgba)(waves * 63.75f + 127.5f).bgra;
		}
	}
	return pixels;
}

fn int main()
{
	io::printn("Psychedelic Vector Vortex Initialized!");
	io::printn("Rendering with C3 SIMD vectors and standard library math directly in WASM.");
	return 0;
}
