
# -*- coding: utf-8 -*-
"""中文字体子集化（Web 首载瘦身）。

Fusion Pixel 全量 4.9MB 会整包进 Web 首载，但游戏实际用到的汉字只有几百个。
本脚本扫全仓（*.gd / *.tscn / *.tres / project.godot）收集所有会被渲染的字符，
用 pyftsubset 裁出子集，并**逐个码位校验**子集确实覆盖了这些字符。

    python tools/subset_font.py            # 重新裁剪 + 校验（改了中文文案后要跑）
    python tools/subset_font.py --check    # 只校验不写文件（L0 判定用）

想加新文案：写完后跑一次本脚本；漏字会被 L0 判据 font-coverage 拦住。
"""
import argparse
import os
import re
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FONT = os.path.join(ROOT, "fonts", "fusion-pixel-12px-proportional-zh_hans.otf")
CHARS_TXT = os.path.join(ROOT, "tools", "qa", "font-chars.txt")

SCAN_GLOBS = ("*.gd", "*.tscn", "*.tres", "project.godot")

# 兜底字符：ASCII 可打印 + 游戏文案里确定会用到的中文标点/全角符号
BASE = (
    "".join(chr(c) for c in range(0x20, 0x7F))
    + "　、。〈〉《》「」『』【】〔〕！？：；，．·…—～＋（）％"
)


def strip_gd_comments(text):
    """去掉 GDScript 的注释——注释里的 ⚠ / ★ 之类不会渲染，别为它们撑大字体。"""
    out = []
    quote = ""
    i = 0
    n = len(text)
    while i < n:
        ch = text[i]
        if quote:
            out.append(ch)
            if ch == "\\":
                i += 1
                if i < n:
                    out.append(text[i])
            elif ch == quote:
                quote = ""
            i += 1
            continue
        if ch == "#":
            while i < n and text[i] != "\n":
                i += 1
            continue
        if ch in ("\"", "'"):
            quote = ch
        out.append(ch)
        i += 1
    return "".join(out)


def collect_chars():
    """扫源码收集所有字符（含注释——多留几个字比漏字便宜得多）。"""
    chars = set(BASE)
    for root, dirs, files in os.walk(ROOT):
        # tools/ 是开发脚本，里面的中文只打到控制台、不进游戏界面，所以不进字体
        dirs[:] = [d for d in dirs if d not in (".git", ".godot", "build", "_shots", "addons", "tools")]
        for name in files:
            if not name.endswith((".gd", ".tscn", ".tres")) and name != "project.godot":
                continue
            path = os.path.join(root, name)
            try:
                with open(path, "r", encoding="utf-8", errors="replace") as fh:
                    text = fh.read()
            except OSError:
                continue
            if name.endswith(".gd"):
                text = strip_gd_comments(text)
            chars |= set(text)
    # 只留可打印字符（换行/制表等控制符不进字体）
    return {c for c in chars if c.isprintable()}


def font_codepoints(path):
    from fontTools.ttLib import TTFont
    font = TTFont(path, lazy=True)
    codes = set()
    for table in font["cmap"].tables:
        codes |= set(table.cmap.keys())
    font.close()
    return codes


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--check", action="store_true", help="只校验子集覆盖率，不重新裁剪")
    args = ap.parse_args()

    chars = collect_chars()
    if not args.check:
        os.makedirs(os.path.dirname(CHARS_TXT), exist_ok=True)
        with open(CHARS_TXT, "w", encoding="utf-8", newline="") as fh:
            fh.write("".join(sorted(chars)))
        before = os.path.getsize(FONT)
        cmd = [sys.executable, "-m", "fontTools.subset", FONT,
               "--text-file=" + CHARS_TXT,
               "--output-file=" + FONT + ".subset",
               "--layout-features=*"]
        proc = subprocess.run(cmd, capture_output=True)
        if proc.returncode != 0:
            print("SUBSET FAIL: pyftsubset exit %d" % proc.returncode)
            print(proc.stderr.decode("utf-8", "replace")[-800:])
            return 1
        os.replace(FONT + ".subset", FONT)
        after = os.path.getsize(FONT)
        print("subsets: %d chars  %.1fMB -> %.1fMB (save %.1fMB)" % (
            len(chars), before / 1048576.0, after / 1048576.0, (before - after) / 1048576.0))

    codes = font_codepoints(FONT)
    missing = sorted(c for c in chars if ord(c) not in codes)
    if missing:
        shown = " ".join("U+%04X(%s)" % (ord(c), "?" if ord(c) > 0xFFFF else c) for c in missing[:40])
        print("SUBSET FAIL: font misses %d chars: %s" % (len(missing), shown.encode("ascii", "replace").decode("ascii")))
        return 1
    print("SUBSET PASS: %d chars all covered (font %.1fMB)" % (len(chars), os.path.getsize(FONT) / 1048576.0))
    return 0


if __name__ == "__main__":
    sys.exit(main())
