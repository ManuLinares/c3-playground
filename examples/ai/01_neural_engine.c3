// Choose your model asset.
// @asset: https://huggingface.co/karpathy/tinyllamas/resolve/main/stories15M.bin -> resources/stories.bin

// https://huggingface.co/karpathy/tinyllamas/resolve/main/stories15M.bin
// https://huggingface.co/karpathy/tinyllamas/resolve/main/stories42M.bin
// https://huggingface.co/karpathy/tinyllamas/resolve/main/stories110M.bin

// @asset: https://raw.githubusercontent.com/karpathy/llama2.c/master/tokenizer.bin -> resources/tokenizer.bin
// @asset: https://raw.githubusercontent.com/ManuLinares/c3ed/refs/heads/main/dep/IntoneMonoNerdFontMono-Regular.ttf.gz -> /dep/IntoneMonoNerdFontMono-Regular.ttf.gz

module main;

import std, raylib6;

const String MODEL_PATH     = "resources/stories.bin";
const String TOKENIZER_PATH = "resources/tokenizer.bin";

// STORY PRESETS
enum PresetStory : int (String label, String prompt)
{
	MAGIC_GARDEN  { "1. Magic Garden",  "One day, Lily found a little silver key in the garden." },
	TINY_ROBOT    { "2. Tiny Robot",    "Timmy built a tiny robot out of old tin cans." },
	LOST_PUPPY    { "3. Lost Puppy",    "Max was walking in the park when he heard a soft whimpering." },
	BIRTHDAY_CAKE { "4. Birthday Cake", "Sara and Ben wanted the last slice of chocolate cake." },
	STAR_SHIP     { "5. Star Ship",     "Leo looked through his telescope and saw a glowing star." },
	SECRET_CAVE   { "6. Secret Cave",   "Deep inside the mountain, the dragon was feeling lonely." }
}

const int SCREEN_WIDTH  = 1024;
const int SCREEN_HEIGHT = 640;
const int MAX_SEQ_LEN   = 2048;

constdef Color : inline RLColor
{
	BG_DARK        = { 10, 14, 23, 255 },
	PANEL_BG       = { 17, 24, 39, 255 },
	PANEL_HEADER   = { 24, 33, 53, 255 },
	PANEL_BORDER   = { 38, 50, 72, 255 },
	ACCENT_CYAN    = { 34, 211, 238, 255 },
	ACCENT_GREEN   = { 52, 211, 153, 255 },
	ACCENT_ORANGE  = { 251, 146, 60, 255 },
	ACCENT_PURPLE  = { 192, 132, 252, 255 },
	TEXT_BRIGHT    = { 248, 250, 252, 255 },
	TEXT_MUTED     = { 156, 163, 175, 255 },
	TEXT_DIM       = { 85, 98, 120, 255 },
	BTN_BG         = { 22, 30, 48, 255 },
	BTN_HOVER      = { 35, 48, 76, 255 },
	SELECTION_BG   = { 3, 105, 161, 200 },
	WHITE          = { 255, 255, 255, 255 }
}

constdef FontSize : inline int
{
	SM = 13,
	MD = 16,
	LG = 20
}

int[512] active_codepoints;
int active_codepoint_count = 0;

fn void init_codepoints()
{
	if (active_codepoint_count > 0) return;
	for (int i = 32; i <= 126; i++) active_codepoints[active_codepoint_count++] = i;
	for (int i = 160; i <= 255; i++) active_codepoints[active_codepoint_count++] = i;
	for (int i = 0x0100; i <= 0x017F; i++) active_codepoints[active_codepoint_count++] = i;
	for (int i = 0x2010; i <= 0x2027; i++) active_codepoints[active_codepoint_count++] = i;
	active_codepoints[active_codepoint_count++] = 0x2192;
	active_codepoints[active_codepoint_count++] = 0x00BB;
}

struct AppFont
{
	RLFont font_lg;
	RLFont font_md;
	RLFont font_sm;
	bool is_loaded;
	int char_w_sm;
	int char_w_md;
	int char_w_lg;
}

AppFont app_font;

fn void AppFont.init(&self)
{
	String[*] candidate_paths = {
		"/dep/IntoneMonoNerdFontMono-Regular.ttf.gz",
		"dep/IntoneMonoNerdFontMono-Regular.ttf.gz",
		"resources/IntoneMonoNerdFontMono-Regular.ttf.gz"
	};

	char[]? gz_data;
	foreach (path : candidate_paths)
	{
		if (file::exists(path))
		{
			gz_data = file::load(tmem, path);
			if (try gz_data) break;
		}
	}

	if (try gz = gz_data)
	{
		char[]? raw_ttf = gzip::uncompress_bytes(mem, gz);
		if (try ttf = raw_ttf)
		{
			defer mem::free(ttf);
			init_codepoints();

			self.font_lg = rl::load_font_from_memory(".ttf".zstr_tcopy(), ttf.ptr, ttf.len, FontSize.LG, &active_codepoints, active_codepoint_count);
			self.font_md = rl::load_font_from_memory(".ttf".zstr_tcopy(), ttf.ptr, ttf.len, FontSize.MD, &active_codepoints, active_codepoint_count);
			self.font_sm = rl::load_font_from_memory(".ttf".zstr_tcopy(), ttf.ptr, ttf.len, FontSize.SM, &active_codepoints, active_codepoint_count);

			if (self.font_md.texture.id > 0)
			{
				self.font_lg.texture.set_filter(RLTextureFilter.BILINEAR);
				self.font_md.texture.set_filter(RLTextureFilter.BILINEAR);
				self.font_sm.texture.set_filter(RLTextureFilter.BILINEAR);
				self.is_loaded = true;

				RLVector2 m_lg = rl::measure_text_ex(self.font_lg, "M", FontSize.LG, 0.0f);
				RLVector2 m_md = rl::measure_text_ex(self.font_md, "M", FontSize.MD, 0.0f);
				RLVector2 m_sm = rl::measure_text_ex(self.font_sm, "M", FontSize.SM, 0.0f);

				self.char_w_lg = m_lg.x > 0.0f ? (int)math::round(m_lg.x) : 12;
				self.char_w_md = m_md.x > 0.0f ? (int)math::round(m_md.x) : 10;
				self.char_w_sm = m_sm.x > 0.0f ? (int)math::round(m_sm.x) : 8;
			}
		}
	}
	if (!self.is_loaded)
	{
		self.char_w_lg = 12;
		self.char_w_md = 10;
		self.char_w_sm = 8;
	}
}

