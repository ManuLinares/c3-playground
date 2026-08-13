// js/share.js

let lastSharedCode = null;
let lastSharedUrl = null;

export async function getSharedCode() {
	const hash = window.location.hash.trim();
	if (!hash) return null;
	const key = hash.replace(/^#(?:p=)?/, '');
	if (!key) return null;

	try {
		const res = await fetch(`https://api.pastes.dev/${key}`);
		if (res.ok) {
			const code = await res.text();
			lastSharedCode = code;
			lastSharedUrl = `${window.location.origin}${window.location.pathname}#p=${key}`;
			return code;
		}
	} catch (err) {
		console.error("Failed to fetch snippet from pastes.dev:", err);
	}
	return null;
}

export async function createShareLink(codeValue) {
	if (lastSharedCode === codeValue && lastSharedUrl) {
		await navigator.clipboard.writeText(lastSharedUrl);
		history.replaceState(null, null, `#p=${lastSharedUrl.split('#p=')[1]}`);
		return lastSharedUrl;
	}

	const res = await fetch('https://api.pastes.dev/post', {
		method: 'POST',
		headers: { 'Content-Type': 'text/c3' },
		body: codeValue
	});

	if (res.ok) {
		const data = await res.json();
		const shareUrl = `${window.location.origin}${window.location.pathname}#p=${data.key}`;
		lastSharedCode = codeValue;
		lastSharedUrl = shareUrl;
		history.replaceState(null, null, `#p=${data.key}`);
		await navigator.clipboard.writeText(shareUrl);
		return shareUrl;
	}
	throw new Error("Failed to post snippet to pastes.dev");
}