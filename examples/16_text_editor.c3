module main;
import std;

// Config
const int MAX_TEXT_LEN          = 512 * 1024;
const int TAB_SIZE_SPACES       = 4;
const int MAX_UNDO_STATES       = 16;

// Font Metrics & Scaling (5x8 Font)
const int GLYPH_WIDTH_CELLS     = 5;
const int GLYPH_HEIGHT_CELLS    = 8;
const int GLYPH_SPACING_CELLS   = 1;

const int FONT_SCALE            = 2;
const int CHAR_WIDTH            = (GLYPH_WIDTH_CELLS + GLYPH_SPACING_CELLS) * FONT_SCALE; // 12 px
const int CHAR_HEIGHT           = GLYPH_HEIGHT_CELLS * FONT_SCALE;                        // 16 px
const int LINE_HEIGHT           = 20;                                                     // 20 px
const int CURSOR_WIDTH          = 2;
const int CURSOR_EXTRA_HEIGHT   = 2;
const int SELECTION_PADDING_Y   = 2;

// Layout Geometry
const int HEADER_HEIGHT         = 36;
const int FOOTER_HEIGHT         = 24;
const int GUTTER_WIDTH          = 48;
const int GUTTER_BORDER_W       = 2;
const int TEXT_PADDING_X        = 10;
const int TEXT_PADDING_Y        = 8;
const int TEXT_START_X          = GUTTER_WIDTH + GUTTER_BORDER_W + TEXT_PADDING_X;       // 60 px
const int TEXT_START_Y          = HEADER_HEIGHT + TEXT_PADDING_Y;                        // 44 px

const float CURSOR_BLINK_RATE   = 0.5f;
const int HORIZONTAL_SCROLL_STEP = 3; // Columns scrolled per wheel step

// Keyboard Control Identifiers (Standard GLFW Virtual Keycodes >= 256)
const int KEY_ESCAPE            = 256;
const int KEY_ENTER             = 257;
const int KEY_TAB               = 258;
const int KEY_BACKSPACE         = 259;
const int KEY_DELETE            = 261;
const int KEY_RIGHT             = 262;
const int KEY_LEFT              = 263;
const int KEY_DOWN              = 264;
const int KEY_UP                = 265;
const int KEY_PAGE_UP           = 266;
const int KEY_PAGE_DOWN         = 267;
const int KEY_HOME              = 268;
const int KEY_END               = 269;
const int KEY_CAPSLOCK          = 280;
const int KEY_SHIFT             = 340;
const int KEY_CTRL              = 341;
const int KEY_ALT               = 342;
const int KEY_ALTGR             = 346;

// Color Palette
const Rgba COLOR_BG              = { 15,  23,  42,  255 }; // Slate 900
const Rgba COLOR_HEADER_BG       = { 30,  41,  59,  255 }; // Slate 800
const Rgba COLOR_FOOTER_BG       = { 30,  41,  59,  255 }; // Slate 800
const Rgba COLOR_GUTTER_BG       = { 15,  23,  42,  255 }; // Slate 900
const Rgba COLOR_GUTTER_BORDER   = { 51,  65,  85,  255 }; // Slate 700
const Rgba COLOR_LINE_HIGHLIGHT  = { 30,  41,  59,  160 }; // Active line background
const Rgba COLOR_TEXT            = { 226, 232, 240, 255 }; // Slate 200
const Rgba COLOR_TEXT_BRIGHT     = { 248, 250, 252, 255 }; // Slate 50
const Rgba COLOR_TEXT_MUTED      = { 100, 116, 139, 255 }; // Slate 500
const Rgba COLOR_HEADER_MUTED    = { 148, 163, 184, 255 }; // Slate 400
const Rgba COLOR_ACCENT_BLUE     = { 56,  189, 248, 255 }; // Sky 400
const Rgba COLOR_ACCENT_GREEN    = { 74,  222, 128, 255 }; // Green 400
const Rgba COLOR_ACCENT_YELLOW   = { 250, 204, 21,  255 }; // Yellow 400
const Rgba COLOR_SELECTION_BG    = { 3,   105, 161, 255 }; // Sky 700
const Rgba COLOR_CURSOR          = { 56,  189, 248, 255 }; // Sky 400

// types

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

struct Rect
{
	int x;
	int y;
	int w;
	int h;
}

struct UndoSnapshot
{
	char[MAX_TEXT_LEN] buffer;
	int text_len;
	int cursor_pos;
	int sel_anchor;
}

// font (5x8 bitmap)

enum FontGlyph : (Char32 ch, ulong bitmap)
{
	// Uppercase Glyphs
	A { 'A', 0b01110_10001_10001_11111_10001_10001_10001_00000 },
	B { 'B', 0b11110_10001_10001_11110_10001_10001_11110_00000 },
	C { 'C', 0b01111_10000_10000_10000_10000_10000_01111_00000 },
	D { 'D', 0b11110_10001_10001_10001_10001_10001_11110_00000 },
	E { 'E', 0b11111_10000_10000_11110_10000_10000_11111_00000 },
	F { 'F', 0b11111_10000_10000_11110_10000_10000_10000_00000 },
	G { 'G', 0b01111_10000_10000_10111_10001_10001_01111_00000 },
	H { 'H', 0b10001_10001_10001_11111_10001_10001_10001_00000 },
	I { 'I', 0b01110_00100_00100_00100_00100_00100_01110_00000 },
	J { 'J', 0b00111_00010_00010_00010_00010_10010_01100_00000 },
	K { 'K', 0b10001_10010_10100_11000_10100_10010_10001_00000 },
	L { 'L', 0b10000_10000_10000_10000_10000_10000_11111_00000 },
	M { 'M', 0b10001_11011_10101_10101_10001_10001_10001_00000 },
	N { 'N', 0b10001_11001_10101_10011_10001_10001_10001_00000 },
	O { 'O', 0b01110_10001_10001_10001_10001_10001_01110_00000 },
	P { 'P', 0b11110_10001_10001_11110_10000_10000_10000_00000 },
	Q { 'Q', 0b01110_10001_10001_10001_10101_10010_01101_00000 },
	R { 'R', 0b11110_10001_10001_11110_10100_10010_10001_00000 },
	S { 'S', 0b01111_10000_10000_01110_00001_00001_11110_00000 },
	T { 'T', 0b11111_00100_00100_00100_00100_00100_00100_00000 },
	U { 'U', 0b10001_10001_10001_10001_10001_10001_01110_00000 },
	V { 'V', 0b10001_10001_10001_10001_10001_01010_00100_00000 },
	W { 'W', 0b10001_10001_10001_10101_10101_11011_10001_00000 },
	X { 'X', 0b10001_10001_01010_00100_01010_10001_10001_00000 },
	Y { 'Y', 0b10001_10001_01010_00100_00100_00100_00100_00000 },
	Z { 'Z', 0b11111_00001_00010_00100_01000_10000_11111_00000 },

