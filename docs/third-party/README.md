# Remote plugin README renderer

- Marked 18.0.12: https://github.com/markedjs/marked, MIT license in `marked.LICENSE`.
- DOMPurify 3.4.15: https://github.com/cure53/DOMPurify, Apache-2.0 or MPL-2.0 terms in `purify.LICENSE`. Distributed here under Apache-2.0.

The unmodified ES module builds are vendored in `app/assets/remote-ui/static/vendor-marked.js` and `vendor-purify.js`. They were obtained from the corresponding versioned npm package tarballs. Keep the version, source and license notices together when updating them.

Copies of both license texts are bundled beside the modules as `vendor-marked.LICENSE.txt` and `vendor-purify.LICENSE.txt` so the APK and served remote UI include their distribution notices.
