// js/monaco-c3.js
import { getDocDbSymbols } from './compiler.js';

let isNavigating = false;

window.addEventListener('keydown', (e) => {
	if (e.key === 'F12' || e.keyCode === 123) {
		isNavigating = true;
		setTimeout(() => { isNavigating = false; }, 400);
	}
}, true);

window.addEventListener('mousedown', () => {
	isNavigating = true;
	setTimeout(() => { isNavigating = false; }, 400);
}, true);

export function setupMonacoC3(monaco) {
	monaco.languages.register({ id: 'c3' });
	monaco.languages.setMonarchTokensProvider('c3', getC3Definition());

	monaco.languages.setLanguageConfiguration('c3', {
		comments: {
			lineComment: '//',
			blockComment: ['/*', '*/'],
		},
		brackets: [
			['{', '}'],
			['[', ']'],
			['(', ')']
		],
		autoClosingPairs: [
			{ open: '{', close: '}' },
			{ open: '[', close: ']' },
			{ open: '(', close: ')' },
			{ open: '"', close: '"', notIn: ['string'] },
			{ open: "'", close: "'", notIn: ['string', 'comment'] },
			{ open: '`', close: '`', notIn: ['string', 'comment'] }
		],
		surroundingPairs: [
			{ open: '{', close: '}' },
			{ open: '[', close: ']' },
			{ open: '(', close: ')' },
			{ open: '"', close: '"' },
			{ open: "'", close: "'" },
			{ open: '`', close: '`' }
		]
	});

	monaco.languages.registerCompletionItemProvider('c3', {
		triggerCharacters: ['@', '$', ':'],

		provideCompletionItems: (model, position) => {
			const word = model.getWordUntilPosition(position);
			let range = {
				startLineNumber: position.lineNumber,
				endLineNumber: position.lineNumber,
				startColumn: word.startColumn,
				endColumn: word.endColumn
			};

			const lineContent = model.getLineContent(position.lineNumber);
			const precedingCharIndex = word.startColumn - 2;
			if (precedingCharIndex >= 0 && (lineContent[precedingCharIndex] === '@' || lineContent[precedingCharIndex] === '$')) {
				range.startColumn -= 1;
			}

			const c3Def = getC3Definition();
			const suggestions = [];
			const docDbSymbols = getDocDbSymbols();

			const lineUntilPosition = lineContent.substring(0, position.column - 1);
			const namespaceMatch = lineUntilPosition.match(/([a-zA-Z_0-9]+(?:::[a-zA-Z_0-9]+)*)::$/);

			let typedNamespace = "";
			if (namespaceMatch) {
				typedNamespace = namespaceMatch[1];
			}

			if (typedNamespace) {
				docDbSymbols.forEach(sym => {
					if (matchesNamespace(sym, typedNamespace)) {
						const signature = getSymbolSignature(sym);
						const docText = sym.docs ? (typeof sym.docs === 'string' ? sym.docs : (sym.docs.text || '')) : '';

						suggestions.push({
							label: sym.name,
							kind: getCompletionItemKind(sym, monaco),
							insertText: sym.name,
							range: range,
							detail: signature || sym.uid,
							documentation: docText ? { value: docText } : undefined
						});
					}
				});
			} else {
				c3Def.keywords.forEach(keyword => {
					suggestions.push({
						label: keyword,
						kind: monaco.languages.CompletionItemKind.Keyword,
						insertText: keyword,
						range: range
					});
				});

				c3Def.typeKeywords.forEach(type => {
					suggestions.push({
						label: type,
						kind: monaco.languages.CompletionItemKind.Class,
						insertText: type,
						range: range
					});
				});

				c3Def.attributes.forEach(attr => {
					suggestions.push({
						label: attr,
						kind: monaco.languages.CompletionItemKind.Property,
						insertText: attr,
						range: range
					});
				});

				const shortNamespaces = new Set();
				docDbSymbols.forEach(s => {
					if (s.uid && s.uid.startsWith('std::')) {
						const parts = s.uid.split('::');
						if (parts.length >= 3) {
							shortNamespaces.add(parts[parts.length - 2]);
						}
					} else if (s.uid && s.uid.includes('::')) {
						const parts = s.uid.split('::');
						if (parts.length >= 2) {
							shortNamespaces.add(parts[0]);
						}
					}
				});

				shortNamespaces.forEach(ns => {
					suggestions.push({
						label: ns,
						kind: monaco.languages.CompletionItemKind.Module,
						insertText: ns,
						range: range,
						detail: `Module ${ns}`,
						documentation: `Standard library module ${ns}`
					});
				});

				docDbSymbols.forEach(sym => {
					const compNames = getSymbolCompletionNames(sym);
					const signature = getSymbolSignature(sym);
					const docText = sym.docs ? (typeof sym.docs === 'string' ? sym.docs : (sym.docs.text || '')) : '';

					suggestions.push({
						label: compNames.label,
						kind: getCompletionItemKind(sym, monaco),
						insertText: compNames.insertText,
						filterText: compNames.filterText,
						range: range,
						detail: signature || sym.uid,
						documentation: docText ? { value: docText } : undefined
					});
				});
			}

			return { suggestions: suggestions };
		}
	});

	monaco.languages.registerHoverProvider('c3', {
		provideHover: (model, position) => {
			const fullId = getFullIdentifierAt(model, position);

			// 1. Try to find a global database symbol match first
			const matches = findSymbols(fullId);
			if (matches.length > 0) {
				return formatSymbolHover(matches[0]);
			}

			// 2. Local fallback upward scan (types, arrays, loop indexes, parameters)
			const localSym = findLocalVariable(model, position, fullId);
			if (localSym) {
				return {
					contents: [
						{ value: `\`\`\`c3\n${localSym.kind} ${localSym.type} ${localSym.name}\n\`\`\`` },
						{ value: localSym.docs },
						{ value: `*Declared on line ${localSym.line}*` }
					]
				};
			}
			return null;
		}
	});

	monaco.languages.registerDefinitionProvider('c3', {
		provideDefinition: (model, position) => {
			const fullId = getFullIdentifierAt(model, position);

			// 1. Check database definitions first
			const matches = findSymbols(fullId);
			const localSym = matches.find(s => s.file && s.file.includes('main.c3'));
			if (localSym) {
				const fileMatch = localSym.file.match(/(?:^|\/)(main\.c3):(\d+):(\d+)/);
				if (fileMatch) {
					const line = parseInt(fileMatch[2], 10);
					const col = parseInt(fileMatch[3], 10);
					return {
						uri: model.uri,
						range: new monaco.Range(line, col, line, col)
					};
				}
			}

			// 2. Scan upwards inside the active file scope for local variables
			const localVariable = findLocalVariable(model, position, fullId);
			if (localVariable) {
				return {
					uri: model.uri,
					range: new monaco.Range(localVariable.line, localVariable.column, localVariable.line, localVariable.column + fullId.length)
				};
			}

			// 3. Fallback to opening std library website specs
			if (isNavigating) {
				isNavigating = false; // Reset so it only fires once per click
				const stdSym = matches.find(s => s.file && !s.file.includes('main.c3'));
				if (stdSym) {
					const docUrl = `https://c3-lang.org/standard-library/docs.html#${stdSym.uid}`;
					window.open(docUrl, '_blank');
				}
			}
			return null;
		}
	});

	monaco.editor.defineTheme('c3PlaygroundTheme', {
		base: 'vs-dark',
		inherit: true,
		rules: [
			{ token: 'keyword', foreground: 'ff7b72', fontStyle: 'bold' },
			{ token: 'annotation', foreground: 'ffa657' },
			{ token: 'type.identifier', foreground: '7ee787' },
			{ token: 'type', foreground: '7ee787' },
			{ token: 'comment', foreground: '8b949e', fontStyle: 'italic' },
			{ token: 'string', foreground: 'a5d6ff' },
			{ token: 'number', foreground: '79c0ff' },
			{ token: 'operator', foreground: 'ff7b72' },
			{ token: 'function', foreground: 'd2a8ff' },
			{ token: 'identifier', foreground: 'C5E478' },
			{ token: 'delimiter', foreground: 'c9d1d9' }
		],
		colors: {
			'editor.background': '#1e293b',
			'editor.foreground': '#D39DD6',
			'editor.lineHighlightBackground': '#33415544',
			'editorCursor.foreground': '#38bdf8',
			'editor.selectionBackground': '#38bdf822',
			'editorLineNumber.foreground': '#475569',
			'editorLineNumber.activeForeground': '#38bdf8'
		}
	});
}