	// Lowercase Glyphs
	LOWER_A { 'a', 0b00000_00000_01111_00001_01111_10001_01111_00000 },
	LOWER_B { 'b', 0b10000_10000_11110_10001_10001_10001_11110_00000 },
	LOWER_C { 'c', 0b00000_00000_01111_10000_10000_10000_01111_00000 },
	LOWER_D { 'd', 0b00001_00001_01111_10001_10001_10001_01111_00000 },
	LOWER_E { 'e', 0b00000_00000_01111_10001_11111_10000_01111_00000 },
	LOWER_F { 'f', 0b00110_01001_01000_11110_01000_01000_01000_00000 },
	LOWER_G { 'g', 0b00000_00000_01111_10001_10001_01111_00001_11110 },
	LOWER_H { 'h', 0b10000_10000_11110_10001_10001_10001_10001_00000 },
	LOWER_I { 'i', 0b00100_00000_01100_00100_00100_00100_01110_00000 },
	LOWER_J { 'j', 0b00010_00000_00010_00010_00010_00010_10010_01100 },
	LOWER_K { 'k', 0b10000_10000_10010_10100_11000_10100_10010_00000 },
	LOWER_L { 'l', 0b01100_00100_00100_00100_00100_00100_01110_00000 },
	LOWER_M { 'm', 0b00000_00000_11010_10101_10101_10101_10101_00000 },
	LOWER_N { 'n', 0b00000_00000_11110_10001_10001_10001_10001_00000 },
	LOWER_O { 'o', 0b00000_00000_01110_10001_10001_10001_01110_00000 },
	LOWER_P { 'p', 0b00000_00000_11110_10001_10001_11110_10000_10000 },
	LOWER_Q { 'q', 0b00000_00000_01111_10001_10001_01111_00001_00001 },
	LOWER_R { 'r', 0b00000_00000_10110_11001_10000_10000_10000_00000 },
	LOWER_S { 's', 0b00000_00000_01111_10000_01110_00001_11110_00000 },
	LOWER_T { 't', 0b00100_00100_11111_00100_00100_00100_00011_00000 },
	LOWER_U { 'u', 0b00000_00000_10001_10001_10001_10011_01101_00000 },
	LOWER_V { 'v', 0b00000_00000_10001_10001_10001_01010_00100_00000 },
	LOWER_W { 'w', 0b00000_00000_10001_10001_10101_10101_01010_00000 },
	LOWER_X { 'x', 0b00000_00000_10001_01010_00100_01010_10001_00000 },
	LOWER_Y { 'y', 0b00000_00000_10001_10001_10001_01111_00001_11110 },
	LOWER_Z { 'z', 0b00000_00000_11111_00010_00100_01000_11111_00000 },

