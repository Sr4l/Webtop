#!/usr/bin/env python3
"""Patch selkies' input_handler.py: inject seat-resolvable unicode keysyms
(umlauts/ß/€ on a German seat keymap) through the pixelflux seat as real key
events instead of routing them to the app-compositor text batch.

Background: with a nested app compositor (KWin on wayland-0, captured by
pixelflux on wayland-1), upstream routes every keysym in 0xA0-0xFF to a text
batch injected via the app compositor's zwp_virtual_keyboard_manager_v1. KWin
does not implement that protocol, so every umlaut falls back to a clipboard
paste — which works but is slow and clobbers the clipboard on every key.
Keysyms the seat keymap itself resolves ride real evdev keycodes that the
nested KWin (which adopted the same keymap) translates to the right glyph, so
they can take the seat path directly; only keysyms the base layout lacks
(overlay binds a nested compositor would re-translate to nothing) still need
the text batch.

The ku half of the patch is mandatory: upstream swallows the key-up of every
unicode-fallback keysym when a separate app compositor exists, which would
leave a seat-routed umlaut pressed forever (stuck/repeating key).

Usage: patch_selkies_umlauts.py /path/to/input_handler.py
Exits non-zero (failing the image build) when an anchor text is not found
exactly once, e.g. because SELKIES_REF drifted; rebase the patch then.
"""
import sys

# --- kd branch: gate the text-batch routing on seat resolvability ------------
KD_OLD = """\
                        if (is_unicode_fallback and not native_inject()
                                and (not self.active_modifiers
                                     or self._has_separate_app_compositor())):
                            unicode_codepoint = keysym & 0x00FFFFFF if (keysym & 0xFF000000) == 0x01000000 else keysym
                            try:
                                char_to_type = chr(unicode_codepoint)
                                unicode_buffer.append(char_to_type)
                                self._route_key_as_text(keysym)
                                continue
                            except ValueError:
                                pass
"""

KD_NEW = """\
                        if (is_unicode_fallback and not native_inject()
                                and (not self.active_modifiers
                                     or self._has_separate_app_compositor())):
                            # PATCHED(webtop): keysyms the seat keymap itself
                            # resolves (umlauts/ß/€ on a de seat) go through
                            # the seat as real key events — the nested
                            # compositor adopted the same keymap, so the
                            # keycode round-trips to the right glyph. Only
                            # keysyms the base layout lacks (overlay binds a
                            # nested compositor would re-translate to nothing)
                            # ride the text batch.
                            owner = await self._ensure_wayland_keymap_owner()
                            if owner is None or not owner.resolves(keysym):
                                unicode_codepoint = keysym & 0x00FFFFFF if (keysym & 0xFF000000) == 0x01000000 else keysym
                                try:
                                    char_to_type = chr(unicode_codepoint)
                                    unicode_buffer.append(char_to_type)
                                    self._route_key_as_text(keysym)
                                    continue
                                except ValueError:
                                    pass
"""

# --- ku branch: stop swallowing the key-up of seat-routed keys ---------------
KU_OLD = """\
                        if is_unicode_fallback and not native_inject():
                            # Buffered text was typed atomically; there is no held key.
                            continue
"""

KU_NEW = """\
                        # PATCHED(webtop): no blanket unicode-fallback swallow
                        # here — a kd that went to the seat must see its ku or
                        # the key sticks; text-routed keys are already
                        # swallowed via _wl_text_routed above.
"""


def main(path: str) -> None:
    with open(path, encoding="utf-8") as f:
        src = f.read()
    for name, old, new in (
        ("kd unicode branch", KD_OLD, KD_NEW),
        ("ku unicode branch", KU_OLD, KU_NEW),
    ):
        count = src.count(old)
        if count != 1:
            sys.exit(
                f"error: patch anchor '{name}' found {count}x (expected 1) in "
                f"{path} — upstream input_handler.py drifted; rebase "
                f"configs/patch_selkies_umlauts.py for the pinned SELKIES_REF."
            )
        src = src.replace(old, new)
    with open(path, "w", encoding="utf-8") as f:
        f.write(src)
    print(f"patched {path}: seat-resolvable unicode keysyms now use the seat")


if __name__ == "__main__":
    if len(sys.argv) != 2:
        sys.exit("usage: patch_selkies_umlauts.py /path/to/input_handler.py")
    main(sys.argv[1])
