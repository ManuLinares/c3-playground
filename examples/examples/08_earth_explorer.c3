// @asset: https://raw.githubusercontent.com/ManuLinares/c3-earth/refs/heads/master/resources/img/earth.png  -> resources/img/earth.png
// @asset: https://raw.githubusercontent.com/ManuLinares/c3-earth/refs/heads/master/resources/img/starmap.png -> resources/img/starmap.png
module main;

import std, raylib6;

const String EARTH_TEXTURE   = "resources/img/earth.png";
const String STARMAP_TEXTURE = "resources/img/starmap.png";
// Downloaded from https://www.solarsystemscope.com/textures

// C3 enums can carry associated data. Each variant here holds a latitude, longitude, and a name.
enum City : int (float lat, float lon, ZString name)
{
	SALA         { 59.9f,   16.5f,  "Sala, Sweden" },
	BUENOS_AIRES { -34.6f, -58.4f,  "Buenos Aires" },
	TOKYO        { 35.7f,   139.7f, "Tokyo" },
	DELHI        { 28.6f,   77.2f,  "Delhi" },
	SHANGHAI     { 31.2f,   121.5f, "Shanghai" },
	SAO_PAULO    { -23.5f, -46.6f,  "Sao Paulo" },
	MEXICO       { 19.4f,  -99.1f,  "Mexico City" },
	CAIRO        { 30.0f,   31.2f,  "Cairo" },
	MUMBAI       { 19.1f,   72.9f,  "Mumbai" },
}

// C3's 'constdef' defines typed constants. Unlike standard C3 enums (which must be
// strictly sequential starting from 0), constdefs allow arbitrary values and gaps.
constdef Ui : inline int
{
	MARGIN      = 20,
	FONT_SIZE   = 20,
	LIST_OFFSET = 55,
	LINE_HEIGHT = 25
}

const float EARTH_RADIUS            =  3.0f;
const float CAMERA_SETTLE_THRESHOLD =  0.5f * rl::DEG2RAD;
const float CAMERA_LERP_SPEED       =  10.0f;
const float CAMERA_ZOOM_SPEED       =  10.0f;
const float CAMERA_ANIM_DURATION    =  1.0f;
const float SUN_GEO_ADJUSTMENT      = -15.0f * rl::DEG2RAD; // 15 degrees = 1 hour of Earth rotation

// Represents the camera's position orbiting around the earth
struct SphericalCoord
{
	float yaw;
	float pitch;
	float radius;
}

// The state of our camera. We keep track of a target and current coordinate
// for smooth interpolation (lerping) and handle mouse drag velocity.
struct GlobeCamera
{
	SphericalCoord target;
	SphericalCoord current;
	SphericalCoord start;
	RLCamera3D camera_3d;
	bool dragging;
	float anim_timer;
	Vec2 vel;
}

// C3 allows attaching methods to structs using the `StructName.method_name` syntax.
// The first parameter is a pointer to the struct, named `self` by convention.
fn void GlobeCamera.init(&self)
{
	SphericalCoord initial_pos = { .yaw = math::HALF_PI - (-30.0f * rl::DEG2RAD), .pitch = 20.0f * rl::DEG2RAD, .radius = 12.0f };

	// We use designated initializers (the dot syntax) to cleanly set up the struct fields
	*self = {
		.target = initial_pos,
		.current = initial_pos,
		.camera_3d = { .up = { 0, 1, 0 }, .fovy = 45, .projection = PERSPECTIVE },
		.anim_timer = CAMERA_ANIM_DURATION,
		.vel = { 0, 0 }
	};
}

