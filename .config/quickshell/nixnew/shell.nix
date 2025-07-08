{ pkgs ? import <nixpkgs> {} }: pkgs.mkShell {
  packages = [ pkgs.qt6.qtdeclarative ];
}
