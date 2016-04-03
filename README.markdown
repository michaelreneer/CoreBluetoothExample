## Shared

#### Add Shared Submodule

```bash
cd "<Project Directory>"
git submodule add https://github.com/michaelreneer/Shared.git
```

#### Add Shared To Project

- Drag the folder from Finder into the Xcode Project Navigator.

#### Commit Changes

```bash
git commit -am "Added Shared to project."
```

#### Update Shared

```bash
cd "<Project Directory>/Shared"
git pull
cd "<Project Directory>"
git commit -am "Updated Shared."
```

For more information see the git documentation on [submodules][]

## License

Copyright (c) 2016 Michael Reneer. See LICENSE for details.

[submodules]: http://git-scm.com/book/en/Git-Tools-Submodules "Submodules"