// The main update loop for the camera, called every frame
fn void GlobeCamera.update(&self, float dt)
{
	// 1. Handle zooming via mouse wheel
	float wheel = math::sign((int)rl::get_mouse_wheel_move());

	if (wheel)
	{
		self.target.radius = math::clamp(self.target.radius - wheel * self.target.radius * 0.1f, 3.5f, 40.0f);
	}
	self.current.radius += (self.target.radius - self.current.radius) * CAMERA_ZOOM_SPEED * dt;

	// 2. Check if we clicked on the Earth (Raycasting)
	if (rl::is_mouse_button_pressed(LEFT))
	{
		RLRay ray = rl::get_screen_to_world_ray(rl::get_mouse_position(), self.camera_3d);
		if (ray.get_collision_sphere({ 0, 0, 0 }, EARTH_RADIUS).hit)
		{
			self.dragging = true;
			self.anim_timer = CAMERA_ANIM_DURATION;
			self.target.yaw = self.current.yaw;
			self.target.pitch = self.current.pitch;
		}
	}

	if (rl::is_mouse_button_released(LEFT)) self.dragging = false;

	// 3. Handle camera rotation based on state
	switch
	{
		case self.dragging:
			// Calculate how much 1 pixel of mouse movement represents in radians based on current zoom
			Vec2 delta            = rl::get_mouse_delta();
			float dist_to_surface = self.current.radius - EARTH_RADIUS;
			float viewport_height = 2.0f * dist_to_surface * math::tan(self.camera_3d.fovy * 0.5f * rl::DEG2RAD);
			float angle_per_pixel = viewport_height / rl::get_screen_height() / EARTH_RADIUS;

			// We divide by cos(pitch) so dragging near the poles feels consistent
			self.vel = { delta.x * angle_per_pixel / math::max(0.1f, math::cos(self.current.pitch)), delta.y * angle_per_pixel };

			self.target.yaw += self.vel.x;
			self.target.pitch = math::clamp(self.target.pitch + self.vel.y, -1.5f, 1.5f);
			self.current.yaw = self.target.yaw;
			self.current.pitch = self.target.pitch;

		case self.anim_timer < CAMERA_ANIM_DURATION:
			// Smoothly animate the camera jumping to a new city
			self.anim_timer += dt;
			float t       = math::min(self.anim_timer / CAMERA_ANIM_DURATION, 1.0f);
			float eased_t = t * t * (3.0f - 2.0f * t); // Smoothstep easing
			self.current.yaw = self.start.yaw + (self.target.yaw - self.start.yaw) * eased_t;
			self.current.pitch = self.start.pitch + (self.target.pitch - self.start.pitch) * eased_t;
			self.current.radius = self.start.radius + (self.target.radius - self.start.radius) * eased_t;
			self.vel = { 0, 0 };

		default:
			// Apply inertia/momentum after releasing the mouse
			self.target.yaw += self.vel.x;
			self.target.pitch = math::clamp(self.target.pitch + self.vel.y, -1.5f, 1.5f);
			self.vel *= math::pow(0.8f, dt * 60.0f); // Friction

			// Lerp the camera towards the target position
			self.current.yaw += (self.target.yaw - self.current.yaw) * CAMERA_LERP_SPEED * dt;
			self.current.pitch += (self.target.pitch - self.current.pitch) * CAMERA_LERP_SPEED * dt;
	}

	// Finally, convert the spherical coordinates back to a 3D position for Raylib
	self.camera_3d.position = spherical_to_vec3(self.current.yaw, self.current.pitch, self.current.radius);
}

// Initiates a smooth, animated camera sweep to a specific City's coordinates
fn void GlobeCamera.jump_to(&self, City city)
{
	self.start = self.current;

	self.target.pitch = city.lat * rl::DEG2RAD;
	self.target.yaw = math::HALF_PI - (double)(city.lon * rl::DEG2RAD);
	self.target.radius = 5.0f;

	float diff = self.target.yaw - self.start.yaw;
	if (diff > math::PI)
	{
		self.start.yaw += math::TAU;
	}
	else if (diff < -math::PI)
	{
		self.start.yaw -= math::TAU;
	}

	self.anim_timer = 0.0f;
}

// A standard free function for math. Converts spherical coordinates to 3D cartesian vectors.
fn Vec3 spherical_to_vec3(float yaw, float pitch, float radius)
{
	float cos_pitch = math::cos(pitch);
	return radius * (Vec3) { cos_pitch * math::cos(yaw), math::sin(pitch), cos_pitch * math::sin(yaw) };
}

struct Pin
{
	float lat;
	float lon;
}

// Scene State
GlobeCamera cam;
RLTexture2D tex;
RLTexture2D star_tex;
RLShader shader;
RLModel model;
RLModel skybox;
int sun_pos_loc;
int is_skybox_loc;
int sun_fade_loc;
List{Pin} pins;
double last_sun_update = -1.0;
Vec3 sun_pos_cache;