// Helpers
export function getFullIdentifierAt(model, position) {
	const lineContent = model.getLineContent(position.lineNumber);
	const col = position.column;
	const regex = /[a-zA-Z_0-9]+(?:::[a-zA-Z_0-9]+|(?:\.[a-zA-Z_0-9]+))*/g;
	let match;
	while ((match = regex.exec(lineContent)) !== null) {
		const start = match.index + 1;
		const end = start + match[0].length;
		if (col >= start && col <= end) {
			return match[0];
		}
	}
	const word = model.getWordAtPosition(position);
	return word ? word.word : "";
}

export function findSymbols(fullId) {
	const docDbSymbols = getDocDbSymbols();
	if (!docDbSymbols || docDbSymbols.length === 0 || !fullId) {
		return [];
	}

	const normalizedId = fullId.replace(/\./g, '::');
	let matches = docDbSymbols.filter(s => {
		const uidNorm = s.uid.replace(/\./g, '::');
		return uidNorm === normalizedId || uidNorm.endsWith('::' + normalizedId);
	});

	if (matches.length > 0) {
		return matches;
	}

	const namePart = fullId.split(/::|\./).pop();
	return docDbSymbols.filter(s => s.name === namePart);
}

export function findLocalVariable(model, position, word) {
	if (!model || !position || !word) return null;
	const currentLine = position.lineNumber;

	for (let i = currentLine; i >= 1; i--) {
		const line = model.getLineContent(i);
		const trimmed = line.trim();

		if (trimmed.startsWith('module ')) break;

		const declMatch = line.match(new RegExp(`\\b([a-zA-Z_0-9<>\\[\\]*?]+)\\s+(${word})\\b\\s*(?:[=,;]|$)`));
		if (declMatch) {
			const type = declMatch[1];
			return {
				name: word, kind: 'local variable', type: type,
				line: i, column: line.indexOf(word) + 1,
				docs: `Local variable of type \`${type}\``
			};
		}

		const foreachMatch = line.match(/foreach\s*\(\s*([a-zA-Z_0-9]+)\s*(?:,\s*([a-zA-Z_0-9]+))?\s*:\s*([a-zA-Z_0-9_]+)/);
		if (foreachMatch) {
			const firstVar = foreachMatch[1];
			const secondVar = foreachMatch[2];
			const iterable = foreachMatch[3];

			if (firstVar === word) {
				return {
					name: word, kind: 'loop variable', type: secondVar ? 'usz' : 'element',
					line: i, column: line.indexOf(word) + 1,
					docs: `Loop variable inside \`foreach\` over \`${iterable}\``
				};
			} else if (secondVar === word) {
				return {
					name: word, kind: 'loop variable', type: 'element',
					line: i, column: line.indexOf(word) + 1,
					docs: `Loop element variable inside \`foreach\` over \`${iterable}\``
				};
			}
		}

		const forMatch = line.match(new RegExp(`for\\s*\\(\\s*([a-zA-Z_0-9<>\\[\\]*?]+)\\s+(${word})\\b`));
		if (forMatch) {
			const type = forMatch[1];
			return {
				name: word, kind: 'loop variable', type: type,
				line: i, column: line.indexOf(word) + 1,
				docs: `Loop iterator variable of type \`${type}\``
			};
		}

		const fnMatch = line.match(/fn\s+([a-zA-Z_0-9*?]+)\s+([a-zA-Z_0-9]+)\s*\(([^)]*)\)/);
		if (fnMatch) {
			const paramsText = fnMatch[3];
			const params = paramsText.split(',').map(p => p.trim());
			for (const param of params) {
				const parts = param.split(/\s+/);
				if (parts.length >= 2) {
					const paramName = parts[parts.length - 1];
					const paramType = parts.slice(0, -1).join(' ');
					if (paramName === word) {
						return {
							name: word, kind: 'parameter', type: paramType,
							line: i, column: line.indexOf(word) + 1,
							docs: `Parameter of function \`${fnMatch[2]}\` of type \`${paramType}\``
						};
					}
				}
			}
			break;
		}
	}
	return null;
}

