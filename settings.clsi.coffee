Path = require 'path'

module.exports =
    mysql:
        clsi:
            storage: Path.resolve(__dirname + "/../data/db.sqlite")
    path:
        compilesDir: Path.resolve(__dirname + "/../data/compiles")
        clsiCacheDir: Path.resolve(__dirname + "/../data/cache")
