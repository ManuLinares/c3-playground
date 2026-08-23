// @asset: https://raw.githubusercontent.com/ManuLinares/c3ed/refs/heads/main/dep/IntoneMonoNerdFontMono-Regular.ttf.gz -> /dep/IntoneMonoNerdFontMono-Regular.ttf.gz

module c3ed::config;
import std, c3ed::gfx;

alias Color = char[<4>];

struct Theme
{
	Color bg;
	Color header_bg;
	Color tab_bg;
	Color tab_active_bg;
	Color tab_border;
	Color footer_bg;
	Color gutter_bg;
	Color gutter_border;
	Color line_highlight;
	Color text;
	Color text_bright;
	Color text_muted;
	Color tab_guide;
	Color indent_guide;
	Color indent_guide_active;
	Color header_muted;
	Color accent_blue;
	Color accent_green;
	Color accent_yellow;
	Color accent_red;
	Color selection_bg;
	Color cursor;
	Color scrollbar;
	Color scrollbar_act;
	Color git_added;
	Color git_modified;
	Color git_deleted;
	Color squiggle_error;
	Color squiggle_warn;
	Color minimap_bg;
	Color minimap_viewport;
	Color panel_bg;
	Color popup_bg;
	Color popup_border;
	Color popup_selected;
}

const Theme DEFAULT_THEME = {
	.bg                  = { 15, 23, 42, 255 },
	.header_bg           = { 30, 41, 59, 255 },
	.tab_bg              = { 20, 29, 47, 255 },
	.tab_active_bg       = { 15, 23, 42, 255 },
	.tab_border          = { 51, 65, 85, 255 },
	.footer_bg           = { 30, 41, 59, 255 },
	.gutter_bg           = { 15, 23, 42, 255 },
	.gutter_border       = { 51, 65, 85, 255 },
	.line_highlight      = { 30, 41, 59, 160 },
	.text                = { 226, 232, 240, 255 },
	.text_bright         = { 248, 250, 252, 255 },
	.text_muted          = { 100, 116, 139, 255 },
	.tab_guide           = { 71, 85, 105, 65 },
	.indent_guide        = { 51, 65, 85, 90 },
	.indent_guide_active = { 56, 189, 248, 180 },
	.header_muted        = { 148, 163, 184, 255 },
	.accent_blue         = { 56, 189, 248, 255 },
	.accent_green        = { 74, 222, 128, 255 },
	.accent_yellow       = { 250, 204, 21, 255 },
	.accent_red          = { 248, 113, 113, 255 },
	.selection_bg        = { 3, 105, 161, 255 },
	.cursor              = { 56, 189, 248, 255 },
	.scrollbar           = { 71, 85, 105, 180 },
	.scrollbar_act       = { 56, 189, 248, 220 },
	.git_added           = { 74, 222, 128, 255 },
	.git_modified        = { 250, 204, 21, 255 },
	.git_deleted         = { 248, 113, 113, 255 },
	.squiggle_error      = { 248, 113, 113, 230 },
	.squiggle_warn       = { 250, 204, 21, 230 },
	.minimap_bg          = { 10, 16, 30, 200 },
	.minimap_viewport    = { 56, 189, 248, 35 },
	.panel_bg            = { 12, 18, 34, 255 },
	.popup_bg            = { 24, 33, 52, 255 },
	.popup_border        = { 56, 189, 248, 200 },
	.popup_selected      = { 3, 105, 161, 220 }
};

struct LayoutMetricsConfig
{
	int gutter_padding_right;
	int gutter_border_w;
	int gutter_base_margin;
	int gutter_min_digits;
	int text_padding_x;
	int text_padding_y;
	int scrollbar_w;
	float scrollbar_min_thumb_h;
	int minimap_margin_right;
	int minimap_line_h;
	int minimap_min_thumb_h;
	float min_font_scale;
	float max_font_scale;
	float font_zoom_step;
	int scroll_wheel_lines;
	int scroll_wheel_cols;
	int modal_min_w;
	int modal_wide_min_w;
	int modal_list_h;
	int modal_input_box_h_min;
	int modal_input_box_padding;
	int modal_padding_x;
	int modal_padding_y;
	int modal_row_h_min;
	int terminal_min_h;
	int terminal_default_h;
	int popup_w;
	int popup_max_rows;
	int tab_min_w_gap;
	int tab_extra_padding;
}

const LayoutMetricsConfig LAYOUT_METRICS = {
	.gutter_padding_right    = 8,
	.gutter_border_w         = 2,
	.gutter_base_margin      = 10,
	.gutter_min_digits       = 4,
	.text_padding_x          = 8,
	.text_padding_y          = 6,
	.scrollbar_w             = 10,
	.scrollbar_min_thumb_h   = 20.0f,
	.minimap_margin_right    = 14,
	.minimap_line_h          = 2,
	.minimap_min_thumb_h     = 16,
	.min_font_scale          = 0.4f,
	.max_font_scale          = 4.0f,
	.font_zoom_step          = 0.1f,
	.scroll_wheel_lines      = 3,
	.scroll_wheel_cols       = 7,
	.modal_min_w             = 560,
	.modal_wide_min_w        = 760,
	.modal_list_h            = 420,
	.modal_input_box_h_min   = 28,
	.modal_input_box_padding = 12,
	.modal_padding_x         = 16,
	.modal_padding_y         = 14,
	.modal_row_h_min         = 24,
	.terminal_min_h          = 100,
	.terminal_default_h      = 220,
	.popup_w                 = 320,
	.popup_max_rows          = 8,
	.tab_min_w_gap           = 40,
	.tab_extra_padding       = 16
};

struct TimingConfig
{
	float cursor_blink_interval;
	double double_click_threshold;
	float double_click_dist_sq;
	float grep_debounce_interval;
	float save_msg_duration;
	float file_watcher_interval;
	float page_hold_multiplier;
	int max_page_speed;
}

const TimingConfig TIMING = {
	.cursor_blink_interval = 0.5f,
	.double_click_threshold = 0.35,
	.double_click_dist_sq   = 100.0f,
	.grep_debounce_interval = 0.18f,
	.save_msg_duration      = 2.0f,
	.file_watcher_interval  = 1.0f,
	.page_hold_multiplier   = 5.0f,
	.max_page_speed         = 10
};

struct EditorSettings
{
	int tab_size;
	bool use_spaces_for_tab;
	bool show_indent_guides;
	bool highlight_matching_brackets;
	bool show_git_gutter;
	bool show_minimap;
	int minimap_width;
	bool autocomplete_enabled;
	bool auto_close_brackets;
	bool format_on_save;
	bool file_watcher_enabled;
	float font_scale;
}

const EditorSettings DEFAULT_SETTINGS = {
	.tab_size                    = 4,
	.use_spaces_for_tab          = false,
	.show_indent_guides          = true,
	.highlight_matching_brackets = true,
	.show_git_gutter             = true,
	.show_minimap                = true,
	.minimap_width               = 68,
	.autocomplete_enabled        = true,
	.auto_close_brackets         = true,
	.format_on_save              = false,
	.file_watcher_enabled        = true,
	.font_scale                  = 1.0f
};

EditorSettings settings = DEFAULT_SETTINGS;
Theme theme = DEFAULT_THEME;

enum EditorCommand
{
	CMD_NONE,
	CMD_MOVE_LEFT,
	CMD_MOVE_RIGHT,
	CMD_MOVE_UP,
	CMD_MOVE_DOWN,
	CMD_MOVE_WORD_LEFT,
	CMD_MOVE_WORD_RIGHT,
	CMD_MOVE_LINE_START,
	CMD_MOVE_LINE_END,
	CMD_MOVE_FILE_START,
	CMD_MOVE_FILE_END,
	CMD_PAGE_UP,
	CMD_PAGE_DOWN,
	CMD_JUMP_MATCHING_BRACKET,
	CMD_ADD_CURSOR_ABOVE,
	CMD_ADD_CURSOR_BELOW,
	CMD_ADD_NEXT_OCCURRENCE,
	CMD_SELECT_ALL,
	CMD_SELECT_TO_TOP,
	CMD_SELECT_TO_BOTTOM,
	CMD_CLEAR_SELECTION,
	CMD_INSERT_TAB,
	CMD_INDENT,
	CMD_OUTDENT,
	CMD_BACKSPACE,
	CMD_DELETE,
	CMD_DELETE_WORD_LEFT,
	CMD_DELETE_WORD_RIGHT,
	CMD_ENTER,
	CMD_DUPLICATE_LINE,
	CMD_DELETE_LINE,
	CMD_MOVE_LINE_UP,
	CMD_MOVE_LINE_DOWN,
	CMD_TOGGLE_COMMENT,
	CMD_TO_UPPERCASE,
	CMD_TO_LOWERCASE,
	CMD_COPY,
	CMD_CUT,
	CMD_PASTE,
	CMD_UNDO,
	CMD_REDO,
	CMD_OPEN_FIND,
	CMD_OPEN_REPLACE,
	CMD_FIND_NEXT,
	CMD_FIND_PREV,
	CMD_REPLACE_NEXT,
	CMD_REPLACE_ALL,
	CMD_TOGGLE_CASE_SENSITIVITY,
	CMD_OPEN_QUICK_OPEN,
	CMD_OPEN_GLOBAL_GREP,
	CMD_OPEN_GOTO_LINE,
	CMD_OPEN_SYMBOL_OUTLINE,
	CMD_GOTO_NEXT_SYMBOL,
	CMD_GOTO_DEFINITION,
	CMD_TRIGGER_AUTOCOMPLETE,
	CMD_BUILD_PROJECT,
	CMD_COMPILE_THIS_FILE,
	CMD_RUN_PROJECT,
	CMD_RUN_THIS_FILE,
	CMD_TOGGLE_TERMINAL,
	CMD_NEW_TAB,
	CMD_CLOSE_TAB,
	CMD_NEXT_TAB,
	CMD_PREV_TAB,
	CMD_TAB_1,
	CMD_TAB_2,
	CMD_TAB_3,
	CMD_TAB_4,
	CMD_TAB_5,
	CMD_TAB_6,
	CMD_TAB_7,
	CMD_TAB_8,
	CMD_TAB_9,
	CMD_SAVE_FILE,
	CMD_SAVE_AS,
	CMD_QUIT,
	CMD_ZOOM_IN,
	CMD_ZOOM_OUT
}

bitstruct KeyModifiers : uint
{
	bool shift;
	bool ctrl;
	bool alt;
}

struct KeyBinding
{
	EditorCommand command;
	Key key;
	KeyModifiers mods;
}

const KeyBinding[*] KEYBINDINGS = {
	{ CMD_NEW_TAB, T, { .ctrl } },
	{ CMD_CLOSE_TAB, W, { .ctrl } },
	{ CMD_NEXT_TAB, TAB, { .ctrl } },
	{ CMD_PREV_TAB, TAB, { .ctrl, .shift } },
	{ CMD_TAB_1, ONE, { .alt } },
	{ CMD_TAB_2, TWO, { .alt } },
	{ CMD_TAB_3, THREE, { .alt } },
	{ CMD_TAB_4, FOUR, { .alt } },
	{ CMD_TAB_5, FIVE, { .alt } },
	{ CMD_TAB_6, SIX, { .alt } },
	{ CMD_TAB_7, SEVEN, { .alt } },
	{ CMD_TAB_8, EIGHT, { .alt } },
	{ CMD_TAB_9, NINE, { .alt } },
	{ CMD_BUILD_PROJECT, B, { .ctrl, .shift } },
	{ CMD_COMPILE_THIS_FILE, F5, { .ctrl, .shift } },
	{ CMD_RUN_PROJECT, F5, { } },
	{ CMD_RUN_THIS_FILE, F5, { .ctrl } },
	{ CMD_TOGGLE_TERMINAL, GRAVE, { .ctrl } },
	{ CMD_SAVE_FILE, S, { .ctrl } },
	{ CMD_SAVE_AS, S, { .ctrl, .shift } },
	{ CMD_QUIT, Q, { .ctrl } },
	{ CMD_OPEN_FIND, F, { .ctrl } },
	{ CMD_OPEN_REPLACE, H, { .ctrl } },
	{ CMD_TOGGLE_CASE_SENSITIVITY, C, { .alt } },
	{ CMD_OPEN_GLOBAL_GREP, F, { .ctrl, .shift } },
	{ CMD_OPEN_QUICK_OPEN, O, { .ctrl } },
	{ CMD_OPEN_QUICK_OPEN, P, { .ctrl } },
	{ CMD_OPEN_GOTO_LINE, G, { .ctrl } },
	{ CMD_GOTO_NEXT_SYMBOL, R, { .ctrl } },
	{ CMD_OPEN_SYMBOL_OUTLINE, R, { .ctrl, .shift } },
	{ CMD_FIND_NEXT, F3, { } },
	{ CMD_FIND_PREV, F3, { .shift } },
	{ CMD_GOTO_DEFINITION, F1, { } },
	{ CMD_TRIGGER_AUTOCOMPLETE, SPACE, { .ctrl } },
	{ CMD_UNDO, Z, { .ctrl } },
	{ CMD_REDO, Y, { .ctrl } },
	{ CMD_REDO, Z, { .ctrl, .shift } },
	{ CMD_COPY, C, { .ctrl } },
	{ CMD_CUT, X, { .ctrl } },
	{ CMD_PASTE, V, { .ctrl } },
	{ CMD_PASTE, INSERT, { .shift } },
	{ CMD_SELECT_ALL, A, { .ctrl } },
	{ CMD_ADD_NEXT_OCCURRENCE, D, { .ctrl } },
	{ CMD_ADD_CURSOR_ABOVE, UP, { .ctrl, .shift } },
	{ CMD_ADD_CURSOR_BELOW, DOWN, { .ctrl, .shift } },
	{ CMD_DUPLICATE_LINE, D, { .ctrl, .shift } },
	{ CMD_DELETE_LINE, K, { .ctrl, .shift } },
	{ CMD_TOGGLE_COMMENT, SLASH, { .ctrl } },
	{ CMD_TOGGLE_COMMENT, M, { .ctrl } },
	{ CMD_TO_LOWERCASE, U, { .ctrl } },
	{ CMD_TO_UPPERCASE, U, { .ctrl, .shift } },
	{ CMD_JUMP_MATCHING_BRACKET, B, { .ctrl } },
	{ CMD_JUMP_MATCHING_BRACKET, BACKSLASH, { .ctrl, .shift } },
	{ CMD_MOVE_LINE_UP, UP, { .alt } },
	{ CMD_MOVE_LINE_DOWN, DOWN, { .alt } },
	{ CMD_SELECT_TO_TOP, HOME, { .ctrl, .shift } },
	{ CMD_SELECT_TO_BOTTOM, END, { .ctrl, .shift } },
	{ CMD_MOVE_FILE_START, HOME, { .ctrl } },
	{ CMD_MOVE_FILE_END, END, { .ctrl } },
	{ CMD_MOVE_WORD_LEFT, LEFT, { .ctrl } },
	{ CMD_MOVE_WORD_RIGHT, RIGHT, { .ctrl } },
	{ CMD_DELETE_WORD_LEFT, BACKSPACE, { .ctrl } },
	{ CMD_DELETE_WORD_RIGHT, DELETE, { .ctrl } },
	{ CMD_MOVE_LEFT, LEFT, { } },
	{ CMD_MOVE_RIGHT, RIGHT, { } },
	{ CMD_MOVE_UP, UP, { } },
	{ CMD_MOVE_DOWN, DOWN, { } },
	{ CMD_MOVE_LINE_START, HOME, { } },
	{ CMD_MOVE_LINE_END, END, { } },
	{ CMD_PAGE_UP, PAGE_UP, { } },
	{ CMD_PAGE_DOWN, PAGE_DOWN, { } },
	{ CMD_BACKSPACE, BACKSPACE, { } },
	{ CMD_DELETE, DELETE, { } },
	{ CMD_ENTER, ENTER, { } },
	{ CMD_ENTER, KP_ENTER, { } },
	{ CMD_INSERT_TAB, TAB, { } },
	{ CMD_OUTDENT, TAB, { .shift } },
	{ CMD_CLEAR_SELECTION, ESCAPE, { } },
	{ CMD_ZOOM_IN, EQUAL, { .ctrl } },
	{ CMD_ZOOM_IN, KP_ADD, { .ctrl } },
	{ CMD_ZOOM_OUT, MINUS, { .ctrl } },
	{ CMD_ZOOM_OUT, KP_SUBTRACT, { .ctrl } }
};

fn EditorCommand resolve_key_command(Key key, KeyModifiers mods)
{
	foreach (&binding : KEYBINDINGS)
	{
		if (binding.key == key && (uint)binding.mods == (uint)mods)
		{
			return binding.command;
		}
	}

	if (mods.shift)
	{
		KeyModifiers no_shift = mods;
		no_shift.shift = false;
		foreach (&binding : KEYBINDINGS)
		{
			if (binding.key == key && (uint)binding.mods == (uint)no_shift)
			{
				switch (binding.command)
				{
					case CMD_MOVE_LEFT:
					case CMD_MOVE_RIGHT:
					case CMD_MOVE_UP:
					case CMD_MOVE_DOWN:
					case CMD_MOVE_WORD_LEFT:
					case CMD_MOVE_WORD_RIGHT:
					case CMD_MOVE_LINE_START:
					case CMD_MOVE_LINE_END:
					case CMD_PAGE_UP:
					case CMD_PAGE_DOWN:
					case CMD_DELETE_WORD_LEFT:
					case CMD_DELETE_WORD_RIGHT:
					case CMD_BACKSPACE:
					case CMD_DELETE:
					case CMD_ENTER:
						return binding.command;
					default: break;
				}
			}
		}
	}
	return CMD_NONE;
}
module c3ed;
import std;

alias BytePos = sz;

struct LineCol
{
	int line;
	int col;
}

struct TextRange
{
	BytePos start;
	BytePos end;
}

struct Cursor
{
	BytePos pos;
	BytePos anchor;
	int target_col;
}

fn bool Cursor.has_selection(&self) @inline => self.pos != self.anchor;
fn BytePos Cursor.sel_start(&self) @inline => math::min(self.pos, self.anchor);
fn BytePos Cursor.sel_end(&self) @inline => math::max(self.pos, self.anchor);

fn int compare_cursors(Cursor* a, Cursor* b)
{
	switch
	{
		case a.pos < b.pos: return -1;
		case a.pos > b.pos: return 1;
		case a.anchor < b.anchor: return -1;
		case a.anchor > b.anchor: return 1;
		default: return 0;
	}
}

fn bool is_word_char(char c) => c.is_alnum() || c == '_' || (c & 0x80) != 0;
fn bool is_symbol_char(char c) => !is_word_char(c) && c != '\n' && c != '\r' && c != ' ' && c != '\t';

fn BytePos get_prev_char_pos(PieceTable* pt, BytePos pos)
{
	if (pos == 0) return 0;
	BytePos len = pt.len();
	BytePos p   = math::min(pos, len) - 1;
	while (p > 0 && (pt.char_at(p) & 0xC0) == 0x80) p--;
	return p;
}

fn BytePos get_next_char_pos(PieceTable* pt, BytePos pos)
{
	BytePos len = pt.len();
	if (pos >= len) return len;
	BytePos p = pos + 1;
	while (p < len && (pt.char_at(p) & 0xC0) == 0x80) p++;
	return p;
}

fn BytePos get_prev_word_pos(PieceTable* pt, BytePos pos)
{
	if (pos == 0) return 0;
	BytePos len = pt.len();
	BytePos p   = math::min(pos, len);
	while (p > 0 && p < len && (pt.char_at(p) & 0xC0) == 0x80) p--;
	while (p > 0 && !is_word_char(pt.char_at(p - 1))) p = get_prev_char_pos(pt, p);
	while (p > 0 && is_word_char(pt.char_at(p - 1))) p = get_prev_char_pos(pt, p);
	return p;
}

fn BytePos get_next_word_pos(PieceTable* pt, BytePos pos)
{
	BytePos len = pt.len();
	if (pos >= len) return len;
	BytePos p = pos;
	while (p < len && (pt.char_at(p) & 0xC0) == 0x80) p++;
	while (p < len && !is_word_char(pt.char_at(p))) p = get_next_char_pos(pt, p);
	while (p < len && is_word_char(pt.char_at(p))) p = get_next_char_pos(pt, p);
	return p;
}

fn TextRange get_word_bounds(PieceTable* pt, BytePos pos)
{
	BytePos len = pt.len();
	if (len == 0) return { 0, 0 };

	BytePos p = math::min(pos, len);
	while (p > 0 && p < len && (pt.char_at(p) & 0xC0) == 0x80) p--;

	if (p == len || (p < len && !is_word_char(pt.char_at(p))))
	{
		if (pos > 0)
		{
			BytePos prev_p = get_prev_char_pos(pt, pos);
			if (is_word_char(pt.char_at(prev_p)))
			{
				p = prev_p;
			}
		}
	}

	if (p >= len) p = len - 1;
	while (p > 0 && (pt.char_at(p) & 0xC0) == 0x80) p--;
	char c = pt.char_at(p);

	switch
	{
		case is_word_char(c):
			BytePos start = p;
			while (start > 0 && is_word_char(pt.char_at(start - 1))) start = get_prev_char_pos(pt, start);
			BytePos end = p;
			while (end < len && is_word_char(pt.char_at(end))) end = get_next_char_pos(pt, end);
			return { start, end };
		case c == '\n' || c == '\r' || c == ' ' || c == '\t':
			return { p, p };
		default:
			BytePos start = p;
			while (start > 0 && is_symbol_char(pt.char_at(start - 1))) start = get_prev_char_pos(pt, start);
			BytePos end = p;
			while (end < len && is_symbol_char(pt.char_at(end))) end = get_next_char_pos(pt, end);
			if (start == end) end = get_next_char_pos(pt, start);
			return { start, end };
	}
}

struct Document
{
	String filepath;
	bool is_file_specified;
	bool is_modified;
	Time last_disk_mtime;

	PieceTable table;
	List{BytePos} line_starts;
	List{LineState} line_states;
	List{Cursor} cursors;
}

fn void Document.init(
	&self,
	Allocator allocator,
	String filepath = "untitled.c3",
	bool file_specified = false,
	char[] content = { },
	bool is_mmap = false,
	FileMmap mmap_handle = { },
	bool owns_buffer = true
)
{
	self.filepath = filepath.copy(allocator);
	self.is_file_specified = file_specified;
	self.is_modified = false;
	self.last_disk_mtime = (Time)0;

	self.table.init(allocator, content, is_mmap, mmap_handle, owns_buffer);
	self.line_starts.init(allocator, 32);
	self.line_states.init(allocator, 32);
	self.cursors.init(allocator, 8);
	self.cursors.push({ 0, 0, 0 });
}

fn void Document.free(&self, Allocator allocator)
{
	self.table.free();
	self.line_starts.free();
	self.line_states.free();
	self.cursors.free();
	if (self.filepath.len > 0)
	{
		alloc::free(allocator, self.filepath.ptr);
		self.filepath = "";
	}
	*self = { };
}

fn Cursor* Document.primary_cursor(&self)
{
	if (self.cursors.len() == 0)
	{
		self.cursors.push({ 0, 0, 0 });
	}
	return &self.cursors[0];
}

fn int Document.get_total_lines(&self)
{
	if (self.line_starts.len() == 0) return 1;
	return (int)self.line_starts.len();
}

fn BytePos Document.get_line_start_of_line(&self, int target_line)
{
	if (target_line <= 0 || self.line_starts.len() == 0) return 0;
	if (target_line >= (int)self.line_starts.len()) return self.table.len();
	return self.line_starts[(sz)target_line];
}

fn BytePos Document.get_line_start(&self, BytePos pos)
{
	int line = self.get_line(pos);
	return self.get_line_start_of_line(line);
}

fn BytePos Document.get_line_end(&self, BytePos pos)
{
	int line = self.get_line(pos);
	if (line + 1 < (int)self.line_starts.len())
	{
		return self.line_starts[(sz)(line + 1)] - 1;
	}
	return self.table.len();
}

fn int Document.get_line(&self, BytePos pos)
{
	sz len = self.line_starts.len();
	if (len <= 1 || pos == 0) return 0;
	BytePos total_len = self.table.len();
	if (pos > total_len) pos = total_len;

	sz low  = 0;
	sz high = len - 1;
	sz ans  = 0;
	while (low <= high)
	{
		sz mid = low + (high - low) / 2;
		if (self.line_starts[mid] <= pos)
		{
			ans = mid;
			low = mid + 1;
		}
		else
		{
			if (mid == 0) break;
			high = mid - 1;
		}
	}
	return (int)ans;
}

fn int Document.advance_col(&self, int col, char c) @inline
{
	if (c == '\t')
	{
		return col + (config::settings.tab_size - (col % config::settings.tab_size));
	}
	return col + 1;
}

fn int Document.get_col(&self, BytePos pos)
{
	BytePos total_len = self.table.len();
	if (pos > total_len) pos = total_len;

	BytePos line_start = self.get_line_start(pos);
	if (line_start > total_len) line_start = total_len;
	if (pos <= line_start) return 0;

	String line_slice = self.table.get_slice(line_start, pos, tmem);
	int col           = 0;
	sz p              = 0;

	while (p < line_slice.len)
	{
		char c = line_slice[p];
		switch (c)
		{
			case '\n':
				col = 0;
				p++;
			case '\r':
				p++;
			default:
				col = self.advance_col(col, c);
				sz char_len = 1;
				while (p + char_len < line_slice.len && (line_slice[p + char_len] & 0xC0) == 0x80) char_len++;
				p += char_len;
		}
	}
	return col;
}

fn LineCol Document.get_line_col(&self, BytePos pos) => { .line = self.get_line(pos), .col = self.get_col(pos) };

fn BytePos Document.get_pos_from_line_col(&self, int target_line, int target_col)
{
	BytePos line_start = self.get_line_start_of_line(target_line);
	BytePos line_end   = self.get_line_end(line_start);
	if (target_col <= 0 || line_start >= line_end) return line_start;

	String line_slice = self.table.get_slice(line_start, line_end, tmem);
	int col           = 0;
	sz p              = 0;

	while (p < line_slice.len && col < target_col)
	{
		char c = line_slice[p];
		switch (c)
		{
			case '\r':
				p++;
			default:
				col = self.advance_col(col, c);
				sz char_len = 1;
				while (p + char_len < line_slice.len && (line_slice[p + char_len] & 0xC0) == 0x80) char_len++;
				p += char_len;
		}
	}
	return line_start + (BytePos)p;
}

fn void Document.normalize_cursors(&self)
{
	if (self.cursors.len() == 0)
	{
		self.cursors.push({ 0, 0, 0 });
	}

	BytePos doc_len = self.table.len();
	foreach (&cur : self.cursors)
	{
		cur.pos = math::min(cur.pos, doc_len);
		cur.anchor = math::min(cur.anchor, doc_len);
		cur.target_col = self.get_col(cur.pos);
	}

	if (self.cursors.len() <= 1) return;

	sort::quicksort(&self.cursors, fn int (Cursor a, Cursor b) => compare_cursors(&a, &b));

	sz i = 0;
	while (i + 1 < self.cursors.len())
	{
		Cursor cur  = self.cursors[i];
		Cursor next = self.cursors[i + 1];

		bool cur_has_sel  = cur.has_selection();
		bool next_has_sel = next.has_selection();

		if (!cur_has_sel && !next_has_sel)
		{
			if (cur.pos == next.pos)
			{
				self.cursors.remove_at(i + 1);
				continue;
			}
		}
		else
		{
			BytePos cur_s  = cur.sel_start();
			BytePos cur_e  = cur.sel_end();
			BytePos next_s = next.sel_start();
			BytePos next_e = next.sel_end();

			if (next_s <= cur_e)
			{
				BytePos merged_s = math::min(cur_s, next_s);
				BytePos merged_e = math::max(cur_e, next_e);
				self.cursors[i].anchor = merged_s;
				self.cursors[i].pos = merged_e;
				self.cursors[i].target_col = self.get_col(merged_e);
				self.cursors.remove_at(i + 1);
				continue;
			}
		}
		i++;
	}
}

fn void Document.rebuild_line_index(&self) => @pool()
{
	if (self.line_starts.entries == null) self.line_starts.init(mem);
	self.line_starts.clear();
	self.line_starts.push(0);

	if (self.line_states.entries == null) self.line_states.init(mem);
	self.line_states.clear();

	BytePos piece_start_pos = 0;
	LineState current_state = LineState.NORMAL;

	foreach (&p : self.table.pieces)
	{
		char[] slice = (p.source == ORIGINAL) ? self.table.original_buffer[p.offset:p.length]
			: self.table.add_buffer[p.offset:p.length];

		sz line_start_idx = 0;
		for (sz i = 0; i < p.length; i++)
		{
			char c = slice[i];
			if (c == '\n')
			{
				String line_str = (String)slice[line_start_idx:i - line_start_idx];
				current_state = syntax::lex_state_only(line_str, current_state);
				self.line_states.push(current_state);

				self.line_starts.push(piece_start_pos + (BytePos)i + 1);
				line_start_idx = i + 1;
			}
		}

		if (line_start_idx < p.length)
		{
			String line_str = (String)slice[line_start_idx:p.length - line_start_idx];
			current_state = syntax::lex_state_only(line_str, current_state);
		}
		piece_start_pos += p.length;
	}

	self.line_states.push(current_state);
	self.normalize_cursors();
}

fn void Document.update_line_index_on_edit(
	&self,
	BytePos edit_start,
	BytePos deleted_len,
	BytePos inserted_len
) => @pool()
{
	BytePos total_len = self.table.len();
	if (edit_start > total_len) edit_start = total_len;

	int start_line   = self.get_line(edit_start);
	BytePos old_end  = edit_start + deleted_len;

	sz start_remove_idx = (sz)(start_line + 1);
	sz end_remove_idx   = start_remove_idx;

	while (end_remove_idx < self.line_starts.len() && self.line_starts[end_remove_idx] <= old_end)
	{
		end_remove_idx++;
	}

	sz remove_count = end_remove_idx - start_remove_idx;
	if (remove_count > 0)
	{
		sz remaining_starts = self.line_starts.len() - end_remove_idx;
		if (remaining_starts > 0)
		{
			mem::move(
				&self.line_starts.entries[start_remove_idx],
				&self.line_starts.entries[end_remove_idx],
				remaining_starts * BytePos::size
			);
		}
		self.line_starts.size -= remove_count;

		if (start_remove_idx < self.line_states.len())
		{
			sz states_end       = math::min(end_remove_idx, self.line_states.len());
			sz states_remove    = states_end - start_remove_idx;
			sz remaining_states = self.line_states.len() - states_end;
			if (remaining_states > 0)
			{
				mem::move(
					&self.line_states.entries[start_remove_idx],
					&self.line_states.entries[states_end],
					remaining_states * LineState::size
				);
			}
			self.line_states.size -= states_remove;
		}
	}

	BytePos insert_scan_end = edit_start + inserted_len;
	List{BytePos} new_line_starts;
	new_line_starts.tinit(16);

	for (BytePos p = edit_start; p < insert_scan_end; p++)
	{
		if (self.table.char_at(p) == '\n')
		{
			new_line_starts.push(p + 1);
		}
	}

	sz inserted_lines_count = new_line_starts.len();
	if (inserted_lines_count > 0)
	{
		sz insert_pos = (sz)(start_line + 1);
		sz old_total  = self.line_starts.len();

		self.line_starts.reserve(inserted_lines_count);
		self.line_starts.size += inserted_lines_count;

		sz to_shift = old_total - insert_pos;
		if (to_shift > 0)
		{
			mem::move(
				&self.line_starts.entries[insert_pos + inserted_lines_count],
				&self.line_starts.entries[insert_pos],
				to_shift * BytePos::size
			);
		}

		mem::copy(&self.line_starts.entries[insert_pos], new_line_starts.entries, inserted_lines_count * BytePos::size);

		self.line_states.reserve(inserted_lines_count);
		sz old_states_total = self.line_states.len();
		sz state_insert_pos = math::min(insert_pos - 1, old_states_total);
		self.line_states.size += inserted_lines_count;

		sz states_to_shift = old_states_total - state_insert_pos;
		if (states_to_shift > 0)
		{
			mem::move(
				&self.line_states.entries[state_insert_pos + inserted_lines_count],
				&self.line_states.entries[state_insert_pos],
				states_to_shift * LineState::size
			);
		}
		for (sz k = 0; k < inserted_lines_count; k++)
		{
			self.line_states.entries[state_insert_pos + k] = LineState.NORMAL;
		}
	}

	if (deleted_len != inserted_len)
	{
		sz subsequent_idx = (sz)(start_line + 1 + (int)inserted_lines_count);
		sz total_starts   = self.line_starts.len();
		if (inserted_len >= deleted_len)
		{
			BytePos diff = inserted_len - deleted_len;
			for (sz i = subsequent_idx; i < total_starts; i++)
			{
				self.line_starts.entries[i] += diff;
			}
		}
		else
		{
			BytePos diff = deleted_len - inserted_len;
			for (sz i = subsequent_idx; i < total_starts; i++)
			{
				self.line_starts.entries[i] -= diff;
			}
		}
	}

	int total_lines = (int)self.line_starts.len();
	while (self.line_states.len() < (sz)total_lines)
	{
		self.line_states.push(LineState.NORMAL);
	}

	int cur_line = start_line;
	while (cur_line < total_lines)
	{
		BytePos l_start = self.get_line_start_of_line(cur_line);
		BytePos l_end   = self.get_line_end(l_start);
		String line_str = self.table.get_slice(l_start, l_end, tmem);

		LineState prev_state = (cur_line == 0) ? LineState.NORMAL : self.line_states[(sz)(cur_line - 1)];
		LineState new_state  = syntax::lex_state_only(line_str, prev_state);

		LineState old_state = self.line_states[(sz)cur_line];
		self.line_states[(sz)cur_line] = new_state;

		if (new_state == old_state && cur_line >= start_line + (int)inserted_lines_count)
		{
			break;
		}
		cur_line++;
	}
}

fn void Document.apply_cursor_edit(
	&self,
	Cursor* cur,
	BytePos start,
	BytePos end,
	char[] replacement,
	sz* delta
)
{
	BytePos del_len = end - start;
	BytePos ins_len = replacement.len;

	if (del_len > 0)
	{
		self.table.replace_range(start, end, replacement);
	}
	else if (ins_len > 0)
	{
		self.table.insert_bytes(start, replacement);
	}

	self.update_line_index_on_edit(start, del_len, ins_len);

	cur.pos        = start + ins_len;
	cur.anchor     = cur.pos;
	cur.target_col = self.get_col(cur.pos);
	*delta         = ins_len - del_len;
}

macro void Document.@mutate_cursors(&self; @body(Cursor* cur, sz* delta))
{
	self.table.begin_transaction(&self.cursors);
	sort::quicksort(&self.cursors, fn int (Cursor a, Cursor b) => compare_cursors(&a, &b));

	for (sz k = self.cursors.len(); k > 0; k--)
	{
		sz i = k - 1;
		Cursor* cur = &self.cursors[i];
		sz delta = 0;
		@body(cur, &delta);

		if (delta != 0)
		{
			for (sz j = i + 1; j < self.cursors.len(); j++)
			{
				self.cursors[j].pos += delta;
				self.cursors[j].anchor += delta;
			}
		}
	}
	self.normalize_cursors();
	self.table.end_transaction(&self.cursors);
	self.is_modified = true;
}

macro void Document.@mutate_selected_lines(&self; @body(int line_idx, BytePos l_start, BytePos l_end))
{
	List{int} lines = self.get_selected_or_cursor_lines();
	if (lines.len() == 0) return;

	self.table.begin_transaction(&self.cursors);

	for (sz k = lines.len(); k > 0; k--)
	{
		int l = lines[k - 1];
		BytePos l_start = self.get_line_start_of_line(l);
		BytePos l_end   = self.get_line_end(l_start);
		@body(l, l_start, l_end);
	}

	foreach (&cur : self.cursors) cur.target_col = self.get_col(cur.pos);
	self.normalize_cursors();
	self.table.end_transaction(&self.cursors);
	self.is_modified = true;
}

fn void Document.shift_cursors_after_edit(&self, BytePos edit_pos, BytePos del_len, BytePos ins_len)
{
	if (del_len > 0)
	{
		BytePos del_end = edit_pos + del_len;
		foreach (&cur : self.cursors)
		{
			if (cur.pos >= del_end)
			{
				cur.pos -= del_len;
			}
			else if (cur.pos >= edit_pos)
			{
				cur.pos = edit_pos;
			}

			if (cur.anchor >= del_end)
			{
				cur.anchor -= del_len;
			}
			else if (cur.anchor >= edit_pos)
			{
				cur.anchor = edit_pos;
			}
		}
	}
	if (ins_len > 0)
	{
		foreach (&cur : self.cursors)
		{
			if (cur.pos >= edit_pos) cur.pos += ins_len;
			if (cur.anchor >= edit_pos) cur.anchor += ins_len;
		}
	}
}

fn List{int} Document.get_selected_or_cursor_lines(&self)
{
	List{int} lines;
	lines.tinit(self.cursors.len() * 4);

	foreach (&cur : self.cursors)
	{
		int s_line = self.get_line(cur.sel_start());
		int e_line = self.get_line(cur.sel_end());
		if (cur.has_selection() && e_line > s_line && cur.sel_end() == self.get_line_start_of_line(e_line))
		{
			e_line--;
		}
		for (int l = s_line; l <= e_line; l++)
		{
			if (!lines.contains(l)) lines.push(l);
		}
	}

	sort::quicksort(&lines, fn int (int a, int b) => (a < b) ? -1 : ((a > b) ? 1 : 0));
	return lines;
}

fn void Document.insert_codepoint(&self, Char32 c)
{
	if (c == '\n')
	{
		self.handle_enter();
		return;
	}

	char close_pair = '\0';
	if (config::settings.auto_close_brackets)
	{
		switch (c)
		{
			case '(': close_pair = ')';
			case '[': close_pair = ']';
			case '{': close_pair = '}';
			case '"': close_pair = '"';
			case '\'': close_pair = '\'';
			default: break;
		}
	}

	char[4] buf;
	sz len = conv::char32_to_utf8(c, &buf) ?? 0;
	if (len == 0) return;

	self.@mutate_cursors(; cur, delta)
	{
		if (!cur.has_selection() && cur.pos < self.table.len())
		{
			char next_c = self.table.char_at(cur.pos);
			if ((c == ')' && next_c == ')') || (c == ']' && next_c == ']') || (c == '}' && next_c == '}')
				|| (c == '"' && next_c == '"')
				|| (c == '\'' && next_c == '\''))
			{
				cur.pos = get_next_char_pos(&self.table, cur.pos);
				cur.anchor = cur.pos;
				cur.target_col = self.get_col(cur.pos);
				return;
			}
		}

		BytePos start_sel = cur.sel_start();
		BytePos end_sel   = cur.sel_end();

		if (close_pair != '\0')
		{
			char[2] pair_buf = { (char)c, close_pair };
			self.apply_cursor_edit(cur, start_sel, end_sel, pair_buf[:2], delta);
			cur.pos = start_sel + 1;
			cur.anchor = cur.pos;
		}
		else
		{
			self.apply_cursor_edit(cur, start_sel, end_sel, buf[:len], delta);
		}
		cur.target_col = self.get_col(cur.pos);
	};
}