function matchesNamespace(sym, typedNamespace) {
	if (!sym || !sym.uid) return false;

	const nsLower = typedNamespace.toLowerCase();
	const uidLower = sym.uid.toLowerCase();
	const parts = uidLower.split('::');
	if (parts.length <= 1) return false;

	const symNamespace = parts.slice(0, -1).join('::');
	if (symNamespace === nsLower) return true;
	if (symNamespace.endsWith('::' + nsLower)) return true;
	if (nsLower.endsWith('::' + symNamespace)) return true;

	return false;
}

function getSymbolCompletionNames(sym) {
	const uid = sym.uid || '';
	const isLocal = sym.file && !sym.file.includes('lib/std/') && !sym.file.includes('compiler_rt');

	if (isLocal) {
		const parts = uid.split('::');
		const shortName = parts[parts.length - 1];
		return { insertText: shortName, label: shortName, filterText: shortName };
	}

	const parts = uid.split('::');
	const shortName = parts[parts.length - 1];

	if (uid.startsWith('std::')) {
		if (parts.length >= 3) {
			const shortQualified = parts[parts.length - 2] + '::' + parts[parts.length - 1];
			return { insertText: shortQualified, label: shortQualified, filterText: parts[parts.length - 1] };
		} else {
			const shortQualified = parts[parts.length - 1];
			return { insertText: shortQualified, label: shortQualified, filterText: shortQualified };
		}
	}

	return { insertText: uid, label: uid, filterText: shortName };
}

