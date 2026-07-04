# Fenced block with an info-string

The forbidden token appears only inside a fenced code block that carries a
language info-string (` ```js `). M-1 requires the fenced content to be excluded
from the code view, so a `region: code, polarity: absent` assertion PASSes.

```js
localStorage.setItem('k', v);   // token lives here, inside a ```js fence
```

Nothing in the surrounding prose references the token.
