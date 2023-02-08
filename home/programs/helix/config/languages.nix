# Language support configuration.
# See the languages documentation: https://docs.helix-editor.com/master/languages.html
{ pkgs, ... }:
let
  configText = ''

[[language]]
name = "rust"
scope = "source.rust"
injection-regex = "rust"
file-types = ["rs"]
roots = ["Cargo.toml", "Cargo.lock"]
auto-format = true
comment-token = "//"
language-server = { command = "rust-analyzer" }
indent = { tab-width = 4, unit = "    " }
formatter = { command = "${pkgs.rustfmt}/bin/rustfmt" }

[language.auto-pairs]
'(' = ')'
'{' = '}'
'[' = ']'
'"' = '"'
'`' = '`'

[language.debugger]
name = "lldb-vscode"
transport = "stdio"
command = "lldb-vscode"

[[language.debugger.templates]]
name = "binary"
request = "launch"
completion = [ { name = "binary", completion = "filename" } ]
args = { program = "{0}" }

[[language.debugger.templates]]
name = "binary (terminal)"
request = "launch"
completion = [ { name = "binary", completion = "filename" } ]
args = { program = "{0}", runInTerminal = true }

[[language.debugger.templates]]
name = "attach"
request = "attach"
completion = [ "pid" ]
args = { pid = "{0}" }

[[language.debugger.templates]]
name = "gdbserver attach"
request = "attach"
completion = [ { name = "lldb connect url", default = "connect://localhost:3333" }, { name = "file", completion = "filename" }, "pid" ]
args = { attachCommands = [ "platform select remote-gdb-server", "platform connect {0}", "file {1}", "attach {2}" ] }

[[grammar]]
name = "rust"
source = { git = "https://github.com/tree-sitter/tree-sitter-rust", rev = "41e23b454f503e6fe63ec4b6d9f7f2cf7788ab8e" }

[[language]]
name = "toml"
scope = "source.toml"
injection-regex = "toml"
file-types = ["toml"]
roots = []
comment-token = "#"
language-server = { command = "${pkgs.taplo}", args = ["lsp", "stdio"] }
formatter = {command = "taplo", args = ["fmt","--stdin"]}
indent = { tab-width = 2, unit = "  " }

[[grammar]]
name = "toml"
source = { git = "https://github.com/ikatyang/tree-sitter-toml", rev = "7cff70bbcbbc62001b465603ca1ea88edd668704" }

[[language]]
name = "awk"
scope = "source.awk"
injection-regex = "awk"
file-types = ["awk", "gawk", "nawk", "mawk"]
roots = []
comment-token = "#"
language-server = { command = "awk-language-server" }
indent = { tab-width = 2, unit = "  " }

[[grammar]]
name = "awk"
source = { git = "https://github.com/Beaglefoot/tree-sitter-awk", rev = "a799bc5da7c2a84bc9a06ba5f3540cf1191e4ee3" }

[[language]]
name = "protobuf"
scope = "source.proto"
injection-regex = "protobuf"
file-types = ["proto"]
roots = []
comment-token = "//"
indent = { tab-width = 2, unit = "  " }

[[grammar]]
name = "protobuf"
source = { git = "https://github.com/yusdacra/tree-sitter-protobuf", rev = "19c211a01434d9f03efff99f85e19f967591b175"}

[[language]]
name = "elixir"
scope = "source.elixir"
injection-regex = "(elixir|ex)"
file-types = ["ex", "exs", "mix.lock"]
shebangs = ["elixir"]
roots = []
comment-token = "#"
language-server = { command = "elixir-ls" }
config = { elixirLS.dialyzerEnabled = false }
indent = { tab-width = 2, unit = "  " }

[[grammar]]
name = "elixir"
source = { git = "https://github.com/elixir-lang/tree-sitter-elixir", rev = "1dabc1c790e07115175057863808085ea60dd08a"  }

[[language]]
name = "fish"
scope = "source.fish"
injection-regex = "fish"
file-types = ["fish"]
shebangs = ["fish"]
roots = []
comment-token = "#"
indent = { tab-width = 4, unit = "    " }

[[grammar]]
name = "fish"
source = { git = "https://github.com/ram02z/tree-sitter-fish", rev = "04e54ab6585dfd4fee6ddfe5849af56f101b6d4f" }

[[language]]
name = "mint"
scope = "source.mint"
injection-regex = "mint"
file-types = ["mint"]
shebangs = []
roots = []
comment-token = "//"
language-server = { command = "mint", args = ["ls"] }
indent = { tab-width = 2, unit = "  " }

[[language]]
name = "json"
scope = "source.json"
injection-regex = "json"
file-types = ["json"]
roots = []
language-server = { command = "vscode-json-language-server", args = ["--stdio"] }
auto-format = false
config = { "provideFormatter" = true }
indent = { tab-width = 2, unit = "  " }
formatter = {command = "prettier", args = ["--parser","json"]}

[[grammar]]
name = "json"
source = { git = "https://github.com/tree-sitter/tree-sitter-json", rev = "65bceef69c3b0f24c0b19ce67d79f57c96e90fcb" }

[[language]]
name = "c"
scope = "source.c"
injection-regex = "c"
file-types = ["c"] # TODO: ["h"]
roots = []
comment-token = "//"
language-server = { command = "clangd" }
indent = { tab-width = 8, unit = "        " }
formatter = { command = "clang-format" , args = [ "-style=file:${import ./clang-format.nix {inherit pkgs;}}"] }

[language.debugger]
name = "lldb-vscode"
transport = "stdio"
command = "lldb-vscode"

[[language.debugger.templates]]
name = "binary"
request = "launch"
completion = [ { name = "binary", completion = "filename" } ]
args = { console = "internalConsole", program = "{0}" }

[[language.debugger.templates]]
name = "attach"
request = "attach"
completion = [ "pid" ]
args = { console = "internalConsole", pid = "{0}" }

[[language.debugger.templates]]
name = "gdbserver attach"
request = "attach"
completion = [ { name = "lldb connect url", default = "connect://localhost:3333" }, { name = "file", completion = "filename" }, "pid" ]
args = { console = "internalConsole", attachCommands = [ "platform select remote-gdb-server", "platform connect {0}", "file {1}", "attach {2}" ] }

[[grammar]]
name = "c"
source = { git = "https://github.com/tree-sitter/tree-sitter-c", rev = "f05e279aedde06a25801c3f2b2cc8ac17fac52ae" }

[[language]]
name = "cpp"
scope = "source.cpp"
injection-regex = "cpp"
file-types = ["cc", "hh", "cpp", "hpp", "h", "ipp", "tpp", "cxx", "hxx", "ixx", "txx", "ino"]
roots = []
comment-token = "//"
language-server = { command = "clangd" }
indent = { tab-width = 8, unit = "        " }
formatter = { command = "clang-format" , args = [ "-style=file:${import ./clang-format.nix {inherit pkgs;}}"] }

[language.debugger]
name = "lldb-vscode"
transport = "stdio"
command = "lldb-vscode"

[[language.debugger.templates]]
name = "binary"
request = "launch"
completion = [ { name = "binary", completion = "filename" } ]
args = { console = "internalConsole", program = "{0}" }

