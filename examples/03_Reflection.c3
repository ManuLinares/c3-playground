module main;
import std;

struct Point
{
	int x;
	int y;
	double depth;
}

// Compile-time macro to introspect struct definitions
macro print_fields($Type)
{
	$foreach $field : $Type::members:
		// Use dot notation (.) to access compile-time member properties
		io::printfn("Field '%s' | Offset: %d bytes | Size: %d bytes", $field.name, $field.offset, $field.size);
	$endforeach
}

fn int main()
{
	io::printn("--- 1. Type Metadata ---");
	// We can query compile-time type properties using the :: syntax
	io::printfn("Name:        %s", Point::name);
	io::printfn("Total Size:  %d bytes", Point::size);
	io::printfn("Is Struct?   %s", Point::kind == STRUCT ? "Yes" : "No");

	io::printn("\n--- 2. Struct Fields Reflection ---");
	// Generate code at compile-time that prints the layout
	print_fields(Point);

	return 0;
}
