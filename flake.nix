{
  inputs.nixpkgs.url = "github:NickCao/nixpkgs/nixos-unstable-small";
  outputs = { self, nixpkgs, ... }: {
    packages.x86_64-linux.ipsec = nixpkgs.legacyPackages.x86_64-linux.nixosTest {
      name = "ipsec";
      nodes =
        let
          nodes = {
            node1 = { addr = "192.168.1.1"; prefix = "100.64.1.0/24"; };
            node2 = { addr = "192.168.1.2"; prefix = "100.64.2.0/24"; };
            node3 = { addr = "192.168.1.3"; prefix = "100.64.3.0/24"; };
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
        {
          node1 = { config, pkgs, ... }: {
            environment.systemPackages = [ pkgs.strongswan ];
            networking.firewall.enable = false;
            systemd.services.create-link = {
              path = [ pkgs.iproute2 ];
              script = ''
                ip link add magic type xfrm dev eth0 if_id 0x1
                ip link set magic up
                ip addr add 192.168.10.1/24 dev magic
              '';
              before = [ "strongswan-swanctl.service" ];
              wantedBy = [ "multi-user.target" ];
            };
            services.strongswan-swanctl = {
              enable = true;
              swanctl = {
                connections = connections "node1";
                inherit secrets;
              };
            };
          };
          node2 = { config, pkgs, ... }: {
            environment.systemPackages = [ pkgs.strongswan ];
            networking.firewall.enable = false;
            systemd.services.create-link = {
              path = [ pkgs.iproute2 ];
              script = ''
                ip link add magic type xfrm dev eth0 if_id 0x1
                ip link set magic up
                ip addr add 192.168.10.2/24 dev magic
              '';
              before = [ "strongswan-swanctl.service" ];
              wantedBy = [ "multi-user.target" ];
            };
            services.strongswan-swanctl = {
              enable = true;
              swanctl = {
                connections = connections "node2";
                inherit secrets;
              };
            };
          };
        };
      testScript = ''
        node1.wait_for_unit("strongswan-swanctl.service")
        node2.wait_for_unit("strongswan-swanctl.service")
        print(node1.succeed("ip xfrm state"))
        print(node1.succeed("ip xfrm policy"))
        print(node1.succeed("swanctl --list-conns"))
        print(node1.succeed("cat /etc/swanctl/swanctl.conf"))
        print(node1.succeed("ping -c 10 192.168.10.2"))
      '';
    };
  };
}