[[language.debugger.templates]]
name = "attach"
request = "attach"
completion = [ "pid" ]
args = { console = "internalConsole", pid = "{0}" }

[[language.debugger.templates]]
name = "gdbserver attach"
request = "attach"
completion = [ { name = "lldb connect url", default = "connect://localhost:3333" }, { name = "file", completion = "filename" }, "pid" ]
args = { console = "internalConsole", attachCommands = [ "platform select remote-gdb-server", "platform connect {0}", "file {1}", "attach {2}" ] }

[[grammar]]
name = "cpp"
source = { git = "https://github.com/tree-sitter/tree-sitter-cpp", rev = "e8dcc9d2b404c542fd236ea5f7208f90be8a6e89" }
indent = { tab-width = 4, unit = "\t" }

[[language]]
name = "c-sharp"
scope = "source.csharp"
injection-regex = "c-?sharp"
file-types = ["cs"]
roots = ["sln", "csproj"]
comment-token = "//"
indent = { tab-width = 4, unit = "\t" }
language-server = { command = "OmniSharp", args = [ "--languageserver" ] }

[[grammar]]
name = "c-sharp"
source = { git = "https://github.com/tree-sitter/tree-sitter-c-sharp", rev = "9c494a503c8e2044bfffce57f70b480c01a82f03" }

[[language]]
name = "go"
scope = "source.go"
injection-regex = "go"
file-types = ["go"]
roots = ["Gopkg.toml", "go.mod"]
auto-format = true
comment-token = "//"
language-server = { command = "gopls" }
# TODO: gopls needs utf-8 offsets?
indent = { tab-width = 4, unit = "\t" }

[language.debugger]
name = "go"
transport = "tcp"
command = "dlv"
args = ["dap"]
port-arg = "-l 127.0.0.1:{}"

[[language.debugger.templates]]
name = "source"
request = "launch"
completion = [ { name = "entrypoint", completion = "filename", default = "." } ]
args = { mode = "debug", program = "{0}" }

[[language.debugger.templates]]
name = "binary"
request = "launch"
completion = [ { name = "binary", completion = "filename" } ]
args = { mode = "exec", program = "{0}" }

[[language.debugger.templates]]
name = "test"
request = "launch"
completion = [ { name = "tests", completion = "directory", default = "." } ]
args = { mode = "test", program = "{0}" }

[[language.debugger.templates]]
name = "attach"
request = "attach"
completion = [ "pid" ]
args = { mode = "local", processId = "{0}" }

[[grammar]]
name = "go"
source = { git = "https://github.com/tree-sitter/tree-sitter-go", rev = "0fa917a7022d1cd2e9b779a6a8fc5dc7fad69c75" }

[[language]]
name = "gomod"
scope = "source.gomod"
injection-regex = "gomod"
file-types = ["go.mod"]
roots = []
auto-format = true
comment-token = "//"
language-server = { command = "gopls" }
indent = { tab-width = 4, unit = "\t" }

[[grammar]]
name = "gomod"
source = { git = "https://github.com/camdencheek/tree-sitter-go-mod", rev = "e8f51f8e4363a3d9a427e8f63f4c1bbc5ef5d8d0" }

[[language]]
name = "gotmpl"
scope = "source.gotmpl"
injection-regex = "gotmpl"
file-types = ["gotmpl"]
roots = []
comment-token = "//"
language-server = { command = "gopls" }
indent = { tab-width = 2, unit = " " }

[[grammar]]
name = "gotmpl"
source = { git = "https://github.com/dannylongeuay/tree-sitter-go-template", rev = "395a33e08e69f4155156f0b90138a6c86764c979" }

[[language]]
name = "gowork"
scope = "source.gowork"
injection-regex = "gowork"
file-types = ["go.work"]
roots = []
auto-format = true
comment-token = "//"
language-server = { command = "gopls" }
indent = { tab-width = 4, unit = "\t" }

[[grammar]]
name = "gowork"
source = { git = "https://github.com/omertuc/tree-sitter-go-work", rev = "6dd9dd79fb51e9f2abc829d5e97b15015b6a8ae2" }

[[language]]
name = "javascript"
scope = "source.js"
injection-regex = "^(js|javascript)$"
file-types = ["js", "jsx", "mjs", "cjs"]
shebangs = ["node"]
roots = []
comment-token = "//"
# TODO: highlights-params
language-server = { command = "typescript-language-server", args = ["--stdio"], language-id = "javascript" }
indent = { tab-width = 2, unit = "  " }

[language.debugger]
name = "node-debug2"
transport = "stdio"
# args consisting of cmd (node) and path to adapter should be added to user's configuration
quirks = { absolute-paths = true }

[[language.debugger.templates]]
name = "source"
request = "launch"
completion = [ { name = "main", completion = "filename", default = "index.js" } ]
args = { program = "{0}" }

[[grammar]]
name = "javascript"
source = { git = "https://github.com/tree-sitter/tree-sitter-javascript", rev = "4a95461c4761c624f2263725aca79eeaefd36cad" }

[[language]]
name = "jsx"
scope = "source.jsx"
injection-regex = "jsx"
file-types = ["jsx"]
roots = []
comment-token = "//"
language-server = { command = "typescript-language-server", args = ["--stdio"], language-id = "javascript" }
indent = { tab-width = 2, unit = "  " }
grammar = "javascript"

[[language]]
name = "typescript"
scope = "source.ts"
injection-regex = "^(ts|typescript)$"
file-types = ["ts"]
shebangs = []
roots = []
# TODO: highlights-params
language-server = { command = "typescript-language-server", args = ["--stdio"], language-id = "typescript"}
indent = { tab-width = 2, unit = "  " }

[[grammar]]
name = "typescript"
source = { git = "https://github.com/tree-sitter/tree-sitter-typescript", rev = "3e897ea5925f037cfae2e551f8e6b12eec2a201a", subpath = "typescript" }

[[language]]
name = "tsx"
scope = "source.tsx"
injection-regex = "^(tsx)$" # |typescript
file-types = ["tsx"]
roots = []
# TODO: highlights-params
language-server = { command = "typescript-language-server", args = ["--stdio"], language-id = "typescriptreact" }
indent = { tab-width = 2, unit = "  " }

[[grammar]]
name = "tsx"
source = { git = "https://github.com/tree-sitter/tree-sitter-typescript", rev = "3e897ea5925f037cfae2e551f8e6b12eec2a201a", subpath = "tsx" }

[[language]]
name = "css"
scope = "source.css"
injection-regex = "css"
file-types = ["css", "scss"]
roots = []
language-server = { command = "vscode-css-language-server", args = ["--stdio"] }
indent = { tab-width = 2, unit = "  " }

[[grammar]]
name = "css"
source = { git = "https://github.com/tree-sitter/tree-sitter-css", rev = "94e10230939e702b4fa3fa2cb5c3bc7173b95d07" }

[[language]]
name = "scss"
scope = "source.scss"
injection-regex = "scss"
file-types = ["scss"]
roots = []
language-server = { command = "vscode-css-language-server", args = ["--stdio"] }
indent = { tab-width = 2, unit = "  " }

