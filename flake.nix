{
  inputs.nixpkgs.url = "github:NickCao/nixpkgs/nixos-unstable-small";
  outputs = { self, nixpkgs, ... }: {
    packages.x86_64-linux.ipsec = nixpkgs.legacyPackages.x86_64-linux.nixosTest {
      name = "ipsec";
      nodes =
        let
          nodes = {
            node1 = {
              id = 1;
              addr = "192.168.1.1";
              prefix = "fc00:1::1/64";
              port = 50001;
              pub = ''
                -----BEGIN PUBLIC KEY-----
                MCowBQYDK2VwAyEA0fIFaKz0kB/jlgjHQZLdlfELwUx5W3/mEErkDPRTKgg=
                -----END PUBLIC KEY-----
              '';
              priv = ''
                -----BEGIN PRIVATE KEY-----
                MC4CAQAwBQYDK2VwBCIEIMamaugVRsYMY3N2iS5jaxDnnuUzFE6A2sg8dh7WStD1
                -----END PRIVATE KEY-----
              '';
            };
            node2 = {
              id = 2;
              addr = "192.168.1.2";
              prefix = "fc00:2::1/64";
              port = 50002;
              pub = ''
                -----BEGIN PUBLIC KEY-----
                MCowBQYDK2VwAyEAqLIvzUm/xMgSyDW3EmtOw65zjPuLsN7Pz57fFJiOCsg=
                -----END PUBLIC KEY-----
              '';
              priv = ''
                -----BEGIN PRIVATE KEY-----
                MC4CAQAwBQYDK2VwBCIEIBujPwQglT7ZgM7MBXM9SNXax5ClhEj3bysEdlFbt/nq
                -----END PRIVATE KEY-----
              '';
            };
            node3 = {
              id = 3;
              addr = "192.168.1.3";
              prefix = "fc00:3::1/64";
              port = 50003;
              pub = ''
                -----BEGIN PUBLIC KEY-----
                MCowBQYDK2VwAyEArVLalM1amJ9neWgPb8ACmLUC8CgD/JvT09IlA3PvHDo=
                -----END PUBLIC KEY-----
              '';
              priv = ''
                -----BEGIN PRIVATE KEY-----
                MC4CAQAwBQYDK2VwBCIEIMqyIbIcIWt09kAXfDm/XLbsSJQQykTgP2u3EiszHxgn
                -----END PRIVATE KEY-----
              '';
            };
          };
        in
        nixpkgs.lib.mapAttrs
          (n: self:
            let
              others = nixpkgs.lib.filterAttrs (name: node: node.id != self.id) nodes;
            in
            ({ config, pkgs, ... }: {
              environment.systemPackages = [ pkgs.strongswan pkgs.iperf3 ];
              environment.etc."swanctl/private/local.pem".text = self.priv;
              networking = {
                firewall = {
                  allowedUDPPorts = [ self.port ];
                  trustedInterfaces = pkgs.lib.attrNames others;
                };
                useNetworkd = true;
              };
              services.iperf3.enable = true;
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
                strongswan.extraConfig = ''
                  charon {
                    port = 0
                    port_nat_t = ${toString self.port}
                  }
                '';
                swanctl = {
                  connections = pkgs.lib.mapAttrs
                    (name: node: {
                      version = 2;
                      encap = true;
                      local_addrs = [ "%any" ]; # acccept connection to any address
                      remote_addrs = [ node.addr "%any" ]; # try connection to specific address, allow connection from any address
                      remote_port = node.port;
                      if_id_out = toString node.id;
                      if_id_in = toString node.id;
                      local.default = {
                        auth = "pubkey";
                        pubkeys = [ (builtins.toFile "local.pub" self.pub) ];
                      };
                      remote.default = {
                        auth = "pubkey";
                        pubkeys = [ (builtins.toFile "remote.pub" node.pub) ];
                      };
                      children.default = {
                        local_ts = [ "0.0.0.0/0" "::/0" ];
                        remote_ts = [ "0.0.0.0/0" "::/0" ];
                        start_action = "start";
                      };
                    })
                    others;
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
        node1.succeed("sleep 5")
        print(node1.succeed("cat /etc/swanctl/swanctl.conf"))
        print(node1.succeed("swanctl --list-conns"))
        print(node1.succeed("birdc s babel n"))
        print(node1.succeed("birdc s r"))
        print(node1.succeed("iperf3 -c fc00:2::1"))
      '';
    };
  };
}
