import json
import sys
import os
from os import path as osp

def powerset(s):
    x = len(s)
    masks = [1 << i for i in range(x)]
    for i in range(1 << x):
        yield [ss for mask, ss in zip(masks, s) if i & mask]

if __name__ == "__main__":
    if (len(sys.argv) < 2):
        print("USAGE: python dump_versions.py <project> [all]")
        quit()
    project = sys.argv[1]
    print_all = False
    if (len(sys.argv) > 2 and sys.argv[2] == "all"):
        print_all = True
    if (not osp.isdir(osp.join("versions", project))):
        print("ERROR: project", project, "not found")
        quit()
    sys.path.append(osp.join(os.getcwd(), "framework", "bin"))
    from backtrack import get_backtrack as backtrack

    location_versions = open(osp.join("backtracks", project+"_backtrack.json"))
    loc_js = json.loads(location_versions.read())

    versions = [int(f.name) for f in os.scandir(osp.join("versions", project)) if f.is_dir()]
    versions.sort()
    for version in versions:
        bugFile = open(osp.join("versions", project, str(version), "bugs.txt"))
        faults = [int(line.split(",")[0]) for line in bugFile.readlines()]
        faults.append(version)
        faults = list(set(faults))
        faults.sort()
        s = project
        for fault in faults:
            if (print_all or backtrack("backtracks", project, str(fault),
                str(version)) is not None):
                s += "-"+str(fault)
        print(s)
