# Sufia under Docker (test app)

This is a very basic example/test of running a Sufia-based app under Docker.
There are three Docker related files here:

 * Dockerfile - the main Rails app
 * Dockerfile.base - the base image, building on the official Rails image,
   adding Sufia runtime dependencies
 * docker-compose.yml - A Compose file for bringing up all the backend services
   needed and a Rails server

## Usage

### Setup

_If you do not have Docker (and Compose) set up, read [below](#basic-docker-installation-osx)._

_Also, these examples use the `dc` alias for `docker-compose`. See
below for more [shell helpers](#shell-helpers)._

Ordinary usage will amount to starting the app and services with
`docker-compose up`, but there a couple of setup steps for the first run. Because
the `web` service needs Bundler to have installed the required gems, it is easiest
to build the image first, then run Bundler, then start up. The web image is the
only one that needs to be built, while the others will simply be pulled.

```
dc build web
dc run web bundle install
dc up web
```

By running `docker-compose up web`, the dependent services will be started, but
not stopped when you exit the web container. This is usually the most effective
pattern since occasional `rails server` restarts are needed, but the other
services can continue. With a bare `docker-compose up`, all the logs will be
collated to your shell and all services stopped upon Control-C (both unseemly
for typical development).

There are two other setup components required. The database must be set up and
the Solr core must be created. These are straightforward, but must be run
differently. The database setup is a usual rake task, run in the web image (a
new, throwaway container is fine).

```
dc run web rake db:create db:migrate
```

The Solr core must be run in the existing container because the `bin/solr`
script works locally, and `docker-compose run` creates temporary containers in
isolation from anything already running. The solution is `docker exec`, which
requires the generated container name/ID. Typically, this will be
`sufiacompose_solr_1`, but it is best to look it up with `docker ps`. The
easiest way to do this is to use the `de` function from the [shell helpers](#shell-helpers)
below.

```
de solr bin/solr create -c development -d /opt/config
# This would expand to:
# docker exec -it $(docker ps -qf name=solr) bin/solr create -c development -d /opt/config
```

At this point, everything should be up, running, and ready to use.

### Development Workflow

There are some differences from local development with Rails, but they are not
very involved. Just as with local development, sometimes you must run `bundle
install` or restart `rails server`. One-off Bundler commands or rake tasks can
be run in their own container. This is the `docker-compose run` pattern. For
examples (using the `dc` alias):

```
dc run web bundle install
dc run web rake db:migrate
dc run web rails c
```

Each of these commands says to create a new container using the web service
definition and run a process within it. Interactive processes like `rails
console` or `bash` work, but keep in mind that this is in a disposable
container, so files outside of mounted directories or system state (like
installed packages) will be discarded upon exit.

Restarting the Rails server is straightforward. Assuming you have started it
with `dc up web` and still have a shell connected, Control-C will terminate it,
and you can simply run `dc up web` again. If there was some abnormal
termination (like a system or VM crash), you may be warned and have to remove
`tmp/pids/server.pid`. You can force all services to stop with `dc stop`.


### Workflow on Windows

There are some problems with interactive terminals on Windows to be worked out.
There is a hard-coded platform check in docker-compose run that disables
interactive mode, even when using a shell that supports tty/pty. There are some
workarounds with `run -d` and `exec`. Some combination of Cmder (ConEmu) and/or
Babun (mintty) appears promising; more details TBD.

## Basic Docker Installation (OSX)

The easiest way to get a nice setup is to use [Docker Toolbox](https://www.docker.com/products/docker-toolbox).
The easiest way to install Docker Toolbox is with [Homebrew](http://brew.sh)/[Caskroom](https://caskroom.github.io).
If you need to set either of these up, they are each one-liners at the shell.

```
/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
brew tap caskroom/cask
```

If Hombrew is installed under a managed environment, you may need to do some
setup like adding your user to the appropriate group and creating a user-owned
cache directory. For example:

```
sudo dseditgroup -o edit -a $username_to_add -t user admin
mkdir -p ~/Library/Caches/Homebrew/Formula
```

Once Homebrew/Caskroom are in place, Docker Toolbox is easy to install, and
will include Docker, Machine, and Compose, as well as the Kitematic app and a
handy quick-launcher for a terminal that starts the default machine. It also
installs the latest VirtualBox.

```
brew cask install dockertoolbox
```

Unless you are familar with creating machines with Docker Machine, the best way
to create the `default` machine is to run the "Docker Quickstart Terminal" app
once. It will be your normal shell, but activating the default machine. You can
use a regular terminal afterwards and activate the machine manually or choose to
use the quickstart.

Because the VirtualBox shared folders are quite slow, Unison mounting is
recommended. The Compose file already has a `unison` container and volume set
up, and the `web` container uses this volume for `/usr/src/app`.

Installing Unison is one step:

```
brew install unison
```

The `web` container will not start until the app files are synced. You can work
around this by using `dc start unison` to start it without the rest of the
containers. Then, to sync, there is a helper function in `docker-profile.sh`
called `dsync`, which runs a Unison sync from the current directory to the
Docker Machine IP. It stays resident and monitors changes bidirectionally,
so this should be run in a separate shell and stay running during development.

## Shell Helpers

The commands for working with machines and containers can be unwieldy
sometimes. With a few helper functions/aliases, this can be simplified
significantly. The [docker-profile.sh](docker-profile.sh) file can be
concatenated to or sourced in your `bash_profile`, `zshrc`, or other.

It calls `dme`, which is short for `docker-machine env`. If in your
login/profile, this will activate the default machine automatically in each new
shell, if it is running.

The main two helpers are the aliases `dm` and `dc`, for `docker-machine` and
`docker-compose`, respectively. These are the most commonly used commands and
also the least wrist- and tab-completion-friendly, so the short aliases are a
large quality of life improvement with no magic to them.

