module main;
import std;
import raylib6;
import std::collections::gapbuffer;

// Config
const int TAB_SIZE_SPACES = 4;
const int MAX_UNDO_STATES = 32;

// Font Metrics & Scaling
const int GLYPH_WIDTH_CELLS   = 5;
const int GLYPH_HEIGHT_CELLS  = 8;
const int GLYPH_SPACING_CELLS = 1;

const int FONT_SCALE          = 2;
const int CHAR_WIDTH          = (GLYPH_WIDTH_CELLS + GLYPH_SPACING_CELLS) * FONT_SCALE;
const int CHAR_HEIGHT         = GLYPH_HEIGHT_CELLS * FONT_SCALE;
const int LINE_HEIGHT         = 22;
const int CURSOR_WIDTH        = 2;
const int CURSOR_EXTRA_HEIGHT = 2;
const int SELECTION_PADDING_Y = 2;

// Layout Geometry
const int HEADER_HEIGHT        = 38;
const int FOOTER_HEIGHT        = 26;
const int GUTTER_WIDTH         = 56;
const int GUTTER_BORDER_W      = 2;
const int GUTTER_PADDING_RIGHT = 8;
const int TEXT_PADDING_X       = 8;
const int TEXT_PADDING_Y       = 6;
const int TEXT_START_X         = GUTTER_WIDTH + GUTTER_BORDER_W + TEXT_PADDING_X;
const int TEXT_START_Y         = HEADER_HEIGHT + TEXT_PADDING_Y;

const float CURSOR_BLINK_RATE    = 0.5f;
const double DOUBLE_CLICK_TIME   = 0.35;
const int HORIZONTAL_SCROLL_STEP = 7;
const int VERTICAL_SCROLL_STEP   = 3;

alias Rgba = char[<4>];

// Color Palette
const Rgba COLOR_BG             = { 15, 23, 42, 255 };
const Rgba COLOR_HEADER_BG      = { 30, 41, 59, 255 };
const Rgba COLOR_FOOTER_BG      = { 30, 41, 59, 255 };
const Rgba COLOR_GUTTER_BG      = { 15, 23, 42, 255 };
const Rgba COLOR_GUTTER_BORDER  = { 51, 65, 85, 255 };
const Rgba COLOR_LINE_HIGHLIGHT = { 30, 41, 59, 160 };
const Rgba COLOR_TEXT           = { 226, 232, 240, 255 };
const Rgba COLOR_TEXT_BRIGHT    = { 248, 250, 252, 255 };
const Rgba COLOR_TEXT_MUTED     = { 100, 116, 139, 255 };
const Rgba COLOR_HEADER_MUTED   = { 148, 163, 184, 255 };
const Rgba COLOR_ACCENT_BLUE    = { 56, 189, 248, 255 };
const Rgba COLOR_ACCENT_GREEN   = { 74, 222, 128, 255 };
const Rgba COLOR_ACCENT_YELLOW  = { 250, 204, 21, 255 };
const Rgba COLOR_SELECTION_BG   = { 3, 105, 161, 255 };
const Rgba COLOR_CURSOR         = { 56, 189, 248, 255 };

// 5x8 Monospace Bitmap Font
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
	SLASH       { '/', 0b00001_00010_00010_00100_00100_01000_01000_10000 },
	BACKSLASH   { '\\', 0b10000_01000_01000_00100_00100_00010_00010_00001 },
	UNDERSCORE  { '_', 0b00000_00000_00000_00000_00000_00000_00000_11111 },
	ASTERISK    { '*', 0b00000_01010_00100_11111_00100_01010_00000_00000 },
	HASH        { '#', 0b01010_01010_11111_01010_11111_01010_01010_00000 },
	AT          { '@', 0b01110_10001_10111_10101_10110_10000_01111_00000 },
	AMPERSAND   { '&', 0b01100_10010_01100_01010_10001_10010_01101_00000 },
	TILDE       { '~', 0b00000_00000_01101_10010_00000_00000_00000_00000 },
	BACKTICK    { '`', 0b01000_00100_00010_00000_00000_00000_00000_00000 },
	DOLLAR      { '$', 0b00100_01111_10100_01110_00101_11110_00100_00000 },
	PERCENT     { '%', 0b11000_11001_00010_00100_01000_10011_00011_00000 },
	CARET       { '^', 0b00100_01010_10001_00000_00000_00000_00000_00000 },
	PIPE        { '|', 0b00100_00100_00100_00100_00100_00100_00100_00000 },
	ACUTE       { '´', 0b00010_00100_01000_00000_00000_00000_00000_00000 }, // ;)

	// Accented Symbols
	N_TILDE       { 'Ñ', 0b01100_10001_11001_10101_10011_10001_10001_00000 },
	LOWER_N_TILDE { 'ñ', 0b01100_00000_11110_10001_10001_10001_10001_00000 },

	UNKNOWN { '\0', 0b11111_10001_10101_10101_10101_10001_11111_00000 }
}

fn ulong get_char_bitmap(Char32 c) => runtime::@enum_lookup(FontGlyph, "ch", c).bitmap ?? FontGlyph.UNKNOWN.bitmap;

RLTexture font_texture;
bool font_texture_ready = false;

fn void init_font_texture()
{
	if (font_texture_ready) return;
	font_texture_ready = true;

	RLImage img = rl::gen_image_color(16 * 8, 16 * 8, { 0, 0, 0, 0 });

	for (int i = 0; i < 256; i++)
	{
		ulong bits = get_char_bitmap((Char32)i);
		int gx     = (i % 16) * 8;
		int gy     = (i / 16) * 8;

		for (int row = 0; row < GLYPH_HEIGHT_CELLS; row++)
		{
			for (int col_idx = 0; col_idx < GLYPH_WIDTH_CELLS; col_idx++)
			{
				int bit_pos = 39 - (row * GLYPH_WIDTH_CELLS + col_idx);
				if (((bits >> bit_pos) & 1) != 0)
				{
					rl::image_draw_pixel(&img, gx + col_idx, gy + row, rl::WHITE);
				}
			}
		}
	}

	font_texture = rl::load_texture_from_image(img);
	font_texture.set_filter(RLTextureFilter.POINT);
	rl::unload_image(img);
}