fn void update_draw_frame()
	{
		// C3 lets us easily iterate over enum variants at runtime using `Enum::values`.
		// We use `idx` as the index, explicitly typed as an RLKeyboardKey for the math.
		foreach (RLKeyboardKey idx, city : City::values)
		{
			if (rl::is_key_pressed(RLKeyboardKey.ONE + idx))
			{
				cam.jump_to(city);
			}
		}

		float dt = math::min(rl::get_frame_time(), 0.1f);
		cam.update(dt);
		float sun_fade = math::clamp((cam.current.radius - 4.5f) / 2.5f, 0.0f, 1.0f);
		shader.set_value(sun_fade_loc, &sun_fade, FLOAT);

		// Heavy math here taken from wikipedia. We cache the solar coordinates and only recalculate once per second.
		if (rl::get_time() - last_sun_update > 1.0)
		{
			DateTime now    = datetime::from_time_tz(time::now(), 0).date_time;
			float hours_utc = now.hour + now.min / 60.0f + now.sec / 3600.0f;
			float day_of_year = now.year_day;
			float day_angle   = 6.24004077f + 0.01720197f * (day_of_year - 1.0f);
			float equation_of_time_mins  = -7.659f * math::sin(day_angle) + 9.863f * math::sin(2.0f * day_angle + 3.5932f);
			float equation_of_time_hours = equation_of_time_mins / 60.0f;
			float sun_yaw     = (float)math::HALF_PI + (hours_utc + equation_of_time_hours - 12.0f) * ((float)math::PI / 12.0f) + SUN_GEO_ADJUSTMENT;
			float orbit_angle = 2.0f * (float)math::PI * (day_of_year - 81.0f) / 365.0f;
			float declination = 23.45f * rl::DEG2RAD * math::sin(orbit_angle);
			sun_pos_cache = { math::cos(declination) * math::cos(sun_yaw), math::sin(declination), math::cos(declination) * math::sin(sun_yaw) };
			last_sun_update = rl::get_time();
		}
		shader.set_value(sun_pos_loc, &sun_pos_cache, VEC3);

		RLRay ray                = rl::get_screen_to_world_ray(rl::get_mouse_position(), cam.camera_3d);
		RLRayCollision collision = ray.get_collision_sphere({ 0, 0, 0 }, EARTH_RADIUS);

		// The `@drawing` trailing block macro automatically wraps the enclosed code
		// with `BeginDrawing()` and `EndDrawing()`.
		rl::@drawing()
		{
			rl::clear_background(rl::BLACK);

			// Same concept here for `BeginMode3D()` and `EndMode3D()`
			rl::@mode3d(cam.camera_3d)
			{
				rl::gl_disable_backface_culling();
				int sky_val = 1;
				shader.set_value(is_skybox_loc, &sky_val, INT);
				rl::draw_model(skybox, { 0, 0, 0 }, 1.0f, rl::WHITE);
				rl::gl_enable_backface_culling();

				int earth_val = 0;
				shader.set_value(is_skybox_loc, &earth_val, INT);
				rl::draw_model(model, { 0, 0, 0 }, 1.0f, rl::GRAY);
				foreach (p : pins)
				{
					Vec3 base = spherical_to_vec3((float)math::HALF_PI - (p.lon * rl::DEG2RAD), p.lat * rl::DEG2RAD, EARTH_RADIUS);
					Vec3 head = base * 1.03f;
					rl::draw_cylinder_ex(base, head, 0.01f, 0.01f, 8, rl::WHITE);
					rl::draw_sphere(head, 0.03f, rl::RED);
				}
			};

			if (collision.hit && (cam.dragging || math::abs(cam.target.yaw - cam.current.yaw) < CAMERA_SETTLE_THRESHOLD))
			{
				Vec3 p    = collision.point.normalize();
				float lat = math::asin(p[1]) * 180.0f / rl::PI;
				float lon = math::atan2(p[0], p[2]) * 180.0f / rl::PI;
				rl::draw_text(rl::text_format("Lat: %.3f Lon: %.3f", lat, lon), Ui.MARGIN, rl::get_screen_height() - (Ui.MARGIN + 10), Ui.FONT_SIZE, rl::SKYBLUE);
				if (rl::is_mouse_button_pressed(RIGHT))
				{
					pins.push({ lat, lon });
				}
			}

			float ui_fade       = math::clamp((cam.current.radius - 4.5f) / 2.5f, 0.0f, 1.0f);
			char ui_alpha       = (char)(ui_fade * 255.0f);
			RLColor ui_white    = { 255, 255, 255, ui_alpha };
			RLColor ui_raywhite = { 245, 245, 245, ui_alpha };

			rl::draw_text("C3 Earth Explorer (Left Click: Rotate, Right Click: Pin, Wheel: Zoom, 1-9: Cities)", Ui.MARGIN, Ui.MARGIN, Ui.FONT_SIZE, ui_raywhite);
			// C3 also supports compile-time `$foreach` loops.
			// This generates a separate, hardcoded `draw_text` call for each city during compilation.
			$foreach $city : City::values:
				rl::draw_text(rl::text_format("%d: %s", $city.ordinal + 1, $city.name), Ui.MARGIN, Ui.LIST_OFFSET + $city.ordinal * Ui.LINE_HEIGHT, Ui.FONT_SIZE, ui_white);
			$endforeach
		};
	}

