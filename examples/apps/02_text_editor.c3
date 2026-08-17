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

// Layout Geometry Constants
const int HEADER_HEIGHT        = 0;
const int FOOTER_HEIGHT        = 26;
const int GUTTER_BORDER_W      = 2;
const int GUTTER_PADDING_RIGHT = 8;
const int TEXT_PADDING_X       = 8;
const int TEXT_PADDING_Y       = 6;

const float CURSOR_BLINK_RATE    = 0.5;
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

fn int get_num_digits(int n)
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

// Line-State Syntax Highlighting Enums & Types

enum LineState : int
{
	NORMAL,
	IN_BLOCK_COMMENT,
	IN_CONTRACT_COMMENT,
	IN_RAW_STRING
}

enum TokenType : (RLColor color, String[] keywords)
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
	foreach (kw : TokenType.KEYWORD.keywords)   if (kw == w) return KEYWORD;
	foreach (tw : TokenType.TYPE.keywords)      if (tw == w) return TYPE;
	foreach (dw : TokenType.DIRECTIVE.keywords) if (dw == w) return DIRECTIVE;
	foreach (bw : TokenType.BUILTIN.keywords)   if (bw == w) return BUILTIN;
	foreach (aw : TokenType.ATTRIBUTE.keywords) if (aw == w) return ATTRIBUTE;

	switch
	{
		case w.len > 1 && (w[0] == 'i' || w[0] == 'u') && w[1].is_digit():
			return TYPE;
		case w.len > 0 && w[0].is_upper():
			return TYPE;
		case is_fn:
			return FUNCTION;
		default:
			return DEFAULT;
	}
}