[[grammar]]
name = "scss"
source = { git = "https://github.com/serenadeai/tree-sitter-scss", rev = "c478c6868648eff49eb04a4df90d703dc45b312a" }

[[language]]
name = "html"
scope = "text.html.basic"
injection-regex = "html"
file-types = ["html"]
roots = []
language-server = { command = "vscode-html-language-server", args = ["--stdio"] }
auto-format = true
config = { "provideFormatter" = true }
indent = { tab-width = 2, unit = "  " }

[[grammar]]
name = "html"
source = { git = "https://github.com/tree-sitter/tree-sitter-html", rev = "d93af487cc75120c89257195e6be46c999c6ba18" }

[[language]]
name = "python"
scope = "source.python"
injection-regex = "python"
file-types = ["py"]
shebangs = ["python"]
roots = []
comment-token = "#"
language-server = { command = "pylsp" }
# TODO: pyls needs utf-8 offsets
indent = { tab-width = 4, unit = "    " }

[[grammar]]
name = "python"
source = { git = "https://github.com/tree-sitter/tree-sitter-python", rev = "de221eccf9a221f5b85474a553474a69b4b5784d" }

[[language]]
name = "nickel"
scope = "source.nickel"
injection-regex = "nickel"
file-types = ["ncl"]
shebangs = []
roots = []
comment-token = "#"
language-server = { command = "nls" }
indent = { tab-width = 2, unit = "  " }

[[grammar]]
name = "nickel"
source = { git = "https://github.com/nickel-lang/tree-sitter-nickel", rev = "9d83db400b6c11260b9106f131f93ddda8131933" }

[[language]]
name = "nix"
scope = "source.nix"
injection-regex = "nix"
file-types = ["nix"]
shebangs = []
roots = ["flake.nix"]
comment-token = "#"
language-server = { command = "${pkgs.nil}/bin/nil" }
indent = { tab-width = 2, unit = "  " }
formatter = { command = "nixpkgs-fmt" }


[[grammar]]
name = "nix"
source = { git = "https://github.com/cstrahan/tree-sitter-nix", rev = "1b69cf1fa92366eefbe6863c184e5d2ece5f187d" }

[[language]]
name = "ruby"
scope = "source.ruby"
injection-regex = "ruby"
file-types = ["rb", "rake", "rakefile", "irb", "gemfile", "gemspec", "Rakefile", "Gemfile", "rabl", "jbuilder", "jb"]
shebangs = ["ruby"]
roots = [ ]
comment-token = "#"
language-server = { command = "solargraph", args = ["stdio"] }
indent = { tab-width = 2, unit = "  " }

[[grammar]]
name = "ruby"
source = { git = "https://github.com/tree-sitter/tree-sitter-ruby", rev = "4c600a463d97e36a0ca5ac57e11f3ac8c297a0fa" }

[[language]]
name = "bash"
scope = "source.bash"
injection-regex = "(shell|bash|zsh|sh)"
file-types = ["sh", "bash", "zsh", ".bash_login", ".bash_logout", ".bash_profile", ".bashrc", ".profile", ".zshenv", ".zlogin", ".zlogout", ".zprofile", ".zshrc", "APKBUILD", "PKGBUILD", "eclass", "ebuild", "bazelrc"]
shebangs = ["sh", "bash", "dash"]
roots = []
comment-token = "#"
language-server = { command = "bash-language-server", args = ["start"] }
indent = { tab-width = 2, unit = "  " }

[[grammar]]
name = "bash"
source = { git = "https://github.com/tree-sitter/tree-sitter-bash", rev = "275effdfc0edce774acf7d481f9ea195c6c403cd" }

[[language]]
name = "php"
scope = "source.php"
injection-regex = "php"
file-types = ["php", "inc"]
shebangs = ["php"]
roots = ["composer.json", "index.php"]
language-server = { command = "intelephense", args = ["--stdio"] }
indent = { tab-width = 4, unit = "    " }

[[grammar]]
name = "php"
source = { git = "https://github.com/tree-sitter/tree-sitter-php", rev = "57f855461aeeca73bd4218754fb26b5ac143f98f" }

[[language]]
name = "twig"
scope = "source.twig"
injection-regex = "twig"
file-types = ["twig"]
roots = []
indent = { tab-width = 2, unit = "  " }

[[grammar]]
name = "twig"
source = { git = "https://github.com/eirabben/tree-sitter-twig", rev = "b7444181fb38e603e25ea8fcdac55f9492e49c27" }

[[language]]
name = "latex"
scope = "source.tex"
injection-regex = "tex"
file-types = ["tex"]
roots = []
comment-token = "%"
language-server = { command = "texlab" }
indent = { tab-width = 4, unit = "\t" }

[[grammar]]
name = "latex"
source = { git = "https://github.com/latex-lsp/tree-sitter-latex", rev = "b3b2cf27f33e71438ebe46934900b1153901c6f2" }

[[language]]
name = "lean"
scope = "source.lean"
injection-regex = "lean"
file-types = ["lean"]
roots = [ "lakefile.lean" ]
comment-token = "--"
language-server = { command = "lean", args = [ "--server" ] }
indent = { tab-width = 2, unit = "  " }

[[grammar]]
name = "lean"
source = { git = "https://github.com/Julian/tree-sitter-lean", rev = "d98426109258b266e1e92358c5f11716d2e8f638" }

[[language]]
name = "julia"
scope = "source.julia"
injection-regex = "julia"
file-types = ["jl"]
roots = []
comment-token = "#"
language-server = { command = "julia", args = [
    "--startup-file=no",
    "--history-file=no",
    "--quiet",
    "-e",
    "using LanguageServer; runserver()",
    ] }
indent = { tab-width = 4, unit = "    " }

[[grammar]]
name = "julia"
source = { git = "https://github.com/tree-sitter/tree-sitter-julia", rev = "fc60b7cce87da7a1b7f8cb0f9371c3dc8b684500" }

[[language]]
name = "java"
scope = "source.java"
injection-regex = "java"
file-types = ["java"]
roots = ["pom.xml"]
language-server = { command = "jdtls" }
indent = { tab-width = 4, unit = "    " }

[[grammar]]
name = "java"
source = { git = "https://github.com/tree-sitter/tree-sitter-java", rev = "bd6186c24d5eb13b4623efac9d944dcc095c0dad" }

[[language]]
name = "ledger"
scope = "source.ledger"
injection-regex = "ledger"
file-types = ["ldg", "ledger", "journal"]
roots = []
comment-token = ";"
indent = { tab-width = 4, unit = "    " }

[[grammar]]
name = "ledger"
source = { git = "https://github.com/cbarrete/tree-sitter-ledger", rev = "1f864fb2bf6a87fe1b48545cc6adc6d23090adf7" }

[[language]]
name = "beancount"
scope = "source.beancount"
injection-regex = "beancount"
file-types = ["beancount", "bean"]
roots = []
comment-token = ";"
indent = { tab-width = 2, unit = "  " }

[[grammar]]
name = "beancount"
source = { git = "https://github.com/polarmutex/tree-sitter-beancount", rev = "4cbd1f09cd07c1f1fabf867c2cf354f9da53cc4c" }

