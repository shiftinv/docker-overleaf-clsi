import os
import sys
import re
import subprocess

def print_err(s):
    sys.stderr.write('{}\n'.format(s))
    sys.stderr.flush()

if len(sys.argv) != 4:
    print_err('Usage: {} <texfile> <jobname> <working directory>'.format(sys.argv[0]))
    sys.exit(1)

jobname = sys.argv[2]
outdir = sys.argv[3]

try:
    if os.stat(os.path.join(outdir, '{}.sagetex.stderr.log'.format(jobname))).st_size != 0:
        print_err('Previous run failed, refusing to try again.')
        sys.exit(1)
except IOError:
    pass

# anonymous compile directories don't have a user id, see
#  https://github.com/overleaf/clsi/blob/812c4e661f/app/coffee/CompileManager.coffee#L21
if not re.match(r'^.*/compiles/[0-9a-f]{24}-[0-9a-f]{24}/?$', outdir):
    print_err('Only authenticated users may use sagetex/run sage scripts.')
    sys.exit(1)

run_sagetex = os.path.join(sys.path[0], 'run-sagetex-if-necessary.py')
sys.exit(subprocess.call(['python', run_sagetex] + sys.argv[1:]))
