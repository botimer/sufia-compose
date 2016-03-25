HOST=hydra.edu
[[ -n $1 ]] && HOST=$1
CMD="unison . socket://$HOST:5000/ -ignore 'Path .git' -ignore 'Path tmp' -auto -batch -prefer . -repeat watch -fastcheck true"
eval $CMD
