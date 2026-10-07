# Small path

For a typo, a config change, or a contained fix with an obvious solution. The
issue's acceptance criteria are the plan; there are no workflow comments.

1. **Implement** the change on the issue branch. Keep it to what the issue
   asks.
2. **Check:** run the required checks from the configuration, plus the
   workflow checks that apply. Fix failures.
3. **Commit** with the repository's convention and a `Refs #N` footer.
4. **Ship:** follow [ship.md](ship.md). In the PR, list each acceptance
   criterion with how you checked it, in place of the Verification comment
   link.

Switch to the normal path ([discuss.md](discuss.md)) as soon as any of these
happens:

- an open question or a design choice comes up;
- the change touches more than one area or needs a migration;
- the fix turns out not to be obvious, or the first attempt fails for a
  reason you do not understand.

Say that you switched, so the user knows workflow comments will follow.