	// Numbers & Punctuation
	ZERO        { '0', 0b01110_10001_10011_10101_11001_10001_01110_00000 },
	ONE         { '1', 0b00100_01100_00100_00100_00100_00100_01110_00000 },
	TWO         { '2', 0b01110_10001_00001_00010_00100_01000_11111_00000 },
	THREE       { '3', 0b11111_00010_00100_00010_00001_10001_01110_00000 },
	FOUR        { '4', 0b00010_00110_01010_10010_11111_00010_00010_00000 },
	FIVE        { '5', 0b11111_10000_11110_00001_00001_10001_01110_00000 },
	SIX         { '6', 0b00110_01000_10000_11110_10001_10001_01110_00000 },
	SEVEN       { '7', 0b11111_00001_00010_00100_01000_01000_01000_00000 },
	EIGHT       { '8', 0b01110_10001_10001_01110_10001_10001_01110_00000 },
	NINE        { '9', 0b01110_10001_10001_01111_00001_00010_01100_00000 },
	SPACE       { ' ', 0b00000_00000_00000_00000_00000_00000_00000_00000 },
	DOT         { '.', 0b00000_00000_00000_00000_00000_00110_00110_00000 },
	COMMA       { ',', 0b00000_00000_00000_00000_00000_00110_00100_01000 },
	EXCLAMATION { '!', 0b00100_00100_00100_00100_00100_00000_00100_00000 },
	QUESTION    { '?', 0b01110_10001_00001_00010_00100_00000_00100_00000 },
	COLON       { ':', 0b00000_00000_00110_00110_00000_00110_00110_00000 },
	SEMICOLON   { ';', 0b00000_00000_00110_00110_00000_00110_00100_01000 },
	QUOTE       { '"', 0b01010_01010_01010_00000_00000_00000_00000_00000 },
	APOSTROPHE  { '\'', 0b00100_00100_00100_00000_00000_00000_00000_00000 },
	HYPHEN      { '-', 0b00000_00000_00000_11111_00000_00000_00000_00000 },
	PLUS        { '+', 0b00000_00100_00100_11111_00100_00100_00000_00000 },
	EQUALS      { '=', 0b00000_00000_11111_00000_11111_00000_00000_00000 },
	LESS        { '<', 0b00010_00100_01000_10000_01000_00100_00010_00000 },
	GREATER     { '>', 0b01000_00100_00010_00001_00010_00100_01000_00000 },
	LPAREN      { '(', 0b00010_00100_01000_01000_01000_00100_00010_00000 },
	RPAREN      { ')', 0b01000_00100_00010_00010_00010_00100_01000_00000 },
	LBRACKET    { '[', 0b01110_01000_01000_01000_01000_01000_01110_00000 },
	RBRACKET    { ']', 0b01110_00010_00010_00010_00010_00010_01110_00000 },
	LBRACE      { '{', 0b00011_00100_00100_01000_00100_00100_00011_00000 },
	RBRACE      { '}', 0b11000_00100_00100_00010_00100_00100_11000_00000 },
	SLASH       { '/',  0b00001_00010_00010_00100_00100_01000_01000_10000 },
	BACKSLASH   { '\\', 0b10000_01000_01000_00100_00100_00010_00010_00001 },
	UNDERSCORE  { '_', 0b00000_00000_00000_00000_00000_00000_00000_11111 },
	ASTERISK    { '*', 0b00000_01010_00100_11111_00100_01010_00000_00000 },
	HASH        { '#', 0b01010_01010_11111_01010_11111_01010_01010_00000 },
	AT          { '@', 0b01110_10001_10111_10101_10110_10000_01111_00000 },
	AMPERSAND   { '&', 0b01100_10010_01100_01010_10001_10010_01101_00000 },
	TILDE       { '~', 0b00000_00000_01101_10010_00000_00000_00000_00000 },
	BACKTICK    { '`', 0b01000_00100_00000_00000_00000_00000_00000_00000 },
	DOLLAR      { '$', 0b00100_01111_10100_01110_00101_11110_00100_00000 },
	PERCENT     { '%', 0b11000_11001_00010_00100_01000_10011_00011_00000 },
	CARET       { '^', 0b00100_01010_10001_00000_00000_00000_00000_00000 },
	PIPE        { '|', 0b00100_00100_00100_00100_00100_00100_00100_00000 },

	// Accented Symbols (Unicode Escape Literals)
	DIAERESIS   { '¨', 0b01010_00000_00000_00000_00000_00000_00000_00000 }, // '\u00A8'
	//ACUTE       { '´', 0b00010_00100_00000_00000_00000_00000_00000_00000 },
	N_TILDE       { 'Ñ', 0b01100_10001_11001_10101_10011_10001_10001_00000 },
	LOWER_N_TILDE { 'ñ', 0b01100_00000_11110_10001_10001_10001_10001_00000 },

	UNKNOWN     { '\0', 0b11111_10001_10101_10101_10101_10001_11111_00000 }
}

fn ulong get_char_bitmap(Char32 c)
{
	FontGlyph? g = runtime::@enum_lookup(FontGlyph, "ch", c);
	if (catch g)
	{
		return FontGlyph.UNKNOWN.bitmap;
	}
	return g.bitmap;
}

fn bool is_word_char(char c)
{
	return ascii::is_alnum(c) || c == '_';
}

// canvas

struct Canvas
{
	Rgba[] pixels;
	int width;
	int height;
}

fn void Canvas.clear(&self, Rgba col)
{
	self.pixels[..] = col;
}

fn void Canvas.draw_rect_clipped(&self, Rect r, Rect clip, Rgba col)
{
	int min_x = math::clamp(r.x, clip.x, clip.x + clip.w);
	int max_x = math::clamp(r.x + r.w, clip.x, clip.x + clip.w);
	int min_y = math::clamp(r.y, clip.y, clip.y + clip.h);
	int max_y = math::clamp(r.y + r.h, clip.y, clip.y + clip.h);

	for (int y = min_y; y < max_y; y++)
	{
		for (int x = min_x; x < max_x; x++)
		{
			self.pixels[y * self.width + x] = col;
		}
	}
}

fn void Canvas.draw_rect(&self, Rect r, Rgba col)
{
	self.draw_rect_clipped(r, { 0, 0, self.width, self.height }, col);
}

fn void Canvas.draw_char_clipped(&self, int x, int y, Char32 c, int scale, Rect clip, Rgba col)
{
	ulong bits = get_char_bitmap(c);
	for (int row = 0; row < GLYPH_HEIGHT_CELLS; row++)
	{
		for (int col_idx = 0; col_idx < GLYPH_WIDTH_CELLS; col_idx++)
		{
			int bit_pos = 39 - (row * GLYPH_WIDTH_CELLS + col_idx);
			if (((bits >> bit_pos) & 1) != 0)
			{
				self.draw_rect_clipped({ x + col_idx * scale, y + row * scale, scale, scale }, clip, col);
			}
		}
	}
}

fn void Canvas.draw_text(&self, int x, int y, String str, int scale, Rgba col)
{
	int advance = (GLYPH_WIDTH_CELLS + GLYPH_SPACING_CELLS) * scale;
	int cur_x = x;
	StringIterator iter = str.iterator();
	while (try Char32 c = iter.next())
	{
		ulong bits = get_char_bitmap(c);
		for (int row = 0; row < GLYPH_HEIGHT_CELLS; row++)
		{
			for (int col_idx = 0; col_idx < GLYPH_WIDTH_CELLS; col_idx++)
			{
				int bit_pos = 39 - (row * GLYPH_WIDTH_CELLS + col_idx);
				if (((bits >> bit_pos) & 1) != 0)
				{
					self.draw_rect({ cur_x + col_idx * scale, y + row * scale, scale, scale }, col);
				}
			}
		}
		cur_x += advance;
	}
}

