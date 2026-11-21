#!/usr/bin/env bash
# Train a screen-blur model on Kaggle's GPUs instead of this PC: generate the notebook, push it, wait, download.
#
#   kaggle/run_blur.sh gender|seg [make_notebook.py options, e.g. --train-minutes 60]
#   KAGGLE_MACHINE=NvidiaTeslaP100 kaggle/run_blur.sh gender --train-minutes 200   # one GPU: double the minutes
#
# Credentials: the repo-root .env (copy .env.example; gitignored), or ~/.kaggle/kaggle.json, ~/.kaggle/access_token.
# The Kaggle username comes from KAGGLE_USERNAME, else from kaggle.json.
# Outputs land in kaggle/blur-<model>/out/ (gitignored). Ctrl-C stops waiting only; the run goes on at Kaggle, and
# `kaggle kernels output <user>/waaiya-blur-<model> -p kaggle/blur-<model>/out` fetches it later.
set -euo pipefail

model=${1:?usage: kaggle/run_blur.sh gender|seg [make_notebook.py options]}
shift
case $model in gender|seg) ;; *) echo "unknown model '$model' (gender or seg)" >&2; exit 2 ;; esac

here=$(cd "$(dirname "$0")" && pwd)

# Local secrets: the repo-root .env (gitignored; template in .env.example). Empty entries are dropped so they
# do not hide the ~/.kaggle files from the Kaggle CLI.
if [[ -f $here/../.env ]]; then
  set -a; source "$here/../.env"; set +a
  for v in KAGGLE_USERNAME KAGGLE_API_TOKEN KAGGLE_KEY; do [[ -n ${!v:-} ]] || unset "$v"; done
fi

user=${KAGGLE_USERNAME:-}
if [[ -z $user && -f ~/.kaggle/kaggle.json ]]; then
  user=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["username"])' ~/.kaggle/kaggle.json)
fi
[[ -n $user ]] || { echo "set KAGGLE_USERNAME to your Kaggle username" >&2; exit 2; }

dir=$(mktemp -d)
trap 'rm -rf "$dir"' EXIT

# A filled-in copy outside the repo: the committed metadata keeps the KAGGLE_USER placeholder.
python3 "$here/blur-$model/make_notebook.py" --owner "$user" --out "$dir" "$@"
# KAGGLE_MACHINE=NvidiaTeslaP100 picks the single P100 (often a shorter queue than the default 2x T4).
if [[ -n ${KAGGLE_MACHINE:-} ]]; then
  python3 - "$dir/kernel-metadata.json" "$KAGGLE_MACHINE" <<'EOF'
import json, sys
p, shape = sys.argv[1:]
m = json.load(open(p)); m["machine_shape"] = shape
json.dump(m, open(p, "w"), indent=1)
EOF
fi
kernel=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["id"])' "$dir/kernel-metadata.json")

kaggle kernels push -p "$dir"
echo "pushed: https://www.kaggle.com/code/$kernel"

while :; do
  sleep 60
  status=$(kaggle kernels status "$kernel" 2>&1 || true)
  echo "$(date +%H:%M) $status"
  case ${status,,} in
    *complete*) break ;;
    *error*|*cancel*) echo "run failed; see the log at https://www.kaggle.com/code/$kernel" >&2; exit 1 ;;
  esac
done

mkdir -p "$here/blur-$model/out"
kaggle kernels output "$kernel" -p "$here/blur-$model/out"
echo "outputs in $here/blur-$model/out"
