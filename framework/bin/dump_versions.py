#!/bin/python3
import json
import sys
import os
import getopt
from os import path as osp

def powerset(s):
    x = len(s)
    masks = [1 << i for i in range(x)]
    for i in range(1 << x):
        yield [ss for mask, ss in zip(masks, s) if i & mask]


def get_versions(project, version_dir, backtrack_dir, print_all=False):
    vs = []
    if (not osp.isdir(osp.join(version_dir, project))):
        print("ERROR: project", project, "not found")
        quit()
    sys.path.append(osp.join(os.getcwd(), "framework", "bin"))
    from backtrack import get_backtrack as backtrack

    versions = [int(f.name) for f in os.scandir(osp.join(version_dir, project)) if f.is_dir()]
    versions.sort()
    for version in versions:
        bugFile = open(osp.join(version_dir, project, str(version), "bugs.txt"))
        faults = [int(line.split(",")[0]) for line in bugFile.readlines()]
        # faults.append(version)
        if (version not in faults):
            continue
        faults = list(set(faults))
        faults.sort()
        s = (project, [])
        for fault in faults:
            if (print_all or backtrack(backtrack_dir, project, str(fault),
                str(version)) is not None):
                s[1].append(fault)
        vs.append(s)
    return vs


if __name__ == "__main__":
    # Process arguments
    usage = "USAGE: python dump_versions.py [-h] [-v <version dir>] " \
                "[-b <backtrack dir>] <project> [all]"
    args = sys.argv[1:]
    try:
        opts, args = getopt.getopt(args, "hv:b:", ["help"])
    except getopt.GetoptError as err:
        print(err)
        print(usage)
        quit()
    opt_dict = dict(opts)
    if ('-h' in opt_dict or '--help' in opt_dict):
        print(usage)
        quit()
    version_dir = 'versions'
    backtrack_dir = 'backtracks'
    if ('-v' in opt_dict):
        version_dir = opt_dict['-v']
    if ('-b' in opt_dict):
        backtrack_dir = opt_dict['-b']
    if (len(args) < 1):
        print("ERROR: please specify a project")
        print(usage)
        quit()
    project = args[0]
    print_all = False
    if (len(args) > 1 and args[1] == "all"):
        print_all = True
    # Get versions
    versions = get_versions(project, version_dir, backtrack_dir, print_all)
    for v in versions:
        print(v[0], *v[1], sep="-")
