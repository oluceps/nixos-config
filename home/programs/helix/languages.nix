{ pkgs, lib, ... }:
let

  apps = lib.genAttrs [
    "rust-analyzer"
    "black"
    "nil"
    "shfmt"
    "nixpkgs-fmt"
    # "bash-language-server"
    "taplo"
    "rustfmt"
  ]
    (name: lib.getExe pkgs.${name});

  clangd = "${pkgs.clang-tools}/bin/clangd";
  # bash-language-server = "${pkgs.nodePackages_latest.bash-language-server}/bin/bash-language-server";

in
with apps;{
  language = [
    {
      auto-format = true;
      auto-pairs = {
        "\"" = "\"";
        "(" = ")";
        "[" = "]";
        "`" = "`";
        "{" = "}";
      };
      comment-token = "//";
      debugger = {
        command = "lldb-vscode";
        name = "lldb-vscode";
        templates = [{
          args = {
            program = "{0}";
          };
          completion = [{
            completion = "filename";
            name = "binary";
          }];
          name = "binary";
          request = "launch";
        }
          {
            args = {
              program = "{0}";
              runInTerminal = true;
            };
            completion = [{
              completion = "filename";
              name = "binary";
            }];
            name = "binary (terminal)";
            request = "launch";
          }
          {
            args = {
              pid = "{0}";
            };
            completion = [ "pid" ];
            name = "attach";
            request = "attach";
          }
          {
            args = {
              attachCommands = [ "platform select remote-gdb-server" "platform connect {0}" "file {1}" "attach {2}" ];
            };
            completion = [{
              default = "connect://localhost:3333";
              name = "lldb connect url";
            }
              {
                completion = "filename";
                name = "file";
              }
              "pid"];
            name = "gdbserver attach";
            request = "attach";
          }];
        transport = "stdio";
      };
      file-types = [ "rs" ];
      formatter = {
        args = [ "--edition" "2021" ];
        command = rustfmt;
      };
      indent = {
        tab-width = 4;
        unit = "    ";
      };
      injection-regex = "rust";
      language-server = {
        command = rust-analyzer;
      };
      name = "rust";
      roots = [ "Cargo.toml" "Cargo.lock" ];
      scope = "source.rust";
    }
    # {
    #   comment-token = "#";
    #   file-types = [ "toml" ];
    #   formatter = {
    #     args = [ "format" "-" ];
    #     command = taplo;
    #   };
    #   indent = {
    #     tab-width = 2;
    #     unit = "  ";
    #   };
    #   injection-regex = "toml";
    #   language-server = {
    #     args = [ "lsp" "stdio" ];
    #     command = taplo;
    #   };
    #   name = "toml";
    #   roots = [ ];
    #   scope = "source.toml";
    # }
    {
      comment-token = "#";
      file-types = [ "awk" "gawk" "nawk" "mawk" ];
      indent = {
        tab-width = 2;
        unit = "  ";
      };
      injection-regex = "awk";
      language-server = {
        command = "awk-language-server";
      };
      name = "awk";
      roots = [ ];
      scope = "source.awk";
    }
    {
      comment-token = "#";
      config = {
        elixirLS = {
          dialyzerEnabled = false;
        };
      };
      file-types = [ "ex" "exs" "mix.lock" ];
      indent = {
        tab-width = 2;
        unit = "  ";
      };
      injection-regex = "(elixir|ex)";
      language-server = {
        command = "elixir-ls";
      };
      name = "elixir";
      roots = [ ];
      scope = "source.elixir";
      shebangs = [ "elixir" ];
    }
    {
      comment-token = "#";
      file-types = [ "fish" ];
      indent = {
        tab-width = 4;
        unit = "    ";
      };
      injection-regex = "fish";
      name = "fish";
      roots = [ ];
      scope = "source.fish";
      shebangs = [ "fish" ];
    }
    {
      auto-format = false;
      config = {
        provideFormatter = true;
      };
      file-types = [ "json" ];
      formatter = {
        args = [ "--parser" "json" ];
        command = "prettier";
      };
      indent = {
        tab-width = 2;
        unit = "  ";
      };
      injection-regex = "json";
      language-server = {
        args = [ "--stdio" ];
        command = "vscode-json-language-server";
      };
      name = "json";
      roots = [ ];
      scope = "source.json";
    }
    {
      comment-token = "//";
      debugger = {
        command = "lldb-vscode";
        name = "lldb-vscode";
        templates = [{
          args = {
            console = "internalConsole";
            program = "{0}";
          };
          completion = [{
            completion = "filename";
            name = "binary";
          }];
          name = "binary";
          request = "launch";
        }
          {
            args = {
              console = "internalConsole";
              pid = "{0}";
            };
            completion = [ "pid" ];
            name = "attach";
            request = "attach";
          }
          {
            args = {
              attachCommands = [ "platform select remote-gdb-server" "platform connect {0}" "file {1}" "attach {2}" ];
              console = "internalConsole";
            };
            completion = [{
              default = "connect://localhost:3333";
              name = "lldb connect url";
            }
              {
                completion = "filename";
                name = "file";
              }
              "pid"];
            name = "gdbserver attach";
            request = "attach";
          }];
        transport = "stdio";
      };
      file-types = [ "c" ];
      formatter = {
        args = [ "-style=file:${pkgs.writeText "clang-format" (builtins.readFile ./clang-format.yaml)}" ];
        command = "clang-format";
      };
      indent = {
        tab-width = 8;
        unit = "        ";
      };
      injection-regex = "c";
      language-server = {
        command = clangd;
      };
      name = "c";
      roots = [ ];
      scope = "source.c";
    }
    {
      comment-token = "//";
      debugger = {
        command = "lldb-vscode";
        name = "lldb-vscode";
        templates = [{
          args = {
            console = "internalConsole";
            program = "{0}";
          };
          completion = [{
            completion = "filename";
            name = "binary";
          }];
          name = "binary";
          request = "launch";
        }
          {
            args = {
              console = "internalConsole";
              pid = "{0}";
            };
            completion = [ "pid" ];
            name = "attach";
            request = "attach";
          }
          {
            args = {
              attachCommands = [ "platform select remote-gdb-server" "platform connect {0}" "file {1}" "attach {2}" ];
              console = "internalConsole";
            };
            completion = [{
              default = "connect://localhost:3333";
              name = "lldb connect url";
            }
              {
                completion = "filename";
                name = "file";
              }
              "pid"];
            name = "gdbserver attach";
            request = "attach";
          }];
        transport = "stdio";
      };
      file-types = [ "cc" "hh" "cpp" "hpp" "h" "ipp" "tpp" "cxx" "hxx" "ixx" "txx" "ino" ];
      formatter = {
        args = [ "-style=file:${pkgs.writeText "clang-format" (builtins.readFile ./clang-format.yaml)}" ];
        command = "clang-format";
      };
      indent = {
        tab-width = 8;
        unit = "        ";
      };
      injection-regex = "cpp";
      language-server = {
        command = "clangd";
      };
      name = "cpp";
      roots = [ ];
      scope = "source.cpp";
    }
    {
      auto-format = true;
      comment-token = "//";
      debugger = {
        args = [ "dap" ];
        command = "dlv";
        name = "go";
        port-arg = "-l 127.0.0.1:{}";
        templates = [{
          args = {
            mode = "debug";
            program = "{0}";
          };
          completion = [{
            completion = "filename";
            default = ".";
            name = "entrypoint";
          }];
          name = "source";
          request = "launch";
        }
          {
            args = {
              mode = "exec";
              program = "{0}";
            };
            completion = [{
              completion = "filename";
              name = "binary";
            }];
            name = "binary";
            request = "launch";
          }
          {
            args = {
              mode = "test";
              program = "{0}";
            };
            completion = [{
              completion = "directory";
              default = ".";
              name = "tests";
            }];
            name = "test";
            request = "launch";
          }
          {
            args = {
              mode = "local";
              processId = "{0}";
            };
            completion = [ "pid" ];
            name = "attach";
            request = "attach";
          }];
        transport = "tcp";
      };
      file-types = [ "go" ];
      indent = {
        tab-width = 4;
        unit = "\t";
      };
      injection-regex = "go";
      language-server = {
        command = "gopls";
      };
      name = "go";
      roots = [ "Gopkg.toml" "go.mod" ];
      scope = "source.go";
    }
    {
      auto-format = true;
      comment-token = "//";
      file-types = [ "go.mod" ];
      indent = {
        tab-width = 4;
        unit = "\t";
      };
      injection-regex = "gomod";
      language-server = {
        command = "gopls";
      };
      name = "gomod";
      roots = [ ];
      scope = "source.gomod";
    }
    {
      comment-token = "//";
      file-types = [ "gotmpl" ];
      indent = {
        tab-width = 2;
        unit = " ";
      };
      injection-regex = "gotmpl";
      language-server = {
        command = "gopls";
      };
      name = "gotmpl";
      roots = [ ];
      scope = "source.gotmpl";
    }
    {
      auto-format = true;
      comment-token = "//";
      file-types = [ "go.work" ];
      indent = {
        tab-width = 4;
        unit = "\t";
      };
      injection-regex = "gowork";
      language-server = {
        command = "gopls";
      };
      name = "gowork";
      roots = [ ];
      scope = "source.gowork";
    }
    {
      comment-token = "//";
      debugger = {
        name = "node-debug2";
        quirks = {
          absolute-paths = true;
        };
        templates = [{
          args = {
            program = "{0}";
          };
          completion = [{
            completion = "filename";
            default = "index.js";
            name = "main";
          }];
          name = "source";
          request = "launch";
        }];
        transport = "stdio";
      };
      file-types = [ "js" "jsx" "mjs" "cjs" ];
      indent = {
        tab-width = 2;
        unit = "  ";
      };
      injection-regex = "^(js|javascript)$";
      language-server = {
        args = [ "--stdio" ];
        command = "typescript-language-server";
        language-id = "javascript";
      };
      name = "javascript";
      roots = [ ];
      scope = "source.js";
      shebangs = [ "node" ];
    }
    {
      comment-token = "//";
      file-types = [ "jsx" ];
      grammar = "javascript";
      indent = {
        tab-width = 2;
        unit = "  ";
      };
      injection-regex = "jsx";
      language-server = {
        args = [ "--stdio" ];
        command = "typescript-language-server";
        language-id = "javascript";
      };
      name = "jsx";
      roots = [ ];
      scope = "source.jsx";
    }
    {
      file-types = [ "ts" ];
      indent = {
        tab-width = 2;
        unit = "  ";
      };
      injection-regex = "^(ts|typescript)$";
      language-server = {
        args = [ "--stdio" ];
        command = "typescript-language-server";
        language-id = "typescript";
      };
      name = "typescript";
      roots = [ ];
      scope = "source.ts";
      shebangs = [ ];
    }
    {
      file-types = [ "tsx" ];
      indent = {
        tab-width = 2;
        unit = "  ";
      };
      injection-regex = "^(tsx)$";
      language-server = {
        args = [ "--stdio" ];
        command = "typescript-language-server";
        language-id = "typescriptreact";
      };
      name = "tsx";
      roots = [ ];
      scope = "source.tsx";
    }
    {
      file-types = [ "css" "scss" ];
      indent = {
        tab-width = 2;
        unit = "  ";
      };
      injection-regex = "css";
      language-server = {
        args = [ "--stdio" ];
        command = "vscode-css-language-server";
      };
      name = "css";
      roots = [ ];
      scope = "source.css";
    }
    {
      file-types = [ "scss" ];
      indent = {
        tab-width = 2;
        unit = "  ";
      };
      injection-regex = "scss";
      language-server = {
        args = [ "--stdio" ];
        command = "vscode-css-language-server";
      };
      name = "scss";
      roots = [ ];
      scope = "source.scss";
    }
    {
      auto-format = true;
      config = {
        provideFormatter = true;
      };
      file-types = [ "html" ];
      indent = {
        tab-width = 2;
        unit = "  ";
      };
      injection-regex = "html";
      language-server = {
        args = [ "--stdio" ];
        command = "vscode-html-language-server";
      };
      name = "html";
      roots = [ ];
      scope = "text.html.basic";
    }
    {
      comment-token = "#";
      file-types = [ "py" ];
      formatter = {
        args = [ "-" ];
        command = black;
      };
      indent = {
        tab-width = 4;
        unit = "    ";
      };
      injection-regex = "python";
      language-server = {
        command = "pylsp";
      };
      name = "python";
      roots = [ ];
      scope = "source.python";
      shebangs = [ "python" ];
    }
    {
      comment-token = "#";
      file-types = [ "nix" ];
      formatter = {
        command = nixpkgs-fmt;
      };
      indent = {
        tab-width = 2;
        unit = "  ";
      };
      injection-regex = "nix";
      language-server = {
        command = nil;
      };
      name = "nix";
      roots = [ "flake.nix" ];
      scope = "source.nix";
      shebangs = [ ];
    }
    {
      comment-token = "#";
      file-types = [ "sh" "bash" "zsh" ".bash_login" ".bash_logout" ".bash_profile" ".bashrc" ".profile" ".zshenv" ".zlogin" ".zlogout" ".zprofile" ".zshrc" "APKBUILD" "PKGBUILD" "eclass" "ebuild" "bazelrc" ];
      formatter = {
        command = shfmt;
      };
      indent = {
        tab-width = 2;
        unit = "  ";
      };
      injection-regex = "(shell|bash|zsh|sh)";
      language-server = {
        args = [ "start" ];
        command = "";
      };
      name = "bash";
      roots = [ ];
      scope = "source.bash";
      shebangs = [ "sh" "bash" "dash" ];
    }
    {
      comment-token = "%";
      file-types = [ "tex" ];
      indent = {
        tab-width = 4;
        unit = "\t";
      };
      injection-regex = "tex";
      language-server = {
        command = "texlab";
      };
      name = "latex";
      roots = [ ];
      scope = "source.tex";
    }
    {
      comment-token = "--";
      file-types = [ "lean" ];
      indent = {
        tab-width = 2;
        unit = "  ";
      };
      injection-regex = "lean";
      language-server = {
        args = [ "--server" ];
        command = "lean";
      };
      name = "lean";
      roots = [ "lakefile.lean" ];
      scope = "source.lean";
    }
    {
      comment-token = "#";
      file-types = [ "jl" ];
      indent = {
        tab-width = 4;
        unit = "    ";
      };
      injection-regex = "julia";
      language-server = {
        args = [
          "--startup-file=no"
          "--history-file=no"
          "--quiet"
          "-e"
          "using LanguageServer;
     runserver()"
        ];
        command = "julia";
      };
      name = "julia";
      roots = [ ];
      scope = "source.julia";
    }
    {
      file-types = [ "java" ];
      indent = {
        tab-width = 4;
        unit = "    ";
      };
      injection-regex = "java";
      language-server = {
        command = "jdtls";
      };
      name = "java";
      roots = [ "pom.xml" ];
      scope = "source.java";
    }
    {
      comment-token = "--";
      file-types = [ "lua" ];
      indent = {
        tab-width = 2;
        unit = "  ";
      };
      language-server = {
        args = [ ];
        command = "lua-language-server";
      };
      name = "lua";
      roots = [ ".luarc.json" ".luacheckrc" ".stylua.toml" "selene.toml" ".git" ];
      scope = "source.lua";
      shebangs = [ "lua" ];
    }
    {
      file-types = [ "vue" ];
      indent = {
        tab-width = 2;
        unit = "  ";
      };
      injection-regex = "vue";
      language-server = {
        command = "vls";
      };
      name = "vue";
      roots = [ "package.json" "vue.config.js" ];
      scope = "source.vue";
    }
    {
      comment-token = "#";
      file-types = [ "yml" "yaml" ];
      indent = {
        tab-width = 2;
        unit = "  ";
      };
      injection-regex = "yml|yaml";
      language-server = {
        args = [ "--stdio" ];
        command = "yaml-language-server";
      };
      name = "yaml";
      roots = [ ];
      scope = "source.yaml";
    }
    {
      comment-token = "--";
      file-types = [ "hs" ];
      indent = {
        tab-width = 2;
        unit = "  ";
      };
      injection-regex = "haskell";
      language-server = {
        args = [ "--lsp" ];
        command = "haskell-language-server-wrapper";
      };
      name = "haskell";
      roots = [ "Setup.hs" "stack.yaml" "*.cabal" ];
      scope = "source.haskell";
    }
    {
      auto-format = true;
      comment-token = "//";
      file-types = [ "zig" ];
      formatter = {
        args = [ "fmt" "--stdin" ];
        command = "zig";
      };
      indent = {
        tab-width = 4;
        unit = "    ";
      };
      injection-regex = "zig";
      language-server = {
        command = "zls";
      };
      name = "zig";
      roots = [ "build.zig" ];
      scope = "source.zig";
    }
    {
      comment-token = "#";
      file-types = [ "cmake" "CMakeLists.txt" ];
      indent = {
        tab-width = 2;
        unit = "  ";
      };
      injection-regex = "cmake";
      language-server = {
        command = "cmake-language-server";
      };
      name = "cmake";
      roots = [ ];
      scope = "source.cmake";
    }
    {
      comment-token = "#";
      file-types = [ "Makefile" "makefile" "mk" "justfile" ".justfile" ];
      indent = {
        tab-width = 4;
        unit = "\t";
      };
      injection-regex = "(make|makefile|Makefile|mk|just)";
      name = "make";
      roots = [ ];
      scope = "source.make";
    }
    {
      comment-token = "//";
      file-types = [ "glsl" "vert" "tesc" "tese" "geom" "frag" "comp" ];
      indent = {
        tab-width = 4;
        unit = "    ";
      };
      injection-regex = "glsl";
      name = "glsl";
      roots = [ ];
      scope = "source.glsl";
    }
    {
      file-types = [ "md" ];
      indent = {
        tab-width = 2;
        unit = "  ";
      };
      injection-regex = "md|markdown";
      name = "markdown";
      roots = [ ];
      scope = "source.md";
    }
    {
      file-types = [ ];
      grammar = "markdown_inline";
      injection-regex = "markdown\\.inline";
      name = "markdown.inline";
      roots = [ ];
      scope = "source.markdown.inline";
    }
    {
      auto-format = true;
      comment-token = "//";
      file-types = [ "dart" ];
      indent = {
        tab-width = 2;
        unit = "  ";
      };
      language-server = {
        args = [ "language-server" "--client-id=helix" ];
        command = "dart";
      };
      name = "dart";
      roots = [ "pubspec.yaml" ];
      scope = "source.dart";
    }
    {
      comment-token = "#";
      file-types = [ "COMMIT_EDITMSG" ];
      indent = {
        tab-width = 2;
        unit = "  ";
      };
      name = "git-commit";
      roots = [ ];
      scope = "git.commitmsg";
    }
    {
      comment-token = "#";
      file-types = [ "diff" ];
      indent = {
        tab-width = 2;
        unit = "  ";
      };
      injection-regex = "diff";
      name = "git-diff";
      roots = [ ];
      scope = "source.diff";
    }
    {
      comment-token = "#";
      file-types = [ "git-rebase-todo" ];
      indent = {
        tab-width = 2;
        unit = " ";
      };
      injection-regex = "git-rebase";
      name = "git-rebase";
      roots = [ ];
      scope = "source.gitrebase";
    }
    {
      file-types = [ "regex" ];
      injection-regex = "regex";
      name = "regex";
      roots = [ ];
      scope = "source.regex";
    }
    {
      comment-token = "#";
      file-types = [ ".gitmodules" ".gitconfig" ];
      indent = {
        tab-width = 4;
        unit = "\t";
      };
      injection-regex = "git-config";
      name = "git-config";
      roots = [ ];
      scope = "source.gitconfig";
    }
    {
      comment-token = "#";
      file-types = [ ".gitattributes" ];
      grammar = "gitattributes";
      injection-regex = "git-attributes";
      name = "git-attributes";
      roots = [ ];
      scope = "source.gitattributes";
    }
    {
      comment-token = "#";
      file-types = [ ".gitignore" ".gitignore_global" ];
      grammar = "gitignore";
      injection-regex = "git-ignore";
      name = "git-ignore";
      roots = [ ];
      scope = "source.gitignore";
    }
    {
      auto-format = true;
      comment-token = "--";
      file-types = [ "elm" ];
      indent = {
        tab-width = 4;
        unit = "    ";
      };
      injection-regex = "elm";
      language-server = {
        command = "elm-language-server";
      };
      name = "elm";
      roots = [ "elm.json" ];
      scope = "source.elm";
    }

    {
      auto-pairs = {
        "\"" = "\"";
        "'" = "'";
        "(" = ")";
        "[" = "]";
        "`" = "'";
        "{" = "}";
      };
      comment-token = "%%";
      file-types = [ "erl" "hrl" "app" "rebar.config" "rebar.lock" ];
      indent = {
        tab-width = 4;
        unit = "    ";
      };
      injection-regex = "erl(ang)?";
      language-server = {
        command = "erlang_ls";
      };
      name = "erlang";
      roots = [ "rebar.config" ];
      scope = "source.erlang";
    }
    {
      comment-token = "//";
      file-types = [ "kt" "kts" ];
      indent = {
        tab-width = 4;
        unit = "    ";
      };
      language-server = {
        command = "kotlin-language-server";
      };
      name = "kotlin";
      roots = [ "settings.gradle" "settings.gradle.kts" ];
      scope = "source.kotlin";
    }
    {
      auto-format = true;
      comment-token = "#";
      file-types = [ "hcl" "tf" "nomad" ];
      indent = {
        tab-width = 2;
        unit = "  ";
      };
      injection-regex = "(hcl|tf|nomad)";
      language-server = {
        args = [ "serve" ];
        command = "terraform-ls";
        language-id = "terraform";
      };
      name = "hcl";
      roots = [ ];
      scope = "source.hcl";
    }
    {
      auto-format = true;
      comment-token = "#";
      file-types = [ "tfvars" ];
      grammar = "hcl";
      indent = {
        tab-width = 2;
        unit = "  ";
      };
      language-server = {
        args = [ "serve" ];
        command = "terraform-ls";
        language-id = "terraform-vars";
      };
      name = "tfvars";
      roots = [ ];
      scope = "source.tfvars";
    }
    {
      file-types = [ "org" ];
      indent = {
        tab-width = 2;
        unit = "  ";
      };
      injection-regex = "org";
      name = "org";
      roots = [ ];
      scope = "source.org";
    }
    {
      comment-token = "//";
      file-types = [ "ron" ];
      grammar = "rust";
      indent = {
        tab-width = 4;
        unit = "    ";
      };
      injection-regex = "ron";
      name = "ron";
      roots = [ ];
      scope = "source.ron";
    }
    {
      comment-token = "#";
      file-types = [ "r" "R" ];
      indent = {
        tab-width = 2;
        unit = "  ";
      };
      injection-regex = "(r|R)";
      language-server = {
        args = [ "--slave" "-e" "languageserver::run()" ];
        command = "R";
      };
      name = "r";
      roots = [ ];
      scope = "source.r";
      shebangs = [ "r" "R" ];
    }
    {
      file-types = [ "rmd" "Rmd" ];
      grammar = "markdown";
      indent = {
        tab-width = 2;
        unit = "  ";
      };
      injection-regex = "(r|R)md";
      language-server = {
        args = [ "--slave" "-e" "languageserver::run()" ];
        command = "R";
      };
      name = "rmarkdown";
      roots = [ ];
      scope = "source.rmd";
    }
    {
      auto-format = true;
      comment-token = "//";
      file-types = [ "swift" ];
      injection-regex = "swift";
      language-server = {
        command = "sourcekit-lsp";
      };
      name = "swift";
      roots = [ "Package.swift" ];
      scope = "source.swift";
    }
    {
      comment-token = "--";
      file-types = [ "sql" ];
      indent = {
        tab-width = 4;
        unit = "    ";
      };
      injection-regex = "sql";
      name = "sql";
      roots = [ ];
      scope = "source.sql";
    }
    {
      auto-format = true;
      comment-token = "#";
      file-types = [ "gd" ];
      indent = {
        tab-width = 4;
        unit = "    ";
      };
      injection-regex = "gdscript";
      name = "gdscript";
      roots = [ "project.godot" ];
      scope = "source.gdscript";
      shebangs = [ ];
    }
    {
      comment-token = "#";
      file-types = [ "nu" ];
      indent = {
        tab-width = 2;
        unit = "  ";
      };
      injection-regex = "nu";
      name = "nu";
      roots = [ ];
      scope = "source.nu";
    }
    {
      comment-token = "#";
      file-types = [ "meson.build" ];
      indent = {
        tab-width = 2;
        unit = "  ";
      };
      injection-regex = "meson";
      name = "meson";
      roots = [ ];
      scope = "source.meson";
    }
    {
      file-types = [ ".ssh/config" "/etc/ssh/ssh_config" ];
      name = "sshclientconfig";
      roots = [ ];
      scope = "source.sshclientconfig";
    }
    {
      comment-token = ";
        ";
      file-types = [ "ss" "rkt" ];
      indent = {
        tab-width = 2;
        unit = "  ";
      };
      injection-regex = "scheme";
      name = "scheme";
      roots = [ ];
      scope = "source.scheme";
    }
    {
      auto-format = true;
      comment-token = "//";
      file-types = [ "v" "vv" ];
      indent = {
        tab-width = 4;
        unit = "\t";
      };
      language-server = {
        args = [ ];
        command = "vls";
      };
      name = "v";
      roots = [ "v.mod" ];
      scope = "source.v";
      shebangs = [ "v run" ];
    }
    {
      comment-token = "//";
      file-types = [ "v" "vh" "sv" "svh" ];
      indent = {
        tab-width = 2;
        unit = "  ";
      };
      injection-regex = "verilog";
      language-server = {
        args = [ ];
        command = "svlangserver";
      };
      name = "verilog";
      roots = [ ];
      scope = "source.verilog";
    }
  ];

}