fn void Canvas.draw_number(&self, int x, int y, int num, int scale, Rgba col)
{
	char[32] buf;
	String s = string::bformat(&buf, "%d", num);
	self.draw_text(x, y, s, scale, col);
}

fn void Canvas.draw_gutter_number(&self, int x, int y, int num, int width_px, int scale, Rgba col)
{
	char[32] buf;
	String s = string::bformat(&buf, "%d", num);
	int text_w = s.len * CHAR_WIDTH;
	int draw_x = x + width_px - text_w;
	self.draw_text(draw_x, y, s, scale, col);
}

// editor

struct Editor
{
	char[MAX_TEXT_LEN] text_buffer;
	int text_len;
	int cursor_pos;
	int sel_anchor;
	int target_col;
	int scroll_line;
	int scroll_col;

	// Clipboard
	char[MAX_TEXT_LEN] clipboard_buffer;
	int clipboard_len;

	// Undo Stack (Ring-Buffer)
	UndoSnapshot[MAX_UNDO_STATES] undo_stack;
	int undo_count;
	int undo_head;

	bool shift_held;
	bool ctrl_held;
	bool mouse_down;
	bool initialized;
	float blink_timer;
	bool cursor_visible;
}

fn String Editor.get_text(&self)
{
	return (String)self.text_buffer[:self.text_len];
}

fn void Editor.load_text(&self, String str)
{
	int len = min(str.len, MAX_TEXT_LEN - 1);
	mem::copy(&self.text_buffer[0], str.ptr, len);
	self.text_len = len;
	self.cursor_pos = len;
	self.sel_anchor = len;
	self.target_col = 0;
	self.scroll_line = 0;
	self.scroll_col = 0;
	self.clipboard_len = 0;
	self.undo_count = 0;
	self.undo_head = 0;
}

fn void Editor.save_undo_state(&self)
{
	int next_slot = (self.undo_head + 1) % MAX_UNDO_STATES;
	UndoSnapshot* snap = &self.undo_stack[next_slot];

	mem::copy(&snap.buffer[0], &self.text_buffer[0], self.text_len);
	snap.text_len = self.text_len;
	snap.cursor_pos = self.cursor_pos;
	snap.sel_anchor = self.sel_anchor;

	self.undo_head = next_slot;
	if (self.undo_count < MAX_UNDO_STATES)
	{
		self.undo_count++;
	}
}

fn void Editor.undo(&self)
{
	if (self.undo_count <= 0) return;

	UndoSnapshot* snap = &self.undo_stack[self.undo_head];
	mem::copy(&self.text_buffer[0], &snap.buffer[0], snap.text_len);
	self.text_len = snap.text_len;
	self.cursor_pos = snap.cursor_pos;
	self.sel_anchor = snap.sel_anchor;
	self.target_col = self.get_col(self.cursor_pos);

	self.undo_head = (self.undo_head - 1 + MAX_UNDO_STATES) % MAX_UNDO_STATES;
	self.undo_count--;
}

fn void Editor.copy_selection(&self)
{
	if (self.cursor_pos == self.sel_anchor) return;
	int start = min(self.cursor_pos, self.sel_anchor);
	int end   = max(self.cursor_pos, self.sel_anchor);
	int count = end - start;

	mem::copy(&self.clipboard_buffer[0], &self.text_buffer[start], count);
	self.clipboard_buffer[count] = '\0';
	self.clipboard_len = count;
}

fn char* get_clipboard_text() @export("get_clipboard_text")
{
	if (editor.cursor_pos != editor.sel_anchor)
	{
		editor.copy_selection();
	}
	return &editor.clipboard_buffer[0];
}

fn void Editor.cut_selection(&self)
{
	if (self.cursor_pos == self.sel_anchor) return;
	self.save_undo_state();
	self.copy_selection();
	self.delete_selection();
}

fn void Editor.paste_clipboard(&self)
{
	if (self.clipboard_len == 0) return;
	self.save_undo_state();
	self.delete_selection();

	if (self.text_len + self.clipboard_len >= MAX_TEXT_LEN - 1) return;

	mem::move(&self.text_buffer[self.cursor_pos + self.clipboard_len], &self.text_buffer[self.cursor_pos], self.text_len - self.cursor_pos);
	mem::copy(&self.text_buffer[self.cursor_pos], &self.clipboard_buffer[0], self.clipboard_len);

	self.text_len += self.clipboard_len;
	self.cursor_pos += self.clipboard_len;
	self.sel_anchor = self.cursor_pos;
	self.target_col = self.get_col(self.cursor_pos);
}

fn int Editor.get_line(&self, int pos)
{
	String text = self.get_text();
	int line = 0;
	int len = min(pos, text.len);
	for (int i = 0; i < len; i++)
	{
		if (text[i] == '\n') line++;
	}
	return line;
}

fn int Editor.get_col(&self, int pos)
{
	String text = self.get_text();
	int col = 0;
	int len = min(pos, text.len);
	for (int i = 0; i < len; )
	{
		sz read_bytes = math::min(len - i, 4);
		Char32 c = conv::utf8_to_char32(&text[i], &read_bytes) ?? text[i];
		if (read_bytes == 0) read_bytes = 1;

		if (c == '\n') { col = 0; }
		else { col++; }
		i += read_bytes;
	}
	return col;
}

fn int Editor.get_total_lines(&self)
{
	return (int)self.get_text().count("\n") + 1;
}

fn int Editor.get_line_start(&self, int pos)
{
	String text = self.get_text();
	sz? idx = text[:pos].rindex_of_char('\n');
	if (try i = idx) return i + 1;
	return 0;
}