fn void Document.handle_enter(&self)
{
	self.@mutate_cursors(; cur, delta)
	{
		BytePos start_sel = cur.sel_start();
		BytePos end_sel   = cur.sel_end();

		BytePos line_start = self.get_line_start(start_sel);
		BytePos pos        = line_start;
		DString indent;
		indent.tinit();

		while (pos < start_sel)
		{
			char ch = self.table.char_at(pos);
			if (ch == ' ' || ch == '\t')
			{
				indent.append_char(ch);
				pos++;
			}
			else
			{
				break;
			}
		}

		bool between_braces = false;
		if (start_sel > 0 && end_sel < self.table.len())
		{
			char prev_c = self.table.char_at(get_prev_char_pos(&self.table, start_sel));
			char next_c = self.table.char_at(end_sel);
			if (prev_c == '{' && next_c == '}') between_braces = true;
		}

		if (between_braces)
		{
			DString ins;
			ins.tinit();
			ins.append_char('\n');
			ins.append(indent.str_view());
			ins.append_char('\t');

			BytePos target_cursor = start_sel + ins.str_view().len;

			ins.append_char('\n');
			ins.append(indent.str_view());

			String ins_str = ins.str_view();
			self.apply_cursor_edit(cur, start_sel, end_sel, (char[])ins_str, delta);

			cur.pos = target_cursor;
			cur.anchor = cur.pos;
			cur.target_col = self.get_col(cur.pos);
			return;
		}

		if (start_sel > 0)
		{
			char last_c = self.table.char_at(get_prev_char_pos(&self.table, start_sel));
			if (last_c == '{' || last_c == ':')
			{
				indent.append_char('\t');
			}
		}

		DString ins;
		ins.tinit();
		ins.append_char('\n');
		ins.append(indent.str_view());

		String ins_str = ins.str_view();
		self.apply_cursor_edit(cur, start_sel, end_sel, (char[])ins_str, delta);
	};
}

fn void Document.handle_backspace(&self)
{
	self.@mutate_cursors(; cur, delta)
	{
		switch
		{
			case cur.has_selection():
				self.apply_cursor_edit(cur, cur.sel_start(), cur.sel_end(), { }, delta);
			case cur.pos > 0:
				BytePos prev = get_prev_char_pos(&self.table, cur.pos);
				self.apply_cursor_edit(cur, prev, cur.pos, { }, delta);
		}
	};
}

fn void Document.handle_delete(&self)
{
	self.@mutate_cursors(; cur, delta)
	{
		switch
		{
			case cur.has_selection():
				self.apply_cursor_edit(cur, cur.sel_start(), cur.sel_end(), { }, delta);
			case cur.pos < self.table.len():
				BytePos next = get_next_char_pos(&self.table, cur.pos);
				self.apply_cursor_edit(cur, cur.pos, next, { }, delta);
		}
	};
}

fn void Document.delete_word_left(&self)
{
	self.@mutate_cursors(; cur, delta)
	{
		BytePos s = cur.has_selection() ? cur.sel_start() : get_prev_word_pos(&self.table, cur.pos);
		BytePos e = cur.has_selection() ? cur.sel_end() : cur.pos;
		if (e > s) self.apply_cursor_edit(cur, s, e, { }, delta);
	};
}

fn void Document.delete_word_right(&self)
{
	self.@mutate_cursors(; cur, delta)
	{
		BytePos s = cur.has_selection() ? cur.sel_start() : cur.pos;
		BytePos e = cur.has_selection() ? cur.sel_end() : get_next_word_pos(&self.table, cur.pos);
		if (e > s) self.apply_cursor_edit(cur, s, e, { }, delta);
	};
}

fn void Document.delete_selection(&self)
{
	self.@mutate_cursors(; cur, delta)
	{
		if (cur.has_selection())
		{
			self.apply_cursor_edit(cur, cur.sel_start(), cur.sel_end(), { }, delta);
		}
	};
}

fn void Document.indent_block(&self, bool outdent)
{
	self.@mutate_selected_lines(; l, l_start, l_end)
	{
		if (outdent)
		{
			if (l_start < l_end)
			{
				char ch    = self.table.char_at(l_start);
				sz del_len = 0;
				switch (ch)
				{
					case '\t':
						del_len = 1;
					case ' ':
						BytePos p = l_start;
						while (p < l_end && del_len < (sz)config::settings.tab_size && self.table.char_at(p) == ' ')
						{
							del_len++;
							p++;
						}
					default: break;
				}

				if (del_len > 0)
				{
					self.table.delete_range(l_start, l_start + del_len);
					self.update_line_index_on_edit(l_start, del_len, 0);
					self.shift_cursors_after_edit(l_start, del_len, 0);
				}
			}
		}
		else
		{
			self.table.insert_bytes(l_start, (char[])"\t");
			self.update_line_index_on_edit(l_start, 0, 1);
			self.shift_cursors_after_edit(l_start, 0, 1);
		}
	};
}

fn void Document.toggle_comment(&self)
{
	List{int} lines = self.get_selected_or_cursor_lines();
	if (lines.len() == 0) return;

	bool all_commented = true;
	foreach (l : lines)
	{
		BytePos l_start = self.get_line_start_of_line(l);
		BytePos l_end   = self.get_line_end(l_start);
		if (l_end <= l_start) continue;

		BytePos p = l_start;
		while (p < l_end && (self.table.char_at(p) == ' ' || self.table.char_at(p) == '\t')) p++;

		if (p + 1 >= l_end || self.table.char_at(p) != '/' || self.table.char_at(p + 1) != '/')
		{
			all_commented = false;
			break;
		}
	}

	self.@mutate_selected_lines(; l, l_start, l_end)
	{
		BytePos p = l_start;
		while (p < l_end && (self.table.char_at(p) == ' ' || self.table.char_at(p) == '\t')) p++;

		if (all_commented)
		{
			if (p + 1 < l_end && self.table.char_at(p) == '/' && self.table.char_at(p + 1) == '/')
			{
				BytePos del_len = (p + 2 < l_end && self.table.char_at(p + 2) == ' ') ? 3 : 2;
				self.table.delete_range(p, p + del_len);
				self.update_line_index_on_edit(p, del_len, 0);
				self.shift_cursors_after_edit(p, del_len, 0);
			}
		}
		else
		{
			self.table.insert_bytes(p, (char[])"// ");
			self.update_line_index_on_edit(p, 0, 3);
			self.shift_cursors_after_edit(p, 0, 3);
		}
	};
}

fn void Document.duplicate_line(&self)
{
	List{int} lines = self.get_selected_or_cursor_lines();
	if (lines.len() == 0) return;

	self.table.begin_transaction(&self.cursors);

	int first_line = lines[0];
	int last_line  = lines[lines.len() - 1];

	BytePos block_start = self.get_line_start_of_line(first_line);
	BytePos block_end   = self.get_line_end(self.get_line_start_of_line(last_line));

	DString block_str;
	block_str.tinit();
	block_str.append_char('\n');
	self.table.append_range_to_dstring(&block_str, block_start, block_end);

	String text = block_str.str_view();
	self.table.insert_bytes(block_end, (char[])text);
	self.update_line_index_on_edit(block_end, 0, text.len);

	sz shift_delta = text.len;
	foreach (&cur : self.cursors)
	{
		cur.pos += shift_delta;
		cur.anchor += shift_delta;
		cur.target_col = self.get_col(cur.pos);
	}

	self.normalize_cursors();
	self.table.end_transaction(&self.cursors);
	self.is_modified = true;
}

fn void Document.delete_line(&self)
{
	self.@mutate_selected_lines(; l, l_start, l_end)
	{
		BytePos del_start = l_start;
		BytePos del_end   = l_end;

		if (del_end < self.table.len())
		{
			if (self.table.char_at(del_end) == '\r' && self.table.char_at(del_end + 1) == '\n')
			{
				del_end += 2;
			}
			else if (self.table.char_at(del_end) == '\n' || self.table.char_at(del_end) == '\r')
			{
				del_end += 1;
			}
		}
		else if (del_start > 0)
		{
			if (self.table.char_at(del_start - 1) == '\n')
			{
				del_start--;
				if (del_start > 0 && self.table.char_at(del_start - 1) == '\r')
				{
					del_start--;
				}
			}
		}

		BytePos del_len = del_end - del_start;
		if (del_len > 0)
		{
			self.table.delete_range(del_start, del_end);
			self.update_line_index_on_edit(del_start, del_len, 0);
			self.shift_cursors_after_edit(del_start, del_len, 0);
		}
	};
}

fn void Document.move_lines_vertical(&self, bool move_up)
{
	List{int} lines = self.get_selected_or_cursor_lines();
	if (lines.len() == 0) return;

	int first_l = lines[0];
	int last_l  = lines[lines.len() - 1];
	int tot     = self.get_total_lines();

	if (move_up && first_l == 0) return;
	if (!move_up && last_l >= tot - 1) return;

	self.table.begin_transaction(&self.cursors);

	if (move_up)
	{
		int target_l = first_l - 1;
		BytePos target_start = self.get_line_start_of_line(target_l);
		BytePos target_end   = self.get_line_end(target_start);

		BytePos block_start  = self.get_line_start_of_line(first_l);
		BytePos block_end    = self.get_line_end(self.get_line_start_of_line(lines[lines.len() - 1]));

		String target_str = self.table.get_slice(target_start, target_end, tmem);
		String block_str  = self.table.get_slice(block_start, block_end, tmem);

		DString combined;
		combined.tinit();
		combined.append(block_str);
		combined.append_char('\n');
		combined.append(target_str);

		String s = combined.str_view();
		BytePos total_span = block_end - target_start;
		self.table.replace_range(target_start, block_end, (char[])s);
		self.update_line_index_on_edit(target_start, total_span, s.len);

		sz shift = target_str.len + 1;
		foreach (&cur : self.cursors)
		{
			cur.pos -= shift;
			cur.anchor -= shift;
			cur.target_col = self.get_col(cur.pos);
		}
	}
	else
	{
		int target_l = last_l + 1;
		BytePos block_start  = self.get_line_start_of_line(first_l);
		BytePos block_end    = self.get_line_end(self.get_line_start_of_line(last_l));

		BytePos target_start = self.get_line_start_of_line(target_l);
		BytePos target_end   = self.get_line_end(target_start);

		String block_str  = self.table.get_slice(block_start, block_end, tmem);
		String target_str = self.table.get_slice(target_start, target_end, tmem);

		DString combined;
		combined.tinit();
		combined.append(target_str);
		combined.append_char('\n');
		combined.append(block_str);

		String s = combined.str_view();
		BytePos total_span = target_end - block_start;
		self.table.replace_range(block_start, target_end, (char[])s);
		self.update_line_index_on_edit(block_start, total_span, s.len);

		sz shift = target_str.len + 1;
		foreach (&cur : self.cursors)
		{
			cur.pos += shift;
			cur.anchor += shift;
			cur.target_col = self.get_col(cur.pos);
		}
	}

	self.normalize_cursors();
	self.table.end_transaction(&self.cursors);
	self.is_modified = true;
}

fn void Document.convert_case_selection(&self, bool to_upper)
{
	self.table.begin_transaction(&self.cursors);
	sort::quicksort(&self.cursors, fn int (Cursor a, Cursor b) => compare_cursors(&a, &b));

	for (sz k = self.cursors.len(); k > 0; k--)
	{
		sz i = k - 1;
		Cursor* cur = &self.cursors[i];
		if (cur.has_selection())
		{
			BytePos start = cur.sel_start();
			BytePos end   = cur.sel_end();

			String text = self.table.get_slice(start, end, tmem);
			String modified = to_upper ? text.to_upper_tcopy() : text.to_lower_tcopy();

			self.table.replace_range(start, end, (char[])modified);
			self.update_line_index_on_edit(start, end - start, modified.len);

			if (cur.pos >= cur.anchor)
			{
				cur.anchor = start;
				cur.pos    = start + modified.len;
			}
			else
			{
				cur.pos    = start;
				cur.anchor = start + modified.len;
			}
			cur.target_col = self.get_col(cur.pos);
		}
	}
	self.normalize_cursors();
	self.table.end_transaction(&self.cursors);
	self.is_modified = true;
}

fn void Document.jump_to_matching_bracket(&self, bool select)
{
	if (self.table.len() == 0) return;
	Cursor* cur = self.primary_cursor();
	BytePos p   = cur.pos;
	if (p >= self.table.len()) p = self.table.len() - 1;

	char c          = self.table.char_at(p);
	char match_char = '\0';
	bool forward    = true;

	switch (c)
	{
		case '(': match_char = ')'; forward = true;
		case '[': match_char = ']'; forward = true;
		case '{': match_char = '}'; forward = true;
		case ')': match_char = '('; forward = false;
		case ']': match_char = '['; forward = false;
		case '}': match_char = '{'; forward = false;
		default:
			if (p > 0)
			{
				p = get_prev_char_pos(&self.table, p);
				c = self.table.char_at(p);
				switch (c)
				{
					case '(': match_char = ')'; forward = true;
					case '[': match_char = ']'; forward = true;
					case '{': match_char = '}'; forward = true;
					case ')': match_char = '('; forward = false;
					case ']': match_char = '['; forward = false;
					case '}': match_char = '{'; forward = false;
					default: break;
				}
			}
	}

	if (match_char == '\0') return;

	int depth     = 1;
	BytePos total = self.table.len();

	if (forward)
	{
		for (BytePos i = p + 1; i < total; i = get_next_char_pos(&self.table, i))
		{
			char ch = self.table.char_at(i);
			switch
			{
				case ch == c: depth++;
				case ch == match_char:
					depth--;
					if (depth == 0)
					{
						cur.pos = i;
						if (!select) cur.anchor = cur.pos;
						cur.target_col = self.get_col(cur.pos);
						return;
					}
			}
		}
	}
	else
	{
		BytePos i = p;
		while (i > 0)
		{
			i = get_prev_char_pos(&self.table, i);
			char ch = self.table.char_at(i);
			switch
			{
				case ch == c: depth++;
				case ch == match_char:
					depth--;
					if (depth == 0)
					{
						cur.pos = i;
						if (!select) cur.anchor = cur.pos;
						cur.target_col = self.get_col(cur.pos);
						return;
					}
			}
		}
	}
}

fn void Document.add_cursor_vertical(&self, bool above)
{
	foreach (&cur : self.cursors)
	{
		if (cur.has_selection()) return;
	}

	List{Cursor} new_list;
	new_list.tinit(self.cursors.len() * 2);
	int tot = self.get_total_lines();

	foreach (&cur : self.cursors)
	{
		new_list.push(*cur);
		int line = self.get_line(cur.pos);
		int target_l = above ? (line - 1) : (line + 1);
		if (target_l >= 0 && target_l < tot)
		{
			BytePos new_p = self.get_pos_from_line_col(target_l, cur.target_col);
			new_list.push({ new_p, new_p, cur.target_col });
		}
	}
	self.cursors.clear();
	foreach (&cur : new_list) self.cursors.push(*cur);
	self.normalize_cursors();
}

fn void Document.add_next_occurrence(&self, Tab* tab, int visible_lines, int visible_cols) => @pool()
{
	Cursor* prim = self.primary_cursor();

	if (!prim.has_selection())
	{
		TextRange bounds = get_word_bounds(&self.table, prim.pos);
		if (bounds.start < bounds.end)
		{
			prim.anchor = bounds.start;
			prim.pos = bounds.end;
			prim.target_col = self.get_col(prim.pos);
			tab.ensure_pos_visible(prim.pos, visible_lines, visible_cols);
			return;
		}
	}

	String query = self.table.get_slice(prim.sel_start(), prim.sel_end(), tmem);
	if (query.len == 0) return;
	sz qlen = query.len;
	if (self.table.len() < qlen) return;

	BytePos max_end = 0;
	foreach (&c : self.cursors)
	{
		max_end = math::max(max_end, c.sel_end());
	}

	if (max_end + qlen <= self.table.len())
	{
		if (try next_idx = self.table.find_forward(max_end, query, true))
		{
			BytePos n_start = next_idx;
			BytePos n_end = n_start + qlen;
			self.cursors.push({ .pos = n_end, .anchor = n_start, .target_col = self.get_col(n_end) });
			self.normalize_cursors();
			tab.ensure_pos_visible(n_end, visible_lines, visible_cols);
			return;
		}
	}

	BytePos scan_pos = 0;
	while (scan_pos + qlen <= self.table.len())
	{
		if (try idx = self.table.find_forward(scan_pos, query, true))
		{
			BytePos match_start = idx;
			BytePos match_end = match_start + qlen;

			bool already_selected = false;
			foreach (&c : self.cursors)
			{
				if (c.sel_start() == match_start && c.sel_end() == match_end)
				{
					already_selected = true;
					break;
				}
			}

			if (!already_selected)
			{
				self.cursors.push({ .pos = match_end, .anchor = match_start, .target_col = self.get_col(match_end) });
				self.normalize_cursors();
				tab.ensure_pos_visible(match_end, visible_lines, visible_cols);
				return;
			}
			scan_pos = match_start + 1;
		}
		else
		{
			break;
		}
	}
}

fn void Document.undo(&self)
{
	BytePos edit_start;
	BytePos del_len;
	BytePos ins_len;
	if (self.table.undo_with_range(&self.cursors, &edit_start, &del_len, &ins_len))
	{
		self.rebuild_line_index();
		self.normalize_cursors();
		self.is_modified = true;
	}
}

fn void Document.redo(&self)
{
	BytePos edit_start;
	BytePos del_len;
	BytePos ins_len;
	if (self.table.redo_with_range(&self.cursors, &edit_start, &del_len, &ins_len))
	{
		self.rebuild_line_index();
		self.normalize_cursors();
		self.is_modified = true;
	}
}

struct Tab
{
	Document doc;
	int scroll_line;
	int scroll_col;
}

fn void Tab.init(
	&self,
	Allocator allocator,
	String filepath = "untitled.c3",
	bool file_specified = false,
	char[] content = { },
	bool is_mmap = false,
	FileMmap mmap_handle = { },
	bool owns_buffer = true
)
{
	self.doc.init(allocator, filepath, file_specified, content, is_mmap, mmap_handle, owns_buffer);
	self.scroll_line = 0;
	self.scroll_col = 0;
}

fn void Tab.free(&self, Allocator allocator)
{
	self.doc.free(allocator);
	*self = { };
}

fn void Tab.ensure_pos_visible(&self, BytePos pos, int visible_lines, int visible_cols)
{
	int cursor_line  = self.doc.get_line(pos);
	switch
	{
		case cursor_line < self.scroll_line:
			self.scroll_line = cursor_line;
		case cursor_line >= self.scroll_line + visible_lines:
			self.scroll_line = cursor_line - visible_lines + 1;
	}
	self.scroll_line = math::clamp(self.scroll_line, 0, math::max(0, self.doc.get_total_lines() - 1));

	int cursor_col = self.doc.get_col(pos);
	switch
	{
		case cursor_col < self.scroll_col:
			self.scroll_col = cursor_col;
		case cursor_col >= self.scroll_col + visible_cols:
			self.scroll_col = cursor_col - visible_cols + 1;
	}
	if (self.scroll_col < 0) self.scroll_col = 0;
}

fn void Tab.ensure_cursor_visible(&self, int visible_lines, int visible_cols)
{
	self.ensure_pos_visible(self.doc.primary_cursor().pos, visible_lines, visible_cols);
}
module c3ed;
import std;

enum PendingSaveAction : char
{
	NONE,
	RUN_FILE,
	COMPILE_FILE
}

struct TerminalPanel
{
	bool is_open;
	bool is_running;
	List{String} lines;
	int scroll_line;
	bool auto_scroll;
	int height_px;
	String last_command;

	bool selecting;
	int sel_start_line;
	int sel_start_col;
	int sel_end_line;
	int sel_end_col;
}

fn void TerminalPanel.init(&self, Allocator allocator = mem)
{
	self.is_open = false;
	self.is_running = false;
	self.lines.init(allocator, 128);
	self.scroll_line = 0;
	self.auto_scroll = true;
	self.height_px = config::LAYOUT_METRICS.terminal_default_h;
	self.last_command = "";
	self.selecting = false;
	self.sel_start_line = 0;
	self.sel_start_col = 0;
	self.sel_end_line = 0;
	self.sel_end_col = 0;
}

fn void TerminalPanel.free(&self)
{
	foreach (l : self.lines)
	{
		if (l.len > 0) mem::free(l.ptr);
	}
	self.lines.free();
	if (self.last_command.len > 0) mem::free(self.last_command.ptr);
	*self = { };
}

fn bool TerminalPanel.has_selection(&self)
{
	return self.sel_start_line != self.sel_end_line || self.sel_start_col != self.sel_end_col;
}

fn void TerminalPanel.append_line(&self, String text)
{
	self.lines.push(text.copy(mem));
	if (self.lines.len() > 1000)
	{
		String removed = self.lines[0];
		if (removed.len > 0) mem::free(removed.ptr);
		self.lines.remove_at(0);
	}
	if (self.auto_scroll)
	{
		self.scroll_line = math::max(0, (int)self.lines.len() - 1);
	}
}

fn String? TerminalPanel.extract_selection(&self, Allocator allocator = tmem) => @pool()
{
	if (!self.has_selection() || self.lines.len() == 0) return NOT_FOUND~;

	int s_line = math::min(self.sel_start_line, self.sel_end_line);
	int e_line = math::max(self.sel_start_line, self.sel_end_line);
	s_line = math::clamp(s_line, 0, (int)self.lines.len() - 1);
	e_line = math::clamp(e_line, 0, (int)self.lines.len() - 1);

	DString ds;
	ds.tinit();

	for (int l = s_line; l <= e_line; l++)
	{
		String line_text = self.lines[(sz)l];
		int s_col = (l == s_line) ? math::min(self.sel_start_col, self.sel_end_col) : 0;
		int e_col = (l == e_line) ? math::max(self.sel_start_col, self.sel_end_col) : (int)line_text.len;

		s_col = math::clamp(s_col, 0, (int)line_text.len);
		e_col = math::clamp(e_col, 0, (int)line_text.len);

		if (s_col < e_col)
		{
			ds.append(line_text[s_col:e_col - s_col]);
		}
		if (l < e_line) ds.append_char('\n');
	}

	if (ds.len() == 0) return NOT_FOUND~;
	return ds.copy_str(allocator);
}

fn void TerminalPanel.execute(
	&self,
	DiagnosticStore* diagnostics,
	String[] cmd
) => @pool()
{
	self.is_open = true;
	self.is_running = true;
	self.append_line(string::tformat(">>> Running: %s", string::join(tmem, cmd, " ")));

	char[65536] buf;
	String? out = process::run_capture_stdout(&buf, cmd, options: STDERR_TO_STDOUT | INHERIT_ENV);
	self.is_running = false;

	if (try output_str = out)
	{
		Splitter split_lines = output_str.tokenize("\n");
		while (try l = split_lines.next())
		{
			self.append_line(l);
		}
		diagnostics.parse_output(output_str);
	}
	else
	{
		self.append_line("Execution failed.");
	}
}

struct CompletionItem
{
	String label;
	String detail;
	String insert_text;
	SymbolKind kind;
}

struct AutocompleteEngine
{
	List{CompletionItem} items;
	int selected_index;
	int scroll_offset;
	bool is_active;
}

fn void AutocompleteEngine.init(&self, Allocator allocator = mem)
{
	self.items.init(allocator, 64);
	self.selected_index = 0;
	self.scroll_offset = 0;
	self.is_active = false;
}

fn void AutocompleteEngine.free(&self, Allocator allocator = mem)
{
	self.clear_items();
	self.items.free();
	*self = { };
}

fn void AutocompleteEngine.clear_items(&self)
{
	foreach (&item : self.items)
	{
		if (item.label.len > 0) mem::free(item.label.ptr);
		if (item.detail.len > 0) mem::free(item.detail.ptr);
		if (item.insert_text.len > 0) mem::free(item.insert_text.ptr);
	}
	self.items.clear();
	self.selected_index = 0;
	self.scroll_offset = 0;
}

fn void AutocompleteEngine.collect_suggestions(
	&self,
	SymbolItem[] symbols,
	PieceTable* doc_table,
	BytePos cur_pos,
	String prefix,
	bool is_dot_access,
	bool is_scope_access,
	String parent_target = ""
) => @pool()
{
	self.clear_items();

	HashSet{String} seen;
	seen.tinit(256);

	String effective_parent = parent_target;
	if (is_dot_access && effective_parent.len > 0 && !effective_parent[0].is_upper())
	{
		BytePos scan_start = (cur_pos > 16384) ? cur_pos - 16384 : 0;
		String scope_text = doc_table.get_slice(scan_start, cur_pos, tmem);
		Splitter lines = scope_text.tokenize("\n");
		while (try l = lines.next())
		{
			String trimmed = l.trim();
			if (trimmed.contains(effective_parent))
			{
				Splitter words = trimmed.tokenize(" \t*&;,(){}");
				String prev_w = "";
				while (try w = words.next())
				{
					if (w == effective_parent && prev_w.len > 0 && prev_w[0].is_upper())
					{
						effective_parent = prev_w;
						break;
					}
					prev_w = w;
				}
			}
		}
	}

	if (is_dot_access)
	{
		foreach (&sym : symbols)
		{
			bool matches_parent = (effective_parent.len > 0 && sym.parent_type == effective_parent);
			if (!matches_parent && effective_parent.len > 0 && sym.parent_type.ends_with(effective_parent))
			{
				matches_parent = true;
			}

			if (matches_parent || (effective_parent.len == 0 && (sym.kind == FIELD || sym.kind == FUNCTION)))
			{
				if (prefix.len > 0 && !sym.name.to_lower_tcopy().starts_with(prefix.to_lower_tcopy())) continue;
				if (seen.contains(sym.name)) continue;
				seen.add(sym.name);

				self.items.push({
					.label       = sym.name.copy(mem),
					.detail      = sym.signature.len > 0 ? sym.signature.copy(mem) : sym.parent_type.copy(mem),
					.insert_text = sym.name.copy(mem),
					.kind        = sym.kind
				});
				if (self.items.len() >= 40) break;
			}
		}
		self.is_active = (self.items.len() > 0);
		return;
	}

	if (is_scope_access && parent_target.len > 0)
	{
		foreach (&sym : symbols)
		{
			if (sym.parent_type == parent_target || sym.parent_type.ends_with(parent_target))
			{
				if (prefix.len > 0 && !sym.name.to_lower_tcopy().starts_with(prefix.to_lower_tcopy())) continue;
				if (seen.contains(sym.name)) continue;
				seen.add(sym.name);

				self.items.push({
					.label       = sym.name.copy(mem),
					.detail      = sym.signature.copy(mem),
					.insert_text = sym.name.copy(mem),
					.kind        = sym.kind
				});
				if (self.items.len() >= 40) break;
			}
		}
		self.is_active = (self.items.len() > 0);
		return;
	}

	bool is_all_caps  = (prefix.len >= 2 && prefix[0].is_upper() && prefix[1].is_upper());
	bool is_type_name = (prefix.len >= 1 && prefix[0].is_upper());

	foreach (&sym : symbols)
	{
		if (is_all_caps && sym.kind != CONSTANT && sym.kind != FAULT && sym.kind != ENUM) continue;
		if (is_type_name && !is_all_caps && sym.kind != STRUCT && sym.kind != UNION && sym.kind != BITSTRUCT && sym.kind != ENUM && sym.kind != TYPE_ALIAS) continue;

		if (prefix.len > 0 && !sym.name.to_lower_tcopy().starts_with(prefix.to_lower_tcopy())) continue;
		if (seen.contains(sym.name)) continue;
		seen.add(sym.name);

		self.items.push({
			.label       = sym.name.copy(mem),
			.detail      = sym.signature.copy(mem),
			.insert_text = sym.name.copy(mem),
			.kind        = sym.kind
		});
		if (self.items.len() >= 30) break;
	}

	if (!is_all_caps)
	{
		foreach (tw : syntax::TokenType.TYPE.keywords)
		{
			if (prefix.len > 0 && !tw.to_lower_tcopy().starts_with(prefix.to_lower_tcopy())) continue;
			if (seen.contains(tw)) continue;
			seen.add(tw);
			self.items.push({
				.label       = tw.copy(mem),
				.detail      = "type".copy(mem),
				.insert_text = tw.copy(mem),
				.kind        = TYPE_ALIAS
			});
			if (self.items.len() >= 40) break;
		}

		foreach (kw : syntax::TokenType.KEYWORD.keywords)
		{
			if (prefix.len > 0 && !kw.to_lower_tcopy().starts_with(prefix.to_lower_tcopy())) continue;
			if (seen.contains(kw)) continue;
			seen.add(kw);
			self.items.push({
				.label       = kw.copy(mem),
				.detail      = "keyword".copy(mem),
				.insert_text = kw.copy(mem),
				.kind        = MACRO
			});
			if (self.items.len() >= 50) break;
		}
	}

	BytePos window_start = (cur_pos > 32768) ? cur_pos - 32768 : 0;
	BytePos window_end   = math::min(doc_table.len(), cur_pos + 32768);

	String local_str = doc_table.get_slice(window_start, window_end, tmem);
	Splitter words   = local_str.tokenize(" \t\n\r(){}[];:.,+-*/=<>!~&|^");

	while (try w = words.next())
	{
		if (w.len < 2 || w == prefix) continue;
		if (prefix.len > 0 && !w.to_lower_tcopy().starts_with(prefix.to_lower_tcopy())) continue;
		if (seen.contains(w)) continue;
		seen.add(w);

		self.items.push({
			.label       = w.copy(mem),
			.detail      = "word".copy(mem),
			.insert_text = w.copy(mem),
			.kind        = VARIABLE
		});
		if (self.items.len() >= 60) break;
	}

	self.is_active = (self.items.len() > 0);
}

struct Editor
{
	List{Tab} tabs;
	int active_tab_index;
	int pending_close_tab_index;
	int pending_reload_tab_index;
	PendingSaveAction pending_action_after_save;

	Workspace workspace;
	ModalState modal;
	TerminalPanel terminal;
	AutocompleteEngine autocomplete;

	float font_scale;
	KeyModifiers modifiers;
	bool mouse_down;
	int click_count;
	bool word_selecting;
	bool line_selecting;
	BytePos word_sel_anchor_start;
	BytePos word_sel_anchor_end;
	bool scrollbar_dragging;
	float scrollbar_drag_offset_y;
	bool minimap_dragging;
	float minimap_drag_offset_y;

	bool initialized;
	float blink_timer;
	bool cursor_visible;
	double last_click_time;
	Vec2 last_click_pos;
	float page_hold_timer;
	float save_msg_timer;
	bool should_exit;
}

fn Tab* Editor.active_tab(&self)
{
	if (self.tabs.len() == 0)
	{
		String uname = self.get_next_untitled_name(tmem);
		self.open_tab(uname, false, "");
	}
	if (self.active_tab_index < 0 || self.active_tab_index >= (int)self.tabs.len())
	{
		self.active_tab_index = 0;
	}
	return &self.tabs[(sz)self.active_tab_index];
}

fn Document* Editor.active_doc(&self) => &self.active_tab().doc;

fn void Editor.init(&self, String root_dir = ".")
{
	self.tabs.init(mem, 8);
	self.active_tab_index = 0;
	self.pending_close_tab_index = -1;
	self.pending_reload_tab_index = -1;
	self.pending_action_after_save = NONE;
	self.font_scale = config::settings.font_scale;
	self.workspace.init(mem, root_dir);
	self.modal.init(mem);
	self.terminal.init(mem);
	self.autocomplete.init(mem);
	self.initialized = true;
	self.blink_timer = 0.0f;
	self.cursor_visible = true;
	self.should_exit = false;
}

fn void Editor.free(&self)
{
	foreach (&t : self.tabs) t.free(mem);
	self.tabs.free();
	self.workspace.free(mem);
	self.modal.free();
	self.terminal.free();
	self.autocomplete.free(mem);
	font::cleanup_font();
	*self = { };
}

fn bool Editor.has_tab_or_file(&self, String candidate)
{
	foreach (&t : self.tabs)
	{
		if (t.doc.filepath == candidate) return true;
	}
	return file::exists(candidate);
}

fn String Editor.get_next_untitled_name(&self, Allocator allocator = mem) => @pool()
{
	int num = 1;
	while (true)
	{
		String candidate = (num == 1 && !self.has_tab_or_file("untitled.c3"))
			? "untitled.c3"
			: string::tformat("untitled-%d.c3", num);

		if (!self.has_tab_or_file(candidate))
		{
			return candidate.copy(allocator);
		}
		num++;
	}
}

fn int Editor.open_tab(
	&self,
	String filepath = "",
	bool file_specified = false,
	String initial_text = ""
)
{
	String actual_path = filepath;
	if (!file_specified && (actual_path.len == 0 || self.has_tab_or_file(actual_path)))
	{
		actual_path = self.get_next_untitled_name(tmem);
	}
	else if (actual_path.len == 0)
	{
		actual_path = "untitled.c3";
	}

	if (file_specified && actual_path.len > 0)
	{
		for (sz i = 0; i < self.tabs.len(); i++)
		{
			if (self.tabs[i].doc.is_file_specified && self.tabs[i].doc.filepath == actual_path)
			{
				self.active_tab_index = (int)i;
				self.reset_cursor_blink();
				return self.active_tab_index;
			}
		}

		if (self.tabs.len() == 1)
		{
			Tab* first = &self.tabs[0];
			if (!first.doc.is_file_specified && !first.doc.is_modified)
			{
				self.tabs[0].free(mem);
				self.tabs.remove_at(0);
			}
		}
	}

	Tab tab;
	if (file_specified && file::exists(actual_path))
	{
		FileMmap? mmap_res = file::mmap_open(actual_path, "r");
		if (try mm = mmap_res)
		{
			tab.init(mem, actual_path, file_specified, mm.bytes(), is_mmap: true, mmap_handle: mm);
		}
		else
		{
			char[]? data = file::load(mem, actual_path);
			tab.init(mem, actual_path, file_specified, data ?? {}, owns_buffer: true);
		}
		tab.doc.last_disk_mtime = file::last_modified(actual_path) ?? (Time)0;
	}
	else
	{
		tab.init(mem, actual_path, file_specified, (char[])initial_text.copy(mem), owns_buffer: true);
	}

	self.tabs.push(tab);
	self.active_tab_index = (int)self.tabs.len() - 1;
	self.active_tab().doc.rebuild_line_index();
	self.reset_cursor_blink();

	if (file_specified && file::exists(actual_path))
	{
		self.workspace.git.update(actual_path, self.active_tab().doc.get_total_lines());
	}
	return self.active_tab_index;
}

fn void Editor.request_close_tab(&self, int tab_idx)
{
	if (tab_idx < 0 || tab_idx >= (int)self.tabs.len()) return;
	Tab* t = &self.tabs[(sz)tab_idx];
	if (!t.doc.is_modified)
	{
		self.close_tab(tab_idx);
	}
	else
	{
		self.pending_close_tab_index = tab_idx;
		self.active_tab_index = tab_idx;
		self.modal.kind = CONFIRM_CLOSE_TAB;
		self.reset_cursor_blink();
	}
}

fn void Editor.close_tab(&self, int tab_idx)
{
	if (tab_idx < 0 || tab_idx >= (int)self.tabs.len()) return;

	self.tabs[tab_idx].free(mem);
	self.tabs.remove_at((sz)tab_idx);

	if (self.tabs.len() == 0)
	{
		String uname = self.get_next_untitled_name(tmem);
		self.open_tab(uname, false, "");
		self.active_tab_index = 0;
		self.reset_cursor_blink();
		return;
	}

	if (self.active_tab_index >= (int)self.tabs.len())
	{
		self.active_tab_index = (int)self.tabs.len() - 1;
	}
	self.reset_cursor_blink();
}

fn void Editor.reset_cursor_blink(&self)
{
	self.blink_timer = 0.0f;
	self.cursor_visible = true;
}

fn String Editor.get_modal_prompt(&self)
{
	String case_ind = self.modal.search_case_sensitive ? "Aa:ON" : "Aa:OFF";
	switch (self.modal.kind)
	{
		case GOTO_LINE:           return "GO TO LINE:";
		case FIND:                return string::tformat("FIND (%d matches) [Alt+C %s] - [Up/Down] Prev/Next [Esc] Close", self.modal.cached_match_count, case_ind);
		case REPLACE:             return string::tformat("FIND & REPLACE (%d matches) [Alt+C %s] - [Enter] Replace [Ctrl+Enter] Replace All [Tab] Switch", self.modal.cached_match_count, case_ind);
		case SAVE_AS:             return "SAVE FILE AS:";
		case QUICK_OPEN:          return string::tformat("QUICK FILE OPEN (Ctrl+O) - %d items", self.modal.picker.items.len());
		case GLOBAL_GREP:         return string::tformat("GLOBAL GREP (Ctrl+Shift+F) - %d matches", self.modal.picker.items.len());
		case SYMBOL_OUTLINE:      return string::tformat("DOCUMENT OUTLINE / SYMBOL PICKER (Ctrl+Shift+R) - %d symbols", self.modal.picker.items.len());
		case CONFIRM_EXIT:        return "UNSAVED CHANGES! Save all files before quitting?";
		case CONFIRM_CLOSE_TAB:   return "UNSAVED CHANGES! Save file before closing tab?";
		case CONFIRM_DISK_RELOAD: return "FILE MODIFIED EXTERNALLY! Reload disk version?";
		default:                  return "";
	}
}

fn Rect Editor.get_modal_rect(&self, LayoutMetrics* lm, int screen_w, int height)
{
	if (self.modal.kind == NONE) return { 0, 0, 0, 0 };

	String prompt = self.get_modal_prompt();
	int prompt_text_w = (int)prompt.len * lm.char_width;
	int modal_w       = math::max(config::LAYOUT_METRICS.modal_min_w, prompt_text_w + 48);

	if (self.modal.kind == QUICK_OPEN || self.modal.kind == GLOBAL_GREP || self.modal.kind == REPLACE || self.modal.kind == SYMBOL_OUTLINE)
	{
		modal_w = math::max(config::LAYOUT_METRICS.modal_wide_min_w, modal_w);
	}
	modal_w = math::min(modal_w, screen_w - config::LAYOUT_METRICS.tab_min_w_gap);

	int input_box_h = math::max(config::LAYOUT_METRICS.modal_input_box_h_min, lm.char_height + config::LAYOUT_METRICS.modal_input_box_padding);
	int modal_h;
	switch (self.modal.kind)
	{
		case CONFIRM_EXIT:
		case CONFIRM_CLOSE_TAB:
		case CONFIRM_DISK_RELOAD:
			modal_h = lm.char_height + input_box_h + 46;
		case REPLACE:
			modal_h = lm.char_height * 2 + input_box_h * 2 + 58;
		case QUICK_OPEN:
		case GLOBAL_GREP:
		case SYMBOL_OUTLINE:
			modal_h = config::LAYOUT_METRICS.modal_list_h;
		default:
			modal_h = lm.char_height + input_box_h + 46;
	}

	int modal_x = (screen_w - modal_w) / 2;
	int modal_y = (height - modal_h) / 3;

	return { (float)modal_x, (float)modal_y, (float)modal_w, (float)modal_h };
}

