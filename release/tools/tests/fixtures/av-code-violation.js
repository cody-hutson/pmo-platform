// This comment mentions localStorage as prose, but the code below GENUINELY
// uses it — a `region: code, polarity: absent` assertion MUST FAIL here.
// This is the symmetric false-PASS guard: the old whole-file grep would also
// FAIL, but for the wrong reason (it cannot tell the comment from the code).
const raw = window.localStorage.getItem('session');
export const session = raw ? JSON.parse(raw) : null;