[[language]]
name = "ocaml"
scope = "source.ocaml"
injection-regex = "ocaml"
file-types = ["ml"]
shebangs = []
roots = []
comment-token = "(**)"
language-server = { command = "ocamllsp" }
indent = { tab-width = 2, unit = "  " }

[[grammar]]
name = "ocaml"
source = { git = "https://github.com/tree-sitter/tree-sitter-ocaml", rev = "23d419ba45789c5a47d31448061557716b02750a", subpath = "ocaml" }

[[language]]
name = "ocaml-interface"
scope = "source.ocaml.interface"
file-types = ["mli"]
shebangs = []
roots = []
comment-token = "(**)"
language-server = { command = "ocamllsp" }
indent = { tab-width = 2, unit = "  " }

[[grammar]]
name = "ocaml-interface"
source = { git = "https://github.com/tree-sitter/tree-sitter-ocaml", rev = "23d419ba45789c5a47d31448061557716b02750a", subpath = "interface" }

[[language]]
name = "lua"
scope = "source.lua"
file-types = ["lua"]
shebangs = ["lua"]
roots = [".luarc.json", ".luacheckrc", ".stylua.toml", "selene.toml", ".git"]
comment-token = "--"
indent = { tab-width = 2, unit = "  " }
language-server = { command = "lua-language-server", args = [] }

[[grammar]]
name = "lua"
source = { git = "https://github.com/nvim-treesitter/tree-sitter-lua", rev = "6f5d40190ec8a0aa8c8410699353d820f4f7d7a6" }

[[language]]
name = "svelte"
scope = "source.svelte"
injection-regex = "svelte"
file-types = ["svelte"]
roots = []
indent = { tab-width = 2, unit = "  " }
language-server = { command = "svelteserver", args = ["--stdio"] }

[[grammar]]
name = "svelte"
source = { git = "https://github.com/Himujjal/tree-sitter-svelte", rev = "349a5984513b4a4a9e143a6e746120c6ff6cf6ed" }

[[language]]
name = "vue"
scope = "source.vue"
injection-regex = "vue"
file-types = ["vue"]
roots = ["package.json", "vue.config.js"]
indent = { tab-width = 2, unit = "  " }
language-server = { command = "vls" }

[[grammar]]
name = "vue"
source = { git = "https://github.com/ikatyang/tree-sitter-vue", rev = "91fe2754796cd8fba5f229505a23fa08f3546c06" }

[[language]]
name = "yaml"
scope = "source.yaml"
file-types = ["yml", "yaml"]
roots = []
comment-token = "#"
indent = { tab-width = 2, unit = "  " }
language-server = { command = "yaml-language-server", args = ["--stdio"] }
injection-regex = "yml|yaml"

[[grammar]]
name = "yaml"
source = { git = "https://github.com/ikatyang/tree-sitter-yaml", rev = "0e36bed171768908f331ff7dff9d956bae016efb" }

[[language]]
name = "haskell"
scope = "source.haskell"
injection-regex = "haskell"
file-types = ["hs"]
roots = ["Setup.hs", "stack.yaml", "*.cabal"]
comment-token = "--"
language-server = { command = "haskell-language-server-wrapper", args = ["--lsp"] }
indent = { tab-width = 2, unit = "  " }

[[grammar]]
name = "haskell"
source = { git = "https://github.com/tree-sitter/tree-sitter-haskell", rev = "b6ec26f181dd059eedd506fa5fbeae1b8e5556c8" }

[[language]]
name = "zig"
scope = "source.zig"
injection-regex = "zig"
file-types = ["zig"]
roots = ["build.zig"]
auto-format = true
comment-token = "//"
language-server = { command = "zls" }
indent = { tab-width = 4, unit = "    " }
formatter = { command = "zig" , args = ["fmt", "--stdin"] }


[[grammar]]
name = "zig"
source = { git = "https://github.com/maxxnino/tree-sitter-zig", rev = "93331b8bd8b4ebee2b575490b2758f16ad4e9f30" }

[[language]]
name = "prolog"
scope = "source.prolog"
roots = []
file-types = ["pl", "prolog"]
shebangs = ["swipl"]
comment-token = "%"
language-server = { command = "swipl", args = [
    "-g", "use_module(library(lsp_server))",
    "-g", "lsp_server:main",
    "-t", "halt", "--", "stdio"] }

[[language]]
name = "tsq"
scope = "source.tsq"
file-types = ["scm"]
roots = []
comment-token = ";"
injection-regex = "tsq"
indent = { tab-width = 2, unit = "  " }

[[grammar]]
name = "tsq"
source = { git = "https://github.com/the-mikedavis/tree-sitter-tsq", rev = "48b5e9f82ae0a4727201626f33a17f69f8e0ff86" }

[[language]]
name = "cmake"
scope = "source.cmake"
file-types = ["cmake", "CMakeLists.txt"]
roots = []
comment-token = "#"
indent = { tab-width = 2, unit = "  " }
language-server = { command = "cmake-language-server" }
injection-regex = "cmake"

[[grammar]]
name = "cmake"
source = { git = "https://github.com/uyha/tree-sitter-cmake", rev = "f6616f1e417ee8b62daf251aa1daa5d73781c596" }

[[language]]
name = "make"
scope = "source.make"
file-types = ["Makefile", "makefile", "mk", "justfile", ".justfile"]
injection-regex = "(make|makefile|Makefile|mk|just)"
roots = []
comment-token = "#"
indent = { tab-width = 4, unit = "\t" }

[[grammar]]
name = "make"
source = { git = "https://github.com/alemuller/tree-sitter-make", rev = "a4b9187417d6be349ee5fd4b6e77b4172c6827dd" }

[[language]]
name = "glsl"
scope = "source.glsl"
file-types = ["glsl", "vert", "tesc", "tese", "geom", "frag", "comp" ]
roots = []
comment-token = "//"
indent = { tab-width = 4, unit = "    " }
injection-regex = "glsl"

[[grammar]]
name = "glsl"
source = { git = "https://github.com/theHamsta/tree-sitter-glsl", rev = "88408ffc5e27abcffced7010fc77396ae3636d7e" }

[[language]]
name = "perl"
scope = "source.perl"
file-types = ["pl", "pm", "t"]
shebangs = ["perl"]
roots = []
comment-token = "#"
indent = { tab-width = 2, unit = "  " }

[[grammar]]
name = "perl"
source = { git = "https://github.com/ganezdragon/tree-sitter-perl", rev = "0ac2c6da562c7a2c26ed7e8691d4a590f7e8b90a" }

[[language]]
name = "racket"
scope = "source.rkt"
roots = []
file-types = ["rkt"]
shebangs = ["racket"]
comment-token = ";"
language-server = { command = "racket", args = ["-l", "racket-langserver"] }

[[language]]
name = "comment"
scope = "scope.comment"
roots = []
file-types = []
injection-regex = "comment"

[[grammar]]
name = "comment"
source = { git = "https://github.com/stsewd/tree-sitter-comment", rev = "5dd3c62f1bbe378b220fe16b317b85247898639e" }

