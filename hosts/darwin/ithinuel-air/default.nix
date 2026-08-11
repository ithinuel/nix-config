{ pathRoot, ... }: {
  security.pki.certificateFiles = [ (pathRoot + "/certs/ithinuel.local.crt") ];

  networking.hostName = "ithinuel-air";
  ids.gids.nixbld = 30000;
}