function formatSymbolHover(sym) {
	const contents = [];
	const signature = getSymbolSignature(sym);
	if (signature) {
		contents.push({ value: `\`\`\`c3\n${signature}\n\`\`\`` });
	} else {
		contents.push({ value: `**${sym.kind || 'definition'}** \`${sym.uid}\`` });
	}

	if (sym.docs && sym.docs.text) {
		contents.push({ value: sym.docs.text });
	}

	if (sym.docs && Array.isArray(sym.docs.params) && sym.docs.params.length > 0) {
		let paramText = `**Parameters:**\n`;
		for (const p of sym.docs.params) {
			paramText += `* \`${p.name}\`: ${p.description || ''}\n`;
		}
		contents.push({ value: paramText });
	}

	if (sym.docs && sym.docs.return) {
		contents.push({ value: `**Returns:** ${sym.docs.return}` });
	}

	let footerParts = [];
	if (sym.file) {
		footerParts.push(`*Defined in \`${sym.file}\`*`);
	}

	if (sym.uid && sym.uid.startsWith('std::')) {
		const docUrl = `https://c3-lang.org/standard-library/docs.html#${sym.uid}`;
		footerParts.push(`[Open Stdlib Docs ↗](${docUrl})`);
	}

	if (footerParts.length > 0) {
		contents.push({ value: footerParts.join('\n\n') });
	}

	return { contents: contents };
}

function getSymbolSignature(sym) {
	if (!sym) return null;

	if (sym.category === 'functions' || sym.category === 'methods' || sym.kind === 'function' || sym.kind === 'method') {
		const retType = sym.return_type ? sym.return_type.name : 'void';
		const params = (sym.members || []).map(m => {
			const t = m.type ? m.type.name : '';
			return t ? `${t} ${m.name}` : m.name;
		}).join(', ');
		return `fn ${retType} ${sym.name}(${params})`;
	}

	if (sym.category === 'macros' || sym.kind === 'macro') {
		const isAtMacro = sym.is_at_macro;
		const namePrefix = isAtMacro && !sym.name.startsWith('@') ? '@' : '';
		const retType = sym.return_type ? sym.return_type.name + ' ' : '';
		const params = (sym.members || []).map(m => {
			const t = m.type ? m.type.name : '';
			return t ? `${t} ${m.name}` : m.name;
		}).join(', ');
		return `macro ${retType}${namePrefix}${sym.name}(${params})`;
	}

	if (sym.category === 'variables' || sym.category === 'globals' || sym.category === 'constants' || sym.kind === 'constant' || sym.kind === 'global variable') {
		const isConst = sym.is_const;
		const typeName = sym.type ? sym.type.name : '';
		const prefix = isConst ? 'const ' : 'extern ';
		const typeStr = typeName ? typeName + ' ' : '';
		const valStr = sym.value !== undefined && sym.value !== null ? ` = ${sym.value}` : '';
		return `${prefix}${typeStr}${sym.name}${valStr}`;
	}

	if (sym.kind === 'union' || sym.kind === 'struct' || sym.kind === 'enum' || sym.kind === 'bitstruct' || sym.kind === 'constdef') {
		const baseType = sym.base_type ? ` : ${sym.base_type.name}` : '';
		return `${sym.kind} ${sym.name}${baseType}`;
	}

	return null;
}