[[language]]
name = "wgsl"
scope = "source.wgsl"
file-types = ["wgsl"]
roots = []
comment-token = "//"
language-server = { command = "wgsl_analyzer" }
indent = { tab-width = 4, unit = "    " }

[[grammar]]
name = "wgsl"
source = { git = "https://github.com/szebniok/tree-sitter-wgsl", rev = "f00ff52251edbd58f4d39c9c3204383253032c11" }

[[language]]
name = "llvm"
scope = "source.llvm"
roots = []
file-types = ["ll"]
comment-token = ";"
indent = { tab-width = 2, unit = "  " }
injection-regex = "llvm"

[[grammar]]
name = "llvm"
source = { git = "https://github.com/benwilliamgraham/tree-sitter-llvm", rev = "3b213925b9c4f42c1acfe2e10bfbb438d9c6834d" }

[[language]]
name = "llvm-mir"
scope = "source.llvm_mir"
roots = []
file-types = []
comment-token = ";"
indent = { tab-width = 2, unit = "  " }
injection-regex = "mir"

[[grammar]]
name = "llvm-mir"
source = { git = "https://github.com/Flakebi/tree-sitter-llvm-mir", rev = "06fabca19454b2dc00c1b211a7cb7ad0bc2585f1" }

[[language]]
name = "llvm-mir-yaml"
# TODO allow languages to point to their grammar like so:
#
#     grammar = "yaml"
scope = "source.yaml"
roots = []
file-types = ["mir"]
comment-token = "#"
indent = { tab-width = 2, unit = "  " }

[[language]]
name = "tablegen"
scope = "source.tablegen"
roots = []
file-types = ["td"]
comment-token = "//"
indent = { tab-width = 2, unit = "  " }
injection-regex = "tablegen"

[[grammar]]
name = "tablegen"
source = { git = "https://github.com/Flakebi/tree-sitter-tablegen", rev = "568dd8a937347175fd58db83d4c4cdaeb6069bd2" }

[[language]]
name = "markdown"
scope = "source.md"
injection-regex = "md|markdown"
file-types = ["md"]
roots = []
indent = { tab-width = 2, unit = "  " }

[[grammar]]
name = "markdown"
source = { git = "https://github.com/MDeiml/tree-sitter-markdown", rev = "142a5b4a1b092b64c9f5db8f11558f9dd4009a1b", subpath = "tree-sitter-markdown" }

[[language]]
name = "markdown.inline"
scope = "source.markdown.inline"
injection-regex = "markdown\\.inline"
file-types = []
roots = []
grammar = "markdown_inline"

[[grammar]]
name = "markdown_inline"
source = { git = "https://github.com/MDeiml/tree-sitter-markdown", rev = "142a5b4a1b092b64c9f5db8f11558f9dd4009a1b", subpath = "tree-sitter-markdown-inline" }

[[language]]
name = "dart"
scope = "source.dart"
file-types = ["dart"]
roots = ["pubspec.yaml"]
auto-format = true
comment-token = "//"
language-server = { command = "dart", args = ["language-server", "--client-id=helix"] }
indent = { tab-width = 2, unit = "  " }

[[grammar]]
name = "dart"
source = { git = "https://github.com/UserNobody14/tree-sitter-dart", rev = "2d7f66651c9319c1a0e4dda226cc2628fbb66528" }

[[language]]
name = "scala"
scope = "source.scala"
roots = ["build.sbt", "pom.xml"]
file-types = ["scala", "sbt"]
comment-token = "//"
indent = { tab-width = 2, unit = "  " }
language-server = { command = "metals" }

[[grammar]]
name = "scala"
source = { git = "https://github.com/tree-sitter/tree-sitter-scala", rev = "0a3dd53a7fc4b352a538397d054380aaa28be54c" }

[[language]]
name = "dockerfile"
scope = "source.dockerfile"
injection-regex = "docker|dockerfile"
roots = ["Dockerfile"]
file-types = ["Dockerfile", "dockerfile"]
comment-token = "#"
indent = { tab-width = 2, unit = "  " }
language-server = { command = "docker-langserver", args = ["--stdio"] }

[[grammar]]
name = "dockerfile"
source = { git = "https://github.com/camdencheek/tree-sitter-dockerfile", rev = "7af32bc04a66ab196f5b9f92ac471f29372ae2ce" }

[[language]]
name = "git-commit"
scope = "git.commitmsg"
roots = []
file-types = ["COMMIT_EDITMSG"]
comment-token = "#"
indent = { tab-width = 2, unit = "  " }

[[grammar]]
name = "git-commit"
source = { git = "https://github.com/the-mikedavis/tree-sitter-git-commit", rev = "318dd72abfaa7b8044c1d1fbeabcd06deaaf038f" }

[[language]]
name = "git-diff"
scope = "source.diff"
roots = []
file-types = ["diff"]
injection-regex = "diff"
comment-token = "#"
indent = { tab-width = 2, unit = "  " }

[[grammar]]
name = "git-diff"
source = { git = "https://github.com/the-mikedavis/tree-sitter-git-diff", rev = "c12e6ecb54485f764250556ffd7ccb18f8e2942b" }

[[language]]
name = "git-rebase"
scope = "source.gitrebase"
roots = []
file-types = ["git-rebase-todo"]
injection-regex = "git-rebase"
comment-token = "#"
indent = { tab-width = 2, unit = " " }

[[grammar]]
name = "git-rebase"
source = { git = "https://github.com/the-mikedavis/tree-sitter-git-rebase", rev = "332dc528f27044bc4427024dbb33e6941fc131f2" }

[[language]]
name = "regex"
scope = "source.regex"
injection-regex = "regex"
file-types = ["regex"]
roots = []

[[grammar]]
name = "regex"
source = { git = "https://github.com/tree-sitter/tree-sitter-regex", rev = "e1cfca3c79896ff79842f057ea13e529b66af636" }

[[language]]
name = "git-config"
scope = "source.gitconfig"
roots = []
# TODO: allow specifying file-types as a regex so we can read directory names (e.g. `.git/config`)
file-types = [".gitmodules", ".gitconfig"]
injection-regex = "git-config"
comment-token = "#"
indent = { tab-width = 4, unit = "\t" }

[[grammar]]
name = "git-config"
source = { git = "https://github.com/the-mikedavis/tree-sitter-git-config", rev = "0e4f0baf90b57e5aeb62dcdbf03062c6315d43ea" }

[[language]]
name = "git-attributes"
scope = "source.gitattributes"
roots = []
file-types = [".gitattributes"]
injection-regex = "git-attributes"
comment-token = "#"
grammar = "gitattributes"

[[grammar]]
name = "gitattributes"
source = { git = "https://github.com/mtoohey31/tree-sitter-gitattributes", rev = "3dd50808e3096f93dccd5e9dc7dc3dba2eb12dc4" }

[[language]]
name = "git-ignore"
scope = "source.gitignore"
roots = []
file-types = [".gitignore", ".gitignore_global"]
injection-regex = "git-ignore"
comment-token = "#"
grammar = "gitignore"

