let
  nodeDependencies = (pkgs.callPackage /home/riro/Blog/default.nix { }).nodeDependencies;
in

stdenv.mkDerivation {
  name = "blog";
  src = /home/riro/Blog;
  buildInputs = [ nodejs ];
  buildPhase = ''
    ln -s ${nodeDependencies}/lib/node_modules ./node_modules
    export PATH="${nodeDependencies}/bin:$PATH"

    # Build the distribution bundle in "dist"
    
    webpack
    cp -r dist $out/
  '';
}
