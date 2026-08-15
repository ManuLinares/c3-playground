// js/share.js

let lastSharedCode = null;
let lastSharedUrl = null;

export async function getSharedCode() {
	// 1. Check for URL query parameter or hash example ID (e.g. ?example=neon_overdrive or #example=neon_overdrive)
	const urlParams = new URLSearchParams(window.location.search);
	const exampleParam = urlParams.get('example') || urlParams.get('ex');
	if (exampleParam) {
		return { type: 'example', id: exampleParam };
	}

	const hash = window.location.hash.trim();
	if (!hash) return null;

	if (hash.startsWith('#example=') || hash.startsWith('#ex=')) {
		const exId = hash.replace(/^#(?:example|ex)=/, '');
		if (exId) return { type: 'example', id: exId };
	}

	const key = hash.replace(/^#(?:p=)?/, '');
	if (!key) return null;

	try {
		const res = await fetch(`https://api.pastes.dev/${key}`);
		if (res.ok) {
			const code = await res.text();
			lastSharedCode = code;
			lastSharedUrl = `${window.location.origin}${window.location.pathname}#p=${key}`;
			return { type: 'snippet', code: code };
		}
	} catch (err) {
		console.error("Failed to fetch snippet from pastes.dev:", err);
	}
	return null;
}

export async function createShareLink(codeValue) {
	// Build a clean URL with no query params - just origin+pathname+hash to avoid conflicting with the paste hash
	const cleanBase = `${window.location.origin}${window.location.pathname}`;

	if (lastSharedCode === codeValue && lastSharedUrl) {
		await navigator.clipboard.writeText(lastSharedUrl);
		history.replaceState(null, null, `${cleanBase}#p=${lastSharedUrl.split('#p=')[1]}`);
		return lastSharedUrl;
	}

	const res = await fetch('https://api.pastes.dev/post', {
		method: 'POST',
		headers: { 'Content-Type': 'text/c3' },
		body: codeValue
	});

	if (res.ok) {
		const data = await res.json();
		const shareUrl = `${cleanBase}#p=${data.key}`;
		lastSharedCode = codeValue;
		lastSharedUrl = shareUrl;
		// Replace the full URL (strips any ?example=... query param)
		history.replaceState(null, null, shareUrl);
		await navigator.clipboard.writeText(shareUrl);
		return shareUrl;
	}
	throw new Error("Failed to post snippet to pastes.dev");
}