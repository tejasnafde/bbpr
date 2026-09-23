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

PR = {"state": "OPEN", "source": {"commit": {"hash": "abcdef1234567890"}},
      "participants": [{"approved": True}, {"approved": False}]}
BUILDS = [{"state": "SUCCESSFUL"}, {"state": "FAILED"}, {"state": "SUCCESSFUL"}]
COMMENTS = [{"id": 1}, {"id": 2, "resolution": {"type": "resolved"}},
            {"id": 3, "parent": {"id": 1}}, {"id": 4, "deleted": True}]
got = bbpr.status_line(PR, BUILDS, COMMENTS)
want = "state=OPEN head=abcdef123456 builds=FAILED:1,SUCCESSFUL:2 comments=3 unresolved=1 approvals=1"
assert got == want, got
assert bbpr.status_line(PR, [], []).split()[2] == "builds=none"
print("ok")