fn Rect Editor.get_case_toggle_rect(&self, LayoutMetrics* lm, int screen_w, int height)
{
	if (self.modal.kind != FIND && self.modal.kind != REPLACE) return { 0, 0, 0, 0 };
	Rect mrect = self.get_modal_rect(lm, screen_w, height);
	String prompt = self.get_modal_prompt();
	sz? tag_idx = prompt.index_of("[Alt+C");
	if (catch tag_idx) return { 0, 0, 0, 0 };

	int tag_pos = (int)tag_idx;
	String case_str = self.modal.search_case_sensitive ? "[Alt+C Aa:ON]" : "[Alt+C Aa:OFF]";
	int badge_x = (int)mrect.x + config::LAYOUT_METRICS.modal_padding_x + tag_pos * lm.char_width;
	int badge_w = (int)case_str.len * lm.char_width + 8;
	int badge_y = (int)mrect.y + 12;
	int badge_h = lm.char_height + 4;

	return { (float)(badge_x - 4), (float)badge_y, (float)badge_w, (float)badge_h };
}

fn void Editor.confirm_save_action(&self)
{
	switch (self.modal.kind)
	{
		case CONFIRM_CLOSE_TAB:
			int target_idx = self.pending_close_tab_index;
			if (target_idx >= 0 && target_idx < (int)self.tabs.len())
			{
				Tab* t = &self.tabs[(sz)target_idx];
				if (!t.doc.is_file_specified || t.doc.filepath.len == 0)
				{
					self.active_tab_index = target_idx;
					self.modal.kind = SAVE_AS;
					self.modal.input.set_text(t.doc.filepath);
				}
				else
				{
					file::save(t.doc.filepath, (char[])t.doc.table.to_tstring())!!;
					t.doc.is_modified = false;
					self.save_msg_timer = config::TIMING.save_msg_duration;
					int to_close = target_idx;
					self.pending_close_tab_index = -1;
					self.modal.kind = NONE;
					self.close_tab(to_close);
				}
			}
			else
			{
				self.modal.kind = NONE;
			}
		case CONFIRM_EXIT:
			foreach (&t : self.tabs)
			{
				if (t.doc.is_modified && t.doc.filepath.len > 0)
				{
					file::save(t.doc.filepath, (char[])t.doc.table.to_tstring())!!;
				}
			}
			self.should_exit = true;
		case CONFIRM_DISK_RELOAD:
			int reload_idx = self.pending_reload_tab_index >= 0 ? self.pending_reload_tab_index : self.active_tab_index;
			if (reload_idx >= 0 && reload_idx < (int)self.tabs.len())
			{
				Tab* t = &self.tabs[(sz)reload_idx];
				if (t.doc.is_file_specified && t.doc.filepath.len > 0)
				{
					t.doc.table.free();
					char[]? data = file::load(mem, t.doc.filepath);
					t.doc.table.init(mem, data ?? {}, owns_buffer: true);
					t.doc.rebuild_line_index();
					t.doc.is_modified = false;
					self.workspace.git.update(t.doc.filepath, t.doc.get_total_lines());
					self.save_msg_timer = config::TIMING.save_msg_duration;
				}
			}
			self.pending_reload_tab_index = -1;
			self.modal.kind = NONE;
		default: break;
	}
}

fn void Editor.confirm_discard_action(&self)
{
	switch (self.modal.kind)
	{
		case CONFIRM_CLOSE_TAB:
			int target_idx = self.pending_close_tab_index;
			self.pending_close_tab_index = -1;
			self.modal.kind = NONE;
			if (target_idx >= 0 && target_idx < (int)self.tabs.len())
			{
				self.close_tab(target_idx);
			}
		case CONFIRM_EXIT:
			self.should_exit = true;
		case CONFIRM_DISK_RELOAD:
			self.modal.kind = NONE;
		default: break;
	}
}

fn void Editor.confirm_cancel_action(&self)
{
	self.pending_close_tab_index = -1;
	self.modal.kind = NONE;
}

fn void Editor.goto_definition(&self, LayoutMetrics* lm) => @pool()
{
	Tab* tab = self.active_tab();
	Document* doc = &tab.doc;
	Cursor* cur = doc.primary_cursor();
	int cur_line = doc.get_line(cur.pos) + 1;

	TextRange bounds = get_word_bounds(&doc.table, cur.pos);
	if (bounds.start >= bounds.end) return;

	DString name_ds;
	name_ds.tinit();
	doc.table.append_range_to_dstring(&name_ds, bounds.start, bounds.end);
	String word = name_ds.str_view();
	if (word.len == 0) return;

	SymbolIndex local_lsp;
	local_lsp.init(tmem);
	local_lsp.index_source_text(doc.filepath, doc.table.to_tstring(), tmem);

	SymbolItem*? local_sym = local_lsp.find_symbol_closest(word, cur_line);
	if (try sym = local_sym)
	{
		BytePos target_pos = doc.get_pos_from_line_col(sym.line - 1, sym.col - 1);
		doc.cursors.clear();
		doc.cursors.push({ target_pos, target_pos, sym.col - 1 });
		tab.ensure_pos_visible(target_pos, lm.visible_lines, lm.visible_cols);
		self.reset_cursor_blink();
		return;
	}

	for (sz i = 0; i < self.tabs.len(); i++)
	{
		if ((int)i == self.active_tab_index) continue;
		Tab* other_tab = &self.tabs[i];
		SymbolIndex other_lsp;
		other_lsp.init(tmem);
		other_lsp.index_source_text(other_tab.doc.filepath, other_tab.doc.table.to_tstring(), tmem);
		if (try sym = other_lsp.find_symbol_closest(word, 0))
		{
			self.active_tab_index = (int)i;
			Tab* active = self.active_tab();
			BytePos target_pos = active.doc.get_pos_from_line_col(sym.line - 1, sym.col - 1);
			active.doc.cursors.clear();
			active.doc.cursors.push({ target_pos, target_pos, sym.col - 1 });
			active.ensure_pos_visible(target_pos, lm.visible_lines, lm.visible_cols);
			self.reset_cursor_blink();
			return;
		}
	}

	SymbolItem*? sym_opt = self.workspace.lsp.find_symbol_closest(word, 0);
	if (try sym = sym_opt)
	{
		self.open_tab(sym.filepath, true);
		Tab* new_tab = self.active_tab();

		BytePos target_pos = new_tab.doc.get_pos_from_line_col(sym.line - 1, sym.col - 1);
		new_tab.doc.cursors.clear();
		new_tab.doc.cursors.push({ target_pos, target_pos, sym.col - 1 });
		new_tab.ensure_pos_visible(target_pos, lm.visible_lines, lm.visible_cols);
		self.reset_cursor_blink();
	}
}

fn void Editor.goto_next_symbol(&self, LayoutMetrics* lm) => @pool()
{
	Tab* tab = self.active_tab();
	Document* doc = &tab.doc;
	Cursor* cur = doc.primary_cursor();
	int cur_l = doc.get_line(cur.pos) + 1;

	SymbolIndex doc_lsp;
	doc_lsp.init(tmem);
	doc_lsp.index_source_text(doc.filepath, doc.table.to_tstring(), tmem);

	if (doc_lsp.symbols.len() == 0) return;

	SymbolItem* target_sym = null;
	foreach (&s : doc_lsp.symbols)
	{
		if (s.line > cur_l)
		{
			target_sym = s;
			break;
		}
	}
	if (target_sym == null)
	{
		target_sym = &doc_lsp.symbols[0];
	}

	SymbolItem* s = target_sym;
	BytePos target_pos = doc.get_pos_from_line_col(s.line - 1, s.col - 1);
	doc.cursors.clear();
	doc.cursors.push({ target_pos, target_pos, s.col - 1 });
	tab.ensure_pos_visible(target_pos, lm.visible_lines, lm.visible_cols);
	self.reset_cursor_blink();
}

fn void Editor.trigger_autocomplete_at_cursor(&self) => @pool()
{
	Tab* tab = self.active_tab();
	Document* doc = &tab.doc;
	Cursor* cur = doc.primary_cursor();
	BytePos p = cur.pos;

	String prefix = "";
	String parent = "";
	bool is_dot = false;
	bool is_scope = false;

	if (p > 0)
	{
		char prev_c = doc.table.char_at(p - 1);
		if (prev_c == '.')
		{
			is_dot = true;
			TextRange b = get_word_bounds(&doc.table, p - 1);
			parent = doc.table.get_slice(b.start, b.end, tmem);
		}
		else if (p > 1 && prev_c == ':' && doc.table.char_at(p - 2) == ':')
		{
			is_scope = true;
			TextRange b = get_word_bounds(&doc.table, p - 2);
			parent = doc.table.get_slice(b.start, b.end, tmem);
		}
		else
		{
			TextRange b = get_word_bounds(&doc.table, p);
			prefix = doc.table.get_slice(b.start, p, tmem);
			if (b.start > 0 && doc.table.char_at(b.start - 1) == '.')
			{
				is_dot = true;
				TextRange pb = get_word_bounds(&doc.table, b.start - 1);
				parent = doc.table.get_slice(pb.start, pb.end, tmem);
			}
		}
	}

	self.autocomplete.collect_suggestions(
		self.workspace.lsp.symbols.array_view(),
		&doc.table,
		cur.pos,
		prefix,
		is_dot,
		is_scope,
		parent
	);

	self.autocomplete.is_active = (self.autocomplete.items.len() > 0);
	if (self.autocomplete.is_active)
	{
		self.autocomplete.selected_index = 0;
		self.autocomplete.scroll_offset = 0;
		self.reset_cursor_blink();
	}
}

fn void Editor.run_or_compile_file(&self, bool run, PendingSaveAction action) => @pool()
{
	Tab* tab = self.active_tab();
	if (!tab.doc.is_file_specified || tab.doc.filepath.len == 0)
	{
		self.modal.kind = SAVE_AS;
		self.modal.input.set_text(tab.doc.filepath);
		self.pending_action_after_save = action;
		return;
	}
	if (tab.doc.is_modified)
	{
		file::save(tab.doc.filepath, (char[])tab.doc.table.to_tstring())!!;
		tab.doc.is_modified = false;
		tab.doc.last_disk_mtime = file::last_modified(tab.doc.filepath) ?? (Time)0;
		self.workspace.git.update(tab.doc.filepath, tab.doc.get_total_lines());
		self.save_msg_timer = config::TIMING.save_msg_duration;
	}
	String[*] cmd = run
		? { "c3c", "compile-run", tab.doc.filepath }
		: { "c3c", "compile", tab.doc.filepath };

	self.terminal.execute(&self.workspace.diagnostics, cmd[..]);
}

fn void Editor.build_project(&self) => @pool()
{
	Tab* tab = self.active_tab();
	if (file::exists("project.json"))
	{
		String[*] cmd = { "c3c", "build" };
		self.terminal.execute(&self.workspace.diagnostics, cmd[..]);
	}
	else if (tab.doc.is_file_specified && tab.doc.filepath.len > 0)
	{
		self.run_or_compile_file(false, COMPILE_FILE);
	}
}

fn void Editor.run_project(&self) => @pool()
{
	Tab* tab = self.active_tab();
	if (file::exists("project.json"))
	{
		String[*] cmd = { "c3c", "run" };
		self.terminal.execute(&self.workspace.diagnostics, cmd[..]);
	}
	else if (tab.doc.is_file_specified && tab.doc.filepath.len > 0)
	{
		self.run_or_compile_file(true, RUN_FILE);
	}
}

fn String get_session_file_path(Allocator allocator, String workspace_dir) => @pool()
{
	Path? home = path::home_directory(tmem);
	if (catch home) return "";

	Path config_dir = home.tappend(".config") ?? home;
	Path c3ed_dir = config_dir.tappend("c3ed") ?? config_dir;
	(void)path::mkdir(c3ed_dir, recursive: true);

	uint hash_val = workspace_dir.hash();
	String fname = string::tformat("session_%x.ini", hash_val);
	Path? full_path = c3ed_dir.tappend(fname);
	if (catch full_path) return "";
	return ((String)full_path).copy(allocator);
}

fn void Editor.save_session(&self, String workspace_dir) => @pool()
{
	String spath = get_session_file_path(tmem, workspace_dir);
	if (spath.len == 0) return;

	Object* root = object::new_obj(tmem);

	Object* sess_sec = object::new_obj(tmem);
	sess_sec.set("active_tab", string::tformat("%d", self.active_tab_index));
	sess_sec.set("font_scale", string::tformat("%f", self.font_scale));
	sess_sec.set("terminal_open", self.terminal.is_open ? "true" : "false");
	sess_sec.set("tab_count", string::tformat("%d", self.tabs.len()));
	root.set("session", sess_sec);

	for (sz i = 0; i < self.tabs.len(); i++)
	{
		Tab* t = &self.tabs[i];
		Cursor* c = (t.doc.cursors.len() > 0) ? &t.doc.cursors[0] : null;
		BytePos pos = c ? c.pos : 0;
		BytePos anchor = c ? c.anchor : 0;

		Object* tab_sec = object::new_obj(tmem);
		tab_sec.set("filepath", t.doc.filepath);
		tab_sec.set("is_file_specified", t.doc.is_file_specified ? "true" : "false");
		tab_sec.set("scroll_line", string::tformat("%d", t.scroll_line));
		tab_sec.set("scroll_col", string::tformat("%d", t.scroll_col));
		tab_sec.set("cursor_pos", string::tformat("%d", (long)pos));
		tab_sec.set("cursor_anchor", string::tformat("%d", (long)anchor));

		root.set(string::tformat("tab_%d", i), tab_sec);
	}

	String encoded = ini::encode(tmem, root);
	(void)file::save(spath, (char[])encoded);
}

fn bool Editor.load_session(&self, String workspace_dir) => @pool()
{
	String spath = get_session_file_path(tmem, workspace_dir);
	if (spath.len == 0 || !file::exists(spath)) return false;

	char[]? content_opt = file::load(tmem, spath);
	if (catch content_opt) return false;
	String content = (String)content_opt;

	Object*? ini_obj = ini::parse(tmem, content);
	if (catch ini_obj) return false;
	Object* dom = ini_obj;

	Object*? sess_sec_opt = dom.get("session");
	if (catch sess_sec_opt) return false;
	Object* sess_sec = sess_sec_opt;

	int active_tab = sess_sec.get_string("active_tab").to_int() ?? sess_sec.get_int("active_tab") ?? 0;
	int tab_count  = sess_sec.get_string("tab_count").to_int() ?? sess_sec.get_int("tab_count") ?? 0;
	double scale   = sess_sec.get_string("font_scale").to_double() ?? sess_sec.get_float("font_scale") ?? 1.0;
	bool term_open = (sess_sec.get_string("terminal_open") ?? "false") == "true";

	if (tab_count <= 0) return false;

	while (self.tabs.len() > 0)
	{
		self.close_tab(0);
	}

	for (int i = 0; i < tab_count; i++)
	{
		String sec_name = string::tformat("tab_%d", i);
		Object*? t_sec_opt = dom.get(sec_name);
		if (catch t_sec_opt) continue;
		Object* t_sec = t_sec_opt;

		String fpath = t_sec.get_string("filepath") ?? "untitled.c3";
		bool f_spec  = (t_sec.get_string("is_file_specified") ?? "false") == "true";

		int s_line       = t_sec.get_string("scroll_line").to_int() ?? t_sec.get_int("scroll_line") ?? 0;
		int s_col        = t_sec.get_string("scroll_col").to_int() ?? t_sec.get_int("scroll_col") ?? 0;
		BytePos c_pos    = (BytePos)(t_sec.get_string("cursor_pos").to_int() ?? t_sec.get_int("cursor_pos") ?? 0);
		BytePos c_anc    = (BytePos)(t_sec.get_string("cursor_anchor").to_int() ?? t_sec.get_int("cursor_anchor") ?? 0);

		self.open_tab(fpath, f_spec);
		Tab* new_tab = self.active_tab();
		new_tab.scroll_line = s_line;
		new_tab.scroll_col = s_col;
		c_pos = math::min(c_pos, new_tab.doc.table.len());
		c_anc = math::min(c_anc, new_tab.doc.table.len());
		new_tab.doc.cursors.clear();
		new_tab.doc.cursors.push({ c_pos, c_anc, new_tab.doc.get_col(c_pos) });
	}

	self.active_tab_index = math::clamp(active_tab, 0, math::max(0, (int)self.tabs.len() - 1));
	self.font_scale = (float)scale;
	self.terminal.is_open = term_open;
	self.reset_cursor_blink();
	return (self.tabs.len() > 0);
}

macro void @move_cursors(doc, shift; @body(Cursor* cur))
{
	foreach (&cur : doc.cursors)
	{
		@body(cur);
		if (!shift) cur.anchor = cur.pos;
		cur.target_col = doc.get_col(cur.pos);
	}
	doc.normalize_cursors();
}

fn bool Editor.handle_tab_command(&self, EditorCommand cmd)
{
	switch (cmd)
	{
		case CMD_NEW_TAB:
			String uname = self.get_next_untitled_name(tmem);
			self.open_tab(uname, false, "");
			return true;

		case CMD_CLOSE_TAB:
			self.request_close_tab(self.active_tab_index);
			return true;

		case CMD_NEXT_TAB:
			if (self.tabs.len() > 1)
			{
				self.active_tab_index = (self.active_tab_index + 1) % (int)self.tabs.len();
				self.reset_cursor_blink();
			}
			return true;

		case CMD_PREV_TAB:
			if (self.tabs.len() > 1)
			{
				self.active_tab_index = (self.active_tab_index + (int)self.tabs.len() - 1) % (int)self.tabs.len();
				self.reset_cursor_blink();
			}
			return true;

		case CMD_TAB_1:
		case CMD_TAB_2:
		case CMD_TAB_3:
		case CMD_TAB_4:
		case CMD_TAB_5:
		case CMD_TAB_6:
		case CMD_TAB_7:
		case CMD_TAB_8:
		case CMD_TAB_9:
			int target_idx = (int)cmd - (int)EditorCommand.CMD_TAB_1;
			if (target_idx < (int)self.tabs.len())
			{
				self.active_tab_index = target_idx;
				self.reset_cursor_blink();
			}
			return true;

		default:
			return false;
	}
}

fn bool Editor.handle_nav_command(&self, EditorCommand cmd, LayoutMetrics* lm)
{
	Tab* tab      = self.active_tab();
	Document* doc = &tab.doc;
	int tot_lines = doc.get_total_lines();

	switch (cmd)
	{
		case CMD_MOVE_LEFT:
			@move_cursors(doc, self.modifiers.shift; cur)
			{
				cur.pos = (!self.modifiers.shift && cur.has_selection())
					? cur.sel_start()
					: get_prev_char_pos(&doc.table, cur.pos);
			};
			return true;

		case CMD_MOVE_RIGHT:
			@move_cursors(doc, self.modifiers.shift; cur)
			{
				cur.pos = (!self.modifiers.shift && cur.has_selection())
					? cur.sel_end()
					: get_next_char_pos(&doc.table, cur.pos);
			};
			return true;

		case CMD_MOVE_WORD_LEFT:
			@move_cursors(doc, self.modifiers.shift; cur) { cur.pos = get_prev_word_pos(&doc.table, cur.pos); };
			return true;

		case CMD_MOVE_WORD_RIGHT:
			@move_cursors(doc, self.modifiers.shift; cur) { cur.pos = get_next_word_pos(&doc.table, cur.pos); };
			return true;

		case CMD_MOVE_UP:
			@move_cursors(doc, self.modifiers.shift; cur)
			{
				int line = doc.get_line(cur.pos);
				cur.pos = (line > 0) ? doc.get_pos_from_line_col(line - 1, cur.target_col) : 0;
			};
			return true;

		case CMD_MOVE_DOWN:
			@move_cursors(doc, self.modifiers.shift; cur)
			{
				int line = doc.get_line(cur.pos);
				cur.pos = (line < tot_lines - 1) ? doc.get_pos_from_line_col(line + 1, cur.target_col) : doc.table.len();
			};
			return true;

		case CMD_MOVE_LINE_START:
			@move_cursors(doc, self.modifiers.shift; cur) { cur.pos = doc.get_line_start(cur.pos); };
			return true;

		case CMD_MOVE_LINE_END:
			@move_cursors(doc, self.modifiers.shift; cur) { cur.pos = doc.get_line_end(cur.pos); };
			return true;

		case CMD_MOVE_FILE_START:
			doc.cursors.clear();
			doc.cursors.push({ 0, 0, 0 });
			return true;

		case CMD_MOVE_FILE_END:
			doc.cursors.clear();
			BytePos end_p = doc.table.len();
			doc.cursors.push({ end_p, end_p, doc.get_col(end_p) });
			return true;

		case CMD_PAGE_UP:
			int step_up = 1 + math::clamp((int)(self.page_hold_timer * config::TIMING.page_hold_multiplier), 0, config::TIMING.max_page_speed);
			int move_up = lm.visible_lines * step_up;
			@move_cursors(doc, self.modifiers.shift; cur)
			{
				int l = math::max(0, doc.get_line(cur.pos) - move_up);
				cur.pos = doc.get_pos_from_line_col(l, cur.target_col);
			};
			return true;

		case CMD_PAGE_DOWN:
			int step_down = 1 + math::clamp((int)(self.page_hold_timer * config::TIMING.page_hold_multiplier), 0, config::TIMING.max_page_speed);
			int move_down = lm.visible_lines * step_down;
			@move_cursors(doc, self.modifiers.shift; cur)
			{
				int l = math::min(tot_lines - 1, doc.get_line(cur.pos) + move_down);
				cur.pos = doc.get_pos_from_line_col(l, cur.target_col);
			};
			return true;

		case CMD_JUMP_MATCHING_BRACKET:
			doc.jump_to_matching_bracket(self.modifiers.shift);
			return true;

		case CMD_SELECT_ALL:
			doc.cursors.clear();
			doc.cursors.push({ doc.table.len(), 0, doc.get_col(doc.table.len()) });
			return true;

		case CMD_SELECT_TO_TOP:
			@move_cursors(doc, true; cur) { cur.pos = 0; };
			return true;

		case CMD_SELECT_TO_BOTTOM:
			@move_cursors(doc, true; cur) { cur.pos = doc.table.len(); };
			return true;

		case CMD_CLEAR_SELECTION:
			if (self.autocomplete.is_active)
			{
				self.autocomplete.is_active = false;
				return false;
			}
			if (doc.cursors.len() > 1)
			{
				Cursor prim = doc.cursors[0];
				doc.cursors.clear();
				doc.cursors.push(prim);
			}
			else
			{
				doc.primary_cursor().anchor = doc.primary_cursor().pos;
			}
			return true;

		case CMD_ADD_CURSOR_ABOVE:
			doc.add_cursor_vertical(true);
			return true;

		case CMD_ADD_CURSOR_BELOW:
			doc.add_cursor_vertical(false);
			return true;

		case CMD_ADD_NEXT_OCCURRENCE:
			doc.add_next_occurrence(tab, lm.visible_lines, lm.visible_cols);
			self.reset_cursor_blink();
			return false;

		case CMD_GOTO_DEFINITION:
			self.goto_definition(lm);
			return true;

		case CMD_GOTO_NEXT_SYMBOL:
			self.goto_next_symbol(lm);
			return true;

		default:
			return false;
	}
}

fn bool Editor.handle_edit_command(&self, EditorCommand cmd)
{
	Tab* tab      = self.active_tab();
	Document* doc = &tab.doc;

	switch (cmd)
	{
		case CMD_BACKSPACE:
			doc.handle_backspace();
			return true;

		case CMD_DELETE:
			doc.handle_delete();
			return true;

		case CMD_DELETE_WORD_LEFT:
			doc.delete_word_left();
			return true;

		case CMD_DELETE_WORD_RIGHT:
			doc.delete_word_right();
			return true;

		case CMD_ENTER:
			doc.handle_enter();
			return true;

		case CMD_INSERT_TAB:
			bool has_any_selection = false;
			foreach (&cur : doc.cursors)
			{
				if (cur.has_selection()) { has_any_selection = true; break; }
			}
			switch
			{
				case self.modifiers.shift: doc.indent_block(true);
				case has_any_selection:    doc.indent_block(false);
				default:                   doc.insert_codepoint('\t');
			}
			return true;

		case CMD_INDENT:
			bool has_sel = false;
			foreach (&cur : doc.cursors)
			{
				if (cur.has_selection()) { has_sel = true; break; }
			}
			has_sel ? doc.indent_block(false) : doc.insert_codepoint('\t');
			return true;

		case CMD_OUTDENT:
			doc.indent_block(true);
			return true;

		case CMD_DUPLICATE_LINE:
			doc.duplicate_line();
			return true;

		case CMD_DELETE_LINE:
			doc.delete_line();
			return true;

		case CMD_MOVE_LINE_UP:
			doc.move_lines_vertical(true);
			return true;

		case CMD_MOVE_LINE_DOWN:
			doc.move_lines_vertical(false);
			return true;

		case CMD_TOGGLE_COMMENT:
			doc.toggle_comment();
			return true;

		case CMD_TO_UPPERCASE:
			doc.convert_case_selection(true);
			return true;

		case CMD_TO_LOWERCASE:
			doc.convert_case_selection(false);
			return true;

		case CMD_COPY:
			DString tmp;
			tmp.tinit();
			foreach (&cur : doc.cursors)
			{
				if (cur.has_selection())
				{
					if (tmp.len() > 0) tmp.append_char('\n');
					doc.table.append_range_to_dstring(&tmp, cur.sel_start(), cur.sel_end());
				}
			}
			if (tmp.len() > 0)
			{
				gfx::set_clipboard(tmp.str_view());
			}
			return false;

		case CMD_CUT:
			DString tmp;
			tmp.tinit();
			foreach (&cur : doc.cursors)
			{
				if (cur.has_selection())
				{
					if (tmp.len() > 0) tmp.append_char('\n');
					doc.table.append_range_to_dstring(&tmp, cur.sel_start(), cur.sel_end());
				}
			}
			if (tmp.len() > 0)
			{
				gfx::set_clipboard(tmp.str_view());
			}
			doc.delete_selection();
			return true;

		case CMD_PASTE:
			String? clip_opt = gfx::get_clipboard(tmem);
			if (try clip = clip_opt)
			{
				doc.@mutate_cursors(; cur, delta)
				{
					BytePos s = cur.sel_start();
					BytePos e = cur.sel_end();
					doc.apply_cursor_edit(cur, s, e, (char[])clip, delta);
				};
				return true;
			}
			return false;

		case CMD_UNDO:
			doc.undo();
			return true;

		case CMD_REDO:
			doc.redo();
			return true;

		default:
			return false;
	}
}

fn bool Editor.handle_search_modal_command(&self, EditorCommand cmd, LayoutMetrics* lm)
{
	Tab* tab      = self.active_tab();
	Document* doc = &tab.doc;

	switch (cmd)
	{
		case CMD_OPEN_FIND:
		case CMD_OPEN_REPLACE:
			self.modal.kind = (cmd == CMD_OPEN_FIND) ? FIND : REPLACE;
			if (doc.primary_cursor().has_selection())
			{
				BytePos s = doc.primary_cursor().sel_start();
				BytePos e = doc.primary_cursor().sel_end();
				if (doc.get_line(s) == doc.get_line(e))
				{
					DString sel_str;
					sel_str.tinit();
					doc.table.append_range_to_dstring(&sel_str, s, e);
					self.modal.input.set_text(sel_str.str_view());
				}
			}
			self.modal.focus_field = 0;
			self.modal.update_cached_search_matches(doc);
			return false;

		case CMD_FIND_NEXT:
			self.modal.find_next(doc, false, tab, lm.visible_lines, lm.visible_cols);
			return false;

		case CMD_FIND_PREV:
			self.modal.find_next(doc, true, tab, lm.visible_lines, lm.visible_cols);
			return false;

		case CMD_REPLACE_NEXT:
			self.modal.replace_next(doc, tab, lm.visible_lines, lm.visible_cols);
			return false;

		case CMD_REPLACE_ALL:
			self.modal.replace_all(doc, tab, lm.visible_lines, lm.visible_cols);
			return false;

		case CMD_TOGGLE_CASE_SENSITIVITY:
			if (self.modal.kind == FIND || self.modal.kind == REPLACE)
			{
				self.modal.search_case_sensitive = !self.modal.search_case_sensitive;
				self.modal.update_cached_search_matches(doc);
				if (self.modal.kind == FIND || (self.modal.kind == REPLACE && self.modal.focus_field == 0))
				{
					self.modal.find_from_current(doc, tab, lm.visible_lines, lm.visible_cols);
				}
			}
			return false;

		case CMD_OPEN_QUICK_OPEN:
			self.modal.kind = QUICK_OPEN;
			self.modal.input.clear();
			self.workspace.refresh_files();
			self.modal.update_quick_open_results(&self.workspace);
			return false;

		case CMD_OPEN_GLOBAL_GREP:
			self.modal.kind = GLOBAL_GREP;
			self.modal.input.clear();
			self.workspace.refresh_files();
			self.modal.update_grep_results(&self.workspace);
			return false;

		case CMD_OPEN_GOTO_LINE:
			self.modal.kind = GOTO_LINE;
			self.modal.input.clear();
			return false;

		case CMD_OPEN_SYMBOL_OUTLINE:
			self.modal.kind = SYMBOL_OUTLINE;
			self.modal.input.clear();
			self.modal.update_outline_results(doc);
			return false;

		case CMD_TRIGGER_AUTOCOMPLETE:
			self.trigger_autocomplete_at_cursor();
			return false;

		default:
			return false;
	}
}

fn bool Editor.handle_workspace_command(&self, EditorCommand cmd)
{
	Tab* tab      = self.active_tab();
	Document* doc = &tab.doc;

	switch (cmd)
	{
		case CMD_BUILD_PROJECT:
			self.build_project();
			return false;

		case CMD_COMPILE_THIS_FILE:
			self.run_or_compile_file(false, COMPILE_FILE);
			return false;

		case CMD_RUN_PROJECT:
			self.run_project();
			return false;

		case CMD_RUN_THIS_FILE:
			self.run_or_compile_file(true, RUN_FILE);
			return false;

		case CMD_TOGGLE_TERMINAL:
			self.terminal.is_open = !self.terminal.is_open;
			return false;

		case CMD_SAVE_FILE:
			if (!doc.is_file_specified)
			{
				self.modal.kind = SAVE_AS;
				self.modal.input.set_text(doc.filepath);
			}
			else
			{
				file::save(doc.filepath, (char[])doc.table.to_tstring())!!;
				doc.is_modified = false;
				doc.last_disk_mtime = file::last_modified(doc.filepath) ?? (Time)0;
				self.workspace.git.update(doc.filepath, doc.get_total_lines());
				self.save_msg_timer = config::TIMING.save_msg_duration;
			}
			return false;

		case CMD_SAVE_AS:
			self.modal.kind = SAVE_AS;
			self.modal.input.set_text(doc.filepath);
			return false;

		case CMD_QUIT:
			bool any_modified = false;
			foreach (&t : self.tabs)
			{
				if (t.doc.is_modified) { any_modified = true; break; }
			}
			if (any_modified)
			{
				self.modal.kind = CONFIRM_EXIT;
			}
			else
			{
				self.should_exit = true;
			}
			return false;

		case CMD_ZOOM_IN:
			self.font_scale = math::min(config::LAYOUT_METRICS.max_font_scale, self.font_scale + config::LAYOUT_METRICS.font_zoom_step);
			return false;

		case CMD_ZOOM_OUT:
			self.font_scale = math::max(config::LAYOUT_METRICS.min_font_scale, self.font_scale - config::LAYOUT_METRICS.font_zoom_step);
			return false;

		default:
			return false;
	}
}

fn void Editor.dispatch_command(&self, EditorCommand cmd, LayoutMetrics* lm, float dt)
{
	if (cmd == CMD_NONE) return;

	bool update_view = false;

	if (self.handle_tab_command(cmd))
	{
		update_view = true;
	}
	else if (self.handle_nav_command(cmd, lm))
	{
		update_view = true;
	}
	else if (self.handle_edit_command(cmd))
	{
		update_view = true;
	}
	else if (self.handle_search_modal_command(cmd, lm))
	{
		update_view = true;
	}
	else if (self.handle_workspace_command(cmd))
	{
		update_view = true;
	}

	if (update_view)
	{
		self.active_tab().ensure_cursor_visible(lm.visible_lines, lm.visible_cols);
	}
}module c3ed::gfx;
import std, raylib6, c3ed::config;

// --- Fast Window Initialization Stubs for Linux/POSIX ---
// Bypasses GLFW's slow `/dev/input/event*` joystick probing on startup
fn bool _glfwInitJoysticksLinux() @cname("_glfwInitJoysticksLinux") @export @feat(!WASM & FAST) => true;
fn void _glfwTerminateJoysticksLinux() @cname("_glfwTerminateJoysticksLinux") @export @feat(!WASM & FAST) {}
fn bool _glfwPlatformInitJoysticks() @cname("_glfwPlatformInitJoysticks") @export @feat(!WASM & FAST) => true;
fn void _glfwPlatformTerminateJoysticks() @cname("_glfwPlatformTerminateJoysticks") @export @feat(!WASM & FAST) {}
fn void _glfwDetectJoystickConnectionLinux() @cname("_glfwDetectJoystickConnectionLinux") @export @feat(!WASM & FAST) {}

enum MouseButton : int
{
	LEFT,
	RIGHT,
	MIDDLE
}

constdef Key : int
{
	NONE = 0,
	A = 65, B, C, D, E, F, G, H, I, J, K, L, M, N, O, P, Q, R, S, T, U, V, W, X, Y, Z,
	ZERO = 48, ONE, TWO, THREE, FOUR, FIVE, SIX, SEVEN, EIGHT, NINE,
	F1 = 290, F2, F3, F4, F5, F6, F7, F8, F9, F10, F11, F12,
	ESCAPE = 256,
	ENTER = 257,
	TAB = 258,
	BACKSPACE = 259,
	INSERT = 260,
	DELETE = 261,
	RIGHT = 262,
	LEFT = 263,
	DOWN = 264,
	UP = 265,
	PAGE_UP = 266,
	PAGE_DOWN = 267,
	HOME = 268,
	END = 269,
	LEFT_SHIFT = 340,
	LEFT_CONTROL = 341,
	LEFT_ALT = 342,
	RIGHT_SHIFT = 344,
	RIGHT_CONTROL = 345,
	RIGHT_ALT = 346,
	SPACE = 32,
	MINUS = 45,
	EQUAL = 61,
	GRAVE = 96,
	SLASH = 47,
	BACKSLASH = 92,
	KP_ADD = 334,
	KP_SUBTRACT = 333,
	KP_ENTER = 335
}

fn RLColor to_rl_color(Color c) @inline => { c[0], c[1], c[2], c[3] };
fn RLRectangle to_rl_rect(Rect r) @inline => { r.x, r.y, r.width, r.height };
fn RLVector2 to_rl_vec2(Vec2 v) @inline => { v.x, v.y };

fn void init_window(int width, int height, String title)
{
	$if $feat(FAST):
		rl::set_trace_log_level(RLTraceLogLevel.NONE);
	$endif

	rl::set_config_flags(RLConfigFlag.WINDOW_RESIZABLE | RLConfigFlag.WINDOW_HIDDEN);
	rl::init_window(width, height, title.zstr_tcopy());
	rl::set_exit_key((RLKeyboardKey)0);

	$if !env::WASM:
		int monitor = rl::get_current_monitor();
		int screen_w = rl::get_monitor_width(monitor);
		int screen_h = rl::get_monitor_height(monitor);

		rl::set_window_size(screen_w, screen_h - 28);
		rl::set_window_position(0, 0);
		rl::set_target_fps(60);
		rl::maximize_window();
	$endif

	rl::clear_window_state(RLConfigFlag.WINDOW_HIDDEN);
}

fn void close_window() => rl::close_window();
fn bool should_close() => rl::window_should_close();
fn float get_frame_time() => rl::get_frame_time();
fn double get_time() => rl::get_time();
fn int get_screen_width() => rl::get_screen_width();
fn int get_screen_height() => rl::get_screen_height();

fn void begin_frame() => rl::begin_drawing();
fn void end_frame() => rl::end_drawing();
fn void clear_background(Color color) => rl::clear_background(to_rl_color(color));

fn void draw_rect(int x, int y, int w, int h, Color color)
{
	rl::draw_rectangle(x, y, w, h, to_rl_color(color));
}

fn void draw_rect_lines(int x, int y, int w, int h, Color color)
{
	rl::draw_rectangle_lines(x, y, w, h, to_rl_color(color));
}

fn void draw_line(int start_x, int start_y, int end_x, int end_y, Color color)
{
	rl::draw_line(start_x, start_y, end_x, end_y, to_rl_color(color));
}

fn void draw_triangle(Vec2 v1, Vec2 v2, Vec2 v3, Color color)
{
	rl::draw_triangle(to_rl_vec2(v1), to_rl_vec2(v2), to_rl_vec2(v3), to_rl_color(color));
}

fn void begin_scissor(int x, int y, int w, int h)
{
	rl::begin_scissor_mode(x, y, w, h);
}

fn void end_scissor()
{
	rl::end_scissor_mode();
}

fn Vec2 get_mouse_pos()
{
	RLVector2 p = rl::get_mouse_position();
	return { p.x, p.y };
}

fn float get_mouse_wheel() => rl::get_mouse_wheel_move();

fn bool is_mouse_down(MouseButton button)
{
	return rl::is_mouse_button_down((RLMouseButton)(int)button);
}

fn bool is_mouse_pressed(MouseButton button)
{
	return rl::is_mouse_button_pressed((RLMouseButton)(int)button);
}

fn bool is_mouse_released(MouseButton button)
{
	return rl::is_mouse_button_released((RLMouseButton)(int)button);
}

fn bool is_key_pressed(Key key) => rl::is_key_pressed((RLKeyboardKey)key);
fn bool is_key_down(Key key) => rl::is_key_down((RLKeyboardKey)key);
fn bool is_key_repeat(Key key) => rl::is_key_pressed_repeat((RLKeyboardKey)key);
fn int get_char_pressed() => rl::get_char_pressed();

fn String? get_clipboard(Allocator allocator) => @pool()
{
	ZString clip = rl::get_clipboard_text();
	if (clip == null) return NOT_FOUND~;
	String s = clip.str_view();
	if (s.len == 0) return NOT_FOUND~;
	return s.copy(allocator);
}

fn void set_clipboard(String text) => @pool()
{
	if (text.len > 15 * 1024 * 1024) return;
	rl::set_clipboard_text(text.zstr_tcopy());
}module c3ed;
import std;

Editor editor;
String current_workspace = ".";

fn bool key_pressed_or_repeat(Key key) => gfx::is_key_pressed(key) || gfx::is_key_repeat(key);

