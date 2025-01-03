FROM mcr.microsoft.com/devcontainers/base:ubuntu

ARG USERNAME=cursor

RUN sh -c "$(wget -O- https://github.com/deluan/zsh-in-docker/releases/download/v1.2.1/zsh-in-docker.sh)" -- \
    -p git \
    -p zsh-autosuggestions \
    -p zsh-syntax-highlighting 

ENV DOTFILES_REPO="https://raw.githubusercontent.com/Luna-Runa/dotfiles/main"
ENV DOTFILES="\.p10k.zsh .zshrc .gitconfig commit_template.txt"

RUN for file in $DOTFILES; do \
        wget -q "$DOTFILES_REPO/$file" -O "$file"; \
    done

# Used to persist bash history as per https://code.visualstudio.com/remote/advancedcontainers/persist-bash-history
RUN SNIPPET="export PROMPT_COMMAND='history -a' && export HISTFILE=/commandhistory/.zsh_history" \
    && mkdir /commandhistory \
    && touch /commandhistory/.zsh_history \
    && chown -R $USERNAME /commandhistory \
    && echo "$SNIPPET" >> "/home/$USERNAME/.zshrc"