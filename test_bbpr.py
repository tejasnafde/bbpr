"""Self-check for the diff line numbering. Run: python3 test_bbpr.py"""
import importlib.machinery
import importlib.util
import pathlib

spec = importlib.util.spec_from_loader(
    "bbpr", importlib.machinery.SourceFileLoader("bbpr", str(pathlib.Path(__file__).parent / "bbpr"))
)
bbpr = importlib.util.module_from_spec(spec)
spec.loader.exec_module(bbpr)

DIFF = """diff --git a/f.py b/f.py
--- a/f.py
+++ b/f.py
@@ -10,4 +20,5 @@ def f():
 ctx_a
-gone
+new_1
+new_2
 ctx_b
"""

EXPECT = """        | diff --git a/f.py b/f.py
        | --- a/f.py
        | +++ b/f.py
        | @@ -10,4 +20,5 @@ def f():
   20   | ctx_a
   11 - | gone
   21 + | new_1
   22 + | new_2
   23   | ctx_b"""

got = bbpr.number_diff(DIFF)
assert got == EXPECT, "\n--- got ---\n%s\n--- want ---\n%s" % (got, EXPECT)
print("ok")
