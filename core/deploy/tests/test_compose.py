"""Tests for compose.py Pattern C primitives.

Covers the operator-content-preservation contract that the install / update flows
both depend on: write_managed_file followed by extract_operator_additions returns
exactly the input preserved_additions (verbatim round-trip), and the token
substitution operates only on managed content.

Run from repo root:
    python3 -m pytest core/deploy/tests/test_compose.py -v
"""

from __future__ import annotations

import sys
from pathlib import Path

# Make core/deploy/ importable without packaging the script.
sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import compose  # noqa: E402


# ----- extract_operator_additions ---------------------------------------------------------------


def test_extract_returns_empty_when_target_absent(tmp_path: Path) -> None:
    assert compose.extract_operator_additions(tmp_path / "no_such_file.txt") == ""


def test_extract_returns_empty_when_target_has_no_markers(tmp_path: Path) -> None:
    target = tmp_path / "no_markers.txt"
    target.write_text("just plain content with no markers\n")
    assert compose.extract_operator_additions(target) == ""


def test_extract_returns_content_between_markers(tmp_path: Path) -> None:
    target = tmp_path / "with_markers.txt"
    target.write_text(
        f"{compose.BEGIN_MANAGED}\n"
        "managed line one\n"
        f"{compose.END_MANAGED}\n"
        "\n"
        f"{compose.BEGIN_OPERATOR}\n"
        "operator-line-1\n"
        "operator-line-2\n"
        f"{compose.END_OPERATOR}\n"
    )
    assert compose.extract_operator_additions(target) == "operator-line-1\noperator-line-2"


def test_extract_returns_empty_when_marker_block_is_empty(tmp_path: Path) -> None:
    target = tmp_path / "empty_block.txt"
    target.write_text(
        f"{compose.BEGIN_OPERATOR}\n\n{compose.END_OPERATOR}\n"
    )
    assert compose.extract_operator_additions(target) == ""


# ----- write_managed_file -----------------------------------------------------------------------


def _seed_source(path: Path, body: str) -> None:
    path.write_text(body)


def test_write_uses_default_placeholder_when_preserved_is_empty(tmp_path: Path) -> None:
    source = tmp_path / "src.txt"
    target = tmp_path / "tgt.txt"
    _seed_source(source, "source body\n")
    compose.write_managed_file(
        source_path=source,
        target_path=target,
        tokens={},
        preserved_additions="",
        source_sha="deadbeef",
        tokens_flag="raw",
    )
    written = target.read_text()
    assert compose.DEFAULT_OPERATOR_ADDITIONS_PLACEHOLDER in written
    assert "source body" in written
    assert "managed_sha: deadbeef" in written


def test_write_preserves_operator_additions_verbatim(tmp_path: Path) -> None:
    source = tmp_path / "src.txt"
    target = tmp_path / "tgt.txt"
    _seed_source(source, "managed body\n")
    preserved = "kept-line-1\nkept-line-2\n  indented-line\n# commented-line"
    compose.write_managed_file(
        source_path=source,
        target_path=target,
        tokens={},
        preserved_additions=preserved,
        source_sha="abc",
        tokens_flag="raw",
    )
    extracted = compose.extract_operator_additions(target)
    assert extracted == preserved


def test_write_substitutes_tokens_when_flag_is_tokens(tmp_path: Path) -> None:
    source = tmp_path / "src.txt"
    target = tmp_path / "tgt.txt"
    _seed_source(source, "hello [OPERATOR_NAME] at [OPERATOR_EMAIL]\n")
    compose.write_managed_file(
        source_path=source,
        target_path=target,
        tokens={"[OPERATOR_NAME]": "Ada", "[OPERATOR_EMAIL]": "ada@example.com"},
        preserved_additions="",
        source_sha="x",
        tokens_flag="tokens",
    )
    written = target.read_text()
    assert "hello Ada at ada@example.com" in written
    assert "[OPERATOR_NAME]" not in written


def test_write_does_not_substitute_when_flag_is_raw(tmp_path: Path) -> None:
    source = tmp_path / "src.txt"
    target = tmp_path / "tgt.txt"
    _seed_source(source, "literal [OPERATOR_NAME]\n")
    compose.write_managed_file(
        source_path=source,
        target_path=target,
        tokens={"[OPERATOR_NAME]": "ShouldNotAppear"},
        preserved_additions="",
        source_sha="x",
        tokens_flag="raw",
    )
    written = target.read_text()
    assert "[OPERATOR_NAME]" in written
    assert "ShouldNotAppear" not in written


# ----- installed_sha tamper anchor (ADR-014) ----------------------------------------------------


