# Nested / adjacent fenced blocks

An outer four-backtick fence encloses an inner three-backtick fence as literal
content (a common pattern when documenting fenced blocks). Per CommonMark, only
a same-or-longer fence of the same character closes the outer block, so the
inner ``` fence is content — the forbidden token inside it is excluded from the
code view and `region: code, polarity: absent` PASSes.

````markdown
```
localStorage.getItem('k');
```
````

An adjacent block follows immediately after the first closes:

```
another example, no forbidden token here
```

Trailing prose.
