# title

testing34

## Description

## Replication instructions

- Creating the databases:
  - Install PostgreSQL (16 in this setup) server.
  - Create a new role and database.
  - Copy this for the import initial IMDb database: https://gist.github.com/1mehal/13c85e108cbc906f5ec34d28d75b1968
    - Make sure to install the packages instructed at the top of the aforementioned file.
    - When prompted for the IMDb data files, leave empty, and the script will download the data files.
    - If the script fails on Line 82, remove the dash before "csvsql".
  - Run all files (in alphabetical order) starting with 01..04 under /inputs using psql's \i command.
- Running the benchmarks:
  - Run the benchmarks one by one by calling the scripts under /tests.

## References