fn void draw_char(Char32 c, int px, int py, int scale, RLColor tint)
{
	int idx = (int)c;
	if (idx < 0 || idx >= 256) idx = 0;

	int gx = (idx % 16) * 8;
	int gy = (idx / 16) * 8;

	Rect src = { (float)gx, (float)gy, (float)GLYPH_WIDTH_CELLS, (float)GLYPH_HEIGHT_CELLS };
	Rect dst = { (float)px, (float)py, (float)(GLYPH_WIDTH_CELLS * scale), (float)(GLYPH_HEIGHT_CELLS * scale) };
	rl::draw_texture_pro(font_texture, src, dst, { 0, 0 }, 0.0f, tint);
}

fn void draw_text(String str, int px, int py, int scale, RLColor tint)
{
	int advance         = (GLYPH_WIDTH_CELLS + GLYPH_SPACING_CELLS) * scale;
	int cur_x           = px;
	StringIterator iter = str.iterator();
	while (try Char32 c = iter.next())
	{
		draw_char(c, cur_x, py, scale, tint);
		cur_x += advance;
	}
}

fn bool is_word_char(char c)   => c.is_alnum() || c == '_';
fn bool is_symbol_char(char c) => !is_word_char(c) && c != '\n' && c != '\r' && c != ' ';

struct TextRange
{
	sz start;
	sz end;
}

struct UndoSnapshot
{
	String text;
	sz cursor_pos;
	sz sel_anchor;
}

// Editor State

struct Editor
{
	GapBuffer buffer;
	sz cursor_pos;
	sz sel_anchor;
	int target_col;
	int scroll_line;
	int scroll_col;

	List{UndoSnapshot*} undo_stack;

	bool shift_held;
	bool ctrl_held;
	bool mouse_down;
	bool word_selecting;
	sz word_sel_anchor_start;
	sz word_sel_anchor_end;
	bool initialized;
	float blink_timer;
	bool cursor_visible;
	double last_click_time;
	Vec2 last_click_pos;
}

fn void Editor.clear_undo_stack(&self)
{
	while (try snap = self.undo_stack.pop())
	{
		if (snap.text.len > 0) mem::free(snap.text.ptr);
		mem::free(snap);
	}
}

fn void Editor.load_text(&self, String str)
{
	self.clear_undo_stack();
	self.buffer.load_bytes((char[])str);
	self.cursor_pos = self.buffer.len();
	self.sel_anchor = self.cursor_pos;
	self.target_col = 0;
	self.scroll_line = 0;
	self.scroll_col = 0;
	self.undo_stack.init(mem);
}

fn void Editor.save_undo_state(&self)
{
	if (self.undo_stack.len() >= MAX_UNDO_STATES)
	{
		UndoSnapshot* old = self.undo_stack.pop_first()!!;
		if (old.text.len > 0) mem::free(old.text.ptr);
		mem::free(old);
	}

	UndoSnapshot* snap = mem::new(UndoSnapshot);
	snap.text = self.buffer.to_string(mem);
	snap.cursor_pos = self.cursor_pos;
	snap.sel_anchor = self.sel_anchor;
	self.undo_stack.push(snap);
}

fn void Editor.undo(&self)
{
	if (try snap = self.undo_stack.pop())
	{
		self.buffer.load_bytes((char[])snap.text);
		self.cursor_pos = snap.cursor_pos;
		self.sel_anchor = snap.sel_anchor;
		self.target_col = self.get_col(self.cursor_pos);
		if (snap.text.len > 0) mem::free(snap.text.ptr);
		mem::free(snap);
	}
}

extern fn void set_web_clipboard(ZString text) @feat(WASM);
fn void set_clipboard(ZString text)
{
	$if env::WASM:
		set_web_clipboard(text);
	$else
		rl::set_clipboard_text(text);
	$endif
}

fn void Editor.copy_selection(&self)
{
	if (self.cursor_pos == self.sel_anchor) return;
	sz start = math::min(self.cursor_pos, self.sel_anchor);
	sz end   = math::max(self.cursor_pos, self.sel_anchor);

	DString tmp;
	tmp.tinit();
	self.buffer.append_range_to_dstring(&tmp, start, end);
	set_clipboard(tmp.zstr_view());
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
	ZString clip = rl::get_clipboard_text();
	if (clip == null) return;
	String text = clip.str_view();
	if (text.len == 0) return;

	self.save_undo_state();
	self.delete_selection();

	self.buffer.insert_bytes(self.cursor_pos, (char[])text);
	self.cursor_pos += text.len;
	self.sel_anchor = self.cursor_pos;
	self.target_col = self.get_col(self.cursor_pos);
}

fn int Editor.get_line(&self, sz pos)
{
	return (int)self.buffer.count_char_range('\n', 0, pos);
}

fn int Editor.get_col(&self, sz pos)
{
	int col                = 0;
	GapBufferIterator iter = self.buffer.iterator(0, pos);
	while (try Char32 c = iter.next())
	{
		switch (c)
		{
			case '\n':
				col = 0;
			case '\t':
				int tab_spaces = TAB_SIZE_SPACES - (col % TAB_SIZE_SPACES);
				if (tab_spaces <= 0) tab_spaces = TAB_SIZE_SPACES;
				col += tab_spaces;
			case '\r':
				break;
			default:
				col++;
		}
	}
	return col;
}

fn int Editor.get_total_lines(&self)
{
	return (int)self.buffer.count_char_range('\n') + 1;
}

fn sz Editor.get_line_start(&self, sz pos)
{
	if (try idx = self.buffer.rindex_of_char('\n', pos))
	{
		return idx + 1;
	}
	return 0;
}

fn sz Editor.get_line_end(&self, sz pos)
{
	if (try idx = self.buffer.index_of_char('\n', pos))
	{
		return idx;
	}
	return self.buffer.len();
}

fn sz Editor.get_line_start_of_line(&self, int target_line)
{
	if (target_line <= 0) return 0;
	int cur_line = 0;
	sz pos       = 0;
	while (try next_nl = self.buffer.index_of_char('\n', pos))
	{
		cur_line++;
		pos = next_nl + 1;
		if (cur_line == target_line) return pos;
	}
	return self.buffer.len();
}

fn sz Editor.get_pos_from_line_col(&self, int target_line, int target_col)
{
	sz line_start = self.get_line_start_of_line(target_line);
	sz line_end   = self.get_line_end(line_start);

	GapBufferIterator iter = self.buffer.iterator(line_start, line_end);
	sz actual_pos          = line_start;
	int col                = 0;
	while (col < target_col && iter.has_next())
	{
		Char32 c = iter.next()!!;
		switch (c)
		{
			case '\t':
				int tab_spaces = TAB_SIZE_SPACES - (col % TAB_SIZE_SPACES);
				if (tab_spaces <= 0) tab_spaces = TAB_SIZE_SPACES;
				col += tab_spaces;
			case '\r':
				break;
			default:
				col++;
		}
		actual_pos = iter.byte_pos();
	}

	return actual_pos;
}

