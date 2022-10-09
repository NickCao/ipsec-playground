{
  inputs.nixpkgs.url = "github:NickCao/nixpkgs/nixos-unstable-small";
  outputs = { self, nixpkgs, ... }: {
    packages.x86_64-linux.ipsec = nixpkgs.legacyPackages.x86_64-linux.nixosTest {
      name = "ipsec";
      nodes =
        let
          nodes = {
            node1 = { id = 1; addr = "192.168.1.1"; prefix = "100.64.1.0/24"; };
            node2 = { id = 2; addr = "192.168.1.2"; prefix = "100.64.2.0/24"; };
            node3 = { id = 3; addr = "192.168.1.3"; prefix = "100.64.3.0/24"; };
          };
          secrets = {
            ike = nixpkgs.lib.mapAttrs
              (name: node: {
                id.default = "${name}@gravity";
                secret = name; # FIXME: use a real secret key
              })
              nodes;
          };
          connections = self: nixpkgs.lib.mapAttrs
            (name: node: {
              version = 2;
              encap = true;
              remote_addrs = [ node.addr ];
              if_id_out = "1";
              if_id_in = "1";
              local.main = {
                auth = "psk";
                id = "${self}@gravity";
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
            nodes;
        in
        nixpkgs.lib.mapAttrs
          (n: self:
            let
              others = nixpkgs.lib.filterAttrs (name: node: node.id != self.id) nodes;
            in
            ({ config, pkgs, ... }: {
              environment.systemPackages = [ pkgs.strongswan ];
              networking = {
                firewall.enable = false;
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
                others;
              systemd.network.networks = pkgs.lib.mapAttrs
                (name: node: {
                  inherit name;
                })
                others;
              /*
              services.strongswan-swanctl = {
                enable = true;
                swanctl = {
                  connections = connections "node1";
                  inherit secrets;
                };
              };
              */
            }))
          nodes;
      testScript = ''
        node1.wait_for_unit("network-online.target")
        print(node1.succeed("ip a"))
      '';
    };
  };
}
