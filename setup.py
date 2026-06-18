#!/usr/bin/env python3
"""Setup shim — delegates to .skill-repos/slalom-discovery-kit/setup.py."""
import subprocess
import sys
from pathlib import Path

REPO_ROOT = Path(__file__).parent
WIZARD = REPO_ROOT / ".skill-repos" / "slalom-discovery-kit" / "setup.py"

def main() -> None:
    if not WIZARD.exists():
        print("Initialising submodules...")
        subprocess.run(
            ["git", "submodule", "update", "--init", "--recursive"],
            cwd=REPO_ROOT, check=True,
        )
    result = subprocess.run(
        [sys.executable, str(WIZARD)] + sys.argv[1:], cwd=REPO_ROOT,
    )
    sys.exit(result.returncode)

if __name__ == "__main__":
    main()
