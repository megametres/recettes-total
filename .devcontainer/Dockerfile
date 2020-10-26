#-------------------------------------------------------------------------------------------------------------
# Copyright (c) Microsoft Corporation. All rights reserved.
# Licensed under the MIT License. See https://go.microsoft.com/fwlink/?linkid=2090316 for license information.
#-------------------------------------------------------------------------------------------------------------

FROM buildpack-deps:buster

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

# Configure apt and install packages
RUN apt-get update \
    && apt-get -y install --no-install-recommends apt-utils dialog 2>&1 \
    #
    # Verify git, needed tools installed
    && apt-get -y install git procps lsb-release \
    #
    # Install other dependencies
    && apt-get install -y lldb npm sudo \
    #
    # Clean up
    && apt-get autoremove -y \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# User info
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID
ARG USER_HOME=/home/$USERNAME

# Create a non-root user to use if preferred - see https://aka.ms/vscode-remote/containers/non-root-user.
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && usermod -a -G staff $USERNAME \
    #
    # [Optional] Add sudo support for non-root user
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME


# Setup env for rust
ENV RUSTUP_HOME=$USER_HOME/.rustup \
    CARGO_HOME=$USER_HOME/.cargo \
    PATH=$USER_HOME/.cargo/bin:$PATH

USER $USERNAME
WORKDIR $USER_HOME

# Install rustup
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs > rustup-init.sh \
    && chmod +x rustup-init.sh \
    && ./rustup-init.sh -y --default-toolchain nightly-gnu

# Install Rust components ( To know when to update, check https://rust-lang.github.io/rustup-components-history/armv7-unknown-linux-gnueabihf.html )
RUN rustup toolchain install nightly-2020-10-11 -c rls -c rust-analysis -c rust-src\
    && cargo install diesel_cli

EXPOSE 8000

# Switch back to dialog for any ad-hoc use of apt-get
ENV DEBIAN_FRONTEND=