fn void AppFont.free(&self)
{
	if (self.is_loaded)
	{
		rl::unload_font(self.font_lg);
		rl::unload_font(self.font_md);
		rl::unload_font(self.font_sm);
		self.is_loaded = false;
	}
	*self = {};
}

fn RLFont AppFont.get_font(&self, FontSize size) @inline =>
	size == LG ? self.font_lg : (size == SM ? self.font_sm : self.font_md);

fn int AppFont.get_char_width(&self, FontSize size) @inline =>
	size == LG ? self.char_w_lg : (size == SM ? self.char_w_sm : self.char_w_md);

fn void AppFont.draw_text(&self, String text, int x, int y, FontSize size, RLColor color)
{
	if (text.len == 0) return;
	if (self.is_loaded)
	{
		RLFont f = self.get_font(size);
		rl::draw_text_ex(f, text.zstr_tcopy(), { x, y }, f.base_size, 0.0f, color);
	}
	else
	{
		rl::draw_text(text.zstr_tcopy(), x, y, size, color);
	}
}

fn int AppFont.measure_text(&self, String text, FontSize size)
{
	if (text.len == 0) return 0;
	if (self.is_loaded)
	{
		return (int)math::round(rl::measure_text_ex(self.get_font(size), text.zstr_tcopy(), size, 0.0f).x);
	}
	return rl::measure_text(text.zstr_tcopy(), size);
}

fn void ui_panel(int x, int y, int w, int h, String title, RLColor title_col = Color.TEXT_MUTED)
{
	rl::draw_rectangle(x, y, w, h, Color.PANEL_BG);
	rl::draw_rectangle_lines(x, y, w, h, Color.PANEL_BORDER);
	rl::draw_rectangle(x, y, w, 26, Color.PANEL_HEADER);
	rl::draw_line(x, y + 26, x + w, y + 26, Color.PANEL_BORDER);
	app_font.draw_text(title, x + 12, y + 7, SM, title_col);
}

macro bool ui_button(int x, int y, int w, int h, String label, RLColor border_col, FontSize size = SM)
{
	RLVector2 mp = rl::get_mouse_position();
	bool hovered = mp.x >= x && mp.x <= (float)(x + w) && mp.y >= y && mp.y <= (float)(y + h);
	rl::draw_rectangle(x, y, w, h, hovered ? Color.BTN_HOVER : Color.BTN_BG);
	rl::draw_rectangle_lines(x, y, w, h, hovered ? Color.WHITE : border_col);
	int text_w = app_font.measure_text(label, size);
	app_font.draw_text(label, x + (w - text_w) / 2, y + (h - size) / 2, size, hovered ? Color.WHITE : border_col);
	return hovered && rl::is_mouse_button_pressed(LEFT);
}

struct ConfigHeader
{
	int dim;
	int hidden_dim;
	int n_layers;
	int n_heads;
	int n_kv_heads;
	int vocab_size;
	int seq_len;
}

struct TransformerWeights
{
	float[] token_embedding_table,
	rms_att_weight, wq, wk, wv, wo,
	rms_ffn_weight, w1, w2, w3,
	rms_final_weight,
	wcls;
}

struct RunState
{
	float[] x,
	xb, xb2,
	hb, hb2,
	q, k, v,
	att,
	logits,
	key_cache,
	value_cache;
}

fn void RunState.init(&self, ConfigHeader* cfg)
{
	sz dim        = (sz)cfg.dim;
	sz hidden_dim = (sz)cfg.hidden_dim;
	sz kv_dim     = (sz)((cfg.dim * cfg.n_kv_heads) / cfg.n_heads);
	sz kv_cache   = (sz)cfg.n_layers * (sz)cfg.seq_len * kv_dim;

	self.x           = mem::new_array(float, dim);
	self.xb          = mem::new_array(float, dim);
	self.xb2         = mem::new_array(float, dim);
	self.hb          = mem::new_array(float, hidden_dim);
	self.hb2         = mem::new_array(float, hidden_dim);
	self.q           = mem::new_array(float, dim);
	self.k           = mem::new_array(float, kv_dim);
	self.v           = mem::new_array(float, kv_dim);
	self.att         = mem::new_array(float, (sz)cfg.n_heads * (sz)cfg.seq_len);
	self.logits      = mem::new_array(float, (sz)cfg.vocab_size);
	self.key_cache   = mem::new_array(float, kv_cache);
	self.value_cache = mem::new_array(float, kv_cache);
}

fn void RunState.free(&self)
{
	$foreach $field : RunState::members:
		mem::free(self.$field);
	$endforeach
	*self = {};
}

struct CandidateProb
{
	int token_id;
	float prob;
	String piece;
}

struct Transformer
{
	ConfigHeader config;
	TransformerWeights weights;
	RunState state;
	char[] raw_data;
	bool loaded;
	CandidateProb[5] top_candidates;
	float[8] head_activations;
}

struct Tokenizer
{
	String[] vocab;
	float[] vocab_scores;
	uint max_token_length;
	int vocab_size;
	char[] raw_data;
	HashMap{String, int} token_map;
	bool loaded;
}