fn sz Editor.get_pos_from_mouse(&self, Vec2 mpos)
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

fn sz Editor.get_prev_char_pos(&self, sz pos)
{
	return self.buffer.prev_codepoint_pos(pos);
}

fn sz Editor.get_next_char_pos(&self, sz pos)
{
	return self.buffer.next_codepoint_pos(pos);
}

fn sz Editor.get_prev_word_pos(&self, sz pos)
{
	if (pos == 0) return 0;
	sz p = pos;
	while (p > 0 && !is_word_char(self.buffer[p - 1])) p--;
	while (p > 0 && is_word_char(self.buffer[p - 1])) p--;
	return p;
}

fn sz Editor.get_next_word_pos(&self, sz pos)
{
	sz len = self.buffer.len();
	if (pos >= len) return len;
	sz p = pos;
	while (p < len && !is_word_char(self.buffer[p])) p++;
	while (p < len && is_word_char(self.buffer[p])) p++;
	return p;
}

fn TextRange Editor.get_word_bounds(&self, sz pos)
{
	sz len = self.buffer.len();
	if (len == 0) return { 0, 0 };

	sz p   = math::min(pos, len - 1);
	char c = self.buffer[p];

	switch
	{
		case is_word_char(c):
			sz start = p;
			while (start > 0 && is_word_char(self.buffer[start - 1])) start--;
			sz end = p;
			while (end < len && is_word_char(self.buffer[end])) end++;
			return { start, end };
		case c == '\n' || c == '\r':
			return { p, p };
		default:
			sz start = p;
			while (start > 0 && is_symbol_char(self.buffer[start - 1])) start--;
			sz end = p;
			while (end < len && is_symbol_char(self.buffer[end])) end++;
			if (start == end) end = math::min(start + 1, len);
			return { start, end };
	}
}

fn void Editor.delete_selection(&self)
{
	if (self.cursor_pos == self.sel_anchor) return;
	sz start = math::min(self.cursor_pos, self.sel_anchor);
	sz end   = math::max(self.cursor_pos, self.sel_anchor);

	self.buffer.delete_range(start, end);
	self.cursor_pos = start;
	self.sel_anchor = start;
	self.target_col = self.get_col(self.cursor_pos);
}

fn void Editor.insert_codepoint(&self, Char32 c)
{
	// Expand tab to spaces (no tab glyph in font)
	if (c == '\t')
	{
		for (int i = 0; i < TAB_SIZE_SPACES; i++) self.insert_codepoint(' ');
		return;
	}

	char[4] buf;
	sz len = conv::char32_to_utf8(c, &buf) ?? 0;
	if (len == 0) return;

	self.save_undo_state();
	self.delete_selection();

	self.buffer.insert_bytes(self.cursor_pos, (char[])buf[:len]);
	self.cursor_pos += len;
	self.sel_anchor = self.cursor_pos;
	self.target_col = self.get_col(self.cursor_pos);
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
		sz prev = self.get_prev_char_pos(self.cursor_pos);
		self.buffer.delete_range(prev, self.cursor_pos);
		self.cursor_pos = prev;
		self.sel_anchor = self.cursor_pos;
		self.target_col = self.get_col(self.cursor_pos);
	}
}

