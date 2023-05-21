{ pkgs, lib, ... }:
{
  language-server = {

    vscode-css-language-server = { command = "vscode-css-language-server"; args = [ "--stdio" ]; config = { provideFormatter = true; }; };
    vscode-html-language-server = { command = "vscode-html-language-server"; args = [ "--stdio" ]; config = { provideFormatter = true; }; };
    vscode-json-language-server = { command = "vscode-json-languageserver"; args = [ "--stdio" ]; config = { provideFormatter = true; }; };
    clangd = { command = "clangd"; };
    docker-langserver = { command = "docker-langserver"; args = [ "--stdio" ]; };
    haskell-language-server = { command = "haskell-language-server-wrapper"; args = [ "--lsp" ]; };
    idris2-lsp = { command = "idris2-lsp"; };
    jsonnet-language-server = { command = "jsonnet-language-server"; args = [ "-t" "--lint" ]; };
    julia = { command = "julia"; timeout = 60; args = [ "--startup-file=no" "--history-file=no" "--quiet" "-e" "using LanguageServer; runserver()" ]; };
    kotlin-language-server = { command = "kotlin-language-server"; };
    lean = { command = "lean"; args = [ "--server" ]; };
    markdoc-ls = { command = "markdoc-ls"; args = [ "--stdio" ]; };
    marksman = { command = "marksman"; args = [ "server" ]; };
    nil = { command = "nil"; };
    ocamllsp = { command = "ocamllsp"; };
    taplo = { command = "taplo"; args = [ "lsp" "stdio" ]; };
    texlab = { command = "texlab"; };
    vuels = { command = "vls"; };
    pylsp = { command = "pylsp"; };
    yaml-language-server = { command = "yaml-language-server"; args = [ "--stdio" ]; };
    zls = { command = "zls"; };
    awk-language-server = { command = "awk-language-server"; };
    bash-language-server = { command = "bash-language-server"; args = [ "start" ]; };
    cmake-language-server = { command = "cmake-language-server"; };
  };
  language = [
    {
      name = "nix";
      formatter = {
        command = "nixpkgs-fmt";
      };
    }
    {
      name = "json";
      formatter = {
        args = [ "--parser" "json" ];
        command = "prettier";
      };
    }
  ];
}
