#!/bin/bash

TMUXSESSION=devenv

tmux attach-session -t $TMUXSESSION
if [ $? != 0 ]
then

##############################################################################
# ctags setup
##############################################################################

    echo "Building exuberant ctags..."

    cd $PROJECT_PATH
    ctags_flags=

    # add excludes
    if [ "" != "$CTAGS_EXCLUDES" ]; then # defined by `docker run`
        for a in $(echo $CTAGS_EXCLUDES | sed "s/,/ /g"); do
            ctags_flags="$ctags_flags --exclude=$a"
        done
    fi

    ctags-exuberant --exclude=.git --exclude=node_modules $ctags_flags -f /src/tags.devenv --append -R $PROJECT_PATH

##############################################################################
# tmux setup
##############################################################################

    echo "Creating tmux session..."

    # Create a new tmux session
    tmux new-session    -d -s $TMUXSESSION

    # System logs
    tmux rename-window     -t $TMUXSESSION:0 'Logs'
    tmux send-keys         -t $TMUXSESSION:0 "sudo tail -f /var/log/messages" C-m

    # editor
    tmux new-window        -t $TMUXSESSION:1
    tmux send-keys         -t $TMUXSESSION:1 "cd ${PROJECT_PATH} && clear && vim" C-m

    # shell
    tmux new-window        -t $TMUXSESSION:2
    tmux send-keys         -t $TMUXSESSION:2 "cd ${PROJECT_PATH} && clear" C-m

    # toggle order
    tmux select-window     -t $TMUXSESSION:2
    tmux select-window     -t $TMUXSESSION:1

    echo "Done."
    tmux attach-session    -t $TMUXSESSION
fi
