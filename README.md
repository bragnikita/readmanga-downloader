# readmanga-downloader
Ruby library and utility for manga chapters downloading from readmanga.me

## Usage

### Using manga.txt file for download tasks
```sh
> ls
manga.txt

> readmanga
# or you can specify this file with -t (--task) flag
> readmanga -t myfilters.txt
```

### Using command line parameters
Use `-f` (`--filter`) key to specify chapters to download
```sh
readmanga -url http://readmanga.me/puella_magi_madoka_magica___wraith_arc -f 3- 
```

## Options
* `-f (--filter) FILTER` chapters filter
* `-d (--dest) DIR` root directory for downloaded pages storing
* `-t (--test)` print provided parametes and without actually downloading
* `-u (--url) URL` **required** manga title page url 
* `-t (--task)` specify a task description file

## Available filters
* `3-` start from the 3th chapter
* `3-4,6` from 3 to 4 and 6
