module Fs = {
  @module("node:fs") external existsSync: string => bool = "existsSync"

  type statResult = {isDirectory: unit => bool}

  @module("node:fs") external statSync: string => statResult = "statSync"

  type mkdirOptions = {recursive?: bool}

  @module("node:fs") external mkdirSync: (string, mkdirOptions) => unit = "mkdirSync"

  @module("node:fs") external readFileSync: (string, string) => string = "readFileSync"

  module Stream = {
    type t

    @send external onClose: (t, @as("close") _, unit => unit) => unit = "on"
  }

  @module("node:fs") external createWriteStream: string => Stream.t = "createWriteStream"
}

module Path = {
  @variadic @module("node:path") external join: array<string> => string = "join"

  @module("node:path") external relative: (string, string) => string = "relative"

  @module("node:path") external dirname: string => string = "dirname"

  @module("node:path") external isAbsolute: string => bool = "isAbsolute"
}

module URL = {
  type t

  @module("node:url") external fileURLToPath: t => string = "fileURLToPath"

  @new
  external make: (string, ~base: string=?) => t = "URL"
}

module ChildProcess = {
  @module("node:child_process")
  external spawnSync: (string, array<string>, {"cwd": string}) => {"status": option<int>} =
    "spawnSync"
}