fn int Editor.get_line_end(&self, int pos)
{
	String text = self.get_text();
	sz? idx = text[pos..].index_of_char('\n');
	if (try i = idx) return pos + i;
	return text.len;
}

fn int Editor.get_pos_from_line_col(&self, int target_line, int target_col)
{
	String text = self.get_text();
	int current_line = 0;
	int line_start = 0;
	int i = 0;

	while (i < text.len && current_line < target_line)
	{
		if (text[i] == '\n')
		{
			current_line++;
			line_start = i + 1;
		}
		i++;
	}

	int line_end = line_start;
	while (line_end < text.len && text[line_end] != '\n')
	{
		line_end++;
	}

	int actual_pos = line_start;
	int col = 0;
	while (actual_pos < line_end && col < target_col)
	{
		sz read_bytes = math::min(line_end - actual_pos, 4);
		conv::utf8_to_char32(&text[actual_pos], &read_bytes) ?? 0;
		if (read_bytes == 0) read_bytes = 1;
		actual_pos += (int)read_bytes;
		col++;
	}

	return actual_pos;
}

fn int Editor.get_pos_from_mouse(&self, Vec2 mpos)
{
	if (mpos.x < TEXT_START_X || mpos.y < TEXT_START_Y)
	{
		if (mpos.y < TEXT_START_Y) return 0;
	}
	int rel_y = (int)(mpos.y - TEXT_START_Y);
	int line  = rel_y / LINE_HEIGHT + self.scroll_line;
	int rel_x = (int)(mpos.x - TEXT_START_X + CHAR_WIDTH / 2);
	int col   = math::max(0, rel_x / CHAR_WIDTH + self.scroll_col);

	return self.get_pos_from_line_col(line, col);
}

fn int Editor.get_prev_char_pos(&self, int pos)
{
	if (pos <= 0) return 0;
	int p = pos - 1;
	while (p > 0 && (self.text_buffer[p] & 0xC0) == 0x80) p--;
	return p;
}

fn int Editor.get_next_char_pos(&self, int pos)
{
	if (pos >= self.text_len) return self.text_len;
	int p = pos + 1;
	while (p < self.text_len && (self.text_buffer[p] & 0xC0) == 0x80) p++;
	return p;
}

fn int Editor.get_prev_word_pos(&self, int pos)
{
	String text = self.get_text();
	if (pos <= 0) return 0;
	int p = pos;

	while (p > 0 && !is_word_char(text[p - 1])) p--;
	while (p > 0 && is_word_char(text[p - 1])) p--;
	return p;
}

fn int Editor.get_next_word_pos(&self, int pos)
{
	String text = self.get_text();
	if (pos >= text.len) return text.len;
	int p = pos;

	while (p < text.len && !is_word_char(text[p])) p++;
	while (p < text.len && is_word_char(text[p])) p++;
	return p;
}

fn void Editor.delete_selection(&self)
{
	if (self.cursor_pos == self.sel_anchor) return;
	int start = min(self.cursor_pos, self.sel_anchor);
	int end   = max(self.cursor_pos, self.sel_anchor);
	int count = end - start;

	if (end < self.text_len)
	{
		mem::move(&self.text_buffer[start], &self.text_buffer[end], self.text_len - end);
	}
	self.text_len -= count;
	self.cursor_pos = start;
	self.sel_anchor = start;
	self.target_col = self.get_col(self.cursor_pos);
}

fn void Editor.insert_codepoint(&self, Char32 c)
{
	// Expand tab to spaces (no tab glyph in font)
	if (c == '\t')
	{
		for (int i = 0; i < 4; i++) self.insert_codepoint(' ');
		return;
	}

	char[4] buf;
	sz len = conv::char32_to_utf8(c, &buf) ?? 0;
	if (len == 0) return;

	self.save_undo_state();
	self.delete_selection();
	if (self.text_len + len >= MAX_TEXT_LEN - 1) return;

	mem::move(&self.text_buffer[self.cursor_pos + len], &self.text_buffer[self.cursor_pos], self.text_len - self.cursor_pos);
	mem::copy(&self.text_buffer[self.cursor_pos], &buf[0], len);
	self.text_len += len;
	self.cursor_pos += len;
	self.sel_anchor = self.cursor_pos;
	self.target_col = self.get_col(self.cursor_pos);
}

fn void Editor.insert_text(&self, String str)
{
	StringIterator iter = str.iterator();
	while (try Char32 c = iter.next())
	{
		self.insert_codepoint(c);
	}
}

fn void Editor.handle_backspace(&self)
{
	if (self.cursor_pos != self.sel_anchor || self.cursor_pos > 0)
	{
		self.save_undo_state();
	}
	if (self.cursor_pos != self.sel_anchor)
	{
		self.delete_selection();
		return;
	}
	if (self.cursor_pos > 0)
	{
		int prev = self.get_prev_char_pos(self.cursor_pos);
		int count = self.cursor_pos - prev;
		mem::move(&self.text_buffer[prev], &self.text_buffer[self.cursor_pos], self.text_len - self.cursor_pos);
		self.text_len -= count;
		self.cursor_pos = prev;
		self.sel_anchor = self.cursor_pos;
		self.target_col = self.get_col(self.cursor_pos);
	}
}

fn void Editor.handle_delete(&self)
{
	if (self.cursor_pos != self.sel_anchor || self.cursor_pos < self.text_len)
	{
		self.save_undo_state();
	}
	if (self.cursor_pos != self.sel_anchor)
	{
		self.delete_selection();
		return;
	}
	if (self.cursor_pos < self.text_len)
	{
		int next = self.get_next_char_pos(self.cursor_pos);
		int count = next - self.cursor_pos;
		mem::move(&self.text_buffer[self.cursor_pos], &self.text_buffer[next], self.text_len - next);
		self.text_len -= count;
	}
}

