Path = require 'path'

DATA_DIR = Path.resolve(__dirname + "/../data/")

module.exports =
    # Options are passed to Sequelize.
    # See http://sequelizejs.com/documentation#usage-options for details
    mysql:
        clsi:
            storage: process.env["SQLITE_PATH"] or Path.join(DATA_DIR, "db.sqlite")
    path:
		# Where to write the project to disk before running LaTeX on it
        compilesDir: Path.join(DATA_DIR, "compiles")
		# Where to cache downloaded URLs for the CLSI
        clsiCacheDir: Path.join(DATA_DIR, "cache")
