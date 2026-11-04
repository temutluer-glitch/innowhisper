# Final checks

At the end of `/build`, including a completed group of QA fixes, read
`docs/kit/guides/checks.md` and resolve the closing plan there. Build and deploy share that
contract. This changes only the final check: tasks/fixes still run targeted files, the main
agent runs full tests once per completed level, and QA runs one independent suite per runtime
before its lanes. Never put an aggregate into those inner loops.
