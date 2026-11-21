# zstd 1.5.7, decoder only

`zstddeclib.c` is zstd's own single-file decoder, generated from the release tarball
(https://github.com/facebook/zstd/releases/download/v1.5.7/zstd-1.5.7.tar.gz, sha256
eb33e51f49a15e023950cd7825ca74a4a2b43db8354825ac24fc1b7ee09e6fa3) with
`build/single_file_libs/combine.sh -r ../../lib -o zstddeclib.c zstddeclib-in.c`. `zstd.h` and `zstd_errors.h` are
copied from `lib/`. Licence: BSD (LICENSE). Used only by `../zpatch` to rebuild an update's APK from the installed one.
