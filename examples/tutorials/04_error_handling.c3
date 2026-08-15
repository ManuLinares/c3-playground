module main;
import std;

faultdef INVALID_CHAR, OUT_OF_RANGE; // Custom faults are declared globally

fn int? parse_digit(char c) // This function returns an Optional int (either an int or a fault)
{
	if (c < '0' || c > '9')
	{
		return INVALID_CHAR~; // Use '~' to return a fault as an empty optional
	}
	return (int)(c - '0');
}

fn int? parse_and_double(char c)
{
	int digit = parse_digit(c)!; // The '!' operator propagates/bubbles up the fault if parse_digit fails
	return (digit > 4) ? OUT_OF_RANGE~! : digit * 2;
}

fn void main()
{
	char[3] test_chars = { '3', '7', 'a' };

	foreach (c : test_chars)
	{
		int? val = parse_and_double(c);

		// Unwrapping the optional cleanly with 'if (catch ...)'
		if (catch err = val)
		{
			io::printfn("Character '%c': Failed with error %s", c, err);
		}
		else
		{
			// Inside this block, 'val' is automatically unwrapped to a standard 'int'
			io::printfn("Character '%c': Success, doubled value is %d", c, val);
		}
	}
}