fn int main(String[] args) @winmain
{
	rl::set_config_flags(WINDOW_RESIZABLE | MSAA_4X_HINT);
	rl::init_window(1024, 600, "C3 Earth Explorer");

	cam.init();

	tex = rl::load_texture(EARTH_TEXTURE);
	assert(tex.id, "Failed to load Earth texture");
	tex.set_filter(BILINEAR);

	star_tex = rl::load_texture(STARMAP_TEXTURE);
	assert(star_tex.id, "Failed to load Star texture");
	star_tex.set_filter(BILINEAR);

	shader = rl::load_shader_from_memory(EARTH_VERTEX_SHADER, EARTH_FRAGMENT_SHADER);
	model = rl::load_model_from_mesh(rl::gen_mesh_sphere(EARTH_RADIUS, 64, 64));
	skybox = rl::load_model_from_mesh(rl::gen_mesh_sphere(100.0f, 64, 64));

	model.materials[0].shader = shader;
	model.materials[0].maps[RLMaterialMapIndex.ALBEDO].texture = tex;

	skybox.materials[0].shader = shader;
	skybox.materials[0].maps[RLMaterialMapIndex.ALBEDO].texture = star_tex;

	sun_pos_loc   = shader.get_location("sunPos");
	is_skybox_loc = shader.get_location("isSkybox");
	sun_fade_loc  = shader.get_location("sunFade");

	pins.init(mem);

	$if env::WASM:
		emscripten_set_main_loop(&update_draw_frame, 60, 1);
	$else
		rl::set_target_fps(60);
		while (!rl::window_should_close()) update_draw_frame();
		pins.free();
		rl::unload_model(skybox);
		rl::unload_model(model);
		rl::unload_shader(shader);
		rl::unload_texture(star_tex);
		rl::unload_texture(tex);
		rl::close_window();
	$endif

	return 0;
}

alias Em_callback_func = fn void();
extern fn void emscripten_set_main_loop(Em_callback_func func, int fps, int simulate_infinite_loop);

// //////////////// Shaders

// We use `@feat` to compile one GLSL version for desktop, and another for the web.
const String SHADER_PREFIX @feat(EMSCRIPTEN)  = "#version 300 es\nprecision highp float;\n";
const String SHADER_PREFIX @feat(!EMSCRIPTEN) = "#version 330\n";

// The `+++` operator concatenates string literals at compile time.
const ZString EARTH_VERTEX_SHADER = SHADER_PREFIX +++ `in vec3 vertexPosition;
uniform mat4 mvp;
uniform mat4 matModel;
out vec3 fragPos;
void main() {
    fragPos = (matModel * vec4(vertexPosition, 1.0)).xyz;
    gl_Position = mvp * vec4(vertexPosition, 1.0);
}
`;

const ZString EARTH_FRAGMENT_SHADER = SHADER_PREFIX +++ `in vec3 fragPos;
uniform sampler2D texture0;
uniform vec3 sunPos;
uniform int isSkybox;
uniform float sunFade;
out vec4 finalColor;
const float PI = 3.14159265359;
void main() {
    vec3 p = normalize(fragPos);
    vec2 uv = vec2(0.5 + atan(p.x, p.z) / (2.0 * PI), 0.5 - asin(p.y) / PI);
    vec4 tex = texture(texture0, uv);
    if (isSkybox != 0) {
        float angle = dot(p, sunPos);
        float sunEffect = smoothstep(0.9995, 1.0, angle);
        vec3 sunColor = vec3(1.0, 0.96, 0.7) * sunEffect * 1.5 * sunFade;
        finalColor = vec4(tex.rgb + sunColor, 1.0);
        return;
    }
    float diff = max(dot(p, sunPos), 0.05);
    float finalDiff = mix(1.0, diff, sunFade);
    finalColor = vec4(tex.rgb * finalDiff, 1.0);
}
`;