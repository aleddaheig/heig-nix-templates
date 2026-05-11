# Nix flake templates for HEIG-VD labs dev environments

[![built with nix](https://builtwithnix.org/badge.svg)](https://builtwithnix.org)

To initialize (where `${COURSE}` is one of the directory above):

```shell
nix flake init -t github:aleddaheig/heig-nix-templates#${COURSE}
```

Here's an example (for the [`arn`](./arn) template):

```shell
# Initialize the environment in the current directory
nix flake init -t github:aleddaheig/heig-nix-templates#arn

# Create a new folder
nix flake new -t github:aleddaheig/heig-nix-templates#arn arn
```

## How to use the templates

Once your preferred template has been initialized, you can use the provided shell in two ways:

1. If you have [`nix-direnv`][nix-direnv] installed, you can initialize the environment by running `direnv allow`.
2. If you don't have `nix-direnv` installed, you can run `nix develop` to open up the Nix-defined shell.

# Acknowledgements

This project is inspired by [the-nix-way/dev-templates](https://github.com/the-nix-way/dev-templates).
Thanks to the maintainers and contributors for the template patterns and flake conventions that shaped this repo.
Any remaining issues are ours.
