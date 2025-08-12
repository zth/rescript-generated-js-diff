type t

@module("fast-glob") external fastGlob: t = "default"

type config = {
  cwd?: string,
  absolute?: bool,
  onlyFiles?: bool,
  dot?: bool,
  followSymbolicLinks?: bool,
}

@send external sync: (t, string, config) => array<string> = "sync"

let thisShouldShow = "this here should show in the diff"