fn void Editor.handle_delete(&self)
{
	if (self.cursor_pos != self.sel_anchor || self.cursor_pos < self.buffer.len())
	{
		self.save_undo_state();
	}
	if (self.cursor_pos != self.sel_anchor)
	{
		self.delete_selection();
		return;
	}
	if (self.cursor_pos < self.buffer.len())
	{
		sz next = self.get_next_char_pos(self.cursor_pos);
		self.buffer.delete_range(self.cursor_pos, next);
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

fn bool key_pressed_or_repeat(RLKeyboardKey key)
{
	return rl::is_key_pressed(key) || rl::is_key_pressed_repeat(key);
}

fn void Editor.poll_raylib_input(&self, int visible_lines, int visible_cols)
{
	sz prev_pos = self.cursor_pos;
	sz prev_len = self.buffer.len();

	self.shift_held = rl::is_key_down(LEFT_SHIFT) || rl::is_key_down(RIGHT_SHIFT);
	self.ctrl_held = rl::is_key_down(LEFT_CONTROL) || rl::is_key_down(RIGHT_CONTROL);

	RLVector2 mouse_v = rl::get_mouse_position();
	Vec2 mouse_pos    = { mouse_v.x, mouse_v.y };

	if (rl::is_mouse_button_pressed(LEFT))
	{
		self.mouse_down = true;
		double now     = rl::get_time();
		sz clicked_pos = self.get_pos_from_mouse(mouse_pos);
		float dx       = mouse_pos.x - self.last_click_pos.x;
		float dy       = mouse_pos.y - self.last_click_pos.y;
		float dist_sq  = dx * dx + dy * dy;

		if (now - self.last_click_time < DOUBLE_CLICK_TIME && dist_sq < 100.0f)
		{
			TextRange bounds = self.get_word_bounds(clicked_pos);

			self.word_selecting = true;
			self.word_sel_anchor_start = bounds.start;
			self.word_sel_anchor_end = bounds.end;

			self.sel_anchor = bounds.start;
			self.cursor_pos = bounds.end;
			self.target_col = self.get_col(self.cursor_pos);
			self.last_click_time = 0.0;
		}
		else
		{
			self.word_selecting = false;
			self.cursor_pos = clicked_pos;
			if (!self.shift_held) self.sel_anchor = self.cursor_pos;
			self.target_col = self.get_col(self.cursor_pos);
			self.last_click_time = now;
			self.last_click_pos = mouse_pos;
		}
	}
	else if (self.mouse_down && rl::is_mouse_button_down(LEFT))
	{
		sz cur_pos = self.get_pos_from_mouse(mouse_pos);
		if (self.word_selecting)
		{
			TextRange cur_bounds = self.get_word_bounds(cur_pos);

			if (cur_pos >= self.word_sel_anchor_start)
			{
				self.sel_anchor = self.word_sel_anchor_start;
				self.cursor_pos = cur_bounds.end;
			}
			else
			{
				self.sel_anchor = self.word_sel_anchor_end;
				self.cursor_pos = cur_bounds.start;
			}
			self.target_col = self.get_col(self.cursor_pos);
		}
		else
		{
			self.cursor_pos = cur_pos;
			self.target_col = self.get_col(self.cursor_pos);
		}
	}
	else if (rl::is_mouse_button_released(LEFT))
	{
		self.mouse_down = false;
		self.word_selecting = false;
	}

	float wheel = rl::get_mouse_wheel_move();
	if (wheel != 0.0f)
	{
		if (self.shift_held)
		{
			self.scroll_col = math::max(0, self.scroll_col - (int)wheel * HORIZONTAL_SCROLL_STEP);
		}
		else
		{
			int total_lines = self.get_total_lines();
			self.scroll_line = math::clamp(
				self.scroll_line - (int)wheel * VERTICAL_SCROLL_STEP, 
				0, 
				math::max(0, total_lines - 1)
			);


		}
	}

	// Typed characters
	int codepoint = rl::get_char_pressed();
	while (codepoint > 0)
	{
		if (!self.ctrl_held)
		{
			self.insert_codepoint((Char32)codepoint);
		}
		codepoint = rl::get_char_pressed();
	}

	// Shortcuts & Navigation
	if (self.ctrl_held)
	{
		if (rl::is_key_pressed(A))
		{
			self.sel_anchor = 0;
			self.cursor_pos = self.buffer.len();
			self.target_col = self.get_col(self.cursor_pos);
		}
		if (rl::is_key_pressed(C)) self.copy_selection();
		if (rl::is_key_pressed(X)) self.cut_selection();
		if (rl::is_key_pressed(V)) self.paste_clipboard();
		if (rl::is_key_pressed(Z)) self.undo();
	}

	if (rl::is_key_pressed(ESCAPE)) self.sel_anchor = self.cursor_pos;
	if (key_pressed_or_repeat(BACKSPACE)) self.handle_backspace();
	if (key_pressed_or_repeat(DELETE)) self.handle_delete();
	if (key_pressed_or_repeat(TAB)) self.insert_codepoint('\t');
	if (key_pressed_or_repeat(ENTER)) self.insert_codepoint('\n');

	if (key_pressed_or_repeat(PAGE_UP))
	{
		int line_pu        = self.get_line(self.cursor_pos);
		int target_line_pu = math::max(0, line_pu - visible_lines);
		self.cursor_pos = self.get_pos_from_line_col(target_line_pu, self.target_col);
		if (!self.shift_held) self.sel_anchor = self.cursor_pos;
	}
	if (key_pressed_or_repeat(PAGE_DOWN))
	{
		int line_pd        = self.get_line(self.cursor_pos);
		int tot_pd         = self.get_total_lines();
		int target_line_pd = math::min(tot_pd - 1, line_pd + visible_lines);
		self.cursor_pos = self.get_pos_from_line_col(target_line_pd, self.target_col);
		if (!self.shift_held) self.sel_anchor = self.cursor_pos;
	}
	if (key_pressed_or_repeat(LEFT))
	{
		sz new_pos_l = self.cursor_pos;
		if (self.ctrl_held)
		{
			new_pos_l = self.get_prev_word_pos(self.cursor_pos);
		}
		else if (!self.shift_held && self.cursor_pos != self.sel_anchor)
		{
			new_pos_l = math::min(self.cursor_pos, self.sel_anchor);
		}
		else
		{
			new_pos_l = self.get_prev_char_pos(self.cursor_pos);
		}

		self.cursor_pos = new_pos_l;
		if (!self.shift_held) self.sel_anchor = self.cursor_pos;
		self.target_col = self.get_col(self.cursor_pos);
	}
	if (key_pressed_or_repeat(RIGHT))
	{
		sz new_pos_r = self.cursor_pos;
		if (self.ctrl_held)
		{
			new_pos_r = self.get_next_word_pos(self.cursor_pos);
		}
		else if (!self.shift_held && self.cursor_pos != self.sel_anchor)
		{
			new_pos_r = math::max(self.cursor_pos, self.sel_anchor);
		}
		else
		{
			new_pos_r = self.get_next_char_pos(self.cursor_pos);
		}

		self.cursor_pos = new_pos_r;
		if (!self.shift_held) self.sel_anchor = self.cursor_pos;
		self.target_col = self.get_col(self.cursor_pos);
	}
	if (key_pressed_or_repeat(UP))
	{
		int line = self.get_line(self.cursor_pos);
		if (line > 0)
		{
			self.cursor_pos = self.get_pos_from_line_col(line - 1, self.target_col);
		}
		else
		{
			self.cursor_pos = 0;
			self.target_col = 0;
		}
		if (!self.shift_held) self.sel_anchor = self.cursor_pos;
	}
	if (key_pressed_or_repeat(DOWN))
	{
		int line = self.get_line(self.cursor_pos);
		int tot  = self.get_total_lines();
		if (line < tot - 1)
		{
			self.cursor_pos = self.get_pos_from_line_col(line + 1, self.target_col);
		}
		else
		{
			self.cursor_pos = self.buffer.len();
			self.target_col = self.get_col(self.cursor_pos);
		}
		if (!self.shift_held) self.sel_anchor = self.cursor_pos;
	}
	if (key_pressed_or_repeat(HOME))
	{
		self.cursor_pos = self.get_line_start(self.cursor_pos);
		if (!self.shift_held) self.sel_anchor = self.cursor_pos;
		self.target_col = self.get_col(self.cursor_pos);
	}
	if (key_pressed_or_repeat(END))
	{
		self.cursor_pos = self.get_line_end(self.cursor_pos);
		if (!self.shift_held) self.sel_anchor = self.cursor_pos;
		self.target_col = self.get_col(self.cursor_pos);
	}

	if (self.cursor_pos != prev_pos || self.buffer.len() != prev_len)
	{
		self.reset_cursor_blink();
		self.ensure_cursor_visible(visible_lines, visible_cols);
	}
}

Editor editor;

fn void update_draw_frame()
{
	init_font_texture();

	float dt   = rl::get_frame_time();
	int width  = rl::get_screen_width();
	int height = rl::get_screen_height();
	if (width <= 0) width = 1024;
	if (height <= 0) height = 768;

	if (!editor.initialized)
	{
		editor.initialized = true;
		editor.load_text(
			`// C3 + Raylib Text Editor Engine (Gap Buffer Backed)
//
// Supported Features & Shortcuts:
// - Buffer: Dynamic High-Performance Gap Buffer Data Structure
// - Font: Pixel-Perfect 5x8 Monospace Bitmap Font (2x Scale)
// - Mouse: Click positioning, Word Double-Click, Drag-to-select
// - Scrolling: Vertical & Horizontal (Shift + Wheel)
// - Navigation: Arrows, Home/End, PageUp/Down, Word Jumps (Ctrl + Arrows)
// - Selection: Shift + Navigation, Ctrl + A (Select All)
// - Clipboard: Ctrl+C (Copy), Ctrl+X (Cut), Ctrl+V (Paste from OS), Ctrl+Z (Undo)

ABCDEFGHIJKLMNOPQRSTUVWXYZ
abcdefghijklmnopqrstuvwxyz
0123456789
. , ! ? : ; " ' - + = < >
( ) [ ] { } / \ _ * # @ &
~ $ % ^ |
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

	editor.poll_raylib_input(visible_lines, visible_cols);

	rl::begin_drawing();
	rl::clear_background(COLOR_BG);

	// Scissor mode for editor viewport
	rl::begin_scissor_mode(TEXT_START_X, HEADER_HEIGHT, editor_w, editor_h);

	// active line highlight
	int cline           = editor.get_line(editor.cursor_pos);
	int ccol            = editor.get_col(editor.cursor_pos);
	int active_rel_line = cline - editor.scroll_line;

	if (active_rel_line >= 0 && active_rel_line < visible_lines)
	{
		int hl_y = TEXT_START_Y + active_rel_line * LINE_HEIGHT;
		rl::draw_rectangle(
			TEXT_START_X - TEXT_PADDING_X,
			hl_y - 1,
			editor_w + TEXT_PADDING_X,
			LINE_HEIGHT,
			COLOR_LINE_HIGHLIGHT
		);
	}

	// text & selection
	sz sel_start = math::min(editor.cursor_pos, editor.sel_anchor);
	sz sel_end   = math::max(editor.cursor_pos, editor.sel_anchor);
	bool has_sel = sel_start != sel_end;

	int cur_line = 0;
	int cur_col  = 0;

	GapBufferIterator iter = editor.buffer.iterator();
	while (iter.has_next())
	{
		sz i     = iter.byte_pos();
		Char32 c = iter.next()!!;

		int rel_line = cur_line - editor.scroll_line;
		int rel_col  = cur_col - editor.scroll_col;

		bool is_visible = rel_line >= 0 && rel_line < visible_lines;

		int px = TEXT_START_X + rel_col * CHAR_WIDTH;
		int py = TEXT_START_Y + rel_line * LINE_HEIGHT;

		bool is_selected = has_sel && (i >= sel_start && i < sel_end);

		switch (c)
		{
			case '\r':
				continue;
			case '\n':
				if (is_selected && is_visible)
				{
					rl::draw_rectangle(px, py, CHAR_WIDTH, CHAR_HEIGHT + SELECTION_PADDING_Y, COLOR_SELECTION_BG);
				}
				cur_line++;
				cur_col = 0;
				continue;
			case '\t':
				int tab_spaces = TAB_SIZE_SPACES - (cur_col % TAB_SIZE_SPACES);
				if (tab_spaces <= 0) tab_spaces = TAB_SIZE_SPACES;
				if (is_selected && is_visible)
				{
					rl::draw_rectangle(
						px,
						py,
						CHAR_WIDTH * tab_spaces,
						CHAR_HEIGHT + SELECTION_PADDING_Y,
						COLOR_SELECTION_BG
					);
				}
				cur_col += tab_spaces;
				continue;
			default:
				if (is_visible && px + CHAR_WIDTH >= TEXT_START_X && px < width)
				{
					if (is_selected)
					{
						rl::draw_rectangle(px, py, CHAR_WIDTH, CHAR_HEIGHT + SELECTION_PADDING_Y, COLOR_SELECTION_BG);
						draw_char(c, px, py, FONT_SCALE, COLOR_TEXT_BRIGHT);
					}
					else
					{
						draw_char(c, px, py, FONT_SCALE, COLOR_TEXT);
					}
				}
				cur_col++;
		}
	}

	// cursor
	if (editor.cursor_visible && active_rel_line >= 0 && active_rel_line < visible_lines)
	{
		int cx = TEXT_START_X + (ccol - editor.scroll_col) * CHAR_WIDTH;
		int cy = TEXT_START_Y + active_rel_line * LINE_HEIGHT;
		rl::draw_rectangle(cx, cy, CURSOR_WIDTH, CHAR_HEIGHT + CURSOR_EXTRA_HEIGHT, COLOR_CURSOR);
	}

	rl::end_scissor_mode();

	// gutter & line numbers
	rl::draw_rectangle(0, HEADER_HEIGHT, GUTTER_WIDTH, editor_h, COLOR_GUTTER_BG);
	rl::draw_rectangle(GUTTER_WIDTH, HEADER_HEIGHT, GUTTER_BORDER_W, editor_h, COLOR_GUTTER_BORDER);

	int total_lines = editor.get_total_lines();
	for (int l = 0; l < visible_lines; l++)
	{
		int line_idx = l + editor.scroll_line;
		if (line_idx >= total_lines) break;

		int gy       = TEXT_START_Y + l * LINE_HEIGHT;
		RLColor gcol = (line_idx == cline) ? COLOR_ACCENT_BLUE : COLOR_TEXT_MUTED;
		char[32] gbuf;
		String gs    = string::bformat(&gbuf, "%d", line_idx + 1);
		int text_w   = gs.len * CHAR_WIDTH;
		int draw_x   = GUTTER_WIDTH - GUTTER_PADDING_RIGHT - text_w;
		draw_text(gs, draw_x, gy, FONT_SCALE, gcol);
	}

	// header
	int header_text_y = (HEADER_HEIGHT - CHAR_HEIGHT) / 2;
	rl::draw_rectangle(0, 0, width, HEADER_HEIGHT, COLOR_HEADER_BG);
	draw_text("C3 EDITOR", 12, header_text_y, FONT_SCALE, COLOR_ACCENT_BLUE);

	int stat_x = 150;

	draw_text("LN:", stat_x, header_text_y, FONT_SCALE, COLOR_HEADER_MUTED);
	stat_x += 3 * CHAR_WIDTH + 6;

	char[32] ln_buf;
	String ln_str = string::bformat(&ln_buf, "%d", cline + 1);
	draw_text(ln_str, stat_x, header_text_y, FONT_SCALE, COLOR_TEXT_BRIGHT);
	stat_x += ln_str.len * CHAR_WIDTH + 16;

	draw_text("COL:", stat_x, header_text_y, FONT_SCALE, COLOR_HEADER_MUTED);
	stat_x += 4 * CHAR_WIDTH + 6;

	char[32] col_buf;
	String col_str = string::bformat(&col_buf, "%d", ccol + 1);
	draw_text(col_str, stat_x, header_text_y, FONT_SCALE, COLOR_TEXT_BRIGHT);
	stat_x += col_str.len * CHAR_WIDTH + 16;

	sz sel_count = editor.cursor_pos > editor.sel_anchor ? editor.cursor_pos - editor.sel_anchor
		: editor.sel_anchor - editor.cursor_pos;
	if (sel_count > 0)
	{
		draw_text("SEL:", stat_x, header_text_y, FONT_SCALE, COLOR_ACCENT_YELLOW);
		stat_x += 4 * CHAR_WIDTH + 6;
		char[32] sel_buf;
		String sel_str = string::bformat(&sel_buf, "%d", sel_count);
		draw_text(sel_str, stat_x, header_text_y, FONT_SCALE, COLOR_ACCENT_YELLOW);
		stat_x += sel_str.len * CHAR_WIDTH + 16;
	}

	if (editor.shift_held)
	{
		draw_text("[SHIFT]", stat_x, header_text_y, FONT_SCALE, COLOR_ACCENT_GREEN);
		stat_x += 7 * CHAR_WIDTH + 12;
	}

	if (editor.ctrl_held)
	{
		draw_text("[CTRL]", stat_x, header_text_y, FONT_SCALE, COLOR_ACCENT_BLUE);
	}

	// footer
	int footer_y      = height - FOOTER_HEIGHT;
	int footer_text_y = footer_y + (FOOTER_HEIGHT - CHAR_HEIGHT) / 2;
	rl::draw_rectangle(0, footer_y, width, FOOTER_HEIGHT, COLOR_FOOTER_BG);

	char[40] undo_buf;
	String undo_str = string::bformat(&undo_buf, "UNDO: %d", editor.undo_stack.len());
	draw_text(undo_str, 12, footer_text_y, FONT_SCALE, COLOR_HEADER_MUTED);

	char[64] info_buf;
	String info_s = string::bformat(&info_buf, "LINES: %d  CHARS: %d", total_lines, editor.buffer.len());
	int info_w    = info_s.len * CHAR_WIDTH;
	draw_text(info_s, width - info_w - 12, footer_text_y, FONT_SCALE, COLOR_HEADER_MUTED);

	rl::end_drawing();
}

fn int main(String[] args) @winmain
{
	rl::init_window(1600, 900, "C3 Text Editor - C3 & Raylib");

	$if env::WASM:
		emscripten_set_main_loop(&update_draw_frame, 60, 1);
	$else
		rl::set_target_fps(60);
		while (!rl::window_should_close())
		{
			update_draw_frame();
		}
		rl::close_window();
	$endif

	return 0;
}

alias Em_callback_func = fn void();
extern fn void emscripten_set_main_loop(Em_callback_func func, int fps, int simulate_infinite_loop);

// ######################################## //
// Module: std::collections::gapbuffer

module std::collections::gapbuffer;
import std::io, std::math;

const sz DEFAULT_CAPACITY = 1024;
const sz MIN_CAPACITY     = 16;

<* GapBuffer maintains a movable gap where insertions and deletions take place in O(1) time. *>
struct GapBuffer (Printable)
{
	char* entries;
	sz capacity;
	sz gap_start;
	sz gap_end;
	Allocator allocator;
}

<*
 Initialize the GapBuffer with a specific allocator and initial capacity.

 @param allocator : "The allocator to use"
 @param initial_capacity : "The starting capacity, defaults to DEFAULT_CAPACITY"
*>
fn void GapBuffer.init(&self, Allocator allocator = mem, sz initial_capacity = DEFAULT_CAPACITY)
{
	sz cap = math::max(MIN_CAPACITY, initial_capacity);
	self.allocator = allocator;
	self.entries = alloc::alloc_array(allocator, char, cap);
	self.capacity = cap;
	self.gap_start = 0;
	self.gap_end = cap;
}

<* Initialize the GapBuffer using the temporary allocator. *>
fn void GapBuffer.tinit(&self, sz initial_capacity = DEFAULT_CAPACITY)
{
	self.init(tmem, initial_capacity) @inline;
}

<* Create a new heap-allocated GapBuffer. *>
fn GapBuffer* new(Allocator allocator = mem, sz initial_capacity = DEFAULT_CAPACITY)
{
	GapBuffer* gb = alloc::new(allocator, GapBuffer);
	gb.init(allocator, initial_capacity);
	return gb;
}

<* Create a new temporary GapBuffer. *>
fn GapBuffer* temp(sz initial_capacity = DEFAULT_CAPACITY)
{
	return new(tmem, initial_capacity) @inline;
}

<* Free memory allocated for the GapBuffer. *>
fn void GapBuffer.free(&self)
{
	if (@unlikely(!self.entries)) return;
	Allocator alloc = self.allocator == null ? mem : self.allocator;
	alloc::free(alloc, self.entries);
	self.entries = null;
	self.capacity = 0;
	self.gap_start = 0;
	self.gap_end = 0;
}

<* Reset the buffer length to 0 without releasing allocated memory. *>
fn void GapBuffer.clear(&self) @inline
{
	self.gap_start = 0;
	self.gap_end = self.capacity;
}

<* Returns true if the buffer contains 0 characters. *>
fn bool GapBuffer.is_empty(&self) @inline
{
	return self.len() == 0;
}

<* Returns the number of characters in the buffer. *>
fn sz GapBuffer.len(&self) @operator(len) @inline
{
	return self.capacity - (self.gap_end - self.gap_start);
}

<* Returns the size of the internal gap. *>
fn sz GapBuffer.gap_size(&self) @inline
{
	return self.gap_end - self.gap_start;
}

<*
 Returns the character at the specified index.

 @require index < self.len() : "Access out of bounds"
*>
fn char GapBuffer.get(&self, sz index) @operator([]) @inline
{
	if (index < self.gap_start)
	{
		return self.entries[index];
	}
	return self.entries[index + (self.gap_end - self.gap_start)];
}

<*
 Returns a pointer to the character at the specified index.

 @require index < self.len() : "Access out of bounds"
*>
fn char* GapBuffer.get_ref(&self, sz index) @operator(&[]) @inline
{
	if (index < self.gap_start)
	{
		return &self.entries[index];
	}
	return &self.entries[index + (self.gap_end - self.gap_start)];
}

<*
 Sets the character at the specified index.

 @require index < self.len() : "Access out of bounds"
*>
fn void GapBuffer.set(&self, sz index, char val) @operator([]=) @inline
{
	if (index < self.gap_start)
	{
		self.entries[index] = val;
	}
	else
	{
		self.entries[index + (self.gap_end - self.gap_start)] = val;
	}
}

<* Returns the character at the specified index (convenience helper). *>
fn char GapBuffer.char_at(&self, sz index) @inline
{
	return self.get(index);
}

<*
 Returns the first character in the buffer.

 @require self.len() > 0 : "Buffer is empty"
*>
fn char GapBuffer.first(&self) @inline
{
	return self.get(0);
}

<*
 Returns the last character in the buffer.

 @require self.len() > 0 : "Buffer is empty"
*>
fn char GapBuffer.last(&self) @inline
{
	return self.get(self.len() - 1);
}

<* Returns a direct slice view of the prefix (bytes before gap). *>
fn char[] GapBuffer.prefix(&self) @inline
{
	if (self.gap_start == 0 || !self.entries) return { };
	return (char[])self.entries[:self.gap_start];
}

<* Returns a direct slice view of the suffix (bytes after gap). *>
fn char[] GapBuffer.suffix(&self) @inline
{
	sz suffix_len = self.capacity - self.gap_end;
	if (suffix_len == 0 || !self.entries) return { };
	return (char[])self.entries[self.gap_end:suffix_len];
}

<* Returns the prefix as a String view. *>
fn String GapBuffer.prefix_str(&self) @inline => (String)self.prefix();

<* Returns the suffix as a String view. *>
fn String GapBuffer.suffix_str(&self) @inline => (String)self.suffix();

<* Converts the entire buffer contents to a newly allocated String. *>
fn String GapBuffer.to_string(&self, Allocator allocator = mem)
{
	sz total = self.len();
	if (total == 0) return "";
	char* data  = alloc::alloc_array(allocator, char, total);
	char[] pref = self.prefix();
	if (pref.len > 0) mem::copy(data, pref.ptr, pref.len);
	char[] suff = self.suffix();
	if (suff.len > 0) mem::copy(&data[pref.len], suff.ptr, suff.len);
	return (String)data[:total];
}

<* Converts the buffer contents to a temporary String. *>
fn String GapBuffer.to_tstring(&self) @inline
{
	return self.to_string(tmem);
}

<* Printable interface implementation for io::printf / Formatter. *>
fn sz? GapBuffer.to_format(&self, Formatter* fmt) @dynamic
{
	sz total    = 0;
	char[] pref = self.prefix();
	if (pref.len > 0)
	{
		total += fmt.print((String)pref)!;
	}
	char[] suff = self.suffix();
	if (suff.len > 0)
	{
		total += fmt.print((String)suff)!;
	}
	return total;
}

<* Constant string representation for reflection/debugging. *>
fn String GapBuffer.to_constant_string(&self) @dynamic => "GapBuffer";

<* Append a range [start, end) directly to a DString without intermediate allocations. *>
fn void GapBuffer.append_range_to_dstring(&self, DString* ds, sz start, sz end)
{
	sz len = self.len();
	sz s   = math::min(start, len);
	sz e   = math::min(end, len);
	if (s >= e) return;

	char[] pref = self.prefix();
	char[] suff = self.suffix();

	sz pref_len = pref.len;
	if (s < pref_len)
	{
		sz p_end = math::min(e, pref_len);
		ds.append_bytes(pref[s:p_end - s]);
	}
	if (e > pref_len)
	{
		sz s_start = s > pref_len ? s - pref_len : 0;
		sz s_end   = e - pref_len;
		ds.append_bytes(suff[s_start:s_end - s_start]);
	}
}

<*
 Search backward for the last occurrence of char 'c' before 'before_pos'.

 @return ? NOT_FOUND : "If char is not found"
*>
fn sz? GapBuffer.rindex_of_char(&self, char c, sz before_pos = sz::max)
{
	sz len = self.len();
	sz p   = math::min(before_pos, len);
	if (p == 0) return NOT_FOUND~;

	char[] pref = self.prefix();
	char[] suff = self.suffix();

	sz pref_len = pref.len;
	if (p > pref_len)
	{
		sz suff_len = p - pref_len;
		String s    = (String)suff[:suff_len];
		if (try idx = s.rindex_of_char(c))
		{
			return pref_len + idx;
		}
		p = pref_len;
	}

	String s = (String)pref[:p];
	if (try idx = s.rindex_of_char(c))
	{
		return idx;
	}

	return NOT_FOUND~;
}

<*
 Search forward for the first occurrence of char 'c' starting from 'from_pos'.

 @return ? NOT_FOUND : "If char is not found"
*>
fn sz? GapBuffer.index_of_char(&self, char c, sz from_pos = 0)
{
	sz len = self.len();
	sz p   = math::min(from_pos, len);
	if (p >= len) return NOT_FOUND~;

	char[] pref = self.prefix();
	char[] suff = self.suffix();

	sz pref_len = pref.len;
	if (p < pref_len)
	{
		String s = (String)pref[p..];
		if (try idx = s.index_of_char(c))
		{
			return p + idx;
		}
		p = pref_len;
	}

	sz suff_start = p - pref_len;
	if (suff_start < suff.len)
	{
		String s = (String)suff[suff_start..];
		if (try idx = s.index_of_char(c))
		{
			return pref_len + suff_start + idx;
		}
	}
	return NOT_FOUND~;
}

<* Count occurrences of char 'c' in the range [start, end). *>
fn sz GapBuffer.count_char_range(&self, char c, sz start = 0, sz end = sz::max)
{
	sz len = self.len();
	sz s   = math::min(start, len);
	sz e   = math::min(end, len);
	if (s >= e) return 0;

	char[] pref   = self.prefix();
	char[] suff   = self.suffix();
	sz total      = 0;
	char[1] c_buf = { c };
	String needle = (String)c_buf[..];

	sz pref_len = pref.len;
	if (s < pref_len)
	{
		sz p_end = math::min(e, pref_len);
		total += ((String)pref[s:p_end - s]).count(needle);
	}
	if (e > pref_len)
	{
		sz s_start = s > pref_len ? s - pref_len : 0;
		sz s_end   = e - pref_len;
		total += ((String)suff[s_start:s_end - s_start]).count(needle);
	}
	return total;
}

<* Navigate to previous UTF-8 codepoint boundary before 'pos'. *>
fn sz GapBuffer.prev_codepoint_pos(&self, sz pos)
{
	if (pos == 0) return 0;
	sz len = self.len();
	sz p   = math::min(pos, len) - 1;
	while (p > 0 && (self.get(p) & 0xC0) == 0x80) p--;
	return p;
}

<* Navigate to next UTF-8 codepoint boundary after 'pos'. *>
fn sz GapBuffer.next_codepoint_pos(&self, sz pos)
{
	sz len = self.len();
	if (pos >= len) return len;
	sz p = pos + 1;
	while (p < len && (self.get(p) & 0xC0) == 0x80) p++;
	return p;
}

<* Ensure internal gap has at least 'needed' bytes available. *>
fn void GapBuffer.ensure_gap(&self, sz needed)
{
	if (self.gap_size() >= needed) return;

	Allocator alloc = self.allocator == null ? mem : self.allocator;
	sz old_len      = self.len();
	sz new_cap      = math::max(self.capacity * 2, old_len + needed + 1024);
	char* new_buf   = alloc::alloc_array(alloc, char, new_cap);

	// Copy prefix (before gap)
	if (self.gap_start > 0)
	{
		mem::copy(new_buf, self.entries, self.gap_start);
	}

	// Copy suffix (after gap) to the end of new buffer
	sz suffix_len  = self.capacity - self.gap_end;
	sz new_gap_end = new_cap - suffix_len;
	if (suffix_len > 0)
	{
		mem::copy(&new_buf[new_gap_end], &self.entries[self.gap_end], suffix_len);
	}

	if (self.entries != null)
	{
		alloc::free(alloc, self.entries);
	}

	self.entries = new_buf;
	self.capacity = new_cap;
	self.gap_end = new_gap_end;
}

<* Move the gap to 'pos' offset within the logical text. *>
fn void GapBuffer.move_gap(&self, sz pos)
{
	sz target = math::min(pos, self.len());
	if (target == self.gap_start) return;

	if (target < self.gap_start)
	{
		sz count = self.gap_start - target;
		mem::move(&self.entries[self.gap_end - count], &self.entries[target], count);
		self.gap_start -= count;
		self.gap_end -= count;
	}
	else
	{
		sz count = target - self.gap_start;
		mem::move(&self.entries[self.gap_start], &self.entries[self.gap_end], count);
		self.gap_start += count;
		self.gap_end += count;
	}
}

<* Insert a slice of bytes at 'pos'. *>
fn void GapBuffer.insert_bytes(&self, sz pos, char[] bytes)
{
	if (bytes.len == 0) return;
	self.move_gap(pos);
	self.ensure_gap(bytes.len);
	mem::copy(&self.entries[self.gap_start], bytes.ptr, bytes.len);
	self.gap_start += bytes.len;
}

<* Insert a single char at 'pos'. *>
fn void GapBuffer.insert_char(&self, sz pos, char c) @inline
{
	char[1] b = { c };
	self.insert_bytes(pos, (char[])b[..]);
}

<* Insert a String at 'pos'. *>
fn void GapBuffer.insert_str(&self, sz pos, String str) @inline
{
	self.insert_bytes(pos, (char[])str);
}

<* Delete bytes in the range [start, end). *>
fn void GapBuffer.delete_range(&self, sz start, sz end)
{
	sz len = self.len();
	sz s   = math::min(start, len);
	sz e   = math::min(end, len);
	if (s >= e) return;

	self.move_gap(s);
	sz count = e - s;
	self.gap_end += count;
}

<* Load bytes replacing entire buffer content. *>
fn void GapBuffer.load_bytes(&self, char[] bytes, Allocator allocator = mem)
{
	self.free();
	self.init(allocator, bytes.len + 1024);
	if (bytes.len > 0)
	{
		mem::copy(self.entries, bytes.ptr, bytes.len);
		self.gap_start = bytes.len;
	}
}

<* Decodes a Char32 codepoint at 'pos' and returns the bytes consumed via 'read_bytes'. *>
fn Char32 GapBuffer.get_char32(&self, sz pos, sz* read_bytes)
{
	sz len = self.len();
	if (pos >= len)
	{
		*read_bytes = 0;
		return 0;
	}
	sz max_read = math::min(len - pos, (sz)4);
	char[4] tmp;
	for (sz k = 0; k < max_read; k++)
	{
		tmp[k] = self.get(pos + k);
	}
	sz bytes = max_read;
	Char32 c = conv::utf8_to_char32(&tmp, &bytes) ?? (Char32)tmp[0];
	*read_bytes = bytes;
	return c;
}

// $##################################
// GapBufferIterator

<* 
 UTF-8 codepoint iterator for GapBuffer
*>
struct GapBufferIterator
{
	GapBuffer* buf;
	sz pos;
	sz limit;
}

<*
 Create an iterator over a GapBuffer range [start, end).
*>
fn GapBufferIterator GapBuffer.iterator(&self, sz start = 0, sz end = sz::max)
{
	sz len = self.len();
	sz s   = math::min(start, len);
	sz e   = math::min(end, len);
	if (e < s) e = s;
	return { self, s, e };
}

<*
 Reset iterator to beginning or 'start' offset.
*>
fn void GapBufferIterator.reset(&self, sz start = 0)
{
	self.pos = math::min(start, self.limit);
}

<*
 Check if there are more codepoints remaining.
*>
fn bool GapBufferIterator.has_next(&self) @inline
{
	return self.pos < self.limit;
}

<*
 Current byte position of iterator.
*>
fn sz GapBufferIterator.byte_pos(&self) @inline
{
	return self.pos;
}

<*
 Yield next Char32 codepoint.

 @return ? NO_MORE_ELEMENT : "When iteration reaches the end"
*>
fn Char32? GapBufferIterator.next(&self)
{
	if (self.pos >= self.limit) return NO_MORE_ELEMENT~;
	sz read_bytes = math::min(self.limit - self.pos, (sz)4);
	Char32 c      = self.buf.get_char32(self.pos, &read_bytes);
	if (read_bytes == 0) read_bytes = 1;
	self.pos += read_bytes;
	return c;
}

<*
 Peek next Char32 codepoint without advancing iterator.

 @return ? NO_MORE_ELEMENT : "When iteration reaches the end"
*>
fn Char32? GapBufferIterator.peek(&self)
{
	if (self.pos >= self.limit) return NO_MORE_ELEMENT~;
	sz read_bytes = math::min(self.limit - self.pos, (sz)4);
	Char32 c      = self.buf.get_char32(self.pos, &read_bytes);
	return c;
}