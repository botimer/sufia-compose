# Activate a Docker machine by sourcing the environment variables.
# The first parameter is the optional machine name, the second, if any value is
# passed mutes the warning if the machine is not running. This is useful for
# running at login/shell startup to keep things quiet.
function dme() {
    MACHINE=default
    [[ -n $1 ]] && MACHINE=$1
		STATUS=$(docker-machine status $MACHINE)
		if [[ "Stopped" == "$STATUS" ]]; then
			if [[ -z $2 ]]; then
				echo "The Docker machine named '$MACHINE' is not running. Start it with docker-machine start $MACHINE before activating."
			fi
		else
			eval $(docker-machine env $MACHINE)
		fi
}

function dmequiet() {
	dme "$1" 1
}

# List Docker containers. If there is a parameter, use it as a name for searching
# and use short format, useful for expansion in other commands like exec.
function dps() {
    ARGS=""
    if [[ -n $1 ]]; then
        NAME=$1
        shift
        ARGS="-qf name=$NAME $@"
    fi
    docker ps $ARGS
}

# Run docker exec in a container searched by name. The first parameter
# is the name or fragment to search for, and the remainder of parameters
# are passed to exec. Runs in the first matching container.
function de() {
    if [[ -z $2 ]]; then
        echo "Usage: dexec <container search> <exec args>"
        echo "Example: dexec web bash"
    fi

    NAME=$1
    shift

    docker exec -it $(dps $NAME | head -1) "$@"
}

function dsync() {
    MACHINE=""
    if [[ -n $1 ]]; then
        MACHINE=$1
    else
        MACHINE="$(dm active)"
    fi

    HOST="$(dm ip $MACHINE)"
    PORT=5000
    if [[ -n $2 ]]; then
        PORT=$2
    fi

    unison . socket://$HOST:$PORT/ -ignore 'Path .git' -ignore 'Path tmp' -auto -batch -prefer . -repeat watch -fastcheck true
}

alias dm='docker-machine'
alias dc='docker-compose'

dmequiet