def _write_token_file(tmp_path: Path) -> Path:
    """Write a token-bearing managed file (substituted) and return the target path."""
    source = tmp_path / "src.txt"
    target = tmp_path / "tgt.txt"
    _seed_source(source, "host [OPERATOR_GITHUB] api.example.com\n")
    compose.write_managed_file(
        source_path=source,
        target_path=target,
        tokens={"[OPERATOR_GITHUB]": "testhandle"},
        preserved_additions="my own addition",
        source_sha="SRCSHA",
        tokens_flag="tokens",
    )
    return target


def test_write_emits_installed_sha_marker(tmp_path: Path) -> None:
    target = _write_token_file(tmp_path)
    written = target.read_text()
    assert "# installed_sha: " in written
    # Marker order is fixed: managed_sha -> installed_sha -> managed_at.
    assert written.index("# managed_sha:") < written.index("# installed_sha:") < written.index("# managed_at:")


def test_installed_sha_round_trips_post_substitution_body(tmp_path: Path) -> None:
    """The stored installed_sha equals installed_sha_of() equals SHA(post-substitution body)."""
    import hashlib

    target = _write_token_file(tmp_path)
    written = target.read_text()
    stored = next(l for l in written.splitlines() if "installed_sha:" in l).split()[2]
    computed = compose.installed_sha_of(target)
    direct = hashlib.sha256(b"host testhandle api.example.com").hexdigest()
    assert stored == computed == direct


def test_installed_sha_detects_managed_body_edit(tmp_path: Path) -> None:
    target = _write_token_file(tmp_path)
    before = compose.installed_sha_of(target)
    target.write_text(target.read_text().replace("api.example.com", "api.TAMPERED"))
    assert compose.installed_sha_of(target) != before


def test_installed_sha_ignores_operator_additions_edit(tmp_path: Path) -> None:
    """Editing the OPERATOR ADDITIONS section must NOT move the tamper anchor."""
    target = _write_token_file(tmp_path)
    before = compose.installed_sha_of(target)
    target.write_text(target.read_text().replace("my own addition", "my own addition\nEXTRA OPERATOR LINE"))
    assert compose.installed_sha_of(target) == before


def test_installed_sha_empty_for_missing_file(tmp_path: Path) -> None:
    assert compose.installed_sha_of(tmp_path / "nope.txt") == ""


def test_installed_sha_empty_for_no_fence(tmp_path: Path) -> None:
    target = tmp_path / "plain.txt"
    target.write_text("just content, no markers\n")
    assert compose.installed_sha_of(target) == ""


def test_extract_managed_body_strips_markers_and_equals_written_body(tmp_path: Path) -> None:
    """_extract_managed_body returns content.rstrip() (markers + additions excluded)."""
    target = _write_token_file(tmp_path)
    assert compose._extract_managed_body(target.read_text()) == "host testhandle api.example.com"


def test_extract_managed_body_handles_markdown_marker_wrapper() -> None:
    text = (
        f"{compose.BEGIN_MANAGED}\n"
        "<!-- managed_sha: SRC -->\n"
        "<!-- installed_sha: ZZZ -->\n"
        "<!-- managed_at: 2026 -->\n"
        "body line one\n"
        "body line two\n"
        f"{compose.END_MANAGED}\n"
    )
    assert compose._extract_managed_body(text) == "body line one\nbody line two"


def test_cli_installed_sha_round_trips(tmp_path: Path) -> None:
    import subprocess

    target = _write_token_file(tmp_path)
    stored = next(l for l in target.read_text().splitlines() if "installed_sha:" in l).split()[2]
    compose_py = Path(__file__).resolve().parent.parent / "compose.py"
    out = subprocess.run(
        [sys.executable, str(compose_py), "installed-sha", "--target", str(target)],
        capture_output=True, text=True,
    )
    assert out.returncode == 0
    assert out.stdout == stored


def test_cli_installed_sha_empty_for_no_fence(tmp_path: Path) -> None:
    import subprocess

    target = tmp_path / "plain.txt"
    target.write_text("no markers here\n")
    compose_py = Path(__file__).resolve().parent.parent / "compose.py"
    out = subprocess.run(
        [sys.executable, str(compose_py), "installed-sha", "--target", str(target)],
        capture_output=True, text=True,
    )
    assert out.returncode == 0
    assert out.stdout == ""


def test_installed_sha_back_compat_fixture_without_marker(tmp_path: Path) -> None:
    """A pre-ADR-014 fence (no installed_sha line) still yields a body hash; the
    DETECTOR (update.sh) treats the *absence of a stored marker* as unknown — but
    installed_sha_of itself just hashes whatever body is present."""
    target = tmp_path / "legacy.txt"
    target.write_text(
        f"{compose.BEGIN_MANAGED}\n"
        "# managed_sha: SRC\n"
        "# managed_at: 2026-01-01T00:00:00Z\n"
        "legacy body line\n"
        f"{compose.END_MANAGED}\n"
        "\n"
        f"{compose.BEGIN_OPERATOR}\n"
        "# placeholder\n"
        f"{compose.END_OPERATOR}\n"
    )
    # No stored installed_sha line in the fixture:
    assert "installed_sha" not in target.read_text()
    # But the body is still hashable (markers stripped):
    import hashlib
    assert compose.installed_sha_of(target) == hashlib.sha256(b"legacy body line").hexdigest()


