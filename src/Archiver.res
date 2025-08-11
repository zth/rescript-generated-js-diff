type t

type config = {
  zlib?: {
    level: int,
  },
}

@module("archiver") external create: (string, config) => t = "default"

@send external onError: (t, @as("error") _, unit => unit) => unit = "on"

@send external pipe: (t, Node.Fs.Stream.t) => unit = "pipe"

type fileConfig = {name: string}

@send external file: (t, string, fileConfig) => unit = "file"

@send external finalize: t => unit = "finalize"
