{
  inputs.nixpkgs.url = "github:NickCao/nixpkgs/nixos-unstable-small";
  outputs = { self, nixpkgs, ... }: {
    packages.x86_64-linux.ipsec = nixpkgs.legacyPackages.x86_64-linux.nixosTest {
      name = "ipsec";
      nodes =
        let
          nodes = {
            node1 = { id = 1; addr = "192.168.1.1"; prefix = "fc00:1::1/64"; };
            node2 = { id = 2; addr = "192.168.1.2"; prefix = "fc00:2::1/64"; };
            node3 = { id = 3; addr = "192.168.1.3"; prefix = "fc00:3::1/64"; };
          };
        in
        nixpkgs.lib.mapAttrs
          (n: self:
            let
              others = nixpkgs.lib.filterAttrs (name: node: node.id != self.id) nodes;
            in
            ({ config, pkgs, ... }: {
              environment.systemPackages = [ pkgs.strongswan ];
              networking = {
                firewall = {
                  allowedUDPPorts = [ 500 4500 ];
                  trustedInterfaces = pkgs.lib.attrNames others;
                };
                useNetworkd = true;
              };
              systemd.network.netdevs = pkgs.lib.mapAttrs
                (name: node: {
                  netdevConfig = {
                    Kind = "xfrm";
                    Name = name;
                  };
                  xfrmConfig = {
                    InterfaceId = node.id;
                    Independent = true;
                  };
                })
                others // {
                gravity = {
                  netdevConfig = {
                    Kind = "dummy";
                    Name = "gravity";
                  };
                };
              };
              systemd.network.networks = pkgs.lib.mapAttrs
                (name: node: {
                  inherit name;
                  linkConfig = {
                    Multicast = true;
                  };
                })
                others // {
                gravity = {
                  name = "gravity";
                  address = [ self.prefix ];
                };
              };
              services.strongswan-swanctl = {
                enable = true;
                swanctl = {
                  connections = pkgs.lib.mapAttrs
                    (name: node: {
                      version = 2;
                      encap = true;
                      remote_addrs = [ node.addr ];
                      if_id_out = toString node.id;
                      if_id_in = toString node.id;
                      local.main = {
                        auth = "psk";
                        id = "${n}@gravity";
                      };
                      remote.main = {
                        auth = "psk";
                        id = "${name}@gravity";
                      };
                      children.default = {
                        local_ts = [ "0.0.0.0/0" "::/0" ];
                        remote_ts = [ "0.0.0.0/0" "::/0" ];
                        start_action = "start";
                      };
                    })
                    others;
                  secrets.ike.shared = {
                    id = pkgs.lib.mapAttrs (name: _: "${name}@gravity") nodes;
                    secret = "supersecretpsk";
                  };
                };
              };
              services.bird2 = {
                enable = true;
                config = ''
                  protocol device {
                    scan time 1;
                  }

                  protocol kernel {
                    ipv6 {
                      export all;
                      import none;
                    };
                  }

                  protocol direct {
                    ipv6;
                    interface "gravity";
                  }

                  protocol babel {
                    ipv6 {
                      export all;
                      import all;
                    };
                    randomize router id;
                    interface "node*" {
                      hello interval 1 s;
                    };
                  }
                '';
              };
            }))
          nodes;
      testScript = ''
        start_all()
        node1.wait_for_unit("strongswan-swanctl.service")
        node1.wait_for_unit("bird2.service")
        print(node1.succeed("swanctl --list-conns"))
        print(node1.succeed("cat /etc/swanctl/swanctl.conf"))
        node1.succeed("sleep 5")
        print(node1.succeed("birdc s babel n"))
        print(node1.succeed("birdc s r"))
      '';
    };
  };
}