# ----- Round-trip property (the safety contract) ------------------------------------------------


def test_roundtrip_preserves_operator_additions_through_multiple_writes(tmp_path: Path) -> None:
    """The core safety contract: write -> extract -> write -> extract -> ... is idempotent on preserved content."""
    source = tmp_path / "src.txt"
    target = tmp_path / "tgt.txt"
    _seed_source(source, "v1 managed body\n")
    initial_preserved = "operator content\nspanning lines\n# with comments"

    compose.write_managed_file(
        source_path=source, target_path=target, tokens={}, preserved_additions=initial_preserved,
        source_sha="sha1", tokens_flag="raw",
    )

    for cycle in range(3):
        extracted = compose.extract_operator_additions(target)
        assert extracted == initial_preserved, f"preservation broke at cycle {cycle}"
        _seed_source(source, f"v{cycle+2} managed body\n")
        compose.write_managed_file(
            source_path=source, target_path=target, tokens={}, preserved_additions=extracted,
            source_sha=f"sha{cycle+2}", tokens_flag="raw",
        )

    assert compose.extract_operator_additions(target) == initial_preserved


def test_roundtrip_with_token_substitution_does_not_affect_preserved_section(tmp_path: Path) -> None:
    """Tokens substitute in managed content but the preserved section is verbatim regardless of token state."""
    source = tmp_path / "src.txt"
    target = tmp_path / "tgt.txt"
    _seed_source(source, "managed has [OPERATOR_NAME]\n")
    preserved_with_token_lookalike = "operator addition mentioning [OPERATOR_NAME] literally"

    compose.write_managed_file(
        source_path=source, target_path=target,
        tokens={"[OPERATOR_NAME]": "Resolved"},
        preserved_additions=preserved_with_token_lookalike,
        source_sha="sha1", tokens_flag="tokens",
    )

    written = target.read_text()
    assert "managed has Resolved" in written
    assert preserved_with_token_lookalike in written
    extracted = compose.extract_operator_additions(target)
    assert extracted == preserved_with_token_lookalike


# ----- regen_one_file end-to-end ---------------------------------------------------------------


def test_regen_one_file_preserves_existing_additions(tmp_path: Path) -> None:
    source = tmp_path / "src.txt"
    target = tmp_path / "tgt.txt"
    operator_toml = tmp_path / "operator.toml"
    operator_toml.write_text(
        '[identity]\n'
        'operator_name = "Ada Lovelace"\n'
    )
    _seed_source(source, "Hello [OPERATOR_NAME]\n")

    compose.write_managed_file(
        source_path=source, target_path=target, tokens={}, preserved_additions="my own addition",
        source_sha="sha-init", tokens_flag="raw",
    )

    _seed_source(source, "Hello [OPERATOR_NAME] (v2)\n")
    compose.regen_one_file(
        source_path=source, target_path=target,
        operator_toml_path=operator_toml, override_toml_path=None,
        tokens_flag="tokens", source_sha="sha-regen",
    )

    written = target.read_text()
    assert "Hello Ada Lovelace (v2)" in written
    assert "managed_sha: sha-regen" in written
    assert compose.extract_operator_additions(target) == "my own addition"


# ----- parse_toml --------------------------------------------------------------------------------


def test_parse_toml_handles_simple_key_value(tmp_path: Path) -> None:
    path = tmp_path / "config.toml"
    path.write_text(
        '# a comment\n'
        '[identity]\n'
        'operator_name = "Ada"\n'
        'operator_email = "ada@example.com"\n'
        '\n'
        '[paths]\n'
        'claude_workspace_root = "/home/ada/Claude"\n'
    )
    parsed = compose.parse_toml(path)
    assert parsed[("identity", "operator_name")] == "Ada"
    assert parsed[("identity", "operator_email")] == "ada@example.com"
    assert parsed[("paths", "claude_workspace_root")] == "/home/ada/Claude"


def test_parse_toml_returns_empty_on_missing_file(tmp_path: Path) -> None:
    assert compose.parse_toml(tmp_path / "missing.toml") == {}


def test_resolve_tokens_derives_first_name(tmp_path: Path) -> None:
    path = tmp_path / "config.toml"
    path.write_text(
        '[identity]\n'
        'operator_name = "Test Operator"\n'
    )
    tokens = compose.resolve_tokens(path)
    assert tokens["[OPERATOR_NAME]"] == "Test Operator"
    assert tokens["[OPERATOR_FIRST_NAME]"] == "Test"
