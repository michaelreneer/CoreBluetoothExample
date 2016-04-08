## Shared

#### Install Shared Submodule

Add [submodule][] in git.

```bash
cd "<Project Directory>"
git submodule add "https://github.com/michaelreneer/Shared.git"
```

Drag the Shared folder from Finder into the Xcode Project Navigator.

Commit the changes.

```bash
git commit -am "Added Shared to project."
```

#### Update Shared Submodule

```bash
cd "<Project Directory>/Shared"
git pull
cd "<Project Directory>"
git commit -am "Updated Shared."
```

#### Install clang-format

```bash
cd "<Projects Directory>"
curl "http://llvm.org/releases/3.8.0/clang+llvm-3.8.0-x86_64-apple-darwin.tar.xz" -o "clang+llvm-3.8.0.tar.xz"
tar xf "clang+llvm-3.8.0.tar.xz"
ln -s "clang+llvm-3.8.0/bin/clang-format" "/usr/local/bin"
ln -s "clang+llvm-3.8.0/bin/git-clang-format" "/usr/local/bin"
```

## License

Copyright (c) 2016 Michael Reneer. See LICENSE for details.

[submodule]: http://git-scm.com/book/en/Git-Tools-Submodules "Submodule"

