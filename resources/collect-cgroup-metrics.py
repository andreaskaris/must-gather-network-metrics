#!/usr/bin/env python3

import sys
import os
import subprocess
import datetime
import json
import getopt

# Constants
CGROUPS_FS = "/sys/fs/cgroup"

# Global vars that we'll populate later
output_dir = None
collect_cgroups = None


# usage prints usage info
def usage():
    print("-d|--directory <output-directory>")
    print("-c|--cgroups 'cgroup1 cgroup2 ...'")
    print("-h|--help")


# parse_options parses provided CLI options
def parse_options():
    global output_dir
    global collect_cgroups

    try:
        opts, args = getopt.getopt(sys.argv[1:], "hd:c:", ["help", "directory=", "cgroups"])
    except getopt.GetoptError as err:
        print(err)
        usage()
        sys.exit(2)
    for o, a in opts:
        if o in ("-h", "--help"):
            usage()
            sys.exit()
        elif o in ("-d", "--directory"):
            output_dir = a
        elif o in ("-c", "--cgroups"):
            collect_cgroups = a.split()
        else:
            assert False, "unhandled option"
    if output_dir == None or collect_cgroups == None:
        usage()
        sys.exit(2)


# collect_cgroup_info collects info from the selected cgroups for the selected
# containers
def collect_cgroup_info():
    global output_dir
    global collect_cgroups

    # create output dir
    os.makedirs(output_dir, exist_ok=True)

    # list date, all containers and all cgroup files
    now = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    cgroup_content = subprocess.check_output(["find", CGROUPS_FS, "-type", "f"]).decode().splitlines()
    container_info = json.loads(subprocess.check_output(["crictl", "ps", "--output", "json"]).decode())

    # iterate over all containers
    for cinfo in container_info["containers"]:
        # get all the ids that we need. Note that in file names, "-" is replaced with "_"
        cid = cinfo["id"].replace("-", "_")
        pid = cinfo["labels"]["io.kubernetes.pod.uid"].replace("-", "_")

        # build a combined name for the output directory
        container_name = cinfo["metadata"]["name"]
        pod_name = cinfo["labels"]["io.kubernetes.pod.name"]
        pod_namespace = cinfo["labels"]["io.kubernetes.pod.namespace"]
        combined_name = pod_namespace + "_" + pod_name + "_" + container_name

        # create directory structure if needed for the containers
        container_output_dir = os.path.join(output_dir, combined_name)
        os.makedirs(container_output_dir, exist_ok=True)
        for cg in collect_cgroups:
            os.makedirs(container_output_dir + "/" + cg, exist_ok=True)

        # iterate through cgroup content and match on pod and container ids
        for ccontent in cgroup_content:
            if pid in ccontent and "crio-" + cid in ccontent:
                for cg in collect_cgroups:
                    if cg in ccontent:
                        basename = os.path.basename(ccontent)
                        target_file = container_output_dir + "/" + cg + "/" + basename
                        try:
                            with open(ccontent, "r") as source_file:
                                s = source_file.read()
                                with open(target_file, "a") as target_file:
                                    target_file.write(now + "\n" + ccontent + "\n" + s)
                        except Exception:
                            pass


def main():
    parse_options()
    collect_cgroup_info()


if __name__ == "__main__":
    main()
