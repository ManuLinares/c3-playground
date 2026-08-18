module app;
import std, raylib6;

fn bool is_word_char(char c) => c.is_alnum() || c == '_';
fn bool is_symbol_char(char c) => !is_word_char(c) && c != '\n' && c != '\r' && c != ' ';

fn BytePos get_prev_char_pos(PieceTable* pt, BytePos pos)
{
	if (pos == 0) return 0;
	BytePos len = pt.len();
	BytePos p   = math::min(pos, len) - 1;
	while (p > 0 && (pt.get(p) & 0xC0) == 0x80) p--;
	return p;
}

fn BytePos get_next_char_pos(PieceTable* pt, BytePos pos)
{
	BytePos len = pt.len();
	if (pos >= len) return len;
	BytePos p = pos + 1;
	while (p < len && (pt.get(p) & 0xC0) == 0x80) p++;
	return p;
}

fn BytePos get_prev_word_pos(PieceTable* pt, BytePos pos)
{
	if (pos == 0) return 0;
	BytePos p = pos;
	while (p > 0 && !is_word_char(pt.get(p - 1))) p--;
	while (p > 0 && is_word_char(pt.get(p - 1))) p--;
	return p;
}

fn BytePos get_next_word_pos(PieceTable* pt, BytePos pos)
{
	BytePos len = pt.len();
	if (pos >= len) return len;
	BytePos p = pos;
	while (p < len && !is_word_char(pt.get(p))) p++;
	while (p < len && is_word_char(pt.get(p))) p++;
	return p;
}