fn LineState lex_line(GapBuffer* buf, sz start, sz end, LineState start_state, TokenType[] out_tokens)
{
	LineState state = start_state;
	sz len          = end - start;
	sz idx          = 0;

	while (idx < len)
	{
		char c = buf.get(start + idx);

		switch
		{
			// Multi-line continuation states
			case state == IN_BLOCK_COMMENT:
				out_tokens[idx] = COMMENT;
				if (c == '*' && idx + 1 < len && buf.get(start + idx + 1) == '/')
				{
					state = NORMAL;
					idx++;
					out_tokens[idx] = COMMENT;
				}
				idx++;

			case state == IN_CONTRACT_COMMENT:
				out_tokens[idx] = CONTRACT;
				if (c == '*' && idx + 1 < len && buf.get(start + idx + 1) == '>')
				{
					state = NORMAL;
					idx++;
					out_tokens[idx] = CONTRACT;
				}
				idx++;

			case state == IN_RAW_STRING:
				out_tokens[idx] = STRING_LITERAL;
				if (c == '`') state = NORMAL;
				idx++;

			// Single-line comments & hashbang
			case (c == '/' && idx + 1 < len && buf.get(
				start + idx + 1
			) == '/') || (c == '#' && idx + 1 < len && buf.get(start + idx + 1) == '!'):
				while (idx < len) out_tokens[idx++] = COMMENT;

			// Comment block openers
			case c == '/' && idx + 1 < len && buf.get(start + idx + 1) == '*':
				out_tokens[idx++] = COMMENT;
				out_tokens[idx++] = COMMENT;
				state = IN_BLOCK_COMMENT;

			case c == '<' && idx + 1 < len && buf.get(start + idx + 1) == '*':
				out_tokens[idx++] = CONTRACT;
				out_tokens[idx++] = CONTRACT;
				state = IN_CONTRACT_COMMENT;

			// Strings: verbatim (\\), raw (`), prefixed/standard quotes (" / ')
			case c == '\\' && idx + 1 < len && buf.get(start + idx + 1) == '\\':
				while (idx < len) out_tokens[idx++] = STRING_LITERAL;

			case c == '`':
				out_tokens[idx++] = STRING_LITERAL;
				state = IN_RAW_STRING;

			case c == '"' || c == '\'':
				char quote = c;
				out_tokens[idx++] = STRING_LITERAL;
				while (idx < len)
				{
					char sc = buf.get(start + idx);
					out_tokens[idx++] = STRING_LITERAL;
					if (sc == quote && (idx < 2 || buf.get(start + idx - 2) != '\\')) break;
				}

			// Numbers (hex, octal, binary, floats)
			case c.is_digit():
				sz n_start = idx;
				while (idx < len && (buf.get(start + idx)
					.is_alnum() || buf.get(start + idx) == '.' || buf.get(start + idx) == '_')) idx++;
				for (sz k = n_start; k < idx; k++) out_tokens[k] = NUMBER;

			// Words: Identifiers, Keywords, Types, Attributes (@), Directives ($), Builtins ($$)
			case c.is_alpha() || c == '_' || c == '@' || c == '$':
				sz id_start = idx;
				while (idx < len && (buf.get(start + idx)
					.is_alnum() || buf.get(
						start + idx
					) == '_' || buf.get(start + idx) == '$' || buf.get(start + idx) == '@')) idx++;

				sz id_len = idx - id_start;
				char[128] stack_word;
				char[] word_chars;

				word_chars = (id_len <= 128) ? stack_word[:id_len] : alloc::alloc_array(tmem, char, id_len);
				for (sz k = 0; k < id_len; k++) word_chars[k] = buf.get(start + id_start + k);

				sz p = idx;
				while (p < len && (buf.get(start + p) == ' ' || buf.get(start + p) == '\t')) p++;
				bool is_fn = (p < len && buf.get(start + p) == '(');

				TokenType t = match_word_token((String)word_chars, is_fn);
				for (sz k = id_start; k < idx; k++) out_tokens[k] = t;

			// Delimiters & Operators
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

// 5x8 Monospace Bitmap Font
enum FontGlyph : (Char32 ch, ulong bitmap)
{
	// Uppercase Glyphs
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

	// Lowercase Glyphs
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

	// Numbers & Punctuation
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
	ACUTE       { '´', 0b00010_00100_01000_00000_00000_00000_00000_00000UL },

	// Accented Symbols
	N_TILDE       { 'Ñ', 0b01100_10001_11001_10101_10011_10001_10001_00000UL },
	LOWER_N_TILDE { 'ñ', 0b01100_00000_11110_10001_10001_10001_10001_00000UL },

	UNKNOWN { '\0', 0b11111_10001_10101_10101_10101_10001_11111_00000UL }
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

fn bool is_word_char(char c) => c.is_alnum() || c == '_';
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
	List{sz} line_starts;
	List{LineState} line_states;
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

	// Features State
	String current_filepath;
	bool is_file_specified;
	bool is_modified;
	bool should_exit;
	bool goto_modal_open;
	char[16] goto_input_buf;
	int goto_input_len;
	float page_hold_timer;
	float save_msg_timer;
}

fn void Editor.recompute_line_states(&self)
{
	if (self.line_states.entries == null)
	{
		self.line_states.init(mem);
	}
	self.line_states.clear();
	int total_lines         = (int)self.line_starts.len();
	LineState current_state = NORMAL;
	TokenType[1024] dummy_buf;

	for (int i = 0; i < total_lines; i++)
	{
		sz start        = self.get_line_start_of_line(i);
		sz end          = self.get_line_end(start);
		sz len          = end - start;
		TokenType[] buf = (len <= 1024) ? dummy_buf[:len] : alloc::alloc_array(tmem, TokenType, len);

		current_state = lex_line(&self.buffer, start, end, current_state, buf);
		self.line_states.push(current_state);
	}
}

fn void Editor.rebuild_line_index(&self)
{
	if (self.line_starts.entries == null)
	{
		self.line_starts.init(mem);
	}
	self.line_starts.clear();
	self.line_starts.push(0);

	char[] pref = self.buffer.prefix();
	for (sz i = 0; i < pref.len; i++)
	{
		if (pref[i] == '\n')
		{
			self.line_starts.push(i + 1);
		}
	}

	sz pref_len = pref.len;
	char[] suff = self.buffer.suffix();
	for (sz j = 0; j < suff.len; j++)
	{
		if (suff[j] == '\n')
		{
			self.line_starts.push(pref_len + j + 1);
		}
	}

	self.recompute_line_states();
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
	self.rebuild_line_index();
	self.cursor_pos = 0;
	self.sel_anchor = 0;
	self.target_col = 0;
	self.scroll_line = 0;
	self.scroll_col = 0;
	self.undo_stack.init(mem);
	self.is_modified = false;
}

fn void Editor.save_undo_state(&self)
{
	sz buf_len = self.buffer.len();
	if (buf_len > 50 * 1024 * 1024) return; // Skip undo for files larger than 50MB

	// Dynamically cap undo states for large documents to preserve memory
	sz max_snapshots = MAX_UNDO_STATES;
	switch
	{
		case buf_len > 10 * 1024 * 1024:
			max_snapshots = 4;
		case buf_len > 2 * 1024 * 1024:
			max_snapshots = 8;
	}

	while (self.undo_stack.len() >= max_snapshots)
	{
		if (try old = self.undo_stack.pop_first())
		{
			if (old.text.len > 0) mem::free(old.text.ptr);
			mem::free(old);
		}
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
		self.rebuild_line_index();
		self.cursor_pos = snap.cursor_pos;
		self.sel_anchor = snap.sel_anchor;
		self.target_col = self.get_col(self.cursor_pos);
		if (snap.text.len > 0) mem::free(snap.text.ptr);
		mem::free(snap);
		self.is_modified = true;
	}
}

extern fn void set_web_clipboard(ZString text) @feat(WASM);
fn void set_clipboard(ZString text)
{
	if (text.str_view().len > 10 * 1024 * 1024) return;

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
	self.rebuild_line_index();
	self.cursor_pos += text.len;
	self.sel_anchor = self.cursor_pos;
	self.target_col = self.get_col(self.cursor_pos);
	self.is_modified = true;
}

fn int Editor.get_line(&self, sz pos)
{
	sz len = self.line_starts.len();
	if (len <= 1 || pos == 0) return 0;
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

fn int Editor.get_col(&self, sz pos)
{
	int col                = 0;
	sz line_start          = self.get_line_start(pos);
	GapBufferIterator iter = self.buffer.iterator(line_start, pos);
	while (try Char32 c = iter.next())
	{
		switch (c)
		{
			case '\n':
				col = 0;
			case '\t':
				int tab_spaces = TAB_SIZE_SPACES - (col % TAB_SIZE_SPACES);
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
	if (self.line_starts.len() == 0) return 1;
	return (int)self.line_starts.len();
}

fn sz Editor.get_line_start(&self, sz pos)
{
	int line = self.get_line(pos);
	return self.get_line_start_of_line(line);
}

fn sz Editor.get_line_end(&self, sz pos)
{
	int line = self.get_line(pos);
	if (line + 1 < (int)self.line_starts.len())
	{
		return self.line_starts[(sz)(line + 1)] - 1;
	}
	return self.buffer.len();
}

fn sz Editor.get_line_start_of_line(&self, int target_line)
{
	if (target_line <= 0 || self.line_starts.len() == 0) return 0;
	if (target_line >= (int)self.line_starts.len()) return self.buffer.len();
	return self.line_starts[target_line];
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

fn sz Editor.get_pos_from_mouse(&self, Vec2 mpos, int text_start_x, int text_start_y)
{
	if (mpos.x < text_start_x || mpos.y < text_start_y)
	{
		if (mpos.y < text_start_y) return 0;
	}
	int rel_y = (int)(mpos.y - text_start_y);
	int line  = rel_y / LINE_HEIGHT + self.scroll_line;
	int rel_x = (int)(mpos.x - text_start_x + CHAR_WIDTH / 2);
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
	self.rebuild_line_index();
	self.cursor_pos = start;
	self.sel_anchor = start;
	self.target_col = self.get_col(self.cursor_pos);
	self.is_modified = true;
}

fn void Editor.insert_codepoint(&self, Char32 c)
{
	// Expand tab to spaces
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
	self.rebuild_line_index();
	self.cursor_pos += len;
	self.sel_anchor = self.cursor_pos;
	self.target_col = self.get_col(self.cursor_pos);
	self.is_modified = true;
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
		self.rebuild_line_index();
		self.cursor_pos = prev;
		self.sel_anchor = self.cursor_pos;
		self.target_col = self.get_col(self.cursor_pos);
		self.is_modified = true;
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
		self.rebuild_line_index();
		self.is_modified = true;
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
	switch
	{
		case cursor_line < self.scroll_line:
			self.scroll_line = cursor_line;
		case cursor_line >= self.scroll_line + visible_lines:
			self.scroll_line = cursor_line - visible_lines + 1;
	}

	self.scroll_line = math::clamp(self.scroll_line, 0, math::max(0, self.get_total_lines() - 1));

	int cursor_col = self.get_col(self.cursor_pos);
	switch
	{
		case cursor_col < self.scroll_col:
			self.scroll_col = cursor_col;
		case cursor_col >= self.scroll_col + visible_cols:
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

fn void Editor.poll_raylib_input(
	&self,
	int visible_lines,
	int visible_cols,
	int text_start_x,
	int text_start_y,
	float dt
)
{
	sz prev_pos = self.cursor_pos;
	sz prev_len = self.buffer.len();

	self.shift_held = rl::is_key_down(LEFT_SHIFT) || rl::is_key_down(RIGHT_SHIFT);
	self.ctrl_held = rl::is_key_down(LEFT_CONTROL) || rl::is_key_down(RIGHT_CONTROL);

	// Go-To-Line Modal Input Handler
	if (self.goto_modal_open)
	{
		if (rl::is_key_pressed(ESCAPE))
		{
			self.goto_modal_open = false;
		}
		if (rl::is_key_pressed(ENTER) || rl::is_key_pressed(KP_ENTER))
		{
			int target_line = 1;
			if (self.goto_input_len > 0)
			{
				target_line = string::to_integer{int}((String)self.goto_input_buf[:self.goto_input_len]) ?? 1;
			}
			int tot = self.get_total_lines();
			target_line = math::clamp(target_line, 1, tot);
			self.cursor_pos = self.get_pos_from_line_col(target_line - 1, 0);
			self.sel_anchor = self.cursor_pos;
			self.target_col = 0;
			self.ensure_cursor_visible(visible_lines, visible_cols);
			self.goto_modal_open = false;
		}
		if (key_pressed_or_repeat(BACKSPACE))
		{
			if (self.goto_input_len > 0)
			{
				self.goto_input_len--;
				self.goto_input_buf[self.goto_input_len] = '\0';
			}
		}

		int codepoint = rl::get_char_pressed();
		while (codepoint > 0)
		{
			if (codepoint >= '0' && codepoint <= '9' && self.goto_input_len < 15)
			{
				self.goto_input_buf[self.goto_input_len++] = (char)codepoint;
				self.goto_input_buf[self.goto_input_len] = '\0';
			}
			codepoint = rl::get_char_pressed();
		}
		return;
	}

	RLVector2 mouse_v = rl::get_mouse_position();
	Vec2 mouse_pos    = { mouse_v.x, mouse_v.y };

	switch
	{
		case rl::is_mouse_button_pressed(LEFT):
			self.mouse_down = true;
			double now = rl::get_time();
			sz clicked_pos = self.get_pos_from_mouse(mouse_pos, text_start_x, text_start_y);
			float dx = mouse_pos.x - self.last_click_pos.x;
			float dy = mouse_pos.y - self.last_click_pos.y;
			float dist_sq = dx * dx + dy * dy;

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

		case self.mouse_down && rl::is_mouse_button_down(LEFT):
			sz cur_pos = self.get_pos_from_mouse(mouse_pos, text_start_x, text_start_y);
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

		case rl::is_mouse_button_released(LEFT):
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
	int cp = rl::get_char_pressed();
	while (cp > 0)
	{
		if (!self.ctrl_held)
		{
			self.insert_codepoint((Char32)cp);
		}
		cp = rl::get_char_pressed();
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
		if (key_pressed_or_repeat(Z)) self.undo();
		if (rl::is_key_pressed(S))
		{
			if (self.current_filepath.len > 0)
			{
				String text = self.buffer.to_tstring();
				if (catch file::save(self.current_filepath, (char[])text))
				{
					// Save failed
				}
				else
				{
					self.is_modified = false;
					self.save_msg_timer = 2.0f;
				}
			}
		}
		if (rl::is_key_pressed(Q)) self.should_exit = true;
		if (rl::is_key_pressed(G))
		{
			self.goto_modal_open = true;
			self.goto_input_len = 0;
			self.goto_input_buf[0] = '\0';
		}
	}

	if (rl::is_key_pressed(ESCAPE)) self.sel_anchor = self.cursor_pos;
	if (key_pressed_or_repeat(BACKSPACE)) self.handle_backspace();
	if (key_pressed_or_repeat(DELETE)) self.handle_delete();
	if (key_pressed_or_repeat(TAB)) self.insert_codepoint('\t');
	if (key_pressed_or_repeat(ENTER)) self.insert_codepoint('\n');

	// Page Up / Down timer acceleration
	bool page_held = rl::is_key_down(PAGE_UP) || rl::is_key_down(PAGE_DOWN);
	if (page_held)
	{
		self.page_hold_timer += dt;
	}
	else
	{
		self.page_hold_timer = 0.0f;
	}
	int step_multiplier = 1 + math::clamp((int)(self.page_hold_timer * 5.0f), 0, 10);
	int move_lines      = visible_lines * step_multiplier;

	if (key_pressed_or_repeat(PAGE_UP))
	{
		int line_pu        = self.get_line(self.cursor_pos);
		int target_line_pu = math::max(0, line_pu - move_lines);
		self.cursor_pos = self.get_pos_from_line_col(target_line_pu, self.target_col);
		if (!self.shift_held) self.sel_anchor = self.cursor_pos;
	}
	if (key_pressed_or_repeat(PAGE_DOWN))
	{
		int line_pd        = self.get_line(self.cursor_pos);
		int tot_pd         = self.get_total_lines();
		int target_line_pd = math::min(tot_pd - 1, line_pd + move_lines);
		self.cursor_pos = self.get_pos_from_line_col(target_line_pd, self.target_col);
		if (!self.shift_held) self.sel_anchor = self.cursor_pos;
	}
	if (key_pressed_or_repeat(LEFT))
	{
		sz new_pos_l = self.cursor_pos;
		switch
		{
			case self.ctrl_held:
				new_pos_l = self.get_prev_word_pos(self.cursor_pos);
			case !self.shift_held && self.cursor_pos != self.sel_anchor:
				new_pos_l = math::min(self.cursor_pos, self.sel_anchor);
			default:
				new_pos_l = self.get_prev_char_pos(self.cursor_pos);
		}

		self.cursor_pos = new_pos_l;
		if (!self.shift_held) self.sel_anchor = self.cursor_pos;
		self.target_col = self.get_col(self.cursor_pos);
	}
	if (key_pressed_or_repeat(RIGHT))
	{
		sz new_pos_r = self.cursor_pos;
		switch
		{
			case self.ctrl_held:
				new_pos_r = self.get_next_word_pos(self.cursor_pos);
			case !self.shift_held && self.cursor_pos != self.sel_anchor:
				new_pos_r = math::max(self.cursor_pos, self.sel_anchor);
			default:
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

fn void update_draw_frame() => @pool()
{
	init_font_texture();

	float dt   = rl::get_frame_time();
	int width  = rl::get_screen_width();
	int height = rl::get_screen_height();
	if (width <= 0) width = 1600;
	if (height <= 0) height = 900;

	if (editor.save_msg_timer > 0.0f)
	{
		editor.save_msg_timer -= dt;
		if (editor.save_msg_timer < 0.0f) editor.save_msg_timer = 0.0f;
	}

	if (!editor.initialized)
	{
		editor.initialized = true;
		if (editor.is_file_specified)
		{
			if (try content = file::load_temp(editor.current_filepath))
			{
				editor.load_text((String)content);
			}
			else
			{
				editor.load_text("");
			}
		}
		else
		{
			editor.load_text(
				`/*

 C3 Text Editor

 Features & Shortcuts:
 - Navigation : Arrows, Home / End, PageUp / PageDown
 - Word Jumps : Ctrl + Left / Right
 - Selection  : Shift + Navigation, Ctrl + A (Select All)
 - Clipboard  : Ctrl + C (Copy), Ctrl + X (Cut), Ctrl + V (Paste)
 - History    : Ctrl + Z (Undo)
 - Go to Line : Ctrl + G
 - File Ops   : Ctrl + S (Save), Ctrl + Q (Quit)
 - Mouse      : Click, Double-click (word), Drag to select

*/

module main;
import std::io;

fn int main(String[] args)
{
	io::printn("Hello, World!");
	return 0;
}
`
			);
		}
	}

	// Dynamic Gutter Calculation
	int total_lines  = editor.get_total_lines();
	int digits       = math::max(4, get_num_digits(total_lines));
	int gutter_width = digits * CHAR_WIDTH + GUTTER_PADDING_RIGHT + GUTTER_BORDER_W;
	int text_start_x = gutter_width + TEXT_PADDING_X;
	int text_start_y = HEADER_HEIGHT + TEXT_PADDING_Y;

	int editor_w = width - text_start_x;
	int editor_h = height - HEADER_HEIGHT - FOOTER_HEIGHT;

	int visible_lines = math::max(1, (editor_h - TEXT_PADDING_Y * 2) / LINE_HEIGHT);
	int visible_cols  = math::max(1, (editor_w - TEXT_PADDING_X) / CHAR_WIDTH);

	editor.blink_timer += dt;
	if (editor.blink_timer >= CURSOR_BLINK_RATE)
	{
		editor.blink_timer -= CURSOR_BLINK_RATE;
		editor.cursor_visible = !editor.cursor_visible;
	}

	editor.poll_raylib_input(visible_lines, visible_cols, text_start_x, text_start_y, dt);

	rl::begin_drawing();
	rl::clear_background(COLOR_BG);

	rl::begin_scissor_mode(text_start_x, text_start_y, editor_w, editor_h);

	// Active line highlight
	int cline           = editor.get_line(editor.cursor_pos);
	int ccol            = editor.get_col(editor.cursor_pos);
	int active_rel_line = cline - editor.scroll_line;

	if (active_rel_line >= 0 && active_rel_line < visible_lines)
	{
		int hl_y = text_start_y + active_rel_line * LINE_HEIGHT;
		rl::draw_rectangle(
			text_start_x - TEXT_PADDING_X,
			hl_y - 1,
			editor_w + TEXT_PADDING_X,
			LINE_HEIGHT,
			COLOR_LINE_HIGHLIGHT
		);
	}

	// Text & selection
	sz sel_start = math::min(editor.cursor_pos, editor.sel_anchor);
	sz sel_end   = math::max(editor.cursor_pos, editor.sel_anchor);
	bool has_sel = sel_start != sel_end;

	int start_line = math::clamp(editor.scroll_line, 0, math::max(0, total_lines - 1));
	int end_line   = math::min(total_lines, start_line + visible_lines + 1);

	sz start_pos = editor.get_line_start_of_line(start_line);
	sz end_pos   = editor.get_line_start_of_line(end_line);

	int cur_line = start_line;
	int cur_col  = 0;

	// Line lexing buffers & state tracking for rendering
	int active_lex_line   = -1;
	TokenType[1024] dummy_toks;
	TokenType[] line_tokens;
	sz cur_line_start_pos =  0;
	sz cur_line_len       =  0;

	GapBufferIterator iter = editor.buffer.iterator(start_pos, end_pos);
	while (iter.has_next())
	{
		if (cur_line != active_lex_line)
		{
			active_lex_line = cur_line;
			cur_line_start_pos = editor.get_line_start_of_line(cur_line);
			sz line_end_pos = editor.get_line_end(cur_line_start_pos);
			cur_line_len = line_end_pos - cur_line_start_pos;

			LineState line_start_state = (cur_line == 0) ? LineState.NORMAL
				: ((sz)cur_line - 1 < editor.line_states.len() ? editor.line_states[(sz)cur_line - 1]
					: LineState.NORMAL);

			line_tokens = (cur_line_len <= 1024) ? dummy_toks[:cur_line_len]
				: alloc::alloc_array(tmem, TokenType, cur_line_len);

			lex_line(&editor.buffer, cur_line_start_pos, line_end_pos, line_start_state, line_tokens);
		}

		sz i     = iter.byte_pos();
		Char32 c = iter.next()!!;

		int rel_line = cur_line - editor.scroll_line;
		int rel_col  = cur_col - editor.scroll_col;

		bool is_visible = rel_line >= 0 && rel_line < visible_lines;

		int px = text_start_x + rel_col * CHAR_WIDTH;
		int py = text_start_y + rel_line * LINE_HEIGHT;

		bool is_selected = has_sel && (i >= sel_start && i < sel_end);

		TokenType token_type = DEFAULT;
		if (i >= cur_line_start_pos && (i - cur_line_start_pos) < cur_line_len)
		{
			token_type = line_tokens[i - cur_line_start_pos];
		}

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
				if (is_visible && px + CHAR_WIDTH >= text_start_x && px < width)
				{
					if (is_selected)
					{
						rl::draw_rectangle(px, py, CHAR_WIDTH, CHAR_HEIGHT + SELECTION_PADDING_Y, COLOR_SELECTION_BG);
						draw_char(c, px, py, FONT_SCALE, COLOR_TEXT_BRIGHT);
					}
					else
					{
						draw_char(c, px, py, FONT_SCALE, token_type.color);
					}
				}
				cur_col++;
		}
	}

	// Cursor
	if (editor.cursor_visible && active_rel_line >= 0 && active_rel_line < visible_lines)
	{
		int cx = text_start_x + (ccol - editor.scroll_col) * CHAR_WIDTH;
		int cy = text_start_y + active_rel_line * LINE_HEIGHT;
		rl::draw_rectangle(cx, cy, CURSOR_WIDTH, CHAR_HEIGHT + CURSOR_EXTRA_HEIGHT, COLOR_CURSOR);
	}

	rl::end_scissor_mode();

	// Dynamic Gutter & Line Numbers
	rl::draw_rectangle(0, HEADER_HEIGHT, gutter_width - GUTTER_BORDER_W, editor_h, COLOR_GUTTER_BG);
	rl::draw_rectangle(gutter_width - GUTTER_BORDER_W, HEADER_HEIGHT, GUTTER_BORDER_W, editor_h, COLOR_GUTTER_BORDER);

	for (int l = 0; l < visible_lines; l++)
	{
		int line_idx = l + editor.scroll_line;
		if (line_idx >= total_lines) break;

		int gy       = text_start_y + l * LINE_HEIGHT;
		RLColor gcol = (line_idx == cline) ? COLOR_ACCENT_BLUE : COLOR_TEXT_MUTED;
		char[32] gbuf;
		String gs    = string::bformat(&gbuf, "%d", line_idx + 1);
		int text_w   = gs.len * CHAR_WIDTH;
		int draw_x   = gutter_width - GUTTER_BORDER_W - GUTTER_PADDING_RIGHT - text_w;
		draw_text(gs, draw_x, gy, FONT_SCALE, gcol);
	}

	// Go-To-Line Modal Dialog Box
	if (editor.goto_modal_open)
	{
		int modal_w = 320;
		int modal_h = 90;
		int modal_x = (width - modal_w) / 2;
		int modal_y = (height - modal_h) / 3;

		rl::draw_rectangle(modal_x - 4, modal_y - 4, modal_w + 8, modal_h + 8, COLOR_GUTTER_BORDER);
		rl::draw_rectangle(modal_x, modal_y, modal_w, modal_h, COLOR_HEADER_BG);

		draw_text("GO TO LINE:", modal_x + 16, modal_y + 16, FONT_SCALE, COLOR_ACCENT_BLUE);

		rl::draw_rectangle(modal_x + 16, modal_y + 44, modal_w - 32, 30, COLOR_BG);
		rl::draw_rectangle_lines(modal_x + 16, modal_y + 44, modal_w - 32, 30, COLOR_GUTTER_BORDER);

		String inp_str = (String)editor.goto_input_buf[:editor.goto_input_len];
		draw_text(inp_str, modal_x + 24, modal_y + 50, FONT_SCALE, COLOR_TEXT_BRIGHT);

		if (editor.cursor_visible)
		{
			int cur_x = modal_x + 24 + editor.goto_input_len * CHAR_WIDTH;
			rl::draw_rectangle(cur_x, modal_y + 50, CURSOR_WIDTH, CHAR_HEIGHT, COLOR_CURSOR);
		}
	}

	// Footer Bar
	int footer_y      = height - FOOTER_HEIGHT;
	int footer_text_y = footer_y + (FOOTER_HEIGHT - CHAR_HEIGHT) / 2;
	rl::draw_rectangle(0, footer_y, width, FOOTER_HEIGHT, COLOR_FOOTER_BG);

	// Left: File path, Save status, Undo count
	char[128] left_buf;
	String file_disp = editor.current_filepath.len > 0 ? editor.current_filepath : "untitled.c3";
	String mod_str   = editor.is_modified ? " [+]" : "";
	String save_str  = (editor.save_msg_timer > 0.0f) ? " [SAVED]" : "";
	String left_s = string::bformat(
		&left_buf,
		"%s%s%s   UNDO: %d",
		file_disp,
		mod_str,
		save_str,
		editor.undo_stack.len()
	);
	draw_text(left_s, 12, footer_text_y, FONT_SCALE, COLOR_TEXT_BRIGHT);

	// Middle: Badges
	int mid_x = width / 2 - 120;
	if (editor.shift_held)
	{
		draw_text("[SHIFT]", mid_x, footer_text_y, FONT_SCALE, COLOR_ACCENT_GREEN);
		mid_x += 8 * CHAR_WIDTH;
	}
	if (editor.ctrl_held)
	{
		draw_text("[CTRL]", mid_x, footer_text_y, FONT_SCALE, COLOR_ACCENT_BLUE);
		mid_x += 7 * CHAR_WIDTH;
	}
	sz sel_count = editor.cursor_pos > editor.sel_anchor ? editor.cursor_pos - editor.sel_anchor
		: editor.sel_anchor - editor.cursor_pos;
	if (sel_count > 0)
	{
		char[32] sel_buf;
		String sel_s = string::bformat(&sel_buf, "SEL: %d", sel_count);
		draw_text(sel_s, mid_x, footer_text_y, FONT_SCALE, COLOR_ACCENT_YELLOW);
	}

	// Right: Position LN/COL & Document stats
	char[128] right_buf;
	String right_s = string::bformat(
		&right_buf,
		"LN: %d  COL: %d   LINES: %d  CHARS: %d",
		cline + 1,
		ccol + 1,
		total_lines,
		editor.buffer.len()
	);
	int right_w = right_s.len * CHAR_WIDTH;
	draw_text(right_s, width - right_w - 12, footer_text_y, FONT_SCALE, COLOR_HEADER_MUTED);

	rl::end_drawing();
}

fn int main(String[] args) @winmain
{
	if (args.len > 1)
	{
		editor.current_filepath = args[1];
		editor.is_file_specified = true;
	}
	else
	{
		editor.current_filepath = "untitled.c3";
		editor.is_file_specified = false;
	}

	// rl::set_trace_log_level(RLTraceLogLevel.WARNING);
	rl::set_config_flags(RLConfigFlag.WINDOW_RESIZABLE);
	rl::init_window(1600, 900, "C3 Text Editor - C3 & Raylib");

	$if env::WASM:
		emscripten_set_main_loop(&update_draw_frame, 60, 1);
	$else
		rl::set_target_fps(60);
		while (!rl::window_should_close() && !editor.should_exit)
		{
			update_draw_frame();
		}
		rl::close_window();
	$endif

	return 0;
}

// Stub GLFW joystick callback to bypass Raylib's /dev/input scan on Linux startup
// This makes the start faster
// needs the linker flag `-z "-Wl,--allow-multiple-definition"`
// fn void glfwSetJoystickCallback(void* cb) @cname("glfwSetJoystickCallback") @export @feat(!WASM) {}

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