function getCompletionItemKind(sym, monaco) {
	const category = sym.category;
	const kind = sym.kind;
	if (category === 'functions' || kind === 'function') return monaco.languages.CompletionItemKind.Function;
	if (category === 'methods' || kind === 'method') return monaco.languages.CompletionItemKind.Method;
	if (category === 'macros' || kind === 'macro') return monaco.languages.CompletionItemKind.Snippet;
	if (kind === 'struct' || kind === 'union') return monaco.languages.CompletionItemKind.Struct;
	if (kind === 'enum') return monaco.languages.CompletionItemKind.Enum;
	if (kind === 'bitstruct') return monaco.languages.CompletionItemKind.Class;
	if (category === 'constants' || kind === 'constant') return monaco.languages.CompletionItemKind.Constant;
	if (category === 'variables' || category === 'globals' || kind === 'global variable') return monaco.languages.CompletionItemKind.Variable;
	return monaco.languages.CompletionItemKind.Field;
}

export function parseCompilerErrors(stderrText, model, monaco) {
	const markers = [];
	const lines = stderrText.split('\n');
	const errorRegex = /(?:\/main\.c3|main\.c3):(\d+)(?::(\d+))?\)?\s*(Error|Warning):\s*(.*)/i;

	for (const line of lines) {
		const match = line.match(errorRegex);
		if (match) {
			const lineNum = parseInt(match[1], 10);
			const colNum = match[2] ? parseInt(match[2], 10) : 1;
			const severity = match[3].toLowerCase() === "error"
				? monaco.MarkerSeverity.Error
				: monaco.MarkerSeverity.Warning;

			let endColumn = colNum + 1;
			if (model) {
				const wordInfo = model.getWordAtPosition({ lineNumber: lineNum, column: colNum });
				if (wordInfo) {
					endColumn = wordInfo.endColumn;
				}
			}

			markers.push({
				severity, message: match[4].trim(),
				startLineNumber: lineNum, startColumn: colNum,
				endLineNumber: lineNum, endColumn: endColumn
			});
		}
	}
	return markers;
}

