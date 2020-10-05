set -ex

main() {
    local version=12.4
    local os=$1 \
          triple=$2

    td=$(mktemp -d)

    pushd $td
    curl https://ftp.postgresql.org/pub/source/v${version}/postgresql-${version}.tar.bz2 | \
        tar --strip-components=1 -xj
    AR=${triple}-ar CC=${triple}-gcc CPP=${triple}-cpp ./configure --without-readline --without-zlib --host=${os} --prefix=/
    nice make -j$(nproc)
    make install

    # clean up
    rm -rf $td
    rm $0
}

main "${@}"