macro void @handle_list_picker_keys(#picker, int visible_rows)
{
	#picker.clamp_view(visible_rows);
	if (key_pressed_or_repeat(PAGE_UP))
	{
		#picker.page_up();
		editor.reset_cursor_blink();
	}
	if (key_pressed_or_repeat(PAGE_DOWN))
	{
		#picker.page_down();
		editor.reset_cursor_blink();
	}
	if (key_pressed_or_repeat(UP) || (editor.modifiers.ctrl && (gfx::is_key_pressed(P) || gfx::is_key_pressed(K))))
	{
		#picker.select_prev();
		editor.reset_cursor_blink();
	}
	if (key_pressed_or_repeat(DOWN) || (editor.modifiers.ctrl && (gfx::is_key_pressed(N) || gfx::is_key_pressed(J))))
	{
		#picker.select_next();
		editor.reset_cursor_blink();
	}
}

fn int get_clicked_list_index(Vec2 mouse_v, int modal_x, int modal_w, int list_y, int list_h, int row_h, int scroll_offset, int count)
{
	if (mouse_v.x >= (float)(modal_x + config::LAYOUT_METRICS.modal_padding_x) && mouse_v.x <= (float)(modal_x + modal_w - config::LAYOUT_METRICS.modal_padding_x)
		&& mouse_v.y >= (float)list_y && mouse_v.y < (float)(list_y + list_h))
	{
		int clicked_row = (int)(mouse_v.y - (float)list_y) / row_h;
		int idx = clicked_row + scroll_offset;
		if (idx >= 0 && idx < count) return idx;
	}
	return -1;
}

fn void update_editor_events(LayoutMetrics* lm, float dt, int screen_w, int height)
{
	Tab* tab = editor.active_tab();
	Document* doc = &tab.doc;

	editor.modifiers = {
		.shift = gfx::is_key_down(LEFT_SHIFT) || gfx::is_key_down(RIGHT_SHIFT),
		.ctrl  = gfx::is_key_down(LEFT_CONTROL) || gfx::is_key_down(RIGHT_CONTROL),
		.alt   = gfx::is_key_down(LEFT_ALT) || gfx::is_key_down(RIGHT_ALT)
	};

	editor.blink_timer += dt;
	if (editor.blink_timer >= config::TIMING.cursor_blink_interval)
	{
		editor.blink_timer -= config::TIMING.cursor_blink_interval;
		editor.cursor_visible = !editor.cursor_visible;
	}

	if (config::settings.file_watcher_enabled)
	{
		editor.workspace.poll_disk_changes(&editor.tabs, &editor.pending_reload_tab_index, &editor.modal.kind, dt);
	}

	if (editor.modal.kind != NONE)
	{
		if (gfx::is_key_pressed(ESCAPE))
		{
			editor.confirm_cancel_action();
			return;
		}

		Rect mrect       = editor.get_modal_rect(lm, screen_w, height);
		int modal_x      = (int)mrect.x;
		int modal_y      = (int)mrect.y;
		int modal_w      = (int)mrect.width;
		int modal_h      = (int)mrect.height;
		int input_box_h  = math::max(config::LAYOUT_METRICS.modal_input_box_h_min, lm.char_height + config::LAYOUT_METRICS.modal_input_box_padding);
		int list_y       = modal_y + 14 + lm.char_height + 8 + input_box_h + 10;
		int list_h       = modal_y + modal_h - list_y - config::LAYOUT_METRICS.modal_padding_y;
		int row_h        = math::max(config::LAYOUT_METRICS.modal_row_h_min, lm.line_height);
		int visible_rows = math::max(1, list_h / row_h);

		if (gfx::is_mouse_pressed(LEFT))
		{
			Vec2 mouse_v = gfx::get_mouse_pos();

			if (mouse_v.x < mrect.x - 4.0f || mouse_v.x > mrect.x + mrect.width + 4.0f
				|| mouse_v.y < mrect.y - 4.0f || mouse_v.y > mrect.y + mrect.height + 4.0f)
			{
				editor.confirm_cancel_action();
				return;
			}

			if (editor.modal.kind == FIND || editor.modal.kind == REPLACE)
			{
				Rect toggle_rect = editor.get_case_toggle_rect(lm, screen_w, height);
				if (mouse_v.x >= toggle_rect.x && mouse_v.x <= toggle_rect.x + toggle_rect.width
					&& mouse_v.y >= toggle_rect.y && mouse_v.y <= toggle_rect.y + toggle_rect.height)
				{
					editor.modal.search_case_sensitive = !editor.modal.search_case_sensitive;
					editor.modal.update_cached_search_matches(doc);
					editor.modal.find_from_current(doc, tab, lm.visible_lines, lm.visible_cols);
					editor.reset_cursor_blink();
					return;
				}
			}

			switch (editor.modal.kind)
			{
				case CONFIRM_CLOSE_TAB:
				case CONFIRM_EXIT:
				case CONFIRM_DISK_RELOAD:
					int btn_w = (modal_w - 32 - 24) / 3;
					int btn_h = input_box_h;
					int btn_y = modal_y + 14 + lm.char_height + 12;

					int btn1_x = modal_x + 16;
					int btn2_x = btn1_x + btn_w + 12;
					int btn3_x = btn2_x + btn_w + 12;

					if (mouse_v.y >= (float)btn_y && mouse_v.y < (float)(btn_y + btn_h))
					{
						switch
						{
							case mouse_v.x >= (float)btn1_x && mouse_v.x < (float)(btn1_x + btn_w):
								editor.confirm_save_action();
								return;
							case mouse_v.x >= (float)btn2_x && mouse_v.x < (float)(btn2_x + btn_w):
								editor.confirm_discard_action();
								return;
							case mouse_v.x >= (float)btn3_x && mouse_v.x < (float)(btn3_x + btn_w):
								editor.confirm_cancel_action();
								return;
						}
					}

				case REPLACE:
					int input1_y = modal_y + 14 + lm.char_height + 6;
					int input2_y = input1_y + input_box_h + 10;
					switch
					{
						case mouse_v.y >= (float)input1_y && mouse_v.y < (float)(input1_y + input_box_h):
							editor.modal.focus_field = 0;
							editor.reset_cursor_blink();
						case mouse_v.y >= (float)input2_y && mouse_v.y < (float)(input2_y + input_box_h):
							editor.modal.focus_field = 1;
							editor.reset_cursor_blink();
					}

				case QUICK_OPEN:
				case GLOBAL_GREP:
				case SYMBOL_OUTLINE:
					int idx = get_clicked_list_index(mouse_v, modal_x, modal_w, list_y, list_h, row_h, editor.modal.picker.scroll_offset, (int)editor.modal.picker.items.len());
					if (idx >= 0)
					{
						editor.modal.picker.selected_index = idx;
						PickerItem item = editor.modal.picker.items[(sz)idx];
						if (item.target_path.len > 0)
						{
							String resolved = resolve_path_string(item.target_path, tmem);
							if (path::is_dir((Path)resolved))
							{
								String new_query = item.target_path.ends_with("/") ? item.target_path : string::tformat("%s/", item.target_path);
								editor.modal.input.set_text(new_query);
								editor.reset_cursor_blink();
								editor.modal.update_quick_open_results(&editor.workspace);
							}
							else
							{
								editor.open_tab(resolved, true);
								if (item.line > 0)
								{
									Tab* new_tab = editor.active_tab();
									BytePos target_pos = new_tab.doc.get_pos_from_line_col(item.line - 1, math::max(0, item.col - 1));
									new_tab.doc.cursors.clear();
									new_tab.doc.cursors.push({ target_pos, target_pos, math::max(0, item.col - 1) });
									new_tab.ensure_pos_visible(target_pos, lm.visible_lines, lm.visible_cols);
								}
								editor.modal.close();
								return;
							}
						}
					}

				default: break;
			}
		}

		float modal_wheel = gfx::get_mouse_wheel();
		if (modal_wheel != 0.0f)
		{
			if (editor.modal.kind == QUICK_OPEN || editor.modal.kind == GLOBAL_GREP || editor.modal.kind == SYMBOL_OUTLINE)
			{
				editor.modal.picker.clamp_view(visible_rows);
				(modal_wheel > 0.0f) ? editor.modal.picker.select_prev() : editor.modal.picker.select_next();
			}
		}

		TextInputWidget* active_input = (editor.modal.kind == REPLACE && editor.modal.focus_field == 1)
			? &editor.modal.replace_input
			: &editor.modal.input;

		if (editor.modal.kind == FIND || editor.modal.kind == REPLACE)
		{
			if (editor.modifiers.alt && gfx::is_key_pressed(C))
			{
				editor.modal.search_case_sensitive = !editor.modal.search_case_sensitive;
				editor.modal.update_cached_search_matches(doc);
				if (editor.modal.kind == FIND || (editor.modal.kind == REPLACE && editor.modal.focus_field == 0))
				{
					editor.modal.find_from_current(doc, tab, lm.visible_lines, lm.visible_cols);
				}
			}
		}

		switch (editor.modal.kind)
		{
			case CONFIRM_CLOSE_TAB:
			case CONFIRM_EXIT:
			case CONFIRM_DISK_RELOAD:
				if (gfx::is_key_pressed(Y)) editor.confirm_save_action();
				if (gfx::is_key_pressed(N)) editor.confirm_discard_action();

			case GOTO_LINE:
				if (gfx::is_key_pressed(ENTER) || gfx::is_key_pressed(KP_ENTER))
				{
					int target         = string::to_integer{int}(editor.modal.input.view()) ?? 1;
					BytePos target_pos = doc.get_pos_from_line_col(
						math::clamp(target - 1, 0, doc.get_total_lines() - 1),
						0
					);
					doc.cursors.clear();
					doc.cursors.push({ target_pos, target_pos, 0 });
					tab.ensure_pos_visible(target_pos, lm.visible_lines, lm.visible_cols);
					editor.modal.close();
				}

			case FIND:
				if (key_pressed_or_repeat(DOWN)) editor.modal.find_next(doc, false, tab, lm.visible_lines, lm.visible_cols);
				if (key_pressed_or_repeat(UP))   editor.modal.find_next(doc, true, tab, lm.visible_lines, lm.visible_cols);
				if (gfx::is_key_pressed(ENTER) || gfx::is_key_pressed(KP_ENTER) || gfx::is_key_pressed(F3))
				{
					editor.modal.find_next(doc, editor.modifiers.shift, tab, lm.visible_lines, lm.visible_cols);
				}

			case REPLACE:
				switch
				{
					case gfx::is_key_pressed(TAB) || key_pressed_or_repeat(UP) || key_pressed_or_repeat(DOWN):
						editor.modal.focus_field = 1 - editor.modal.focus_field;
						editor.reset_cursor_blink();
					case gfx::is_key_pressed(ENTER) || gfx::is_key_pressed(KP_ENTER):
						(editor.modifiers.ctrl || editor.modifiers.alt)
							? editor.modal.replace_all(doc, tab, lm.visible_lines, lm.visible_cols)
							: editor.modal.replace_next(doc, tab, lm.visible_lines, lm.visible_cols);
					case gfx::is_key_pressed(F3):
						editor.modal.find_next(doc, editor.modifiers.shift, tab, lm.visible_lines, lm.visible_cols);
				}

			case QUICK_OPEN:
			case GLOBAL_GREP:
			case SYMBOL_OUTLINE:
				@handle_list_picker_keys(editor.modal.picker, visible_rows);
				if (gfx::is_key_pressed(ENTER) || gfx::is_key_pressed(KP_ENTER))
				{
					if (editor.modal.picker.items.len() > 0)
					{
						PickerItem item = editor.modal.picker.items[(sz)editor.modal.picker.selected_index];
						if (item.target_path.len > 0)
						{
							String resolved = resolve_path_string(item.target_path, tmem);
							if (path::is_dir((Path)resolved))
							{
								String new_query = item.target_path.ends_with("/") ? item.target_path : string::tformat("%s/", item.target_path);
								editor.modal.input.set_text(new_query);
								editor.reset_cursor_blink();
								editor.modal.update_quick_open_results(&editor.workspace);
							}
							else
							{
								editor.open_tab(resolved, true);
								if (item.line > 0)
								{
									Tab* new_tab = editor.active_tab();
									BytePos target_pos = new_tab.doc.get_pos_from_line_col(item.line - 1, math::max(0, item.col - 1));
									new_tab.doc.cursors.clear();
									new_tab.doc.cursors.push({ target_pos, target_pos, math::max(0, item.col - 1) });
									new_tab.ensure_pos_visible(target_pos, lm.visible_lines, lm.visible_cols);
								}
								editor.modal.close();
								return;
							}
						}
					}
				}

			case SAVE_AS:
				if (gfx::is_key_pressed(ENTER) || gfx::is_key_pressed(KP_ENTER))
				{
					String target_file = resolve_path_string(editor.modal.input.view(), tmem);
					if (target_file.len > 0)
					{
						file::save(target_file, (char[])doc.table.to_tstring())!!;
						if (doc.filepath.len > 0) mem::free(doc.filepath.ptr);
						doc.filepath = target_file.copy(mem);
						doc.is_file_specified = true;
						doc.is_modified = false;
						doc.last_disk_mtime = file::last_modified(doc.filepath) ?? (Time)0;
						editor.workspace.git.update(doc.filepath, doc.get_total_lines());
						editor.save_msg_timer = config::TIMING.save_msg_duration;
						editor.workspace.invalidate_files();

						PendingSaveAction action = editor.pending_action_after_save;
						editor.pending_action_after_save = NONE;

						if (editor.pending_close_tab_index >= 0)
						{
							int to_close = editor.pending_close_tab_index;
							editor.pending_close_tab_index = -1;
							editor.modal.close();
							editor.close_tab(to_close);
							return;
						}

						editor.modal.close();

						switch (action)
						{
							case RUN_FILE:     editor.run_or_compile_file(true, RUN_FILE);
							case COMPILE_FILE: editor.run_or_compile_file(false, COMPILE_FILE);
							default: break;
						}
						return;
					}
					editor.pending_action_after_save = NONE;
					editor.modal.close();
				}
			default: break;
		}

		if (key_pressed_or_repeat(LEFT))
		{
			if (active_input.cursor_pos > 0)
			{
				int prev = active_input.cursor_pos - 1;
				while (prev > 0 && (active_input.buffer[prev] & 0xC0) == 0x80) prev--;
				active_input.cursor_pos = prev;
			}
			editor.reset_cursor_blink();
		}
		if (key_pressed_or_repeat(RIGHT))
		{
			if (active_input.cursor_pos < active_input.length)
			{
				int next = active_input.cursor_pos + 1;
				while (next < active_input.length && (active_input.buffer[next] & 0xC0) == 0x80) next++;
				active_input.cursor_pos = next;
			}
			editor.reset_cursor_blink();
		}
		if (gfx::is_key_pressed(HOME))
		{
			active_input.cursor_pos = 0;
			editor.reset_cursor_blink();
		}
		if (gfx::is_key_pressed(END))
		{
			active_input.cursor_pos = active_input.length;
			editor.reset_cursor_blink();
		}

		bool input_modified = false;
		bool is_paste_event = (editor.modifiers.ctrl  && gfx::is_key_pressed(V))
			               || (editor.modifiers.shift && gfx::is_key_pressed(INSERT));

		if (is_paste_event)
		{
			String? clip_opt = gfx::get_clipboard(tmem);
			if (try clip = clip_opt)
			{
				String sanitized = clip.trim("\r\n");
				if (active_input.insert_str(sanitized)) input_modified = true;
			}
		}

		if (key_pressed_or_repeat(BACKSPACE))
		{
			if (editor.modifiers.ctrl || editor.modifiers.alt)
			{
				if (active_input.delete_word_left()) input_modified = true;
			}
			else
			{
				if (active_input.backspace()) input_modified = true;
			}
		}
		if (key_pressed_or_repeat(DELETE) && active_input.delete()) input_modified = true;

		int char_code = gfx::get_char_pressed();
		while (char_code > 0)
		{
			if (char_code >= 32 && (!editor.modifiers.ctrl || editor.modifiers.alt))
			{
				if (active_input.insert_codepoint((Char32)char_code)) input_modified = true;
			}
			char_code = gfx::get_char_pressed();
		}

		if (input_modified)
		{
			editor.reset_cursor_blink();
			if (editor.modal.kind == FIND || (editor.modal.kind == REPLACE && editor.modal.focus_field == 0))
			{
				editor.modal.update_cached_search_matches(doc);
				editor.modal.find_from_current(doc, tab, lm.visible_lines, lm.visible_cols);
			}
			if (editor.modal.kind == QUICK_OPEN) editor.modal.update_quick_open_results(&editor.workspace);
			if (editor.modal.kind == SYMBOL_OUTLINE) editor.modal.update_outline_results(doc);
			if (editor.modal.kind == GLOBAL_GREP)
			{
				editor.modal.grep_dirty = true;
				editor.modal.grep_debounce_timer = config::TIMING.grep_debounce_interval;
			}
		}

		if (editor.modal.kind == GLOBAL_GREP && editor.modal.grep_dirty)
		{
			editor.modal.grep_debounce_timer -= math::min(dt, 0.05f);
			if (editor.modal.grep_debounce_timer <= 0.0f)
			{
				editor.modal.grep_dirty = false;
				editor.modal.grep_debounce_timer = 0.0f;
				editor.modal.update_grep_results(&editor.workspace);
			}
		}
		return;
	}

	if (editor.autocomplete.is_active)
	{
		if (gfx::is_key_pressed(ESCAPE))
		{
			editor.autocomplete.is_active = false;
			return;
		}
		if (key_pressed_or_repeat(UP))
		{
			if (editor.autocomplete.selected_index > 0) editor.autocomplete.selected_index--;
			return;
		}
		if (key_pressed_or_repeat(DOWN))
		{
			if (editor.autocomplete.selected_index + 1 < (int)editor.autocomplete.items.len())
			{
				editor.autocomplete.selected_index++;
			}
			return;
		}
		if (gfx::is_key_pressed(TAB) || gfx::is_key_pressed(ENTER) || gfx::is_key_pressed(KP_ENTER))
		{
			if (editor.autocomplete.items.len() > 0)
			{
				CompletionItem item = editor.autocomplete.items[(sz)editor.autocomplete.selected_index];
				Cursor* cur = doc.primary_cursor();
				TextRange b = get_word_bounds(&doc.table, cur.pos);
				doc.table.begin_transaction(&doc.cursors);
				doc.table.replace_range(b.start, b.end, (char[])item.insert_text);
				doc.update_line_index_on_edit(b.start, b.end - b.start, (BytePos)item.insert_text.len);
				cur.pos = b.start + (BytePos)item.insert_text.len;
				cur.anchor = cur.pos;
				cur.target_col = doc.get_col(cur.pos);
				doc.table.end_transaction(&doc.cursors);
				doc.is_modified = true;
				editor.autocomplete.is_active = false;
				return;
			}
		}
	}

	Vec2 mouse_pos = gfx::get_mouse_pos();
	int tot_lines  = doc.get_total_lines();

	if (!gfx::is_mouse_down(LEFT))
	{
		if (editor.terminal.selecting)
		{
			editor.terminal.selecting = false;
			if (editor.terminal.has_selection())
			{
				String? sel_text = editor.terminal.extract_selection(tmem);
				if (try t = sel_text)
				{
					gfx::set_clipboard(t);
				}
			}
		}
		editor.mouse_down = false;
		editor.word_selecting = false;
		editor.line_selecting = false;
		editor.scrollbar_dragging = false;
		editor.minimap_dragging = false;
	}

	switch
	{
		case gfx::is_mouse_pressed(LEFT):
			if (editor.terminal.is_open && lm.terminal_height > 0)
			{
				int ty = (int)lm.terminal_rect.y;
				int th = lm.terminal_height;
				if (mouse_pos.y >= (float)ty && mouse_pos.y < (float)(ty + th))
				{
					int max_term_lines = math::max(1, (th - lm.line_height - 8) / lm.line_height);
					int total_tlines   = (int)editor.terminal.lines.len();
					int start_idx      = math::clamp(editor.terminal.scroll_line - max_term_lines + 1, 0, math::max(0, total_tlines - max_term_lines));
					int rel_ty         = (int)(mouse_pos.y - (float)(ty + lm.line_height + 8));
					int clicked_line   = start_idx + (rel_ty / lm.line_height);
					int clicked_col    = math::max(0, (int)(mouse_pos.x - 14.0f) / lm.char_width);

					editor.terminal.selecting = true;
					editor.terminal.sel_start_line = clicked_line;
					editor.terminal.sel_start_col = clicked_col;
					editor.terminal.sel_end_line = clicked_line;
					editor.terminal.sel_end_col = clicked_col;
					return;
				}
			}

			if (mouse_pos.y >= (float)(height - lm.footer_height) && mouse_pos.y <= (float)height)
			{
				String file_disp = doc.filepath.len > 0 ? doc.filepath : "untitled.c3";
				String mod_str   = doc.is_modified ? " [+]" : "";
				String save_str  = (editor.save_msg_timer > 0.0f) ? " [SAVED]" : "";
				String left_s    = string::tformat("%s%s%s", file_disp, mod_str, save_str);
				int left_w       = (int)left_s.len * lm.char_width + 24;

				if (mouse_pos.x >= 0.0f && mouse_pos.x <= (float)left_w)
				{
					editor.modal.kind = SAVE_AS;
					editor.modal.input.set_text(doc.filepath);
					editor.reset_cursor_blink();
					return;
				}
			}

			if (mouse_pos.y >= 0.0f && mouse_pos.y < (float)lm.tab_bar_height)
			{
				int tab_x       = 0;
				int close_box_w = lm.char_width * 2 + 10;
				for (sz i = 0; i < editor.tabs.len(); i++)
				{
					Tab* t  = &editor.tabs[i];
					String name_str = t.doc.filepath.file_tbasename() ?? t.doc.filepath;
					if (name_str.len == 0) name_str = "untitled.c3";

					String tab_title = string::tformat("%d: %s%s", i + 1, name_str, t.doc.is_modified ? " *" : "");
					int title_w      = (int)tab_title.len * lm.char_width;
					int tab_w        = title_w + close_box_w + config::LAYOUT_METRICS.tab_extra_padding;

					if (tab_x + tab_w > screen_w - config::LAYOUT_METRICS.tab_min_w_gap) tab_w = screen_w - config::LAYOUT_METRICS.tab_min_w_gap - tab_x;
					if (tab_w <= close_box_w + 10) break;

					if (mouse_pos.x >= (float)tab_x && mouse_pos.x < (float)(tab_x + tab_w))
					{
						if (mouse_pos.x >= (float)(tab_x + tab_w - close_box_w))
						{
							editor.request_close_tab((int)i);
						}
						else
						{
							editor.active_tab_index = (int)i;
							editor.reset_cursor_blink();
						}
						return;
					}
					tab_x += tab_w;
				}
				return;
			}

			if (tot_lines > lm.visible_lines && mouse_pos.x >= lm.scrollbar_rect.x - 4.0f
				&& mouse_pos.x <= (float)screen_w
				&& mouse_pos.y >= lm.scrollbar_rect.y
				&& mouse_pos.y <= (float)(lm.scrollbar_rect.y + lm.scrollbar_rect.height))
			{
				float max_scroll   = (float)(tot_lines - lm.visible_lines);
				float track_h      = lm.scrollbar_rect.height;
				float thumb_h      = math::max(config::LAYOUT_METRICS.scrollbar_min_thumb_h, track_h * (float)lm.visible_lines / (float)tot_lines);
				float scrollable_h = track_h - thumb_h;
				float thumb_y      = lm.scrollbar_rect.y + (scrollable_h * (float)tab.scroll_line / max_scroll);

				editor.scrollbar_dragging = true;
				editor.minimap_dragging = false;
				editor.mouse_down = false;
				if (mouse_pos.y >= thumb_y && mouse_pos.y <= thumb_y + thumb_h)
				{
					editor.scrollbar_drag_offset_y = mouse_pos.y - thumb_y;
				}
				else
				{
					editor.scrollbar_drag_offset_y = thumb_h * 0.5f;
					float new_thumb_y = mouse_pos.y - editor.scrollbar_drag_offset_y;
					float norm        = scrollable_h > 0.0f ? (new_thumb_y - lm.scrollbar_rect.y) / scrollable_h : 0.0f;
					tab.scroll_line = math::clamp((int)math::round(norm * max_scroll), 0, (int)max_scroll);
				}
				editor.reset_cursor_blink();
				break;
			}

			if (config::settings.show_minimap && lm.minimap_w > 0
				&& mouse_pos.x >= lm.minimap_rect.x
				&& mouse_pos.x <= lm.minimap_rect.x + lm.minimap_rect.width
				&& mouse_pos.y >= lm.minimap_rect.y
				&& mouse_pos.y <= lm.minimap_rect.y + lm.minimap_rect.height)
			{
				float mm_y = lm.minimap_rect.y;
				float mm_h = lm.minimap_rect.height;
				int max_scroll = math::max(0, tot_lines - lm.visible_lines);
				float click_rel_y = mouse_pos.y - mm_y;
				float norm = mm_h > 0.0f ? click_rel_y / mm_h : 0.0f;

				editor.minimap_dragging = true;
				editor.scrollbar_dragging = false;
				editor.mouse_down = false;
				editor.minimap_drag_offset_y = 0.0f;
				tab.scroll_line = math::clamp((int)math::round(norm * (float)max_scroll), 0, max_scroll);
				editor.reset_cursor_blink();
				break;
			}

			editor.scrollbar_dragging = false;
			editor.minimap_dragging = false;
			editor.mouse_down = true;
			double now = gfx::get_time();

			int rel_y = (int)(mouse_pos.y - (float)lm.text_start_y);
			int line  = rel_y / lm.line_height + tab.scroll_line;
			int rel_x = (int)(mouse_pos.x - (float)lm.text_start_x + (float)lm.char_width * 0.5f);
			int col   = math::max(0, rel_x / lm.char_width + tab.scroll_col);
			BytePos clicked_pos = doc.get_pos_from_line_col(line, col);

			float dx = mouse_pos.x - editor.last_click_pos.x;
			float dy = mouse_pos.y - editor.last_click_pos.y;

			if (now - editor.last_click_time < config::TIMING.double_click_threshold && (dx * dx + dy * dy) < config::TIMING.double_click_dist_sq)
			{
				editor.click_count = (editor.click_count % 3) + 1;
			}
			else
			{
				editor.click_count = 1;
			}
			editor.last_click_time = now;
			editor.last_click_pos = mouse_pos;

			Cursor* cur = doc.primary_cursor();
			switch (editor.click_count)
			{
				case 1:
					editor.word_selecting = false;
					editor.line_selecting = false;
					cur.pos = clicked_pos;
					if (!editor.modifiers.shift) cur.anchor = cur.pos;
					cur.target_col = doc.get_col(cur.pos);

				case 2:
					editor.word_selecting = true;
					editor.line_selecting = false;
					TextRange bounds = get_word_bounds(&doc.table, clicked_pos);
					editor.word_sel_anchor_start = bounds.start;
					editor.word_sel_anchor_end = bounds.end;
					cur.anchor = bounds.start;
					cur.pos = bounds.end;
					cur.target_col = doc.get_col(cur.pos);

				case 3:
					editor.word_selecting = false;
					editor.line_selecting = true;
					int clicked_line = doc.get_line(clicked_pos);
					BytePos l_start = doc.get_line_start_of_line(clicked_line);
					BytePos l_end = (clicked_line + 1 < doc.get_total_lines())
						? doc.get_line_start_of_line(clicked_line + 1)
						: doc.get_line_end(l_start);

					editor.word_sel_anchor_start = l_start;
					editor.word_sel_anchor_end = l_end;
					cur.anchor = l_start;
					cur.pos = l_end;
					cur.target_col = doc.get_col(cur.pos);
			}

			if (!editor.modifiers.shift && !editor.modifiers.alt && doc.cursors.len() > 1)
			{
				Cursor single = *cur;
				doc.cursors.clear();
				doc.cursors.push(single);
			}
			editor.reset_cursor_blink();

		case editor.terminal.selecting && gfx::is_mouse_down(LEFT):
			if (editor.terminal.is_open && lm.terminal_height > 0)
			{
				int ty = (int)lm.terminal_rect.y;
				int th = lm.terminal_height;
				int max_term_lines = math::max(1, (th - lm.line_height - 8) / lm.line_height);
				int total_tlines   = (int)editor.terminal.lines.len();
				int start_idx      = math::clamp(editor.terminal.scroll_line - max_term_lines + 1, 0, math::max(0, total_tlines - max_term_lines));
				int rel_ty         = (int)(mouse_pos.y - (float)(ty + lm.line_height + 8));
				int drag_line      = start_idx + (rel_ty / lm.line_height);
				int drag_col       = math::max(0, (int)(mouse_pos.x - 14.0f) / lm.char_width);

				editor.terminal.sel_end_line = drag_line;
				editor.terminal.sel_end_col = drag_col;
			}

		case editor.scrollbar_dragging && gfx::is_mouse_down(LEFT):
			if (tot_lines > lm.visible_lines)
			{
				float max_scroll   = (float)(tot_lines - lm.visible_lines);
				float track_h      = lm.scrollbar_rect.height;
				float thumb_h      = math::max(config::LAYOUT_METRICS.scrollbar_min_thumb_h, track_h * (float)lm.visible_lines / (float)tot_lines);
				float scrollable_h = track_h - thumb_h;
				float new_thumb_y  = mouse_pos.y - editor.scrollbar_drag_offset_y;
				float norm         = scrollable_h > 0.0f ? (new_thumb_y - lm.scrollbar_rect.y) / scrollable_h : 0.0f;
				tab.scroll_line = math::clamp((int)math::round(norm * max_scroll), 0, (int)max_scroll);
				editor.reset_cursor_blink();
			}

		case editor.minimap_dragging && gfx::is_mouse_down(LEFT):
			if (tot_lines > lm.visible_lines)
			{
				float mm_y = lm.minimap_rect.y;
				float mm_h = lm.minimap_rect.height;
				int max_scroll = math::max(0, tot_lines - lm.visible_lines);
				float click_rel_y = mouse_pos.y - mm_y;
				float norm = mm_h > 0.0f ? click_rel_y / mm_h : 0.0f;
				tab.scroll_line = math::clamp((int)math::round(norm * (float)max_scroll), 0, max_scroll);
				editor.reset_cursor_blink();
			}

		case editor.mouse_down && gfx::is_mouse_down(LEFT):
			int rel_y = (int)(mouse_pos.y - (float)lm.text_start_y);
			int line  = rel_y / lm.line_height + tab.scroll_line;
			int rel_x = (int)(mouse_pos.x - (float)lm.text_start_x + (float)lm.char_width * 0.5f);
			int col   = math::max(0, rel_x / lm.char_width + tab.scroll_col);
			BytePos cur_pos = doc.get_pos_from_line_col(line, col);

			Cursor* cur_p = doc.primary_cursor();
			if (editor.line_selecting)
			{
				int drag_line = doc.get_line(cur_pos);
				BytePos drag_l_start = doc.get_line_start_of_line(drag_line);
				BytePos drag_l_end = (drag_line + 1 < doc.get_total_lines())
					? doc.get_line_start_of_line(drag_line + 1)
					: doc.get_line_end(drag_l_start);

				if (cur_pos >= editor.word_sel_anchor_start)
				{
					cur_p.anchor = editor.word_sel_anchor_start;
					cur_p.pos = drag_l_end;
				}
				else
				{
					cur_p.anchor = editor.word_sel_anchor_end;
					cur_p.pos = drag_l_start;
				}
			}
			else if (editor.word_selecting)
			{
				TextRange cur_bounds = get_word_bounds(&doc.table, cur_pos);
				if (cur_pos >= editor.word_sel_anchor_start)
				{
					cur_p.anchor = editor.word_sel_anchor_start;
					cur_p.pos = cur_bounds.end;
				}
				else
				{
					cur_p.anchor = editor.word_sel_anchor_end;
					cur_p.pos = cur_bounds.start;
				}
			}
			else
			{
				cur_p.pos = cur_pos;
			}
			cur_p.target_col = doc.get_col(cur_p.pos);
			editor.reset_cursor_blink();

		case gfx::is_mouse_released(LEFT):
			if (editor.terminal.selecting)
			{
				editor.terminal.selecting = false;
				if (editor.terminal.has_selection())
				{
					String? sel_text = editor.terminal.extract_selection(tmem);
					if (try t = sel_text)
					{
						gfx::set_clipboard(t);
					}
				}
			}
			editor.mouse_down = false;
			editor.word_selecting = false;
			editor.line_selecting = false;
			editor.scrollbar_dragging = false;
			editor.minimap_dragging = false;
	}

	float wheel = gfx::get_mouse_wheel();
	if (wheel != 0.0f)
	{
		if (editor.terminal.is_open && lm.terminal_height > 0)
		{
			int ty = (int)lm.terminal_rect.y;
			int th = lm.terminal_height;
			if (mouse_pos.y >= (float)ty && mouse_pos.y < (float)(ty + th))
			{
				int total_tlines = (int)editor.terminal.lines.len();
				editor.terminal.scroll_line = math::clamp(editor.terminal.scroll_line - (int)wheel * config::LAYOUT_METRICS.scroll_wheel_lines, 0, math::max(0, total_tlines - 1));
				editor.terminal.auto_scroll = (editor.terminal.scroll_line >= total_tlines - 1);
				return;
			}
		}

		switch
		{
			case editor.modifiers.ctrl:
				editor.font_scale = math::clamp(editor.font_scale + (wheel > 0.0f ? config::LAYOUT_METRICS.font_zoom_step : -config::LAYOUT_METRICS.font_zoom_step), config::LAYOUT_METRICS.min_font_scale, config::LAYOUT_METRICS.max_font_scale);
			case editor.modifiers.shift:
				tab.scroll_col = math::max(0, tab.scroll_col - (int)wheel * config::LAYOUT_METRICS.scroll_wheel_cols);
			default:
				tab.scroll_line = math::clamp(tab.scroll_line - (int)wheel * config::LAYOUT_METRICS.scroll_wheel_lines, 0, math::max(0, tot_lines - 1));
		}
		editor.reset_cursor_blink();
	}

	bool page_held = gfx::is_key_down(PAGE_UP) || gfx::is_key_down(PAGE_DOWN);
	editor.page_hold_timer = page_held ? editor.page_hold_timer + dt : 0.0f;

	for (int k = 32; k < 349; k++)
	{
		Key key = (Key)k;
		bool is_triggered = false;
		switch (key)
		{
			case LEFT:
			case RIGHT:
			case UP:
			case DOWN:
			case PAGE_UP:
			case PAGE_DOWN:
			case HOME:
			case END:
			case BACKSPACE:
			case DELETE:
			case ENTER:
			case KP_ENTER:
			case TAB:
				is_triggered = key_pressed_or_repeat(key);
			default:
				switch
				{
					case editor.modifiers.ctrl && (key == Z || key == Y || key == D || key == R || key == SPACE):
					case editor.modifiers.alt && (key == UP || key == DOWN || key == C):
						is_triggered = key_pressed_or_repeat(key);
					default:
						is_triggered = gfx::is_key_pressed(key);
				}
		}
		if (is_triggered)
		{
			EditorCommand cmd = config::resolve_key_command(key, editor.modifiers);
			if (cmd != CMD_NONE) editor.dispatch_command(cmd, lm, dt);
		}
	}

	int cp = gfx::get_char_pressed();
	while (cp > 0)
	{
		if (cp >= 32 && (!editor.modifiers.ctrl || editor.modifiers.alt))
		{
			doc.insert_codepoint((Char32)cp);
			tab.ensure_cursor_visible(lm.visible_lines, lm.visible_cols);

			if (config::settings.autocomplete_enabled)
			{
				BytePos p = doc.cursors[0].pos;
				bool is_dot = (cp == '.');
				bool is_colon = (cp == ':' && p > 1 && doc.table.char_at(p - 2) == ':');

				TextRange b = get_word_bounds(&doc.table, p);
				String pre = doc.table.get_slice(b.start, p, tmem);

				String parent_target = "";
				if (is_dot && p > 1)
				{
					TextRange pb = get_word_bounds(&doc.table, p - 2);
					parent_target = doc.table.get_slice(pb.start, pb.end, tmem);
				}
				else if (is_colon && p > 2)
				{
					TextRange pb = get_word_bounds(&doc.table, p - 3);
					parent_target = doc.table.get_slice(pb.start, pb.end, tmem);
				}
				else if (b.start > 0 && doc.table.char_at(b.start - 1) == '.')
				{
					is_dot = true;
					TextRange pb = get_word_bounds(&doc.table, b.start - 1);
					parent_target = doc.table.get_slice(pb.start, pb.end, tmem);
				}

				bool is_two_caps = (pre.len >= 2 && pre[0].is_upper() && pre[1].is_upper());
				bool is_camel = (pre.len >= 2 && pre[0].is_upper() && pre[1].is_lower());

				if (is_dot || is_colon || is_two_caps || is_camel || pre.len >= 3)
				{
					editor.autocomplete.collect_suggestions(
						editor.workspace.lsp.symbols.array_view(),
						&doc.table,
						p,
						pre,
						is_dot,
						is_colon,
						parent_target
					);
				}
				else
				{
					editor.autocomplete.is_active = false;
				}
			}
		}
		cp = gfx::get_char_pressed();
	}
}

fn void update_draw_frame() => @pool()
{
	font::init_font_texture();
	float dt     = gfx::get_frame_time();
	int screen_w = gfx::get_screen_width();
	int height   = gfx::get_screen_height();
	if (screen_w <= 0) screen_w = 1600;
	if (height <= 0) height = 900;

	if (editor.save_msg_timer > 0.0f)
	{
		editor.save_msg_timer -= dt;
		if (editor.save_msg_timer < 0.0f) editor.save_msg_timer = 0.0f;
	}

	if (!editor.initialized)
	{
		editor.init(current_workspace);
	}

	Tab* tab                = editor.active_tab();
	BytePos prev_cursor_pos = tab.doc.primary_cursor().pos;
	BytePos prev_table_len  = tab.doc.table.len();

	LayoutMetrics lm = ui::compute_layout(
		screen_w,
		height,
		editor.font_scale,
		tab.doc.get_total_lines(),
		true,
		editor.terminal.is_open,
		editor.terminal.height_px
	);
	update_editor_events(&lm, dt, screen_w, height);

	tab = editor.active_tab();
	if (tab.doc.primary_cursor().pos != prev_cursor_pos || tab.doc.table.len() != prev_table_len)
	{
		editor.reset_cursor_blink();
	}

	ui::render(&editor, screen_w, height, &lm);
}

fn int main(String[] args) @winmain
{
	String target_dir = "";
	List{String} files_to_open;
	files_to_open.tinit(args.len);

	if (args.len > 1)
	{
		for (sz i = 1; i < args.len; i++)
		{
			String arg = args[i];
			if (path::is_dir((Path)arg))
			{
				if (target_dir.len == 0) target_dir = arg;
			}
			else
			{
				files_to_open.push(arg);
			}
		}
	}

	if (target_dir.len > 0)
	{
		(void)path::chdir((Path)target_dir);
	}

	Path? cwd = path::cwd(mem);
	if (try cwd_path = cwd)
	{
		current_workspace = (String)cwd_path;
	}
	else
	{
		current_workspace = target_dir.len > 0 ? target_dir.copy(mem) : ".";
	}

	editor.init(current_workspace);

	if (files_to_open.len() > 0)
	{
		foreach (filepath : files_to_open)
		{
			editor.open_tab(filepath, true);
		}
		editor.active_tab_index = 0;
	}
	else
	{
		bool session_restored = editor.load_session(current_workspace);
		if (!session_restored)
		{
			editor.open_tab(
				"untitled.c3",
				false,
`/* c3ed - Quick Reference

    Ctrl+O / Ctrl+P      Quick open file / path navigator
    Ctrl+Shift+F         Workspace grep search
    Ctrl+Shift+R         Document symbol outline
    F1                   Go to definition (WIP)
    Ctrl+G               Go to line

    Ctrl+F / Ctrl+H      Find / Replace in file
    Alt+C                Toggle case sensitivity

    F5                   Run project (c3c run)
    Ctrl+F5              Run current file (c3c compile-run)
    Ctrl+Shift+B         Build project (c3c build)
    Ctrl+~               Toggle output / terminal panel

    Ctrl+Shift+Up/Down   Column multi-cursor
    Ctrl+D               Select next occurrence
    Ctrl+/               Toggle line comment
    Ctrl+Shift+D         Duplicate line
*/

module main;
import std;

fn int main(String[] args)
{
	io::printn("Hello from c3ed!");
	return 0;
}
`
			);
		}
	}

	gfx::init_window(1024, 600, "C3 Text Editor");

	$if env::WASM:
		emscripten_set_main_loop(&update_draw_frame, 60, 1);
	$else
		while (!editor.should_exit)
		{
			if (gfx::should_close())
			{
				bool any_modified = false;
				foreach (&t : editor.tabs)
				{
					if (t.doc.is_modified)
					{
						any_modified = true;
						break;
					}
				}
				if (any_modified)
				{
					editor.modal.kind = CONFIRM_EXIT;
					editor.reset_cursor_blink();
				}
				else
				{
					editor.should_exit = true;
				}
			}
			update_draw_frame();
		}

		editor.save_session(current_workspace);
		editor.free();
		gfx::close_window();
	$endif

	return 0;
}

alias EmCallbackFunc = fn void();
extern fn void emscripten_set_main_loop(EmCallbackFunc func, int fps, int simulate_infinite_loop) @feat(WASM);module c3ed;
import std;

enum ModalKind : int
{
	NONE,
	FIND,
	REPLACE,
	GLOBAL_GREP,
	QUICK_OPEN,
	GOTO_LINE,
	SYMBOL_OUTLINE,
	SAVE_AS,
	CONFIRM_EXIT,
	CONFIRM_CLOSE_TAB,
	CONFIRM_DISK_RELOAD
}

struct PickerItem
{
	String label;
	String detail;
	String target_path;
	int line;
	int col;
}

fn void PickerItem.free(&self, Allocator allocator = mem)
{
	if (self.label.len > 0) alloc::free(allocator, self.label.ptr);
	if (self.detail.len > 0) alloc::free(allocator, self.detail.ptr);
	if (self.target_path.len > 0) alloc::free(allocator, self.target_path.ptr);
	*self = { };
}

struct ScoredPickerItem @local
{
	PickerItem item;
	int score;
}

struct ModalState
{
	ModalKind kind;
	TextInputWidget input;
	TextInputWidget replace_input;
	int focus_field;

	bool search_case_sensitive;
	int cached_match_count;
	List{int} cached_match_lines;

	ListPickerWidget{PickerItem} picker;

	float grep_debounce_timer;
	bool grep_dirty;
}

fn void ModalState.init(&self, Allocator allocator = mem)
{
	self.kind = NONE;
	self.focus_field = 0;
	self.search_case_sensitive = false;
	self.cached_match_count = 0;
	self.cached_match_lines.init(allocator, 64);
	self.picker.init(allocator, 10);
	self.grep_debounce_timer = 0.0f;
	self.grep_dirty = false;
}

fn void ModalState.free(&self)
{
	self.cached_match_lines.free();
	foreach (&item : self.picker.items) item.free(mem);
	self.picker.items.free();
	*self = { };
}

fn void ModalState.close(&self)
{
	self.kind = NONE;
}

fn bool fuzzy_match(String text, String pattern)
{
	StringIterator pat_it = pattern.iterator();
	Char32 pc @noinit;

	if (try first_pc = pat_it.next())
	{
		pc = first_pc;
	}
	else
	{
		return true;
	}

	StringIterator text_it = text.iterator();
	while (try tc = text_it.next())
	{
		if (tc <= 0x7F && pc <= 0x7F ? ((char)tc).to_lower() == ((char)pc).to_lower() : tc == pc)
		{
			if (try next_pc = pat_it.next())
			{
				pc = next_pc;
			}
			else
			{
				return true;
			}
		}
	}
	return false;
}

fn int score_quick_open_match(String filepath, String query)
{
	if (query.len == 0) return 1;

	String q    = query.to_lower_tcopy();
	String fp   = filepath.to_lower_tcopy();
	String base = (filepath.file_tbasename() ?? filepath).to_lower_tcopy();

	if (!q.contains_char(' '))
	{
		int score = 0;
		switch
		{
			case base == q:           score += 10000;
			case fp == q:             score += 9000;
			case base.starts_with(q): score += 6000;
			case base.contains(q):    score += 4000;
			case fp.starts_with(q):   score += 2500;
			case fp.contains(q):      score += 1500;
			case fuzzy_match(base, q): score += 800;
			case fuzzy_match(fp, q):  score += 200;
			default: return 0;
		}
		if (try dot_idx = base.rindex_of_char('.'))
		{
			if (base[:dot_idx] == q) score += 3000;
		}
		score += math::max(0, 100 - (int)filepath.len);
		return score;
	}

	Splitter tokens = q.tokenize(" ");
	int token_count = 0;
	int score       = 0;

	while (try token = tokens.next())
	{
		if (token.len == 0) continue;
		token_count++;
		switch
		{
			case base == token:           score += 3000;
			case base.starts_with(token): score += 1500;
			case base.contains(token):    score += 1000;
			case fp.contains(token):      score += 500;
			case fuzzy_match(base, token): score += 200;
			case fuzzy_match(fp, token):  score += 50;
			default: return 0;
		}
	}
	if (token_count == 0) return 1;
	score += math::max(0, 100 - (int)filepath.len);
	return score;
}

fn int score_grep_match(String line, String query)
{
	if (query.len == 0) return 1;
	String line_lower  = line.to_lower_tcopy();
	String query_lower = query.to_lower_tcopy();

	if (line_lower.contains(query_lower)) return 1000;
	if (!query_lower.contains_char(' '))
	{
		return fuzzy_match(line_lower, query_lower) ? 200 : 0;
	}

	Splitter tokens = query_lower.tokenize(" ");
	int score       = 0;
	while (try token = tokens.next())
	{
		if (token.len == 0) continue;
		switch
		{
			case line_lower.contains(token): score += 300;
			case fuzzy_match(line_lower, token): score += 50;
			default: return 0;
		}
	}
	return score;
}

fn void ModalState.update_cached_search_matches(&self, Document* doc) => @pool()
{
	self.cached_match_lines.clear();

	if ((self.kind != FIND && self.kind != REPLACE) || self.input.length == 0)
	{
		self.cached_match_count = 0;
		return;
	}

	String query = self.input.view();
	sz qlen      = query.len;
	if (doc.table.len() < qlen) return;

	BytePos sp = 0;
	int match_count = 0;

	while (sp + qlen <= doc.table.len())
	{
		if (try idx = doc.table.find_forward(sp, query, self.search_case_sensitive))
		{
			match_count++;
			if (self.cached_match_lines.len() < 30000)
			{
				int line_idx = doc.get_line(idx);
				self.cached_match_lines.push(line_idx);
			}
			sp = idx + qlen;
		}
		else
		{
			break;
		}
	}
	self.cached_match_count = match_count;
}

fn void ModalState.find_next(
	&self,
	Document* doc,
	bool reverse,
	Tab* tab,
	int visible_lines,
	int visible_cols
)
{
	String query = self.input.view();
	if (query.len == 0) return;
	sz qlen = query.len;
	if (doc.table.len() < qlen) return;

	Cursor* cur = doc.primary_cursor();

	if (!reverse)
	{
		BytePos search_start = cur.sel_end();
		if (search_start + qlen > doc.table.len()) search_start = 0;

		if (try idx = doc.table.find_forward(search_start, query, self.search_case_sensitive))
		{
			cur.anchor = idx;
			cur.pos = idx + qlen;
			cur.target_col = doc.get_col(cur.pos);
			tab.ensure_cursor_visible(visible_lines, visible_cols);
			return;
		}
		if (search_start > 0)
		{
			if (try idx = doc.table.find_forward(0, query, self.search_case_sensitive))
			{
				cur.anchor = idx;
				cur.pos = idx + qlen;
				cur.target_col = doc.get_col(cur.pos);
				tab.ensure_cursor_visible(visible_lines, visible_cols);
			}
		}
	}
	else
	{
		BytePos search_end = (cur.sel_start() > 0)
			? cur.sel_start() - 1
			: (doc.table.len() >= qlen ? doc.table.len() - qlen : 0);

		if (try idx = doc.table.find_backward(search_end, query, self.search_case_sensitive))
		{
			cur.anchor = idx;
			cur.pos = idx + qlen;
			cur.target_col = doc.get_col(cur.pos);
			tab.ensure_cursor_visible(visible_lines, visible_cols);
			return;
		}
		if (search_end < doc.table.len() - qlen)
		{
			if (try idx = doc.table.find_backward(doc.table.len() - qlen, query, self.search_case_sensitive))
			{
				cur.anchor = idx;
				cur.pos = idx + qlen;
				cur.target_col = doc.get_col(cur.pos);
				tab.ensure_cursor_visible(visible_lines, visible_cols);
			}
		}
	}
}

fn void ModalState.find_from_current(&self, Document* doc, Tab* tab, int visible_lines, int visible_cols)
{
	String query = self.input.view();
	if (query.len == 0) return;
	sz qlen = query.len;
	if (doc.table.len() < qlen) return;

	Cursor* cur          = doc.primary_cursor();
	BytePos search_start = cur.sel_start();
	if (search_start + qlen > doc.table.len()) search_start = 0;

	if (try idx = doc.table.find_forward(search_start, query, self.search_case_sensitive))
	{
		cur.anchor = idx;
		cur.pos = idx + qlen;
		cur.target_col = doc.get_col(cur.pos);
		tab.ensure_cursor_visible(visible_lines, visible_cols);
		return;
	}
	if (try idx = doc.table.find_forward(0, query, self.search_case_sensitive))
	{
		cur.anchor = idx;
		cur.pos = idx + qlen;
		cur.target_col = doc.get_col(cur.pos);
		tab.ensure_cursor_visible(visible_lines, visible_cols);
	}
}

fn void ModalState.replace_next(&self, Document* doc, Tab* tab, int visible_lines, int visible_cols)
{
	String query = self.input.view();
	if (query.len == 0) return;
	String replace_text = self.replace_input.view();

	Cursor* cur       = doc.primary_cursor();
	BytePos sel_start = cur.sel_start();
	BytePos sel_end   = cur.sel_end();

	bool is_matching = false;
	if (sel_end - sel_start == query.len)
	{
		DString cur_sel;
		cur_sel.tinit();
		doc.table.append_range_to_dstring(&cur_sel, sel_start, sel_end);
		String sel_view = cur_sel.str_view();
		is_matching = self.search_case_sensitive
			? (sel_view == query)
			: (sel_view.to_lower_tcopy() == query.to_lower_tcopy());
	}

	if (is_matching)
	{
		doc.table.begin_transaction(&doc.cursors);
		doc.table.replace_range(sel_start, sel_end, (char[])replace_text);
		doc.update_line_index_on_edit(sel_start, sel_end - sel_start, replace_text.len);

		cur.pos = sel_start + replace_text.len;
		cur.anchor = cur.pos;
		cur.target_col = doc.get_col(cur.pos);
		doc.table.end_transaction(&doc.cursors);
		doc.is_modified = true;
	}

	self.find_next(doc, false, tab, visible_lines, visible_cols);
	self.update_cached_search_matches(doc);
}

fn void ModalState.replace_all(&self, Document* doc, Tab* tab, int visible_lines, int visible_cols) => @pool()
{
	String query = self.input.view();
	if (query.len == 0) return;
	String replace_text = self.replace_input.view();

	sz qlen = query.len;
	if (doc.table.len() < qlen) return;

	List{BytePos} matches;
	matches.tinit(64);

	BytePos pos = 0;
	while (pos + qlen <= doc.table.len())
	{
		if (try idx = doc.table.find_forward(pos, query, self.search_case_sensitive))
		{
			matches.push(idx);
			pos = idx + qlen;
		}
		else
		{
			break;
		}
	}

	if (matches.len() == 0) return;

	String buf_str = doc.table.to_tstring();
	DString out_buf;
	out_buf.tinit(buf_str.len + matches.len() * replace_text.len + 64);

	BytePos last_pos = 0;
	foreach (m_pos : matches)
	{
		if (m_pos > last_pos)
		{
			out_buf.append(buf_str[last_pos:m_pos - last_pos]);
		}
		out_buf.append(replace_text);
		last_pos = m_pos + qlen;
	}
	if (last_pos < buf_str.len)
	{
		out_buf.append(buf_str[last_pos..]);
	}

	String new_doc    = out_buf.str_view();
	BytePos total_len = doc.table.len();

	doc.table.begin_transaction(&doc.cursors);
	doc.table.replace_range(0, total_len, (char[])new_doc);
	doc.rebuild_line_index();

	Cursor* cur = doc.primary_cursor();
	cur.pos = math::min(cur.pos, doc.table.len());
	cur.anchor = cur.pos;
	cur.target_col = doc.get_col(cur.pos);
	doc.table.end_transaction(&doc.cursors);

	doc.is_modified = true;
	self.update_cached_search_matches(doc);
	tab.ensure_cursor_visible(visible_lines, visible_cols);
}

fn void ModalState.clear_picker(&self)
{
	foreach (&item : self.picker.items) item.free(mem);
	self.picker.items.clear();
	self.picker.selected_index = 0;
	self.picker.scroll_offset = 0;
}

fn void ModalState.update_quick_open_results(&self, Workspace* ws) => @pool()
{
	self.clear_picker();
	String query = self.input.view().trim();

	bool has_slash = query.contains_char('/') || query.contains_char('\\');
	bool is_special_start = query.starts_with("~") || query.starts_with(".") || query.starts_with("/");

	if (has_slash || is_special_start)
	{
		String dir_part = "";
		String filter_part = "";

		sz? slash_pos = query.rindex_of_char('/') ?? query.rindex_of_char('\\');
		if (try s_idx = slash_pos)
		{
			if (s_idx == 0 && (query.starts_with("/") || query.starts_with("\\")))
			{
				dir_part = "/";
				filter_part = query[1..];
			}
			else
			{
				dir_part = query[:s_idx];
				filter_part = query[s_idx + 1..];
			}
		}
		else
		{
			dir_part = query;
			filter_part = "";
		}

		String resolved_dir = resolve_path_string(dir_part, tmem);
		if (resolved_dir.len > 0 && path::is_dir((Path)resolved_dir))
		{
			PathList? entries_opt = path::ls(tmem, (Path)resolved_dir, no_dirs: false, no_symlinks: true, relative: true);
			if (try entries = entries_opt)
			{
				List{ScoredPickerItem} candidates;
				candidates.tinit(entries.len());

				String filter_lower = filter_part.to_lower_tcopy();

				foreach (entry : entries)
				{
					String entry_str = (String)entry;
					if (entry_str.len == 0 || entry_str == "." || entry_str == "..") continue;
					if (is_ignored_dirname(entry_str)) continue;

					String full_rel;
					if (dir_part == "/" || dir_part == "\\")
					{
						full_rel = string::tformat("/%s", entry_str);
					}
					else if (dir_part.ends_with("/") || dir_part.ends_with("\\"))
					{
						full_rel = string::tformat("%s%s", dir_part, entry_str);
					}
					else
					{
						full_rel = string::tformat("%s/%s", dir_part, entry_str);
					}

					String full_resolved = string::tformat("%s/%s", resolved_dir, entry_str);
					bool is_directory = path::is_dir((Path)full_resolved);

					if (is_directory)
					{
						full_rel = string::tformat("%s/", full_rel);
					}
					else if (is_binary_extension(entry_str))
					{
						continue;
					}

					if (filter_part.len == 0)
					{
						int score = is_directory ? 5000 : 1000;
						candidates.push({ { .label = full_rel.copy(tmem), .target_path = full_rel.copy(tmem) }, score });
					}
					else
					{
						String entry_lower = entry_str.to_lower_tcopy();
						int score = 0;
						switch
						{
							case entry_lower == filter_lower:           score = 10000;
							case entry_lower.starts_with(filter_lower): score = 5000;
							case entry_lower.contains(filter_lower):    score = 2000;
							case fuzzy_match(entry_lower, filter_lower): score = 500;
						}
						if (score > 0)
						{
							if (is_directory) score += 500;
							candidates.push({ { .label = full_rel.copy(tmem), .target_path = full_rel.copy(tmem) }, score });
						}
					}
				}

				if (candidates.len() > 0)
				{
					sort::quicksort(&candidates, fn int (ScoredPickerItem a, ScoredPickerItem b) =>
						(a.score != b.score) ? (a.score > b.score ? -1 : 1) : a.item.label.compare_to(b.item.label));

					sz count = math::min(candidates.len(), (sz)100);
					for (sz i = 0; i < count; i++)
					{
						PickerItem it = candidates[i].item;
						self.picker.items.push({ .label = it.label.copy(mem), .target_path = it.target_path.copy(mem) });
					}
					return;
				}
			}
		}
	}

	ws.ensure_files();

	List{ScoredPickerItem} candidates;
	candidates.tinit(ws.files.len());

	foreach (filepath : ws.files)
	{
		int score = score_quick_open_match(filepath, query);
		if (score > 0)
		{
			candidates.push({ { .label = filepath.copy(tmem), .target_path = filepath.copy(tmem) }, score });
		}
	}

	if (candidates.len() > 0)
	{
		sort::quicksort(&candidates, fn int (ScoredPickerItem a, ScoredPickerItem b) =>
			(a.score != b.score) ? (a.score > b.score ? -1 : 1) : a.item.label.compare_to(b.item.label));

		sz count = math::min(candidates.len(), (sz)100);
		for (sz i = 0; i < count; i++)
		{
			PickerItem it = candidates[i].item;
			self.picker.items.push({ .label = it.label.copy(mem), .target_path = it.target_path.copy(mem) });
		}
	}
}

fn void ModalState.update_grep_results(&self, Workspace* ws) => @pool()
{
	self.clear_picker();
	String query = self.input.view();
	if (query.len == 0) return;

	ws.ensure_files();

	List{ScoredPickerItem} candidates;
	candidates.tinit(256);

	foreach (filepath : ws.files)
	{
		File? opened_file = file::open(filepath, "rb");
		if (catch opened_file) continue;
		File f = opened_file;
		defer (void)f.close();

		char[4096] scan_buffer;
		Scanner scanner;
		scanner.init(&f, &scan_buffer);

		int line_num     = 1;
		bool first_chunk = true;

		while (true)
		{
			char[]? scanned_line = scanner.scan("\n");
			if (catch scanned_line)
			{
				char[] remaining = scanner.flush();
				if (remaining.len > 0)
				{
					String line = (String)remaining;
					int score   = score_grep_match(line, query);
					if (score > 0)
					{
						String trimmed = line.trim();
						if (trimmed.len > 120) trimmed = trimmed[:120];
						String display = string::tformat("%s:%d: %s", filepath, line_num, trimmed);
						candidates.push({ { .label = display.copy(tmem), .target_path = filepath.copy(tmem), .line = line_num }, score });
					}
				}
				break;
			}

			char[] line_slice = scanned_line;
			if (first_chunk)
			{
				first_chunk = false;
				sz check_len = math::min(line_slice.len, (sz)1024);
				bool has_null = false;
				for (sz i = 0; i < check_len; i++)
				{
					if (line_slice[i] == '\0') { has_null = true; break; }
				}
				if (has_null) break;
			}

			String line = (String)line_slice;
			int score   = score_grep_match(line, query);
			if (score > 0)
			{
				String trimmed = line.trim();
				if (trimmed.len > 120) trimmed = trimmed[:120];
				String display = string::tformat("%s:%d: %s", filepath, line_num, trimmed);
				candidates.push({ { .label = display.copy(tmem), .target_path = filepath.copy(tmem), .line = line_num }, score });
				if (candidates.len() >= 500) break;
			}
			line_num++;
		}
		if (candidates.len() >= 500) break;
	}

	if (candidates.len() > 0)
	{
		sort::quicksort(&candidates, fn int (ScoredPickerItem a, ScoredPickerItem b) =>
			(a.score != b.score) ? (a.score > b.score ? -1 : 1) : a.item.label.compare_to(b.item.label));

		sz count = math::min(candidates.len(), (sz)200);
		for (sz i = 0; i < count; i++)
		{
			PickerItem it = candidates[i].item;
			self.picker.items.push({ .label = it.label.copy(mem), .target_path = it.target_path.copy(mem), .line = it.line });
		}
	}
}

fn void ModalState.update_outline_results(&self, Document* doc) => @pool()
{
	self.clear_picker();
	String query = self.input.view().to_lower_tcopy();

	SymbolIndex doc_lsp;
	doc_lsp.init(tmem);
	doc_lsp.index_source_text(doc.filepath, doc.table.to_tstring(), tmem);

	List{ScoredPickerItem} candidates;
	candidates.tinit(doc_lsp.symbols.len());

	foreach (&s : doc_lsp.symbols)
	{
		int score = 0;
		if (query.len == 0)
		{
			score = 1;
		}
		else
		{
			String n_lower = s.name.to_lower_tcopy();
			switch
			{
				case n_lower == query:           score = 1000;
				case n_lower.starts_with(query): score = 500;
				case n_lower.contains(query):    score = 200;
				case fuzzy_match(n_lower, query): score = 50;
			}
		}

		if (score > 0)
		{
			String kind_str = "[fn]";
			switch (s.kind)
			{
				case STRUCT:     kind_str = "[struct]";
				case ENUM:       kind_str = "[enum]";
				case MACRO:      kind_str = "[macro]";
				case TYPE_ALIAS: kind_str = "[alias]";
				case CONSTANT:   kind_str = "[const]";
				default:         kind_str = "[fn]";
			}
			String display = string::tformat("%s %s (Line %d)", kind_str, s.name, s.line);
			candidates.push({ { .label = display.copy(tmem), .target_path = doc.filepath.copy(tmem), .line = s.line, .col = s.col }, score });
		}
	}

	sort::quicksort(&candidates, fn int (ScoredPickerItem a, ScoredPickerItem b) =>
		(a.score != b.score) ? (a.score > b.score ? -1 : 1) : (a.item.line - b.item.line));

	sz count = math::min(candidates.len(), (sz)100);
	for (sz i = 0; i < count; i++)
	{
		PickerItem it = candidates[i].item;
		self.picker.items.push({
			.label       = it.label.copy(mem),
			.target_path = it.target_path.copy(mem),
			.line        = it.line,
			.col         = it.col
		});
	}
}
module c3ed;
import std, libc;

enum BufferSource : char
{
	ORIGINAL,
	ADD
}

struct Piece
{
	BufferSource source;
	BytePos offset;
	BytePos length;
	sz line_count;
}

struct PieceMutation
{
	sz piece_index;
	List{Piece} old_pieces;
	List{Piece} new_pieces;
}

struct UndoTransaction
{
	List{PieceMutation} mutations;
	List{Cursor} cursors_before;
	List{Cursor} cursors_after;
}

struct PieceSpan
{
	sz start_idx;
	BytePos start_offset;
	sz end_idx;
	BytePos end_offset;
}

struct PieceTable (Printable)
{
	char[] original_buffer;
	FileMmap mmap_handle;
	bool is_mmap;
	bool owns_buffer;

	char* add_buffer;
	BytePos add_capacity;
	BytePos add_len;

	List{Piece} pieces;
	Allocator allocator;

	List{UndoTransaction*} undo_stack;
	List{UndoTransaction*} redo_stack;
	UndoTransaction* active_transaction;
	bool in_transaction;

	BytePos cached_total_length;
}

const BytePos DEFAULT_ADD_CAPACITY = 4096;

fn void PieceTable.init(
	&self,
	Allocator allocator = mem,
	char[] initial_text = { },
	bool is_mmap = false,
	FileMmap mmap_handle = { },
	bool owns_buffer = true
)
{
	self.allocator = allocator;
	self.original_buffer = initial_text;
	self.is_mmap = is_mmap;
	self.mmap_handle = mmap_handle;
	self.owns_buffer = owns_buffer;

	self.add_capacity = DEFAULT_ADD_CAPACITY;
	self.add_len = 0;
	self.add_buffer = alloc::alloc_array(allocator, char, self.add_capacity);

	self.pieces.init(allocator, 16);
	self.undo_stack.init(allocator, 32);
	self.redo_stack.init(allocator, 32);
	self.active_transaction = null;
	self.in_transaction = false;

	if (initial_text.len > 0)
	{
		sz lines = count_newlines(initial_text);
		self.pieces.push({ .source = ORIGINAL, .offset = 0, .length = initial_text.len, .line_count = lines });
		self.cached_total_length = initial_text.len;
	}
	else
	{
		self.cached_total_length = 0;
	}
}

fn void PieceTable.free(&self)
{
	if (self.add_buffer)
	{
		alloc::free(self.allocator, self.add_buffer);
		self.add_buffer = null;
	}
	self.pieces.free();
	self.clear_undo_redo();
	self.undo_stack.free();
	self.redo_stack.free();

	if (self.is_mmap)
	{
		(void)self.mmap_handle.destroy();
	}
	else if (self.owns_buffer && self.original_buffer.len > 0)
	{
		alloc::free(self.allocator, self.original_buffer.ptr);
	}
	*self = { };
}

fn void free_undo_transaction(Allocator allocator, UndoTransaction* tx) @private
{
	if (!tx) return;
	for (sz i = 0; i < tx.mutations.len(); i++)
	{
		tx.mutations[i].old_pieces.free();
		tx.mutations[i].new_pieces.free();
	}
	tx.mutations.free();
	tx.cursors_before.free();
	tx.cursors_after.free();
	alloc::free(allocator, tx);
}

fn void PieceTable.clear_undo_redo(&self)
{
	while (try act = self.undo_stack.pop())
	{
		free_undo_transaction(self.allocator, act);
	}
	while (try act = self.redo_stack.pop())
	{
		free_undo_transaction(self.allocator, act);
	}
	if (self.active_transaction)
	{
		free_undo_transaction(self.allocator, self.active_transaction);
		self.active_transaction = null;
		self.in_transaction = false;
	}
}

fn void PieceTable.begin_transaction(&self, List{Cursor}* cursors_before)
{
	if (self.in_transaction) return;
	while (try act = self.redo_stack.pop())
	{
		free_undo_transaction(self.allocator, act);
	}

	UndoTransaction* tx = alloc::new(self.allocator, UndoTransaction);
	tx.mutations.init(self.allocator, 8);
	tx.cursors_before.init(self.allocator, cursors_before.len());
	tx.cursors_after.init(self.allocator, cursors_before.len());

	for (sz i = 0; i < cursors_before.len(); i++)
	{
		tx.cursors_before.push((*cursors_before)[i]);
	}

	self.active_transaction = tx;
	self.in_transaction = true;
}

fn void PieceTable.end_transaction(&self, List{Cursor}* cursors_after)
{
	if (!self.in_transaction || !self.active_transaction) return;

	UndoTransaction* tx = self.active_transaction;
	self.active_transaction = null;
	self.in_transaction = false;

	if (tx.mutations.len() == 0)
	{
		free_undo_transaction(self.allocator, tx);
		return;
	}

	for (sz i = 0; i < cursors_after.len(); i++)
	{
		tx.cursors_after.push((*cursors_after)[i]);
	}

	self.undo_stack.push(tx);
}

fn void PieceTable.record_mutation(&self, PieceMutation mutation)
{
	if (self.in_transaction && self.active_transaction)
	{
		self.active_transaction.mutations.push(mutation);
	}
	else
	{
		while (try act = self.redo_stack.pop())
		{
			free_undo_transaction(self.allocator, act);
		}
		UndoTransaction* tx = alloc::new(self.allocator, UndoTransaction);
		tx.mutations.init(self.allocator, 1);
		tx.cursors_before.init(self.allocator, 0);
		tx.cursors_after.init(self.allocator, 0);
		tx.mutations.push(mutation);
		self.undo_stack.push(tx);
	}
}

fn BytePos PieceTable.len(&self) @operator(len) @inline => self.cached_total_length;

fn char PieceTable.get(&self, BytePos index) @operator([])
{
	assert(index < self.cached_total_length, "PieceTable index out of bounds");
	BytePos current_offset = 0;

	foreach (&p : self.pieces)
	{
		if (index < current_offset + p.length)
		{
			BytePos local_idx = index - current_offset;
			return (p.source == ORIGINAL)
				? self.original_buffer[p.offset + local_idx]
				: self.add_buffer[p.offset + local_idx];
		}
		current_offset += p.length;
	}
	unreachable("Unreachable piece table index search");
}

fn char PieceTable.char_at(&self, BytePos index, char fallback = '\0') @inline
{
	if (index >= self.cached_total_length) return fallback;
	return self.get(index);
}

fn char[] PieceTable.piece_slice(&self, Piece* p) @inline
{
	return (p.source == ORIGINAL)
		? self.original_buffer[p.offset:p.length]
		: self.add_buffer[p.offset:p.length];
}

fn bool PieceTable.match_cross_boundary(&self, BytePos global_pos, String needle, bool case_sensitive)
{
	sz nlen = needle.len;
	if (global_pos + nlen > self.cached_total_length) return false;

	for (sz j = 0; j < nlen; j++)
	{
		char doc_c = self.char_at(global_pos + (BytePos)j);
		char ned_c = needle[j];
		if (case_sensitive)
		{
			if (doc_c != ned_c) return false;
		}
		else
		{
			if (doc_c != ned_c && ascii::to_lower(doc_c) != ascii::to_lower(ned_c)) return false;
		}
	}
	return true;
}

fn BytePos? PieceTable.find_forward(&self, BytePos start_pos, String needle, bool case_sensitive)
{
	sz nlen = needle.len;
	if (nlen == 0 || self.cached_total_length < nlen || start_pos + nlen > self.cached_total_length)
	{
		return NOT_FOUND~;
	}

	char n0 = needle[0];
	char lower_n0 = ascii::to_lower(n0);
	char upper_n0 = ascii::to_upper(n0);

	BytePos current_piece_start = 0;

	for (sz pi = 0; pi < self.pieces.len(); pi++)
	{
		Piece* p = &self.pieces[pi];
		BytePos p_len = p.length;
		BytePos next_piece_start = current_piece_start + p_len;

		if (start_pos >= next_piece_start)
		{
			current_piece_start = next_piece_start;
			continue;
		}

		sz local_start = (start_pos > current_piece_start) ? (sz)(start_pos - current_piece_start) : 0;
		char[] slice = self.piece_slice(p);
		char* ptr = slice.ptr;

		if (case_sensitive)
		{
			sz cur_idx = local_start;
			while (cur_idx < slice.len)
			{
				void* found = libc::memchr((void*)&ptr[cur_idx], (CInt)n0, (usz)(slice.len - cur_idx));
				if (found == null) break;

				sz match_local = (sz)((uptr)found - (uptr)ptr);
				BytePos global_match = current_piece_start + (BytePos)match_local;

				if (match_local + nlen <= slice.len)
				{
					if (nlen == 1 || libc::memcmp((void*)&ptr[match_local + 1], (void*)&needle[1], (usz)(nlen - 1)) == 0)
					{
						return global_match;
					}
				}
				else
				{
					if (self.match_cross_boundary(global_match, needle, true))
					{
						return global_match;
					}
				}
				cur_idx = match_local + 1;
			}
		}
		else
		{
			sz cur_idx = local_start;
			sz max_local = slice.len >= nlen ? slice.len - nlen : 0;

			while (cur_idx <= max_local)
			{
				char c = ptr[cur_idx];
				if (c == lower_n0 || c == upper_n0)
				{
					bool matched = true;
					for (sz j = 1; j < nlen; j++)
					{
						char dc = ptr[cur_idx + j];
						char nc = needle[j];
						if (dc != nc && ascii::to_lower(dc) != ascii::to_lower(nc))
						{
							matched = false;
							break;
						}
					}
					if (matched)
					{
						return current_piece_start + (BytePos)cur_idx;
					}
				}
				cur_idx++;
			}

			while (cur_idx < slice.len)
			{
				char c = ptr[cur_idx];
				if (c == lower_n0 || c == upper_n0)
				{
					BytePos global_match = current_piece_start + (BytePos)cur_idx;
					if (self.match_cross_boundary(global_match, needle, false))
					{
						return global_match;
					}
				}
				cur_idx++;
			}
		}

		current_piece_start = next_piece_start;
	}

	return NOT_FOUND~;
}

fn BytePos? PieceTable.find_backward(&self, BytePos max_start, String needle, bool case_sensitive)
{
	sz nlen = needle.len;
	if (nlen == 0 || self.cached_total_length < nlen)
	{
		return NOT_FOUND~;
	}

	BytePos max_valid = self.cached_total_length - nlen;
	BytePos start = math::min(max_start, max_valid);

	char n0 = needle[0];
	char lower_n0 = ascii::to_lower(n0);
	char upper_n0 = ascii::to_upper(n0);

	for (BytePos pos = start + 1; pos > 0; pos--)
	{
		BytePos cur = pos - 1;
		char c = self.char_at(cur);
		bool first_matches = case_sensitive ? (c == n0) : (c == lower_n0 || c == upper_n0);
		if (first_matches)
		{
			if (self.match_cross_boundary(cur, needle, case_sensitive))
			{
				return cur;
			}
		}
	}
	return NOT_FOUND~;
}

fn int PieceTable.count_matches(&self, String needle, bool case_sensitive, int max_count = int::max)
{
	sz nlen = needle.len;
	if (nlen == 0 || self.cached_total_length < nlen) return 0;

	int count = 0;
	BytePos pos = 0;
	while (pos + nlen <= self.cached_total_length)
	{
		if (try match_pos = self.find_forward(pos, needle, case_sensitive))
		{
			count++;
			if (count >= max_count) break;
			pos = match_pos + nlen;
		}
		else
		{
			break;
		}
	}
	return count;
}

fn void PieceTable.ensure_add_capacity(&self, BytePos needed)
{
	if (self.add_len + needed <= self.add_capacity) return;
	BytePos new_cap = math::max(self.add_capacity * 2, self.add_len + needed + 1024);
	self.add_buffer = alloc::realloc(self.allocator, self.add_buffer, new_cap);
	self.add_capacity = new_cap;
}

fn sz count_newlines(char[] text) @private
{
	sz count = 0;
	foreach (c : text)
	{
		if (c == '\n') count++;
	}
	return count;
}

fn Piece make_sub_piece(PieceTable* pt, Piece p, BytePos local_start, BytePos local_len) @private
{
	char[] piece_bytes = (p.source == ORIGINAL)
		? pt.original_buffer[p.offset + local_start:local_len]
		: pt.add_buffer[p.offset + local_start:local_len];

	sz lines = count_newlines(piece_bytes);
	return { .source = p.source, .offset = p.offset + local_start, .length = local_len, .line_count = lines };
}

fn void PieceTable.recalculate_total_length(&self)
{
	BytePos total = 0;
	foreach (&p : self.pieces) total += p.length;
	self.cached_total_length = total;
}

fn bool PieceTable.find_piece_span(&self, BytePos s, BytePos e, PieceSpan* out_span)
{
	BytePos current_offset = 0;
	bool found_start = false;
	bool found_end = false;

	for (sz i = 0; i < self.pieces.len(); i++)
	{
		Piece p = self.pieces[i];
		BytePos next_offset = current_offset + p.length;

		if (!found_start && s >= current_offset
			&& (s < next_offset || (s == next_offset && i + 1 == self.pieces.len())))
		{
			out_span.start_idx = i;
			out_span.start_offset = s - current_offset;
			found_start = true;
		}

		if (!found_end && e > current_offset && e <= next_offset)
		{
			out_span.end_idx = i;
			out_span.end_offset = e - current_offset;
			found_end = true;
			break;
		}
		current_offset = next_offset;
	}

	return found_start && found_end;
}

fn void PieceTable.insert_bytes(&self, BytePos pos, char[] bytes)
{
	if (bytes.len == 0) return;
	BytePos byte_len = bytes.len;

	self.ensure_add_capacity(byte_len);
	BytePos add_offset = self.add_len;
	mem::copy(&self.add_buffer[add_offset], bytes.ptr, byte_len);
	self.add_len += byte_len;

	sz lines = count_newlines(bytes);
	Piece new_p = { .source = ADD, .offset = add_offset, .length = byte_len, .line_count = lines };

	PieceMutation mut;
	switch
	{
		case pos == 0:
			mut.piece_index = 0;
			mut.old_pieces.init(self.allocator, 0);
			mut.new_pieces.init(self.allocator, 1);
			mut.new_pieces.push(new_p);
			self.pieces.insert_at(0, new_p);

		case pos >= self.cached_total_length:
			sz idx = self.pieces.len();
			mut.piece_index = idx;
			mut.old_pieces.init(self.allocator, 0);
			mut.new_pieces.init(self.allocator, 1);
			mut.new_pieces.push(new_p);
			self.pieces.push(new_p);

		default:
			BytePos current_offset = 0;
			bool handled = false;
			for (sz i = 0; i < self.pieces.len(); i++)
			{
				Piece p = self.pieces[i];
				if (pos == current_offset)
				{
					mut.piece_index = i;
					mut.old_pieces.init(self.allocator, 0);
					mut.new_pieces.init(self.allocator, 1);
					mut.new_pieces.push(new_p);
					self.pieces.insert_at(i, new_p);
					handled = true;
					break;
				}

				if (pos > current_offset && pos < current_offset + p.length)
				{
					BytePos left_len  = pos - current_offset;
					BytePos right_len = p.length - left_len;

					Piece left_piece  = make_sub_piece(self, p, 0, left_len);
					Piece right_piece = make_sub_piece(self, p, left_len, right_len);

					mut.piece_index = i;
					mut.old_pieces.init(self.allocator, 1);
					mut.old_pieces.push(p);

					mut.new_pieces.init(self.allocator, 3);
					mut.new_pieces.push(left_piece);
					mut.new_pieces.push(new_p);
					mut.new_pieces.push(right_piece);

					self.pieces[i] = left_piece;
					self.pieces.insert_at(i + 1, new_p);
					self.pieces.insert_at(i + 2, right_piece);
					handled = true;
					break;
				}
				current_offset += p.length;
			}
			if (!handled)
			{
				sz idx = self.pieces.len();
				mut.piece_index = idx;
				mut.old_pieces.init(self.allocator, 0);
				mut.new_pieces.init(self.allocator, 1);
				mut.new_pieces.push(new_p);
				self.pieces.push(new_p);
			}
	}

	self.record_mutation(mut);
	self.cached_total_length += byte_len;
}

fn void PieceTable.replace_range(&self, BytePos start, BytePos end, char[] bytes)
{
	if (start == end || start >= self.cached_total_length)
	{
		self.insert_bytes(start, bytes);
		return;
	}

	BytePos s = math::min(start, self.cached_total_length);
	BytePos e = math::min(end, self.cached_total_length);
	if (s >= e)
	{
		self.insert_bytes(s, bytes);
		return;
	}

	PieceSpan span;
	if (!self.find_piece_span(s, e, &span)) return;

	Piece start_p = self.pieces[span.start_idx];
	Piece end_p   = self.pieces[span.end_idx];

	PieceMutation mut;
	mut.piece_index = span.start_idx;

	sz old_count = span.end_idx - span.start_idx + 1;
	mut.old_pieces.init(self.allocator, old_count);
	for (sz i = span.start_idx; i <= span.end_idx; i++)
	{
		mut.old_pieces.push(self.pieces[i]);
	}

	mut.new_pieces.init(self.allocator, 3);

	if (span.start_offset > 0)
	{
		mut.new_pieces.push(make_sub_piece(self, start_p, 0, span.start_offset));
	}

	BytePos byte_len = bytes.len;
	if (byte_len > 0)
	{
		self.ensure_add_capacity(byte_len);
		BytePos add_offset = self.add_len;
		mem::copy(&self.add_buffer[add_offset], bytes.ptr, byte_len);
		self.add_len += byte_len;

		sz lines = count_newlines(bytes);
		mut.new_pieces.push({ .source = ADD, .offset = add_offset, .length = byte_len, .line_count = lines });
	}

	if (span.end_offset < end_p.length)
	{
		mut.new_pieces.push(make_sub_piece(self, end_p, span.end_offset, end_p.length - span.end_offset));
	}

	sz remaining = self.pieces.len() - (span.end_idx + 1);
	if (remaining > 0)
	{
		mem::move(
			&self.pieces.entries[span.start_idx],
			&self.pieces.entries[span.end_idx + 1],
			remaining * Piece::size
		);
	}
	self.pieces.size -= old_count;

	for (sz i = 0; i < mut.new_pieces.len(); i++)
	{
		self.pieces.insert_at(span.start_idx + i, mut.new_pieces[i]);
	}

	self.record_mutation(mut);
	self.cached_total_length = self.cached_total_length - (e - s) + byte_len;
}

fn void PieceTable.delete_range(&self, BytePos start, BytePos end)
{
	self.replace_range(start, end, { });
}

fn void PieceTable.apply_mutation_list(&self, List{PieceMutation}* mutations, bool is_undo)
{
	sz mut_count = mutations.len();
	for (sz step = 0; step < mut_count; step++)
	{
		sz k = is_undo ? (mut_count - 1 - step) : step;
		PieceMutation* mut = &(*mutations)[k];

		List{Piece}* remove_list = is_undo ? &mut.new_pieces : &mut.old_pieces;
		List{Piece}* insert_list = is_undo ? &mut.old_pieces : &mut.new_pieces;

		sz num_remove = remove_list.len();
		sz remaining  = self.pieces.len() - (mut.piece_index + num_remove);
		if (remaining > 0)
		{
			mem::move(
				&self.pieces.entries[mut.piece_index],
				&self.pieces.entries[mut.piece_index + num_remove],
				remaining * Piece::size
			);
		}
		self.pieces.size -= num_remove;

		for (sz i = 0; i < insert_list.len(); i++)
		{
			self.pieces.insert_at(mut.piece_index + i, (*insert_list)[i]);
		}
	}
	self.recalculate_total_length();
}

fn bool PieceTable.undo_with_range(
	&self,
	List{Cursor}* out_cursors,
	BytePos* out_edit_start,
	BytePos* out_deleted_len,
	BytePos* out_inserted_len
)
{
	UndoTransaction*? tx_opt = self.undo_stack.pop();
	if (catch tx_opt) return false;
	UndoTransaction* tx = tx_opt;

	BytePos edit_start = 0;
	BytePos del_len = 0;
	BytePos ins_len = 0;

	if (tx.mutations.len() > 0)
	{
		sz first_p_idx = tx.mutations[0].piece_index;
		BytePos offset = 0;
		for (sz i = 0; i < first_p_idx && i < self.pieces.len(); i++)
		{
			offset += self.pieces[i].length;
		}
		edit_start = offset;

		foreach (&mut : tx.mutations)
		{
			foreach (&p : mut.new_pieces) del_len += p.length;
			foreach (&p : mut.old_pieces) ins_len += p.length;
		}
	}

	self.apply_mutation_list(&tx.mutations, true);

	out_cursors.clear();
	for (sz i = 0; i < tx.cursors_before.len(); i++)
	{
		out_cursors.push(tx.cursors_before[i]);
	}

	self.redo_stack.push(tx);

	*out_edit_start = edit_start;
	*out_deleted_len = del_len;
	*out_inserted_len = ins_len;
	return true;
}

fn bool PieceTable.redo_with_range(
	&self,
	List{Cursor}* out_cursors,
	BytePos* out_edit_start,
	BytePos* out_deleted_len,
	BytePos* out_inserted_len
)
{
	UndoTransaction*? tx_opt = self.redo_stack.pop();
	if (catch tx_opt) return false;
	UndoTransaction* tx = tx_opt;

	BytePos edit_start = 0;
	BytePos del_len = 0;
	BytePos ins_len = 0;

	if (tx.mutations.len() > 0)
	{
		sz first_p_idx = tx.mutations[0].piece_index;
		BytePos offset = 0;
		for (sz i = 0; i < first_p_idx && i < self.pieces.len(); i++)
		{
			offset += self.pieces[i].length;
		}
		edit_start = offset;

		foreach (&mut : tx.mutations)
		{
			foreach (&p : mut.old_pieces) del_len += p.length;
			foreach (&p : mut.new_pieces) ins_len += p.length;
		}
	}

	self.apply_mutation_list(&tx.mutations, false);

	out_cursors.clear();
	for (sz i = 0; i < tx.cursors_after.len(); i++)
	{
		out_cursors.push(tx.cursors_after[i]);
	}

	self.undo_stack.push(tx);

	*out_edit_start = edit_start;
	*out_deleted_len = del_len;
	*out_inserted_len = ins_len;
	return true;
}

fn void PieceTable.append_range_to_dstring(&self, DString* ds, BytePos start, BytePos end)
{
	BytePos s = math::min(start, self.cached_total_length);
	BytePos e = math::min(end, self.cached_total_length);
	if (s >= e) return;

	BytePos current_offset = 0;
	foreach (&p : self.pieces)
	{
		BytePos piece_start = current_offset;
		BytePos piece_end   = current_offset + p.length;

		if (piece_end > s && piece_start < e)
		{
			BytePos sub_start = s > piece_start ? s - piece_start : 0;
			BytePos sub_end   = e < piece_end ? e - piece_start : p.length;
			BytePos len       = sub_end - sub_start;

			char[] slice = (p.source == ORIGINAL)
				? self.original_buffer[p.offset + sub_start:len]
				: self.add_buffer[p.offset + sub_start:len];

			ds.append_bytes(slice);
		}
		current_offset += p.length;
	}
}

fn String PieceTable.get_slice(&self, BytePos start, BytePos end, Allocator allocator = tmem)
{
	BytePos s = math::min(start, self.cached_total_length);
	BytePos e = math::min(end, self.cached_total_length);
	if (s >= e) return "";

	PieceSpan span;
	if (self.find_piece_span(s, e, &span))
	{
		if (span.start_idx == span.end_idx)
		{
			Piece p = self.pieces[span.start_idx];
			BytePos len = e - s;
			char[] slice = (p.source == ORIGINAL)
				? self.original_buffer[p.offset + span.start_offset:len]
				: self.add_buffer[p.offset + span.start_offset:len];
			return (String)slice;
		}
	}

	DString ds;
	ds.init(allocator, (e - s) + 16);
	self.append_range_to_dstring(&ds, s, e);
	return ds.copy_str(allocator);
}

fn String PieceTable.to_string(&self, Allocator allocator = mem)
{
	DString ds;
	ds.init(allocator, self.cached_total_length + 16);
	self.append_range_to_dstring(&ds, 0, self.cached_total_length);
	return ds.copy_str(allocator);
}

fn String PieceTable.to_tstring(&self) => self.to_string(tmem);

fn sz? PieceTable.to_format(&self, Formatter* fmt) @dynamic
{
	sz total = 0;
	foreach (&p : self.pieces)
	{
		char[] slice = (p.source == ORIGINAL)
			? self.original_buffer[p.offset:p.length]
			: self.add_buffer[p.offset:p.length];
		total += fmt.print((String)slice)!;
	}
	return total;
}
module c3ed::syntax;
import std, c3ed::config;

enum LineState : char
{
	NORMAL,
	IN_BLOCK_COMMENT,
	IN_CONTRACT_COMMENT,
	IN_RAW_STRING
}

enum TokenType : (Color color, String[] keywords)
{
	DEFAULT { { 226, 232, 240, 255 }, { } },

	KEYWORD { { 255, 123, 114, 255 }, {
		"alias", "assert", "asm", "attrdef", "attrgroup", "attrmacro", "bitstruct", "break",
		"case", "catch", "cenum", "const", "constdef", "constset", "continue", "default",
		"defer", "distinct", "do", "else", "enum", "extern", "false", "faultconst", "faultdef",
		"faultset", "fn", "for", "foreach", "foreach_r", "if", "import", "inline", "interface",
		"lengthof", "macro", "module", "nextcase", "null", "return", "scope", "static", "struct",
		"switch", "tlocal", "true", "try", "typedef", "union", "var", "while", "excuse"
	} },

	TYPE { { 126, 231, 135, 255 }, {
		"any", "void", "bool", "char", "double", "float", "float16", "bfloat", "bfloat16",
		"float128", "int128", "int", "ichar", "iptr", "sz", "long", "short", "uint128",
		"uint", "ulong", "uptr", "ushort", "usz", "typeid", "fault", "untypedlist",
		"$Typeof", "$Typefrom"
	} },

	ATTRIBUTE { { 255, 166, 87, 255 }, {
		"@align", "@allow_deprecated", "@benchmark", "@bigendian", "@builtin", "@callconv",
		"@cname", "@compact", "@const", "@constinit", "@deprecated", "@dynamic", "@export",
		"@feat", "@finalizer", "@format", "@if", "@init", "@inline", "@jump", "@link",
		"@littleendian", "@local", "@maydiscard", "@mustinit", "@naked", "@noalias",
		"@nodiscard", "@noinit", "@noinline", "@nopadding", "@norecurse", "@noreturn",
		"@nosanitize", "@nostrip", "@obfuscate", "@operator", "@operator_r", "@operator_s",
		"@optional", "@overlap", "@packed", "@private", "@public", "@pure", "@reflect",
		"@safeinfer", "@safemacro", "@section", "@simd", "@tag", "@test", "@unused",
		"@used", "@wasm", "@weak", "@weaklink", "@winmain"
	} },

	DIRECTIVE { { 255, 123, 114, 255 }, {
		"$assert", "$case", "$concat", "$default", "$defined", "$echo", "$else", "$embed",
		"$endfor", "$endforeach", "$endif", "$endswitch", "$error", "$eval", "$exec", "$expand",
		"$feat", "$feature", "$for", "$foreach", "$if", "$include", "$reflect", "$stringify",
		"$switch", "$vaarg", "$vaexpr", "$varef"
	} },

	BUILTIN { { 210, 168, 255, 255 }, {
		"$$abs", "$$acos", "$$asin", "$$atan", "$$any_make", "$$atomic_load", "$$atomic_store",
		"$$atomic_fetch_exchange", "$$atomic_fetch_add", "$$atomic_fetch_sub", "$$atomic_fetch_and",
		"$$atomic_fetch_nand", "$$atomic_fetch_or", "$$atomic_fetch_xor", "$$atomic_fetch_max",
		"$$atomic_fetch_min", "$$atomic_fetch_inc_wrap", "$$atomic_fetch_dec_wrap", "$$bitreverse",
		"$$breakpoint", "$$bswap", "$$ceil", "$$compare_exchange", "$$copysign", "$$cos", "$$cosh",
		"$$clz", "$$ctz", "$$add", "$$div", "$$mod", "$$mul", "$$neg", "$$sub", "$$exp", "$$exp2",
		"$$exp10", "$$expect", "$$expect_with_probability", "$$fence", "$$floor", "$$fma",
		"$$fmuladd", "$$frameaddress", "$$fshl", "$$fshr", "$$gather", "$$get_rounding_mode",
		"$$int_to_mask", "$$log", "$$log2", "$$log10", "$$matrix_mul", "$$matrix_transpose",
		"$$mask_to_int", "$$masked_load", "$$masked_store", "$$max", "$$memcpy", "$$memcpy_inline",
		"$$memmove", "$$memset", "$$memset_inline", "$$min", "$$nearbyint", "$$overflow_add",
		"$$overflow_mul", "$$overflow_sub", "$$popcount", "$$pow", "$$pow_int", "$$prefetch",
		"$$reduce_add", "$$reduce_and", "$$reduce_fadd", "$$reduce_fmul", "$$reduce_max",
		"$$reduce_min", "$$reduce_mul", "$$reduce_or", "$$reduce_xor", "$$reverse", "$$returnaddress",
		"$$rint", "$$rnd", "$$round", "$$roundeven", "$$sat_add", "$$sat_shl", "$$sat_sub",
		"$$sat_mul", "$$scatter", "$$select", "$$set_rounding_mode", "$$sprintf", "$$str_find",
		"$$str_hash", "$$str_lower", "$$str_pascalcase", "$$str_replace", "$$str_upper",
		"$$str_snakecase", "$$swizzle", "$$swizzle2", "$$sin", "$$sinh", "$$sqrt", "$$syscall",
		"$$sysclock", "$$tan", "$$tanh", "$$trap", "$$trunc", "$$unaligned_load", "$$unaligned_store",
		"$$unreachable", "$$veccomplt", "$$veccomple", "$$veccompgt", "$$veccompge", "$$veccompeq",
		"$$veccompne", "$$volatile_load", "$$volatile_store", "$$wasm_memory_size", "$$wasm_memory_grow",
		"$$wstr16", "$$wstr32", "$$DATE", "$$FILE", "$$FILEPATH", "$$FUNC", "$$FUNCTION", "$$LINE",
		"$$LINE_RAW", "$$MODULE", "$$BENCHMARK_NAMES", "$$BENCHMARK_FNS", "$$TEST_NAMES", "$$TEST_FNS",
		"$$TIME"
	} },

	FUNCTION       { { 210, 168, 255, 255 }, { } },
	NUMBER         { { 121, 192, 255, 255 }, { } },
	STRING_LITERAL { { 165, 214, 255, 255 }, { } },
	COMMENT        { { 139, 148, 158, 255 }, { } },
	CONTRACT       { { 165, 180, 198, 255 }, { } },
	OPERATOR       { { 255, 123, 114, 255 }, { } },
	DELIMITER      { { 201, 209, 217, 255 }, { } }
}

fn TokenType match_word_token(String w, bool is_fn)
{
	if (w.len == 0) return DEFAULT;

	char c0 = w[0];

	if (c0 == '@')
	{
		foreach (aw : TokenType.ATTRIBUTE.keywords)
		{
			if (aw == w) return ATTRIBUTE;
		}
		return DEFAULT;
	}

	if (c0 == '$')
	{
		if (w.len > 1 && w[1] == '$')
		{
			foreach (bw : TokenType.BUILTIN.keywords)
			{
				if (bw == w) return BUILTIN;
			}
		}
		else
		{
			foreach (dw : TokenType.DIRECTIVE.keywords)
			{
				if (dw == w) return DIRECTIVE;
			}
		}
		return DEFAULT;
	}

	foreach (kw : TokenType.KEYWORD.keywords)
	{
		if (kw == w) return KEYWORD;
	}
	foreach (tw : TokenType.TYPE.keywords)
	{
		if (tw == w) return TYPE;
	}

	switch
	{
		case w.len > 1 && (c0 == 'i' || c0 == 'u') && w[1].is_digit():
			return TYPE;
		case c0.is_upper():
			return TYPE;
		case is_fn:
			return FUNCTION;
		default:
			return DEFAULT;
	}
}

fn LineState lex_state_only(String line, LineState initial_state)
{
	LineState state = initial_state;
	sz len          = line.len;
	sz idx          = 0;

	while (idx < len)
	{
		char c = line[idx];
		switch
		{
			case state == IN_BLOCK_COMMENT:
				if (c == '*' && idx + 1 < len && line[idx + 1] == '/')
				{
					state = NORMAL;
					idx++;
				}
				idx++;

			case state == IN_CONTRACT_COMMENT:
				if (c == '*' && idx + 1 < len && line[idx + 1] == '>')
				{
					state = NORMAL;
					idx++;
				}
				idx++;

			case state == IN_RAW_STRING:
				if (c == '`')
				{
					state = NORMAL;
				}
				idx++;

			case (c == '/' && idx + 1 < len && line[idx + 1] == '/') || (c == '#' && idx + 1 < len && line[idx + 1] == '!'):
				return state;

			case c == '/' && idx + 1 < len && line[idx + 1] == '*':
				state = IN_BLOCK_COMMENT;
				idx += 2;

			case c == '<' && idx + 1 < len && line[idx + 1] == '*' && !(idx > 0 && line[idx - 1] == '['):
				state = IN_CONTRACT_COMMENT;
				idx += 2;

			case c == '\\' && idx + 1 < len && line[idx + 1] == '\\':
				return state;

			case c == '`':
				state = IN_RAW_STRING;
				idx++;

			case c == '"' || c == '\'':
				char q = c;
				idx++;
				while (idx < len)
				{
					char sc = line[idx];
					if (sc == '\\' && idx + 1 < len)
					{
						idx += 2;
						continue;
					}
					idx++;
					if (sc == q) break;
				}

			default:
				idx++;
		}
	}
	return state;
}

fn LineState lex_slice(String line, LineState initial_state, TokenType[] out_tokens)
{
	LineState state = initial_state;
	sz len          = line.len;
	sz idx          = 0;

	while (idx < len)
	{
		char c = line[idx];
		switch
		{
			case state == IN_BLOCK_COMMENT:
				out_tokens[idx] = COMMENT;
				if (c == '*' && idx + 1 < len && line[idx + 1] == '/')
				{
					state = NORMAL;
					idx++;
					if (idx < len) out_tokens[idx] = COMMENT;
				}
				idx++;

			case state == IN_CONTRACT_COMMENT:
				out_tokens[idx] = CONTRACT;
				if (c == '*' && idx + 1 < len && line[idx + 1] == '>')
				{
					state = NORMAL;
					idx++;
					if (idx < len) out_tokens[idx] = CONTRACT;
				}
				idx++;

			case state == IN_RAW_STRING:
				out_tokens[idx] = STRING_LITERAL;
				if (c == '`')
				{
					state = NORMAL;
				}
				idx++;

			case (c == '/' && idx + 1 < len && line[idx + 1] == '/') || (c == '#' && idx + 1 < len && line[idx + 1] == '!'):
				while (idx < len)
				{
					out_tokens[idx++] = COMMENT;
				}

			case c == '/' && idx + 1 < len && line[idx + 1] == '*':
				out_tokens[idx++] = COMMENT;
				if (idx < len) out_tokens[idx++] = COMMENT;
				state = IN_BLOCK_COMMENT;

			case c == '<' && idx + 1 < len && line[idx + 1] == '*' && !(idx > 0 && line[idx - 1] == '['):
				out_tokens[idx++] = CONTRACT;
				if (idx < len) out_tokens[idx++] = CONTRACT;
				state = IN_CONTRACT_COMMENT;

			case c == '\\' && idx + 1 < len && line[idx + 1] == '\\':
				while (idx < len)
				{
					out_tokens[idx++] = STRING_LITERAL;
				}

			case c == '`':
				out_tokens[idx++] = STRING_LITERAL;
				state = IN_RAW_STRING;

			case c == '"' || c == '\'':
				char q = c;
				out_tokens[idx++] = STRING_LITERAL;
				while (idx < len)
				{
					char sc = line[idx];
					out_tokens[idx++] = STRING_LITERAL;
					if (sc == '\\' && idx < len)
					{
						out_tokens[idx++] = STRING_LITERAL;
						continue;
					}
					if (sc == q) break;
				}

			case c.is_digit():
				sz n_start = idx;
				while (idx < len && (line[idx].is_alnum() || line[idx] == '.' || line[idx] == '_'))
				{
					idx++;
				}
				for (sz k = n_start; k < idx; k++)
				{
					out_tokens[k] = NUMBER;
				}

			case c.is_alpha() || c == '_' || c == '@' || c == '$' || (c & 0x80) != 0:
				sz id_start = idx;
				while (idx < len && (line[idx].is_alnum() || line[idx] == '_' || line[idx] == '$' || line[idx] == '@' || (line[idx] & 0x80) != 0))
				{
					idx++;
				}
				String word = line[id_start:idx - id_start];

				sz p = idx;
				while (p < len && (line[p] == ' ' || line[p] == '\t')) p++;
				bool is_fn = (p < len && line[p] == '(');

				TokenType t = match_word_token(word, is_fn);
				for (sz k = id_start; k < idx; k++)
				{
					out_tokens[k] = t;
				}

			default:
				switch (c)
				{
					case ';':
					case ',':
					case '.':
					case '{':
					case '}':
					case '(':
					case ')':
					case '[':
					case ']':
						out_tokens[idx++] = DELIMITER;
					default:
						out_tokens[idx++] = OPERATOR;
				}
		}
	}
	return state;
}
module c3ed::font;
import std, raylib6, c3ed, std::compression::gzip;

const char[] EMBEDDED_FONT_GZ = $embed("../dep/IntoneMonoNerdFontMono-Regular.ttf.gz");

const int FONT_SIZE           = 20;
const int LINE_HEIGHT         = 20;
const int VERTICAL_OFFSET     = -1;

const int GLYPH_WIDTH_CELLS   = 5;
const int GLYPH_HEIGHT_CELLS  = 8;
const int GLYPH_SPACING_CELLS = 1;

char[] cached_decompressed_font = {};

RLFont ttf_font;
bool ttf_loaded = false;

List{RLFont} fallback_fonts;
List{String} cached_fallback_paths;

int current_loaded_size = 0;
int ttf_char_width = 10;

HashSet{int} registered_codepoints;
List{int} active_codepoints;

RLTexture font_texture;
bool font_texture_ready = false;

fn char[] get_embedded_font_bytes() @private
{
	if (cached_decompressed_font.len == 0)
	{
		char[]? decompressed = gzip::uncompress_bytes(mem, EMBEDDED_FONT_GZ);
		if (try bytes = decompressed)
		{
			cached_decompressed_font = bytes;
		}
	}
	return cached_decompressed_font;
}

fn int get_char_width(float scale)
{
	if (ttf_loaded)
	{
		return math::max(1, ttf_char_width);
	}
	return (int)math::round((float)(GLYPH_WIDTH_CELLS + GLYPH_SPACING_CELLS) * scale);
}

fn int get_char_height(float scale)
{
	if (ttf_loaded)
	{
		return math::max(1, current_loaded_size);
	}
	return (int)math::round((float)GLYPH_HEIGHT_CELLS * scale);
}

fn int get_line_height(float scale)
{
	if (ttf_loaded)
	{
		float ratio = (float)current_loaded_size / (float)FONT_SIZE;
		return math::max(1, (int)math::round((float)LINE_HEIGHT * ratio));
	}
	int ch = get_char_height(scale);
	return ch + math::max(4, (int)math::round(6.0f * scale));
}

enum FontGlyph : (Char32 ch, ulong bitmap)
{
	A { 'A', 0b01110_10001_10001_11111_10001_10001_10001_00000UL },
	B { 'B', 0b11110_10001_10001_11110_10001_10001_11110_00000UL },
	C { 'C', 0b01111_10000_10000_10000_10000_10000_01111_00000UL },
	D { 'D', 0b11110_10001_10001_10001_10001_10001_11110_00000UL },
	E { 'E', 0b11111_10000_10000_11110_10000_10000_11111_00000UL },
	F { 'F', 0b11111_10000_10000_11110_10000_10000_10000_00000UL },
	G { 'G', 0b01111_10000_10000_10111_10001_10001_01111_00000UL },
	H { 'H', 0b10001_10001_10001_11111_10001_10001_10001_00000UL },
	I { 'I', 0b01110_00100_00100_00100_00100_00100_01110_00000UL },
	J { 'J', 0b00111_00010_00010_00010_00010_10010_01100_00000UL },
	K { 'K', 0b10001_10010_10100_11000_10100_10010_10001_00000UL },
	L { 'L', 0b10000_10000_10000_10000_10000_10000_11111_00000UL },
	M { 'M', 0b10001_11011_10101_10101_10001_10001_10001_00000UL },
	N { 'N', 0b10001_11001_10101_10011_10001_10001_10001_00000UL },
	O { 'O', 0b01110_10001_10001_10001_10001_10001_01110_00000UL },
	P { 'P', 0b11110_10001_10001_11110_10000_10000_10000_00000UL },
	Q { 'Q', 0b01110_10001_10001_10001_10101_10010_01101_00000UL },
	R { 'R', 0b11110_10001_10001_11110_10100_10010_10001_00000UL },
	S { 'S', 0b01111_10000_10000_01110_00001_00001_11110_00000UL },
	T { 'T', 0b11111_00100_00100_00100_00100_00100_00100_00000UL },
	U { 'U', 0b10001_10001_10001_10001_10001_10001_01110_00000UL },
	V { 'V', 0b10001_10001_10001_10001_10001_01010_00100_00000UL },
	W { 'W', 0b10001_10001_10001_10101_10101_11011_10001_00000UL },
	X { 'X', 0b10001_10001_01010_00100_01010_10001_10001_00000UL },
	Y { 'Y', 0b10001_10001_01010_00100_00100_00100_00100_00000UL },
	Z { 'Z', 0b11111_00001_00010_00100_01000_10000_11111_00000UL },

	LOWER_A { 'a', 0b00000_00000_01111_00001_01111_10001_01111_00000UL },
	LOWER_B { 'b', 0b10000_10000_11110_10001_10001_10001_11110_00000UL },
	LOWER_C { 'c', 0b00000_00000_01111_10000_10000_10000_01111_00000UL },
	LOWER_D { 'd', 0b00001_00001_01111_10001_10001_10001_01111_00000UL },
	LOWER_E { 'e', 0b00000_00000_01111_10001_11111_10000_01111_00000UL },
	LOWER_F { 'f', 0b00110_01001_01000_11110_01000_01000_01000_00000UL },
	LOWER_G { 'g', 0b00000_00000_01111_10001_10001_01111_00001_11110UL },
	LOWER_H { 'h', 0b10000_10000_11110_10001_10001_10001_10001_00000UL },
	LOWER_I { 'i', 0b00100_00000_01100_00100_00100_00100_01110_00000UL },
	LOWER_J { 'j', 0b00010_00000_00010_00010_00010_00010_10010_01100UL },
	LOWER_K { 'k', 0b10000_10000_10010_10100_11000_10100_10010_00000UL },
	LOWER_L { 'l', 0b01100_00100_00100_00100_00100_00100_01110_00000UL },
	LOWER_M { 'm', 0b00000_00000_11010_10101_10101_10101_10101_00000UL },
	LOWER_N { 'n', 0b00000_00000_11110_10001_10001_10001_10001_00000UL },
	LOWER_O { 'o', 0b00000_00000_01110_10001_10001_10001_01110_00000UL },
	LOWER_P { 'p', 0b00000_00000_11110_10001_10001_11110_10000_10000UL },
	LOWER_Q { 'q', 0b00000_00000_01111_10001_10001_01111_00001_00001UL },
	LOWER_R { 'r', 0b00000_00000_10110_11001_10000_10000_10000_00000UL },
	LOWER_S { 's', 0b00000_00000_01111_10000_01110_00001_11110_00000UL },
	LOWER_T { 't', 0b00100_00100_11111_00100_00100_00100_00011_00000UL },
	LOWER_U { 'u', 0b00000_00000_10001_10001_10001_10011_01101_00000UL },
	LOWER_V { 'v', 0b00000_00000_10001_10001_10001_01010_00100_00000UL },
	LOWER_W { 'w', 0b00000_00000_10001_10001_10101_10101_01010_00000UL },
	LOWER_X { 'x', 0b00000_00000_10001_01010_00100_01010_10001_00000UL },
	LOWER_Y { 'y', 0b00000_00000_10001_10001_10001_01111_00001_11110UL },
	LOWER_Z { 'z', 0b00000_00000_11111_00010_00100_01000_11111_00000UL },

	ZERO        { '0', 0b01110_10001_10011_10101_11001_10001_01110_00000UL },
	ONE         { '1', 0b00100_01100_00100_00100_00100_00100_01110_00000UL },
	TWO         { '2', 0b01110_10001_00001_00010_00100_01000_11111_00000UL },
	THREE       { '3', 0b11111_00010_00100_00010_00001_10001_01110_00000UL },
	FOUR        { '4', 0b00010_00110_01010_10010_11111_00010_00010_00000UL },
	FIVE        { '5', 0b11111_10000_11110_00001_00001_10001_01110_00000UL },
	SIX         { '6', 0b00110_01000_10000_11110_10001_10001_01110_00000UL },
	SEVEN       { '7', 0b11111_00001_00010_00100_01000_01000_01000_00000UL },
	EIGHT       { '8', 0b01110_10001_10001_01110_10001_10001_01110_00000UL },
	NINE        { '9', 0b01110_10001_10001_01111_00001_00010_01100_00000UL },
	SPACE       { ' ', 0b00000_00000_00000_00000_00000_00000_00000_00000UL },
	DOT         { '.', 0b00000_00000_00000_00000_00000_00110_00110_00000UL },
	COMMA       { ',', 0b00000_00000_00000_00000_00000_00110_00100_01000UL },
	EXCLAMATION { '!', 0b00100_00100_00100_00100_00100_00000_00100_00000UL },
	QUESTION    { '?', 0b01110_10001_00001_00010_00100_00000_00100_00000UL },
	COLON       { ':', 0b00000_00000_00110_00110_00000_00110_00110_00000UL },
	SEMICOLON   { ';', 0b00000_00000_00110_00110_00000_00110_00100_01000UL },
	QUOTE       { '"', 0b01010_01010_01010_00000_00000_00000_00000_00000UL },
	APOSTROPHE  { '\'', 0b00100_00100_00100_00000_00000_00000_00000_00000UL },
	HYPHEN      { '-', 0b00000_00000_00000_11111_00000_00000_00000_00000UL },
	PLUS        { '+', 0b00000_00100_00100_11111_00100_00100_00000_00000UL },
	EQUALS      { '=', 0b00000_00000_11111_00000_11111_00000_00000_00000UL },
	LESS        { '<', 0b00010_00100_01000_10000_01000_00100_00010_00000UL },
	GREATER     { '>', 0b01000_00100_00010_00001_00010_00100_01000_00000UL },
	LPAREN      { '(', 0b00010_00100_01000_01000_01000_00100_00010_00000UL },
	RPAREN      { ')', 0b01000_00100_00010_00010_00010_00100_01000_00000UL },
	LBRACKET    { '[', 0b01110_01000_01000_01000_01000_01000_01110_00000UL },
	RBRACKET    { ']', 0b01110_00010_00010_00010_00010_00010_01110_00000UL },
	LBRACE      { '{', 0b00011_00100_00100_01000_00100_00100_00011_00000UL },
	RBRACE      { '}', 0b11000_00100_00100_00010_00100_00100_11000_00000UL },
	SLASH       { '/', 0b00001_00010_00010_00100_00100_01000_01000_10000UL },
	BACKSLASH   { '\\', 0b10000_01000_01000_00100_00100_00010_00010_00001UL },
	UNDERSCORE  { '_', 0b00000_00000_00000_00000_00000_00000_00000_11111UL },
	ASTERISK    { '*', 0b00000_01010_00100_11111_00100_01010_00000_00000UL },
	HASH        { '#', 0b01010_01010_11111_01010_11111_01010_01010_00000UL },
	AT          { '@', 0b01110_10001_10111_10101_10110_10000_01111_00000UL },
	AMPERSAND   { '&', 0b01100_10010_01100_01010_10001_10010_01101_00000UL },
	TILDE       { '~', 0b00000_00000_01101_10010_00000_00000_00000_00000UL },
	BACKTICK    { '`', 0b01000_00100_00010_00000_00000_00000_00000_00000UL },
	DOLLAR      { '$', 0b00100_01111_10100_01110_00101_11110_00100_00000UL },
	PERCENT     { '%', 0b11000_11001_00010_00100_01000_10011_00011_00000UL },
	CARET       { '^', 0b00100_01010_10001_00000_00000_00000_00000_00000UL },
	PIPE        { '|', 0b00100_00100_00100_00100_00100_00100_00100_00000UL },
	TAB_ARROW   { 0x2192, 0b00000_00100_00010_11111_00010_00100_00000_00000UL },
	EM_DASH     { '—', 0b10000_00000_00000_11111_00000_00000_00000_10000UL },
	UNKNOWN     { '\0', 0b11111_10001_10101_10101_10101_10001_11111_00000UL }
}

fn ulong get_char_bitmap(Char32 c) => runtime::@enum_lookup(FontGlyph, "ch", c).bitmap ?? FontGlyph.UNKNOWN.bitmap;

fn int get_glyph_atlas_index(Char32 c)
{
	if (c < 128) return (int)c;
	switch (c)
	{
		case 0x2192: return 9;
		case 0x00BB: return 9;
		case '—':    return 128;
		default:
			if (c >= 128 && c < 256) return (int)c;
			FontGlyph? g = runtime::@enum_lookup(FontGlyph, "ch", c);
			if (try g)
			{
				if (g.ch == 0x2192) return 9;
				if (g.ch == '—') return 128;
			}
			return 0;
	}
}

fn bool font_has_glyph(RLFont font, int codepoint)
{
	if (font.glyph_count == 0 || font.glyphs == null) return false;
	int idx = rl::get_glyph_index(font, codepoint);
	if (codepoint == '?') return true;
	return font.glyphs[idx].value == codepoint;
}

fn bool add_codepoint(int cp) @private
{
	if (cp <= 0 || cp > 0x10FFFF) return false;
	if (registered_codepoints.contains(cp)) return false;
	registered_codepoints.add(cp);
	active_codepoints.push(cp);
	return true;
}

fn void init_base_codepoints() @private
{
	if (active_codepoints.entries != null) return;
	active_codepoints.init(mem, 512);
	registered_codepoints.init(mem, 512);

	for (int i = 32; i <= 126; i++) add_codepoint(i);
	for (int i = 160; i <= 255; i++) add_codepoint(i);
	for (int i = 0x0100; i <= 0x017F; i++) add_codepoint(i);
	for (int i = 0x2010; i <= 0x2027; i++) add_codepoint(i);
	add_codepoint(0x2192);
	add_codepoint(0x00BB);
}

fn void load_ttf_at_pixel_size(int pixel_size) @private => @pool()
{
	char[] font_bytes = get_embedded_font_bytes();
	if (font_bytes.len == 0) return;

	init_base_codepoints();

	RLFont new_font = rl::load_font_from_memory(
		".ttf".zstr_tcopy(),
		font_bytes.ptr,
		(int)font_bytes.len,
		pixel_size,
		active_codepoints.entries,
		(int)active_codepoints.len()
	);

	if (new_font.texture.id > 0)
	{
		if (ttf_loaded)
		{
			rl::unload_font(ttf_font);
		}
		ttf_font = new_font;
		ttf_loaded = true;
		ttf_font.texture.set_filter(RLTextureFilter.BILINEAR);
		current_loaded_size = pixel_size;

		RLVector2 sz_m = rl::measure_text_ex(ttf_font, "M", (float)pixel_size, 0.0f);
		ttf_char_width = (sz_m.x > 0.0f) ? (int)math::round(sz_m.x) : math::max(1, pixel_size / 2);
	}

	foreach (&fb : fallback_fonts)
	{
		if (fb.texture.id > 0) rl::unload_font(*fb);
	}
	fallback_fonts.clear();

	foreach (fb_path : cached_fallback_paths)
	{
		RLFont fb_f = rl::load_font_ex(
			fb_path.zstr_tcopy(),
			pixel_size,
			active_codepoints.entries,
			(int)active_codepoints.len()
		);
		if (fb_f.texture.id > 0)
		{
			fb_f.texture.set_filter(RLTextureFilter.BILINEAR);
			fallback_fonts.push(fb_f);
		}
	}
}

fn void ensure_font_scale(float scale)
{
	int target_pixel_size = math::max(8, (int)math::round((float)FONT_SIZE * scale));
	if (target_pixel_size != current_loaded_size)
	{
		load_ttf_at_pixel_size(target_pixel_size);
	}
}

fn String find_script_font_for_codepoint(int cp) @private
{
	String font_name = "";
	switch
	{
		case (cp >= 0x2000 && cp <= 0x2BFF) || (cp >= 0x1F000 && cp <= 0x1FFFF):
			font_name = "NotoSansSymbols2-Regular.ttf";
		case cp >= 0x1200 && cp <= 0x139F:
			font_name = "NotoSansEthiopic-Regular.ttf";
		case cp >= 0x0600 && cp <= 0x06FF:
			font_name = "NotoSansArabic-Regular.ttf";
		case cp >= 0x0590 && cp <= 0x05FF:
			font_name = "NotoSansHebrew-Regular.ttf";
		case cp >= 0x0900 && cp <= 0x097F:
			font_name = "NotoSansDevanagari-Regular.ttf";
		case cp >= 0x0E00 && cp <= 0x0E7F:
			font_name = "NotoSansThai-Regular.ttf";
		case cp >= 0x0980 && cp <= 0x09FF:
			font_name = "NotoSansBengali-Regular.ttf";
		case cp >= 0x0D00 && cp <= 0x0D7F:
			font_name = "NotoSansMalayalam-Regular.ttf";
		case cp >= 0x0B80 && cp <= 0x0BFF:
			font_name = "NotoSansTamil-Regular.ttf";
		case cp >= 0x0C00 && cp <= 0x0C7F:
			font_name = "NotoSansTelugu-Regular.ttf";
		case cp >= 0x1000 && cp <= 0x109F:
			font_name = "NotoSansMyanmar-Regular.ttf";
		case cp >= 0x1780 && cp <= 0x17FF:
			font_name = "NotoSansKhmer-Regular.ttf";
		default:
			break;
	}

	if (font_name.len > 0)
	{
		String[*] candidate_dirs = {
			"/usr/share/fonts/noto",
			"/usr/share/fonts/truetype/noto",
			"/usr/share/fonts/TTF",
			"/usr/share/fonts/opentype/noto"
		};
		foreach (dir : candidate_dirs)
		{
			String path = string::tformat("%s/%s", dir, font_name);
			if (file::exists(path)) return path;
		}
	}
	return "";
}

fn void try_load_ttf() @private => @pool()
{
	if (ttf_loaded) return;

	if (cached_fallback_paths.entries == null) cached_fallback_paths.init(mem, 8);
	if (fallback_fonts.entries == null) fallback_fonts.init(mem, 8);

	String[*] base_fallbacks = {
		"/usr/share/fonts/TTF/DejaVuSans.ttf",
		"/usr/share/fonts/truetype/dejavu/DejaVuSans.ttf",
		"/usr/share/fonts/noto/NotoSansSymbols2-Regular.ttf",
		"/usr/share/fonts/truetype/noto/NotoSansSymbols2-Regular.ttf",
		"/usr/share/fonts/noto/NotoSansSymbols-Regular.ttf",
		"/usr/share/fonts/truetype/noto/NotoSansSymbols-Regular.ttf",
		"/usr/share/fonts/noto/NotoSans-Regular.ttf",
		"/usr/share/fonts/truetype/noto/NotoSans-Regular.ttf"
	};

	foreach (fb : base_fallbacks)
	{
		if (file::exists(fb))
		{
			bool already_added = false;
			foreach (cached : cached_fallback_paths)
			{
				if (cached == fb) { already_added = true; break; }
			}
			if (!already_added)
			{
				cached_fallback_paths.push(fb.copy(mem));
			}
		}
	}

	load_ttf_at_pixel_size(FONT_SIZE);
}

fn void init_font_texture()
{
	if (font_texture_ready) return;
	font_texture_ready = true;

	try_load_ttf();

	RLImage img = rl::gen_image_color(16 * 8, 16 * 8, { 0, 0, 0, 0 });

	for (int i = 0; i < 256; i++)
	{
		ulong bits = 0;
		switch (i)
		{
			case 9:   bits = FontGlyph.TAB_ARROW.bitmap;
			case 128: bits = FontGlyph.EM_DASH.bitmap;
			default:  bits = get_char_bitmap((Char32)i);
		}

		int gx = (i % 16) * 8;
		int gy = (i / 16) * 8;

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

fn void cleanup_font()
{
	if (ttf_loaded)
	{
		rl::unload_font(ttf_font);
		ttf_loaded = false;
	}
	if (cached_decompressed_font.len > 0)
	{
		mem::free(cached_decompressed_font.ptr);
		cached_decompressed_font = {};
	}
	foreach (&fb : fallback_fonts)
	{
		if (fb.texture.id > 0) rl::unload_font(*fb);
	}
	fallback_fonts.free();
	foreach (p : cached_fallback_paths)
	{
		if (p.len > 0) mem::free(p.ptr);
	}
	cached_fallback_paths.free();
	if (font_texture_ready)
	{
		rl::unload_texture(font_texture);
		font_texture_ready = false;
	}
	registered_codepoints.free();
	active_codepoints.free();
}

fn void draw_char(Char32 c, int px, int py, float scale, Color tint)
{
	if (c == ' ' || c == '\r' || c == '\n') return;
	RLColor rl_tint = gfx::to_rl_color(tint);

	if (ttf_loaded)
	{
		int cp = (int)c;
		if (cp == '\t') cp = 0x00BB;

		if (!registered_codepoints.contains(cp))
		{
			String script_font = find_script_font_for_codepoint(cp);
			if (script_font.len > 0)
			{
				bool already = false;
				foreach (p : cached_fallback_paths)
				{
					if (p == script_font) { already = true; break; }
				}
				if (!already) cached_fallback_paths.push(script_font.copy(mem));
			}

			if (add_codepoint(cp))
			{
				load_ttf_at_pixel_size(current_loaded_size);
			}
		}

		float font_size = (float)current_loaded_size;
		float ratio     = (float)current_loaded_size / (float)FONT_SIZE;
		int draw_y      = py + (int)math::round((float)VERTICAL_OFFSET * ratio);

		if (font_has_glyph(ttf_font, cp))
		{
			rl::draw_text_codepoint(ttf_font, cp, { (float)px, (float)draw_y }, font_size, rl_tint);
			return;
		}

		foreach (&fb_font : fallback_fonts)
		{
			if (font_has_glyph(*fb_font, cp))
			{
				rl::draw_text_codepoint(*fb_font, cp, { (float)px, (float)draw_y }, font_size, rl_tint);
				return;
			}
		}

		rl::draw_text_codepoint(ttf_font, cp, { (float)px, (float)draw_y }, font_size, rl_tint);
		return;
	}

	int idx = get_glyph_atlas_index(c);
	if (idx < 0 || idx >= 256) idx = 0;

	int gx = (idx % 16) * 8;
	int gy = (idx / 16) * 8;

	RLRectangle src = { (float)gx, (float)gy, (float)GLYPH_WIDTH_CELLS, (float)GLYPH_HEIGHT_CELLS };
	RLRectangle dst = { (float)px, (float)py, (float)GLYPH_WIDTH_CELLS * scale, (float)GLYPH_HEIGHT_CELLS * scale };
	rl::draw_texture_pro(font_texture, src, dst, { 0, 0 }, 0.0f, rl_tint);
}

fn void draw_tab_guide(int px, int py, int tab_spaces, int char_width, float scale, Color tint)
{
	for (int i = 0; i < tab_spaces - 1; i++)
	{
		draw_char('-', px + i * char_width, py, scale, tint);
	}
	int arrow_x = px + (tab_spaces - 1) * char_width;
	draw_char(0x2192, arrow_x, py, scale, tint);
}

fn void draw_text(String str, int px, int py, float scale, Color tint)
{
	int advance         = get_char_width(scale);
	int cur_x           = px;
	StringIterator iter = str.iterator();
	while (try Char32 c = iter.next())
	{
		draw_char(c, cur_x, py, scale, tint);
		cur_x += advance;
	}
}module c3ed::ui;
import std, c3ed;

struct TextInputWidget
{
	char[256] buffer;
	int length;
	int cursor_pos;
	int scroll_col;
}

fn int prev_utf8_char_idx(char* buf, int pos) @inline @private
{
	if (pos <= 0) return 0;
	int prev = pos - 1;
	while (prev > 0 && (buf[prev] & 0xC0) == 0x80) prev--;
	return prev;
}

fn int next_utf8_char_idx(char* buf, int pos, int max_len) @inline @private
{
	if (pos >= max_len) return max_len;
	int next = pos + 1;
	while (next < max_len && (buf[next] & 0xC0) == 0x80) next++;
	return next;
}

fn void TextInputWidget.clear(&self)
{
	self.length = 0;
	self.cursor_pos = 0;
	self.scroll_col = 0;
	self.buffer[0] = '\0';
}

fn void TextInputWidget.set_text(&self, String str)
{
	self.clear();
	sz copy_len = math::min(str.len, (sz)254);
	if (copy_len > 0)
	{
		self.buffer[:copy_len] = str[:copy_len];
	}
	self.length = (int)copy_len;
	self.cursor_pos = self.length;
	self.scroll_col = 0;
	self.buffer[self.length] = '\0';
}

fn String TextInputWidget.view(&self) => (String)self.buffer[:self.length];

fn void TextInputWidget.ensure_cursor_visible(&self, int max_visible_cols)
{
	int cursor_col = (int)conv::utf8_codepoints(self.view()[:self.cursor_pos]);
	if (cursor_col < self.scroll_col)
	{
		self.scroll_col = cursor_col;
	}
	if (cursor_col >= self.scroll_col + max_visible_cols)
	{
		self.scroll_col = cursor_col - max_visible_cols + 1;
	}
	if (self.scroll_col < 0) self.scroll_col = 0;
}

fn bool TextInputWidget.insert_codepoint(&self, Char32 cp)
{
	char[4] buf;
	sz len = conv::char32_to_utf8(cp, &buf) ?? 0;
	if (len == 0 || self.length + (int)len >= 255) return false;

	int ins_len = (int)len;
	int remaining = self.length - self.cursor_pos;
	if (remaining > 0)
	{
		mem::move(&self.buffer[self.cursor_pos + ins_len], &self.buffer[self.cursor_pos], (sz)remaining);
	}
	self.buffer[self.cursor_pos:len] = buf[:len];
	self.length += ins_len;
	self.cursor_pos += ins_len;
	self.buffer[self.length] = '\0';
	return true;
}

fn bool TextInputWidget.insert_str(&self, String str)
{
	if (str.len == 0) return false;
	sz available = (sz)math::max(0, 254 - self.length);
	sz to_copy = math::min(str.len, available);
	if (to_copy == 0) return false;

	int ins_len = (int)to_copy;
	int remaining = self.length - self.cursor_pos;
	if (remaining > 0)
	{
		mem::move(&self.buffer[self.cursor_pos + ins_len], &self.buffer[self.cursor_pos], (sz)remaining);
	}
	self.buffer[self.cursor_pos:to_copy] = str[:to_copy];
	self.length += ins_len;
	self.cursor_pos += ins_len;
	self.buffer[self.length] = '\0';
	return true;
}

fn bool TextInputWidget.backspace(&self)
{
	if (self.cursor_pos <= 0) return false;

	int prev = prev_utf8_char_idx(&self.buffer, self.cursor_pos);
	int del_len = self.cursor_pos - prev;
	int remaining = self.length - self.cursor_pos;

	if (remaining > 0)
	{
		mem::move(&self.buffer[prev], &self.buffer[self.cursor_pos], (sz)remaining);
	}
	self.length -= del_len;
	self.cursor_pos = prev;
	self.buffer[self.length] = '\0';
	return true;
}

fn bool TextInputWidget.delete_word_left(&self)
{
	if (self.cursor_pos <= 0) return false;

	int p = prev_utf8_char_idx(&self.buffer, self.cursor_pos);

	while (p > 0)
	{
		int prev = prev_utf8_char_idx(&self.buffer, p);
		char c = self.buffer[prev];
		if (c == ' ' || c == '\t' || c == '/' || c == '\\' || c == '-' || c == '_' || c == '.' || c == ':')
		{
			p = prev;
		}
		else
		{
			break;
		}
	}

	while (p > 0)
	{
		int prev = prev_utf8_char_idx(&self.buffer, p);
		char c = self.buffer[prev];
		if (c.is_alnum() || (c & 0x80) != 0)
		{
			p = prev;
		}
		else
		{
			break;
		}
	}

	if (p == self.cursor_pos && p > 0)
	{
		p = prev_utf8_char_idx(&self.buffer, p);
	}

	int del_len = self.cursor_pos - p;
	if (del_len <= 0) return false;

	int remaining = self.length - self.cursor_pos;
	if (remaining > 0)
	{
		mem::move(&self.buffer[p], &self.buffer[self.cursor_pos], (sz)remaining);
	}
	self.length -= del_len;
	self.cursor_pos = p;
	self.buffer[self.length] = '\0';
	return true;
}

fn bool TextInputWidget.delete(&self)
{
	if (self.cursor_pos >= self.length) return false;

	int next = next_utf8_char_idx(&self.buffer, self.cursor_pos, self.length);
	int del_len = next - self.cursor_pos;
	int remaining = self.length - next;

	if (remaining > 0)
	{
		mem::move(&self.buffer[self.cursor_pos], &self.buffer[next], (sz)remaining);
	}
	self.length -= del_len;
	self.buffer[self.length] = '\0';
	return true;
}

struct ListPickerWidget<ItemType>
{
	List{ItemType} items;
	int selected_index;
	int scroll_offset;
	int visible_rows;
}

fn void ListPickerWidget.init(&self, Allocator allocator, int visible_rows = 10)
{
	self.items.init(allocator, 32);
	self.selected_index = 0;
	self.scroll_offset = 0;
	self.visible_rows = visible_rows;
}

fn void ListPickerWidget.ensure_visible(&self)
{
	int total = (int)self.items.len();
	if (total == 0)
	{
		self.selected_index = 0;
		self.scroll_offset = 0;
		return;
	}
	self.selected_index = math::clamp(self.selected_index, 0, total - 1);
	if (self.selected_index < self.scroll_offset)
	{
		self.scroll_offset = self.selected_index;
	}
	if (self.selected_index >= self.scroll_offset + self.visible_rows)
	{
		self.scroll_offset = self.selected_index - self.visible_rows + 1;
	}
	int max_offset = math::max(0, total - self.visible_rows);
	self.scroll_offset = math::clamp(self.scroll_offset, 0, max_offset);
}

fn void ListPickerWidget.select_next(&self)
{
	int total = (int)self.items.len();
	if (total == 0) return;
	if (self.selected_index + 1 < total)
	{
		self.selected_index++;
	}
	else
	{
		self.selected_index = 0;
		self.scroll_offset = 0;
	}
	self.ensure_visible();
}

fn void ListPickerWidget.select_prev(&self)
{
	int total = (int)self.items.len();
	if (total == 0) return;
	if (self.selected_index > 0)
	{
		self.selected_index--;
	}
	else
	{
		self.selected_index = total - 1;
	}
	self.ensure_visible();
}

fn void ListPickerWidget.page_up(&self)
{
	int total = (int)self.items.len();
	if (total == 0) return;
	int step = math::max(1, self.visible_rows);
	self.selected_index = math::max(0, self.selected_index - step);
	self.scroll_offset = math::max(0, self.scroll_offset - step);
	self.ensure_visible();
}

fn void ListPickerWidget.page_down(&self)
{
	int total = (int)self.items.len();
	if (total == 0) return;
	int step = math::max(1, self.visible_rows);
	self.selected_index = math::min(total - 1, self.selected_index + step);
	self.scroll_offset = math::min(math::max(0, total - self.visible_rows), self.scroll_offset + step);
	self.ensure_visible();
}

fn void ListPickerWidget.clamp_view(&self, int visible_rows)
{
	self.visible_rows = math::max(1, visible_rows);
	self.ensure_visible();
}

struct LayoutMetrics
{
	float font_scale;
	int char_width;
	int char_height;
	int line_height;

	int screen_w;
	int screen_h;

	int tab_bar_height;
	int footer_height;
	int terminal_height;
	int gutter_width;
	int text_start_x;
	int text_start_y;

	int editor_w;
	int editor_h;
	int visible_lines;
	int visible_cols;

	int minimap_w;
	int minimap_x;

	Rect tab_bar_rect;
	Rect gutter_rect;
	Rect editor_rect;
	Rect footer_rect;
	Rect scrollbar_rect;
	Rect minimap_rect;
	Rect terminal_rect;
}

fn int get_digits_count(int n) @private
{
	if (n <= 0) return 1;
	int count = 0;
	while (n > 0)
	{
		count++;
		n /= 10;
	}
	return count;
}

fn LayoutMetrics compute_layout(
	int screen_w,
	int screen_h,
	float font_scale,
	int total_lines,
	bool show_tab_bar = true,
	bool terminal_open = false,
	int terminal_h = config::LAYOUT_METRICS.terminal_default_h
)
{
	LayoutMetrics lm;
	lm.font_scale = math::clamp(font_scale, config::LAYOUT_METRICS.min_font_scale, config::LAYOUT_METRICS.max_font_scale);
	font::ensure_font_scale(lm.font_scale);

	lm.char_width = font::get_char_width(lm.font_scale);
	lm.char_height = font::get_char_height(lm.font_scale);
	lm.line_height = font::get_line_height(lm.font_scale);

	lm.screen_w = screen_w;
	lm.screen_h = screen_h;

	int tab_bar_padding_y = math::max(4, (int)math::round(6.0f * lm.font_scale));
	int footer_padding_y  = math::max(4, (int)math::round(5.0f * lm.font_scale));
	lm.tab_bar_height = show_tab_bar ? (lm.char_height + tab_bar_padding_y * 2) : 0;
	lm.footer_height = lm.char_height + footer_padding_y * 2;
	lm.terminal_height = terminal_open ? math::clamp(terminal_h, config::LAYOUT_METRICS.terminal_min_h, screen_h / 2) : 0;

	int digits = math::max(config::LAYOUT_METRICS.gutter_min_digits, get_digits_count(total_lines));
	lm.gutter_width = digits * lm.char_width + config::LAYOUT_METRICS.gutter_padding_right + config::LAYOUT_METRICS.gutter_border_w + config::LAYOUT_METRICS.gutter_base_margin;
	lm.text_start_x = lm.gutter_width + config::LAYOUT_METRICS.text_padding_x;
	lm.text_start_y = lm.tab_bar_height + config::LAYOUT_METRICS.text_padding_y;

	lm.minimap_w = config::settings.show_minimap ? config::settings.minimap_width : 0;
	lm.minimap_x = screen_w - lm.minimap_w - config::LAYOUT_METRICS.minimap_margin_right;

	lm.editor_w = screen_w - lm.text_start_x - lm.minimap_w - 18;
	lm.editor_h = screen_h - lm.tab_bar_height - lm.footer_height - lm.terminal_height;

	lm.visible_lines = math::max(1, (lm.editor_h - config::LAYOUT_METRICS.text_padding_y * 2) / lm.line_height);
	lm.visible_cols = math::max(1, (lm.editor_w - config::LAYOUT_METRICS.text_padding_x) / lm.char_width);

	lm.tab_bar_rect   = { 0, 0, (float)screen_w, (float)lm.tab_bar_height };
	lm.gutter_rect    = { 0, (float)lm.tab_bar_height, (float)(lm.gutter_width - config::LAYOUT_METRICS.gutter_border_w), (float)lm.editor_h };
	lm.editor_rect    = { (float)lm.text_start_x, (float)lm.text_start_y, (float)lm.editor_w, (float)(lm.editor_h - config::LAYOUT_METRICS.text_padding_y * 2) };
	lm.scrollbar_rect = { (float)(screen_w - config::LAYOUT_METRICS.scrollbar_w - 2), (float)lm.tab_bar_height, (float)config::LAYOUT_METRICS.scrollbar_w, (float)lm.editor_h };
	lm.minimap_rect   = { (float)lm.minimap_x, (float)lm.tab_bar_height, (float)lm.minimap_w, (float)lm.editor_h };
	lm.terminal_rect  = { 0, (float)(screen_h - lm.footer_height - lm.terminal_height), (float)screen_w, (float)lm.terminal_height };
	lm.footer_rect    = { 0, (float)(screen_h - lm.footer_height), (float)screen_w, (float)lm.footer_height };

	return lm;
}

fn void render_modal(Editor* ed, int screen_w, int height, LayoutMetrics* lm)
{
	String prompt   = ed.get_modal_prompt();
	Rect mrect      = ed.get_modal_rect(lm, screen_w, height);
	int modal_x     = (int)mrect.x;
	int modal_y     = (int)mrect.y;
	int modal_w     = (int)mrect.width;
	int modal_h     = (int)mrect.height;
	int input_box_h = math::max(config::LAYOUT_METRICS.modal_input_box_h_min, lm.char_height + config::LAYOUT_METRICS.modal_input_box_padding);

	gfx::draw_rect(modal_x - 4, modal_y - 4, modal_w + 8, modal_h + 8, config::theme.gutter_border);
	gfx::draw_rect(modal_x, modal_y, modal_w, modal_h, config::theme.header_bg);

	int prompt_y = modal_y + config::LAYOUT_METRICS.modal_padding_y;

	if (ed.modal.kind == FIND || ed.modal.kind == REPLACE)
	{
		Rect toggle_rect = ed.get_case_toggle_rect(lm, screen_w, height);
		Vec2 mouse_v = gfx::get_mouse_pos();
		bool is_hover = mouse_v.x >= toggle_rect.x && mouse_v.x <= toggle_rect.x + toggle_rect.width
			&& mouse_v.y >= toggle_rect.y && mouse_v.y <= toggle_rect.y + toggle_rect.height;

		if (is_hover)
		{
			gfx::draw_rect((int)toggle_rect.x, (int)toggle_rect.y, (int)toggle_rect.width, (int)toggle_rect.height, config::theme.selection_bg);
			gfx::draw_rect_lines((int)toggle_rect.x, (int)toggle_rect.y, (int)toggle_rect.width, (int)toggle_rect.height, config::theme.accent_blue);
		}
	}

	font::draw_text(prompt, modal_x + config::LAYOUT_METRICS.modal_padding_x, prompt_y, lm.font_scale, config::theme.accent_blue);

	if (ed.modal.kind == CONFIRM_EXIT || ed.modal.kind == CONFIRM_CLOSE_TAB || ed.modal.kind == CONFIRM_DISK_RELOAD)
	{
		Vec2 mouse_v = gfx::get_mouse_pos();

		int btn_w = (modal_w - 32 - 24) / 3;
		int btn_h = input_box_h;
		int btn_y = modal_y + 14 + lm.char_height + 12;

		int btn1_x = modal_x + 16;
		int btn2_x = btn1_x + btn_w + 12;
		int btn3_x = btn2_x + btn_w + 12;

		bool hover1 = mouse_v.x >= (float)btn1_x && mouse_v.x < (float)(btn1_x + btn_w) && mouse_v.y >= (float)btn_y && mouse_v.y < (float)(btn_y + btn_h);
		bool hover2 = mouse_v.x >= (float)btn2_x && mouse_v.x < (float)(btn2_x + btn_w) && mouse_v.y >= (float)btn_y && mouse_v.y < (float)(btn_y + btn_h);
		bool hover3 = mouse_v.x >= (float)btn3_x && mouse_v.x < (float)(btn3_x + btn_w) && mouse_v.y >= (float)btn_y && mouse_v.y < (float)(btn_y + btn_h);

		gfx::draw_rect(btn1_x, btn_y, btn_w, btn_h, hover1 ? config::theme.accent_green : config::theme.bg);
		gfx::draw_rect_lines(btn1_x, btn_y, btn_w, btn_h, config::theme.accent_green);
		String b1_str = "[Y] Yes";
		font::draw_text(b1_str, btn1_x + (btn_w - (int)b1_str.len * lm.char_width) / 2, btn_y + (btn_h - lm.char_height) / 2, lm.font_scale, hover1 ? config::theme.bg : config::theme.accent_green);

		gfx::draw_rect(btn2_x, btn_y, btn_w, btn_h, hover2 ? config::theme.accent_red : config::theme.bg);
		gfx::draw_rect_lines(btn2_x, btn_y, btn_w, btn_h, hover2 ? config::theme.accent_red : config::theme.gutter_border);
		String b2_str = "[N] No";
		font::draw_text(b2_str, btn2_x + (btn_w - (int)b2_str.len * lm.char_width) / 2, btn_y + (btn_h - lm.char_height) / 2, lm.font_scale, hover2 ? config::theme.bg : config::theme.accent_red);

		gfx::draw_rect(btn3_x, btn_y, btn_w, btn_h, hover3 ? config::theme.selection_bg : config::theme.bg);
		gfx::draw_rect_lines(btn3_x, btn_y, btn_w, btn_h, hover3 ? config::theme.accent_blue : config::theme.gutter_border);
		String b3_str = "[Esc] Cancel";
		font::draw_text(b3_str, btn3_x + (btn_w - (int)b3_str.len * lm.char_width) / 2, btn_y + (btn_h - lm.char_height) / 2, lm.font_scale, hover3 ? config::theme.text_bright : config::theme.text_muted);
	}
	else if (ed.modal.kind == REPLACE)
	{
		int input_w  = modal_w - 32;
		int input1_y = modal_y + 14 + lm.char_height + 6;
		int input2_y = input1_y + input_box_h + 10;
		int max_vis_chars = math::max(1, (input_w - 16) / lm.char_width);

		ed.modal.input.ensure_cursor_visible(max_vis_chars);
		ed.modal.replace_input.ensure_cursor_visible(max_vis_chars);

		gfx::draw_rect(modal_x + 16, input1_y, input_w, input_box_h, config::theme.bg);
		Color border1_col = (ed.modal.focus_field == 0) ? config::theme.accent_blue : config::theme.gutter_border;
		gfx::draw_rect_lines(modal_x + 16, input1_y, input_w, input_box_h, border1_col);

		gfx::begin_scissor(modal_x + 18, input1_y, input_w - 4, input_box_h);
		int text_draw1_y = input1_y + (input_box_h - lm.char_height) / 2;
		int text_draw1_x = modal_x + 24 - ed.modal.input.scroll_col * lm.char_width;
		font::draw_text(ed.modal.input.view(), text_draw1_x, text_draw1_y, lm.font_scale, config::theme.text_bright);
		if (ed.modal.focus_field == 0 && ed.cursor_visible)
		{
			int cursor_col = (int)conv::utf8_codepoints(ed.modal.input.view()[:ed.modal.input.cursor_pos]);
			int cur_x = modal_x + 24 + (cursor_col - ed.modal.input.scroll_col) * lm.char_width;
			gfx::draw_rect(cur_x, text_draw1_y, 2, lm.char_height, config::theme.cursor);
		}
		gfx::end_scissor();

		gfx::draw_rect(modal_x + 16, input2_y, input_w, input_box_h, config::theme.bg);
		Color border2_col = (ed.modal.focus_field == 1) ? config::theme.accent_blue : config::theme.gutter_border;
		gfx::draw_rect_lines(modal_x + 16, input2_y, input_w, input_box_h, border2_col);

		gfx::begin_scissor(modal_x + 18, input2_y, input_w - 4, input_box_h);
		int text_draw2_y = input2_y + (input_box_h - lm.char_height) / 2;
		int text_draw2_x = modal_x + 24 - ed.modal.replace_input.scroll_col * lm.char_width;
		font::draw_text(ed.modal.replace_input.view(), text_draw2_x, text_draw2_y, lm.font_scale, config::theme.text_bright);
		if (ed.modal.focus_field == 1 && ed.cursor_visible)
		{
			int cursor_col = (int)conv::utf8_codepoints(ed.modal.replace_input.view()[:ed.modal.replace_input.cursor_pos]);
			int cur_x = modal_x + 24 + (cursor_col - ed.modal.replace_input.scroll_col) * lm.char_width;
			gfx::draw_rect(cur_x, text_draw2_y, 2, lm.char_height, config::theme.cursor);
		}
		gfx::end_scissor();
	}
	else
	{
		int input_y = modal_y + 14 + lm.char_height + 8;
		int input_w = modal_w - 32;
		int max_vis_chars = math::max(1, (input_w - 16) / lm.char_width);

		ed.modal.input.ensure_cursor_visible(max_vis_chars);

		gfx::draw_rect(modal_x + 16, input_y, input_w, input_box_h, config::theme.bg);
		gfx::draw_rect_lines(modal_x + 16, input_y, input_w, input_box_h, config::theme.gutter_border);

		gfx::begin_scissor(modal_x + 18, input_y, input_w - 4, input_box_h);
		int text_draw_y = input_y + (input_box_h - lm.char_height) / 2;
		int text_draw_x = modal_x + 24 - ed.modal.input.scroll_col * lm.char_width;
		font::draw_text(ed.modal.input.view(), text_draw_x, text_draw_y, lm.font_scale, config::theme.text_bright);

		if (ed.cursor_visible)
		{
			int cursor_col = (int)conv::utf8_codepoints(ed.modal.input.view()[:ed.modal.input.cursor_pos]);
			int cur_x = modal_x + 24 + (cursor_col - ed.modal.input.scroll_col) * lm.char_width;
			gfx::draw_rect(cur_x, text_draw_y, 2, lm.char_height, config::theme.cursor);
		}
		gfx::end_scissor();

		if (ed.modal.kind == QUICK_OPEN || ed.modal.kind == GLOBAL_GREP || ed.modal.kind == SYMBOL_OUTLINE)
		{
			int list_y   = input_y + input_box_h + 10;
			int list_h   = modal_y + modal_h - list_y - config::LAYOUT_METRICS.modal_padding_y;
			int row_h    = math::max(config::LAYOUT_METRICS.modal_row_h_min, lm.line_height);
			int max_rows = math::max(1, list_h / row_h);
			ed.modal.picker.clamp_view(max_rows);

			gfx::draw_rect(modal_x + config::LAYOUT_METRICS.modal_padding_x, list_y, input_w, list_h, config::theme.bg);
			gfx::draw_rect_lines(modal_x + config::LAYOUT_METRICS.modal_padding_x, list_y, input_w, list_h, config::theme.gutter_border);
			gfx::begin_scissor(modal_x + config::LAYOUT_METRICS.modal_padding_x, list_y, input_w, list_h);

			for (int r = 0; r < max_rows; r++)
			{
				int idx = r + ed.modal.picker.scroll_offset;
				if (idx >= (int)ed.modal.picker.items.len()) break;
				int ry = list_y + r * row_h + 2;
				bool is_selected = (idx == ed.modal.picker.selected_index);
				if (is_selected)
				{
					gfx::draw_rect(modal_x + 18, ry - 1, input_w - 4, row_h - 2, config::theme.selection_bg);
				}

				PickerItem item = ed.modal.picker.items[(sz)idx];
				Color text_col = is_selected ? config::theme.text_bright : config::theme.text;
				int draw_text_y = ry + (row_h - lm.char_height) / 2;

				if (item.detail.len > 0)
				{
					font::draw_text(item.detail, modal_x + 24, draw_text_y, lm.font_scale, config::theme.accent_blue);
					int offset_x = (int)(item.detail.len + 1) * lm.char_width;
					font::draw_text(item.label, modal_x + 24 + offset_x, draw_text_y, lm.font_scale, text_col);
				}
				else
				{
					font::draw_text(item.label, modal_x + 24, draw_text_y, lm.font_scale, text_col);
				}
			}
			gfx::end_scissor();
		}
	}
}

struct MatchByteInfo
{
	bool is_match;
	bool is_start;
	bool is_end;
}

fn void render(Editor* ed, int screen_w, int height, LayoutMetrics* lm)
{
	Tab* tab = ed.active_tab();
	Document* doc = &tab.doc;

	gfx::begin_frame();
	gfx::clear_background(config::theme.bg);

	// Tab Bar
	gfx::draw_rect(0, 0, screen_w, lm.tab_bar_height, config::theme.tab_bg);
	gfx::draw_rect(0, lm.tab_bar_height - 1, screen_w, 1, config::theme.tab_border);

	int tab_x       = 0;
	int tab_h       = lm.tab_bar_height;
	int close_box_w = lm.char_width * 2 + 10;

	for (sz i = 0; i < ed.tabs.len(); i++)
	{
		Tab* t = &ed.tabs[i];
		bool is_active = ((int)i == ed.active_tab_index);

		String name_str = t.doc.filepath.file_tbasename() ?? t.doc.filepath;
		if (name_str.len == 0) name_str = "untitled.c3";

		String tab_title = string::tformat("%d: %s%s", i + 1, name_str, t.doc.is_modified ? " *" : "");
		int title_w      = (int)tab_title.len * lm.char_width;
		int tab_w        = title_w + close_box_w + config::LAYOUT_METRICS.tab_extra_padding;

		if (tab_x + tab_w > screen_w - config::LAYOUT_METRICS.tab_min_w_gap)
		{
			tab_w = screen_w - config::LAYOUT_METRICS.tab_min_w_gap - tab_x;
		}
		if (tab_w <= close_box_w + 10) break;

		Color bg_col = is_active ? config::theme.tab_active_bg : config::theme.tab_bg;
		gfx::draw_rect(tab_x, 0, tab_w, tab_h, bg_col);
		gfx::draw_rect(tab_x + tab_w - 1, 0, 1, tab_h, config::theme.tab_border);

		if (is_active)
		{
			gfx::draw_rect(tab_x, 0, tab_w, 2, config::theme.accent_blue);
		}

		Color txt_col = is_active ? config::theme.text_bright : config::theme.text_muted;
		int txt_y     = (tab_h - lm.char_height) / 2;

		int label_w = tab_w - close_box_w - 8;
		if (label_w > 0)
		{
			gfx::begin_scissor(tab_x + 8, 0, label_w, tab_h);
			font::draw_text(tab_title, tab_x + 8, txt_y, lm.font_scale, txt_col);
			gfx::end_scissor();
		}

		int close_x   = tab_x + tab_w - close_box_w;
		int x_glyph_x = close_x + (close_box_w - lm.char_width) / 2;
		font::draw_char('x', x_glyph_x, txt_y, lm.font_scale, is_active ? config::theme.text : config::theme.text_muted);

		tab_x += tab_w;
	}

	// Gutter and Git Diffs
	gfx::draw_rect(0, lm.tab_bar_height, lm.gutter_width - config::LAYOUT_METRICS.gutter_border_w, lm.editor_h, config::theme.gutter_bg);
	gfx::draw_rect(lm.gutter_width - config::LAYOUT_METRICS.gutter_border_w, lm.tab_bar_height, config::LAYOUT_METRICS.gutter_border_w, lm.editor_h, config::theme.gutter_border);

	Cursor* primary = doc.primary_cursor();
	LineCol cur_lc  = doc.get_line_col(primary.pos);
	int cline       = cur_lc.line;
	int ccol        = cur_lc.col;

	for (int l = 0; l < lm.visible_lines; l++)
	{
		int line_idx = l + tab.scroll_line;
		if (line_idx >= doc.get_total_lines()) break;

		int gy = lm.text_start_y + l * lm.line_height;

		if (config::settings.show_git_gutter)
		{
			GitLineStatus st = ed.workspace.git.get_status(line_idx);
			int gx = lm.gutter_width - config::LAYOUT_METRICS.gutter_border_w - 5;
			switch (st)
			{
				case ADDED:
					gfx::draw_rect(gx, gy, 3, lm.line_height, config::theme.git_added);
				case MODIFIED:
					gfx::draw_rect(gx, gy, 3, lm.line_height, config::theme.git_modified);
				case DELETED:
					gfx::draw_triangle(
						{ (float)gx, (float)gy },
						{ (float)gx, (float)gy + 6.0f },
						{ (float)(gx + 5), (float)gy + 3.0f },
						config::theme.git_deleted
					);
				default: break;
			}
		}

		Color gcol = (line_idx == cline) ? config::theme.accent_blue : config::theme.text_muted;
		char[32] gbuf;
		String gs    = string::bformat(&gbuf, "%d", line_idx + 1);
		int text_w   = (int)gs.len * lm.char_width;
		int draw_x   = lm.gutter_width - config::LAYOUT_METRICS.gutter_border_w - 8 - text_w - 6;
		font::draw_text(gs, draw_x, gy, lm.font_scale, gcol);
	}

	// Editor Text Canvas
	gfx::begin_scissor(lm.text_start_x, lm.text_start_y, lm.editor_w, lm.editor_h - 12);

	foreach (&cur : doc.cursors)
	{
		int active_rel_line = doc.get_line(cur.pos) - tab.scroll_line;
		if (active_rel_line >= 0 && active_rel_line < lm.visible_lines)
		{
			int hl_y = lm.text_start_y + active_rel_line * lm.line_height;
			gfx::draw_rect(lm.text_start_x - 8, hl_y, lm.editor_w + 8, lm.line_height, config::theme.line_highlight);
		}
	}

	int start_line = math::clamp(tab.scroll_line, 0, math::max(0, doc.get_total_lines() - 1));
	int end_line   = math::min(doc.get_total_lines(), start_line + lm.visible_lines + 1);

	// Indentation Guides
	if (config::settings.show_indent_guides)
	{
		int guide_start_l = math::max(0, start_line - 64);
		int guide_end_l   = math::min(doc.get_total_lines(), end_line + 64);

		for (int l = guide_start_l; l < guide_end_l; l++)
		{
			BytePos ls = doc.get_line_start_of_line(l);
			BytePos le = doc.get_line_end(ls);
			if (ls >= le) continue;

			String l_str = doc.table.get_slice(ls, le, tmem);
			sz first_non_ws = 0;
			while (first_non_ws < l_str.len && (l_str[first_non_ws] == ' ' || l_str[first_non_ws] == '\t')) first_non_ws++;
			int scope_col = doc.get_col(ls + first_non_ws);

			for (sz p = 0; p < l_str.len; p++)
			{
				if (l_str[p] == '{')
				{
					int depth = 1;
					BytePos close_pos = 0;
					BytePos max_scan = math::min(doc.table.len(), ls + p + 16384);
					for (BytePos cp = ls + p + 1; cp < max_scan; cp = c3ed::get_next_char_pos(&doc.table, cp))
					{
						char ch = doc.table.char_at(cp);
						if (ch == '{')
						{
							depth++;
						}
						else if (ch == '}')
						{
							depth--;
							if (depth == 0)
							{
								close_pos = cp;
								break;
							}
						}
					}
					if (close_pos > 0)
					{
						int l_close = doc.get_line(close_pos);
						if (l_close > l)
						{
							int sx = lm.text_start_x + (scope_col - tab.scroll_col) * lm.char_width + (lm.char_width / 2);
							int top_l = math::max(l + 1, start_line);
							int bot_l = math::min(l_close, end_line);

							if (bot_l >= top_l)
							{
								int sy_start = lm.text_start_y + (top_l - tab.scroll_line) * lm.line_height;
								int sy_end   = lm.text_start_y + (bot_l - tab.scroll_line) * lm.line_height;
								bool is_active_scope = (cline >= l && cline <= l_close);
								Color scol = is_active_scope ? config::theme.indent_guide_active : config::theme.indent_guide;
								gfx::draw_line(sx, sy_start, sx, sy_end, scol);
							}
						}
					}
				}
			}
		}
	}

	TokenType[1024] token_scratch;
	MatchByteInfo[1024] match_info;

	bool has_search_query = (ed.modal.kind == FIND || ed.modal.kind == REPLACE) && ed.modal.input.length > 0;
	String search_query = has_search_query ? ed.modal.input.view() : "";

	for (int l = start_line; l < end_line; l++)
	{
		int rel_line = l - tab.scroll_line;
		if (rel_line < 0 || rel_line >= lm.visible_lines) continue;

		BytePos ls = doc.get_line_start_of_line(l);
		BytePos le = doc.get_line_end(ls);
		String line_str = doc.table.get_slice(ls, le, tmem);

		LineState start_state = (l == 0) ? NORMAL
			: ((sz)l - 1 < doc.line_states.len() ? doc.line_states[(sz)l - 1] : NORMAL);

		TokenType[] line_tokens = (line_str.len <= 1024) ? token_scratch[:line_str.len]
			: alloc::alloc_array(tmem, TokenType, line_str.len);

		syntax::lex_slice(line_str, start_state, line_tokens);

		sz max_track = math::min(line_str.len + 1, (sz)1024);
		mem::clear(&match_info, max_track * MatchByteInfo::size);

		if (has_search_query && search_query.len > 0 && line_str.len >= search_query.len)
		{
			sz qlen = search_query.len;
			sz scan_idx = 0;
			while (scan_idx + qlen <= line_str.len)
			{
				bool is_match = ed.modal.search_case_sensitive
					? (line_str[scan_idx:qlen] == search_query)
					: (line_str[scan_idx:qlen].to_lower_tcopy() == search_query.to_lower_tcopy());

				if (is_match)
				{
					sz end_m = math::min(scan_idx + qlen, (sz)1024);
					for (sz m = scan_idx; m < end_m; m++)
					{
						match_info[m].is_match = true;
					}
					if (scan_idx < 1024) match_info[scan_idx].is_start = true;
					if (end_m > 0 && end_m <= 1024) match_info[end_m - 1].is_end = true;
					scan_idx += qlen;
				}
				else
				{
					scan_idx++;
				}
			}
		}

		int py = lm.text_start_y + rel_line * lm.line_height;
		int cur_col = 0;
		sz p = 0;

		while (p < line_str.len)
		{
			char c = line_str[p];
			int rel_col = cur_col - tab.scroll_col;
			int px = lm.text_start_x + rel_col * lm.char_width;

			BytePos global_p = ls + p;
			sz char_bytes = 1;
			while (p + char_bytes < line_str.len && (line_str[p + char_bytes] & 0xC0) == 0x80) char_bytes++;
			BytePos global_next_p = global_p + char_bytes;

			bool is_selected = false;
			foreach (&cur : doc.cursors)
			{
				if (cur.has_selection() && global_p < cur.sel_end() && global_next_p > cur.sel_start())
				{
					is_selected = true;
					break;
				}
			}

			bool is_search_match = (p < 1024 && match_info[p].is_match);
			bool is_match_start  = (p < 1024 && match_info[p].is_start);
			bool is_match_end    = (p + char_bytes - 1 < 1024 && match_info[p + char_bytes - 1].is_end);
			TokenType tok_type   = line_tokens[p];

			switch (c)
			{
				case '\r':
					p++;
				case '\t':
					int tab_spaces = config::settings.tab_size - (cur_col % config::settings.tab_size);
					int tab_w = lm.char_width * tab_spaces;
					if (px + tab_w >= lm.text_start_x && px < screen_w)
					{
						if (is_selected)
						{
							gfx::draw_rect(px, py, tab_w, lm.line_height, config::theme.selection_bg);
						}
						else if (is_search_match)
						{
							Color match_bg     = { 250, 204, 21, 95 };
							Color match_border = { 250, 204, 21, 200 };
							gfx::draw_rect(px, py, tab_w, lm.line_height, match_bg);
							gfx::draw_line(px, py, px + tab_w, py, match_border);
							gfx::draw_line(px, py + lm.line_height - 1, px + tab_w, py + lm.line_height - 1, match_border);
							if (is_match_start) gfx::draw_line(px, py, px, py + lm.line_height, match_border);
							if (is_match_end)   gfx::draw_line(px + tab_w - 1, py, px + tab_w - 1, py + lm.line_height, match_border);
						}
						else
						{
							font::draw_tab_guide(px, py, tab_spaces, lm.char_width, lm.font_scale, config::theme.tab_guide);
						}
					}
					cur_col += tab_spaces;
					p++;
				default:
					Char32 codepoint = (Char32)c;
					if (char_bytes > 1)
					{
						sz read_len = char_bytes;
						codepoint = conv::utf8_to_char32(&line_str[p], &read_len) ?? (Char32)c;
					}

					if (px + lm.char_width >= lm.text_start_x && px < screen_w)
					{
						if (is_selected)
						{
							gfx::draw_rect(px, py, lm.char_width, lm.line_height, config::theme.selection_bg);
							font::draw_char(codepoint, px, py, lm.font_scale, config::theme.text_bright);
						}
						else if (is_search_match)
						{
							Color match_bg     = { 250, 204, 21, 95 };
							Color match_border = { 250, 204, 21, 200 };
							gfx::draw_rect(px, py, lm.char_width, lm.line_height, match_bg);
							gfx::draw_line(px, py, px + lm.char_width, py, match_border);
							gfx::draw_line(px, py + lm.line_height - 1, px + lm.char_width, py + lm.line_height - 1, match_border);

							if (is_match_start) gfx::draw_line(px, py, px, py + lm.line_height, match_border);
							if (is_match_end)   gfx::draw_line(px + lm.char_width - 1, py, px + lm.char_width - 1, py + lm.line_height, match_border);
							font::draw_char(codepoint, px, py, lm.font_scale, config::theme.text_bright);
						}
						else
						{
							font::draw_char(codepoint, px, py, lm.font_scale, tok_type.color);
						}
					}
					cur_col++;
					p += char_bytes;
			}
		}

		if (le < doc.table.len())
		{
			bool newline_selected = false;
			foreach (&cur : doc.cursors)
			{
				if (cur.has_selection() && le < cur.sel_end() && le >= cur.sel_start())
				{
					newline_selected = true;
					break;
				}
			}
			if (newline_selected)
			{
				int px = lm.text_start_x + (cur_col - tab.scroll_col) * lm.char_width;
				if (px >= lm.text_start_x && px < screen_w)
				{
					gfx::draw_rect(px, py, lm.char_width, lm.line_height, config::theme.selection_bg);
				}
			}
		}
	}

	// Diagnostic Squiggles
	for (int l = start_line; l < end_line; l++)
	{
		Diagnostic*? d_opt = ed.workspace.diagnostics.get_at(doc.filepath, l + 1);
		if (try d = d_opt)
		{
			if (d != null)
			{
				int sy = lm.text_start_y + (l - tab.scroll_line + 1) * lm.line_height - 2;
				int sx = lm.text_start_x + (d.col - 1 - tab.scroll_col) * lm.char_width;
				Color scol = (d.severity == ERROR) ? config::theme.squiggle_error : config::theme.squiggle_warn;

				for (int wx = sx; wx < sx + 30; wx += 4)
				{
					gfx::draw_line(wx, sy, wx + 2, sy - 2, scol);
					gfx::draw_line(wx + 2, sy - 2, wx + 4, sy, scol);
				}
			}
		}
	}

	// Render Cursors
	if (ed.cursor_visible && ed.modal.kind == NONE)
	{
		foreach (&cur : doc.cursors)
		{
			int cur_l        = doc.get_line(cur.pos);
			int cur_c        = doc.get_col(cur.pos);
			int active_rel_l = cur_l - tab.scroll_line;

			if (active_rel_l >= 0 && active_rel_l < lm.visible_lines)
			{
				int cx = lm.text_start_x + (cur_c - tab.scroll_col) * lm.char_width;
				int cy = lm.text_start_y + active_rel_l * lm.line_height;
				gfx::draw_rect(cx, cy, 2, lm.line_height, config::theme.cursor);
			}
		}
	}

	gfx::end_scissor();

	// Minimap
	if (config::settings.show_minimap && lm.minimap_w > 0)
	{
		int mm_y = lm.tab_bar_height;
		int mm_h = lm.editor_h;
		gfx::draw_rect(lm.minimap_x, mm_y, lm.minimap_w, mm_h, config::theme.minimap_bg);

		int total_doc_lines = doc.get_total_lines();
		int mm_line_h = config::LAYOUT_METRICS.minimap_line_h;
		int total_mm_h = total_doc_lines * mm_line_h;
		int max_editor_scroll = math::max(1, total_doc_lines - lm.visible_lines);
		float scroll_ratio = math::clamp((float)tab.scroll_line / (float)max_editor_scroll, 0.0f, 1.0f);

		int mm_scroll_y = 0;
		if (total_mm_h > mm_h)
		{
			mm_scroll_y = (int)(scroll_ratio * (float)(total_mm_h - mm_h));
		}

		int mm_start_l = mm_scroll_y / mm_line_h;
		int mm_end_l   = math::min(total_doc_lines, mm_start_l + (mm_h / mm_line_h) + 1);

		gfx::begin_scissor(lm.minimap_x, mm_y, lm.minimap_w, mm_h);

		for (int l = mm_start_l; l < mm_end_l; l++)
		{
			int my = mm_y + l * mm_line_h - mm_scroll_y;
			if (my < mm_y || my >= mm_y + mm_h) continue;

			if (config::settings.show_git_gutter)
			{
				GitLineStatus st = ed.workspace.git.get_status(l);
				switch (st)
				{
					case ADDED:
						gfx::draw_rect(lm.minimap_x, my, 3, mm_line_h, config::theme.git_added);
					case MODIFIED:
						gfx::draw_rect(lm.minimap_x, my, 3, mm_line_h, config::theme.git_modified);
					case DELETED:
						gfx::draw_rect(lm.minimap_x, my, 5, 2, config::theme.git_deleted);
					default: break;
				}
			}

			BytePos ls = doc.get_line_start_of_line(l);
			BytePos le = doc.get_line_end(ls);
			int line_len = (int)math::min((sz)lm.minimap_w - 6, (le - ls) / 2);
			if (line_len > 0)
			{
				gfx::draw_rect(lm.minimap_x + 4, my, line_len, mm_line_h, config::theme.text_muted);
			}
		}

		foreach (match_l : ed.modal.cached_match_lines)
		{
			int my = mm_y + match_l * mm_line_h - mm_scroll_y;
			if (my >= mm_y && my < mm_y + mm_h)
			{
				gfx::draw_rect(lm.minimap_x, my, lm.minimap_w, 2, config::theme.accent_yellow);
			}
		}

		int vp_y = mm_y + tab.scroll_line * mm_line_h - mm_scroll_y;
		int vp_h = math::max(config::LAYOUT_METRICS.minimap_min_thumb_h, lm.visible_lines * mm_line_h);
		vp_y = math::clamp(vp_y, mm_y, mm_y + mm_h - vp_h);

		gfx::draw_rect(lm.minimap_x, vp_y, lm.minimap_w, vp_h, config::theme.minimap_viewport);
		gfx::draw_rect_lines(lm.minimap_x, vp_y, lm.minimap_w, vp_h, config::theme.accent_blue);

		gfx::end_scissor();
	}

	// Scrollbar
	if (doc.get_total_lines() > lm.visible_lines)
	{
		int sb_w           = config::LAYOUT_METRICS.scrollbar_w;
		int sb_x           = screen_w - sb_w - 2;
		int sb_y           = lm.tab_bar_height;
		int sb_h           = lm.editor_h;
		float thumb_h      = math::max(config::LAYOUT_METRICS.scrollbar_min_thumb_h, (float)sb_h * (float)lm.visible_lines / (float)doc.get_total_lines());
		float max_scroll   = (float)(doc.get_total_lines() - lm.visible_lines);
		float scrollable_h = (float)sb_h - thumb_h;
		float thumb_y      = (float)sb_y + (scrollable_h * (float)tab.scroll_line / max_scroll);

		gfx::draw_rect(sb_x, sb_y, sb_w, sb_h, config::theme.header_bg);
		Color thumb_col = ed.scrollbar_dragging ? config::theme.scrollbar_act : config::theme.scrollbar;
		gfx::draw_rect(sb_x + 1, (int)thumb_y, sb_w - 2, (int)thumb_h, thumb_col);

		if (config::settings.show_git_gutter)
		{
			foreach (&hunk : ed.workspace.git.hunks)
			{
				int tick_y = sb_y + (int)(((float)hunk.line_start / (float)doc.get_total_lines()) * (float)sb_h);
				Color gcol = (hunk.status == ADDED)
					? config::theme.git_added
					: ((hunk.status == DELETED) ? config::theme.git_deleted : config::theme.git_modified);
				gfx::draw_rect(sb_x, tick_y, sb_w, 2, gcol);
			}
		}

		foreach (match_l : ed.modal.cached_match_lines)
		{
			int tick_y = sb_y + (int)(((float)match_l / (float)doc.get_total_lines()) * (float)sb_h);
			gfx::draw_rect(sb_x, tick_y, sb_w, 2, config::theme.accent_yellow);
		}

		foreach (&d : ed.workspace.diagnostics.items)
		{
			if (d.filepath.ends_with(doc.filepath) || doc.filepath.ends_with(d.filepath))
			{
				int tick_y = sb_y + (int)(((float)d.line / (float)doc.get_total_lines()) * (float)sb_h);
				Color tcol = (d.severity == ERROR) ? config::theme.accent_red : config::theme.accent_yellow;
				gfx::draw_rect(sb_x, tick_y, sb_w, 2, tcol);
			}
		}
	}

	// Autocomplete Popup
	if (ed.autocomplete.is_active && ed.autocomplete.items.len() > 0)
	{
		int pop_w = config::LAYOUT_METRICS.popup_w;
		int row_h = lm.char_height + 6;
		int pop_rows = math::min(config::LAYOUT_METRICS.popup_max_rows, (int)ed.autocomplete.items.len());
		int pop_h = pop_rows * row_h + 8;

		int pop_x = lm.text_start_x + (ccol - tab.scroll_col) * lm.char_width;
		int pop_y = lm.text_start_y + (cline - tab.scroll_line + 1) * lm.line_height;

		if (pop_x + pop_w > screen_w - 20) pop_x = screen_w - pop_w - 20;
		if (pop_y + pop_h > height - lm.footer_height) pop_y = pop_y - pop_h - lm.line_height;

		gfx::draw_rect(pop_x - 2, pop_y - 2, pop_w + 4, pop_h + 4, config::theme.popup_border);
		gfx::draw_rect(pop_x, pop_y, pop_w, pop_h, config::theme.popup_bg);

		for (int r = 0; r < pop_rows; r++)
		{
			int item_idx = r + ed.autocomplete.scroll_offset;
			if (item_idx >= (int)ed.autocomplete.items.len()) break;

			CompletionItem* it = &ed.autocomplete.items[(sz)item_idx];
			int ry = pop_y + 4 + r * row_h;

			if (item_idx == ed.autocomplete.selected_index)
			{
				gfx::draw_rect(pop_x + 2, ry, pop_w - 4, row_h, config::theme.popup_selected);
			}

			String kind_tag = "[v]";
			Color tag_col = config::theme.accent_yellow;
			switch (it.kind)
			{
				case FUNCTION:   kind_tag = "[fn]";     tag_col = config::theme.accent_blue;
				case STRUCT:     kind_tag = "[struct]"; tag_col = config::theme.accent_green;
				case UNION:      kind_tag = "[union]";  tag_col = config::theme.accent_green;
				case ENUM:       kind_tag = "[enum]";   tag_col = config::theme.accent_green;
				case BITSTRUCT:  kind_tag = "[bitst]";  tag_col = config::theme.accent_green;
				case MACRO:      kind_tag = "[macro]";  tag_col = config::theme.accent_red;
				case TYPE_ALIAS: kind_tag = "[type]";   tag_col = config::theme.accent_green;
				case CONSTANT:   kind_tag = "[const]";  tag_col = config::theme.accent_yellow;
				case FAULT:      kind_tag = "[fault]";  tag_col = config::theme.accent_red;
				case FIELD:      kind_tag = "[field]";  tag_col = config::theme.accent_blue;
				default:         kind_tag = "[var]";    tag_col = config::theme.text_muted;
			}

			font::draw_text(kind_tag, pop_x + 6, ry + 2, lm.font_scale, tag_col);
			font::draw_text(it.label, pop_x + 6 + 8 * lm.char_width, ry + 2, lm.font_scale, config::theme.text_bright);
		}
	}

	// Bottom Terminal Panel
	if (ed.terminal.is_open && lm.terminal_height > 0)
	{
		int ty = (int)lm.terminal_rect.y;
		int th = lm.terminal_height;

		gfx::draw_rect(0, ty, screen_w, th, config::theme.panel_bg);
		gfx::draw_rect(0, ty, screen_w, 2, config::theme.accent_blue);

		font::draw_text("[BUILD & RUN OUTPUT] (Ctrl+~ to toggle | Click+Drag to Copy)", 12, ty + 6, lm.font_scale, config::theme.accent_blue);

		gfx::begin_scissor(12, ty + lm.line_height + 4, screen_w - 24, th - lm.line_height - 8);
		int max_term_lines = (th - lm.line_height - 8) / lm.line_height;
		int total_tlines   = (int)ed.terminal.lines.len();
		int start_idx      = math::clamp(ed.terminal.scroll_line - max_term_lines + 1, 0, math::max(0, total_tlines - max_term_lines));

		for (int idx = start_idx; idx < total_tlines && idx < start_idx + max_term_lines; idx++)
		{
			int row_y = ty + lm.line_height + 8 + (idx - start_idx) * lm.line_height;
			String line_text = ed.terminal.lines[(sz)idx];

			if (ed.terminal.has_selection())
			{
				int s_line = math::min(ed.terminal.sel_start_line, ed.terminal.sel_end_line);
				int e_line = math::max(ed.terminal.sel_start_line, ed.terminal.sel_end_line);
				if (idx >= s_line && idx <= e_line)
				{
					int s_col = (idx == s_line) ? math::min(ed.terminal.sel_start_col, ed.terminal.sel_end_col) : 0;
					int e_col = (idx == e_line) ? math::max(ed.terminal.sel_start_col, ed.terminal.sel_end_col) : (int)line_text.len;
					int hl_x  = 14 + s_col * lm.char_width;
					int hl_w  = math::max(1, (e_col - s_col)) * lm.char_width;
					gfx::draw_rect(hl_x, row_y, hl_w, lm.line_height, config::theme.selection_bg);
				}
			}

			Color tcol = config::theme.text;
			if (line_text.contains("Error") || line_text.contains("error"))
			{
				tcol = config::theme.accent_red;
			}
			else if (line_text.contains("Warning") || line_text.contains("warning"))
			{
				tcol = config::theme.accent_yellow;
			}
			font::draw_text(line_text, 14, row_y, lm.font_scale, tcol);
		}
		gfx::end_scissor();
	}

	// Modals
	if (ed.modal.kind != NONE)
	{
		render_modal(ed, screen_w, height, lm);
	}

	int footer_y      = (int)lm.footer_rect.y;
	int footer_text_y = footer_y + (lm.footer_height - lm.char_height) / 2;
	gfx::draw_rect(0, footer_y, screen_w, lm.footer_height, config::theme.footer_bg);

	String file_disp = doc.filepath.len > 0 ? doc.filepath : "untitled.c3";
	String mod_str   = doc.is_modified ? " [+]" : "";
	String save_str  = (ed.save_msg_timer > 0.0f) ? " [SAVED]" : "";
	String left_s    = string::tformat("%s%s%s", file_disp, mod_str, save_str);
	font::draw_text(left_s, 12, footer_text_y, lm.font_scale, config::theme.text_bright);

	int mid_x = screen_w / 2 - 120;
	if (doc.cursors.len() > 1)
	{
		String cur_count_str = string::tformat("[%d CARETS]", doc.cursors.len());
		font::draw_text(cur_count_str, mid_x, footer_text_y, lm.font_scale, config::theme.accent_blue);
		mid_x += ((int)cur_count_str.len + 2) * lm.char_width;
	}

	Cursor* pcur = doc.primary_cursor();
	sz sel_bytes = pcur.pos > pcur.anchor ? pcur.pos - pcur.anchor : pcur.anchor - pcur.pos;
	if (sel_bytes > 0)
	{
		DString sel_ds;
		sel_ds.tinit();
		doc.table.append_range_to_dstring(&sel_ds, pcur.sel_start(), pcur.sel_end());
		sz sel_count = conv::utf8_codepoints(sel_ds.str_view());
		String sel_s = string::tformat("SEL: %d", sel_count);
		font::draw_text(sel_s, mid_x, footer_text_y, lm.font_scale, config::theme.accent_yellow);
	}

	String right_str = string::tformat(
		"TAB %d/%d  LN: %d  COL: %d   LINES: %d  BYTES: %d",
		ed.active_tab_index + 1,
		ed.tabs.len(),
		cline + 1,
		ccol + 1,
		doc.get_total_lines(),
		doc.table.len()
	);
	int right_w = (int)right_str.len * lm.char_width;
	font::draw_text(right_str, screen_w - right_w - 12, footer_text_y, lm.font_scale, config::theme.header_muted);

	gfx::end_frame();
}
module c3ed;
import std;

fn String resolve_path_string(String raw_path, Allocator allocator = tmem)
{
	if (raw_path == "~")
	{
		if (try Path home = path::home_directory(allocator)) return ((String)home).copy(allocator);
	}
	else if (raw_path.starts_with("~/") || raw_path.starts_with("~\\"))
	{
		if (try Path home = path::home_directory(allocator))
		{
			if (raw_path.len <= 2) return ((String)home).copy(allocator);
			Path appended = home.append(allocator, raw_path[2..]) ?? home;
			return ((String)appended).copy(allocator);
		}
	}
	return raw_path;
}

enum DiagnosticSeverity : char
{
	ERROR,
	WARNING,
	NOTE
}

struct Diagnostic
{
	String filepath;
	int line;
	int col;
	String message;
	DiagnosticSeverity severity;
}

fn void Diagnostic.free(&self, Allocator allocator = mem)
{
	if (self.filepath.len > 0) alloc::free(allocator, self.filepath.ptr);
	if (self.message.len > 0) alloc::free(allocator, self.message.ptr);
	*self = { };
}

struct DiagnosticStore
{
	List{Diagnostic} items;
}

fn void DiagnosticStore.init(&self, Allocator allocator = mem)
{
	self.items.init(allocator, 32);
}

fn void DiagnosticStore.clear(&self)
{
	foreach (&diag : self.items)
	{
		diag.free(mem);
	}
	self.items.clear();
}

fn void DiagnosticStore.parse_output(&self, String output) => @pool()
{
	self.clear();
	if (output.len == 0) return;

	Splitter lines = output.tokenize("\n");
	while (try l = lines.next())
	{
		sz colon1 = l.index_of_char(':') ?? 0;
		if (colon1 == 0) continue;

		String path = l[:colon1].trim();
		String rest1 = l[colon1 + 1..];

		sz colon2 = rest1.index_of_char(':') ?? 0;
		if (colon2 == 0) continue;

		int line_num = rest1[:colon2].to_int() ?? 0;
		if (line_num <= 0) continue;

		String rest2 = rest1[colon2 + 1..];
		sz colon3 = rest2.index_of_char(':') ?? 0;
		int col_num = 1;
		String msg = rest2;

		if (colon3 > 0)
		{
			col_num = rest2[:colon3].to_int() ?? 1;
			msg = rest2[colon3 + 1..].trim();
		}

		DiagnosticSeverity sev = ERROR;
		if (msg.contains("Warning") || msg.contains("warning"))
		{
			sev = WARNING;
		}
		else if (msg.contains("Note") || msg.contains("note"))
		{
			sev = NOTE;
		}

		self.items.push({
			.filepath = path.copy(mem),
			.line     = line_num,
			.col      = col_num,
			.message  = msg.copy(mem),
			.severity = sev
		});
	}
}

fn Diagnostic*? DiagnosticStore.get_at(&self, String filepath, int line)
{
	if (filepath.len == 0 || self.items.len() == 0) return NOT_FOUND~;
	foreach (&d : self.items)
	{
		if (d.line == line && (d.filepath.ends_with(filepath) || filepath.ends_with(d.filepath)))
		{
			return d;
		}
	}
	return NOT_FOUND~;
}

enum GitLineStatus : char
{
	NONE,
	ADDED,
	MODIFIED,
	DELETED
}

struct GitHunk
{
	int line_start;
	int line_count;
	GitLineStatus status;
}

struct GitDiffStore
{
	String filepath;
	List{GitHunk} hunks;
}

fn void GitDiffStore.init(&self, Allocator allocator = mem)
{
	self.filepath = "";
	self.hunks.init(allocator, 16);
}

fn void GitDiffStore.free(&self, Allocator allocator = mem)
{
	if (self.filepath.len > 0) alloc::free(allocator, self.filepath.ptr);
	self.hunks.free();
	*self = { };
}

fn GitLineStatus GitDiffStore.get_status(&self, int line_idx)
{
	foreach (&h : self.hunks)
	{
		if (line_idx >= h.line_start && line_idx < h.line_start + h.line_count)
		{
			return h.status;
		}
	}
	return NONE;
}

fn void GitDiffStore.update(&self, String filepath, int total_lines) => @pool()
{
	$if env::WIN32:
		return;
	$else
		if (!config::settings.show_git_gutter) return;

		if (filepath.len == 0 || !file::exists(filepath) || is_binary_extension(filepath)) return;

		if (self.filepath != filepath)
		{
			if (self.filepath.len > 0) mem::free(self.filepath.ptr);
			self.filepath = filepath.copy(mem);
		}

		self.hunks.clear();

		String[*] cmd = {
			"git",
			"-c", "core.pager=",
			"--no-pager",
			"diff",
			"--no-color",
			"-U0",
			"--",
			filepath
		};

		char[16384] out_buf;
		SpawnOptions opts = STDERR_TO_STDOUT | INHERIT_ENV;
		String? diff_out = process::run_capture_stdout(&out_buf, cmd[..], options: opts);
		if (catch diff_out) return;
		if (diff_out.len == 0 || diff_out.starts_with("fatal:") || diff_out.starts_with("error:")) return;

		Splitter lines = diff_out.tokenize("\n");
		while (try l = lines.next())
		{
			if (!l.starts_with("@@")) continue;

			sz minus_idx = l.index_of_char('-') ?? 0;
			sz plus_idx  = l.index_of_char('+') ?? 0;
			if (minus_idx == 0 || plus_idx == 0 || plus_idx <= minus_idx) continue;

			String old_hunk = l[minus_idx + 1..plus_idx - 1].trim();
			String new_hunk = l[plus_idx + 1..];
			sz space_idx = new_hunk.index_of_char(' ') ?? new_hunk.len;
			new_hunk = new_hunk[:space_idx].trim();

			int old_start = 1;
			int old_count = 1;
			if (try comma = old_hunk.index_of_char(','))
			{
				old_start = old_hunk[:comma].to_int() ?? 1;
				old_count = old_hunk[comma + 1..].to_int() ?? 1;
			}
			else
			{
				old_start = old_hunk.to_int() ?? 1;
				old_count = 1;
			}

			int new_start = 1;
			int new_count = 1;
			if (try comma = new_hunk.index_of_char(','))
			{
				new_start = new_hunk[:comma].to_int() ?? 1;
				new_count = new_hunk[comma + 1..].to_int() ?? 1;
			}
			else
			{
				new_start = new_hunk.to_int() ?? 1;
				new_count = 1;
			}

			if (new_count == 0)
			{
				self.hunks.push({ math::max(0, new_start - 1), 1, DELETED });
			}
			else
			{
				GitLineStatus status = (old_count > 0) ? MODIFIED : ADDED;
				self.hunks.push({ math::max(0, new_start - 1), new_count, status });
			}
		}
	$endif
}

enum SymbolKind : char
{
	FUNCTION,
	STRUCT,
	UNION,
	ENUM,
	BITSTRUCT,
	MACRO,
	TYPE_ALIAS,
	CONSTANT,
	FAULT,
	VARIABLE,
	FIELD,
	MODULE
}

struct SymbolItem
{
	String name;
	SymbolKind kind;
	String signature;
	String doc_comment;
	String filepath;
	String parent_type;
	int line;
	int col;
}

fn void SymbolItem.free(&self, Allocator allocator = mem)
{
	if (self.name.len > 0) alloc::free(allocator, self.name.ptr);
	if (self.signature.len > 0) alloc::free(allocator, self.signature.ptr);
	if (self.doc_comment.len > 0) alloc::free(allocator, self.doc_comment.ptr);
	if (self.filepath.len > 0) alloc::free(allocator, self.filepath.ptr);
	if (self.parent_type.len > 0) alloc::free(allocator, self.parent_type.ptr);
	*self = { };
}

struct DeclKeyword
{
	String kw;
	SymbolKind kind;
	char[] stop_chars;
	bool is_callable;
}

const DeclKeyword[*] DECL_KEYWORDS = {
	{ "fn ",        FUNCTION,   "(",                     true  },
	{ "macro ",     MACRO,      "(",                     true  },
	{ "struct ",    STRUCT,     {' ', '{', '<', '('},    false },
	{ "union ",     UNION,      {' ', '{', '<', '('},    false },
	{ "enum ",      ENUM,       {' ', '{', ':', '('},    false },
	{ "bitstruct ", BITSTRUCT,  {' ', '{', ':'},         false },
	{ "const ",     CONSTANT,   {'=', ';'},              false },
	{ "faultdef ",  FAULT,      {';', ' '},              false },
	{ "alias ",     TYPE_ALIAS, {'=', ';', '<', '@', ' '}, false },
	{ "typedef ",   TYPE_ALIAS, {'=', ';', '<', '@', ' '}, false },
};

struct SymbolIndex
{
	List{SymbolItem} symbols;
	bool initialized;
}

fn void SymbolIndex.init(&self, Allocator allocator = mem)
{
	self.symbols.init(allocator, 2048);
	self.initialized = false;
}

fn void SymbolIndex.free(&self, Allocator allocator = mem)
{
	foreach (&s : self.symbols) s.free(allocator);
	self.symbols.free();
	*self = { };
}

fn void SymbolIndex.index_source_text(&self, String filepath, String text, Allocator allocator = mem) => @pool()
{
	if (text.len == 0) return;

	Splitter lines = text.tokenize_all("\n");
	int line_num = 1;
	DString active_doc;
	active_doc.tinit();
	bool inside_doc = false;
	bool inside_block_comment = false;

	String active_container = "";
	String current_module = "";
	int container_brace_depth = 0;

	while (try line_raw = lines.next())
	{
		String l = line_raw.trim();
		if (l.len == 0 || l.starts_with("//") || l.starts_with("#!"))
		{
			line_num++;
			continue;
		}

		if (l.starts_with("module "))
		{
			String mod_rest = l["module ".len..].trim(" ;");
			if (try semi = mod_rest.index_of_char(';')) mod_rest = mod_rest[:semi].trim();
			sz last_col = mod_rest.rindex_of("::") ?? -1;
			current_module = (last_col >= 0 ? mod_rest[last_col + 2..] : mod_rest);
			line_num++;
			continue;
		}

		if (!inside_block_comment && l.starts_with("<*"))
		{
			if (l.ends_with("*>") && l.len >= 4)
			{
				active_doc.clear();
				active_doc.append(l[2..l.len - 2].trim());
				line_num++;
				continue;
			}
			inside_doc = true;
			active_doc.clear();
			active_doc.append(l[2..].trim());
			line_num++;
			continue;
		}

		if (inside_doc)
		{
			if (l.ends_with("*>"))
			{
				inside_doc = false;
				active_doc.append_char(' ');
				active_doc.append(l[:l.len - 2].trim());
			}
			else
			{
				active_doc.append_char(' ');
				active_doc.append(l);
			}
			line_num++;
			continue;
		}

		if (!inside_doc && !inside_block_comment && l.starts_with("/*"))
		{
			if (l.ends_with("*/") && l.len >= 4)
			{
				line_num++;
				continue;
			}
			inside_block_comment = true;
			line_num++;
			continue;
		}

		if (inside_block_comment)
		{
			if (l.ends_with("*/") || l.contains("*/"))
			{
				inside_block_comment = false;
			}
			line_num++;
			continue;
		}

		if (active_container.len > 0)
		{
			if (l.contains_char('{')) container_brace_depth++;
			if (l.contains_char('}'))
			{
				container_brace_depth--;
				if (container_brace_depth <= 0)
				{
					active_container = "";
					container_brace_depth = 0;
				}
			}
			else if (container_brace_depth > 0)
			{
				if (l.ends_with(";") && !l.starts_with("fn ") && !l.starts_with("struct ") && !l.starts_with("union "))
				{
					String field_line = l[:l.len - 1].trim();
					sz sp_idx = field_line.rindex_of_char(' ') ?? -1;
					if (sp_idx >= 0)
					{
						String fname = field_line[sp_idx + 1..].trim();
						if (fname.len > 0 && (fname[0].is_alpha() || fname[0] == '_'))
						{
							SymbolItem fsym = {
								.name        = fname.copy(allocator),
								.kind        = FIELD,
								.signature   = l.copy(allocator),
								.filepath    = filepath.copy(allocator),
								.parent_type = active_container.copy(allocator),
								.line        = line_num,
								.col         = (int)(line_raw.index_of(fname) ?? 0) + 1
							};
							self.symbols.push(fsym);
						}
					}
				}
				else if (l.ends_with(",") || !l.contains_char(';'))
				{
					String entry_name = l.trim(" ,{}=0123456789;");
					if (entry_name.len > 0 && entry_name[0].is_upper())
					{
						sz sp_i = entry_name.index_of_char(' ') ?? entry_name.len;
						entry_name = entry_name[:sp_i];
						SymbolItem esym = {
							.name        = entry_name.copy(allocator),
							.kind        = CONSTANT,
							.signature   = l.copy(allocator),
							.filepath    = filepath.copy(allocator),
							.parent_type = active_container.copy(allocator),
							.line        = line_num,
							.col         = (int)(line_raw.index_of(entry_name) ?? 0) + 1
						};
						self.symbols.push(esym);
					}
				}
			}
		}

		SymbolItem sym = { };
		bool found = false;

		foreach (&dk : DECL_KEYWORDS)
		{
			if (l.starts_with(dk.kw))
			{
				String rest = l[dk.kw.len..].trim();
				sz end_idx = dk.is_callable
					? (rest.index_of_char('(') ?? 0)
					: (rest.index_of_chars(dk.stop_chars) ?? rest.len);

				if (end_idx > 0)
				{
					found = true;
					sym.kind = dk.kind;
					String pre = rest[:end_idx].trim();
					sz sp = pre.rindex_of_char(' ') ?? -1;
					String full_name = (sp >= 0 ? pre[sp + 1..] : pre).trim();

					if (try dot_pos = full_name.index_of_char('.'))
					{
						sym.parent_type = full_name[:dot_pos].copy(allocator);
						sym.name = full_name[dot_pos + 1..].copy(allocator);
					}
					else
					{
						sym.name = full_name.copy(allocator);
						if (current_module.len > 0) sym.parent_type = current_module.copy(allocator);
					}
					sym.signature = l.copy(allocator);

					if (dk.kind == STRUCT || dk.kind == UNION || dk.kind == BITSTRUCT || dk.kind == ENUM)
					{
						active_container = sym.name;
						container_brace_depth = l.contains_char('{') ? 1 : 0;
					}
				}
				break;
			}
		}

		if (found && sym.name.len > 0)
		{
			sym.filepath = filepath.copy(allocator);
			sym.line = line_num;
			sym.col = (int)(line_raw.index_of(sym.name) ?? 0) + 1;
			sym.doc_comment = active_doc.str_view().trim().copy(allocator);
			active_doc.clear();
			self.symbols.push(sym);
		}
		line_num++;
	}
}

fn SymbolItem*? SymbolIndex.find_symbol_closest(&self, String name, int near_line = 0)
{
	if (name.len == 0 || self.symbols.len() == 0) return NOT_FOUND~;

	SymbolItem* best = null;
	int best_dist = int::max;

	foreach (&sym : self.symbols)
	{
		bool matches = (sym.name == name);
		if (!matches && sym.name.ends_with(name))
		{
			if (sym.name.len > name.len && sym.name[sym.name.len - name.len - 1] == '.')
			{
				matches = true;
			}
		}

		if (matches)
		{
			if (near_line > 0)
			{
				if (sym.line <= near_line)
				{
					int dist = near_line - sym.line;
					if (dist < best_dist)
					{
						best_dist = dist;
						best = sym;
					}
				}
				else if (best == null)
				{
					best = sym;
				}
			}
			else
			{
				return sym;
			}
		}
	}
	if (best != null) return best;
	return NOT_FOUND~;
}

struct FileWatcher
{
	float check_interval;
	float timer;
}

fn void FileWatcher.init(&self, float check_interval = config::TIMING.file_watcher_interval)
{
	self.check_interval = check_interval;
	self.timer = 0.0f;
}

fn bool FileWatcher.should_poll(&self, float dt)
{
	self.timer += dt;
	if (self.timer < self.check_interval) return false;
	self.timer = 0.0f;
	return true;
}

struct Workspace
{
	String root_dir;
	List{String} files;
	bool files_valid;

	SymbolIndex lsp;
	DiagnosticStore diagnostics;
	GitDiffStore git;
	FileWatcher watcher;
}

fn void Workspace.init(&self, Allocator allocator = mem, String root_dir = ".")
{
	self.root_dir = root_dir.copy(allocator);
	self.files.init(allocator, 512);
	self.files_valid = false;
	self.lsp.init(allocator);
	self.diagnostics.init(allocator);
	self.git.init(allocator);
	self.watcher.init(config::TIMING.file_watcher_interval);

	self.index_workspace_symbols();
}

fn void Workspace.free(&self, Allocator allocator = mem)
{
	if (self.root_dir.len > 0) alloc::free(allocator, self.root_dir.ptr);
	self.invalidate_files();
	self.files.free();
	self.lsp.free(allocator);
	self.diagnostics.clear();
	self.diagnostics.items.free();
	self.git.free(allocator);
	*self = { };
}

fn void Workspace.invalidate_files(&self)
{
	foreach (s : self.files)
	{
		if (s.len > 0) mem::free(s.ptr);
	}
	self.files.clear();
	self.files_valid = false;
}

fn void Workspace.refresh_files(&self) => @pool()
{
	self.invalidate_files();
	collect_workspace_files(mem, (Path)self.root_dir, &self.files, c3_only: false, max_files: 5000);
	self.files_valid = true;
}

fn void Workspace.ensure_files(&self)
{
	if (!self.files_valid || self.files.len() == 0)
	{
		self.refresh_files();
	}
}

fn void Workspace.index_workspace_symbols(&self) => @pool()
{
	List{String} c3_files;
	c3_files.tinit(512);
	collect_workspace_files(tmem, (Path)self.root_dir, &c3_files, c3_only: true, max_files: 1000);

	foreach (filepath : c3_files)
	{
		@pool()
		{
			if (file::get_size(filepath) ?? 0 > 2 * 1024 * 1024) return;
			char[]? code_opt = file::load(tmem, filepath);
			if (try code = code_opt)
			{
				self.lsp.index_source_text(filepath, (String)code, mem);
			}
		};
	}
	self.lsp.initialized = true;
}

fn void Workspace.poll_disk_changes(
	&self,
	List{Tab}* tabs,
	int* pending_reload_tab,
	ModalKind* active_modal,
	float dt
) => @pool()
{
	if (!self.watcher.should_poll(dt)) return;

	for (sz idx = 0; idx < tabs.len(); idx++)
	{
		Tab* tab = &(*tabs)[idx];
		if (!tab.doc.is_file_specified || tab.doc.filepath.len == 0) continue;
		Time? mtime = file::last_modified(tab.doc.filepath);
		if (catch mtime) continue;

		Time cur_mtime = mtime;
		if (tab.doc.last_disk_mtime != (Time)0 && cur_mtime > tab.doc.last_disk_mtime)
		{
			tab.doc.last_disk_mtime = cur_mtime;
			self.invalidate_files();

			if (!tab.doc.is_modified)
			{
				char[]? new_content = file::load(tmem, tab.doc.filepath);
				if (try c = new_content)
				{
					tab.doc.table.free();
					tab.doc.table.init(mem, (char[])((String)c).copy(mem));
					tab.doc.rebuild_line_index();
					tab.doc.is_modified = false;
					self.git.update(tab.doc.filepath, tab.doc.get_total_lines());
				}
			}
			else
			{
				*pending_reload_tab = (int)idx;
				*active_modal = CONFIRM_DISK_RELOAD;
			}
		}
		else if (tab.doc.last_disk_mtime == (Time)0)
		{
			tab.doc.last_disk_mtime = cur_mtime;
		}
	}
}

const String[*] IGNORED_DIRECTORIES = {
	".git", ".venv", "venv", "env", "node_modules",
	".cache", ".local", ".config", ".vscode", ".idea", ".vs", "build",
	"bin", "obj", "target", "dist", "out", "pkg", "dependencies",
	".pytest_cache", "__pycache__", ".mypy_cache",
	".svn", ".hg", ".dart_tool", ".gradle", "snap", "flatpak"
};

fn bool is_ignored_dirname(String name)
{
	if (name.len == 0) return false;
	if (name.starts_with(".") && name != ".") return true;
	if (name.starts_with("build_") || name.starts_with("build-") || name.starts_with(".build")) return true;
	foreach (ignored : IGNORED_DIRECTORIES)
	{
		if (name == ignored) return true;
	}
	return false;
}

fn bool is_binary_extension(String filepath)
{
	String ext = filepath.file_tbasename() ?? filepath;
	return ext.ends_with(".png")  || ext.ends_with(".jpg")  || ext.ends_with(".jpeg") ||
	       ext.ends_with(".gif")  || ext.ends_with(".ico")  || ext.ends_with(".bmp")  ||
	       ext.ends_with(".exe")  || ext.ends_with(".dll")  || ext.ends_with(".so")   ||
	       ext.ends_with(".dylib")|| ext.ends_with(".o")    || ext.ends_with(".a")    ||
	       ext.ends_with(".lib")  || ext.ends_with(".bin")  || ext.ends_with(".dat")  ||
	       ext.ends_with(".wasm") || ext.ends_with(".zip")  || ext.ends_with(".tar")  ||
	       ext.ends_with(".gz")   || ext.ends_with(".7z")   || ext.ends_with(".pdf")  ||
	       ext.ends_with(".ttf")  || ext.ends_with(".otf")  || ext.ends_with(".woff") ||
	       ext.ends_with(".woff2")|| ext.ends_with(".mp3")  || ext.ends_with(".wav")  ||
	       ext.ends_with(".mp4")  || ext.ends_with(".mkv")  || ext.ends_with(".class")||
	       ext.ends_with(".pdb")  || ext.ends_with(".zst")  || ext.ends_with(".data");
}

fn void collect_workspace_files(
	Allocator allocator,
	Path dir,
	List{String}* out_files,
	bool c3_only = false,
	int depth = 0,
	sz max_files = 5000
) => @pool()
{
	if (depth > 8 || out_files.len() >= max_files) return;

	PathList? entries_opt = path::ls(tmem, dir, no_dirs: false, no_symlinks: true, relative: true, rebase: dir);
	if (catch entries_opt) return;
	PathList entries = entries_opt;

	List{Path} sub_dirs;
	sub_dirs.tinit(32);

	foreach (entry_path : entries)
	{
		if (out_files.len() >= max_files) break;

		String p_str = (String)entry_path;
		String base_name = p_str.file_tbasename() ?? p_str;
		if (base_name.len == 0 || base_name == "." || base_name == "..") continue;
		if (is_ignored_dirname(base_name)) continue;

		if (path::is_dir(entry_path))
		{
			sub_dirs.push(entry_path);
		}
		else if (path::is_file(entry_path))
		{
			if (is_binary_extension(p_str)) continue;
			if (c3_only && !p_str.ends_with(".c3")) continue;

			out_files.push(p_str.copy(allocator));
		}
	}

	foreach (sub_dir : sub_dirs)
	{
		if (out_files.len() >= max_files) break;
		collect_workspace_files(allocator, sub_dir, out_files, c3_only, depth + 1, max_files);
	}
}
