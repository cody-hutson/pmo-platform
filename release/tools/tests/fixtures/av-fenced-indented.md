# Indented fenced block

A fence may be indented up to three spaces and still be a code fence. The
forbidden token appears only inside this indented fence, so `region: code,
polarity: absent` PASSes (the indented fenced content is excluded).

- a list item introducing an example:

   ```js
   localStorage.clear();
   ```

Prose resumes here with no reference to the token.
