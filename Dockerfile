# syntax = docker/dockerfile:1.2-labs
FROM gentoo/stage3:musl-vanilla

ARG BUID=1000
ARG BGID=1000
ARG BUSER=user

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

ENV GPORTAGE=/etc/portage

RUN pushd $GPORTAGE && \
    ls | grep -v make.conf | grep -v make.profile | xargs rm -rf && \
    popd

COPY portage/env                     $GPORTAGE/env
COPY portage/patches                 $GPORTAGE/patches
COPY portage/profile                 $GPORTAGE/profile
COPY portage/package.env             $GPORTAGE/package.env
COPY portage/package.use             $GPORTAGE/package.use
COPY portage/package.accept_keywords $GPORTAGE/package.accept_keywords
COPY portage/package.mask            $GPORTAGE/package.mask
COPY portage/repos.conf              $GPORTAGE/repos.conf.new
COPY portage/make.conf               $GPORTAGE/make.conf.new

RUN --security=insecure \
    find $GPORTAGE -type f -exec chmod 644 -- {} + && \
    find $GPORTAGE -type d -exec chmod 755 -- {} + && \
    \
    ncpus="$(( $(cat /proc/cpuinfo | grep processor | wc -l) ))" && \
    export MAKEOPTS="-j$ncpus" && \
    export CONFIG_PROTECT="-*" && \
    export CLEAN_DELAY=0 && \
    \
    emerge-webrsync && \
    emerge --verbose dev-vcs/git && \
    mv $GPORTAGE/repos.conf.new $GPORTAGE/repos.conf && \
    rm -rf /var/db/repos/* && \
    emerge --sync && \
    emerge --verbose --update --deep --changed-use @world && \
    \
    emerge --verbose sys-libs/fortify-headers sys-devel/clang && \
    mv $GPORTAGE/make.conf.new $GPORTAGE/make.conf && \
    emerge --verbose --unmerge dev-util/cmake && \
    emerge --verbose --oneshot dev-libs/jsoncpp dev-util/cmake && \
    \
    pushd /usr/bin && \
    chost=$(portageq envvar CHOST) && \
    ls $(binutils-config -B) | fgrep -v $chost- | xargs -d $'\n' -I {} rm -vf {} $chost-{} && \
    ls $(gcc-config -B) | fgrep -v $chost- | xargs -d $'\n' -I {} rm -vf {} $chost-{} && \
    rm -vf cc f77 && \
    popd && \
    emerge --verbose --unmerge gcc-config binutils-config && \
    emerge --verbose --depclean && \
    \
    emerge --verbose @preserved-rebuild && \
    emerge --verbose --depclean && \
    \
    rm -rf /etc/env.d/*binutils* /etc/env.d/*gcc* && \
    env-update && \
    rm -rf /usr/$chost && \
    \
    emerge --verbose --emptytree @world && \
    emerge --verbose --depclean && \
    \
    source /etc/profile && \
    ln -sr $(which clang) /usr/local/bin/cc && \
    ln -sr /usr/lib/libunwind.so.1 /usr/local/lib/libgcc_s.so.1 && \
    echo 'INPUT(-lunwind)' > /usr/local/lib/libgcc_s.so && \
    export RUSTFLAGS="$(portageq envvar RUSTFLAGS) -L/usr/lib -L/usr/local/lib" && \
    emerge --verbose app-admin/doas \
                     app-portage/gentoolkit app-portage/portage-utils \
                     app-text/mandoc net-misc/curl app-text/tree \
                     sys-process/procps app-shells/fish app-misc/tmux \
                     media-video/ffmpeg sys-process/glances \
                     app-shells/fzf sys-apps/bat sys-apps/fd sys-apps/ripgrep \
                     app-text/editorconfig-core-c app-editors/micro app-shells/starship \
                     dev-util/lldb dev-util/cmake && \
                     emerge --verbose --depclean && \
    rm /usr/local/bin/cc /usr/local/lib/libgcc_s.so{,.1} && \
    \
    emerge --verbose @preserved-rebuild && \
    emerge --verbose --depclean --with-bdeps=n && \
    \
    find /bin /sbin /lib /etc /var /usr -xtype l -print -delete && \
    rm -rf /var/tmp/* && \
    rm -rf /var/cache/* && \
    rm -rf /var/db/repos/* && \
    rm -rf /tmp/* && \
    \
    groupadd --gid $BGID --non-unique $BUSER && \
    useradd --create-home --shell /bin/bash --password '*' --uid $BUID --gid $BGID --non-unique $BUSER && \
    echo "permit nopass $BUSER" >> /etc/doas.conf && \
    sed --in-place 's/^.\?PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config && \
    sed --in-place 's/^.\?PasswordAuthentication.*/PasswordAuthentication no/' /etc/ssh/sshd_config && \
    sed --in-place 's/^.\?PrintMotd.*/PrintMotd no/' /etc/ssh/sshd_config && \
    sed --in-place 's/^.\?PrintLastLog.*/PrintLastLog no/' /etc/ssh/sshd_config && \
    ssh-keygen -A

USER $BUSER

COPY --chown=$BUSER ssh/id_ed25519_remote.pub /home/$BUSER/.ssh/authorized_keys
COPY --chown=$BUSER home/ /home/$BUSER/

RUN find ~ -type f -exec chmod 644 -- {} + && \
    find ~ -type d -exec chmod 755 -- {} + && \
    chmod 700 ~/.ssh && \
    chmod 400 ~/.ssh/authorized_keys && \
    \
    echo "command -v fish &> /dev/null && [[ \$(ps --no-header --pid=\$PPID --format=cmd) != 'fish' ]] && exec fish" >> ~/.bashrc && \
    fish -c 'curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher PatrickF1/fzf.fish' && \
    mkdir ~/work && \
    \
    rm -rf /tmp/*

FROM scratch

ARG BUID
ARG BGID
ARG BUSER

ENV MYUID=$BUID
ENV MYGID=$BGID
ENV MYUSER=$BUSER

COPY --from=0 / /

EXPOSE 22

CMD groupmod --gid $MYGID --non-unique $MYUSER && \
    usermod  --uid $MYUID --gid $MYGID --non-unique $MYUSER && \
    exec /usr/sbin/sshd -D
