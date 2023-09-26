import json
import sys
from os import path as osp


def get_backtrack(backtracks_dir, project, bugId, version):
    f = open(osp.join(backtracks_dir, project+"_backtrack.json"))
    backtrack = json.load(f)
    bugFix = None
    for bug in backtrack:
        if (bugId in bug["bug"].keys()):
            if (bugId == version):
                bugFix = bug["bug"]
            elif (version in bug):
                bugFix = bug[version]
            break
    if (bugFix is not None):
        if (bugFix == "failed"):
            bugFix = None
        else:
            bugFix = bugFix[bugId]
    return bugFix


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
    bugFix = get_backtrack(backtracks_dir, project, bugId, version)
    if (bugFix is None):
        print("Bug not found: failed to apply backtrack")
    else:
        for file in bugFix:
            print(file, ','.join(map(str, bugFix[file])), sep=',')
