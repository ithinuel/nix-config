{ pkgs, pathRoot }:
let
  nixbldUsers = builtins.listToAttrs (builtins.genList
    (i:
      let
        num = i + 1;
        uid = 30000 + num;
        name = "nixbld${toString num}";
      in
      pkgs.lib.nameValuePair name
        "${name}:x:${toString uid}:30000:NixUser${toString num}:/dev/null:/bin/false"
    )
    32
  );
  custom-bundle = pkgs.cacert.override {
    extraCertificateFiles = [ (pathRoot + "/certs/home.ca.pem") ];
  };
in
pkgs.dockerTools.buildLayeredImage {
  name = "nix-node";
  tag = "latest";
  contents = [
    pkgs.nix
    pkgs.nodejs_26
    custom-bundle
    pkgs.bashInteractive
    pkgs.coreutils
    pkgs.gitMinimal
    pkgs.gnutar
    pkgs.gzip
    pkgs.xz
    pkgs.openssh
  ];
  fakeRootCommands = ''
    mkdir /root

    # Create /etc/passwd with root + nixbld users
    cat > etc/passwd <<'EOF'
    root:x:0:0:root:/root:/bin/bash
    ${pkgs.lib.concatStringsSep "\n" (builtins.attrValues nixbldUsers)}
    EOF

    # Create /etc/group with root + nixbld group
    cat > etc/group <<'EOF'
    root:x:0:
    nixbld:x:30000:${pkgs.lib.concatStringsSep "," (builtins.attrNames nixbldUsers)}
    EOF

    # Create /etc/shadow
    cat > etc/shadow <<'EOF'
    root:!::0:99999:7:::
    EOF
    for i in $(seq 1 32); do
      echo "nixbld''${i}:!:0:0:99999:7:::" >> etc/shadow
    done

    # Create /etc/gshadow
    cat > etc/gshadow <<'EOF'
    root:!::
    nixbld:!::
    EOF

    # Create /etc/nix/nix.conf
    mkdir -p /etc/nix
    cat > /etc/nix/nix.conf <<'EOF'
    accept-flake-config = true
    experimental-features = nix-command flakes
    max-jobs = auto
    EOF
  '';
  enableFakechroot = true;
  config = {
    Cmd = [ "/bin/bash" ];
    Env = [
      "PATH=/usr/bin:/bin"
      "SSL_CERT_FILE=${custom-bundle}/etc/ssl/certs/ca-bundle.crt"
      "NODE_EXTRA_CA_CERTS=${custom-bundle}/etc/ssl/certs/ca-bundle.crt"
    ];
  };
}
