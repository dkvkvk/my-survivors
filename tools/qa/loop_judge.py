#!/usr/bin/env python3
"""my-survivors L0 judge: headless smoke + asset contract.

Exit code 0 = all checks pass. Writes tools/qa/judge-report.json.

Usage:
    python tools/qa/loop_judge.py            # full run
    python tools/qa/loop_judge.py --fast     # skip the 240-frame headless run
    python tools/qa/loop_judge.py --json     # print the report to stdout
"""
from __future__ import annotations

import argparse
import hashlib
import json
import os
import re
import struct
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
QA_DIR = ROOT / "tools" / "qa"
REPORT_PATH = QA_DIR / "judge-report.json"

GODOT = os.environ.get(
    "GODOT_BIN",
    "D:/Downloads/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64_console.exe",
)

# 编辑器插件的已知无害噪音（见 HANDOVER §3）
NOISE = re.compile(r"Out of bounds", re.IGNORECASE)
IMPORT_BAD = re.compile(r"Parse Error|Failed to load|non-existent", re.IGNORECASE)
RUNTIME_BAD = re.compile(r"SCRIPT ERROR|SHADER ERROR|no animation")

# 素材契约规格表：改素材只改这里
ASSET_SPEC = {
    "assets/hero/ninja_sheet.png": {"size": (64, 64), "note": "4x4 方向行走表，禁止换成图标九宫格（坑 #10）"},
    "assets/ui/cover.png": {"size": (1920, 1080), "note": "封面 16:9"},
    "assets/ui/menu_bg.png": {"size": (1920, 1080), "note": "菜单背景 16:9", "optional": True},
    "assets/ui/gameover_bg.png": {"size": (1920, 1080), "note": "结算背景 16:9", "optional": True},
}


def read_image_size(path: Path):
    """零依赖读取 png/jpg 尺寸。"""
    with path.open("rb") as fh:
        head = fh.read(32)
        if head[:8] == b"\x89PNG\r\n\x1a\n":
            w, h = struct.unpack(">II", head[16:24])
            return (w, h)
        if head[:2] == b"\xff\xd8":
            fh.seek(2)
            while True:
                b = fh.read(1)
                if not b:
                    return None
                if b != b"\xff":
                    continue
                marker = fh.read(1)
                while marker == b"\xff":
                    marker = fh.read(1)
                if marker in (b"\xc0", b"\xc1", b"\xc2", b"\xc3"):
                    fh.read(3)
                    h, w = struct.unpack(">HH", fh.read(4))
                    return (w, h)
                seg = fh.read(2)
                if len(seg) < 2:
                    return None
                fh.seek(struct.unpack(">H", seg)[0] - 2, os.SEEK_CUR)
        if head[:4] == b"RIFF" and head[8:12] == b"WEBP":
            fmt = head[12:16]
            if fmt == b"VP8X":
                w = int.from_bytes(head[24:27], "little") + 1
                h = int.from_bytes(head[27:30], "little") + 1
                return (w, h)
            if fmt == b"VP8 ":
                w = int.from_bytes(head[26:28], "little") & 0x3FFF
                h = int.from_bytes(head[28:30], "little") & 0x3FFF
                return (w, h)
    return None


