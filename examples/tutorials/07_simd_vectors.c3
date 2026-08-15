module main;
import std;

fn void main()
{
	// C3 natively supports hardware-backed SIMD vector types using [<>] syntax
	float[<3>] position = { 1.0, 2.0, 3.0 };
	float[<3>] velocity = { 0.5, -1.0, 1.5 };

	io::printn("--- 1. Vector Arithmetic & Dot Methods ---");
	// Vector arithmetic is performed elementwise out-of-the-box
	float[<3>] next_pos = position + velocity * 2.0;
	io::printfn("Initial Position:  [%f, %f, %f]", position.x, position.y, position.z);
	io::printfn("Velocity:          [%f, %f, %f]", velocity.x, velocity.y, velocity.z);
	io::printfn("Position + Vel*2:  [%f, %f, %f]", next_pos.x, next_pos.y, next_pos.z);

	// Standard vector operations via dot-method syntax
	float len             = velocity.length();
	float[<3>] normalized = velocity.normalize();
	io::printfn("Velocity Length:   %f", len);
	io::printfn("Velocity Norm:     [%f, %f, %f]", normalized.x, normalized.y, normalized.z);

	io::printn("\n--- 2. Vector Swizzling & Extraction ---");
	// Swizzling allows extracting or rearranging components easily
	float[<2>] horizontal_vel = velocity.xy;
	float[<3>] reversed_pos   = position.zyx;
	io::printfn("Horizontal Vel (xy): [%f, %f]", horizontal_vel.x, horizontal_vel.y);
	io::printfn("Reversed Pos (zyx):  [%f, %f, %f]", reversed_pos.x, reversed_pos.y, reversed_pos.z);

	io::printn("\n--- 3. Dot Product & Reflection ---");
	// Physics simulation: reflecting an incident vector off a normal
	float[<3>] incident = { 1.0, -1.0, 0.0 };
	float[<3>] normal   = { 0.0, 1.0, 0.0 }; // Pointing straight up

	float[<3>] reflected = incident.reflect(normal);
	float dot_prod       = incident.dot(normal);

	io::printfn("Incident:    [%f, %f, %f]", incident.x, incident.y, incident.z);
	io::printfn("Normal:      [%f, %f, %f]", normal.x, normal.y, normal.z);
	io::printfn("Dot Product: %f", dot_prod);
	io::printfn("Reflected:   [%f, %f, %f]", reflected.x, reflected.y, reflected.z);
}