fn void Editor.reset_cursor_blink(&self)
{
	self.blink_timer = 0.0f;
	self.cursor_visible = true;
}

fn void Editor.ensure_cursor_visible(&self, int visible_lines, int visible_cols)
{
	int cursor_line = self.get_line(self.cursor_pos);
	if (cursor_line < self.scroll_line)
	{
		self.scroll_line = cursor_line;
	}
	else if (cursor_line >= self.scroll_line + visible_lines)
	{
		self.scroll_line = cursor_line - visible_lines + 1;
	}
	
	self.scroll_line = math::clamp(self.scroll_line, 0, math::max(0, self.get_total_lines() - 1));

	int cursor_col = self.get_col(self.cursor_pos);
	if (cursor_col < self.scroll_col)
	{
		self.scroll_col = cursor_col;
	}
	else if (cursor_col >= self.scroll_col + visible_cols)
	{
		self.scroll_col = cursor_col - visible_cols + 1;
	}

	if (self.scroll_col < 0)
	{
		self.scroll_col = 0;
	}
}

fn void Editor.process_event(&self, Event event, int visible_lines, int visible_cols)
{
	switch (event.kind)
	{
		case MOUSE_DOWN:
			if (event.mouse_button == 0)
			{
				self.mouse_down = true;
				self.cursor_pos = self.get_pos_from_mouse(event.mouse_pos);
				if (!self.shift_held) self.sel_anchor = self.cursor_pos;
				self.target_col = self.get_col(self.cursor_pos);
				self.reset_cursor_blink();
				self.ensure_cursor_visible(visible_lines, visible_cols);
			}

		case MOUSE_MOVE:
			if (self.mouse_down)
			{
				self.cursor_pos = self.get_pos_from_mouse(event.mouse_pos);
				self.target_col = self.get_col(self.cursor_pos);
				self.reset_cursor_blink();
				self.ensure_cursor_visible(visible_lines, visible_cols);
			}

		case MOUSE_UP:
			if (event.mouse_button == 0)
			{
				self.mouse_down = false;
			}

		case MOUSE_WHEEL:
			if (self.shift_held)
			{
				self.scroll_col = math::max(0, self.scroll_col - (int)event.wheel * HORIZONTAL_SCROLL_STEP);
			}
			else
			{
				int total_lines = self.get_total_lines();
				self.scroll_line = math::clamp(self.scroll_line - (int)event.wheel, 0, math::max(0, total_lines - 1));
			}

		case CHAR_INPUT:
			self.reset_cursor_blink();
			if (event.character != 0)
			{
				self.insert_codepoint(event.character);
				self.ensure_cursor_visible(visible_lines, visible_cols);
			}

		case KEY_DOWN:
			self.reset_cursor_blink();

			int k = event.key;

			if (self.ctrl_held)
			{
				switch (k)
				{
					case 'A':
					case 'a':
						self.sel_anchor = 0;
						self.cursor_pos = self.text_len;
						self.target_col = self.get_col(self.cursor_pos);
						self.ensure_cursor_visible(visible_lines, visible_cols);
						return;

					case 'C':
					case 'c':
						self.copy_selection();
						return;

					case 'X':
					case 'x':
						self.cut_selection();
						self.ensure_cursor_visible(visible_lines, visible_cols);
						return;

					case 'Z':
					case 'z':
						self.undo();
						self.ensure_cursor_visible(visible_lines, visible_cols);
						return;

					default:
						break;
				}
			}

			switch (k)
			{
				case KEY_SHIFT:
					self.shift_held = true;

				case KEY_CTRL:
					self.ctrl_held = true;

				case KEY_ALT:
				case KEY_ALTGR:
				case KEY_CAPSLOCK:
				case KEY_ESCAPE:
					return;

				case KEY_BACKSPACE:
					self.handle_backspace();
					self.ensure_cursor_visible(visible_lines, visible_cols);

				case KEY_DELETE:
					self.handle_delete();
					self.ensure_cursor_visible(visible_lines, visible_cols);

				case KEY_TAB:
					self.insert_text("    ");
					self.ensure_cursor_visible(visible_lines, visible_cols);

				case KEY_ENTER:
					self.insert_codepoint('\n');
					self.ensure_cursor_visible(visible_lines, visible_cols);

				case KEY_PAGE_UP:
					int line_pu = self.get_line(self.cursor_pos);
					int target_line_pu = math::max(0, line_pu - visible_lines);
					self.cursor_pos = self.get_pos_from_line_col(target_line_pu, self.target_col);
					if (!self.shift_held) self.sel_anchor = self.cursor_pos;
					self.ensure_cursor_visible(visible_lines, visible_cols);

				case KEY_PAGE_DOWN:
					int line_pd = self.get_line(self.cursor_pos);
					int tot_pd = self.get_total_lines();
					int target_line_pd = math::min(tot_pd - 1, line_pd + visible_lines);
					self.cursor_pos = self.get_pos_from_line_col(target_line_pd, self.target_col);
					if (!self.shift_held) self.sel_anchor = self.cursor_pos;
					self.ensure_cursor_visible(visible_lines, visible_cols);

				case KEY_LEFT:
					int new_pos_l = self.cursor_pos;
					if (self.ctrl_held)
					{
						new_pos_l = self.get_prev_word_pos(self.cursor_pos);
					}
					else if (!self.shift_held && self.cursor_pos != self.sel_anchor)
					{
						new_pos_l = min(self.cursor_pos, self.sel_anchor);
					}
					else
					{
						new_pos_l = self.get_prev_char_pos(self.cursor_pos);
					}

					self.cursor_pos = new_pos_l;
					if (!self.shift_held) self.sel_anchor = self.cursor_pos;
					self.target_col = self.get_col(self.cursor_pos);
					self.ensure_cursor_visible(visible_lines, visible_cols);

				case KEY_RIGHT:
					int new_pos_r = self.cursor_pos;
					if (self.ctrl_held)
					{
						new_pos_r = self.get_next_word_pos(self.cursor_pos);
					}
					else if (!self.shift_held && self.cursor_pos != self.sel_anchor)
					{
						new_pos_r = max(self.cursor_pos, self.sel_anchor);
					}
					else
					{
						new_pos_r = self.get_next_char_pos(self.cursor_pos);
					}

					self.cursor_pos = new_pos_r;
					if (!self.shift_held) self.sel_anchor = self.cursor_pos;
					self.target_col = self.get_col(self.cursor_pos);
					self.ensure_cursor_visible(visible_lines, visible_cols);

				case KEY_UP:
					int line = self.get_line(self.cursor_pos);
					if (line > 0)
					{
						self.cursor_pos = self.get_pos_from_line_col(line - 1, self.target_col);
						if (!self.shift_held) self.sel_anchor = self.cursor_pos;
					}
					self.ensure_cursor_visible(visible_lines, visible_cols);

				case KEY_DOWN:
					int line = self.get_line(self.cursor_pos);
					int tot  = self.get_total_lines();
					if (line < tot - 1)
					{
						self.cursor_pos = self.get_pos_from_line_col(line + 1, self.target_col);
						if (!self.shift_held) self.sel_anchor = self.cursor_pos;
					}
					self.ensure_cursor_visible(visible_lines, visible_cols);

				case KEY_HOME:
					self.cursor_pos = self.get_line_start(self.cursor_pos);
					if (!self.shift_held) self.sel_anchor = self.cursor_pos;
					self.target_col = self.get_col(self.cursor_pos);
					self.ensure_cursor_visible(visible_lines, visible_cols);

				case KEY_END:
					self.cursor_pos = self.get_line_end(self.cursor_pos);
					if (!self.shift_held) self.sel_anchor = self.cursor_pos;
					self.target_col = self.get_col(self.cursor_pos);
					self.ensure_cursor_visible(visible_lines, visible_cols);

				default:
					break;
			}

		case KEY_UP:
			if (event.key == KEY_SHIFT) self.shift_held = false;
			if (event.key == KEY_CTRL)  self.ctrl_held = false;

		default:
			break;
	}
}

