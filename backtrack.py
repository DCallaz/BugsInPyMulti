import json
import sys
from os import path as osp

if __name__ == "__main__":
    usage = ("USAGE: python3 backtrack.py <backtracks dir> <project> "
             "<bugId> <version>")
    if (len(sys.argv) < 5):
        print(usage)
        quit()
    backtracks_dir = sys.argv[1]
    project = sys.argv[2]
    bugId = sys.argv[3]
    version = sys.argv[4]
    f = open(osp.join(backtracks_dir, project+"_backtrack.json"))
    backtrack = json.load(f)
    bugFix = None
    for bug in backtrack:
        if (bugId in bug["bug"].keys()):
            if (bugId == version):
                bugFix = bug["bug"]
            else:
                bugFix = bug[version]
            break
    if (bugFix is None or bugFix == "failed"):
        print("Bug not found: failed to apply backtrack")
    else:
        bugFix = bugFix[bugId]
        for file in bugFix:
            print(file, ','.join(map(str, bugFix[file])), sep=',')