macro float[] @take_slice(#ptr, sz count)
{
	float[] slice = #ptr[0:count];
	#ptr += count;
	return slice;
}

fn void rmsnorm(float[] out, float[] x, float[] weight, int size)
{
	float ss = 0.0f;
	foreach (v : x[:size]) ss += v * v;
	float inv_ss = 1.0f / math::sqrt((ss / size) + 1e-5f);
	foreach (i, &o : out[:size]) *o = x[i] * weight[i] * inv_ss;
}

fn void matmul(float[] out, float[] x, float[] w, int n, int d)
{
	for (int i = 0; i < n; i++)
	{
		float val = 0.0f;
		float[] w_row = w[i * d : d];
		foreach (j, w_val : w_row)
		{
			val += w_val * x[j];
		}
		out[i] = val;
	}
}

fn void softmax(float[] x, int size)
{
	if (size <= 0) return;
	float[] slice = x[:size];

	float max_val = slice[0];
	foreach (v : slice[1..]) if (v > max_val) max_val = v;

	float sum = 0.0f;
	foreach (&v : slice)
	{
		*v = math::exp(*v - max_val);
		sum += *v;
	}

	float inv_sum = 1.0f / sum;
	foreach (&v : slice) *v *= inv_sum;
}

fn void apply_rope(float[] vec, int num_heads, int head_size, int pos)
{
	for (int h = 0; h < num_heads; h++)
	{
		int offset = h * head_size;
		for (int i = 0; i < head_size; i += 2)
		{
			float v0 = vec[offset + i];
			float v1 = vec[offset + i + 1];
			float val = pos / math::pow(10000.0f, (float)i / head_size);
			float[<2>] sc = math::sincos(val);
			float[<2>] rotated = { v0 * sc.y - v1 * sc.x, v0 * sc.x + v1 * sc.y };
			vec[offset + i : 2] = rotated[..];
		}
	}
}

fn void vector_add_inplace(float[] dst, float[] src, int size)
{
	foreach (i, &d : dst[:size]) *d += src[i];
}

fn void Transformer.forward(&self, int token, int pos)
{
	ConfigHeader* p = &self.config;
	TransformerWeights* w = &self.weights;
	RunState* s = &self.state;

	int dim = p.dim;
	int hidden_dim = p.hidden_dim;
	int head_size = dim / p.n_heads;
	int kv_dim = (p.dim * p.n_kv_heads) / p.n_heads;
	int kv_mul = p.n_heads / p.n_kv_heads;

	s.x[:dim] = w.token_embedding_table[token * dim : dim];

	for (int l = 0; l < p.n_layers; l++)
	{
		rmsnorm(s.xb, s.x, w.rms_att_weight[l * dim : dim], dim);

		matmul(s.q, s.xb, w.wq[l * dim * dim : dim * dim], dim, dim);
		matmul(s.k, s.xb, w.wk[l * dim * kv_dim : dim * kv_dim], kv_dim, dim);
		matmul(s.v, s.xb, w.wv[l * dim * kv_dim : dim * kv_dim], kv_dim, dim);

		apply_rope(s.q, p.n_heads, head_size, pos);
		apply_rope(s.k, p.n_kv_heads, head_size, pos);

		int loff = l * p.seq_len * kv_dim + pos * kv_dim;
		s.key_cache[loff : kv_dim] = s.k[:kv_dim];
		s.value_cache[loff : kv_dim] = s.v[:kv_dim];

		for (int h = 0; h < p.n_heads; h++)
		{
			int q_off = h * head_size;
			int att_off = h * p.seq_len;
			int kv_head_idx = h / kv_mul;

			for (int t = 0; t <= pos; t++)
			{
				int k_off = l * p.seq_len * kv_dim + t * kv_dim + kv_head_idx * head_size;
				float score = 0.0f;
				for (int i = 0; i < head_size; i++) score += s.q[q_off + i] * s.key_cache[k_off + i];
				s.att[att_off + t] = score / math::sqrt((float)head_size);
			}

			softmax(s.att[att_off : pos + 1], pos + 1);

			int xb_off = h * head_size;
			s.xb[xb_off : head_size] = 0.0f;

			for (int t = 0; t <= pos; t++)
			{
				int v_off = l * p.seq_len * kv_dim + t * kv_dim + kv_head_idx * head_size;
				float a = s.att[att_off + t];
				for (int i = 0; i < head_size; i++) s.xb[xb_off + i] += a * s.value_cache[v_off + i];
			}

			if (h < 8 && l == p.n_layers - 1) self.head_activations[h] = s.att[att_off + pos];
		}

		matmul(s.xb2, s.xb, w.wo[l * dim * dim : dim * dim], dim, dim);
		vector_add_inplace(s.x, s.xb2, dim);

		rmsnorm(s.xb, s.x, w.rms_ffn_weight[l * dim : dim], dim);
		matmul(s.hb, s.xb, w.w1[l * dim * hidden_dim : dim * hidden_dim], hidden_dim, dim);
		matmul(s.hb2, s.xb, w.w3[l * dim * hidden_dim : dim * hidden_dim], hidden_dim, dim);

		foreach (i, &h1 : s.hb[:hidden_dim])
		{
			float h2 = s.hb2[i];
			*h1 = (*h1 / (1.0f + math::exp(-*h1))) * h2;
		}

		matmul(s.xb, s.hb, w.w2[l * hidden_dim * dim : hidden_dim * dim], dim, hidden_dim);
		vector_add_inplace(s.x, s.xb, dim);
	}

	rmsnorm(s.x, s.x, w.rms_final_weight, dim);
	matmul(s.logits, s.x, w.wcls, p.vocab_size, dim);
}

fn bool Transformer.load_model(&self, String filename)
{
	char[]? data_opt = file::load(mem, filename);
	if (catch data_opt) return false;
	self.raw_data = data_opt;
	if (self.raw_data.len < ConfigHeader::size) return false;

	mem::copy(&self.config, self.raw_data.ptr, ConfigHeader::size);
	bool shared_weights = self.config.vocab_size > 0;
	if (self.config.vocab_size < 0) self.config.vocab_size = -self.config.vocab_size;
	if (self.config.seq_len <= 0) self.config.seq_len = 256;

	sz dim = (sz)self.config.dim;
	sz hidden_dim = (sz)self.config.hidden_dim;
	sz n_layers = (sz)self.config.n_layers;
	sz head_size = (sz)(self.config.dim / self.config.n_heads);
	sz kv_dim = (sz)((self.config.dim * self.config.n_kv_heads) / self.config.n_heads);

	float* ptr = (float*)(self.raw_data.ptr + ConfigHeader::size);

	self.weights.token_embedding_table = @take_slice(ptr, (sz)self.config.vocab_size * dim);
	self.weights.rms_att_weight        = @take_slice(ptr, n_layers * dim);
	self.weights.wq                    = @take_slice(ptr, n_layers * dim * dim);
	self.weights.wk                    = @take_slice(ptr, n_layers * dim * kv_dim);
	self.weights.wv                    = @take_slice(ptr, n_layers * dim * kv_dim);
	self.weights.wo                    = @take_slice(ptr, n_layers * dim * dim);
	self.weights.rms_ffn_weight        = @take_slice(ptr, n_layers * dim);
	self.weights.w1                    = @take_slice(ptr, n_layers * dim * hidden_dim);
	self.weights.w2                    = @take_slice(ptr, n_layers * hidden_dim * dim);
	self.weights.w3                    = @take_slice(ptr, n_layers * dim * hidden_dim);
	self.weights.rms_final_weight      = @take_slice(ptr, dim);
	ptr += (sz)self.config.seq_len * head_size;

	self.weights.wcls = shared_weights ? self.weights.token_embedding_table : @take_slice(ptr, (sz)self.config.vocab_size * dim);

	self.state.init(&self.config);

	self.loaded = true;
	return true;
}

fn void Transformer.free(&self)
{
	if (self.raw_data.len > 0) mem::free(self.raw_data.ptr);
	self.state.free();
	*self = {};
}

fn bool Tokenizer.load_tokenizer(&self, String filename, int vocab_size)
{
	char[]? data_opt = file::load(mem, filename);
	if (catch data_opt) return false;
	self.raw_data = data_opt;
	self.vocab_size = vocab_size;
	if (self.raw_data.len < 4) return false;

	char* ptr = self.raw_data.ptr;
	char* end_ptr = ptr + self.raw_data.len;

	mem::copy(&self.max_token_length, ptr, 4);
	ptr += 4;

	self.vocab = mem::new_array(String, (sz)vocab_size);
	self.vocab_scores = mem::new_array(float, (sz)vocab_size);
	self.token_map.init(mem, (sz)vocab_size * 2);

	for (int i = 0; i < vocab_size && ptr + 8 <= end_ptr; i++)
	{
		mem::copy(&self.vocab_scores[i], ptr, 4);
		int len;
		mem::copy(&len, ptr + 4, 4);
		ptr += 8;

		if (len > 0 && ptr + len <= end_ptr)
		{
			self.vocab[i] = ((String)ptr[0:len]).copy(mem);
			self.token_map.set(self.vocab[i], i);
			ptr += len;
		}
		else
		{
			self.vocab[i] = "";
		}
	}
	self.loaded = true;
	return true;
}

fn void Tokenizer.free(&self)
{
	foreach (word : self.vocab) mem::free(word);
	mem::free(self.vocab);
	mem::free(self.vocab_scores);
	self.token_map.free();
	mem::free(self.raw_data);
	*self = {};
}

fn int Tokenizer.encode_step(&self, String text, Allocator allocator, List{int}* out_tokens)
{
	out_tokens.push(1);
	for (sz i = 0; i < text.len; i++)
	{
		int id = self.token_map.get(text[i:1]) ?? (text[i] + 3);
		out_tokens.push(id);
	}

	while (out_tokens.len() >= 2)
	{
		float best_score = -1e10f;
		int best_id = -1;
		sz best_idx = 0;

		for (sz i = 0; i + 1 < out_tokens.len(); i++)
		{
			String merged = string::tformat("%s%s", self.vocab[(*out_tokens)[i]], self.vocab[(*out_tokens)[i + 1]]);
			if (try id = self.token_map.get(merged))
			{
				if (self.vocab_scores[id] > best_score)
				{
					best_score = self.vocab_scores[id];
					best_id = id;
					best_idx = i;
				}
			}
		}
		if (best_id == -1) break;
		(*out_tokens)[best_idx] = best_id;
		out_tokens.remove_at(best_idx + 1);
	}
	return (int)out_tokens.len();
}

fn int[] Tokenizer.encode(&self, String text, Allocator allocator)
{
	List{int} tokens;
	tokens.init(allocator, (sz)text.len + 4);
	self.encode_step(text, allocator, &tokens);
	return tokens.array_view();
}

fn String sanitize_piece(String piece, Allocator allocator = tmem)
{
	switch
	{
		case piece.len == 0: return "";
		case piece == "<0x0A>": return "\n";
		case piece.contains("<s>") || piece.contains("</s>") || piece.contains("<unk>"): return "";
		case piece.contains("\xe2\x96\x81"): return piece.replace(allocator, "\xe2\x96\x81", " ");
		default: return piece;
	}
}

struct Sampler
{
	float temperature;
	Sfc64Random rng;
}

fn void Sampler.init(&self, ulong seed = 0)
{
	self.temperature = 0.8f;
	if (seed != 0)
	{
		self.rng.set_seed(@as_char_view(seed));
	}
	else
	{
		random::seed_entropy(&self.rng);
	}
}

fn void Sampler.update_top_candidates(&self, Transformer* model, Tokenizer* tokenizer)
{
	float[] logits = model.state.logits;
	int vocab_size = model.config.vocab_size;

	float[] temp_logits = mem::temp_array(float, (sz)vocab_size);
	if (self.temperature > 0.0f)
	{
		float inv_temp = 1.0f / self.temperature;
		foreach (i, &v : temp_logits) *v = logits[i] * inv_temp;
	}
	else
	{
		temp_logits[..] = logits[..];
	}
	softmax(temp_logits, vocab_size);

	for (int c = 0; c < 5; c++)
	{
		int best_i = -1;
		float best_p = -1.0f;
		for (int i = 0; i < vocab_size; i++)
		{
			bool chosen = false;
			for (int prev = 0; prev < c; prev++)
			{
				if (model.top_candidates[prev].token_id == i) { chosen = true; break; }
			}
			if (!chosen && temp_logits[i] > best_p)
			{
				best_p = temp_logits[i];
				best_i = i;
			}
		}
		if (best_i != -1)
		{
			model.top_candidates[c] = { best_i, best_p, tokenizer.vocab[best_i] };
		}
	}
}

fn int Sampler.sample(&self, Transformer* model)
{
	float[] logits = model.state.logits;
	int vocab_size = model.config.vocab_size;

	if (self.temperature == 0.0f)
	{
		int max_i = 0;
		for (int i = 1; i < vocab_size; i++) if (logits[i] > logits[max_i]) max_i = i;
		return max_i;
	}

	float[] temp_logits = mem::temp_array(float, (sz)vocab_size);
	float inv_temp = 1.0f / self.temperature;
	foreach (i, &v : temp_logits) *v = logits[i] * inv_temp;
	softmax(temp_logits, vocab_size);

	float coin = random::next_float(&self.rng);
	float cdf = 0.0f;
	for (int i = 0; i < vocab_size; i++)
	{
		cdf += temp_logits[i];
		if (coin <= cdf) return i;
	}
	return vocab_size - 1;
}

struct AppState
{
	Transformer model;
	Tokenizer tokenizer;
	Sampler sampler;

	DString output_stream;
	int current_token;
	int current_pos;
	int[] prompt_tokens;
	List{int} history_tokens;

	bool is_generating;
	bool is_paused;
	float tokens_per_second;
	int generated_count;
	Clock gen_start_clock;

	int selected_prompt_idx;
	bool max_speed_mode;
	float gen_accumulator;

	int scroll_line;
	bool auto_scroll;

	bool is_selecting;
	int sel_start_line;
	int sel_start_char;
	int sel_end_line;
	int sel_end_char;
	float copied_toast_timer;
}

AppState app;

fn void AppState.init(&self)
{
	self.sampler.init();
	self.output_stream.init(mem, 1024 * 64);
	self.history_tokens.init(mem, 1024);
	self.auto_scroll = true;
	self.max_speed_mode = true;

	if (self.model.load_model(MODEL_PATH) &&
		self.tokenizer.load_tokenizer(TOKENIZER_PATH, self.model.config.vocab_size))
	{
		self.reset_to_prompt(PresetStory::values[0].prompt);
	}
}

fn void AppState.free(&self)
{
	self.model.free();
	self.tokenizer.free();
	self.output_stream.free();
	self.history_tokens.free();
	mem::free(self.prompt_tokens);
	*self = {};
}

fn void AppState.set_temperature(&self, float new_temp)
{
	self.sampler.temperature = math::clamp(new_temp, 0.0f, 2.0f);
	self.sampler.update_top_candidates(&self.model, &self.tokenizer);
}

fn void AppState.adjust_temperature(&self, float delta)
{
	self.set_temperature(self.sampler.temperature + delta);
}

fn void AppState.select_preset(&self, int idx)
{
	if (idx >= 0 && idx < (int)PresetStory::len)
	{
		self.selected_prompt_idx = idx;
		self.reset_to_prompt(PresetStory::values[idx].prompt);
	}
}

fn void AppState.reset_to_prompt(&self, String prompt_text) => @pool()
{
	if (!self.model.loaded || !self.tokenizer.loaded) return;

	mem::free(self.prompt_tokens);
	self.output_stream.clear();
	self.history_tokens.clear();
	self.current_pos = 0;
	self.generated_count = 0;
	self.gen_start_clock = clock::now();
	self.scroll_line = 0;
	self.auto_scroll = true;
	self.is_selecting = false;

	self.prompt_tokens = self.tokenizer.encode(prompt_text, mem);
	foreach (tok : self.prompt_tokens) self.history_tokens.push(tok);

	for (sz i = 0; i < self.prompt_tokens.len; i++)
	{
		int tok = self.prompt_tokens[i];
		self.model.forward(tok, (int)i);
		if (i > 0) self.output_stream.append_string(sanitize_piece(self.tokenizer.vocab[tok]));
	}

	self.current_pos = (int)self.prompt_tokens.len - 1;
	self.current_token = self.prompt_tokens[^1];

	self.sampler.update_top_candidates(&self.model, &self.tokenizer);
	self.is_generating = true;
	self.is_paused = false;
}

fn void AppState.step_token(&self) => @pool()
{
	if (!self.model.loaded || self.current_pos >= self.model.config.seq_len - 1)
	{
		self.is_generating = false;
		return;
	}

	int next_token = self.sampler.sample(&self.model);
	self.history_tokens.push(next_token);
	self.output_stream.append_string(sanitize_piece(self.tokenizer.vocab[next_token]));

	self.current_token = next_token;
	self.current_pos++;
	self.generated_count++;

	self.model.forward(self.current_token, self.current_pos);
	self.sampler.update_top_candidates(&self.model, &self.tokenizer);

	NanoDuration elapsed = self.gen_start_clock.to_now();
	double elapsed_sec = elapsed.to_sec();
	if (elapsed_sec > 0.05) self.tokens_per_second = (float)(self.generated_count / elapsed_sec);
	if (next_token == 2) self.is_generating = false;
}

fn void AppState.step_backward(&self) => @pool()
{
	if (!self.model.loaded || self.current_pos <= self.prompt_tokens.len - 1) return;

	self.is_paused = true;
	(void)self.history_tokens.pop();
	self.current_pos--;
	self.current_token = self.history_tokens[self.current_pos];
	if (self.generated_count > 0) self.generated_count--;

	self.output_stream.clear();
	for (sz i = 1; i < self.history_tokens.len(); i++)
	{
		self.output_stream.append_string(sanitize_piece(self.tokenizer.vocab[self.history_tokens[i]]));
	}

	self.model.forward(self.current_token, self.current_pos);
	self.sampler.update_top_candidates(&self.model, &self.tokenizer);
	self.is_selecting = false;
	self.auto_scroll = true;
}

fn void AppState.step_generation(&self, float dt)
{
	if (!self.is_generating || self.is_paused || !self.model.loaded) return;

	if (self.max_speed_mode)
	{
		for (int i = 0; i < 2 && self.is_generating && !self.is_paused; i++) self.step_token();
	}
	else
	{
		self.gen_accumulator += dt;
		if (self.gen_accumulator >= 0.016f)
		{
			self.step_token();
			self.gen_accumulator = 0.0f;
		}
	}
}

fn List{String} wrap_text(String text, int max_chars, Allocator allocator = tmem)
{
	List{String} lines;
	lines.tinit(128);
	if (text.len == 0) { lines.push(""); return lines; }

	Splitter split = text.tokenize_all("\n");
	while (try para = split.next())
	{
		if (para.len == 0) { lines.push(""); continue; }
		sz start = 0;
		while (start < para.len)
		{
			if (para.len - start <= (sz)max_chars)
			{
				lines.push(para[start..].copy(allocator));
				break;
			}
			sz limit = start + (sz)max_chars;
			sz break_pos = limit;
			while (break_pos > start && para[break_pos] != ' ') break_pos--;

			if (break_pos == start)
			{
				lines.push(para[start:max_chars].copy(allocator));
				start += (sz)max_chars;
			}
			else
			{
				lines.push(para[start : break_pos - start].copy(allocator));
				start = break_pos + 1;
			}
		}
	}
	return lines;
}

fn List{String} AppState.get_wrapped_lines(&self, int inner_w, Allocator allocator = tmem)
{
	int char_w = app_font.get_char_width(MD);
	int max_chars = math::max(20, inner_w / math::max(1, char_w));
	return wrap_text(self.output_stream.str_view(), max_chars, allocator);
}

fn String format_candidate_piece(CandidateProb cand, Allocator allocator = tmem)
{
	String piece = cand.piece;
	switch
	{
		case cand.token_id == 1: piece = "[BOS]";
		case cand.token_id == 2 || piece == "</s>": piece = "[EOS]";
		case piece == "<0x0A>" || piece == "\n": piece = "[ENTER]";
		case piece == " " || piece == "\xe2\x96\x81": piece = "[SPACE]";
		default:
			String clean = sanitize_piece(piece, allocator);
			piece = clean.starts_with(" ") ? string::tformat("_%s", clean[1..]) : clean;
	}
	return piece.len > 10 ? piece[:10] : piece;
}

fn void draw_dashboard() => @pool()
{
	rl::draw_rectangle(0, 0, SCREEN_WIDTH, 44, Color.PANEL_BG);
	rl::draw_line(0, 44, SCREEN_WIDTH, 44, Color.PANEL_BORDER);

	app_font.draw_text("[C3 NEURAL CORE]", 16, 12, LG, Color.ACCENT_ORANGE);

	String model_title = "LLAMA-2 TRANSFORMER";
	if (app.model.loaded)
	{
		switch (app.model.config.dim)
		{
			case 64:  model_title = "LLAMA-2 260K TRANSFORMER";
			case 288: model_title = "LLAMA-2 15M TRANSFORMER";
			case 512: model_title = "LLAMA-2 42M TRANSFORMER";
			case 768: model_title = "LLAMA-2 110M TRANSFORMER";
			default:  model_title = string::tformat("LLAMA-2 (DIM %d, L%d) TRANSFORMER", app.model.config.dim, app.model.config.n_layers);
		}
	}
	app_font.draw_text(model_title, 205, 12, LG, Color.ACCENT_CYAN);

	RLColor status_col = app.is_paused ? Color.ACCENT_ORANGE : (app.is_generating ? Color.ACCENT_GREEN : Color.TEXT_MUTED);
	app_font.draw_text(app.is_paused ? "[PAUSED]" : (app.is_generating ? "[GENERATING]" : "[COMPLETED]"), 580, 14, MD, status_col);
	app_font.draw_text(string::tformat("%.1f tok/s", app.tokens_per_second), 740, 14, MD, Color.ACCENT_PURPLE);
	app_font.draw_text(string::tformat("Pos: %d/%d", app.current_pos + 1, app.model.loaded ? app.model.config.seq_len : 256), 890, 14, MD, Color.TEXT_MUTED);

	int term_x = 16;
	int term_y = 54;
	int term_w = 630;
	int term_h = 530;

	ui_panel(term_x, term_y, term_w, term_h, "TERMINAL // LIVE STORY OUTPUT STREAM", Color.TEXT_MUTED);

	int pad_x = 14;
	int text_start_x = term_x + pad_x;
	int text_start_y = term_y + 36;
	int inner_w = term_w - (pad_x * 2);
	int visible_h = term_h - 44;

	rl::begin_scissor_mode(term_x + 4, term_y + 30, term_w - 8, visible_h + 8);

	int char_w = app_font.get_char_width(MD);
	int line_h = (int)FontSize.MD + 4;

	List{String} lines = app.get_wrapped_lines(inner_w, tmem);
	int max_vis = visible_h / line_h;
	int max_scroll = math::max(0, (int)lines.len() - max_vis);

	app.scroll_line = app.auto_scroll ? max_scroll : math::clamp(app.scroll_line, 0, max_scroll);

	int s_start = math::min(app.sel_start_line, app.sel_end_line);
	int s_end   = math::max(app.sel_start_line, app.sel_end_line);
	bool has_sel = (app.sel_start_line != app.sel_end_line || app.sel_start_char != app.sel_end_char);

	for (int i = 0; i < max_vis && (app.scroll_line + i) < (int)lines.len(); i++)
	{
		int l_idx = app.scroll_line + i;
		String l = lines[l_idx];
		int py = text_start_y + i * line_h;

		if (has_sel && l_idx >= s_start && l_idx <= s_end)
		{
			int c_start = (l_idx == s_start) ? math::min(app.sel_start_char, app.sel_end_char) : 0;
			int c_end   = (l_idx == s_end) ? math::max(app.sel_start_char, app.sel_end_char) : (int)l.len;
			c_start = math::clamp(c_start, 0, (int)l.len);
			c_end   = math::clamp(c_end, 0, (int)l.len);
			if (c_end > c_start)
			{
				rl::draw_rectangle(text_start_x + c_start * char_w, py - 1, (c_end - c_start) * char_w, line_h, Color.SELECTION_BG);
			}
		}
		if (l.len > 0) app_font.draw_text(l, text_start_x, py, MD, Color.TEXT_BRIGHT);
	}

	if (((int)(rl::get_time() * 3.0)) % 2 == 0 && app.is_generating)
	{
		int rel_line = (int)lines.len() - 1 - app.scroll_line;
		if (rel_line >= 0 && rel_line < max_vis)
		{
			int last_len = (int)lines[^1].len;
			rl::draw_rectangle(text_start_x + last_len * char_w + 2, text_start_y + rel_line * line_h + 2, 7, (int)FontSize.MD - 2, Color.ACCENT_CYAN);
		}
	}
	rl::end_scissor_mode();

	if (app.copied_toast_timer > 0.0f)
	{
		app.copied_toast_timer -= rl::get_frame_time();
		rl::draw_rectangle(term_x + term_w - 230, term_y + 3, 220, 20, Color.ACCENT_GREEN);
		app_font.draw_text("COPIED TO CLIPBOARD!", term_x + term_w - 215, term_y + 7, SM, Color.BG_DARK);
	}

	int right_x = 660;
	int right_w = 348;

	int cand_y = 54;
	int cand_h = 195;
	ui_panel(right_x, cand_y, right_w, cand_h, "TOP CANDIDATES // NEXT TOKEN LOGITS", Color.ACCENT_CYAN);

	for (int i = 0; i < 5; i++)
	{
		CandidateProb cand = app.model.top_candidates[i];
		int bar_y = cand_y + 34 + i * 31;
		String piece = format_candidate_piece(cand, tmem);

		app_font.draw_text(piece, right_x + 12, bar_y + 3, MD, Color.TEXT_MUTED);
		int fill_w = (int)(cand.prob * 135.0f);
		rl::draw_rectangle(right_x + 120, bar_y + 2, 135, 16, Color.BG_DARK);
		rl::draw_rectangle(right_x + 120, bar_y + 2, math::clamp(fill_w, 2, 135), 16, i == 0 ? Color.ACCENT_GREEN : Color.ACCENT_CYAN);
		app_font.draw_text(string::tformat("%5.1f%%", cand.prob * 100.0f), right_x + 265, bar_y + 3, MD, Color.TEXT_MUTED);
	}

	int attn_y = 258;
	int attn_h = 100;
	int total_layers = app.model.loaded ? app.model.config.n_layers : 6;
	ui_panel(right_x, attn_y, right_w, attn_h, string::tformat("MULTI-HEAD ATTENTION // LAYER %d", total_layers), Color.ACCENT_PURPLE);

	int heads_to_draw = app.model.loaded ? math::min(6, app.model.config.n_heads) : 6;
	for (int h = 0; h < heads_to_draw; h++)
	{
		int gx = right_x + 16 + h * 54;
		int fill_h = (int)(math::clamp(app.model.head_activations[h] * 2.5f, 0.05f, 1.0f) * 40.0f);
		rl::draw_rectangle(gx, attn_y + 34, 42, 42, Color.BG_DARK);
		rl::draw_rectangle(gx + 2, attn_y + 34 + (40 - fill_h), 38, fill_h, Color.ACCENT_PURPLE);
		app_font.draw_text(string::tformat("H%d", h + 1), gx + 12, attn_y + 78, SM, Color.TEXT_DIM);
	}

	int ctrl_y = 366;
	int ctrl_h = 218;
	ui_panel(right_x, ctrl_y, right_w, ctrl_h, "GENERATION CONTROLS & PRESETS", Color.ACCENT_ORANGE);

	app_font.draw_text(string::tformat("Temp: %.2f", app.sampler.temperature), right_x + 12, ctrl_y + 34, SM, Color.TEXT_MUTED);
	if (ui_button(right_x + 105, ctrl_y + 32, 22, 20, "-", Color.PANEL_BORDER)) app.adjust_temperature(-0.05f);
	if (ui_button(right_x + 130, ctrl_y + 32, 22, 20, "+", Color.PANEL_BORDER)) app.adjust_temperature(0.05f);
	if (ui_button(right_x + 158, ctrl_y + 32, 34, 20, "0.0", Color.PANEL_BORDER)) app.set_temperature(0.0f);
	if (ui_button(right_x + 196, ctrl_y + 32, 34, 20, "0.7", Color.PANEL_BORDER)) app.set_temperature(0.7f);
	if (ui_button(right_x + 240, ctrl_y + 32, 98, 20, app.max_speed_mode ? "Speed: MAX" : "Speed: 60", app.max_speed_mode ? Color.ACCENT_CYAN : Color.PANEL_BORDER))
	{
		app.max_speed_mode = !app.max_speed_mode;
	}

	int btn_y = ctrl_y + 60;
	if (ui_button(right_x + 12, btn_y, 80, 26, app.is_paused ? "RESUME" : "PAUSE", app.is_paused ? Color.ACCENT_GREEN : Color.ACCENT_ORANGE))
	{
		app.is_paused = !app.is_paused;
	}
	if (ui_button(right_x + 98, btn_y, 74, 26, "< BACK", Color.ACCENT_ORANGE)) app.step_backward();
	if (ui_button(right_x + 178, btn_y, 74, 26, "STEP >", Color.ACCENT_PURPLE))
	{
		app.is_paused = true;
		app.step_token();
	}
	if (ui_button(right_x + 258, btn_y, 78, 26, "RESTART", Color.ACCENT_CYAN))
	{
		app.select_preset(app.selected_prompt_idx);
	}

	app_font.draw_text("STORY PROMPT PRESETS:", right_x + 12, ctrl_y + 96, SM, Color.TEXT_MUTED);

	foreach (int idx, preset : PresetStory::values)
	{
		int px = right_x + 12 + (idx % 2) * 164;
		int py = ctrl_y + 114 + (idx / 2) * 32;
		bool sel = (app.selected_prompt_idx == idx);

		if (ui_button(px, py, 158, 28, preset.label, sel ? Color.ACCENT_CYAN : Color.PANEL_BORDER))
		{
			app.select_preset(idx);
		}
	}

	rl::draw_rectangle(0, SCREEN_HEIGHT - 46, SCREEN_WIDTH, 46, Color.PANEL_BG);
	rl::draw_line(0, SCREEN_HEIGHT - 46, SCREEN_WIDTH, SCREEN_HEIGHT - 46, Color.PANEL_BORDER);
	app_font.draw_text(
		app.model.loaded ? "Shortcuts: [SPACE] Pause/Resume  |  [<- / ->] Step Back/Fwd  |  [1-6] Story Presets  |  [R] Restart  |  [-/+] Temp"
		                 : string::tformat("LOADING MODEL WEIGHTS (%s) & TOKENIZER...", MODEL_PATH),
		16, SCREEN_HEIGHT - 28, SM, app.model.loaded ? Color.TEXT_MUTED : Color.ACCENT_ORANGE
	);
}

fn bool key_pressed_or_repeat(RLKeyboardKey key) =>
	rl::is_key_pressed(key) || rl::is_key_pressed_repeat(key);

fn void handle_inputs() => @pool()
{
	if (rl::is_key_pressed(SPACE)) app.is_paused = !app.is_paused;
	if (rl::is_key_pressed(ESCAPE)) app.is_selecting = false;

	if (key_pressed_or_repeat(RIGHT) || key_pressed_or_repeat(S))
	{
		app.is_paused = true;
		app.step_token();
	}
	if (key_pressed_or_repeat(LEFT)) app.step_backward();

	if (key_pressed_or_repeat(MINUS) || key_pressed_or_repeat(KP_SUBTRACT)) app.adjust_temperature(-0.05f);
	if (key_pressed_or_repeat(EQUAL) || key_pressed_or_repeat(KP_ADD))      app.adjust_temperature(0.05f);

	if (key_pressed_or_repeat(R)) app.select_preset(app.selected_prompt_idx);

	foreach (int idx, preset : PresetStory::values)
	{
		if (key_pressed_or_repeat((RLKeyboardKey)((int)RLKeyboardKey.ONE + idx)))
		{
			app.select_preset(idx);
		}
	}

	RLVector2 mp = rl::get_mouse_position();

	if (mp.x >= 16.0f && mp.x <= 646.0f && mp.y >= 54.0f && mp.y <= 584.0f)
	{
		float wheel = rl::get_mouse_wheel_move();
		if (wheel != 0.0f)
		{
			List{String} lines = app.get_wrapped_lines(630 - 28, tmem);
			int max_scroll = math::max(0, (int)lines.len() - (486 / (FontSize.MD + 4)));

			if (wheel > 0.0f)
			{
				app.scroll_line = math::max(0, app.scroll_line - (int)wheel * 3);
				app.auto_scroll = (app.scroll_line >= max_scroll);
			}
			else
			{
				app.scroll_line = math::min(max_scroll, app.scroll_line - (int)wheel * 3);
				if (app.scroll_line >= max_scroll) app.auto_scroll = true;
			}
		}
	}

	int text_start_x = 30;
	int text_start_y = 90;
	int char_w = app_font.get_char_width(MD);
	int line_h = FontSize.MD + 4;

	if (mp.x >= (float)text_start_x && mp.x <= 640.0f && mp.y >= (float)text_start_y && mp.y <= 570.0f)
	{
		int clicked_line = math::max(0, (int)(mp.y - (float)text_start_y) / line_h + app.scroll_line);
		int clicked_col  = math::max(0, (int)(mp.x - (float)text_start_x) / char_w);

		if (rl::is_mouse_button_pressed(LEFT))
		{
			app.is_selecting = true;
			app.sel_start_line = clicked_line;
			app.sel_start_char = clicked_col;
			app.sel_end_line   = clicked_line;
			app.sel_end_char   = clicked_col;
		}
		else if (app.is_selecting && rl::is_mouse_button_down(LEFT))
		{
			app.sel_end_line = clicked_line;
			app.sel_end_char = clicked_col;
		}
	}

	if (app.is_selecting && rl::is_mouse_button_released(LEFT))
	{
		app.is_selecting = false;
		if (app.sel_start_line != app.sel_end_line || app.sel_start_char != app.sel_end_char)
		{
			List{String} lines = app.get_wrapped_lines(630 - 28, tmem);
			int s_line = math::min(app.sel_start_line, app.sel_end_line);
			int e_line = math::max(app.sel_start_line, app.sel_end_line);

			if (s_line < (int)lines.len())
			{
				DString copied;
				copied.tinit();
				for (int l = s_line; l <= e_line && l < (int)lines.len(); l++)
				{
					String line_str = lines[l];
					int c_start = math::clamp((l == s_line) ? math::min(app.sel_start_char, app.sel_end_char) : 0, 0, (int)line_str.len);
					int c_end   = math::clamp((l == e_line) ? math::max(app.sel_start_char, app.sel_end_char) : (int)line_str.len, 0, (int)line_str.len);
					if (c_end > c_start) copied.append(line_str[c_start : c_end - c_start]);
					if (l < e_line) copied.append_char('\n');
				}
				if (copied.len() > 0)
				{
					rl::set_clipboard_text(copied.str_view().zstr_tcopy());
					app.copied_toast_timer = 2.0f;
				}
			}
		}
	}
}

fn void update_draw_frame() => @pool()
{
	handle_inputs();
	app.step_generation(rl::get_frame_time());

	rl::@drawing()
	{
		rl::clear_background(Color.BG_DARK);
		draw_dashboard();
	};
}

fn int main(String[] args) @winmain
{
	$if !env::WASM:
		rl::set_config_flags(WINDOW_RESIZABLE | MSAA_4X_HINT);
	$endif

	rl::init_window(SCREEN_WIDTH, SCREEN_HEIGHT, "C3 Neural Engine - Llama-2 Transformer");
	app_font.init();
	app.init();

	$if env::WASM:
		emscripten_set_main_loop(&update_draw_frame, 0, 1);
	$else
		rl::set_target_fps(60);
		while (!rl::window_should_close()) update_draw_frame();
		app.free();
		app_font.free();
		rl::close_window();
	$endif

	return 0;
}

alias EmCallbackFunc = fn void();
extern fn void emscripten_set_main_loop(EmCallbackFunc func, int fps, int simulate_infinite_loop) @feat(WASM);