Editor editor;

fn Rgba* update_canvas(int width, int height, float dt, Event[] events) @export("update_canvas")
{
	static Rgba[] pixels;
	if (pixels.len != width * height)
	{
		if (pixels.len > 0) mem::free(pixels.ptr);
		pixels = mem::new_array(Rgba, width * height);
	}

	if (!editor.initialized)
	{
		editor.initialized = true;
		editor.load_text(
			`// C3 Canvas Text Editor Engine
// Powered by the C3 Standard Library
//
// Supported Features & Shortcuts:
// - Font: Full ASCII 5x8 Bitmap
// - Mouse: Click positioning, Drag-to-select
// - Scrolling: Vertical & Horizontal (Shift + Wheel)
// - Navigation: Arrows, Home/End, PageUp/Down, Word Jumps (Ctrl + Arrows)
// - Selection: Shift + Navigation, Ctrl + A (Select All)
// - Clipboard & History: Ctrl + C / X / V, Ctrl + Z (Undo)

ABCDEFGHIJKLMNOPQRSTUVWXYZ
abcdefghijklmnopqrstuvwxyz
ñÑ
0123456789
. , ! ? : ; " ' - + = < >
( ) [ ] { } / \ _ * # @ &
~ ¨ `` $ % ^ |
`
		);
	}

	int editor_w = width - TEXT_START_X;
	int editor_h = height - HEADER_HEIGHT - FOOTER_HEIGHT;

	int visible_lines = math::max(1, (editor_h - TEXT_PADDING_Y * 2) / LINE_HEIGHT);
	int visible_cols  = math::max(1, (editor_w - TEXT_PADDING_X) / CHAR_WIDTH);

	editor.blink_timer += dt;
	if (editor.blink_timer >= CURSOR_BLINK_RATE)
	{
		editor.blink_timer -= CURSOR_BLINK_RATE;
		editor.cursor_visible = !editor.cursor_visible;
	}

	foreach (event : events)
	{
		editor.process_event(event, visible_lines, visible_cols);
	}

	Canvas canvas = { .pixels = pixels, .width = width, .height = height };
	Rect text_clip = { TEXT_START_X, HEADER_HEIGHT, editor_w, editor_h };

	canvas.clear(COLOR_BG);

	// active line highlight
	int cline = editor.get_line(editor.cursor_pos);
	int ccol  = editor.get_col(editor.cursor_pos);
	int active_rel_line = cline - editor.scroll_line;

	if (active_rel_line >= 0 && active_rel_line < visible_lines)
	{
		int hl_y = TEXT_START_Y + active_rel_line * LINE_HEIGHT;
		canvas.draw_rect_clipped({ TEXT_START_X - TEXT_PADDING_X, hl_y - 2, editor_w + TEXT_PADDING_X, LINE_HEIGHT }, text_clip, COLOR_LINE_HIGHLIGHT);
	}

	// text & selection
	String text   = editor.get_text();
	int sel_start = min(editor.cursor_pos, editor.sel_anchor);
	int sel_end   = max(editor.cursor_pos, editor.sel_anchor);
	bool has_sel  = sel_start != sel_end;

	int cur_line = 0;
	int cur_col  = 0;

	for (int i = 0; i < editor.text_len; )
	{
		sz read_bytes = math::min(editor.text_len - i, 4);
		Char32 c = conv::utf8_to_char32(&editor.text_buffer[i], &read_bytes) ?? editor.text_buffer[i];
		if (read_bytes == 0) read_bytes = 1;

		int rel_line = cur_line - editor.scroll_line;
		int rel_col  = cur_col - editor.scroll_col;

		bool is_visible = rel_line >= 0 && rel_line < visible_lines;

		int px = TEXT_START_X + rel_col * CHAR_WIDTH;
		int py = TEXT_START_Y + rel_line * LINE_HEIGHT;

		bool is_selected = has_sel && (i >= sel_start && i < sel_end);

		if (c == '\n')
		{
			if (is_selected && is_visible)
			{
				canvas.draw_rect_clipped({ px, py, CHAR_WIDTH, CHAR_HEIGHT + SELECTION_PADDING_Y }, text_clip, COLOR_SELECTION_BG);
			}
			cur_line++;
			cur_col = 0;
			i += read_bytes;
			continue;
		}

		if (is_visible && px + CHAR_WIDTH >= TEXT_START_X && px < width)
		{
			if (is_selected)
			{
				canvas.draw_rect_clipped({ px, py, CHAR_WIDTH, CHAR_HEIGHT + SELECTION_PADDING_Y }, text_clip, COLOR_SELECTION_BG);
				canvas.draw_char_clipped(px, py, c, FONT_SCALE, text_clip, COLOR_TEXT_BRIGHT);
			}
			else
			{
				canvas.draw_char_clipped(px, py, c, FONT_SCALE, text_clip, COLOR_TEXT);
			}
		}

		cur_col++;
		i += read_bytes;
	}

	// cursor
	if (editor.cursor_visible && active_rel_line >= 0 && active_rel_line < visible_lines)
	{
		int cx = TEXT_START_X + (ccol - editor.scroll_col) * CHAR_WIDTH;
		int cy = TEXT_START_Y + active_rel_line * LINE_HEIGHT;
		canvas.draw_rect_clipped({ cx, cy, CURSOR_WIDTH, CHAR_HEIGHT + CURSOR_EXTRA_HEIGHT }, text_clip, COLOR_CURSOR);
	}

	// gutter & line numbers
	canvas.draw_rect({ 0, HEADER_HEIGHT, GUTTER_WIDTH, editor_h }, COLOR_GUTTER_BG);
	canvas.draw_rect({ GUTTER_WIDTH, HEADER_HEIGHT, GUTTER_BORDER_W, editor_h }, COLOR_GUTTER_BORDER);

	int total_lines = editor.get_total_lines();
	for (int l = 0; l < visible_lines; l++)
	{
		int line_idx = l + editor.scroll_line;
		if (line_idx >= total_lines) break;

		int gy = TEXT_START_Y + l * LINE_HEIGHT;
		Rgba gcol = (line_idx == cline) ? COLOR_ACCENT_BLUE : COLOR_TEXT_MUTED;
		canvas.draw_gutter_number(4, gy, line_idx + 1, GUTTER_WIDTH - 8, FONT_SCALE, gcol);
	}

	// header
	canvas.draw_rect({ 0, 0, width, HEADER_HEIGHT }, COLOR_HEADER_BG);
	canvas.draw_text(12, 10, "C3 EDITOR", FONT_SCALE, COLOR_ACCENT_BLUE);

	int stat_x = 180;
	canvas.draw_text(stat_x, 10, "LN:", FONT_SCALE, COLOR_HEADER_MUTED);
	stat_x += 3 * CHAR_WIDTH + 6;
	canvas.draw_number(stat_x, 10, cline + 1, FONT_SCALE, COLOR_TEXT_BRIGHT);
	stat_x += 48;

	canvas.draw_text(stat_x, 10, "COL:", FONT_SCALE, COLOR_HEADER_MUTED);
	stat_x += 4 * CHAR_WIDTH + 6;
	canvas.draw_number(stat_x, 10, ccol + 1, FONT_SCALE, COLOR_TEXT_BRIGHT);
	stat_x += 48;

	int sel_count = math::abs(editor.cursor_pos - editor.sel_anchor);
	if (sel_count > 0)
	{
		canvas.draw_text(stat_x, 10, "SEL:", FONT_SCALE, COLOR_ACCENT_YELLOW);
		stat_x += 4 * CHAR_WIDTH + 6;
		canvas.draw_number(stat_x, 10, sel_count, FONT_SCALE, COLOR_ACCENT_YELLOW);
		stat_x += 48;
	}

	if (editor.shift_held)
	{
		canvas.draw_text(stat_x, 10, "[SHIFT]", FONT_SCALE, COLOR_ACCENT_GREEN);
		stat_x += 7 * CHAR_WIDTH + 12;
	}

	if (editor.ctrl_held)
	{
		canvas.draw_text(stat_x, 10, "[CTRL]", FONT_SCALE, COLOR_ACCENT_BLUE);
	}

	// footer
	int footer_y = height - FOOTER_HEIGHT;
	canvas.draw_rect({ 0, footer_y, width, FOOTER_HEIGHT }, COLOR_FOOTER_BG);

	char[40] clip_buf;
	String clip_s = string::bformat(&clip_buf, "CLIPBOARD: %d", editor.clipboard_len);
	canvas.draw_text(10, footer_y + 4, clip_s, FONT_SCALE, COLOR_HEADER_MUTED);

	char[40] undo_buf;
	String undo_s = string::bformat(&undo_buf, "UNDO: %d", editor.undo_count);
	canvas.draw_text(180, footer_y + 4, undo_s, FONT_SCALE, COLOR_HEADER_MUTED);

	char[64] info_buf;
	String info_s = string::bformat(&info_buf, "LINES: %d  CHARS: %d", total_lines, editor.text_len);
	int info_w = info_s.len * CHAR_WIDTH;
	canvas.draw_text(width - info_w - 12, footer_y + 4, info_s, FONT_SCALE, COLOR_HEADER_MUTED);

	return pixels;
}

fn int main()
{
	io::printn("C3 Canvas Text Editor Initialized.");
	return 0;
}