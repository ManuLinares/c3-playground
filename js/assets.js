// js/assets.js

const assetCache = new Map(); // url -> Uint8Array

/**
 * Parses `@asset:` directives from C3 source code.
 * Supports formats:
 *   // @asset: https://example.com/texture.png -> resources/img/texture.png
 *   // @asset: https://example.com/texture.png => resources/img/texture.png
 *   /* @asset: https://example.com/texture.png -> resources/img/texture.png * /
 *   // @asset: https://example.com/texture.png (defaults destination to filename)
 */
export function parseAssetDirectives(sourceCode) {
	if (!sourceCode) return [];
	const regex = /(?:\/\/|\/\*)\s*@asset:\s*(\S+?)(?:\s*(?:->|=>)\s*(\S+?))?(?:\s*\*\/|\s*$)/gm;
	const assets = [];
	const seenPaths = new Set();
	let match;

	while ((match = regex.exec(sourceCode)) !== null) {
		const url = match[1].trim();
		let destPath = match[2] ? match[2].trim() : '';

		if (!destPath) {
			try {
				const u = new URL(url);
				destPath = u.pathname.split('/').filter(Boolean).pop() || 'asset.dat';
			} catch (_) {
				destPath = url.split('/').filter(Boolean).pop() || 'asset.dat';
			}
		}

		// Normalize destination path
		destPath = destPath.replace(/\\/g, '/').replace(/^\.?\/+/, '');

		if (url && destPath && !seenPaths.has(destPath)) {
			seenPaths.add(destPath);
			assets.push({ url, path: destPath });
		}
	}
	return assets;
}

/**
 * Fetches all requested assets in parallel and caches them in memory.
 */
export async function fetchAssets(assets, onProgress) {
	if (!assets || assets.length === 0) return [];

	return Promise.all(assets.map(async ({ url, path }, index) => {
		if (assetCache.has(url)) {
			return { path, data: assetCache.get(url) };
		}

		if (onProgress) {
			onProgress(`Downloading asset (${index + 1}/${assets.length}): ${path}`);
		}

		const res = await fetch(url);
		if (!res.ok) {
			throw new Error(`Failed to download asset "${path}" from ${url} (${res.status} ${res.statusText})`);
		}

		const buffer = await res.arrayBuffer();
		const data = new Uint8Array(buffer);
		assetCache.set(url, data);
		return { path, data };
	}));
}

/**
 * Recursively creates directories and writes binary data to an Emscripten VFS.
 */
export function writeVfsFile(fs, filePath, data) {
	if (!fs || !filePath || !data) return;
	const cleanPath = filePath.replace(/\\/g, '/');
	const normalizedPath = cleanPath.startsWith('/') ? cleanPath : '/' + cleanPath;
	const parts = normalizedPath.split('/').filter(Boolean);
	parts.pop(); // Remove filename, keep directories

	let cur = '';
	for (const p of parts) {
		cur += '/' + p;
		try {
			if (fs.analyzePath) {
				if (!fs.analyzePath(cur).exists) {
					fs.mkdir(cur);
				}
			} else {
				fs.mkdir(cur);
			}
		} catch (_) {}
	}

	try {
		fs.unlink(normalizedPath);
	} catch (_) {}

	const u8 = data instanceof Uint8Array ? data : new Uint8Array(data);
	fs.writeFile(normalizedPath, u8);
}