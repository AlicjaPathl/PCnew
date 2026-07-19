#!/usr/bin/env python3
"""
docs/test_all.py — automatyczne testy dokumentacji PC VM.

Uruchom z katalogu projektu:
    py docs/test_all.py
"""

from __future__ import annotations

import os
import re
import subprocess
import sys
import tempfile

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PY = sys.executable


def run(cmd: list[str], cwd: str = ROOT, timeout: int = 120) -> subprocess.CompletedProcess:
    env = os.environ.copy()
    env.setdefault("PYTHONUTF8", "1")
    return subprocess.run(
        cmd,
        cwd=cwd,
        capture_output=True,
        text=True,
        encoding="utf-8",
        errors="replace",
        timeout=timeout,
        env=env,
    )


def ok(name: str) -> None:
    print(f"  [OK] {name}")


def fail(name: str, detail: str) -> None:
    print(f"  [FAIL] {name}")
    print(detail.rstrip())
    raise SystemExit(1)


def expect_in(output: str, *needles: str) -> None:
    for needle in needles:
        if needle not in output:
            raise AssertionError(f"Brak oczekiwanego tekstu: {needle!r}\n--- output ---\n{output}")


def test_cc_and_vm() -> None:
    r = run([PY, "cc.py", "test.c"])
    if r.returncode != 0:
        fail("cc.py test.c", r.stderr or r.stdout)
    expect_in(r.stdout, "Compilation to Disk image successful", "test.ds")

    r = run([PY, "vm.py", "test.ds"])
    if r.returncode != 0:
        fail("vm.py test.ds", r.stderr or r.stdout)
    expect_in(r.stdout, "BOOT", "Hello from C program!", "Factorial(5)", "Done.")
    ok("cc.py + vm.py (test.c)")


def test_fileio() -> None:
    r = run([PY, "cc.py", "test_fileio.c"])
    if r.returncode != 0:
        fail("cc.py test_fileio.c", r.stderr or r.stdout)

    r = run([PY, "vm.py", "test_fileio.ds"])
    if r.returncode != 0:
        fail("vm.py test_fileio.ds", r.stderr or r.stdout)
    expect_in(r.stdout, "File I/O OK!", "Hello from VM fileio!")
    ok("fileio (test_fileio.c)")


def test_comp_cli() -> None:
    r = run([PY, "comp.py", "main.s", "main_from_comp.ds"])
    if r.returncode != 0:
        fail("comp.py main.s", r.stderr or r.stdout)
    expect_in(r.stdout, "Done. Output: main_from_comp.ds")

    r = run([PY, "vm.py", "main_from_comp.ds"])
    if r.returncode != 0:
        fail("vm.py main_from_comp.ds", r.stderr or r.stdout)
    expect_in(r.stdout, "BOOT", "OK: WSZYSTKO")
    ok("comp.py CLI + vm.py (main.s)")


def test_pyt() -> None:
    demo = os.path.join(ROOT, "docs", "examples", "pyt_demo.py")
    r = run([PY, "pyt.py", demo])
    if r.returncode != 0:
        fail("pyt.py docs/examples/pyt_demo.py", r.stderr or r.stdout)
    expect_in(r.stdout, "Fib(10) = 55", "Counter(5)")
    ok("pyt.py (docs/examples/pyt_demo.py)")


def test_asm_hello() -> None:
    hello_s = os.path.join(ROOT, "docs", "examples", "hello.s")
    hello_ds = os.path.join(ROOT, "docs", "examples", "hello.ds")
    r = run([PY, "comp.py", hello_s, hello_ds])
    if r.returncode != 0:
        fail("comp.py hello.s", r.stderr or r.stdout)

    r = run([PY, "vm.py", hello_ds])
    if r.returncode != 0:
        fail("vm.py hello.ds", r.stderr or r.stdout)
    expect_in(r.stdout, "BOOT", "Hello from ASM!")
    ok("hello.s przyklad z dokumentacji")


def test_docs_exist() -> None:
    required = [
        "docs/README.md",
        "docs/getting_started.md",
        "docs/architecture.md",
        "docs/assembly.md",
        "docs/c_programming.md",
        "docs/stdlib.md",
        "docs/pyt_interpreter.md",
        "docs/arduino_vm.md",
        "docs/tools.md",
        "docs/testing.md",
        "docs/troubleshooting.md",
    ]
    missing = [p for p in required if not os.path.exists(os.path.join(ROOT, p))]
    if missing:
        fail("pliki dokumentacji", "Brakuje: " + ", ".join(missing))
    ok("komplet plikow docs/")


def main() -> None:
    os.chdir(ROOT)
    print("PC VM — testy dokumentacji")
    print("=" * 40)
    test_docs_exist()
    test_cc_and_vm()
    test_fileio()
    test_comp_cli()
    test_asm_hello()
    test_pyt()
    print("=" * 40)
    print("Wszystkie testy przeszly pomyslnie.")


if __name__ == "__main__":
    main()
