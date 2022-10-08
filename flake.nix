{
  inputs.nixpkgs.url = "github:NickCao/nixpkgs/nixos-unstable-small";
  outputs = { self, nixpkgs, ... }: {
    packages.x86_64-linux.ipsec = nixpkgs.legacyPackages.x86_64-linux.nixosTest {
      name = "ipsec";
      nodes =
        let
          child = {
            local_ts = [ "0.0.0.0/0" "::/0" ];
            remote_ts = [ "0.0.0.0/0" "::/0" ];
            start_action = "start";
          };
          mkConnection = { remote_addr, local_id, remote_id }: {
            version = 2;
            # local_addrs = [ "192.168.1.1" ];
            remote_addrs = [ remote_addr ];
            if_id_out = "1";
            if_id_in = "1";
            local.main = {
              auth = "psk";
              id = local_id;
            };
            remote.main = {
              auth = "psk";
              id = remote_id;
            };
            children = {
              node2 = child;
            };
          };
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
                connections = {
                  node2 = mkConnection {
                    remote_addr = "192.168.1.2";
                    local_id = "node1@gravity";
                    remote_id = "node2@gravity";
                  };
                };
                secrets = {
                  ike.node2 = {
                    id.main = "node2@gravity";
                    secret = "0sFpZAZqEN6Ti9sqt4ZP5EWcqx";
                  };
                };
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
                connections = {
                  node2 = mkConnection {
                    remote_addr = "192.168.1.1";
                    local_id = "node2@gravity";
                    remote_id = "node1@gravity";
                  };
                };
                secrets = {
                  ike.node1 = {
                    id.main = "node1@gravity";
                    secret = "0sFpZAZqEN6Ti9sqt4ZP5EWcqx";
                  };
                };
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
