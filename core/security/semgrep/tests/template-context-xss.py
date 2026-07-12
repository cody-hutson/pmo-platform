# Portable --test fixture for R1 (template-context-xss-transport).
# Independent of git history: proves the taint rule fires on the pre-fix shape and
# stays green on the shipped-fix shape (the encoder-in-the-pipe sanitizer).
import json


def bad(embedded, template):
    # Pre-fix shape (eb90e67^): json.dumps straight into the <script> placeholder,
    # no < > & neutralization -> a value carrying </script> breaks out.
    data_json = json.dumps(embedded)
    # ruleid: template-context-xss-transport
    return template.replace("/*__EMBEDDED_DATA__*/", f"const EMBEDDED_DATA = {data_json};")


def good(embedded, template):
    # Shipped-fix shape: chained < > & neutralization sanitizes the taint BEFORE the
    # template substitution -- MUST NOT flag (keys on the MISSING encoder, so the fix
    # is not false-positived and no blanket suppression is invited).
    data_json = (
        json.dumps(embedded)
        .replace("&", "\\u0026")
        .replace("<", "\\u003c")
        .replace(">", "\\u003e")
    )
    # ok: template-context-xss-transport
    return template.replace("/*__EMBEDDED_DATA__*/", f"const EMBEDDED_DATA = {data_json};")
