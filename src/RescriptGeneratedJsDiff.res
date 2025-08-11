open Node

external importMetaUrl: string = "import.meta.url"
external argv: array<string> = "process.argv"
external cwd: unit => string = "process.cwd"
external exit: int => 'any = "process.exit"

let dirname = URL.make(".", ~base=importMetaUrl)->URL.fileURLToPath

let findConfig = baseDir => {
  let candidates = ["rescript.json", "bsconfig.json"]

  candidates
  ->Array.map(configName => Path.join([baseDir, configName]))
  ->Array.find(Fs.existsSync)
  ->Option.getOrThrow(
    ~message="Could not find a ReScript config file (rescript.json or bsconfig.json) in the target directory.",
  )
}

type sourceEntry = {
  dir: string,
  subdirs: bool,
}

let toSourceEntries = sources => {
  let normalize = json =>
    switch json {
    | JSON.String(s) => {dir: s, subdirs: true}
    | JSON.Object(dict{"dir": ?dir, "subdirs": ?subdirs}) => {
        dir: switch dir {
        | Some(String(dir)) => dir
        | _ => "."
        },
        subdirs: switch subdirs {
        | Some(Boolean(subdirs)) => subdirs
        | _ => true
        },
      }
    | _ => panic("Invalid `sources` config in ReScript config file.")
    }

  switch sources {
  | JSON.Array(array) => array->Array.map(normalize)
  | JSON.String(_) | JSON.Object(_) => [normalize(sources)]
  | _ => []
  }
}

let collectFilesWithSuffix = (~baseDir, ~sourceDir, ~recursive, ~suffix) => {
  let root = Path.join([baseDir, sourceDir])

  if !Fs.existsSync(root) || !Fs.statSync(root).isDirectory() {
    []
  } else {
    let rel = Path.relative(baseDir, root)
    let tail = `*${suffix}`
    let pattern = recursive ? `${rel}/**/${tail}` : `${rel}/${tail}`
    FastGlob.fastGlob->FastGlob.sync(
      pattern,
      {cwd: baseDir, absolute: true, onlyFiles: true, dot: false, followSymbolicLinks: true},
    )
  }
}

let uniqueSorted = list => {
  let l =
    list
    ->Set.fromArray
    ->Set.toArray

  l->Array.sort(String.compare)

  l
}

let ensureParentDir = p => {
  let dir = Path.dirname(p)

  if !Fs.existsSync(dir) {
    Fs.mkdirSync(dir, {recursive: true})
  }
}

let createZip = async (~baseDir, ~filesAbs, ~outPath) => {
  let filesRel = filesAbs->Array.map(f => Path.relative(baseDir, f))
  await Promise.make((resolve, reject) => {
    let output = Fs.createWriteStream(outPath)
    let archive = Archiver.create("zip", {zlib: {level: 9}})

    output->Fs.Stream.onClose(() => {
      resolve()
    })
    archive->Archiver.onError(() => {
      reject()
    })
    archive->Archiver.pipe(output)

    filesRel->Array.forEach(rel => {
      archive->Archiver.file(Path.join([baseDir, rel]), {name: rel})
    })

    archive->Archiver.finalize
  })
}

let procudeDiffZip = async (~baseDirArg, ~outArg) => {
  let baseDir = switch Path.isAbsolute(baseDirArg) {
  | true => baseDirArg
  | false => Path.join([cwd(), baseDirArg])
  }

  let cfgPath = findConfig(baseDir)
  let cfg = JSON.parseOrThrow(Fs.readFileSync(cfgPath, "utf8"))

  let (suffix, sources) = switch cfg {
  | JSON.Object(dict{"suffix": ?suffix, "sources": sources}) => (
      switch suffix {
      | Some(String(suffix)) => suffix
      | _ => ".bs.js"
      },
      toSourceEntries(sources),
    )
  | _ => (".bs.js", [])
  }

  Console.log(`=== Zipping files with suffix "${suffix}"...`)

  let files =
    sources->Array.flatMap(s =>
      collectFilesWithSuffix(~baseDir, ~sourceDir=s.dir, ~recursive=s.subdirs, ~suffix)
    )

  switch uniqueSorted(files) {
  | [] =>
    Console.error(`No files with suffix "${suffix}" (??) found in configured sources.`)
    exit(1)
  | files =>
    let resolvedOutPath = switch outArg {
    | None => Path.join([baseDir, "diff.zip"])
    | Some(outArg) => Path.isAbsolute(outArg) ? outArg : Path.join([baseDir, outArg])
    }

    ensureParentDir(resolvedOutPath)
    switch await createZip(~baseDir, ~filesAbs=files, ~outPath=resolvedOutPath) {
    | exception _ =>
      Console.error(`Failed to create zip file!`)
      exit(1)
    | _ => ()
    }

    Console.log(`=== Created zip file: ${resolvedOutPath}`)
    Console.log(`=== Done.`)
    exit(0)
  }
}

let saveGeneratedJsUsageStr = "rescript-generated-js-diff save-generated-js <base-dir> [out-file]"

let main = async () => {
  let args = argv->Array.slice(~start=2)->List.fromArray

  switch args {
  | list{"save-generated-js", ...args} if List.length(args) >= 1 =>
    let (baseDirArg, outArg) = switch args {
    | list{baseDir} => (baseDir, None)
    | list{baseDir, outFile} => (baseDir, Some(outFile))
    | _ => panic(`Usage: ${saveGeneratedJsUsageStr}`)
    }

    await procudeDiffZip(~baseDirArg, ~outArg)
  | _ =>
    Console.error(`Usage: ${saveGeneratedJsUsageStr}`)
    exit(1)
  }
}

main()
->Promise.catch(e => {
  Console.error2(`Something went wrong`, e)
  exit(1)
})
->Promise.ignore
