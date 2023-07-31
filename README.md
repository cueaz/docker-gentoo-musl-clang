# Building Pure Clang-only Gentoo Image

This was just an experiment I did about 2 years ago. It might not work today.

I created several clang patches to align with [Gentoo-style GCC Security Patches](https://gitweb.gentoo.org/proj/gcc-patches.git).

 * [clang: enable FORTIFY automatically](portage/patches/sys-devel/clang/enable-FORTIFY-by-default.patch)
 * [clang: find fortify headers](portage/patches/sys-devel/clang/apply-musl-FORTIFY.patch)
 * [lld: enable bindnow by default](portage/patches/sys-devel/lld/enable-bindnow-by-default.patch)