[[grammar]]
name = "gitignore"
source = { git = "https://github.com/shunsambongi/tree-sitter-gitignore", rev = "f4685bf11ac466dd278449bcfe5fd014e94aa504" }

[[language]]
name = "graphql"
scope = "source.graphql"
injection-regex = "graphql"
file-types = ["gql", "graphql"]
roots = []
indent = { tab-width = 2, unit = "  " }

[[grammar]]
name = "graphql"
source = { git = "https://github.com/bkegley/tree-sitter-graphql", rev = "5e66e961eee421786bdda8495ed1db045e06b5fe" }

[[language]]
name = "elm"
scope = "source.elm"
injection-regex = "elm"
file-types = ["elm"]
roots = ["elm.json"]
auto-format = true
comment-token = "--"
language-server = { command = "elm-language-server" }
indent = { tab-width = 4, unit = "    " }

[[grammar]]
name = "elm"
source = { git = "https://github.com/elm-tooling/tree-sitter-elm", rev = "df4cb639c01b76bc9ac9cc66788709a6da20002c" }

[[language]]
name = "iex"
scope = "source.iex"
injection-regex = "iex"
file-types = ["iex"]
roots = []

[[grammar]]
name = "iex"
source = { git = "https://github.com/elixir-lang/tree-sitter-iex", rev = "39f20bb51f502e32058684e893c0c0b00bb2332c" }

[[language]]
name = "rescript"
scope = "source.rescript"
injection-regex = "rescript"
file-types = ["res"]
roots = ["bsconfig.json"]
auto-format = true
comment-token = "//"
language-server = { command = "rescript-language-server", args = ["--stdio"] }
indent = { tab-width = 2, unit = "  " }

[[grammar]]
name = "rescript"
source = { git = "https://github.com/jaredramirez/tree-sitter-rescript", rev = "4cd7ba91696886fdaca086fb32b5fd8cc294a129" }

[[language]]
name = "erlang"
scope = "source.erlang"
injection-regex = "erl(ang)?"
file-types = ["erl", "hrl", "app", "rebar.config", "rebar.lock"]
roots = ["rebar.config"]
comment-token = "%%"
indent = { tab-width = 4, unit = "    " }
language-server = { command = "erlang_ls" }

[language.auto-pairs]
'(' = ')'
'{' = '}'
'[' = ']'
'"' = '"'
"'" = "'"
'`' = "'"

[[grammar]]
name = "erlang"
source = { git = "https://github.com/the-mikedavis/tree-sitter-erlang", rev = "0e7d677d11a7379686c53c616825714ccb728059" }

[[language]]
name = "kotlin"
scope = "source.kotlin"
file-types = ["kt", "kts"]
roots = ["settings.gradle", "settings.gradle.kts"]
comment-token = "//"
indent = { tab-width = 4, unit = "    " }
language-server = { command = "kotlin-language-server" }

[[grammar]]
name = "kotlin"
source = { git = "https://github.com/fwcd/tree-sitter-kotlin", rev = "a4f71eb9b8c9b19ded3e0e9470be4b1b77c2b569" }

[[language]]
name = "hcl"
scope = "source.hcl"
injection-regex = "(hcl|tf|nomad)"
file-types = ["hcl", "tf", "nomad"]
roots = []
comment-token = "#"
indent = { tab-width = 2, unit = "  " }
language-server = { command = "terraform-ls", args = ["serve"], language-id = "terraform" }
auto-format = true

[[grammar]]
name = "hcl"
source = { git = "https://github.com/MichaHoffmann/tree-sitter-hcl", rev = "3cb7fc28247efbcb2973b97e71c78838ad98a583" }

[[language]]
name = "tfvars"
scope = "source.tfvars"
file-types = ["tfvars"]
roots = []
comment-token = "#"
indent = { tab-width = 2, unit = "  " }
language-server = { command = "terraform-ls", args = ["serve"], language-id = "terraform-vars" }
auto-format = true
grammar = "hcl"

[[language]]
name = "org"
scope = "source.org"
injection-regex = "org"
file-types = ["org"]
roots = []
indent = { tab-width = 2, unit = "  " }

[[grammar]]
name = "org"
source = { git = "https://github.com/milisims/tree-sitter-org", rev = "698bb1a34331e68f83fc24bdd1b6f97016bb30de" }

[[language]]
name = "solidity"
scope = "source.sol"
injection-regex = "^(sol|solidity)$"
file-types = ["sol"]
roots = []
comment-token = "//"
indent = { tab-width = 4, unit = "    " }
language-server = { command = "solc", args = ["--lsp"] }

[[grammar]]
name = "solidity"
source = { git = "https://github.com/slinlee/tree-sitter-solidity", rev = "f3a002274744e859bf64cf3524985f8c31ea84fd" }

[[language]]
name = "gleam"
scope = "source.gleam"
injection-regex = "gleam"
file-types = ["gleam"]
roots = ["gleam.toml"]
comment-token = "//"
indent = { tab-width = 2, unit = "  " }
language-server = { command = "gleam", args = ["lsp"] }

[[grammar]]
name = "gleam"
source = { git = "https://github.com/gleam-lang/tree-sitter-gleam", rev = "d7861b2a4b4d594c58bb4f1be5f1f4ee4c67e5c3" }

[[language]]
name = "ron"
scope = "source.ron"
injection-regex = "ron"
file-types = ["ron"]
roots = []
comment-token = "//"
indent = { tab-width = 4, unit = "    " }
grammar = "rust"

[[language]]
name = "r"
scope = "source.r"
injection-regex = "(r|R)"
file-types = ["r", "R"]
shebangs = ["r", "R"]
roots = []
comment-token = "#"
indent = { tab-width = 2, unit = "  " }
language-server = { command = "R", args = ["--slave", "-e", "languageserver::run()"] }

[[grammar]]
name = "r"
source = { git = "https://github.com/r-lib/tree-sitter-r", rev = "cc04302e1bff76fa02e129f332f44636813b0c3c" }

[[language]]
name = "rmarkdown"
scope = "source.rmd"
injection-regex = "(r|R)md"
file-types = ["rmd", "Rmd"]
roots = []
indent = { tab-width = 2, unit = "  " }
grammar = "markdown"
language-server = { command = "R", args = ["--slave", "-e", "languageserver::run()"] }

[[language]]
name = "swift"
scope = "source.swift"
injection-regex = "swift"
file-types = ["swift"]
roots = [ "Package.swift" ]
comment-token = "//"
auto-format = true
language-server = { command = "sourcekit-lsp" }

[[grammar]]
name = "swift"
source = { git = "https://github.com/alex-pinkus/tree-sitter-swift", rev = "77c6312c8438f4dbaa0350cec92b3d6dd3d74a66" }

[[language]]
name = "erb"
scope = "text.html.erb"
injection-regex = "erb"
file-types = ["erb"]
roots = []
indent = { tab-width = 2, unit = "  " }
grammar = "embedded-template"

[[language]]
name = "ejs"
scope = "text.html.ejs"
injection-regex = "ejs"
file-types = ["ejs"]
roots = []
indent = { tab-width = 2, unit = "  " }
grammar = "embedded-template"

