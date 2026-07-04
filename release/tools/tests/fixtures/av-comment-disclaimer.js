// ADR: this module deliberately does NOT use localStorage
// (the token appears only in these disclaiming comments, never in code)
const store = new MemoryStore();   // in-memory only
export function get(key) {
  return store.read(key);
}