fn TextRange get_word_bounds(PieceTable* pt, BytePos pos)
{
	BytePos len = pt.len();
	if (len == 0) return { 0, 0 };

	BytePos p = math::min(pos, len - 1);
	char c    = pt.get(p);

	switch
	{
		case is_word_char(c):
			BytePos start = p;
			while (start > 0 && is_word_char(pt.get(start - 1))) start--;
			BytePos end = p;
			while (end < len && is_word_char(pt.get(end))) end++;
			return { start, end };
		case c == '\n' || c == '\r':
			return { p, p };
		default:
			BytePos start = p;
			while (start > 0 && is_symbol_char(pt.get(start - 1))) start--;
			BytePos end = p;
			while (end < len && is_symbol_char(pt.get(end))) end++;
			if (start == end) end = math::min(start + 1, len);
			return { start, end };
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
	TabDocument* tab = self.active_tab();
	DString tmp;
	tmp.tinit();
	foreach (&cur : tab.cursors)
	{
		if (cur.has_selection())
		{
			if (tmp.len() > 0) tmp.append_char('\n');
			tab.table.append_range_to_dstring(&tmp, cur.sel_start(), cur.sel_end());
		}
	}
	if (tmp.len() > 0)
	{
		set_clipboard(tmp.zstr_view());
	}
}

fn void Editor.cut_selection(&self)
{
	self.copy_selection();
	self.delete_selection();
}

fn void Editor.paste_clipboard(&self)
{
	TabDocument* tab = self.active_tab();
	ZString clip     = rl::get_clipboard_text();
	if (clip == null) return;
	String text = clip.str_view();
	if (text.len == 0) return;

	tab.table.begin_transaction(&tab.cursors);
	sort::quicksort(&tab.cursors, fn int (Cursor a, Cursor b) => compare_cursors(&a, &b));

	for (sz k = tab.cursors.len(); k > 0; k--)
	{
		sz i        = k - 1;
		Cursor* cur = &tab.cursors[i];
		BytePos s   = cur.sel_start();
		BytePos e   = cur.sel_end();
		BytePos del = e - s;

		if (del > 0)
		{
			tab.table.replace_range(s, e, (char[])text);
		}
		else
		{
			tab.table.insert_bytes(s, (char[])text);
		}
		self.update_line_index_on_edit(s, del, text.len);
		cur.pos = s + text.len;
		cur.anchor = cur.pos;
		cur.target_col = self.get_col(cur.pos);

		sz delta = text.len - del;
		if (delta != 0)
		{
			for (sz j = i + 1; j < tab.cursors.len(); j++)
			{
				tab.cursors[j].pos += delta;
				tab.cursors[j].anchor += delta;
			}
		}
	}
	self.normalize_cursors();
	tab.table.end_transaction(&tab.cursors);
	tab.is_modified = true;
}

fn void Editor.delete_selection(&self)
{
	TabDocument* tab = self.active_tab();
	tab.table.begin_transaction(&tab.cursors);
	sort::quicksort(&tab.cursors, fn int (Cursor a, Cursor b) => compare_cursors(&a, &b));

	for (sz k = tab.cursors.len(); k > 0; k--)
	{
		sz i        = k - 1;
		Cursor* cur = &tab.cursors[i];
		if (!cur.has_selection()) continue;

		BytePos s   = cur.sel_start();
		BytePos e   = cur.sel_end();
		BytePos del = e - s;

		tab.table.delete_range(s, e);
		self.update_line_index_on_edit(s, del, 0);

		cur.pos = s;
		cur.anchor = s;
		cur.target_col = self.get_col(cur.pos);

		for (sz j = i + 1; j < tab.cursors.len(); j++)
		{
			tab.cursors[j].pos -= del;
			tab.cursors[j].anchor -= del;
		}
	}
	self.normalize_cursors();
	tab.table.end_transaction(&tab.cursors);
	tab.is_modified = true;
}

fn void Editor.insert_codepoint(&self, Char32 c)
{
	TabDocument* tab = self.active_tab();
	if (c == '\n')
	{
		self.handle_enter();
		return;
	}

	char close_pair = '\0';
	switch (c)
	{
		case '(': close_pair = ')';
		case '[': close_pair = ']';
		case '{': close_pair = '}';
		case '"': close_pair = '"';
		case '\'': close_pair = '\'';
		default: break;
	}

	char[4] buf;
	sz len = conv::char32_to_utf8(c, &buf) ?? 0;
	if (len == 0) return;

	tab.table.begin_transaction(&tab.cursors);
	sort::quicksort(&tab.cursors, fn int (Cursor a, Cursor b) => compare_cursors(&a, &b));

	for (sz k = tab.cursors.len(); k > 0; k--)
	{
		sz i        = k - 1;
		Cursor* cur = &tab.cursors[i];

		if (!cur.has_selection() && cur.pos < tab.table.len())
		{
			char next_c = tab.table.get(cur.pos);
			if ((c == ')' && next_c == ')') || (c == ']' && next_c == ']') || (c == '}' && next_c == '}')
				|| (c == '"' && next_c == '"')
				|| (c == '\'' && next_c == '\''))
			{
				cur.pos = get_next_char_pos(&tab.table, cur.pos);
				cur.anchor = cur.pos;
				cur.target_col = self.get_col(cur.pos);
				continue;
			}
		}

		BytePos start_sel = cur.sel_start();
		BytePos end_sel   = cur.sel_end();
		BytePos del_len   = end_sel - start_sel;
		sz delta          = 0;

		if (del_len > 0)
		{
			if (close_pair != '\0')
			{
				char[2] pair_buf = { (char)c, close_pair };
				tab.table.replace_range(start_sel, end_sel, pair_buf[:2]);
				self.update_line_index_on_edit(start_sel, del_len, 2);
				cur.pos = start_sel + 1;
				cur.anchor = cur.pos;
				cur.target_col = self.get_col(cur.pos);
				delta = 2 - del_len;
			}
			else
			{
				tab.table.replace_range(start_sel, end_sel, buf[:len]);
				self.update_line_index_on_edit(start_sel, del_len, len);
				cur.pos = start_sel + len;
				cur.anchor = cur.pos;
				cur.target_col = self.get_col(cur.pos);
				delta = len - del_len;
			}
		}
		else
		{
			if (close_pair != '\0')
			{
				char[2] pair_buf = { (char)c, close_pair };
				tab.table.insert_bytes(start_sel, pair_buf[:2]);
				self.update_line_index_on_edit(start_sel, 0, 2);
				cur.pos = start_sel + 1;
				cur.anchor = cur.pos;
				cur.target_col = self.get_col(cur.pos);
				delta = 2;
			}
			else
			{
				tab.table.insert_bytes(start_sel, buf[:len]);
				self.update_line_index_on_edit(start_sel, 0, len);
				cur.pos = start_sel + len;
				cur.anchor = cur.pos;
				cur.target_col = self.get_col(cur.pos);
				delta = len;
			}
		}

		if (delta != 0)
		{
			for (sz j = i + 1; j < tab.cursors.len(); j++)
			{
				tab.cursors[j].pos += delta;
				tab.cursors[j].anchor += delta;
			}
		}
	}

	self.normalize_cursors();
	tab.table.end_transaction(&tab.cursors);
	tab.is_modified = true;
}

fn void Editor.handle_enter(&self)
{
	TabDocument* tab = self.active_tab();
	tab.table.begin_transaction(&tab.cursors);
	sort::quicksort(&tab.cursors, fn int (Cursor a, Cursor b) => compare_cursors(&a, &b));

	for (sz k = tab.cursors.len(); k > 0; k--)
	{
		sz i        = k - 1;
		Cursor* cur = &tab.cursors[i];

		BytePos start_sel = cur.sel_start();
		BytePos end_sel   = cur.sel_end();
		BytePos del_len   = end_sel - start_sel;

		BytePos line_start = self.get_line_start(start_sel);
		BytePos pos        = line_start;
		DString indent;
		indent.tinit();

		while (pos < start_sel)
		{
			char ch = tab.table.get(pos);
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
		if (start_sel > 0 && end_sel < tab.table.len())
		{
			char prev_c = tab.table.get(get_prev_char_pos(&tab.table, start_sel));
			char next_c = tab.table.get(end_sel);
			if (prev_c == '{' && next_c == '}')
			{
				between_braces = true;
			}
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
			if (del_len > 0)
			{
				tab.table.replace_range(start_sel, end_sel, (char[])ins_str);
			}
			else
			{
				tab.table.insert_bytes(start_sel, (char[])ins_str);
			}
			self.update_line_index_on_edit(start_sel, del_len, ins_str.len);

			cur.pos = target_cursor;
			cur.anchor = cur.pos;
			cur.target_col = self.get_col(cur.pos);

			sz delta = ins_str.len - del_len;
			if (delta != 0)
			{
				for (sz j = i + 1; j < tab.cursors.len(); j++)
				{
					tab.cursors[j].pos += delta;
					tab.cursors[j].anchor += delta;
				}
			}
			continue;
		}

		if (start_sel > 0)
		{
			char last_c = tab.table.get(get_prev_char_pos(&tab.table, start_sel));
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
		if (del_len > 0)
		{
			tab.table.replace_range(start_sel, end_sel, (char[])ins_str);
		}
		else
		{
			tab.table.insert_bytes(start_sel, (char[])ins_str);
		}
		self.update_line_index_on_edit(start_sel, del_len, ins_str.len);

		cur.pos = start_sel + ins_str.len;
		cur.anchor = cur.pos;
		cur.target_col = self.get_col(cur.pos);

		sz delta = ins_str.len - del_len;
		if (delta != 0)
		{
			for (sz j = i + 1; j < tab.cursors.len(); j++)
			{
				tab.cursors[j].pos += delta;
				tab.cursors[j].anchor += delta;
			}
		}
	}

	self.normalize_cursors();
	tab.table.end_transaction(&tab.cursors);
	tab.is_modified = true;
}

fn void Editor.handle_backspace(&self)
{
	TabDocument* tab = self.active_tab();
	tab.table.begin_transaction(&tab.cursors);
	sort::quicksort(&tab.cursors, fn int (Cursor a, Cursor b) => compare_cursors(&a, &b));
	bool any_deleted = false;

	for (sz k = tab.cursors.len(); k > 0; k--)
	{
		sz i        = k - 1;
		Cursor* cur = &tab.cursors[i];

		switch
		{
			case cur.has_selection():
				BytePos s = cur.sel_start();
				BytePos e = cur.sel_end();
				BytePos del_len = e - s;

				tab.table.delete_range(s, e);
				self.update_line_index_on_edit(s, del_len, 0);

				cur.pos = s;
				cur.anchor = s;
				cur.target_col = self.get_col(cur.pos);

				for (sz j = i + 1; j < tab.cursors.len(); j++)
				{
					tab.cursors[j].pos -= del_len;
					tab.cursors[j].anchor -= del_len;
				}
				any_deleted = true;

			case cur.pos > 0:
				BytePos prev = get_prev_char_pos(&tab.table, cur.pos);
				BytePos del_len = cur.pos - prev;
				tab.table.delete_range(prev, cur.pos);
				self.update_line_index_on_edit(prev, del_len, 0);

				cur.pos = prev;
				cur.anchor = cur.pos;
				cur.target_col = self.get_col(cur.pos);

				for (sz j = i + 1; j < tab.cursors.len(); j++)
				{
					tab.cursors[j].pos -= del_len;
					tab.cursors[j].anchor -= del_len;
				}
				any_deleted = true;
		}
	}
	if (any_deleted)
	{
		self.normalize_cursors();
		tab.is_modified = true;
	}
	tab.table.end_transaction(&tab.cursors);
}

fn void Editor.handle_delete(&self)
{
	TabDocument* tab = self.active_tab();
	tab.table.begin_transaction(&tab.cursors);
	sort::quicksort(&tab.cursors, fn int (Cursor a, Cursor b) => compare_cursors(&a, &b));
	bool any_deleted = false;

	for (sz k = tab.cursors.len(); k > 0; k--)
	{
		sz i        = k - 1;
		Cursor* cur = &tab.cursors[i];

		switch
		{
			case cur.has_selection():
				BytePos s = cur.sel_start();
				BytePos e = cur.sel_end();
				BytePos del_len = e - s;

				tab.table.delete_range(s, e);
				self.update_line_index_on_edit(s, del_len, 0);

				cur.pos = s;
				cur.anchor = s;
				cur.target_col = self.get_col(cur.pos);

				for (sz j = i + 1; j < tab.cursors.len(); j++)
				{
					tab.cursors[j].pos -= del_len;
					tab.cursors[j].anchor -= del_len;
				}
				any_deleted = true;

			case cur.pos < tab.table.len():
				BytePos next = get_next_char_pos(&tab.table, cur.pos);
				BytePos del_len = next - cur.pos;
				tab.table.delete_range(cur.pos, next);
				self.update_line_index_on_edit(cur.pos, del_len, 0);

				for (sz j = i + 1; j < tab.cursors.len(); j++)
				{
					tab.cursors[j].pos -= del_len;
					tab.cursors[j].anchor -= del_len;
				}
				any_deleted = true;
		}
	}
	if (any_deleted)
	{
		self.normalize_cursors();
		tab.is_modified = true;
	}
	tab.table.end_transaction(&tab.cursors);
}

fn void Editor.duplicate_line(&self)
{
	TabDocument* tab = self.active_tab();
	tab.table.begin_transaction(&tab.cursors);
	Cursor* cur     = self.primary_cursor();
	BytePos l_start = self.get_line_start(cur.pos);
	BytePos l_end   = self.get_line_end(l_start);

	DString line_str;
	line_str.tinit();
	line_str.append_char('\n');
	tab.table.append_range_to_dstring(&line_str, l_start, l_end);

	String text = line_str.str_view();
	tab.table.insert_bytes(l_end, (char[])text);
	self.update_line_index_on_edit(l_end, 0, text.len);

	cur.pos = l_end + text.len;
	cur.anchor = cur.pos;
	cur.target_col = self.get_col(cur.pos);
	tab.is_modified = true;
	tab.table.end_transaction(&tab.cursors);
}

fn void Editor.delete_line(&self)
{
	TabDocument* tab = self.active_tab();
	tab.table.begin_transaction(&tab.cursors);
	Cursor* cur     = self.primary_cursor();
	BytePos l_start = self.get_line_start(cur.pos);
	BytePos l_end   = self.get_line_end(l_start);

	BytePos del_end = l_end;
	if (del_end < tab.table.len())
	{
		switch (tab.table.get(del_end))
		{
			case '\n': del_end++;
			case '\r':
				del_end++;
				if (del_end < tab.table.len() && tab.table.get(del_end) == '\n') del_end++;
			default: break;
		}
	}

	BytePos del_len = del_end - l_start;
	tab.table.delete_range(l_start, del_end);
	self.update_line_index_on_edit(l_start, del_len, 0);

	cur.pos = math::min(l_start, tab.table.len());
	cur.anchor = cur.pos;
	cur.target_col = self.get_col(cur.pos);
	tab.is_modified = true;
	tab.table.end_transaction(&tab.cursors);
}

fn void Editor.move_line_up(&self)
{
	TabDocument* tab = self.active_tab();
	Cursor* cur      = self.primary_cursor();
	int cline        = self.get_line(cur.pos);
	if (cline <= 0) return;

	tab.table.begin_transaction(&tab.cursors);
	BytePos line1_start = self.get_line_start_of_line(cline - 1);
	BytePos line1_end   = self.get_line_end(line1_start);
	BytePos line2_start = self.get_line_start_of_line(cline);
	BytePos line2_end   = self.get_line_end(line2_start);

	DString line1;
	DString line2;
	line1.tinit();
	line2.tinit();
	tab.table.append_range_to_dstring(&line1, line1_start, line1_end);
	tab.table.append_range_to_dstring(&line2, line2_start, line2_end);

	BytePos old_len = line2_end - line1_start;

	DString swapped;
	swapped.tinit();
	swapped.append(line2.str_view());
	swapped.append_char('\n');
	swapped.append(line1.str_view());

	String s = swapped.str_view();
	tab.table.replace_range(line1_start, line2_end, (char[])s);
	self.update_line_index_on_edit(line1_start, old_len, s.len);

	cur.pos = self.get_pos_from_line_col(cline - 1, cur.target_col);
	cur.anchor = cur.pos;
	tab.is_modified = true;
	tab.table.end_transaction(&tab.cursors);
}

fn void Editor.move_line_down(&self)
{
	TabDocument* tab = self.active_tab();
	Cursor* cur      = self.primary_cursor();
	int cline        = self.get_line(cur.pos);
	int tot          = self.get_total_lines();
	if (cline >= tot - 1) return;

	tab.table.begin_transaction(&tab.cursors);
	BytePos line1_start = self.get_line_start_of_line(cline);
	BytePos line1_end   = self.get_line_end(line1_start);
	BytePos line2_start = self.get_line_start_of_line(cline + 1);
	BytePos line2_end   = self.get_line_end(line2_start);

	DString line1;
	DString line2;
	line1.tinit();
	line2.tinit();
	tab.table.append_range_to_dstring(&line1, line1_start, line1_end);
	tab.table.append_range_to_dstring(&line2, line2_start, line2_end);

	BytePos old_len = line2_end - line1_start;

	DString swapped;
	swapped.tinit();
	swapped.append(line2.str_view());
	swapped.append_char('\n');
	swapped.append(line1.str_view());

	String s = swapped.str_view();
	tab.table.replace_range(line1_start, line2_end, (char[])s);
	self.update_line_index_on_edit(line1_start, old_len, s.len);

	cur.pos = self.get_pos_from_line_col(cline + 1, cur.target_col);
	cur.anchor = cur.pos;
	tab.is_modified = true;
	tab.table.end_transaction(&tab.cursors);
}

fn void Editor.toggle_line_comment(&self)
{
	TabDocument* tab = self.active_tab();
	if (tab.cursors.len() == 0) return;

	List{int} lines;
	lines.tinit(tab.cursors.len() * 4);

	foreach (&cur : tab.cursors)
	{
		int s_line = self.get_line(cur.sel_start());
		int e_line = self.get_line(cur.sel_end());
		if (cur.has_selection() && e_line > s_line && self.get_col(cur.sel_end()) == 0)
		{
			e_line--;
		}
		for (int l = s_line; l <= e_line; l++)
		{
			bool already = false;
			foreach (existing : lines)
			{
				if (existing == l)
				{
					already = true;
					break;
				}
			}
			if (!already) lines.push(l);
		}
	}

	if (lines.len() == 0) return;
	sort::quicksort(&lines, fn int (int a, int b)
	{
		switch
		{
			case a < b: return -1;
			case a > b: return 1;
			default: return 0;
		}
	});

	bool all_commented = true;
	foreach (l : lines)
	{
		BytePos l_start = self.get_line_start_of_line(l);
		BytePos l_end   = self.get_line_end(l_start);
		if (l_end <= l_start) continue;

		BytePos p = l_start;
		while (p < l_end && (tab.table.get(p) == ' ' || tab.table.get(p) == '\t')) p++;

		if (p + 1 >= l_end || tab.table.get(p) != '/' || tab.table.get(p + 1) != '/')
		{
			all_commented = false;
			break;
		}
	}

	tab.table.begin_transaction(&tab.cursors);

	for (sz k = lines.len(); k > 0; k--)
	{
		int l           = lines[k - 1];
		BytePos l_start = self.get_line_start_of_line(l);
		BytePos l_end   = self.get_line_end(l_start);

		BytePos p = l_start;
		while (p < l_end && (tab.table.get(p) == ' ' || tab.table.get(p) == '\t')) p++;

		if (all_commented)
		{
			if (p + 1 < l_end && tab.table.get(p) == '/' && tab.table.get(p + 1) == '/')
			{
				BytePos del_len = (p + 2 < l_end && tab.table.get(p + 2) == ' ') ? 3 : 2;
				tab.table.delete_range(p, p + del_len);
				self.update_line_index_on_edit(p, del_len, 0);

				foreach (&cur : tab.cursors)
				{
					switch
					{
						case cur.pos >= p + del_len: cur.pos -= del_len;
						case cur.pos >= p: cur.pos = p;
					}
					switch
					{
						case cur.anchor >= p + del_len: cur.anchor -= del_len;
						case cur.anchor >= p: cur.anchor = p;
					}
				}
			}
		}
		else
		{
			tab.table.insert_bytes(p, (char[])"// ");
			self.update_line_index_on_edit(p, 0, 3);

			foreach (&cur : tab.cursors)
			{
				if (cur.pos >= p) cur.pos += 3;
				if (cur.anchor >= p) cur.anchor += 3;
			}
		}
	}

	foreach (&cur : tab.cursors)
	{
		cur.target_col = self.get_col(cur.pos);
	}

	self.normalize_cursors();
	tab.table.end_transaction(&tab.cursors);
	tab.is_modified = true;
}

fn void Editor.indent_block(&self, bool outdent)
{
	TabDocument* tab = self.active_tab();
	if (tab.cursors.len() == 0) return;

	List{int} lines;
	lines.tinit(tab.cursors.len() * 4);

	foreach (&cur : tab.cursors)
	{
		int s_line = self.get_line(cur.sel_start());
		int e_line = self.get_line(cur.sel_end());
		if (cur.has_selection() && e_line > s_line && self.get_col(cur.sel_end()) == 0)
		{
			e_line--;
		}
		for (int l = s_line; l <= e_line; l++)
		{
			bool already = false;
			foreach (existing : lines)
			{
				if (existing == l)
				{
					already = true;
					break;
				}
			}
			if (!already) lines.push(l);
		}
	}

	if (lines.len() == 0) return;
	sort::quicksort(&lines, fn int (int a, int b)
	{
		switch
		{
			case a < b: return -1;
			case a > b: return 1;
			default: return 0;
		}
	});

	tab.table.begin_transaction(&tab.cursors);

	for (sz k = lines.len(); k > 0; k--)
	{
		int l           = lines[k - 1];
		BytePos l_start = self.get_line_start_of_line(l);
		BytePos l_end   = self.get_line_end(l_start);

		if (outdent)
		{
			if (l_start < l_end)
			{
				char ch    = tab.table.get(l_start);
				sz del_len = 0;
				switch (ch)
				{
					case '\t':
						del_len = 1;
					case ' ':
						BytePos p = l_start;
						while (p < l_end && del_len < (sz)TAB_SIZE_SPACES && tab.table.get(p) == ' ')
						{
							del_len++;
							p++;
						}
					default: break;
				}

				if (del_len > 0)
				{
					tab.table.delete_range(l_start, l_start + del_len);
					self.update_line_index_on_edit(l_start, del_len, 0);

					foreach (&cur : tab.cursors)
					{
						int cur_line = self.get_line(cur.pos);
						switch
						{
							case cur_line == l:
								switch
								{
									case cur.pos >= l_start + del_len: cur.pos -= del_len;
									case cur.pos >= l_start: cur.pos = l_start;
								}
							case cur_line > l:
								cur.pos -= del_len;
						}

						int anchor_line = self.get_line(cur.anchor);
						switch
						{
							case anchor_line == l:
								switch
								{
									case cur.anchor >= l_start + del_len: cur.anchor -= del_len;
									case cur.anchor >= l_start: cur.anchor = l_start;
								}
							case anchor_line > l:
								cur.anchor -= del_len;
						}
					}
				}
			}
		}
		else
		{
			tab.table.insert_bytes(l_start, (char[])"\t");
			self.update_line_index_on_edit(l_start, 0, 1);

			foreach (&cur : tab.cursors)
			{
				int cur_line = self.get_line(cur.pos);
				if (cur_line >= l)
				{
					cur.pos += 1;
				}

				int anchor_line = self.get_line(cur.anchor);
				if (anchor_line >= l)
				{
					cur.anchor += 1;
				}
			}
		}
	}

	foreach (&cur : tab.cursors)
	{
		cur.target_col = self.get_col(cur.pos);
	}

	self.normalize_cursors();
	tab.table.end_transaction(&tab.cursors);
	tab.is_modified = true;
}

fn void Editor.convert_case_selection(&self, bool to_upper)
{
	TabDocument* tab = self.active_tab();
	tab.table.begin_transaction(&tab.cursors);
	sort::quicksort(&tab.cursors, fn int (Cursor a, Cursor b) => compare_cursors(&a, &b));

	for (sz k = tab.cursors.len(); k > 0; k--)
	{
		sz i        = k - 1;
		Cursor* cur = &tab.cursors[i];
		if (!cur.has_selection()) continue;

		BytePos start = cur.sel_start();
		BytePos end   = cur.sel_end();
		BytePos span  = end - start;

		DString str;
		str.tinit();
		tab.table.append_range_to_dstring(&str, start, end);
		String text = str.str_view();

		char[] modified = alloc::alloc_array(tmem, char, text.len);
		for (sz j = 0; j < text.len; j++)
		{
			char c = text[j];
			modified[j] = to_upper ? c.to_upper() : c.to_lower();
		}

		tab.table.replace_range(start, end, modified);
		self.update_line_index_on_edit(start, span, modified.len);

		cur.pos = start + modified.len;
		cur.anchor = start;
		cur.target_col = self.get_col(cur.pos);

		sz delta = modified.len - span;
		if (delta != 0)
		{
			for (sz j = i + 1; j < tab.cursors.len(); j++)
			{
				tab.cursors[j].pos += delta;
				tab.cursors[j].anchor += delta;
			}
		}
	}
	self.normalize_cursors();
	tab.table.end_transaction(&tab.cursors);
	tab.is_modified = true;
}

fn void Editor.jump_to_matching_bracket(&self)
{
	TabDocument* tab = self.active_tab();
	if (tab.table.len() == 0) return;
	Cursor* cur = self.primary_cursor();
	BytePos p   = cur.pos;
	if (p >= tab.table.len()) p = tab.table.len() - 1;

	char c          = tab.table.get(p);
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
				p--;
				c = tab.table.get(p);
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
	BytePos total = tab.table.len();

	if (forward)
	{
		for (BytePos i = p + 1; i < total; i++)
		{
			char ch = tab.table.get(i);
			switch
			{
				case ch == c:
					depth++;
				case ch == match_char:
					depth--;
					if (depth == 0)
					{
						cur.pos = i;
						if (!self.modifiers.shift) cur.anchor = cur.pos;
						cur.target_col = self.get_col(cur.pos);
						return;
					}
			}
		}
	}
	else
	{
		for (BytePos i = p; i > 0; i--)
		{
			char ch = tab.table.get(i - 1);
			switch
			{
				case ch == c:
					depth++;
				case ch == match_char:
					depth--;
					if (depth == 0)
					{
						cur.pos = i - 1;
						if (!self.modifiers.shift) cur.anchor = cur.pos;
						cur.target_col = self.get_col(cur.pos);
						return;
					}
			}
		}
	}
}

fn void Editor.add_cursor_above(&self)
{
	TabDocument* tab = self.active_tab();
	List{Cursor} new_list;
	new_list.tinit(tab.cursors.len() * 2);

	foreach (&cur : tab.cursors)
	{
		new_list.push(*cur);
		int line = self.get_line(cur.pos);
		if (line > 0)
		{
			BytePos new_p = self.get_pos_from_line_col(line - 1, cur.target_col);
			new_list.push({ new_p, new_p, cur.target_col });
		}
	}
	tab.cursors.clear();
	foreach (&cur : new_list) tab.cursors.push(*cur);
	self.normalize_cursors();
}

fn void Editor.add_cursor_below(&self)
{
	TabDocument* tab = self.active_tab();
	List{Cursor} new_list;
	new_list.tinit(tab.cursors.len() * 2);
	int tot = self.get_total_lines();

	foreach (&cur : tab.cursors)
	{
		new_list.push(*cur);
		int line = self.get_line(cur.pos);
		if (line < tot - 1)
		{
			BytePos new_p = self.get_pos_from_line_col(line + 1, cur.target_col);
			new_list.push({ new_p, new_p, cur.target_col });
		}
	}
	tab.cursors.clear();
	foreach (&cur : new_list) tab.cursors.push(*cur);
	self.normalize_cursors();
}

fn void Editor.apply_undo_redo(&self, bool is_undo)
{
	TabDocument* tab = self.active_tab();
	bool success     = is_undo ? tab.table.undo(&tab.cursors) : tab.table.redo(&tab.cursors);
	if (success)
	{
		self.rebuild_line_index();
		self.normalize_cursors();
		tab.is_modified = true;
	}
}

fn void dispatch_command(Editor* ed, EditorCommand cmd, LayoutMetrics* lm, float dt)
{
	TabDocument* tab = ed.active_tab();
	int tot_lines    = ed.get_total_lines();
	bool update_view = false;

	switch (cmd)
	{
		case CMD_NONE:
			return;

		case CMD_NEW_TAB:
			ed.open_new_tab("untitled.c3", false, "");
			update_view = true;

		case CMD_CLOSE_TAB:
			ed.request_close_tab(ed.active_tab_index);
			update_view = true;

		case CMD_NEXT_TAB:
			if (ed.tabs.len() > 1)
			{
				ed.active_tab_index = (ed.active_tab_index + 1) % (int)ed.tabs.len();
				ed.reset_cursor_blink();
			}
			update_view = true;

		case CMD_PREV_TAB:
			if (ed.tabs.len() > 1)
			{
				ed.active_tab_index = (ed.active_tab_index + (int)ed.tabs.len() - 1) % (int)ed.tabs.len();
				ed.reset_cursor_blink();
			}
			update_view = true;

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
			if (target_idx < (int)ed.tabs.len())
			{
				ed.active_tab_index = target_idx;
				ed.reset_cursor_blink();
			}
			update_view = true;

		case CMD_ADD_CURSOR_ABOVE:
			ed.add_cursor_above();
			update_view = true;

		case CMD_ADD_CURSOR_BELOW:
			ed.add_cursor_below();
			update_view = true;

		case CMD_MOVE_LEFT:
			foreach (&cur : tab.cursors)
			{
				BytePos new_pos = cur.pos;
				switch
				{
					case !ed.modifiers.shift && cur.has_selection():
						new_pos = cur.sel_start();
					default:
						new_pos = get_prev_char_pos(&tab.table, cur.pos);
				}
				cur.pos = new_pos;
				if (!ed.modifiers.shift) cur.anchor = cur.pos;
				cur.target_col = ed.get_col(cur.pos);
			}
			ed.normalize_cursors();
			update_view = true;

		case CMD_MOVE_RIGHT:
			foreach (&cur : tab.cursors)
			{
				BytePos new_pos = cur.pos;
				switch
				{
					case !ed.modifiers.shift && cur.has_selection():
						new_pos = cur.sel_end();
					default:
						new_pos = get_next_char_pos(&tab.table, cur.pos);
				}
				cur.pos = new_pos;
				if (!ed.modifiers.shift) cur.anchor = cur.pos;
				cur.target_col = ed.get_col(cur.pos);
			}
			ed.normalize_cursors();
			update_view = true;

		case CMD_MOVE_WORD_LEFT:
			foreach (&cur : tab.cursors)
			{
				cur.pos = get_prev_word_pos(&tab.table, cur.pos);
				if (!ed.modifiers.shift) cur.anchor = cur.pos;
				cur.target_col = ed.get_col(cur.pos);
			}
			ed.normalize_cursors();
			update_view = true;

		case CMD_MOVE_WORD_RIGHT:
			foreach (&cur : tab.cursors)
			{
				cur.pos = get_next_word_pos(&tab.table, cur.pos);
				if (!ed.modifiers.shift) cur.anchor = cur.pos;
				cur.target_col = ed.get_col(cur.pos);
			}
			ed.normalize_cursors();
			update_view = true;

		case CMD_MOVE_UP:
			foreach (&cur : tab.cursors)
			{
				int line = ed.get_line(cur.pos);
				if (line > 0)
				{
					cur.pos = ed.get_pos_from_line_col(line - 1, cur.target_col);
				}
				else
				{
					cur.pos = 0;
					cur.target_col = 0;
				}
				if (!ed.modifiers.shift) cur.anchor = cur.pos;
			}
			ed.normalize_cursors();
			update_view = true;

		case CMD_MOVE_DOWN:
			foreach (&cur : tab.cursors)
			{
				int line = ed.get_line(cur.pos);
				if (line < tot_lines - 1)
				{
					cur.pos = ed.get_pos_from_line_col(line + 1, cur.target_col);
				}
				else
				{
					cur.pos = tab.table.len();
					cur.target_col = ed.get_col(cur.pos);
				}
				if (!ed.modifiers.shift) cur.anchor = cur.pos;
			}
			ed.normalize_cursors();
			update_view = true;

		case CMD_MOVE_LINE_START:
			foreach (&cur : tab.cursors)
			{
				cur.pos = ed.get_line_start(cur.pos);
				if (!ed.modifiers.shift) cur.anchor = cur.pos;
				cur.target_col = ed.get_col(cur.pos);
			}
			ed.normalize_cursors();
			update_view = true;

		case CMD_MOVE_LINE_END:
			foreach (&cur : tab.cursors)
			{
				cur.pos = ed.get_line_end(cur.pos);
				if (!ed.modifiers.shift) cur.anchor = cur.pos;
				cur.target_col = ed.get_col(cur.pos);
			}
			ed.normalize_cursors();
			update_view = true;

		case CMD_MOVE_FILE_START:
			tab.cursors.clear();
			tab.cursors.push({ 0, 0, 0 });
			update_view = true;

		case CMD_MOVE_FILE_END:
			tab.cursors.clear();
			BytePos end_p = tab.table.len();
			tab.cursors.push({ end_p, end_p, ed.get_col(end_p) });
			update_view = true;

		case CMD_PAGE_UP:
			int step_multiplier = 1 + math::clamp((int)(ed.page_hold_timer * 5.0f), 0, 10);
			int move_lines = lm.visible_lines * step_multiplier;
			foreach (&cur : tab.cursors)
			{
				int l = math::max(0, ed.get_line(cur.pos) - move_lines);
				cur.pos = ed.get_pos_from_line_col(l, cur.target_col);
				if (!ed.modifiers.shift) cur.anchor = cur.pos;
			}
			ed.normalize_cursors();
			update_view = true;

		case CMD_PAGE_DOWN:
			int step_multiplier_down = 1 + math::clamp((int)(ed.page_hold_timer * 5.0f), 0, 10);
			int move_lines_down = lm.visible_lines * step_multiplier_down;
			foreach (&cur : tab.cursors)
			{
				int l = math::min(tot_lines - 1, ed.get_line(cur.pos) + move_lines_down);
				cur.pos = ed.get_pos_from_line_col(l, cur.target_col);
				if (!ed.modifiers.shift) cur.anchor = cur.pos;
			}
			ed.normalize_cursors();
			update_view = true;

		case CMD_JUMP_MATCHING_BRACKET:
			ed.jump_to_matching_bracket();
			update_view = true;

		case CMD_SELECT_ALL:
			tab.cursors.clear();
			tab.cursors.push({ tab.table.len(), 0, ed.get_col(tab.table.len()) });
			update_view = true;

		case CMD_SELECT_TO_TOP:
			foreach (&cur : tab.cursors)
			{
				cur.pos = 0;
				cur.target_col = 0;
			}
			ed.normalize_cursors();
			update_view = true;

		case CMD_SELECT_TO_BOTTOM:
			foreach (&cur : tab.cursors)
			{
				cur.pos = tab.table.len();
				cur.target_col = ed.get_col(cur.pos);
			}
			ed.normalize_cursors();
			update_view = true;

		case CMD_CLEAR_SELECTION:
			if (tab.cursors.len() > 1)
			{
				Cursor prim = tab.cursors[0];
				tab.cursors.clear();
				tab.cursors.push(prim);
			}
			else
			{
				ed.primary_cursor().anchor = ed.primary_cursor().pos;
			}
			update_view = true;

		case CMD_BACKSPACE:
			ed.handle_backspace();
			update_view = true;

		case CMD_DELETE:
			ed.handle_delete();
			update_view = true;

		case CMD_ENTER:
			ed.handle_enter();
			update_view = true;

		case CMD_INSERT_TAB:
			bool has_any_selection = false;
			foreach (&cur : tab.cursors)
			{
				if (cur.has_selection())
				{
					has_any_selection = true;
					break;
				}
			}
			switch
			{
				case ed.modifiers.shift:
					ed.indent_block(true);
				case has_any_selection:
					ed.indent_block(false);
				default:
					ed.insert_codepoint('\t');
			}
			update_view = true;

		case CMD_INDENT:
			bool has_sel = false;
			foreach (&cur : tab.cursors)
			{
				if (cur.has_selection())
				{
					has_sel = true;
					break;
				}
			}
			switch
			{
				case has_sel:
					ed.indent_block(false);
				default:
					ed.insert_codepoint('\t');
			}
			update_view = true;

		case CMD_OUTDENT:
			ed.indent_block(true);
			update_view = true;

		case CMD_DUPLICATE_LINE:
			ed.duplicate_line();
			update_view = true;

		case CMD_DELETE_LINE:
			ed.delete_line();
			update_view = true;

		case CMD_MOVE_LINE_UP:
			ed.move_line_up();
			update_view = true;

		case CMD_MOVE_LINE_DOWN:
			ed.move_line_down();
			update_view = true;

		case CMD_TOGGLE_COMMENT:
			ed.toggle_line_comment();
			update_view = true;

		case CMD_TO_UPPERCASE:
			ed.convert_case_selection(true);
			update_view = true;

		case CMD_TO_LOWERCASE:
			ed.convert_case_selection(false);
			update_view = true;

		case CMD_COPY:
			ed.copy_selection();

		case CMD_CUT:
			ed.cut_selection();
			update_view = true;

		case CMD_PASTE:
			ed.paste_clipboard();
			update_view = true;

		case CMD_UNDO:
			ed.apply_undo_redo(true);
			update_view = true;

		case CMD_REDO:
			ed.apply_undo_redo(false);
			update_view = true;

		case CMD_OPEN_FIND:
			ed.active_modal = FIND;
			if (ed.primary_cursor().has_selection())
			{
				BytePos s = ed.primary_cursor().sel_start();
				BytePos e = ed.primary_cursor().sel_end();
				if (ed.get_line(s) == ed.get_line(e))
				{
					DString sel_str;
					sel_str.tinit();
					tab.table.append_range_to_dstring(&sel_str, s, e);
					ed.modal_input.set_text(sel_str.str_view());
				}
			}
			ed.modal_focus_field = 0;
			ed.cached_match_count = ed.count_find_matches();

		case CMD_OPEN_REPLACE:
			ed.active_modal = REPLACE;
			if (ed.primary_cursor().has_selection())
			{
				BytePos s = ed.primary_cursor().sel_start();
				BytePos e = ed.primary_cursor().sel_end();
				if (ed.get_line(s) == ed.get_line(e))
				{
					DString sel_str;
					sel_str.tinit();
					tab.table.append_range_to_dstring(&sel_str, s, e);
					ed.modal_input.set_text(sel_str.str_view());
				}
			}
			ed.modal_focus_field = 0;
			ed.cached_match_count = ed.count_find_matches();

		case CMD_FIND_NEXT:
			ed.find_next(false, lm);

		case CMD_FIND_PREV:
			ed.find_next(true, lm);

		case CMD_REPLACE_NEXT:
			ed.replace_next(lm);

		case CMD_REPLACE_ALL:
			ed.replace_all(lm);

		case CMD_OPEN_QUICK_OPEN:
			ed.active_modal = QUICK_OPEN;
			ed.modal_input.clear();
			ed.update_quick_open_results();

		case CMD_OPEN_GLOBAL_GREP:
			ed.active_modal = GLOBAL_GREP;
			ed.modal_input.clear();
			ed.update_search_results();

		case CMD_OPEN_GOTO_LINE:
			ed.active_modal = GOTO_LINE;
			ed.modal_input.clear();

		case CMD_SAVE_FILE:
			if (!tab.is_file_specified)
			{
				ed.active_modal = SAVE_AS;
				ed.modal_input.set_text(tab.filepath);
			}
			else
			{
				file::save(tab.filepath, (char[])tab.table.to_tstring())!!;
				tab.is_modified = false;
				ed.save_msg_timer = 2.0f;
			}

		case CMD_SAVE_AS:
			ed.active_modal = SAVE_AS;
			ed.modal_input.set_text(tab.filepath);

		case CMD_QUIT:
			bool any_modified = false;
			foreach (&t : ed.tabs)
			{
				if (t.is_modified)
				{
					any_modified = true;
					break;
				}
			}
			if (any_modified)
			{
				ed.active_modal = CONFIRM_EXIT;
			}
			else
			{
				ed.should_exit = true;
			}

		case CMD_ZOOM_IN:
			ed.font_scale = math::min(6.0f, ed.font_scale + 0.5f);

		case CMD_ZOOM_OUT:
			ed.font_scale = math::max(1.0f, ed.font_scale - 0.5f);
	}

	if (update_view && !ed.scrollbar_dragging)
	{
		ed.ensure_cursor_visible(lm);
	}
}module app::command;
import std, raylib6;

enum EditorCommand
{
	CMD_NONE,

	// Caret Navigation
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

	// Multi-Cursor
	CMD_ADD_CURSOR_ABOVE,
	CMD_ADD_CURSOR_BELOW,

	// Selection
	CMD_SELECT_ALL,
	CMD_SELECT_TO_TOP,
	CMD_SELECT_TO_BOTTOM,
	CMD_CLEAR_SELECTION,

	// Text & Line Editing
	CMD_INSERT_TAB,
	CMD_INDENT,
	CMD_OUTDENT,
	CMD_BACKSPACE,
	CMD_DELETE,
	CMD_ENTER,
	CMD_DUPLICATE_LINE,
	CMD_DELETE_LINE,
	CMD_MOVE_LINE_UP,
	CMD_MOVE_LINE_DOWN,
	CMD_TOGGLE_COMMENT,
	CMD_TO_UPPERCASE,
	CMD_TO_LOWERCASE,

	// Clipboard & History
	CMD_COPY,
	CMD_CUT,
	CMD_PASTE,
	CMD_UNDO,
	CMD_REDO,

	// Search & Modals
	CMD_OPEN_FIND,
	CMD_OPEN_REPLACE,
	CMD_FIND_NEXT,
	CMD_FIND_PREV,
	CMD_REPLACE_NEXT,
	CMD_REPLACE_ALL,
	CMD_OPEN_QUICK_OPEN,
	CMD_OPEN_GLOBAL_GREP,
	CMD_OPEN_GOTO_LINE,

	// Tab Management
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

	// File & View Operations
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
	RLKeyboardKey key;
	KeyModifiers mods;
	EditorCommand command;
}

const KeyBinding[*] KEYBINDINGS = {
	// Tab Management
	{ T, { .ctrl = true }, CMD_NEW_TAB },
	{ W, { .ctrl = true }, CMD_CLOSE_TAB },
	{ TAB, { .ctrl = true }, CMD_NEXT_TAB },
	{ TAB, { .ctrl = true, .shift = true }, CMD_PREV_TAB },
	{ ONE, { .alt = true }, CMD_TAB_1 },
	{ TWO, { .alt = true }, CMD_TAB_2 },
	{ THREE, { .alt = true }, CMD_TAB_3 },
	{ FOUR, { .alt = true }, CMD_TAB_4 },
	{ FIVE, { .alt = true }, CMD_TAB_5 },
	{ SIX, { .alt = true }, CMD_TAB_6 },
	{ SEVEN, { .alt = true }, CMD_TAB_7 },
	{ EIGHT, { .alt = true }, CMD_TAB_8 },
	{ NINE, { .alt = true }, CMD_TAB_9 },
	// File & Application
	{ S, { .ctrl = true }, CMD_SAVE_FILE },
	{ S, { .ctrl = true, .shift = true }, CMD_SAVE_AS },
	{ Q, { .ctrl = true }, CMD_QUIT },
	// Search & Navigation Modals
	{ F, { .ctrl = true }, CMD_OPEN_FIND },
	{ H, { .ctrl = true }, CMD_OPEN_REPLACE },
	{ F, { .ctrl = true, .shift = true }, CMD_OPEN_GLOBAL_GREP },
	{ P, { .ctrl = true }, CMD_OPEN_QUICK_OPEN },
	{ O, { .ctrl = true }, CMD_OPEN_QUICK_OPEN },
	{ G, { .ctrl = true }, CMD_OPEN_GOTO_LINE },
	{ F3, { }, CMD_FIND_NEXT },
	{ F3, { .shift = true }, CMD_FIND_PREV },
	// History & Clipboard
	{ Z, { .ctrl = true }, CMD_UNDO },
	{ Y, { .ctrl = true }, CMD_REDO },
	{ Z, { .ctrl = true, .shift = true }, CMD_REDO },
	{ C, { .ctrl = true }, CMD_COPY },
	{ X, { .ctrl = true }, CMD_CUT },
	{ V, { .ctrl = true }, CMD_PASTE },
	{ A, { .ctrl = true }, CMD_SELECT_ALL },
	// Multi-Cursor Spawn
	{ UP, { .ctrl = true, .shift = true }, CMD_ADD_CURSOR_ABOVE },
	{ DOWN, { .ctrl = true, .shift = true }, CMD_ADD_CURSOR_BELOW },
	// Line & Selection Operations
	{ D, { .ctrl = true }, CMD_DUPLICATE_LINE },
	{ K, { .ctrl = true, .shift = true }, CMD_DELETE_LINE },
	{ SLASH, { .ctrl = true }, CMD_TOGGLE_COMMENT },
	{ M, { .ctrl = true }, CMD_TOGGLE_COMMENT },
	{ U, { .ctrl = true }, CMD_TO_LOWERCASE },
	{ U, { .ctrl = true, .shift = true }, CMD_TO_UPPERCASE },
	{ B, { .ctrl = true }, CMD_JUMP_MATCHING_BRACKET },
	{ BACKSLASH, { .ctrl = true, .shift = true }, CMD_JUMP_MATCHING_BRACKET },
	{ B, { .ctrl = true, .shift = true }, CMD_JUMP_MATCHING_BRACKET },
	// Line Movements
	{ UP, { .alt = true }, CMD_MOVE_LINE_UP },
	{ DOWN, { .alt = true }, CMD_MOVE_LINE_DOWN },
	// File Boundary Jumps & Selections
	{ HOME, { .ctrl = true, .shift = true }, CMD_SELECT_TO_TOP },
	{ END, { .ctrl = true, .shift = true }, CMD_SELECT_TO_BOTTOM },
	{ HOME, { .ctrl = true }, CMD_MOVE_FILE_START },
	{ END, { .ctrl = true }, CMD_MOVE_FILE_END },
	// Word Jumps
	{ LEFT, { .ctrl = true }, CMD_MOVE_WORD_LEFT },
	{ LEFT, { .ctrl = true, .shift = true }, CMD_MOVE_WORD_LEFT },
	{ RIGHT, { .ctrl = true }, CMD_MOVE_WORD_RIGHT },
	{ RIGHT, { .ctrl = true, .shift = true }, CMD_MOVE_WORD_RIGHT },
	// Basic Navigation
	{ LEFT, { }, CMD_MOVE_LEFT },
	{ LEFT, { .shift = true }, CMD_MOVE_LEFT },
	{ RIGHT, { }, CMD_MOVE_RIGHT },
	{ RIGHT, { .shift = true }, CMD_MOVE_RIGHT },
	{ UP, { }, CMD_MOVE_UP },
	{ UP, { .shift = true }, CMD_MOVE_UP },
	{ DOWN, { }, CMD_MOVE_DOWN },
	{ DOWN, { .shift = true }, CMD_MOVE_DOWN },
	{ HOME, { }, CMD_MOVE_LINE_START },
	{ HOME, { .shift = true }, CMD_MOVE_LINE_START },
	{ END, { }, CMD_MOVE_LINE_END },
	{ END, { .shift = true }, CMD_MOVE_LINE_END },
	{ PAGE_UP, { }, CMD_PAGE_UP },
	{ PAGE_UP, { .shift = true }, CMD_PAGE_UP },
	{ PAGE_DOWN, { }, CMD_PAGE_DOWN },
	{ PAGE_DOWN, { .shift = true }, CMD_PAGE_DOWN },
	// Standard Keys
	{ BACKSPACE, { }, CMD_BACKSPACE },
	{ BACKSPACE, { .shift = true }, CMD_BACKSPACE },
	{ DELETE, { }, CMD_DELETE },
	{ DELETE, { .shift = true }, CMD_DELETE },
	{ ENTER, { }, CMD_ENTER },
	{ ENTER, { .shift = true }, CMD_ENTER },
	{ KP_ENTER, { }, CMD_ENTER },
	{ KP_ENTER, { .shift = true }, CMD_ENTER },
	{ TAB, { }, CMD_INSERT_TAB },
	{ TAB, { .shift = true }, CMD_OUTDENT },
	{ ESCAPE, { }, CMD_CLEAR_SELECTION },
	// Zooming
	{ EQUAL, { .ctrl = true }, CMD_ZOOM_IN },
	{ KP_ADD, { .ctrl = true }, CMD_ZOOM_IN },
	{ MINUS, { .ctrl = true }, CMD_ZOOM_OUT },
	{ KP_SUBTRACT, { .ctrl = true }, CMD_ZOOM_OUT }
};

fn EditorCommand resolve_key_command(RLKeyboardKey key, KeyModifiers mods)
{
	foreach (&binding : KEYBINDINGS)
	{
		if (binding.key == key && (uint)binding.mods == (uint)mods)
		{
			return binding.command;
		}
	}
	return CMD_NONE;
}module app;
import std, raylib6;

// Tuning & Layout Constants
const int TAB_SIZE_SPACES        = 4;
const float DEFAULT_FONT_SCALE   = 2.0f;
const int CURSOR_WIDTH           = 2;
const int CURSOR_EXTRA_HEIGHT    = 2;
const int SELECTION_PADDING_Y    = 2;
const float CURSOR_BLINK_RATE    = 0.5f;
const double DOUBLE_CLICK_TIME   = 0.35;
const int HORIZONTAL_SCROLL_STEP = 7;
const int VERTICAL_SCROLL_STEP   = 3;

alias Rgba = char[<4>];

// Color Palette
const Rgba COLOR_BG             = { 15, 23, 42, 255 };
const Rgba COLOR_HEADER_BG      = { 30, 41, 59, 255 };
const Rgba COLOR_TAB_BG         = { 20, 29, 47, 255 };
const Rgba COLOR_TAB_ACTIVE_BG  = { 15, 23, 42, 255 };
const Rgba COLOR_TAB_BORDER     = { 51, 65, 85, 255 };
const Rgba COLOR_FOOTER_BG      = { 30, 41, 59, 255 };
const Rgba COLOR_GUTTER_BG      = { 15, 23, 42, 255 };
const Rgba COLOR_GUTTER_BORDER  = { 51, 65, 85, 255 };
const Rgba COLOR_LINE_HIGHLIGHT = { 30, 41, 59, 160 };
const Rgba COLOR_TEXT           = { 226, 232, 240, 255 };
const Rgba COLOR_TEXT_BRIGHT    = { 248, 250, 252, 255 };
const Rgba COLOR_TEXT_MUTED     = { 100, 116, 139, 255 };
const Rgba COLOR_TAB_GUIDE      = { 71, 85, 105, 65 };
const Rgba COLOR_HEADER_MUTED   = { 148, 163, 184, 255 };
const Rgba COLOR_ACCENT_BLUE    = { 56, 189, 248, 255 };
const Rgba COLOR_ACCENT_GREEN   = { 74, 222, 128, 255 };
const Rgba COLOR_ACCENT_YELLOW  = { 250, 204, 21, 255 };
const Rgba COLOR_ACCENT_RED     = { 248, 113, 113, 255 };
const Rgba COLOR_SELECTION_BG   = { 3, 105, 161, 255 };
const Rgba COLOR_CURSOR         = { 56, 189, 248, 255 };
const Rgba COLOR_SCROLLBAR      = { 71, 85, 105, 180 };
const Rgba COLOR_SCROLLBAR_ACT  = { 56, 189, 248, 220 };

struct SearchMatch
{
	String filepath;
	int line_num;
	String line_text;
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

struct TabDocument
{
	PieceTable table;
	List{BytePos} line_starts;
	List{LineState} line_states;
	List{Cursor} cursors;

	String filepath;
	bool is_file_specified;
	bool is_modified;

	int scroll_line;
	int scroll_col;
}

fn void TabDocument.init(
	&self,
	Allocator allocator,
	String filepath = "untitled.c3",
	bool file_specified = false,
	char[] content = { }
)
{
	self.filepath = filepath.copy(allocator);
	self.is_file_specified = file_specified;
	self.is_modified = false;
	self.scroll_line = 0;
	self.scroll_col = 0;

	self.table.init(allocator, content);
	self.line_starts.init(allocator, 32);
	self.line_states.init(allocator, 32);
	self.cursors.init(allocator, 8);
	self.cursors.push({ 0, 0, 0 });
}

fn void TabDocument.free(&self, Allocator allocator)
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

struct Editor
{
	List{TabDocument} tabs;
	int active_tab_index;
	int pending_close_tab_index;

	float font_scale;

	KeyModifiers modifiers;
	bool mouse_down;
	bool word_selecting;
	BytePos word_sel_anchor_start;
	BytePos word_sel_anchor_end;
	bool initialized;
	float blink_timer;
	bool cursor_visible;
	double last_click_time;
	Vec2 last_click_pos;

	bool scrollbar_dragging;
	float scrollbar_drag_offset_y;

	bool should_exit;

	ModalKind active_modal;
	TextInputWidget modal_input;
	TextInputWidget modal_replace_input;
	int modal_focus_field; // 0 = Find, 1 = Replace
	bool search_case_sensitive;
	int cached_match_count;
	ListPickerWidget{SearchMatch} grep_picker;
	ListPickerWidget{String} file_picker;

	float grep_debounce_timer;
	bool grep_dirty;

	float page_hold_timer;
	float save_msg_timer;
}

fn TabDocument* Editor.active_tab(&self)
{
	if (self.tabs.len() == 0)
	{
		self.open_new_tab("untitled.c3", false, "");
	}
	if (self.active_tab_index < 0 || self.active_tab_index >= (int)self.tabs.len())
	{
		self.active_tab_index = 0;
	}
	return &self.tabs[(sz)self.active_tab_index];
}

fn Cursor* Editor.primary_cursor(&self)
{
	TabDocument* tab = self.active_tab();
	if (tab.cursors.len() == 0)
	{
		tab.cursors.push({ 0, 0, 0 });
	}
	return &tab.cursors[0];
}

fn void Editor.init(&self)
{
	self.tabs.init(mem, 8);
	self.active_tab_index = 0;
	self.pending_close_tab_index = -1;
	self.font_scale = DEFAULT_FONT_SCALE;
	self.file_picker.init(mem, 10);
	self.grep_picker.init(mem, 11);
	self.initialized = true;
}

fn int Editor.open_new_tab(
	&self,
	String filepath = "untitled.c3",
	bool file_specified = false,
	String initial_text = ""
)
{
	if (file_specified && filepath.len > 0)
	{
		for (sz i = 0; i < self.tabs.len(); i++)
		{
			if (self.tabs[i].is_file_specified && self.tabs[i].filepath == filepath)
			{
				self.active_tab_index = (int)i;
				self.reset_cursor_blink();
				return self.active_tab_index;
			}
		}
	}

	TabDocument doc;
	doc.init(mem, filepath, file_specified, (char[])initial_text.copy(mem));
	self.tabs.push(doc);
	self.active_tab_index = (int)self.tabs.len() - 1;
	self.rebuild_line_index();
	self.reset_cursor_blink();
	return self.active_tab_index;
}

fn void Editor.request_close_tab(&self, int tab_idx)
{
	if (tab_idx < 0 || tab_idx >= (int)self.tabs.len())
	{
		return;
	}
	TabDocument* t = &self.tabs[(sz)tab_idx];
	if (!t.is_modified)
	{
		self.close_tab(tab_idx);
	}
	else
	{
		self.pending_close_tab_index = tab_idx;
		self.active_tab_index = tab_idx;
		self.active_modal = CONFIRM_CLOSE_TAB;
		self.reset_cursor_blink();
	}
}

fn void Editor.close_tab(&self, int tab_idx)
{
	if (tab_idx < 0 || tab_idx >= (int)self.tabs.len())
	{
		return;
	}

	self.tabs[tab_idx].free(mem);
	self.tabs.remove_at((sz)tab_idx);

	if (self.tabs.len() == 0)
	{
		self.should_exit = true;
		return;
	}

	if (self.active_tab_index >= (int)self.tabs.len())
	{
		self.active_tab_index = (int)self.tabs.len() - 1;
	}
	self.reset_cursor_blink();
}

fn Rect Editor.get_modal_rect(&self, LayoutMetrics* lm, int screen_w, int height)
{
	if (self.active_modal == NONE) return { 0, 0, 0, 0 };

	String prompt         = "";
	String case_indicator = self.search_case_sensitive ? "Aa:ON" : "Aa:OFF";

	switch (self.active_modal)
	{
		case GOTO_LINE: prompt = "GO TO LINE:";
		case FIND: prompt = string::tformat("FIND (%d matches) [Alt+1/Alt+C %s] - [Up/Down] Prev/Next [Esc] Close", self.cached_match_count, case_indicator);
		case REPLACE: prompt = string::tformat("FIND & REPLACE (%d matches) [Alt+1/Alt+C %s] - [Tab] Switch [Enter] Next [Ctrl+Enter] All", self.cached_match_count, case_indicator);
		case SAVE_AS: prompt = "SAVE FILE AS:";
		case QUICK_OPEN: prompt = string::tformat("QUICK FILE OPEN (Ctrl+P) - %d files", self.file_picker.items.len());
		case GLOBAL_GREP: prompt = string::tformat("GLOBAL GREP (Ctrl+Shift+F) - %d matches", self.grep_picker.items.len());
		case CONFIRM_EXIT: prompt = "UNSAVED CHANGES! Save all files before quitting?";
		case CONFIRM_CLOSE_TAB: prompt = "UNSAVED CHANGES! Save file before closing tab?";
		default: break;
	}

	int prompt_text_w = (int)prompt.len * lm.char_width;
	int modal_w       = math::max(560, prompt_text_w + 48);

	if (self.active_modal == QUICK_OPEN || self.active_modal == GLOBAL_GREP || self.active_modal == REPLACE)
	{
		modal_w = math::max(760, modal_w);
	}
	modal_w = math::min(modal_w, screen_w - 40);

	int input_box_h = math::max(28, lm.char_height + 12);
	int modal_h     = 100;
	switch (self.active_modal)
	{
		case CONFIRM_EXIT:
		case CONFIRM_CLOSE_TAB:
			modal_h = lm.char_height + input_box_h + 46;
		case REPLACE:
			modal_h = lm.char_height * 2 + input_box_h * 2 + 58;
		case QUICK_OPEN:
		case GLOBAL_GREP:
			modal_h = 420;
		default:
			modal_h = lm.char_height + input_box_h + 46;
	}

	int modal_x = (screen_w - modal_w) / 2;
	int modal_y = (height - modal_h) / 3;

	return { (float)modal_x, (float)modal_y, (float)modal_w, (float)modal_h };
}

fn void Editor.confirm_save_action(&self)
{
	switch (self.active_modal)
	{
		case CONFIRM_CLOSE_TAB:
			int target_idx = self.pending_close_tab_index;
			if (target_idx >= 0 && target_idx < (int)self.tabs.len())
			{
				TabDocument* t = &self.tabs[(sz)target_idx];
				if (!t.is_file_specified || t.filepath.len == 0)
				{
					self.active_tab_index = target_idx;
					self.active_modal = SAVE_AS;
					self.modal_input.set_text(t.filepath);
				}
				else
				{
					file::save(t.filepath, (char[])t.table.to_tstring())!!;
					t.is_modified = false;
					self.save_msg_timer = 2.0f;
					int to_close = target_idx;
					self.pending_close_tab_index = -1;
					self.active_modal = NONE;
					self.close_tab(to_close);
				}
			}
			else
			{
				self.active_modal = NONE;
			}
		case CONFIRM_EXIT:
			foreach (&t : self.tabs)
			{
				if (t.is_modified && t.filepath.len > 0)
				{
					file::save(t.filepath, (char[])t.table.to_tstring())!!;
				}
			}
			self.should_exit = true;
		default: break;
	}
}

fn void Editor.confirm_discard_action(&self)
{
	switch (self.active_modal)
	{
		case CONFIRM_CLOSE_TAB:
			int target_idx = self.pending_close_tab_index;
			self.pending_close_tab_index = -1;
			self.active_modal = NONE;
			if (target_idx >= 0 && target_idx < (int)self.tabs.len())
			{
				self.close_tab(target_idx);
			}
		case CONFIRM_EXIT:
			self.should_exit = true;
		default: break;
	}
}

fn void Editor.confirm_cancel_action(&self)
{
	self.pending_close_tab_index = -1;
	self.active_modal = NONE;
}

fn void Editor.load_text(&self, String str)
{
	TabDocument* tab = self.active_tab();
	tab.table.free();
	tab.table.init(mem, (char[])str.copy(mem));
	self.rebuild_line_index();
	tab.cursors.clear();
	tab.cursors.push({ 0, 0, 0 });
	tab.scroll_line = 0;
	tab.scroll_col = 0;
	tab.is_modified = false;
	self.active_modal = NONE;
	self.cached_match_count = 0;
}

fn void Editor.normalize_cursors(&self)
{
	TabDocument* tab = self.active_tab();
	if (tab.cursors.len() <= 1) return;

	sort::quicksort(&tab.cursors, fn int (Cursor a, Cursor b) => compare_cursors(&a, &b));

	sz i = 0;
	while (i + 1 < tab.cursors.len())
	{
		Cursor cur  = tab.cursors[i];
		Cursor next = tab.cursors[i + 1];

		bool cur_has_sel  = cur.has_selection();
		bool next_has_sel = next.has_selection();

		if (!cur_has_sel && !next_has_sel)
		{
			if (cur.pos == next.pos)
			{
				tab.cursors.remove_at(i + 1);
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
				tab.cursors[i].anchor = merged_s;
				tab.cursors[i].pos = merged_e;
				tab.cursors[i].target_col = self.get_col(merged_e);
				tab.cursors.remove_at(i + 1);
				continue;
			}
		}
		i++;
	}
}

fn void Editor.reset_cursor_blink(&self)
{
	self.blink_timer = 0.0f;
	self.cursor_visible = true;
}

fn void Editor.ensure_cursor_visible(&self, LayoutMetrics* lm)
{
	TabDocument* tab = self.active_tab();
	Cursor* cur      = self.primary_cursor();
	int cursor_line  = self.get_line(cur.pos);
	switch
	{
		case cursor_line < tab.scroll_line:
			tab.scroll_line = cursor_line;
		case cursor_line >= tab.scroll_line + lm.visible_lines:
			tab.scroll_line = cursor_line - lm.visible_lines + 1;
	}
	tab.scroll_line = math::clamp(tab.scroll_line, 0, math::max(0, self.get_total_lines() - 1));

	int cursor_col = self.get_col(cur.pos);
	switch
	{
		case cursor_col < tab.scroll_col:
			tab.scroll_col = cursor_col;
		case cursor_col >= tab.scroll_col + lm.visible_cols:
			tab.scroll_col = cursor_col - lm.visible_cols + 1;
	}
	if (tab.scroll_col < 0) tab.scroll_col = 0;
}module app::font;
import std, raylib6;

const int GLYPH_WIDTH_CELLS   = 5;
const int GLYPH_HEIGHT_CELLS  = 8;
const int GLYPH_SPACING_CELLS = 1;

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
	UNKNOWN     { '\0', 0b11111_10001_10101_10101_10101_10001_11111_00000UL }
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
		if (i == 9) bits = FontGlyph.TAB_ARROW.bitmap;

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

fn void draw_char(Char32 c, int px, int py, float scale, RLColor tint)
{
	int idx = (int)c;
	if (idx < 0 || idx >= 256) idx = 0;

	int gx = (idx % 16) * 8;
	int gy = (idx / 16) * 8;

	RLRectangle src = { (float)gx, (float)gy, (float)GLYPH_WIDTH_CELLS, (float)GLYPH_HEIGHT_CELLS };
	RLRectangle dst = { (float)px, (float)py, (float)GLYPH_WIDTH_CELLS * scale, (float)GLYPH_HEIGHT_CELLS * scale };
	rl::draw_texture_pro(font_texture, src, dst, { 0, 0 }, 0.0f, tint);
}

fn void draw_tab_guide(int px, int py, int tab_spaces, int char_width, float scale, RLColor tint)
{
	for (int i = 0; i < tab_spaces - 1; i++)
	{
		draw_char('-', px + i * char_width, py, scale, tint);
	}
	int arrow_x     = px + (tab_spaces - 1) * char_width;
	int gx          = 9 % 16 * 8;
	int gy          = 9 / 16 * 8;
	RLRectangle src = { (float)gx, (float)gy, (float)GLYPH_WIDTH_CELLS, (float)GLYPH_HEIGHT_CELLS };
	RLRectangle dst = {
		(float)arrow_x,
		(float)py,
		(float)GLYPH_WIDTH_CELLS * scale,
		(float)GLYPH_HEIGHT_CELLS * scale
	};
	rl::draw_texture_pro(font_texture, src, dst, { 0, 0 }, 0.0f, tint);
}

fn void draw_text(String str, int px, int py, float scale, RLColor tint)
{
	int advance         = (int)math::round((float)(GLYPH_WIDTH_CELLS + GLYPH_SPACING_CELLS) * scale);
	int cur_x           = px;
	StringIterator iter = str.iterator();
	while (try Char32 c = iter.next())
	{
		draw_char(c, cur_x, py, scale, tint);
		cur_x += advance;
	}
}module app;
import std;

fn int Editor.get_total_lines(&self)
{
	TabDocument* tab = self.active_tab();
	if (tab.line_starts.len() == 0) return 1;
	return (int)tab.line_starts.len();
}

fn BytePos Editor.get_line_start_of_line(&self, int target_line)
{
	TabDocument* tab = self.active_tab();
	if (target_line <= 0 || tab.line_starts.len() == 0) return 0;
	if (target_line >= (int)tab.line_starts.len()) return tab.table.len();
	return tab.line_starts[(sz)target_line];
}

fn BytePos Editor.get_line_start(&self, BytePos pos)
{
	int line = self.get_line(pos);
	return self.get_line_start_of_line(line);
}

fn BytePos Editor.get_line_end(&self, BytePos pos)
{
	TabDocument* tab = self.active_tab();
	int line         = self.get_line(pos);
	if (line + 1 < (int)tab.line_starts.len())
	{
		return tab.line_starts[(sz)(line + 1)] - 1;
	}
	return tab.table.len();
}

fn int Editor.get_line(&self, BytePos pos)
{
	TabDocument* tab = self.active_tab();
	sz len           = tab.line_starts.len();
	if (len <= 1 || pos == 0) return 0;
	BytePos total_len = tab.table.len();
	if (pos > total_len) pos = total_len;

	sz low  = 0;
	sz high = len - 1;
	sz ans  = 0;
	while (low <= high)
	{
		sz mid = low + (high - low) / 2;
		if (tab.line_starts[mid] <= pos)
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

fn int Editor.get_col(&self, BytePos pos)
{
	TabDocument* tab  = self.active_tab();
	BytePos total_len = tab.table.len();
	if (pos > total_len) pos = total_len;

	int col            = 0;
	BytePos line_start = self.get_line_start(pos);
	if (line_start > total_len) line_start = total_len;

	for (BytePos p = line_start; p < pos; p++)
	{
		char c = tab.table.get(p);
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

fn LineCol Editor.get_line_col(&self, BytePos pos)
{
	return { .line = self.get_line(pos), .col = self.get_col(pos) };
}

fn BytePos Editor.get_pos_from_line_col(&self, int target_line, int target_col)
{
	TabDocument* tab   = self.active_tab();
	BytePos line_start = self.get_line_start_of_line(target_line);
	BytePos line_end   = self.get_line_end(line_start);
	int col            = 0;
	BytePos actual_pos = line_start;

	while (actual_pos < line_end && col < target_col)
	{
		char c = tab.table.get(actual_pos);
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
		actual_pos = get_next_char_pos(&tab.table, actual_pos);
	}
	return actual_pos;
}

fn BytePos Editor.get_pos_from_lc(&self, LineCol lc) => self.get_pos_from_line_col(lc.line, lc.col);

fn BytePos Editor.get_pos_from_mouse(&self, Vec2 mpos, LayoutMetrics* lm)
{
	TabDocument* tab = self.active_tab();
	if (mpos.y < (float)lm.text_start_y) return 0;
	int rel_y = (int)(mpos.y - (float)lm.text_start_y);
	int line  = rel_y / lm.line_height + tab.scroll_line;
	int rel_x = (int)(mpos.x - (float)lm.text_start_x + (float)lm.char_width * 0.5f);
	int col   = math::max(0, rel_x / lm.char_width + tab.scroll_col);

	return self.get_pos_from_line_col(line, col);
}

fn void Editor.rebuild_line_index(&self)
{
	TabDocument* tab = self.active_tab();
	if (tab.line_starts.entries == null)
	{
		tab.line_starts.init(mem);
	}
	tab.line_starts.clear();
	tab.line_starts.push(0);

	BytePos piece_start_pos = 0;
	foreach (&p : tab.table.pieces)
	{
		char[] slice = (p.source == ORIGINAL) ? tab.table.original_buffer[p.offset:p.length]
			: tab.table.add_buffer[p.offset:p.length];

		for (sz i = 0; i < p.length; i++)
		{
			if (slice[i] == '\n')
			{
				tab.line_starts.push(piece_start_pos + i + 1);
			}
		}
		piece_start_pos += p.length;
	}

	if (tab.line_states.entries == null)
	{
		tab.line_states.init(mem);
	}
	tab.line_states.clear();

	int total_lines         = (int)tab.line_starts.len();
	LineState current_state = NORMAL;

	for (int i = 0; i < total_lines; i++)
	{
		BytePos start = self.get_line_start_of_line(i);
		BytePos end   = self.get_line_end(start);

		current_state = syntax::lex_state_only(&tab.table, start, end, current_state);
		tab.line_states.push(current_state);
	}
}

fn void Editor.update_line_index_on_edit(&self, BytePos edit_start, BytePos deleted_len, BytePos inserted_len)
{
	TabDocument* tab = self.active_tab();
	int start_line   = self.get_line(edit_start);
	BytePos old_end  = edit_start + deleted_len;

	sz start_remove_idx = (sz)(start_line + 1);
	sz end_remove_idx   = start_remove_idx;

	while (end_remove_idx < tab.line_starts.len() && tab.line_starts[end_remove_idx] <= old_end)
	{
		end_remove_idx++;
	}

	sz remove_count = end_remove_idx - start_remove_idx;
	if (remove_count > 0)
	{
		sz remaining_starts = tab.line_starts.len() - end_remove_idx;
		if (remaining_starts > 0)
		{
			mem::move(
				&tab.line_starts.entries[start_remove_idx],
				&tab.line_starts.entries[end_remove_idx],
				remaining_starts * BytePos::size
			);
		}
		tab.line_starts.size -= remove_count;

		if (start_remove_idx < tab.line_states.len())
		{
			sz states_end       = math::min(end_remove_idx, tab.line_states.len());
			sz states_remove    = states_end - start_remove_idx;
			sz remaining_states = tab.line_states.len() - states_end;
			if (remaining_states > 0)
			{
				mem::move(
					&tab.line_states.entries[start_remove_idx],
					&tab.line_states.entries[states_end],
					remaining_states * LineState::size
				);
			}
			tab.line_states.size -= states_remove;
		}
	}

	BytePos insert_scan_end = edit_start + inserted_len;
	List{BytePos} new_line_starts;
	new_line_starts.tinit(16);

	for (BytePos p = edit_start; p < insert_scan_end; p++)
	{
		if (tab.table.get(p) == '\n')
		{
			new_line_starts.push(p + 1);
		}
	}

	sz inserted_lines_count = new_line_starts.len();
	if (inserted_lines_count > 0)
	{
		sz insert_pos = (sz)(start_line + 1);
		sz old_total  = tab.line_starts.len();

		tab.line_starts.reserve(inserted_lines_count);
		tab.line_starts.size += inserted_lines_count;

		sz to_shift = old_total - insert_pos;
		if (to_shift > 0)
		{
			mem::move(
				&tab.line_starts.entries[insert_pos + inserted_lines_count],
				&tab.line_starts.entries[insert_pos],
				to_shift * BytePos::size
			);
		}

		mem::copy(&tab.line_starts.entries[insert_pos], new_line_starts.entries, inserted_lines_count * BytePos::size);

		tab.line_states.reserve(inserted_lines_count);
		sz old_states_total = tab.line_states.len();
		sz state_insert_pos = math::min(insert_pos - 1, old_states_total);
		tab.line_states.size += inserted_lines_count;

		sz states_to_shift = old_states_total - state_insert_pos;
		if (states_to_shift > 0)
		{
			mem::move(
				&tab.line_states.entries[state_insert_pos + inserted_lines_count],
				&tab.line_states.entries[state_insert_pos],
				states_to_shift * LineState::size
			);
		}
		for (sz k = 0; k < inserted_lines_count; k++)
		{
			tab.line_states.entries[state_insert_pos + k] = LineState.NORMAL;
		}
	}

	if (deleted_len != inserted_len)
	{
		sz subsequent_idx = (sz)(start_line + 1 + (int)inserted_lines_count);
		sz total_starts   = tab.line_starts.len();
		for (sz i = subsequent_idx; i < total_starts; i++)
		{
			if (inserted_len >= deleted_len)
			{
				tab.line_starts.entries[i] += (inserted_len - deleted_len);
			}
			else
			{
				tab.line_starts.entries[i] -= (deleted_len - inserted_len);
			}
		}
	}

	int total_lines = (int)tab.line_starts.len();
	while (tab.line_states.len() < (sz)total_lines)
	{
		tab.line_states.push(LineState.NORMAL);
	}

	int cur_line = start_line;
	while (cur_line < total_lines)
	{
		BytePos l_start = self.get_line_start_of_line(cur_line);
		BytePos l_end   = self.get_line_end(l_start);

		LineState prev_state = (cur_line == 0) ? LineState.NORMAL : tab.line_states[(sz)(cur_line - 1)];
		LineState new_state  = syntax::lex_state_only(&tab.table, l_start, l_end, prev_state);

		LineState old_state = tab.line_states[(sz)cur_line];
		tab.line_states[(sz)cur_line] = new_state;

		if (new_state == old_state && cur_line >= start_line + (int)inserted_lines_count)
		{
			break;
		}
		cur_line++;
	}
}module app;
import std, raylib6, app::font;

alias BytePos = sz;

struct LineCol
{
	int line;
	int col;
}

struct ScreenPx
{
	float x;
	float y;
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
	int gutter_width;
	int text_start_x;
	int text_start_y;

	int editor_w;
	int editor_h;
	int visible_lines;
	int visible_cols;

	Rect tab_bar_rect;
	Rect gutter_rect;
	Rect editor_rect;
	Rect footer_rect;
	Rect scrollbar_rect;
}

const int GUTTER_PADDING_RIGHT = 8;
const int GUTTER_BORDER_W      = 2;
const int TEXT_PADDING_X       = 8;
const int TEXT_PADDING_Y       = 6;

fn LayoutMetrics compute_layout(int screen_w, int screen_h, float font_scale, int total_lines, bool show_tab_bar = true)
{
	LayoutMetrics lm;
	lm.font_scale = math::clamp(font_scale, 1.0f, 6.0f);
	lm.char_width = (int)math::round((float)(font::GLYPH_WIDTH_CELLS + font::GLYPH_SPACING_CELLS) * lm.font_scale);
	lm.char_height = (int)math::round((float)font::GLYPH_HEIGHT_CELLS * lm.font_scale);
	lm.line_height = lm.char_height + math::max(4, (int)math::round(6.0f * (lm.font_scale / 2.0f)));

	lm.screen_w = screen_w;
	lm.screen_h = screen_h;

	int tab_bar_padding_y = math::max(4, (int)math::round(6.0f * (lm.font_scale / 2.0f)));
	int footer_padding_y  = math::max(4, (int)math::round(5.0f * (lm.font_scale / 2.0f)));
	lm.tab_bar_height = show_tab_bar ? (lm.char_height + tab_bar_padding_y * 2) : 0;
	lm.footer_height = lm.char_height + footer_padding_y * 2;

	int digits = math::max(4, get_digits_count(total_lines));
	lm.gutter_width = digits * lm.char_width + GUTTER_PADDING_RIGHT + GUTTER_BORDER_W;
	lm.text_start_x = lm.gutter_width + TEXT_PADDING_X;
	lm.text_start_y = lm.tab_bar_height + TEXT_PADDING_Y;

	lm.editor_w = screen_w - lm.text_start_x - 14;
	lm.editor_h = screen_h - lm.tab_bar_height - lm.footer_height;

	lm.visible_lines = math::max(1, (lm.editor_h - TEXT_PADDING_Y * 2) / lm.line_height);
	lm.visible_cols = math::max(1, (lm.editor_w - TEXT_PADDING_X) / lm.char_width);

	lm.tab_bar_rect = { 0, 0, (float)screen_w, (float)lm.tab_bar_height };
	lm.gutter_rect = { 0, (float)lm.tab_bar_height, (float)(lm.gutter_width - GUTTER_BORDER_W), (float)lm.editor_h };
	lm.editor_rect = { (float)lm.text_start_x, (float)lm.text_start_y, (float)lm.editor_w, (float)lm.editor_h };
	lm.footer_rect = { 0, (float)(screen_h - lm.footer_height), (float)screen_w, (float)lm.footer_height };
	lm.scrollbar_rect = { (float)(screen_w - 12), (float)lm.text_start_y, 10.0f, (float)lm.editor_h };

	return lm;
}

fn int get_digits_count(int n) @private
{
	if (n <= 0)
	{
		return 1;
	}
	int count = 0;
	while (n > 0)
	{
		count++;
		n /= 10;
	}
	return count;
}module app;
import std, raylib6, app::command;

Editor editor;

fn bool key_pressed_or_repeat(RLKeyboardKey key)
{
	return rl::is_key_pressed(key) || rl::is_key_pressed_repeat(key);
}

fn void update_editor_events(LayoutMetrics* lm, float dt, int screen_w, int height)
{
	TabDocument* tab = editor.active_tab();

	editor.modifiers = {
		.shift = rl::is_key_down(LEFT_SHIFT) || rl::is_key_down(RIGHT_SHIFT),
		.ctrl = rl::is_key_down(LEFT_CONTROL) || rl::is_key_down(RIGHT_CONTROL),
		.alt = rl::is_key_down(LEFT_ALT) || rl::is_key_down(RIGHT_ALT)
	};

	editor.blink_timer += dt;
	if (editor.blink_timer >= CURSOR_BLINK_RATE)
	{
		editor.blink_timer -= CURSOR_BLINK_RATE;
		editor.cursor_visible = !editor.cursor_visible;
	}

	if (editor.active_modal != NONE)
	{
		if (rl::is_key_pressed(ESCAPE))
		{
			editor.confirm_cancel_action();
			return;
		}

		if (rl::is_mouse_button_pressed(LEFT))
		{
			RLVector2 mouse_v = rl::get_mouse_position();
			Rect mrect        = editor.get_modal_rect(lm, screen_w, height);

			if (mouse_v.x < mrect.x - 4.0f || mouse_v.x > mrect.x + mrect.width + 4.0f || mouse_v.y < mrect.y - 4.0f
				|| mouse_v.y > mrect.y + mrect.height + 4.0f)
			{
				editor.confirm_cancel_action();
				return;
			}

			int modal_x     = (int)mrect.x;
			int modal_y     = (int)mrect.y;
			int modal_w     = (int)mrect.width;
			int modal_h     = (int)mrect.height;
			int input_box_h = math::max(28, lm.char_height + 12);

			switch (editor.active_modal)
			{
				case CONFIRM_CLOSE_TAB:
				case CONFIRM_EXIT:
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
							editor.modal_focus_field = 0;
							editor.reset_cursor_blink();
						case mouse_v.y >= (float)input2_y && mouse_v.y < (float)(input2_y + input_box_h):
							editor.modal_focus_field = 1;
							editor.reset_cursor_blink();
					}

				case QUICK_OPEN:
					int input_y = modal_y + 14 + lm.char_height + 8;
					int list_y = input_y + input_box_h + 10;
					int list_h = modal_y + modal_h - list_y - 14;
					int row_h = math::max(24, lm.line_height);

					if (mouse_v.x >= (float)(modal_x + 16) && mouse_v.x <= (float)(modal_x + modal_w - 16)
						&& mouse_v.y >= (float)list_y
						&& mouse_v.y < (float)(list_y + list_h))
					{
						int clicked_row = (int)(mouse_v.y - (float)list_y) / row_h;
						int idx         = clicked_row + editor.file_picker.scroll_offset;
						if (idx >= 0 && idx < (int)editor.file_picker.items.len())
						{
							editor.file_picker.selected_index = idx;
							String selected = editor.file_picker.items[(sz)idx];
							String loaded   = "";
							if (try c = file::load_temp(selected)) loaded = (String)c;
							editor.open_new_tab(selected, true, loaded);
							editor.active_modal = NONE;
							return;
						}
					}

				case GLOBAL_GREP:
					int input_y = modal_y + 14 + lm.char_height + 8;
					int list_y = input_y + input_box_h + 10;
					int list_h = modal_y + modal_h - list_y - 14;
					int row_h = math::max(24, lm.line_height);

					if (mouse_v.x >= (float)(modal_x + 16) && mouse_v.x <= (float)(modal_x + modal_w - 16)
						&& mouse_v.y >= (float)list_y
						&& mouse_v.y < (float)(list_y + list_h))
					{
						int clicked_row = (int)(mouse_v.y - (float)list_y) / row_h;
						int idx         = clicked_row + editor.grep_picker.scroll_offset;
						if (idx >= 0 && idx < (int)editor.grep_picker.items.len())
						{
							editor.grep_picker.selected_index = idx;
							SearchMatch m = editor.grep_picker.items[(sz)idx];
							String loaded = "";
							if (try c = file::load_temp(m.filepath)) loaded = (String)c;
							editor.open_new_tab(m.filepath, true, loaded);
							TabDocument* new_tab = editor.active_tab();
							BytePos target_pos   = editor.get_pos_from_line_col(m.line_num - 1, 0);
							new_tab.cursors.clear();
							new_tab.cursors.push({ target_pos, target_pos, 0 });
							editor.ensure_cursor_visible(lm);
							editor.active_modal = NONE;
							return;
						}
					}

				default: break;
			}
		}

		float modal_wheel = rl::get_mouse_wheel_move();
		if (modal_wheel != 0.0f)
		{
			switch (editor.active_modal)
			{
				case QUICK_OPEN:
					(modal_wheel > 0.0f) ? editor.file_picker.select_prev() : editor.file_picker.select_next();
				case GLOBAL_GREP:
					(modal_wheel > 0.0f) ? editor.grep_picker.select_prev() : editor.grep_picker.select_next();
				default: break;
			}
		}

		TextInputWidget* active_input = (editor.active_modal == REPLACE
			&& editor.modal_focus_field == 1) ? &editor.modal_replace_input
			: &editor.modal_input;

		if (editor.active_modal == FIND || editor.active_modal == REPLACE)
		{
			bool toggle_case = (editor.modifiers.alt && rl::is_key_pressed(
				C
			)) || ((editor.modifiers.ctrl || editor.modifiers.alt) && (rl::is_key_pressed(
				ONE
			) || rl::is_key_pressed(KP_1))) || rl::is_key_pressed(F1);

			if (toggle_case)
			{
				editor.search_case_sensitive = !editor.search_case_sensitive;
				editor.cached_match_count = editor.count_find_matches();
				if (editor.active_modal == FIND || (editor.active_modal == REPLACE && editor.modal_focus_field == 0))
				{
					editor.find_from_current(lm);
				}
			}
		}

		switch (editor.active_modal)
		{
			case CONFIRM_CLOSE_TAB:
			case CONFIRM_EXIT:
				if (rl::is_key_pressed(Y))
				{
					editor.confirm_save_action();
				}
				if (rl::is_key_pressed(N))
				{
					editor.confirm_discard_action();
				}

			case GOTO_LINE:
				if (rl::is_key_pressed(ENTER) || rl::is_key_pressed(KP_ENTER))
				{
					int target         = string::to_integer{int}(editor.modal_input.view()) ?? 1;
					BytePos target_pos = editor.get_pos_from_line_col(
						math::clamp(target - 1, 0, editor.get_total_lines() - 1),
						0
					);
					tab.cursors.clear();
					tab.cursors.push({ target_pos, target_pos, 0 });
					editor.ensure_cursor_visible(lm);
					editor.active_modal = NONE;
				}

			case FIND:
				if (key_pressed_or_repeat(DOWN)) editor.find_next(false, lm);
				if (key_pressed_or_repeat(UP)) editor.find_next(true, lm);
				if (rl::is_key_pressed(ENTER) || rl::is_key_pressed(KP_ENTER) || rl::is_key_pressed(F3))
				{
					editor.find_next(editor.modifiers.shift, lm);
				}

			case REPLACE:
				switch
				{
					case rl::is_key_pressed(TAB) || key_pressed_or_repeat(UP) || key_pressed_or_repeat(DOWN):
						editor.modal_focus_field = 1 - editor.modal_focus_field;
						editor.reset_cursor_blink();
					case rl::is_key_pressed(ENTER) || rl::is_key_pressed(KP_ENTER):
						if (editor.modifiers.ctrl || editor.modifiers.alt)
						{
							editor.replace_all(lm);
						}
						else
						{
							editor.replace_next(lm);
						}
					case rl::is_key_pressed(F3):
						editor.find_next(editor.modifiers.shift, lm);
				}

			case QUICK_OPEN:
				if (key_pressed_or_repeat(UP)) editor.file_picker.select_prev();
				if (key_pressed_or_repeat(DOWN)) editor.file_picker.select_next();
				if (rl::is_key_pressed(ENTER) || rl::is_key_pressed(KP_ENTER))
				{
					if (editor.file_picker.items.len() > 0)
					{
						String selected = editor.file_picker.items[(sz)editor.file_picker.selected_index];
						String loaded   = "";
						if (try c = file::load_temp(selected)) loaded = (String)c;
						editor.open_new_tab(selected, true, loaded);
						editor.active_modal = NONE;
					}
				}

			case GLOBAL_GREP:
				if (key_pressed_or_repeat(UP)) editor.grep_picker.select_prev();
				if (key_pressed_or_repeat(DOWN)) editor.grep_picker.select_next();
				if (rl::is_key_pressed(ENTER) || rl::is_key_pressed(KP_ENTER))
				{
					if (editor.grep_picker.items.len() > 0)
					{
						SearchMatch m = editor.grep_picker.items[(sz)editor.grep_picker.selected_index];
						String loaded = "";
						if (try c = file::load_temp(m.filepath)) loaded = (String)c;
						editor.open_new_tab(m.filepath, true, loaded);
						TabDocument* new_tab = editor.active_tab();
						BytePos target_pos   = editor.get_pos_from_line_col(m.line_num - 1, 0);
						new_tab.cursors.clear();
						new_tab.cursors.push({ target_pos, target_pos, 0 });
						editor.ensure_cursor_visible(lm);
						editor.active_modal = NONE;
					}
				}

			case SAVE_AS:
				if (rl::is_key_pressed(ENTER) || rl::is_key_pressed(KP_ENTER))
				{
					String target_file = editor.modal_input.view();
					if (target_file.len > 0)
					{
						file::save(target_file, (char[])tab.table.to_tstring())!!;
						if (tab.filepath.len > 0) mem::free(tab.filepath.ptr);
						tab.filepath = target_file.copy(mem);
						tab.is_file_specified = true;
						tab.is_modified = false;
						editor.save_msg_timer = 2.0f;

						if (editor.pending_close_tab_index >= 0)
						{
							int to_close = editor.pending_close_tab_index;
							editor.pending_close_tab_index = -1;
							editor.active_modal = NONE;
							editor.close_tab(to_close);
							return;
						}
					}
					editor.active_modal = NONE;
				}
			default: break;
		}

		if (key_pressed_or_repeat(LEFT))
		{
			active_input.cursor_pos = math::max(0, active_input.cursor_pos - 1);
			editor.reset_cursor_blink();
		}
		if (key_pressed_or_repeat(RIGHT))
		{
			active_input.cursor_pos = math::min(active_input.length, active_input.cursor_pos + 1);
			editor.reset_cursor_blink();
		}
		if (rl::is_key_pressed(HOME))
		{
			active_input.cursor_pos = 0;
			editor.reset_cursor_blink();
		}
		if (rl::is_key_pressed(END))
		{
			active_input.cursor_pos = active_input.length;
			editor.reset_cursor_blink();
		}

		bool input_modified = false;
		if (key_pressed_or_repeat(BACKSPACE) && active_input.backspace()) input_modified = true;
		if (key_pressed_or_repeat(DELETE) && active_input.delete()) input_modified = true;

		int char_code = rl::get_char_pressed();
		while (char_code > 0)
		{
			if (char_code >= 32 && char_code <= 126 && (!editor.modifiers.ctrl || editor.modifiers.alt))
			{
				if (active_input.insert_char((char)char_code)) input_modified = true;
			}
			char_code = rl::get_char_pressed();
		}

		if (input_modified)
		{
			editor.reset_cursor_blink();
			if (editor.active_modal == FIND || (editor.active_modal == REPLACE && editor.modal_focus_field == 0))
			{
				editor.find_from_current(lm);
				editor.cached_match_count = editor.count_find_matches();
			}
			if (editor.active_modal == QUICK_OPEN) editor.update_quick_open_results();
			if (editor.active_modal == GLOBAL_GREP)
			{
				editor.grep_dirty = true;
				editor.grep_debounce_timer = 0.08f;
			}
		}

		if (editor.active_modal == GLOBAL_GREP && editor.grep_dirty)
		{
			editor.grep_debounce_timer -= dt;
			if (editor.grep_debounce_timer <= 0.0f)
			{
				editor.grep_dirty = false;
				editor.grep_debounce_timer = 0.0f;
				editor.update_search_results();
			}
		}
		return;
	}

	// Mouse & Scrollbar Handling
	RLVector2 mouse_v = rl::get_mouse_position();
	Vec2 mouse_pos    = { mouse_v.x, mouse_v.y };
	int tot_lines     = editor.get_total_lines();

	switch
	{
		case rl::is_mouse_button_pressed(LEFT):
			if (mouse_pos.y >= (float)(height - lm.footer_height) && mouse_pos.y <= (float)height)
			{
				String file_disp = tab.filepath.len > 0 ? tab.filepath : "untitled.c3";
				String mod_str   = tab.is_modified ? " [+]" : "";
				String save_str  = (editor.save_msg_timer > 0.0f) ? " [SAVED]" : "";
				String left_s    = string::tformat("%s%s%s", file_disp, mod_str, save_str);
				int left_w       = (int)left_s.len * lm.char_width + 24;

				if (mouse_pos.x >= 0.0f && mouse_pos.x <= (float)left_w)
				{
					editor.active_modal = SAVE_AS;
					editor.modal_input.set_text(tab.filepath);
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
					TabDocument* t  = &editor.tabs[i];
					String name_str = t.filepath.file_tbasename() ?? t.filepath;
					if (name_str.len == 0) name_str = "untitled.c3";

					String tab_title = string::tformat("%d: %s%s", i + 1, name_str, t.is_modified ? " *" : "");
					int title_w      = (int)tab_title.len * lm.char_width;
					int tab_w        = title_w + close_box_w + 16;

					if (tab_x + tab_w > screen_w - 40)
					{
						tab_w = screen_w - 40 - tab_x;
					}
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
				float thumb_h      = math::max(20.0f, track_h * (float)lm.visible_lines / (float)tot_lines);
				float scrollable_h = track_h - thumb_h;
				float thumb_y      = lm.scrollbar_rect.y + (scrollable_h * (float)tab.scroll_line / max_scroll);

				editor.scrollbar_dragging = true;
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

			editor.mouse_down = true;
			double now = rl::get_time();
			BytePos clicked_pos = editor.get_pos_from_mouse(mouse_pos, lm);
			float dx = mouse_pos.x - editor.last_click_pos.x;
			float dy = mouse_pos.y - editor.last_click_pos.y;

			Cursor* cur = editor.primary_cursor();
			if (now - editor.last_click_time < DOUBLE_CLICK_TIME && (dx * dx + dy * dy) < 100.0f)
			{
				TextRange bounds = get_word_bounds(&tab.table, clicked_pos);
				editor.word_selecting = true;
				editor.word_sel_anchor_start = bounds.start;
				editor.word_sel_anchor_end = bounds.end;
				cur.anchor = bounds.start;
				cur.pos = bounds.end;
				cur.target_col = editor.get_col(cur.pos);
				editor.last_click_time = 0.0;
			}
			else
			{
				editor.word_selecting = false;
				cur.pos = clicked_pos;
				if (!editor.modifiers.shift) cur.anchor = cur.pos;
				cur.target_col = editor.get_col(cur.pos);
				editor.last_click_time = now;
				editor.last_click_pos = mouse_pos;
			}
			if (!editor.modifiers.shift && !editor.modifiers.alt && tab.cursors.len() > 1)
			{
				Cursor single = *cur;
				tab.cursors.clear();
				tab.cursors.push(single);
			}
			editor.reset_cursor_blink();

		case editor.scrollbar_dragging && rl::is_mouse_button_down(LEFT):
			if (tot_lines > lm.visible_lines)
			{
				float max_scroll   = (float)(tot_lines - lm.visible_lines);
				float track_h      = lm.scrollbar_rect.height;
				float thumb_h      = math::max(20.0f, track_h * (float)lm.visible_lines / (float)tot_lines);
				float scrollable_h = track_h - thumb_h;
				float new_thumb_y  = mouse_pos.y - editor.scrollbar_drag_offset_y;
				float norm         = scrollable_h > 0.0f ? (new_thumb_y - lm.scrollbar_rect.y) / scrollable_h : 0.0f;
				tab.scroll_line = math::clamp((int)math::round(norm * max_scroll), 0, (int)max_scroll);
				editor.reset_cursor_blink();
			}

		case editor.mouse_down && rl::is_mouse_button_down(LEFT):
			BytePos cur_pos = editor.get_pos_from_mouse(mouse_pos, lm);
			Cursor* cur_p = editor.primary_cursor();
			if (editor.word_selecting)
			{
				TextRange cur_bounds = get_word_bounds(&tab.table, cur_pos);
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
			cur_p.target_col = editor.get_col(cur_p.pos);
			editor.reset_cursor_blink();

		case rl::is_mouse_button_released(LEFT):
			editor.mouse_down = false;
			editor.word_selecting = false;
			editor.scrollbar_dragging = false;
	}

	float wheel = rl::get_mouse_wheel_move();
	if (wheel != 0.0f)
	{
		switch
		{
			case editor.modifiers.ctrl:
				editor.font_scale = math::clamp(editor.font_scale + (wheel > 0.0f ? 0.5f : -0.5f), 1.0f, 6.0f);
			case editor.modifiers.shift:
				tab.scroll_col = math::max(0, tab.scroll_col - (int)wheel * HORIZONTAL_SCROLL_STEP);
			default:
				tab.scroll_line = math::clamp(
					tab.scroll_line - (int)wheel * VERTICAL_SCROLL_STEP,
					0,
					math::max(0, tot_lines - 1)
				);
		}
		editor.reset_cursor_blink();
	}

	bool page_held = rl::is_key_down(PAGE_UP) || rl::is_key_down(PAGE_DOWN);
	editor.page_hold_timer = page_held ? editor.page_hold_timer + dt : 0.0f;

	for (int k = 32; k < 349; k++)
	{
		RLKeyboardKey key = (RLKeyboardKey)k;
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
					case editor.modifiers.ctrl && (key == Z || key == Y):
					case editor.modifiers.alt && (key == UP || key == DOWN):
						is_triggered = key_pressed_or_repeat(key);
					default:
						is_triggered = rl::is_key_pressed(key);
				}
		}
		if (is_triggered)
		{
			EditorCommand cmd = command::resolve_key_command(key, editor.modifiers);
			if (cmd != CMD_NONE) dispatch_command(&editor, cmd, lm, dt);
		}
	}

	int cp = rl::get_char_pressed();
	while (cp > 0)
	{
		if (cp >= 32 && (!editor.modifiers.ctrl || editor.modifiers.alt))
		{
			editor.insert_codepoint((Char32)cp);
			editor.ensure_cursor_visible(lm);
		}
		cp = rl::get_char_pressed();
	}
}

fn void update_draw_frame() => @pool()
{
	font::init_font_texture();
	float dt     = rl::get_frame_time();
	int screen_w = rl::get_screen_width();
	int height   = rl::get_screen_height();
	if (screen_w <= 0) screen_w = 1600;
	if (height <= 0) height = 900;

	if (editor.save_msg_timer > 0.0f)
	{
		editor.save_msg_timer -= dt;
		if (editor.save_msg_timer < 0.0f) editor.save_msg_timer = 0.0f;
	}

	if (!editor.initialized)
	{
		editor.init();
	}

	TabDocument* tab        = editor.active_tab();
	BytePos prev_cursor_pos = editor.primary_cursor().pos;
	BytePos prev_table_len  = tab.table.len();

	LayoutMetrics lm = compute_layout(screen_w, height, editor.font_scale, editor.get_total_lines(), true);
	update_editor_events(&lm, dt, screen_w, height);

	tab = editor.active_tab();
	if (editor.primary_cursor().pos != prev_cursor_pos || tab.table.len() != prev_table_len)
	{
		editor.reset_cursor_blink();
	}

	editor.render(screen_w, height, &lm);
}

fn int main(String[] args) @winmain
{
	editor.init();

	if (args.len > 1)
	{
		for (sz i = 1; i < args.len; i++)
		{
			String filepath = args[i];
			String content  = "";
			if (try c = file::load_temp(filepath)) content = (String)c;
			editor.open_new_tab(filepath, true, content);
		}
		editor.active_tab_index = 0;
	}
	else
	{
		editor.open_new_tab(
			"untitled.c3",
			false,
`/* c3ed

 FILE & TAB OPERATIONS                         LINE EDITING
 ---------------------                         ------------
 New / Close Tab    Ctrl + T / Ctrl + W        Toggle Comment    Ctrl + / or Ctrl + M
 Next / Prev Tab    Ctrl + Tab / Shift+Tab     Duplicate Line    Ctrl + D
 Select Tab 1..9    Alt + 1 .. Alt + 9         Delete Line       Ctrl + Shift + K
 Open / Save        Ctrl + P / Ctrl + S        Move Line         Alt + Up / Down
 Save As / Quit     Ctrl+Shift+S / Ctrl+Q

 NAVIGATION & SEARCH                           TEXT & HISTORY
 -------------------                           --------------
 Find in Buffer     Ctrl + F                   Undo / Redo       Ctrl + Z / Ctrl + Y
 Find & Replace     Ctrl + H                   Cut / Copy / Paste Ctrl + X / C / V
 Find Next/Prev     F3 / Shift + F3            Indent / Outdent  Tab / Shift + Tab
 Match Case         Alt+1 / Ctrl+1 / Alt+C     Lower / Uppercase Ctrl + U / Shift + U
 Workspace Grep     Ctrl + Shift + F           Select All        Ctrl + A
 Go to Line         Ctrl + G                   Bracket Jump      Ctrl + B
 Add Caret Up/Dn    Ctrl + Shift + Up/Down

 MOVEMENT & VIEW
 ---------------
 Word Jumps         Ctrl + Left / Right
 Select File Bounds Ctrl + Home / End
 Zoom Font          Ctrl + (+ or -), or Ctrl + Wheel
 Mouse              Click caret, Double-click word, Drag select, Scroll wheel, Tab bar click/close

*/

`
			"module main;\nimport std;\n\nfn int main(String[] args)\n{\n\tio::printn(\"Hello, World!\");\n\treturn 0;\n}\n"
		);
	}
	$if $feat(FAST):
	rl::set_trace_log_level(NONE) ;
	$endif

	rl::set_config_flags(WINDOW_RESIZABLE | WINDOW_HIDDEN);
	rl::init_window(1920, 1080, "C3 Text Editor");
	rl::set_exit_key((RLKeyboardKey)0);
	$if env::WASM:
		emscripten_set_main_loop(&update_draw_frame, 60, 1);
	$else
		rl::set_target_fps(60);
		rl::maximize_window();
		update_draw_frame();
		rl::clear_window_state(RLConfigFlag.WINDOW_HIDDEN);

		while (!editor.should_exit)
		{
			if (rl::window_should_close())
			{
				bool any_modified = false;
				foreach (&t : editor.tabs)
				{
					if (t.is_modified)
					{
						any_modified = true;
						break;
					}
				}
				if (any_modified)
				{
					editor.active_modal = CONFIRM_EXIT;
				}
				else
				{
					editor.should_exit = true;
				}
			}
			update_draw_frame();
		}
		rl::close_window();
	$endif

	return 0;
}

/*
 Stub GLFW internal joystick initialization to prevent scanning /dev/input/...
 This makes the start faster but, needs the linker flag `-z "-Wl,--allow-multiple-definition"`
*/
fn bool _glfwInitJoysticksLinux() @cname("_glfwInitJoysticksLinux") @export @feat(!WASM & FAST) => true;
fn void _glfwTerminateJoysticksLinux() @cname("_glfwTerminateJoysticksLinux") @export @feat(!WASM & FAST) {}
fn bool _glfwPlatformInitJoysticks() @cname("_glfwPlatformInitJoysticks") @export @feat(!WASM & FAST) => true;
fn void _glfwPlatformTerminateJoysticks() @cname("_glfwPlatformTerminateJoysticks") @export @feat(!WASM & FAST) {}
fn void _glfwDetectJoystickConnectionLinux() @cname("_glfwDetectJoystickConnectionLinux") @export @feat(!WASM & FAST) {}

alias Em_callback_func = fn void();
extern fn void emscripten_set_main_loop(Em_callback_func func, int fps, int simulate_infinite_loop);module app;
import std;

enum BufferSource : char
{
	ORIGINAL,
	ADD
}

struct Piece
{
	BufferSource source;
	sz offset;
	sz length;
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

struct PieceTable (Printable)
{
	char[] original_buffer;
	char* add_buffer;
	sz add_capacity;
	sz add_len;

	List{Piece} pieces;
	Allocator allocator;

	List{UndoTransaction*} undo_stack;
	List{UndoTransaction*} redo_stack;
	UndoTransaction* active_transaction;
	bool in_transaction;

	sz cached_total_length;
}

const sz DEFAULT_ADD_CAPACITY = 4096;

fn void PieceTable.init(&self, Allocator allocator = mem, char[] initial_text = { })
{
	self.allocator = allocator;
	self.original_buffer = initial_text;

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
	*self = { };
}

fn void free_undo_transaction(Allocator allocator, UndoTransaction* tx) @private
{
	if (!tx)
	{
		return;
	}
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
	if (self.in_transaction)
	{
		return;
	}
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
	if (!self.in_transaction || !self.active_transaction)
	{
		return;
	}

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

fn sz PieceTable.len(&self) @operator(len) @inline
{
	return self.cached_total_length;
}

fn char PieceTable.get(&self, sz index) @operator([])
{
	assert(index < self.cached_total_length, "PieceTable index out of bounds");
	sz current_offset = 0;

	foreach (&p : self.pieces)
	{
		if (index < current_offset + p.length)
		{
			sz local_idx = index - current_offset;
			if (p.source == ORIGINAL)
			{
				return self.original_buffer[p.offset + local_idx];
			}
			else
			{
				return self.add_buffer[p.offset + local_idx];
			}
		}
		current_offset += p.length;
	}
	unreachable("Unreachable piece table index search");
}

fn void PieceTable.ensure_add_capacity(&self, sz needed)
{
	if (self.add_len + needed <= self.add_capacity)
	{
		return;
	}
	sz new_cap = math::max(self.add_capacity * 2, self.add_len + needed + 1024);
	self.add_buffer = alloc::realloc(self.allocator, self.add_buffer, new_cap);
	self.add_capacity = new_cap;
}

fn sz count_newlines(char[] text) @private
{
	sz count = 0;
	foreach (c : text)
	{
		if (c == '\n')
		{
			count++;
		}
	}
	return count;
}

fn Piece make_sub_piece(PieceTable* pt, Piece p, sz local_start, sz local_len) @private
{
	char[] piece_bytes = (p.source == ORIGINAL) ? pt.original_buffer[p.offset + local_start:local_len]
		: pt.add_buffer[p.offset + local_start:local_len];

	sz lines = count_newlines(piece_bytes);
	return { .source = p.source, .offset = p.offset + local_start, .length = local_len, .line_count = lines };
}

fn void PieceTable.recalculate_total_length(&self)
{
	sz total = 0;
	foreach (&p : self.pieces)
	{
		total += p.length;
	}
	self.cached_total_length = total;
}

fn void PieceTable.insert_bytes(&self, sz pos, char[] bytes)
{
	if (bytes.len == 0)
	{
		return;
	}

	self.ensure_add_capacity(bytes.len);
	sz add_offset = self.add_len;
	mem::copy(&self.add_buffer[add_offset], bytes.ptr, bytes.len);
	self.add_len += bytes.len;

	sz lines = count_newlines(bytes);
	Piece new_p = { .source = ADD, .offset = add_offset, .length = bytes.len, .line_count = lines };

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
			sz current_offset = 0;
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
					sz left_len  = pos - current_offset;
					sz right_len = p.length - left_len;

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
	self.cached_total_length += bytes.len;
}

fn void PieceTable.replace_range(&self, sz start, sz end, char[] bytes)
{
	if (start == end || start >= self.cached_total_length)
	{
		self.insert_bytes(start, bytes);
		return;
	}
	if (bytes.len == 0)
	{
		self.delete_range(start, end);
		return;
	}

	sz s = math::min(start, self.cached_total_length);
	sz e = math::min(end, self.cached_total_length);
	if (s >= e)
	{
		self.insert_bytes(s, bytes);
		return;
	}

	self.ensure_add_capacity(bytes.len);
	sz add_offset = self.add_len;
	mem::copy(&self.add_buffer[add_offset], bytes.ptr, bytes.len);
	self.add_len += bytes.len;

	sz lines = count_newlines(bytes);
	Piece new_p = { .source = ADD, .offset = add_offset, .length = bytes.len, .line_count = lines };

	sz start_piece_idx    = 0;
	sz start_local_offset = 0;
	sz end_piece_idx      = 0;
	sz end_local_offset   = 0;

	sz current_offset = 0;
	bool found_start  = false;
	bool found_end    = false;

	for (sz i = 0; i < self.pieces.len(); i++)
	{
		Piece p        = self.pieces[i];
		sz next_offset = current_offset + p.length;

		if (!found_start && s >= current_offset
			&& (s < next_offset || (s == next_offset && i + 1 == self.pieces.len())))
		{
			start_piece_idx = i;
			start_local_offset = s - current_offset;
			found_start = true;
		}

		if (!found_end && e > current_offset && e <= next_offset)
		{
			end_piece_idx = i;
			end_local_offset = e - current_offset;
			found_end = true;
			break;
		}
		current_offset = next_offset;
	}

	if (!found_start || !found_end) return;

	Piece start_p = self.pieces[start_piece_idx];
	Piece end_p   = self.pieces[end_piece_idx];

	PieceMutation mut;
	mut.piece_index = start_piece_idx;

	sz old_count = end_piece_idx - start_piece_idx + 1;
	mut.old_pieces.init(self.allocator, old_count);
	for (sz i = start_piece_idx; i <= end_piece_idx; i++)
	{
		mut.old_pieces.push(self.pieces[i]);
	}

	mut.new_pieces.init(self.allocator, 3);

	if (start_local_offset > 0)
	{
		Piece left_p = make_sub_piece(self, start_p, 0, start_local_offset);
		mut.new_pieces.push(left_p);
	}

	mut.new_pieces.push(new_p);

	if (end_local_offset < end_p.length)
	{
		Piece right_p = make_sub_piece(self, end_p, end_local_offset, end_p.length - end_local_offset);
		mut.new_pieces.push(right_p);
	}

	sz remaining = self.pieces.len() - (end_piece_idx + 1);
	if (remaining > 0)
	{
		mem::move(
			&self.pieces.entries[start_piece_idx],
			&self.pieces.entries[end_piece_idx + 1],
			remaining * Piece::size
		);
	}
	self.pieces.size -= old_count;

	for (sz i = 0; i < mut.new_pieces.len(); i++)
	{
		self.pieces.insert_at(start_piece_idx + i, mut.new_pieces[i]);
	}

	self.record_mutation(mut);
	self.cached_total_length = self.cached_total_length - (e - s) + bytes.len;
}

fn void PieceTable.delete_range(&self, sz start, sz end)
{
	if (start >= end || start >= self.cached_total_length)
	{
		return;
	}
	sz s = math::min(start, self.cached_total_length);
	sz e = math::min(end, self.cached_total_length);
	if (s >= e) return;

	sz start_piece_idx    = 0;
	sz start_local_offset = 0;
	sz end_piece_idx      = 0;
	sz end_local_offset   = 0;

	sz current_offset = 0;
	bool found_start  = false;
	bool found_end    = false;

	for (sz i = 0; i < self.pieces.len(); i++)
	{
		Piece p        = self.pieces[i];
		sz next_offset = current_offset + p.length;

		if (!found_start && s >= current_offset
			&& (s < next_offset || (s == next_offset && i + 1 == self.pieces.len())))
		{
			start_piece_idx = i;
			start_local_offset = s - current_offset;
			found_start = true;
		}

		if (!found_end && e > current_offset && e <= next_offset)
		{
			end_piece_idx = i;
			end_local_offset = e - current_offset;
			found_end = true;
			break;
		}
		current_offset = next_offset;
	}

	if (!found_start || !found_end) return;

	Piece start_p = self.pieces[start_piece_idx];
	Piece end_p   = self.pieces[end_piece_idx];

	PieceMutation mut;
	mut.piece_index = start_piece_idx;

	sz old_count = end_piece_idx - start_piece_idx + 1;
	mut.old_pieces.init(self.allocator, old_count);
	for (sz i = start_piece_idx; i <= end_piece_idx; i++)
	{
		mut.old_pieces.push(self.pieces[i]);
	}

	mut.new_pieces.init(self.allocator, 2);

	if (start_local_offset > 0)
	{
		Piece left_p = make_sub_piece(self, start_p, 0, start_local_offset);
		mut.new_pieces.push(left_p);
	}

	if (end_local_offset < end_p.length)
	{
		Piece right_p = make_sub_piece(self, end_p, end_local_offset, end_p.length - end_local_offset);
		mut.new_pieces.push(right_p);
	}

	sz remaining = self.pieces.len() - (end_piece_idx + 1);
	if (remaining > 0)
	{
		mem::move(
			&self.pieces.entries[start_piece_idx],
			&self.pieces.entries[end_piece_idx + 1],
			remaining * Piece::size
		);
	}
	self.pieces.size -= old_count;

	for (sz i = 0; i < mut.new_pieces.len(); i++)
	{
		self.pieces.insert_at(start_piece_idx + i, mut.new_pieces[i]);
	}

	self.record_mutation(mut);
	self.cached_total_length -= (e - s);
}

fn bool PieceTable.undo(&self, List{Cursor}* out_cursors)
{
	UndoTransaction*? tx_opt = self.undo_stack.pop();
	if (catch tx_opt) return false;
	UndoTransaction* tx = tx_opt;

	for (sz k = tx.mutations.len(); k > 0; k--)
	{
		PieceMutation* mut = &tx.mutations[k - 1];
		sz num_new         = mut.new_pieces.len();
		sz remaining       = self.pieces.len() - (mut.piece_index + num_new);
		if (remaining > 0)
		{
			mem::move(
				&self.pieces.entries[mut.piece_index],
				&self.pieces.entries[mut.piece_index + num_new],
				remaining * Piece::size
			);
		}
		self.pieces.size -= num_new;

		for (sz i = 0; i < mut.old_pieces.len(); i++)
		{
			self.pieces.insert_at(mut.piece_index + i, mut.old_pieces[i]);
		}
	}

	self.recalculate_total_length();

	out_cursors.clear();
	for (sz i = 0; i < tx.cursors_before.len(); i++)
	{
		out_cursors.push(tx.cursors_before[i]);
	}

	self.redo_stack.push(tx);
	return true;
}

fn bool PieceTable.redo(&self, List{Cursor}* out_cursors)
{
	UndoTransaction*? tx_opt = self.redo_stack.pop();
	if (catch tx_opt) return false;
	UndoTransaction* tx = tx_opt;

	for (sz k = 0; k < tx.mutations.len(); k++)
	{
		PieceMutation* mut = &tx.mutations[k];
		sz num_old         = mut.old_pieces.len();
		sz remaining       = self.pieces.len() - (mut.piece_index + num_old);
		if (remaining > 0)
		{
			mem::move(
				&self.pieces.entries[mut.piece_index],
				&self.pieces.entries[mut.piece_index + num_old],
				remaining * Piece::size
			);
		}
		self.pieces.size -= num_old;

		for (sz i = 0; i < mut.new_pieces.len(); i++)
		{
			self.pieces.insert_at(mut.piece_index + i, mut.new_pieces[i]);
		}
	}

	self.recalculate_total_length();

	out_cursors.clear();
	for (sz i = 0; i < tx.cursors_after.len(); i++)
	{
		out_cursors.push(tx.cursors_after[i]);
	}

	self.undo_stack.push(tx);
	return true;
}

fn void PieceTable.append_range_to_dstring(&self, DString* ds, sz start, sz end)
{
	sz s = math::min(start, self.cached_total_length);
	sz e = math::min(end, self.cached_total_length);
	if (s >= e)
	{
		return;
	}

	sz current_offset = 0;
	foreach (&p : self.pieces)
	{
		sz piece_start = current_offset;
		sz piece_end   = current_offset + p.length;

		if (piece_end > s && piece_start < e)
		{
			sz sub_start = s > piece_start ? s - piece_start : 0;
			sz sub_end   = e < piece_end ? e - piece_start : p.length;
			sz len       = sub_end - sub_start;

			char[] slice = (p.source == ORIGINAL) ? self.original_buffer[p.offset + sub_start:len]
				: self.add_buffer[p.offset + sub_start:len];

			ds.append_bytes(slice);
		}
		current_offset += p.length;
	}
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
		char[] slice = (p.source == ORIGINAL) ? self.original_buffer[p.offset:p.length]
			: self.add_buffer[p.offset:p.length];
		total += fmt.print((String)slice)!;
	}
	return total;
}module app;
import std, raylib6;

fn void Editor.render(&self, int screen_w, int height, LayoutMetrics* lm)
{
	TabDocument* tab = self.active_tab();
	rl::begin_drawing();
	rl::clear_background(COLOR_BG);

	rl::draw_rectangle(0, 0, screen_w, lm.tab_bar_height, COLOR_TAB_BG);
	rl::draw_rectangle(0, lm.tab_bar_height - 1, screen_w, 1, COLOR_TAB_BORDER);

	int tab_x       = 0;
	int tab_h       = lm.tab_bar_height;
	int close_box_w = lm.char_width * 2 + 10;

	for (sz i = 0; i < self.tabs.len(); i++)
	{
		TabDocument* t = &self.tabs[i];
		bool is_active = ((int)i == self.active_tab_index);

		String name_str = t.filepath.file_tbasename() ?? t.filepath;
		if (name_str.len == 0) name_str = "untitled.c3";

		String tab_title = string::tformat("%d: %s%s", i + 1, name_str, t.is_modified ? " *" : "");
		int title_w      = (int)tab_title.len * lm.char_width;
		int tab_w        = title_w + close_box_w + 16;

		if (tab_x + tab_w > screen_w - 40)
		{
			tab_w = screen_w - 40 - tab_x;
		}
		if (tab_w <= close_box_w + 10) break;

		Rgba bg_col = is_active ? COLOR_TAB_ACTIVE_BG : COLOR_TAB_BG;
		rl::draw_rectangle(tab_x, 0, tab_w, tab_h, bg_col);
		rl::draw_rectangle(tab_x + tab_w - 1, 0, 1, tab_h, COLOR_TAB_BORDER);

		if (is_active)
		{
			rl::draw_rectangle(tab_x, 0, tab_w, 2, COLOR_ACCENT_BLUE);
		}

		RLColor txt_col = is_active ? COLOR_TEXT_BRIGHT : COLOR_TEXT_MUTED;
		int txt_y       = (tab_h - lm.char_height) / 2;

		int label_w = tab_w - close_box_w - 8;
		if (label_w > 0)
		{
			rl::begin_scissor_mode(tab_x + 8, 0, label_w, tab_h);
			font::draw_text(tab_title, tab_x + 8, txt_y, lm.font_scale, txt_col);
			rl::end_scissor_mode();
		}

		int close_x   = tab_x + tab_w - close_box_w;
		int x_glyph_x = close_x + (close_box_w - lm.char_width) / 2;
		font::draw_char('x', x_glyph_x, txt_y, lm.font_scale, is_active ? COLOR_TEXT : COLOR_TEXT_MUTED);

		tab_x += tab_w;
	}

	rl::draw_rectangle(0, lm.tab_bar_height, lm.gutter_width - GUTTER_BORDER_W, lm.editor_h, COLOR_GUTTER_BG);
	rl::draw_rectangle(
		lm.gutter_width - GUTTER_BORDER_W,
		lm.tab_bar_height,
		GUTTER_BORDER_W,
		lm.editor_h,
		COLOR_GUTTER_BORDER
	);

	Cursor* primary = self.primary_cursor();
	LineCol cur_lc  = self.get_line_col(primary.pos);
	int cline       = cur_lc.line;
	int ccol        = cur_lc.col;

	for (int l = 0; l < lm.visible_lines; l++)
	{
		int line_idx = l + tab.scroll_line;
		if (line_idx >= self.get_total_lines()) break;

		int gy       = lm.text_start_y + l * lm.line_height;
		RLColor gcol = (line_idx == cline) ? COLOR_ACCENT_BLUE : COLOR_TEXT_MUTED;
		char[32] gbuf;
		String gs    = string::bformat(&gbuf, "%d", line_idx + 1);
		int text_w   = (int)gs.len * lm.char_width;
		int draw_x   = lm.gutter_width - GUTTER_BORDER_W - GUTTER_PADDING_RIGHT - text_w;
		font::draw_text(gs, draw_x, gy, lm.font_scale, gcol);
	}

	rl::begin_scissor_mode(lm.text_start_x, lm.text_start_y, lm.editor_w, lm.editor_h);

	foreach (&cur : tab.cursors)
	{
		int active_rel_line = self.get_line(cur.pos) - tab.scroll_line;
		if (active_rel_line >= 0 && active_rel_line < lm.visible_lines)
		{
			int hl_y = lm.text_start_y + active_rel_line * lm.line_height;
			rl::draw_rectangle(
				lm.text_start_x - TEXT_PADDING_X,
				hl_y - 1,
				lm.editor_w + TEXT_PADDING_X,
				lm.line_height,
				COLOR_LINE_HIGHLIGHT
			);
		}
	}

	int start_line = math::clamp(tab.scroll_line, 0, math::max(0, self.get_total_lines() - 1));
	int end_line   = math::min(self.get_total_lines(), start_line + lm.visible_lines + 1);

	BytePos start_pos = self.get_line_start_of_line(start_line);
	BytePos end_pos   = self.get_line_start_of_line(end_line);

	int cur_line               =  start_line;
	int cur_col                =  0;
	TokenType[1024] dummy_toks;
	TokenType[] line_tokens;
	int active_lex_line        = -1;
	BytePos cur_line_start_pos =  0;
	BytePos cur_line_len       =  0;

	for (BytePos p = start_pos; p < end_pos; p++)
	{
		if (cur_line != active_lex_line)
		{
			active_lex_line = cur_line;
			cur_line_start_pos = self.get_line_start_of_line(cur_line);
			BytePos line_end_pos = self.get_line_end(cur_line_start_pos);
			cur_line_len = line_end_pos - cur_line_start_pos;

			LineState start_state = (cur_line == 0) ? LineState.NORMAL
				: ((sz)cur_line - 1 < tab.line_states.len() ? tab.line_states[(sz)cur_line - 1] : LineState.NORMAL);

			line_tokens = (cur_line_len <= 1024) ? dummy_toks[:cur_line_len]
				: alloc::alloc_array(tmem, TokenType, cur_line_len);
			syntax::lex_slice(&tab.table, cur_line_start_pos, line_end_pos, start_state, line_tokens);
		}

		char c          = tab.table.get(p);
		int rel_line    = cur_line - tab.scroll_line;
		int rel_col     = cur_col - tab.scroll_col;
		bool is_visible = rel_line >= 0 && rel_line < lm.visible_lines;

		int px = lm.text_start_x + rel_col * lm.char_width;
		int py = lm.text_start_y + rel_line * lm.line_height;

		bool is_selected = false;
		foreach (&cur : tab.cursors)
		{
			if (cur.has_selection() && p >= cur.sel_start() && p < cur.sel_end())
			{
				is_selected = true;
				break;
			}
		}

		TokenType tok_type = DEFAULT;
		if (p >= cur_line_start_pos && (p - cur_line_start_pos) < cur_line_len)
		{
			tok_type = line_tokens[p - cur_line_start_pos];
		}

		switch (c)
		{
			case '\r':
				continue;
			case '\n':
				if (is_selected && is_visible)
				{
					rl::draw_rectangle(px, py, lm.char_width, lm.char_height + SELECTION_PADDING_Y, COLOR_SELECTION_BG);
				}
				cur_line++;
				cur_col = 0;
			case '\t':
				int tab_spaces = TAB_SIZE_SPACES - (cur_col % TAB_SIZE_SPACES);
				int tab_w = lm.char_width * tab_spaces;
				if (is_visible && px + tab_w >= lm.text_start_x && px < screen_w)
				{
					if (is_selected)
					{
						rl::draw_rectangle(px, py, tab_w, lm.char_height + SELECTION_PADDING_Y, COLOR_SELECTION_BG);
					}
					else
					{
						font::draw_tab_guide(px, py, tab_spaces, lm.char_width, lm.font_scale, COLOR_TAB_GUIDE);
					}
				}
				cur_col += tab_spaces;
			default:
				if (is_visible && px + lm.char_width >= lm.text_start_x && px < screen_w)
				{
					if (is_selected)
					{
						rl::draw_rectangle(
							px,
							py,
							lm.char_width,
							lm.char_height + SELECTION_PADDING_Y,
							COLOR_SELECTION_BG
						);
						font::draw_char((Char32)c, px, py, lm.font_scale, COLOR_TEXT_BRIGHT);
					}
					else
					{
						font::draw_char((Char32)c, px, py, lm.font_scale, tok_type.color);
					}
				}
				cur_col++;
		}
	}

	if (self.cursor_visible)
	{
		foreach (&cur : tab.cursors)
		{
			int cur_l        = self.get_line(cur.pos);
			int cur_c        = self.get_col(cur.pos);
			int active_rel_l = cur_l - tab.scroll_line;

			if (active_rel_l >= 0 && active_rel_l < lm.visible_lines)
			{
				int cx = lm.text_start_x + (cur_c - tab.scroll_col) * lm.char_width;
				int cy = lm.text_start_y + active_rel_l * lm.line_height;
				rl::draw_rectangle(cx, cy, CURSOR_WIDTH, lm.char_height + CURSOR_EXTRA_HEIGHT, COLOR_CURSOR);
			}
		}
	}

	rl::end_scissor_mode();

	if (self.get_total_lines() > lm.visible_lines)
	{
		int sb_w           = 10;
		int sb_x           = screen_w - sb_w - 2;
		int sb_y           = lm.text_start_y;
		int sb_h           = lm.editor_h;
		float thumb_h      = math::max(20.0f, (float)sb_h * (float)lm.visible_lines / (float)self.get_total_lines());
		float max_scroll   = (float)(self.get_total_lines() - lm.visible_lines);
		float scrollable_h = (float)sb_h - thumb_h;
		float thumb_y      = (float)sb_y + (scrollable_h * (float)tab.scroll_line / max_scroll);

		rl::draw_rectangle(sb_x, sb_y, sb_w, sb_h, COLOR_HEADER_BG);
		Rgba thumb_col = self.scrollbar_dragging ? COLOR_SCROLLBAR_ACT : COLOR_SCROLLBAR;
		rl::draw_rectangle(sb_x + 1, (int)thumb_y, sb_w - 2, (int)thumb_h, thumb_col);
	}

	if (self.active_modal != NONE)
	{
		self.render_modal(screen_w, height, lm);
	}

	int footer_y      = (int)lm.footer_rect.y;
	int footer_text_y = footer_y + (lm.footer_height - lm.char_height) / 2;
	rl::draw_rectangle(0, footer_y, screen_w, lm.footer_height, COLOR_FOOTER_BG);

	String file_disp = tab.filepath.len > 0 ? tab.filepath : "untitled.c3";
	String mod_str   = tab.is_modified ? " [+]" : "";
	String save_str  = (self.save_msg_timer > 0.0f) ? " [SAVED]" : "";
	String left_s    = string::tformat("%s%s%s", file_disp, mod_str, save_str);
	font::draw_text(left_s, 12, footer_text_y, lm.font_scale, COLOR_TEXT_BRIGHT);

	int mid_x = screen_w / 2 - 160;
	if (self.modifiers.shift)
	{
		font::draw_text("[SHIFT]", mid_x, footer_text_y, lm.font_scale, COLOR_ACCENT_GREEN);
		mid_x += 8 * lm.char_width;
	}
	if (self.modifiers.ctrl)
	{
		font::draw_text("[CTRL]", mid_x, footer_text_y, lm.font_scale, COLOR_ACCENT_BLUE);
		mid_x += 7 * lm.char_width;
	}
	if (self.modifiers.alt)
	{
		font::draw_text("[ALT]", mid_x, footer_text_y, lm.font_scale, COLOR_ACCENT_YELLOW);
		mid_x += 6 * lm.char_width;
	}
	if (tab.cursors.len() > 1)
	{
		String cur_count_str = string::tformat("[%d CARETS]", tab.cursors.len());
		font::draw_text(cur_count_str, mid_x, footer_text_y, lm.font_scale, COLOR_ACCENT_BLUE);
		mid_x += ((int)cur_count_str.len + 1) * lm.char_width;
	}

	Cursor* pcur = self.primary_cursor();
	sz sel_count = pcur.pos > pcur.anchor ? pcur.pos - pcur.anchor : pcur.anchor - pcur.pos;
	if (sel_count > 0)
	{
		String sel_s = string::tformat("SEL: %d", sel_count);
		font::draw_text(sel_s, mid_x, footer_text_y, lm.font_scale, COLOR_ACCENT_YELLOW);
	}

	String right_str = string::tformat(
		"TAB %d/%d  LN: %d  COL: %d   LINES: %d  CHARS: %d",
		self.active_tab_index + 1,
		self.tabs.len(),
		cline + 1,
		ccol + 1,
		self.get_total_lines(),
		tab.table.len()
	);
	int right_w      = (int)right_str.len * lm.char_width;
	font::draw_text(right_str, screen_w - right_w - 12, footer_text_y, lm.font_scale, COLOR_HEADER_MUTED);

	rl::end_drawing();
}

fn void Editor.render_modal(&self, int screen_w, int height, LayoutMetrics* lm)
{
	String prompt         = "";
	String case_indicator = self.search_case_sensitive ? "Aa:ON" : "Aa:OFF";

	switch (self.active_modal)
	{
		case GOTO_LINE:         prompt = "GO TO LINE:";
		case FIND:              prompt = string::tformat("FIND (%d matches) [Alt+1/Alt+C %s] - [Up/Down] Prev/Next [Esc] Close", self.cached_match_count, case_indicator);
		case REPLACE:           prompt = string::tformat("FIND & REPLACE (%d matches) [Alt+1/Alt+C %s] - [Tab] Switch [Enter] Next [Ctrl+Enter] All", self.cached_match_count, case_indicator);
		case SAVE_AS:           prompt = "SAVE FILE AS:";
		case QUICK_OPEN:        prompt = string::tformat("QUICK FILE OPEN (Ctrl+P) - %d files", self.file_picker.items.len());
		case GLOBAL_GREP:       prompt = string::tformat("GLOBAL GREP (Ctrl+Shift+F) - %d matches", self.grep_picker.items.len());
		case CONFIRM_EXIT:      prompt = "UNSAVED CHANGES! Save all files before quitting?";
		case CONFIRM_CLOSE_TAB: prompt = "UNSAVED CHANGES! Save file before closing tab?";
		default: break;
	}

	Rect mrect      = self.get_modal_rect(lm, screen_w, height);
	int modal_x     = (int)mrect.x;
	int modal_y     = (int)mrect.y;
	int modal_w     = (int)mrect.width;
	int modal_h     = (int)mrect.height;
	int input_box_h = math::max(28, lm.char_height + 12);

	rl::draw_rectangle(modal_x - 4, modal_y - 4, modal_w + 8, modal_h + 8, COLOR_GUTTER_BORDER);
	rl::draw_rectangle(modal_x, modal_y, modal_w, modal_h, COLOR_HEADER_BG);

	int prompt_y = modal_y + 14;
	font::draw_text(prompt, modal_x + 16, prompt_y, lm.font_scale, COLOR_ACCENT_BLUE);

	if (self.active_modal == CONFIRM_EXIT || self.active_modal == CONFIRM_CLOSE_TAB)
	{
		RLVector2 mouse_v = rl::get_mouse_position();

		int btn_w = (modal_w - 32 - 24) / 3;
		int btn_h = input_box_h;
		int btn_y = modal_y + 14 + lm.char_height + 12;

		int btn1_x = modal_x + 16;
		int btn2_x = btn1_x + btn_w + 12;
		int btn3_x = btn2_x + btn_w + 12;

		bool hover1 = mouse_v.x >= (float)btn1_x && mouse_v.x < (float)(btn1_x + btn_w) && mouse_v.y >= (float)btn_y
			&& mouse_v.y < (float)(btn_y + btn_h);
		bool hover2 = mouse_v.x >= (float)btn2_x && mouse_v.x < (float)(btn2_x + btn_w) && mouse_v.y >= (float)btn_y
			&& mouse_v.y < (float)(btn_y + btn_h);
		bool hover3 = mouse_v.x >= (float)btn3_x && mouse_v.x < (float)(btn3_x + btn_w) && mouse_v.y >= (float)btn_y
			&& mouse_v.y < (float)(btn_y + btn_h);

		rl::draw_rectangle(btn1_x, btn_y, btn_w, btn_h, hover1 ? COLOR_ACCENT_GREEN : COLOR_BG);
		rl::draw_rectangle_lines(btn1_x, btn_y, btn_w, btn_h, COLOR_ACCENT_GREEN);
		String b1_str = "[Y] Save";
		int b1_text_w = (int)b1_str.len * lm.char_width;
		font::draw_text(
			b1_str,
			btn1_x + (btn_w - b1_text_w) / 2,
			btn_y + (btn_h - lm.char_height) / 2,
			lm.font_scale,
			hover1 ? COLOR_BG : COLOR_ACCENT_GREEN
		);

		rl::draw_rectangle(btn2_x, btn_y, btn_w, btn_h, hover2 ? COLOR_ACCENT_RED : COLOR_BG);
		rl::draw_rectangle_lines(btn2_x, btn_y, btn_w, btn_h, hover2 ? COLOR_ACCENT_RED : COLOR_GUTTER_BORDER);
		String b2_str = "[N] Discard";
		int b2_text_w = (int)b2_str.len * lm.char_width;
		font::draw_text(
			b2_str,
			btn2_x + (btn_w - b2_text_w) / 2,
			btn_y + (btn_h - lm.char_height) / 2,
			lm.font_scale,
			hover2 ? COLOR_BG : COLOR_ACCENT_RED
		);

		rl::draw_rectangle(btn3_x, btn_y, btn_w, btn_h, hover3 ? COLOR_SELECTION_BG : COLOR_BG);
		rl::draw_rectangle_lines(btn3_x, btn_y, btn_w, btn_h, hover3 ? COLOR_ACCENT_BLUE : COLOR_GUTTER_BORDER);
		String b3_str = "[Esc] Cancel";
		int b3_text_w = (int)b3_str.len * lm.char_width;
		font::draw_text(
			b3_str,
			btn3_x + (btn_w - b3_text_w) / 2,
			btn_y + (btn_h - lm.char_height) / 2,
			lm.font_scale,
			hover3 ? COLOR_TEXT_BRIGHT : COLOR_TEXT_MUTED
		);
	}
	else if (self.active_modal == REPLACE)
	{
		int input_w  = modal_w - 32;
		int input1_y = modal_y + 14 + lm.char_height + 6;
		int input2_y = input1_y + input_box_h + 10;

		rl::draw_rectangle(modal_x + 16, input1_y, input_w, input_box_h, COLOR_BG);
		Rgba border1_col = (self.modal_focus_field == 0) ? COLOR_ACCENT_BLUE : COLOR_GUTTER_BORDER;
		rl::draw_rectangle_lines(modal_x + 16, input1_y, input_w, input_box_h, border1_col);

		rl::begin_scissor_mode(modal_x + 18, input1_y, input_w - 4, input_box_h);
		int text_draw1_y = input1_y + (input_box_h - lm.char_height) / 2;
		font::draw_text(self.modal_input.view(), modal_x + 24, text_draw1_y, lm.font_scale, COLOR_TEXT_BRIGHT);
		if (self.modal_focus_field == 0 && self.cursor_visible)
		{
			int cur_x = modal_x + 24 + self.modal_input.cursor_pos * lm.char_width;
			rl::draw_rectangle(cur_x, text_draw1_y, CURSOR_WIDTH, lm.char_height, COLOR_CURSOR);
		}
		rl::end_scissor_mode();

		rl::draw_rectangle(modal_x + 16, input2_y, input_w, input_box_h, COLOR_BG);
		Rgba border2_col = (self.modal_focus_field == 1) ? COLOR_ACCENT_BLUE : COLOR_GUTTER_BORDER;
		rl::draw_rectangle_lines(modal_x + 16, input2_y, input_w, input_box_h, border2_col);

		rl::begin_scissor_mode(modal_x + 18, input2_y, input_w - 4, input_box_h);
		int text_draw2_y = input2_y + (input_box_h - lm.char_height) / 2;
		font::draw_text(self.modal_replace_input.view(), modal_x + 24, text_draw2_y, lm.font_scale, COLOR_TEXT_BRIGHT);
		if (self.modal_focus_field == 1 && self.cursor_visible)
		{
			int cur_x = modal_x + 24 + self.modal_replace_input.cursor_pos * lm.char_width;
			rl::draw_rectangle(cur_x, text_draw2_y, CURSOR_WIDTH, lm.char_height, COLOR_CURSOR);
		}
		rl::end_scissor_mode();
	}
	else
	{
		int input_y = modal_y + 14 + lm.char_height + 8;
		int input_w = modal_w - 32;

		rl::draw_rectangle(modal_x + 16, input_y, input_w, input_box_h, COLOR_BG);
		rl::draw_rectangle_lines(modal_x + 16, input_y, input_w, input_box_h, COLOR_GUTTER_BORDER);

		rl::begin_scissor_mode(modal_x + 18, input_y, input_w - 4, input_box_h);

		int text_draw_y = input_y + (input_box_h - lm.char_height) / 2;
		font::draw_text(self.modal_input.view(), modal_x + 24, text_draw_y, lm.font_scale, COLOR_TEXT_BRIGHT);

		if (self.cursor_visible)
		{
			int cur_x = modal_x + 24 + self.modal_input.cursor_pos * lm.char_width;
			rl::draw_rectangle(cur_x, text_draw_y, CURSOR_WIDTH, lm.char_height, COLOR_CURSOR);
		}

		rl::end_scissor_mode();

		if (self.active_modal == QUICK_OPEN)
		{
			int list_y = input_y + input_box_h + 10;
			int list_h = modal_y + modal_h - list_y - 14;
			int row_h  = math::max(24, lm.line_height);

			rl::draw_rectangle(modal_x + 16, list_y, input_w, list_h, COLOR_BG);
			rl::draw_rectangle_lines(modal_x + 16, list_y, input_w, list_h, COLOR_GUTTER_BORDER);
			rl::begin_scissor_mode(modal_x + 16, list_y, input_w, list_h);

			int max_rows = list_h / row_h;
			for (int r = 0; r < max_rows && r < (int)self.file_picker.items.len(); r++)
			{
				int idx = r + self.file_picker.scroll_offset;
				if (idx >= (int)self.file_picker.items.len()) break;
				int ry = list_y + r * row_h + 2;
				if (idx == self.file_picker.selected_index)
				{
					rl::draw_rectangle(modal_x + 18, ry - 1, input_w - 4, row_h - 2, COLOR_SELECTION_BG);
				}
				RLColor text_col = (idx == self.file_picker.selected_index) ? COLOR_TEXT_BRIGHT : COLOR_TEXT;
				font::draw_text(
					self.file_picker.items[(sz)idx],
					modal_x + 24,
					ry + (row_h - lm.char_height) / 2,
					lm.font_scale,
					text_col
				);
			}
			rl::end_scissor_mode();
		}
		else if (self.active_modal == GLOBAL_GREP)
		{
			int list_y = input_y + input_box_h + 10;
			int list_h = modal_y + modal_h - list_y - 14;
			int row_h  = math::max(24, lm.line_height);

			rl::draw_rectangle(modal_x + 16, list_y, input_w, list_h, COLOR_BG);
			rl::draw_rectangle_lines(modal_x + 16, list_y, input_w, list_h, COLOR_GUTTER_BORDER);
			rl::begin_scissor_mode(modal_x + 16, list_y, input_w, list_h);

			int max_rows = list_h / row_h;
			for (int r = 0; r < max_rows && r < (int)self.grep_picker.items.len(); r++)
			{
				int idx = r + self.grep_picker.scroll_offset;
				if (idx >= (int)self.grep_picker.items.len()) break;
				int ry            = list_y + r * row_h + 2;
				SearchMatch match = self.grep_picker.items[(sz)idx];
				if (idx == self.grep_picker.selected_index)
				{
					rl::draw_rectangle(modal_x + 18, ry - 1, input_w - 4, row_h - 2, COLOR_SELECTION_BG);
				}
				String match_str = string::tformat("%s:%d: %s", match.filepath, match.line_num, match.line_text);
				RLColor text_col = (idx == self.grep_picker.selected_index) ? COLOR_TEXT_BRIGHT : COLOR_TEXT;
				font::draw_text(match_str, modal_x + 24, ry + (row_h - lm.char_height) / 2, lm.font_scale, text_col);
			}
			rl::end_scissor_mode();
		}
	}
}module app;
import std;

struct ScoredFile @local
{
	String filepath;
	int score;
}

struct ScoredGrepMatch @local
{
	SearchMatch match;
	int score;
}

const String[*] IGNORED_DIRECTORIES = {
	".git", ".venv", "venv", "env", "node_modules",
	".cache", ".vscode", ".idea", ".vs", "build",
	"bin", "obj", "target", "dist", "out",
	".pytest_cache", "__pycache__", ".mypy_cache",
	".svn", ".hg", ".dart_tool", ".gradle"
};

<*
 Checks if any directory segment in filepath matches a commonly ignored directory name.
 Supports both '/' and '\\' separators.
*>
fn bool is_ignored_path(String filepath)
{
	if (filepath.len == 0) return false;

	// Normalize check across path separators
	sz start = 0;
	sz len   = filepath.len;

	while (start < len)
	{
		sz end = start;
		while (end < len && filepath[end] != '/' && filepath[end] != '\\') end++;

		String segment = filepath[start:end - start];
		if (segment.len > 0)
		{
			// Check against ignored list
			foreach (ignored : IGNORED_DIRECTORIES)
			{
				if (segment == ignored) return true;
			}
		}

		start = end + 1;
	}

	return false;
}

fn bool is_binary_extension(String filepath)
{
	String ext = filepath.file_tbasename() ?? filepath;
	if (ext.ends_with(".png")  || ext.ends_with(".jpg")  || ext.ends_with(".jpeg") ||
	    ext.ends_with(".gif")  || ext.ends_with(".ico")  || ext.ends_with(".bmp")  ||
	    ext.ends_with(".exe")  || ext.ends_with(".dll")  || ext.ends_with(".so")   ||
	    ext.ends_with(".dylib")|| ext.ends_with(".o")    || ext.ends_with(".a")    ||
	    ext.ends_with(".lib")  || ext.ends_with(".bin")  || ext.ends_with(".dat")  ||
	    ext.ends_with(".wasm") || ext.ends_with(".zip")  || ext.ends_with(".tar")  ||
	    ext.ends_with(".gz")   || ext.ends_with(".7z")   || ext.ends_with(".pdf")  ||
	    ext.ends_with(".ttf")  || ext.ends_with(".otf")  || ext.ends_with(".woff") ||
	    ext.ends_with(".woff2")|| ext.ends_with(".mp3")  || ext.ends_with(".wav")  ||
	    ext.ends_with(".mp4")  || ext.ends_with(".mkv")  || ext.ends_with(".class"))
	{
		return true;
	}
	return false;
}

fn bool buffer_contains_null_byte(char[] buf)
{
	sz check_len = math::min(buf.len, (sz)1024);
	for (sz i = 0; i < check_len; i++)
	{
		if (buf[i] == '\0') return true;
	}
	return false;
}

fn bool fuzzy_match(String text, String pattern)
{
	if (pattern.len == 0) return true;
	sz text_idx = 0;
	sz pat_idx  = 0;
	while (text_idx < text.len && pat_idx < pattern.len)
	{
		char tc = text[text_idx].to_lower();
		char pc = pattern[pat_idx].to_lower();
		if (tc == pc) pat_idx++;
		text_idx++;
	}
	return pat_idx == pattern.len;
}

<*
 Matches text against a query. If the query contains multiple space-separated words,
 each word can match anywhere in the text (in any order) either as a substring or as a fuzzy match.
*>
fn bool line_matches_query(String text, String query)
{
	if (query.len == 0) return true;
	String text_lower  = text.to_lower_tcopy();
	String query_lower = query.to_lower_tcopy();

	if (!query_lower.contains_char(' '))
	{
		if (text_lower.contains(query_lower)) return true;
		return fuzzy_match(text_lower, query_lower);
	}

	Splitter tokens = query_lower.tokenize(" ");
	while (try token = tokens.next())
	{
		if (token.len == 0) continue;
		if (!text_lower.contains(token) && !fuzzy_match(text_lower, token))
		{
			return false;
		}
	}
	return true;
}

<*
 Compute relevance score for Quick Open file paths.
 Higher score = higher priority in search results.
*>
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
			case base == q:
				score += 10000;
			case fp == q:
				score += 9000;
			case base.starts_with(q):
				score += 6000;
			case base.contains(q):
				score += 4000;
			case fp.starts_with(q):
				score += 2500;
			case fp.contains(q):
				score += 1500;
			case fuzzy_match(base, q):
				score += 800;
			case fuzzy_match(fp, q):
				score += 200;
			default:
				return 0;
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
			case base == token:
				score += 3000;
			case base.starts_with(token):
				score += 1500;
			case base.contains(token):
				score += 1000;
			case fp.contains(token):
				score += 500;
			case fuzzy_match(base, token):
				score += 200;
			case fuzzy_match(fp, token):
				score += 50;
			default:
				return 0;
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
		if (fuzzy_match(line_lower, query_lower)) return 200;
		return 0;
	}

	Splitter tokens = query_lower.tokenize(" ");
	int score       = 0;
	while (try token = tokens.next())
	{
		if (token.len == 0) continue;
		switch
		{
			case line_lower.contains(token):
				score += 300;
			case fuzzy_match(line_lower, token):
				score += 50;
			default:
				return 0;
		}
	}
	return score;
}

fn int Editor.count_find_matches(&self)
{
	String query = self.modal_input.view();
	if (query.len == 0) return 0;

	TabDocument* tab = self.active_tab();
	String buf_str   = tab.table.to_tstring();
	sz qlen          = query.len;
	if (buf_str.len < qlen) return 0;

	int count   = 0;
	BytePos pos = 0;

	if (self.search_case_sensitive)
	{
		while (pos <= buf_str.len - qlen)
		{
			if (try idx = buf_str[pos..].index_of(query))
			{
				count++;
				pos += idx + qlen;
			}
			else
			{
				break;
			}
		}
	}
	else
	{
		String query_lower = query.to_lower_tcopy();
		String buf_lower   = buf_str.to_lower_tcopy();
		while (pos <= buf_lower.len - qlen)
		{
			if (try idx = buf_lower[pos..].index_of(query_lower))
			{
				count++;
				pos += idx + qlen;
			}
			else
			{
				break;
			}
		}
	}
	return count;
}

fn void Editor.find_next(&self, bool reverse, LayoutMetrics* lm)
{
	String query = self.modal_input.view();
	if (query.len == 0) return;
	TabDocument* tab = self.active_tab();
	String buf_str   = tab.table.to_tstring();
	sz qlen          = query.len;
	if (buf_str.len < qlen) return;

	String target_buf   = self.search_case_sensitive ? buf_str : buf_str.to_lower_tcopy();
	String target_query = self.search_case_sensitive ? query : query.to_lower_tcopy();

	Cursor* cur = self.primary_cursor();

	if (!reverse)
	{
		BytePos search_start = cur.sel_end();
		if (search_start >= target_buf.len) search_start = 0;
		if (try idx = target_buf[search_start..].index_of(target_query))
		{
			cur.anchor = search_start + idx;
			cur.pos = search_start + idx + qlen;
			cur.target_col = self.get_col(cur.pos);
			self.ensure_cursor_visible(lm);
			self.reset_cursor_blink();
			return;
		}
		if (try idx = target_buf[:search_start].index_of(target_query))
		{
			cur.anchor = idx;
			cur.pos = idx + qlen;
			cur.target_col = self.get_col(cur.pos);
			self.ensure_cursor_visible(lm);
			self.reset_cursor_blink();
		}
	}
	else
	{
		BytePos search_end = cur.sel_start();
		if (search_end > 0)
		{
			search_end--;
		}
		else
		{
			search_end = target_buf.len;
		}

		if (try idx = target_buf[:search_end].rindex_of(target_query))
		{
			cur.anchor = idx;
			cur.pos = idx + qlen;
			cur.target_col = self.get_col(cur.pos);
			self.ensure_cursor_visible(lm);
			self.reset_cursor_blink();
			return;
		}
		if (try idx = target_buf[search_end..].rindex_of(target_query))
		{
			cur.anchor = search_end + idx;
			cur.pos = search_end + idx + qlen;
			cur.target_col = self.get_col(cur.pos);
			self.ensure_cursor_visible(lm);
			self.reset_cursor_blink();
		}
	}
}

fn void Editor.find_from_current(&self, LayoutMetrics* lm)
{
	String query = self.modal_input.view();
	if (query.len == 0) return;
	TabDocument* tab = self.active_tab();
	String buf_str   = tab.table.to_tstring();
	sz qlen          = query.len;
	if (buf_str.len < qlen) return;

	String target_buf   = self.search_case_sensitive ? buf_str : buf_str.to_lower_tcopy();
	String target_query = self.search_case_sensitive ? query : query.to_lower_tcopy();

	Cursor* cur          = self.primary_cursor();
	BytePos search_start = cur.sel_start();
	if (search_start >= target_buf.len) search_start = 0;
	if (try idx = target_buf[search_start..].index_of(target_query))
	{
		cur.anchor = search_start + idx;
		cur.pos = search_start + idx + qlen;
		cur.target_col = self.get_col(cur.pos);
		self.ensure_cursor_visible(lm);
		self.reset_cursor_blink();
		return;
	}
	if (try idx = target_buf.index_of(target_query))
	{
		cur.anchor = idx;
		cur.pos = idx + qlen;
		cur.target_col = self.get_col(cur.pos);
		self.ensure_cursor_visible(lm);
		self.reset_cursor_blink();
	}
}

fn void Editor.replace_next(&self, LayoutMetrics* lm)
{
	String query = self.modal_input.view();
	if (query.len == 0) return;
	String replace_text = self.modal_replace_input.view();

	TabDocument* tab  = self.active_tab();
	Cursor* cur       = self.primary_cursor();
	BytePos sel_start = cur.sel_start();
	BytePos sel_end   = cur.sel_end();

	bool is_matching = false;
	if (sel_end - sel_start == query.len)
	{
		DString cur_sel;
		cur_sel.tinit();
		tab.table.append_range_to_dstring(&cur_sel, sel_start, sel_end);
		String sel_view = cur_sel.str_view();
		if (self.search_case_sensitive)
		{
			is_matching = (sel_view == query);
		}
		else
		{
			is_matching = (sel_view.to_lower_tcopy() == query.to_lower_tcopy());
		}
	}

	if (is_matching)
	{
		tab.table.begin_transaction(&tab.cursors);
		tab.table.replace_range(sel_start, sel_end, (char[])replace_text);
		self.update_line_index_on_edit(sel_start, sel_end - sel_start, replace_text.len);

		cur.pos = sel_start + replace_text.len;
		cur.anchor = cur.pos;
		cur.target_col = self.get_col(cur.pos);
		tab.table.end_transaction(&tab.cursors);
		tab.is_modified = true;
	}

	self.find_next(false, lm);
	self.cached_match_count = self.count_find_matches();
}

fn void Editor.replace_all(&self, LayoutMetrics* lm)
{
	String query = self.modal_input.view();
	if (query.len == 0) return;
	String replace_text = self.modal_replace_input.view();

	TabDocument* tab = self.active_tab();
	String buf_str   = tab.table.to_tstring();
	sz qlen          = query.len;
	if (buf_str.len < qlen) return;

	String target_buf   = self.search_case_sensitive ? buf_str : buf_str.to_lower_tcopy();
	String target_query = self.search_case_sensitive ? query : query.to_lower_tcopy();

	if (!target_buf.contains(target_query)) return;

	List{BytePos} matches;
	matches.tinit(64);

	BytePos pos = 0;
	while (pos <= target_buf.len - qlen)
	{
		if (try idx = target_buf[pos..].index_of(target_query))
		{
			matches.push(pos + idx);
			pos += idx + qlen;
		}
		else
		{
			break;
		}
	}

	if (matches.len() == 0) return;

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
	BytePos total_len = tab.table.len();

	tab.table.begin_transaction(&tab.cursors);
	tab.table.replace_range(0, total_len, (char[])new_doc);
	self.rebuild_line_index();

	Cursor* cur = self.primary_cursor();
	cur.pos = math::min(cur.pos, tab.table.len());
	cur.anchor = cur.pos;
	cur.target_col = self.get_col(cur.pos);
	tab.table.end_transaction(&tab.cursors);

	tab.is_modified = true;
	self.cached_match_count = 0;
	self.ensure_cursor_visible(lm);
}

fn void Editor.update_quick_open_results(&self)
{
	foreach (s : self.file_picker.items)
	{
		if (s.len > 0) mem::free(s.ptr);
	}
	self.file_picker.items.clear();
	self.file_picker.selected_index = 0;
	self.file_picker.scroll_offset = 0;

	String query = self.modal_input.view();
	@pool()
	{
		if (try files = path::ls(tmem, (Path)".", no_dirs: true, recursive: true, relative: true))
		{
			List{ScoredFile} candidates;
			candidates.tinit(files.len());

			foreach (file_path_obj : files)
			{
				String filepath = (String)file_path_obj;
				if (is_ignored_path(filepath)) continue;
				if (is_binary_extension(filepath)) continue;

				int score = score_quick_open_match(filepath, query);
				if (score > 0)
				{
					candidates.push({ filepath, score });
				}
			}

			if (candidates.len() > 0)
			{
				sort::quicksort(&candidates, fn int (ScoredFile a, ScoredFile b)
				{
					switch
					{
						case a.score > b.score: return -1;
						case a.score < b.score: return 1;
						default: return a.filepath.compare_to(b.filepath);
					}
				});

				sz count = math::min(candidates.len(), (sz)100);
				for (sz i = 0; i < count; i++)
				{
					self.file_picker.items.push(candidates[i].filepath.copy(mem));
				}
			}
		}
	};
}

fn void Editor.update_search_results(&self)
{
	foreach (&m : self.grep_picker.items)
	{
		if (m.filepath.len > 0) mem::free(m.filepath.ptr);
		if (m.line_text.len > 0) mem::free(m.line_text.ptr);
	}
	self.grep_picker.items.clear();
	self.grep_picker.selected_index = 0;
	self.grep_picker.scroll_offset = 0;

	String query = self.modal_input.view();
	if (query.len == 0) return;

	@pool()
	{
		if (try files = path::ls(tmem, (Path)".", no_dirs: true, recursive: true, relative: true))
		{
			List{ScoredGrepMatch} candidates;
			candidates.tinit(256);

			foreach (file_path_obj : files)
			{
				String filepath = (String)file_path_obj;
				if (is_ignored_path(filepath)) continue;
				if (is_binary_extension(filepath)) continue;

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
						// Flush any trailing line at EOF without trailing newline
						char[] remaining = scanner.flush();
						if (remaining.len > 0)
						{
							String line = (String)remaining;
							int score   = score_grep_match(line, query);
							if (score > 0)
							{
								SearchMatch match;
								match.filepath = filepath.copy(tmem);
								match.line_num = line_num;
								String trimmed = line.trim();
								if (trimmed.len > 120) trimmed = trimmed[:120];
								match.line_text = trimmed.copy(tmem);
								candidates.push({ match, score });
							}
						}
						break;
					}

					char[] line_slice = scanned_line;
					if (first_chunk)
					{
						first_chunk = false;
						if (buffer_contains_null_byte(line_slice)) break;
					}

					String line = (String)line_slice;
					int score   = score_grep_match(line, query);
					if (score > 0)
					{
						SearchMatch match;
						match.filepath = filepath.copy(tmem);
						match.line_num = line_num;

						String trimmed = line.trim();
						if (trimmed.len > 120) trimmed = trimmed[:120];
						match.line_text = trimmed.copy(tmem);

						candidates.push({ match, score });
						if (candidates.len() >= 500) break;
					}
					line_num++;
				}
				if (candidates.len() >= 500) break;
			}

			if (candidates.len() > 0)
			{
				sort::quicksort(&candidates, fn int (ScoredGrepMatch a, ScoredGrepMatch b)
				{
					switch
					{
						case a.score > b.score: return -1;
						case a.score < b.score: return 1;
						default: return a.match.filepath.compare_to(b.match.filepath);
					}
				});

				sz count = math::min(candidates.len(), (sz)200);
				for (sz i = 0; i < count; i++)
				{
					SearchMatch m = candidates[i].match;
					self.grep_picker.items.push({ m.filepath.copy(mem), m.line_num, m.line_text.copy(mem) });
				}
			}
		}
	};
}module app::syntax;
import std, raylib6;

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
	foreach (kw : TokenType.KEYWORD.keywords)
	{
		if (kw == w) return KEYWORD;
	}
	foreach (tw : TokenType.TYPE.keywords)
	{
		if (tw == w) return TYPE;
	}
	foreach (dw : TokenType.DIRECTIVE.keywords)
	{
		if (dw == w) return DIRECTIVE;
	}
	foreach (bw : TokenType.BUILTIN.keywords)
	{
		if (bw == w) return BUILTIN;
	}
	foreach (aw : TokenType.ATTRIBUTE.keywords)
	{
		if (aw == w) return ATTRIBUTE;
	}

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

<*
 Fast line lexer for state cache propagation (does not write to an output token buffer).
*>
fn LineState lex_state_only(PieceTable* pt, sz start, sz end, LineState initial_state)
{
	LineState state = initial_state;
	sz len          = end - start;
	sz idx          = 0;

	while (idx < len)
	{
		char c = pt.get(start + idx);
		switch
		{
			case state == IN_BLOCK_COMMENT:
				if (c == '*' && idx + 1 < len && pt.get(start + idx + 1) == '/')
				{
					state = NORMAL;
					idx++;
				}
				idx++;

			case state == IN_CONTRACT_COMMENT:
				if (c == '*' && idx + 1 < len && pt.get(start + idx + 1) == '>')
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

			case (c == '/' && idx + 1 < len && pt.get(start + idx + 1) == '/') || (c == '#' && idx + 1 < len && pt.get(start + idx + 1) == '!'):
				return state;

			case c == '/' && idx + 1 < len && pt.get(start + idx + 1) == '*':
				state = IN_BLOCK_COMMENT;
				idx += 2;

			case c == '<' && idx + 1 < len && pt.get(start + idx + 1) == '*':
				state = IN_CONTRACT_COMMENT;
				idx += 2;

			case c == '\\' && idx + 1 < len && pt.get(start + idx + 1) == '\\':
				return state;

			case c == '`':
				state = IN_RAW_STRING;
				idx++;

			case c == '"' || c == '\'':
				char q = c;
				idx++;
				while (idx < len)
				{
					char sc = pt.get(start + idx);
					idx++;
					switch
					{
						case sc == '\\' && idx < len:
							idx++;
						case sc == q:
							break;
					}
				}

			default:
				idx++;
		}
	}
	return state;
}

fn LineState lex_slice(PieceTable* pt, sz start, sz end, LineState initial_state, TokenType[] out_tokens)
{
	LineState state = initial_state;
	sz len          = end - start;
	sz idx          = 0;

	while (idx < len)
	{
		char c = pt.get(start + idx);
		switch
		{
			case state == IN_BLOCK_COMMENT:
				out_tokens[idx] = COMMENT;
				if (c == '*' && idx + 1 < len && pt.get(start + idx + 1) == '/')
				{
					state = NORMAL;
					idx++;
					out_tokens[idx] = COMMENT;
				}
				idx++;

			case state == IN_CONTRACT_COMMENT:
				out_tokens[idx] = CONTRACT;
				if (c == '*' && idx + 1 < len && pt.get(start + idx + 1) == '>')
				{
					state = NORMAL;
					idx++;
					out_tokens[idx] = CONTRACT;
				}
				idx++;

			case state == IN_RAW_STRING:
				out_tokens[idx] = STRING_LITERAL;
				if (c == '`')
				{
					state = NORMAL;
				}
				idx++;

			case (c == '/' && idx + 1 < len && pt.get(start + idx + 1) == '/') || (c == '#' && idx + 1 < len && pt.get(start + idx + 1) == '!'):
				while (idx < len)
				{
					out_tokens[idx++] = COMMENT;
				}

			case c == '/' && idx + 1 < len && pt.get(start + idx + 1) == '*':
				out_tokens[idx++] = COMMENT;
				out_tokens[idx++] = COMMENT;
				state = IN_BLOCK_COMMENT;

			case c == '<' && idx + 1 < len && pt.get(start + idx + 1) == '*':
				out_tokens[idx++] = CONTRACT;
				out_tokens[idx++] = CONTRACT;
				state = IN_CONTRACT_COMMENT;

			case c == '\\' && idx + 1 < len && pt.get(start + idx + 1) == '\\':
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
					char sc = pt.get(start + idx);
					out_tokens[idx++] = STRING_LITERAL;
					switch
					{
						case sc == '\\' && idx < len:
							out_tokens[idx++] = STRING_LITERAL;
						case sc == q:
							break;
					}
				}

			case c.is_digit():
				sz n_start = idx;
				while (idx < len && (pt.get(start + idx).is_alnum() || pt.get(start + idx) == '.' || pt.get(start + idx) == '_'))
				{
					idx++;
				}
				for (sz k = n_start; k < idx; k++)
				{
					out_tokens[k] = NUMBER;
				}

			case c.is_alpha() || c == '_' || c == '@' || c == '$':
				sz id_start = idx;
				while (idx < len && (pt.get(start + idx).is_alnum() || pt.get(start + idx) == '_' || pt.get(start + idx) == '$' || pt.get(start + idx) == '@'))
				{
					idx++;
				}
				sz id_len = idx - id_start;
				char[128] stack_word;
				char[] word_chars = (id_len <= 128) ? stack_word[:id_len] : alloc::alloc_array(tmem, char, id_len);
				for (sz k = 0; k < id_len; k++)
				{
					word_chars[k] = pt.get(start + id_start + k);
				}

				sz p = idx;
				while (p < len && (pt.get(start + p) == ' ' || pt.get(start + p) == '\t')) p++;
				bool is_fn = (p < len && pt.get(start + p) == '(');

				TokenType t = match_word_token((String)word_chars, is_fn);
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
}module app;
import std;

enum ModalKind : int
{
	NONE,
	FIND,
	REPLACE,
	GLOBAL_GREP,
	QUICK_OPEN,
	GOTO_LINE,
	SAVE_AS,
	CONFIRM_EXIT,
	CONFIRM_CLOSE_TAB
}

struct TextInputWidget
{
	char[256] buffer;
	int length;
	int cursor_pos;
}

fn void TextInputWidget.clear(&self)
{
	self.length = 0;
	self.cursor_pos = 0;
	self.buffer[0] = '\0';
}

fn void TextInputWidget.set_text(&self, String str)
{
	self.clear();
	sz copy_len = math::min(str.len, (sz)255);
	for (sz i = 0; i < copy_len; i++)
	{
		self.buffer[i] = str[i];
	}
	self.length = (int)copy_len;
	self.cursor_pos = self.length;
	self.buffer[self.length] = '\0';
}

fn String TextInputWidget.view(&self)
{
	return (String)self.buffer[:self.length];
}

fn bool TextInputWidget.insert_char(&self, char c)
{
	if (self.length >= 255)
	{
		return false;
	}
	for (int i = self.length; i > self.cursor_pos; i--)
	{
		self.buffer[i] = self.buffer[i - 1];
	}
	self.buffer[self.cursor_pos] = c;
	self.length++;
	self.cursor_pos++;
	self.buffer[self.length] = '\0';
	return true;
}

fn bool TextInputWidget.backspace(&self)
{
	if (self.cursor_pos <= 0)
	{
		return false;
	}
	for (int i = self.cursor_pos - 1; i < self.length - 1; i++)
	{
		self.buffer[i] = self.buffer[i + 1];
	}
	self.length--;
	self.cursor_pos--;
	self.buffer[self.length] = '\0';
	return true;
}

fn bool TextInputWidget.delete(&self)
{
	if (self.cursor_pos >= self.length)
	{
		return false;
	}
	for (int i = self.cursor_pos; i < self.length - 1; i++)
	{
		self.buffer[i] = self.buffer[i + 1];
	}
	self.length--;
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

fn void ListPickerWidget.select_next(&self)
{
	int total = (int)self.items.len();
	if (self.selected_index + 1 < total)
	{
		self.selected_index++;
		if (self.selected_index >= self.scroll_offset + self.visible_rows)
		{
			self.scroll_offset = self.selected_index - self.visible_rows + 1;
		}
	}
}

fn void ListPickerWidget.select_prev(&self)
{
	if (self.selected_index > 0)
	{
		self.selected_index--;
		if (self.selected_index < self.scroll_offset)
		{
			self.scroll_offset = self.selected_index;
		}
	}
}