function getC3Definition() {
	return {
		defaultToken: 'invalid',

		keywords: [

			'alias', 'assert', 'asm', 'attrdef', 'attrgroup', 'attrmacro', 'bitstruct', 'break',
			'case', 'catch', 'cenum', 'const', 'constdef', 'constset', 'continue', 'default',
			'defer', 'distinct', 'do', 'else', 'enum', 'extern', 'false', 'faultconst', 'faultdef',
			'faultset', 'fn', 'for', 'foreach', 'foreach_r', 'if', 'import', 'inline', 'interface',
			'lengthof', 'macro', 'module', 'nextcase', 'null', 'return', 'scope', 'static', 'struct',
			'switch', 'tlocal', 'true', 'try', 'typedef', 'union', 'var', 'while',
			'$assert', '$case', '$concat', '$default', '$defined', '$echo', '$else', '$embed',
			'$endfor', '$endforeach', '$endif', '$endswitch', '$error', '$eval', '$exec', '$expand',
			'$feat', '$feature', '$for', '$foreach', '$if', '$include', '$reflect', '$stringify',
			'$switch', '$vaarg', '$vaexpr', '$varef',
			'$$abs', '$$acos', '$$asin', '$$atan', '$$any_make', '$$atomic_load', '$$atomic_store',
			'$$atomic_fetch_exchange', '$$atomic_fetch_add', '$$atomic_fetch_sub', '$$atomic_fetch_and',
			'$$atomic_fetch_nand', '$$atomic_fetch_or', '$$atomic_fetch_xor', '$$atomic_fetch_max',
			'$$atomic_fetch_min', '$$atomic_fetch_inc_wrap', '$$atomic_fetch_dec_wrap', '$$bitreverse',
			'$$breakpoint', '$$bswap', '$$ceil', '$$compare_exchange', '$$copysign', '$$cos', '$$cosh',
			'$$clz', '$$ctz', '$$add', '$$div', '$$mod', '$$mul', '$$neg', '$$sub', '$$exp', '$$exp2',
			'$$exp10', '$$expect', '$$expect_with_probability', '$$fence', '$$floor', '$$fma',
			'$$fmuladd', '$$frameaddress', '$$fshl', '$$fshr', '$$gather', '$$get_rounding_mode',
			'$$int_to_mask', '$$log', '$$log2', '$$log10', '$$matrix_mul', '$$matrix_transpose',
			'$$mask_to_int', '$$masked_load', '$$masked_store', '$$max', '$$memcpy', '$$memcpy_inline',
			'$$memmove', '$$memset', '$$memset_inline', '$$min', '$$nearbyint', '$$overflow_add',
			'$$overflow_mul', '$$overflow_sub', '$$popcount', '$$pow', '$$pow_int', '$$prefetch',
			'$$reduce_add', '$$reduce_and', '$$reduce_fadd', '$$reduce_fmul', '$$reduce_max',
			'$$reduce_min', '$$reduce_mul', '$$reduce_or', '$$reduce_xor', '$$reverse', '$$returnaddress',
			'$$rint', '$$rnd', '$$round', '$$roundeven', '$$sat_add', '$$sat_shl', '$$sat_sub',
			'$$sat_mul', '$$scatter', '$$select', '$$set_rounding_mode', '$$sprintf', '$$str_find',
			'$$str_hash', '$$str_lower', '$$str_pascalcase', '$$str_replace', '$$str_upper',
			'$$str_snakecase', '$$swizzle', '$$swizzle2', '$$sin', '$$sinh', '$$sqrt', '$$syscall',
			'$$sysclock', '$$tan', '$$tanh', '$$trap', '$$trunc', '$$unaligned_load', '$$unaligned_store',
			'$$unreachable', '$$veccomplt', '$$veccomple', '$$veccompgt', '$$veccompge', '$$veccompeq',
			'$$veccompne', '$$volatile_load', '$$volatile_store', '$$wasm_memory_size', '$$wasm_memory_grow',
			'$$wstr16', '$$wstr32', '$$DATE', '$$FILE', '$$FILEPATH', '$$FUNC', '$$FUNCTION', '$$LINE',
			'$$LINE_RAW', '$$MODULE', '$$BENCHMARK_NAMES', '$$BENCHMARK_FNS', '$$TEST_NAMES', '$$TEST_FNS',
			'$$TIME',
			'excuse'
		],
		typeKeywords: [
			'any', 'void', 'bool', 'char', 'double', 'float', 'float16', 'bfloat', 'bfloat16',
			'float128', 'int128', 'int', 'ichar', 'iptr', 'sz', 'long', 'short', 'uint128',
			'uint', 'ulong', 'uptr', 'ushort', 'usz', 'typeid', 'fault', 'untypedlist',
			'$Typeof', '$Typefrom'
		],
		operators: [
			'+', '-', '/', '*', '=', '^', '&', '?', '|', '!', '>', '<', '%', '??', '!!', '?:',
			'???', '++', '--', '<<', '>>', '+=', '-=', '/=', '*=', '==', '!=', '^=', '&=', '|=',
			'>=', '<=', '%=', '<<=', '>>=', '+++=', '+++', '&&&', '|||', '~', '::', '->', '!!!',
			'[<', '>]', '=>', '&&', '||', '..', '...'
		],
		attributes: [
			'@align', '@allow_deprecated', '@benchmark', '@bigendian', '@builtin', '@callconv',
			'@cname', '@compact', '@const', '@constinit', '@deprecated', '@dynamic', '@export',
			'@feat', '@finalizer', '@format', '@if', '@init', '@inline', '@jump', '@link',
			'@littleendian', '@local', '@maydiscard', '@mustinit', '@naked', '@noalias',
			'@nodiscard', '@noinit', '@noinline', '@nopadding', '@norecurse', '@noreturn',
			'@nosanitize', '@nostrip', '@obfuscate', '@operator', '@operator_r', '@operator_s',
			'@optional', '@overlap', '@packed', '@private', '@public', '@pure', '@reflect',
			'@safeinfer', '@safemacro', '@section', '@simd', '@tag', '@test', '@unused',
			'@used', '@wasm', '@weak', '@weaklink', '@winmain'
		],

		symbols: /[=><!~?:&|+\-*/^%]+/,
		escapes: /\\(?:[0abefnrtv\\"']|x[0-9A-Fa-f]{1,4}|u[0-9A-Fa-f]{4}|U[0-9A-Fa-f]{8})/,

		tokenizer: {
			root: [
				[
					/@[a-zA-Z_$][\w$]*/,
					{
						cases: {
							'@attributes': 'keyword',
							'@default': 'annotation',
						},
					},
				],
				[/\$[a-zA-Z_$][\w$]*/, 'keyword'],
				[/[a-z_$][\w$]*(?=\s*\()/, 'function'],
				[/[a-z_$][\w$]*(?=\s*::)/, 'keyword'],
				[/[iu]\d+/, 'keyword'],
				[
					/[a-z_$][\w$]*/,
					{
						cases: {
							'@typeKeywords': 'type',
							'@keywords': 'keyword',
							'@default': 'identifier',
						},
					},
				],
				[/[A-Z][\w$]*/, 'type.identifier'],
				{ include: '@whitespace' },
				[/#![^\n]*$/, 'comment'],
				[/[{}()[\]]/, '@brackets'],
				[/[<>](?!@symbols)/, '@brackets'],
				[
					/@symbols/,
					{
						cases: {
							'@operators': 'operator',
							'@default': '',
						},
					},
				],
				[/\d*\.\d+([eE][-+]?\d+)?[fFdD]?/, 'number.float'],
				[/0[xX][0-9a-fA-F_]*[0-9a-fA-F][Ll]?/, 'number.hex'],
				[/0o[0-7_]*[0-7][Ll]?/, 'number.octal'],
				[/0[bB][0-1_]*[0-1][Ll]?/, 'number.binary'],
				[/\d+/, 'number'],
				[/[;,.]/, 'delimiter'],
				[/"([^"\\]|\\.)*$/, 'string.invalid'],
				[/(?:c|x|b64)?\\\\.*$/, 'string'],
				[/(?:c|x|b64)?"/, 'string', '@string'],
				[/(?:c|x|b64)?`/, 'string', '@rawString'],
				[/(?:c|x|b64)?'[^\\']*'/, 'string'],
				[/(?:c|x|b64)?(')(@escapes)(')/, ['string', 'string.escape', 'string']],
				[/'/, 'string.invalid']
			],

			whitespace: [
				[/[ \r\n]+/, 'white'],
				[/\/\*/, 'comment', '@comment'],
				[/<\*/, 'contract', '@contract'],
				[/\/\/.*$/, 'comment'],
				[/\t/, 'comment.invalid']
			],

			comment: [
				[/[^/*]+/, 'comment'],
				[/\/\*/, 'comment', '@comment'],
				[/\*\//, 'comment', '@pop'],
				[/\*>/, 'comment', '@pop'],
				[/[/*]/, 'comment']
			],

			contract: [
				[/[^/*]+/, 'contract'],
				[/\*>/, 'contract', '@pop'],
				[/[/*]/, 'contract'],
				[/\t/, 'contract.invalid']
			],

			string: [
				[/[^\\"]+/, 'string'],
				[/@escapes/, 'string.escape'],
				[/\\./, 'string.escape.invalid'],
				[/"/, 'string', '@pop']
			],

			rawString: [
				[/``/, 'string.escape'],
				[/[^`]+/, 'string'],
				[/`/, 'string', '@pop']
			]
		}
	};
}