[[grammar]]
name = "embedded-template"
source = { git = "https://github.com/tree-sitter/tree-sitter-embedded-template", rev = "d21df11b0ecc6fd211dbe11278e92ef67bd17e97" }

[[language]]
name = "eex"
scope = "source.eex"
injection-regex = "eex"
file-types = ["eex"]
roots = []
indent = { tab-width = 2, unit = "  " }

[[grammar]]
name = "eex"
source = { git = "https://github.com/connorlay/tree-sitter-eex", rev = "f742f2fe327463335e8671a87c0b9b396905d1d1" }

[[language]]
name = "heex"
scope = "source.heex"
injection-regex = "heex"
file-types = ["heex"]
roots = []
indent = { tab-width = 2, unit = "  " }

[[grammar]]
name = "heex"
source = { git = "https://github.com/phoenixframework/tree-sitter-heex", rev = "961bc4d2937cfd24ceb0a5a6b2da607809f8822e" }

[[language]]
name = "sql"
scope = "source.sql"
file-types = ["sql"]
roots = []
comment-token = "--"
indent = { tab-width = 4, unit = "    " }
injection-regex = "sql"

[[grammar]]
name = "sql"
source = { git = "https://github.com/DerekStride/tree-sitter-sql", rev = "0caa7fa2ee00e0b770493a79d4efacc1fc376cc5" }

[[language]]
name = "gdscript"
scope = "source.gdscript"
injection-regex = "gdscript"
file-types = ["gd"]
shebangs = []
roots = ["project.godot"]
auto-format = true
comment-token = "#"
indent = { tab-width = 4, unit = "    " }

[[grammar]]
name = "gdscript"
source = { git = "https://github.com/PrestonKnopp/tree-sitter-gdscript", rev = "2a6abdaa47fcb91397e09a97c7433fd995ea46c6" }

[[language]]
name = "nu"
scope = "source.nu"
injection-regex = "nu"
file-types = ["nu"]
roots = []
comment-token = "#"
indent = { tab-width = 2, unit = "  " }

[[grammar]]
name = "nu"
source = { git = "https://github.com/LhKipp/tree-sitter-nu", rev = "db4e990b78824c8abef3618e0f93b7fe1e8f4c0d" }

[[language]]
name = "vala"
scope = "source.vala"
injection-regex = "vala"
file-types = ["vala", "vapi"]
roots = []
comment-token = "//"
indent = { tab-width = 2, unit = "  " }
language-server = { command = "vala-language-server" }

[[grammar]]
name = "vala"
source = { git = "https://github.com/vala-lang/tree-sitter-vala", rev = "c9eea93ba2ec4ec1485392db11945819779745b3" }

[[language]]
name = "hare"
scope = "source.hare"
injection-regex = "hare"
file-types = ["ha"]
roots = []
comment-token = "//"
indent = { tab-width = 8, unit = "\t" }

[[grammar]]
name = "hare"
source = { git = "https://git.sr.ht/~ecmma/tree-sitter-hare", rev = "bc26a6a949f2e0d98b7bfc437d459b250900a165" }

[[language]]
name = "devicetree"
scope = "source.devicetree"
injection-regex = "(dtsi?|devicetree|fdt)"
file-types = ["dts", "dtsi"]
roots = []
comment-token = "//"
indent = { tab-width = 4, unit = "\t" }

[[grammar]]
name = "devicetree"
source = { git = "https://github.com/joelspadin/tree-sitter-devicetree", rev = "877adbfa0174d25894c40fa75ad52d4515a36368" }

[[language]]
name = "cairo"
scope = "source.cairo"
injection-regex = "cairo"
file-types = ["cairo"]
roots = []
comment-token = "#"
indent = { tab-width = 4, unit = "    " }

[[grammar]]
name = "cairo"
source = { git = "https://github.com/archseer/tree-sitter-cairo", rev = "5155c6eb40db6d437f4fa41b8bcd8890a1c91716" }

[[language]]
name = "cpon"
scope = "scope.cpon"
injection-regex = "^cpon$"
file-types = ["cpon", "cp"]
roots = []
auto-format = true
comment-token = "//"
indent = { tab-width = 2, unit = "  " }

[[grammar]]
name = "cpon"
source = { git = "https://github.com/fvacek/tree-sitter-cpon", rev = "0d01fcdae5a53191df5b1349f9bce053833270e7" }

[[language]]
name = "odin"
auto-format = false
scope = "source.odin"
file-types = ["odin"]
roots = ["ols.json"]
language-server = { command = "ols", args = [] }
comment-token = "//"
indent = { tab-width = 4, unit = "\t" }

[[grammar]]
name = "odin"
source = { git = "https://github.com/MineBill/tree-sitter-odin", rev = "da885f4a387f169b9b69fe0968259ee257a8f69a" }

[[language]]
name = "meson"
scope = "source.meson"
injection-regex = "meson"
file-types = ["meson.build"]
roots = []
comment-token = "#"
indent = { tab-width = 2, unit = "  " }

[[grammar]]
name = "meson"
source = { git = "https://github.com/bearcove/tree-sitter-meson", rev = "feea83be9225842490066522ced2d13eb9cce0bd" }

[[language]]
name = "sshclientconfig"
scope = "source.sshclientconfig"
file-types = [".ssh/config", "/etc/ssh/ssh_config"]
roots = []

[[grammar]]
name = "sshclientconfig"
source = { git = "https://github.com/metio/tree-sitter-ssh-client-config", rev = "769d7a01a2e5493b4bb5a51096c6bf4be130b024" }

[[language]]
name = "scheme"
scope = "source.scheme"
injection-regex = "scheme"
file-types = ["ss", "rkt"] # "scm",
roots = []
comment-token = ";"
indent = { tab-width = 2, unit = "  " }

[[grammar]]
name = "scheme"
source = { git = "https://github.com/6cdh/tree-sitter-scheme", rev = "27fb77db05f890c2823b4bd751c6420378df146b" }

[[language]]
name = "v"
scope = "source.v"
file-types = ["v", "vv"]
shebangs = ["v run"]
roots = ["v.mod"]
language-server = { command = "vls", args = [] }
auto-format = true
comment-token = "//"
indent = { tab-width = 4, unit = "\t" }

[[grammar]]
name = "v"
source = { git = "https://github.com/vlang/vls", subpath = "tree_sitter_v", rev = "3e8124ea4ab80aa08ec77f03df53f577902a0cdd" }

[[language]]
name = "verilog"
scope = "source.verilog"
file-types = ["v", "vh", "sv", "svh"]
roots = []
comment-token = "//"
language-server = { command = "svlangserver", args = [] }
indent = { tab-width = 2, unit = "  " }
injection-regex = "verilog"

[[grammar]]
name = "verilog"
source = { git = "https://github.com/andreytkachenko/tree-sitter-verilog", rev = "514d8d70593d29ef3ef667fa6b0e504ae7c977e3" }

[[language]]
name = "edoc"
scope = "source.edoc"
file-types = ["edoc", "edoc.in"]
injection-regex = "edoc"
roots = []
indent = { tab-width = 4, unit = "    " }