def sha256_of(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as fh:
        for chunk in iter(lambda: fh.read(1 << 20), b""):
            digest.update(chunk)
    return digest.hexdigest()


def run_godot(args, timeout=420):
    cmd = [GODOT, "--headless", "--path", str(ROOT)] + args
    started = time.time()
    try:
        proc = subprocess.run(cmd, capture_output=True, timeout=timeout)
        out = (proc.stdout or b"").decode("utf-8", "replace") + (proc.stderr or b"").decode("utf-8", "replace")
        return proc.returncode, out, time.time() - started
    except subprocess.TimeoutExpired as exc:
        out = (exc.stdout or b"").decode("utf-8", "replace") if exc.stdout else ""
        return None, out, time.time() - started
    except FileNotFoundError:
        return "missing", "", time.time() - started


def check_import():
    code, out, secs = run_godot(["--import"])
    if code == "missing":
        return {"id": "headless-import", "determinism": "grep", "pass": False,
                "reason": "找不到 Godot 可执行文件，设置 GODOT_BIN 环境变量", "godot": GODOT}
    bad = [ln for ln in out.splitlines() if IMPORT_BAD.search(ln) and not NOISE.search(ln)]
    return {
        "id": "headless-import",
        "determinism": "grep",
        "pass": code == 0 and not bad,
        "exit_code": code,
        "bad_lines": bad[:10],
        "bad_count": len(bad),
        "seconds": round(secs, 1),
    }


def check_runtime(frames=240):
    code, out, secs = run_godot(["--quit-after", str(frames)])
    if code == "missing":
        return {"id": "headless-runtime", "determinism": "grep", "pass": False,
                "reason": "找不到 Godot 可执行文件", "godot": GODOT}
    bad = [ln for ln in out.splitlines() if RUNTIME_BAD.search(ln)]
    return {
        "id": "headless-runtime",
        "determinism": "grep",
        "pass": code == 0 and not bad,
        "exit_code": code,
        "frames": frames,
        "bad_count": len(bad),
        "bad_lines": bad[:10],
        "seconds": round(secs, 1),
    }


def check_script_parse():
    """全量解析每个 .gd。

    --import 不会编译脚本，未被场景引用的坏脚本抓不到（2026-09-22 反向测试发现）。
    这里用一个 SceneTree 脚本 load() 全部 .gd 逼 Godot 解析，再抓 stderr 的确定信号。
    """
    code, out, secs = run_godot(["--script", "res://tools/qa/check_scripts.gd"])
    if code == "missing":
        return {"id": "script-parse", "determinism": "grep", "pass": False,
                "reason": "找不到 Godot 可执行文件", "godot": GODOT}
    bad = [ln for ln in out.splitlines()
           if re.search(r"Parse Error|Failed to load script|SCRIPT ERROR", ln)]
    match = re.search(r"SCRIPT_CHECK_LOADED=(\d+)", out)
    return {
        "id": "script-parse",
        "determinism": "grep",
        "pass": not bad,
        "loaded": int(match.group(1)) if match else None,
        "bad_count": len(bad),
        "bad_lines": bad[:10],
        "seconds": round(secs, 1),
    }


def check_kill_credit():
    """功能回归：精确斩妖归属（P6）。

    用 tools/qa/check_kill_credit.gd 起真实场景，造怪分别带/不带 source 打死，
    断言只有致命一击的法宝 +1、来源不明时兜底给所有法宝。
    """
    code, out, secs = run_godot(["--script", "res://tools/qa/check_kill_credit.gd"])
    if code == "missing":
        return {"id": "kill-credit", "determinism": "assert", "pass": False,
                "reason": "找不到 Godot 可执行文件", "godot": GODOT}
    bad = [ln for ln in out.splitlines() if "KILLCHECK FAIL" in ln]
    passed = "KILLCHECK PASS" in out
    return {
        "id": "kill-credit",
        "determinism": "assert",
        "pass": passed and not bad,
        "bad_count": len(bad),
        "bad_lines": bad[:10],
        "seconds": round(secs, 1),
    }


def check_weapons():
    """功能回归：6 把法宝的被动 / 技能 / 进化 / 归属（P6）。

    默认的 --quit-after 停在开局选择界面，法宝根本不会跑；这里用 tools/qa/check_weapons.gd
    装上全部法宝跑真实帧，并直接驱动命中回调验证伤害与斩妖归属。
    """
    code, out, secs = run_godot(["--script", "res://tools/qa/check_weapons.gd"])
    if code == "missing":
        return {"id": "weapons-smoke", "determinism": "assert", "pass": False,
                "reason": "找不到 Godot 可执行文件", "godot": GODOT}
    bad = [ln for ln in out.splitlines() if "WEAPONS FAIL" in ln]
    passed = "WEAPONS PASS" in out
    info = [ln.strip() for ln in out.splitlines() if "WEAPONS INFO" in ln]
    return {
        "id": "weapons-smoke",
        "determinism": "assert",
        "pass": passed and not bad,
        "bad_count": len(bad),
        "bad_lines": bad[:10],
        "info": info,
        "seconds": round(secs, 1),
    }


def check_fx_entry():
    """震屏 / 定帧必须走 VFX 统一入口（VFX.shake / VFX.hitstop）。

    踩过：每只怪死亡都直接 Juice.shake(0.35) + Juice.hitstop(0.05)——
    trauma 制是累加的，连杀时被顶在 1.0（实测 51%~84% 的帧画面偏移 >4px = "一直在抖"），
    而 hitstop 让 6%~22% 的帧 time_scale 钉在 0（= "一直卡"）。
    统一入口才能统一强度（CAMERA_SHAKE_GAIN）与统一限流。
    """
    bad = []
    for path in sorted(ROOT.glob("*.gd")):
        if path.name == "vfx.gd":
            continue
        for i, line in enumerate(path.read_text(encoding="utf-8", errors="replace").splitlines(), 1):
            code = line.split("#", 1)[0]
            if "Juice.shake(" in code or "Juice.hitstop(" in code:
                bad.append("%s:%d" % (path.name, i))
    return {
        "id": "fx-entry",
        "determinism": "grep",
        "pass": not bad,
        "bad_count": len(bad),
        "bad_lines": ["绕开统一入口直接调 Juice：" + b for b in bad[:10]],
    }


def check_hero_columns():
    """主角四向走路用的精灵表列必须「帧间自洽 + 朝向正确」。

    踩过：修仙化换表后，右向列（col3）的 row0 与其余 3 帧朝向相反且整体右移 2px，
    而左向是镜像 col3 —— 于是往左往右走都像"边走边转身"（人眼很难发现，质心一量就出来）。
    校验逻辑在 tools/qa/check_hero_columns.py（零依赖 PNG 解码 + 质心分析）。
    """
    script = ROOT / "tools" / "qa" / "check_hero_columns.py"
    if not script.exists():
        return {"id": "hero-columns", "determinism": "assert", "pass": True, "reason": "无校验脚本，跳过"}
    started = time.time()
    try:
        proc = subprocess.run([sys.executable, str(script)], capture_output=True, cwd=str(ROOT), timeout=120)
        out = (proc.stdout or b"").decode("utf-8", "replace") + (proc.stderr or b"").decode("utf-8", "replace")
    except Exception as exc:  # noqa: BLE001
        return {"id": "hero-columns", "determinism": "assert", "pass": False,
                "reason": "跑不动 check_hero_columns.py：%s" % exc}
    bad = [ln.strip() for ln in out.splitlines() if "HEROCOL FAIL" in ln]
    return {
        "id": "hero-columns",
        "determinism": "assert",
        "pass": "HEROCOL PASS" in out and not bad,
        "bad_count": len(bad),
        "bad_lines": bad[:5],
        "info": [ln.strip() for ln in out.splitlines() if "col" in ln][:4],
        "seconds": round(time.time() - started, 1),
    }


def check_touch():
    """功能回归：触屏操作（P2b）。

    本机没有触摸屏，用环境变量 MS_TOUCH=1 强制开启触屏层，
    再断言摇杆方向（含模拟量/死区）、松手归零、神通按钮能放技能、触屏时隐藏按键提示。
    """
    env = dict(os.environ)
    env["MS_TOUCH"] = "1"
    cmd = [GODOT, "--headless", "--path", str(ROOT), "--script", "res://tools/qa/check_touch.gd"]
    started = time.time()
    try:
        proc = subprocess.run(cmd, capture_output=True, timeout=300, env=env)
    except FileNotFoundError:
        return {"id": "touch-controls", "determinism": "assert", "pass": False,
                "reason": "找不到 Godot 可执行文件", "godot": GODOT}
    except subprocess.TimeoutExpired:
        return {"id": "touch-controls", "determinism": "assert", "pass": False, "reason": "超时"}
    out = (proc.stdout or b"").decode("utf-8", "replace") + (proc.stderr or b"").decode("utf-8", "replace")
    bad = [ln for ln in out.splitlines() if "TOUCH FAIL" in ln]
    return {
        "id": "touch-controls",
        "determinism": "assert",
        "pass": "TOUCH PASS" in out and not bad,
        "bad_count": len(bad),
        "bad_lines": bad[:10],
        "seconds": round(time.time() - started, 1),
    }


def check_font_coverage():
    """中文字体子集必须覆盖全仓用到的字符（漏字 = 界面出现豆腐块）。

    字体是子集化的（Web 首载瘦身），所以"改了中文文案忘了重新裁剪"必须被拦住。
    校验逻辑在 tools/subset_font.py --check（零依赖部分只有码位比对）。
    """
    script = ROOT / "tools" / "subset_font.py"
    if not script.exists():
        return {"id": "font-coverage", "determinism": "assert", "pass": True, "reason": "无子集脚本，跳过"}
    started = time.time()
    try:
        proc = subprocess.run([sys.executable, str(script), "--check"],
                              capture_output=True, cwd=str(ROOT), timeout=120)
        out = (proc.stdout or b"").decode("utf-8", "replace") + (proc.stderr or b"").decode("utf-8", "replace")
    except Exception as exc:  # noqa: BLE001
        return {"id": "font-coverage", "determinism": "assert", "pass": False,
                "reason": "跑不动 subset_font.py --check：%s" % exc}
    bad = [ln for ln in out.splitlines() if "SUBSET FAIL" in ln]
    return {
        "id": "font-coverage",
        "determinism": "assert",
        "pass": "SUBSET PASS" in out and not bad,
        "bad_count": len(bad),
        "bad_lines": bad[:5],
        "info": [ln.strip() for ln in out.splitlines() if "SUBSET PASS" in ln][:1],
        "seconds": round(time.time() - started, 1),
    }


def check_asset_contract():
    problems = []
    checked = []
    for rel, spec in ASSET_SPEC.items():
        path = ROOT / rel
        if not path.exists():
            if spec.get("optional"):
                continue
            problems.append(f"{rel}: 文件不存在")
            continue
        size = read_image_size(path)
        if size is None:
            problems.append(f"{rel}: 无法读取尺寸（格式不支持）")
            continue
        checked.append({"path": rel, "size": list(size), "expected": list(spec["size"]),
                        "sha256": sha256_of(path)[:16]})
        if size != tuple(spec["size"]):
            problems.append(f"{rel}: 尺寸 {size[0]}x{size[1]} != 期望 {spec['size'][0]}x{spec['size'][1]}（{spec['note']}）")
    return {
        "id": "asset-contract",
        "determinism": "contract",
        "pass": not problems,
        "checked": checked,
        "problems": problems,
    }


def check_import_hygiene():
    pngs = [p for p in ROOT.glob("assets/**/*.png")]
    imports = [p for p in ROOT.glob("assets/**/*.png.import")]
    orphans = [str(p.relative_to(ROOT)) for p in imports if not p.with_suffix("").exists()]
    missing = [str(p.relative_to(ROOT)) for p in pngs if not Path(str(p) + ".import").exists()]
    return {
        "id": "import-hygiene",
        "determinism": "filesystem",
        "pass": not missing,
        "png_count": len(pngs),
        "orphan_imports": orphans,
        "missing_imports": missing,
        "warnings": [f"孤儿 .import：{o}" for o in orphans],
    }


def check_sprite_refs():
    """balance.gd 里引用的贴图路径必须真实存在（坑 #10 的机器版）。"""
    balance = ROOT / "balance.gd"
    if not balance.exists():
        return {"id": "sprite-refs", "determinism": "filesystem", "pass": True, "reason": "无 balance.gd，跳过"}
    text = balance.read_text(encoding="utf-8", errors="replace")
    refs = sorted(set(re.findall(r'res://([A-Za-z0-9_./\-]+\.(?:png|webp|jpg))', text)))
    missing = [r for r in refs if not (ROOT / r).exists()]
    return {
        "id": "sprite-refs",
        "determinism": "filesystem",
        "pass": not missing,
        "ref_count": len(refs),
        "missing": missing,
    }


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--fast", action="store_true", help="跳过 240 帧 headless 运行")
    parser.add_argument("--json", action="store_true", help="把报告打到 stdout")
    args = parser.parse_args()

    checks = [check_import(), check_script_parse(), check_kill_credit(), check_weapons(),
              check_asset_contract(), check_import_hygiene(), check_sprite_refs(),
              check_touch(), check_hero_columns(), check_fx_entry(), check_font_coverage()]
    if not args.fast:
        checks.insert(1, check_runtime())

    failed = [c for c in checks if not c.get("pass")]
    warnings = [w for c in checks for w in c.get("warnings", [])]
    report = {
        "judge": "my-survivors L0 (smoke + asset contract)",
        "round_at": time.strftime("%Y-%m-%d %H:%M:%S"),
        "root": str(ROOT),
        "verdict": "pass" if not failed else "fail",
        "checks": checks,
        "warnings": warnings,
        "failed_checks": [c["id"] for c in failed],
        "next_action_for_build": None if not failed else "; ".join(
            f"{c['id']}: " + str(c.get("problems") or c.get("bad_lines") or c.get("missing")) for c in failed
        ),
    }

    QA_DIR.mkdir(parents=True, exist_ok=True)
    REPORT_PATH.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")

    for c in checks:
        mark = "PASS" if c.get("pass") else "FAIL"
        extra = ""
        if c["id"] == "kill-credit":
            extra = " (精确斩妖归属)"
        if c["id"] == "weapons-smoke":
            extra = " (6 把法宝被动/技能/进化/归属)"
            for line in c.get("info", [])[:2]:
                print(f"       {line}")
        if c["id"] == "fx-entry":
            extra = " (震屏/定帧统一入口)"
        if c["id"] == "hero-columns":
            extra = " (四向走路列自洽+朝向)"
        if c["id"] == "touch-controls":
            extra = " (触屏摇杆/神通按钮)"
        if c["id"] == "font-coverage":
            extra = " (中文字体子集覆盖全仓文案)"
            for line in c.get("info", [])[:1]:
                print(f"       {line}")
        if c["id"] == "asset-contract":
            extra = f" ({len(c.get('checked', []))} 项)"
        if c["id"] == "import-hygiene":
            extra = f" (png={c.get('png_count')}, 孤儿={len(c.get('orphan_imports', []))})"
        if c["id"] == "sprite-refs":
            extra = f" (引用 {c.get('ref_count', 0)} 个)"
        print(f"[{mark}] {c['id']}{extra}")
        for p in c.get("problems", [])[:5]:
            print(f"       - {p}")
        for w in c.get("warnings", [])[:5]:
            print(f"       ! {w}")
    print(f"verdict={report['verdict']}  报告={REPORT_PATH}")

    if args.json:
        print(json.dumps(report, ensure_ascii=False, indent=2))
    return 0 if report["verdict"] == "pass" else 1


if __name__ == "__main__":
    sys.exit(main())
