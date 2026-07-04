<!-- ADR: this document deliberately describes a store that does NOT use localStorage -->

# Storage design

The reference store is in-memory only. The running prose here does not mention
the forbidden token, so a `region: code, polarity: absent` assertion for that
token must PASS on this file — the only occurrence lives inside the HTML comment
above (and the fenced example below), both of which are excluded from the code
view.

```js
// illustrative counter-example — NOT the chosen design
const bad = window.localStorage.getItem('k');
```

Prose after the fenced block, still saying nothing about the forbidden token.
