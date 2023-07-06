# ingest

Shared internal tooling for pathogen data ingest.  Used by our individual
pathogen repos which produce Nextstrain builds.  Expected to be vendored by
each pathogen repo using `git subtree` (or `git subrepo`).

Some tools may only live here temporarily before finding a permanent home in
`augur curate` or Nextstrain CLI.  Others may happily live out their days here.

## History

Much of this tooling originated in
[ncov-ingest](https://github.com/nextstrain/ncov-ingest) and was passaged thru
[monkeypox's ingest/](https://github.com/nextstrain/monkeypox/tree/@/ingest/).
It subsequently proliferated from [monkeypox][] to other pathogen repos
([rsv][], [zika][], [dengue][], [hepatitisB][], [forecasts-ncov][]) primarily
thru copying.  To [counter that
proliferation](https://bedfordlab.slack.com/archives/C7SDVPBLZ/p1688577879947079),
this repo was made.

[monkeypox]: https://github.com/nextstrain/monkeypox
[rsv]: https://github.com/nextstrain/rsv
[zika]: https://github.com/nextstrain/zika/pull/24
[dengue]: https://github.com/nextstrain/dengue/pull/10
[hepatitisB]: https://github.com/nextstrain/hepatitisB
[forecasts-ncov]: https://github.com/nextstrain/forecasts-ncov

## Elsewhere

The creation of this repo, in both the abstract and concrete, and the general
approach to "ingest" has been discussed in various internal places, including:

- https://github.com/nextstrain/private/issues/59
- @joverlee521's [workflows document](https://docs.google.com/document/d/1rLWPvEuj0Ayc8MR0O1lfRJZfj9av53xU38f20g8nU_E/edit#heading=h.4g0d3mjvb89i)
- [5 July 2023 Slack thread](https://bedfordlab.slack.com/archives/C7SDVPBLZ/p1688577879947079)
- [6 July 2023 team meeting](https://docs.google.com/document/d/1FPfx-ON5RdqL2wyvODhkrCcjgOVX3nlXgBwCPhIEsco/edit)
- _…many others_
