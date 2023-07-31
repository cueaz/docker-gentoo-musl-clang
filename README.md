# Building Pure Clang-only Gentoo Image

This was just an experiment I did about 2 years ago. It might not work today.

As of 2023, ﻿[clang-musl-overlay](https://github.com/clang-musl-overlay/clang-musl-overlay) seems to be a better approach.

I have created several clang patches to align with [Gentoo-style GCC hardening patches](https://gitweb.gentoo.org/proj/gcc-patches.git).

 * [clang: enable fortify source by default](portage/patches/sys-devel/clang/enable-FORTIFY-by-default.patch)
 * [clang: find fortify headers](portage/patches/sys-devel/clang/apply-musl-FORTIFY.patch)
 * [lld: enable bindnow by default](portage/patches/sys-devel/lld/enable-bindnow-by-default.patch)
