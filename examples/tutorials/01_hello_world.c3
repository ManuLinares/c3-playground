module main;
import std;

fn void main()
{
	String[] greetings = {
		"Hello, world!",
		"¡Hola Mundo!",
		"Γειά σου Κόσμε!",
		"Привет, мир!",
		"こんにちは世界！",
		"你好世界！",
		"नमस्ते दुनिया!",
		"👋🌎!"
	};
	foreach (greeting : greetings)
	{
		io::printn(greeting);
	}
}