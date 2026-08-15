module main;
import std;

fn int main()
{
	String file = `
		{"id":12345,"name":"Alice Johnson","email":"alice@example.com",
		"active":true,"roles":["admin","editor"],
		"profile":{"city":"Buenos Aires","country":"Argentina"},
		"lastLogin":"2026-08-01T12:34:56Z","preferences":{"theme":"dark","notifications":true}}
`;

	Object*? json_object = json::tparse(file);
	if (catch err = json_object)
	{
		io::printfn("Error: Failed to parse JSON (%s)", err);
		return 1;
	}

	if (catch err = json::marshal_to(io::stdout(), json_object, SPACE_4))
	{
		io::printfn("Error: Failed to write pretty printed JSON (%s)", err);
		return 1;
	}

	io::printn();

	return 0;
}