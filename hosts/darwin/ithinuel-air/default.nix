{ pathRoot, ... }: {
  security.pki.certificateFiles = [ (pathRoot + "/certs/home.ca.pem") ];

  networking.hostName = "ithinuel-air";
  ids.gids.nixbld = 30000;
}