[[grammar]]
name = "edoc"
source = { git = "https://github.com/the-mikedavis/tree-sitter-edoc", rev = "1691ec0aa7ad1ed9fa295590545f27e570d12d60" }

[[language]]
name = "jsdoc"
scope = "source.jsdoc"
injection-regex = "jsdoc"
file-types = ["jsdoc"]
roots = []
indent = { tab-width = 2, unit = "  " }

[[grammar]]
name = "jsdoc"
source = { git = "https://github.com/tree-sitter/tree-sitter-jsdoc", rev = "189a6a4829beb9cdbe837260653b4a3dfb0cc3db" }

[[language]]
name = "openscad"
scope = "source.openscad"
injection-regex = "openscad"
file-types = ["scad"]
roots = []
comment-token = "//"
language-server = { command = "openscad-language-server" }
indent = { tab-width = 2, unit = "\t" }

[[grammar]]
name = "openscad"
source = { git = "https://github.com/bollian/tree-sitter-openscad", rev = "5c3ce93df0ac1da7197cf6ae125aade26d6b8972" }

[[language]]
name = "prisma"
scope = "source.prisma"
injection-regex = "prisma"
file-types = ["prisma"]
roots = ["package.json"]
comment-token = "//"
language-server = { command = "prisma-language-server", args = ["--stdio"] }
indent = { tab-width = 2, unit = "  " }

[[grammar]]
name = "prisma"
source = { git = "https://github.com/victorhqc/tree-sitter-prisma", rev = "17a59236ac25413b81b1613ea6ba5d8d52d7cd6c" }

[[language]]
name = "clojure"
scope = "source.clojure"
injection-regex = "(clojure|clj|edn|boot)"
file-types = ["clj", "cljs", "cljc", "clje", "cljr", "cljx", "edn", "boot"]
roots = ["project.clj", "build.boot", "deps.edn", "shadow-cljs.edn"]
comment-token = ";"
language-server = { command = "clojure-lsp" }
indent = { tab-width = 2, unit = "  " }

[[grammar]]
name = "clojure"
source = { git = "https://github.com/sogaiu/tree-sitter-clojure", rev = "e57c569ae332ca365da623712ae1f50f84daeae2" }

[[language]]
name = "starlark"
scope = "source.starlark"
injection-regex = "(starlark|bzl|bazel)"
file-types = ["bzl", "bazel", "BUILD"]
roots = []
comment-token = "#"
indent = { tab-width = 4, unit = "    " }
grammar = "python"

[[language]]
name = "elvish"
scope = "source.elvish"
file-types = ["elv"]
roots = []
comment-token = "#"
indent = { tab-width = 2, unit = "  " }
language-server = { command = "elvish", args = ["-lsp"] }
grammar = "elvish"

[[grammar]]
name = "elvish"
source = { git = "https://github.com/ckafi/tree-sitter-elvish", rev = "e50787cadd3bc54f6d9c0704493a79078bb8a4e5" }

[[language]]
name = "idris"
scope = "source.idr"
injection-regex = "idr"
file-types = ["idr"]
shebangs = []
roots = []
comment-token = "--"
indent = { tab-width = 2, unit = "  " }
language-server = { command = "idris2-lsp" }

[[language]]
name = "fortran"
scope = "source.fortran"
injection-regex = "fortran"
file-types = ["f", "for", "f90", "f95", "f03"]
roots = ["fpm.toml"]
comment-token = "!"
indent = { tab-width = 4, unit = "    "}
language-server = { command = "fortls", args = ["--lowercase_intrinsics"] }

[[grammar]]
name = "fortran"
source = { git = "https://github.com/stadelmanma/tree-sitter-fortran", rev = "f0f2f100952a353e64e26b0fa710b4c296d7af13" }

[[language]]
name = "ungrammar"
scope = "source.ungrammar"
injection-regex = "ungrammar"
file-types = ["ungram", "ungrammar"]
roots = []
comment-token = "//"
indent = { tab-width = 2, unit = "  " }

[[grammar]]
name = "ungrammar"
source = { git = "https://github.com/Philipp-M/tree-sitter-ungrammar", rev = "0113de880a58ea14f2a75802e9b99fcc25003d9c" }

[[language]]
name = "dot"
scope = "source.dot"
injection-regex = "dot"
file-types = ["dot"]
roots = []
comment-token = "//"
indent = { tab-width = 4, unit = "    " }
language-server = { command = "dot-language-server", args = ["--stdio"] }

[[grammar]]
name = "dot"
source = { git = "https://github.com/rydesun/tree-sitter-dot", rev = "917230743aa10f45a408fea2ddb54bbbf5fbe7b7" }

[[language]]
name = "cue"
scope = "source.cue"
injection-regex = "cue"
file-types = ["cue"]
roots = ["cue.mod"]
auto-format = true
comment-token = "//"
language-server = { command = "cuelsp" }
indent = { tab-width = 4, unit = "\t" }

[[grammar]]
name = "cue"
source = { git = "https://github.com/eonpatapon/tree-sitter-cue", rev = "61843e3beebf19417e4fede4e8be4df1084317ad" }

[[language]]
name = "slint"
scope = "source.slint"
injection-regex = "slint"
file-types = ["slint"]
roots = []
comment-token = "//"
indent = { tab-width = 4, unit = "    " }
language-server = { command = "slint-lsp", args = [] }

[[grammar]]
name = "slint"
source = { git = "https://github.com/jrmoulton/tree-sitter-slint", rev = "0d4dda94f96623302dfc234e06be62a5717f47da" }

[[language]]
name = "task"
scope = "source.task"
injection-regex = "task"
file-types = ["task"]
roots = []
comment-token = "#"
indent = { tab-width = 2, unit = "  " }

[[grammar]]
name = "task"
source = { git = "https://github.com/alexanderbrevig/tree-sitter-task", rev = "f2cb435c5dbf3ee19493e224485d977cb2d36d8b" }

[[language]]
name = "xit"
scope = "source.xit"
injection-regex = "xit"
file-types = ["xit"]
roots = []
indent = { tab-width = 4, unit = "    " }

[[grammar]]
name = "xit"
source = { git = "https://github.com/synaptiko/tree-sitter-xit", rev = "7d7902456061bc2ad21c64c44054f67b5515734c" }

[[language]]
name = "esdl"
scope = "source.esdl"
injection-regex = "esdl"
file-types = ["esdl"]
comment-token = "#"
indent = { tab-width = 2, unit = "  " }
roots = ["edgedb.toml"]

[[grammar]]
name ="esdl"
source = { git = "https://github.com/greym0uth/tree-sitter-esdl", rev = "b840c8a8028127e0a7c6e6c45141adade2bd75cf" }

[[language]]
name = "pascal"
scope = "source.pascal"
injection-regex = "pascal"
file-types = ["pas", "pp", "inc", "lpr", "lfm"]
roots = []
comment-token = "//"
indent = { tab-width = 2, unit = "  " }
language-server = { command = "pasls", args = [] }

[[grammar]]
name = "pascal"
source = { git = "https://github.com/Isopod/tree-sitter-pascal", rev = "2fd40f477d3e2794af152618ccfac8d92eb72a66" }
'';
in
configText
