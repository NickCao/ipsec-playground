{
  inputs.nixpkgs.url = "github:NickCao/nixpkgs/nixos-unstable-small";
  outputs = { self, nixpkgs, ... }: rec {
    packages.x86_64-linux.xfirm = nixpkgs.legacyPackages.x86_64-linux.buildGoModule {
      name = "xfirm";
      src = ./xfirm;
      vendorHash = "sha256-3Qc2tNGUtb0nPqp7dKmwzJtncXgN3PGYdwPIX3AK4rg=";
      overrideModAttrs = _: {
        postConfigure = ''
          export GOPROXY=https://goproxy.cn
        '';
      };
    };
    packages.x86_64-linux.ipsec = nixpkgs.legacyPackages.x86_64-linux.nixosTest {
      name = "ipsec";
      nodes =
        let
          remotes = [
            {
              remote_addrs = [ "192.168.1.1" "%any" ];
              remote_port = 500;
              public_key = "MCowBQYDK2VwAyEA0fIFaKz0kB/jlgjHQZLdlfELwUx5W3/mEErkDPRTKgg=";
              mtu = 1400;
              name = "node1";
            }
            {
              remote_addrs = [ "192.168.1.2" "%any" ];
              remote_port = 500;
              public_key = "MCowBQYDK2VwAyEAqLIvzUm/xMgSyDW3EmtOw65zjPuLsN7Pz57fFJiOCsg=";
              mtu = 1400;
              name = "node2";
            }
            {
              remote_addrs = [ "192.168.1.3" "%any" ];
              remote_port = 500;
              public_key = "MCowBQYDK2VwAyEArVLalM1amJ9neWgPb8ACmLUC8CgD/JvT09IlA3PvHDo=";
              mtu = 1400;
              name = "node3";
            }
          ];
          locals = {
            node1 = [{
              local_addrs = [ "%any" ];
              local_port = 0;
              private_key = "MC4CAQAwBQYDK2VwBCIEIMamaugVRsYMY3N2iS5jaxDnnuUzFE6A2sg8dh7WStD1";
              mtu = 1400;
              prefix = "node1";
            }];
            node2 = [{
              local_addrs = [ "%any" ];
              local_port = 0;
              private_key = "MC4CAQAwBQYDK2VwBCIEIBujPwQglT7ZgM7MBXM9SNXax5ClhEj3bysEdlFbt/nq";
              mtu = 1400;
              prefix = "node2";
            }];
            node3 = [{
              local_addrs = [ "%any" ];
              local_port = 0;
              private_key = "MC4CAQAwBQYDK2VwBCIEIMqyIbIcIWt09kAXfDm/XLbsSJQQykTgP2u3EiszHxgn";
              mtu = 1400;
              prefix = "node3";
            }];
          };
          mkConfig = name: (builtins.toFile "xfirm.conf" (builtins.toJSON {
            inherit remotes;
            locals = locals.${name};
          }));
        in
        nixpkgs.lib.mapAttrs
          (name: cfg: ({ config, pkgs, ... }: {
            boot.kernel.sysctl = {
              "net.ipv6.conf.default.forwarding" = 1;
              "net.ipv4.conf.default.forwarding" = 1;
              "net.ipv6.conf.all.forwarding" = 1;
              "net.ipv4.conf.all.forwarding" = 1;
            };
            environment.systemPackages = [ pkgs.strongswan pkgs.iperf3 pkgs.mtr ];
            services.strongswan-swanctl.enable = true;
            systemd.services.xfirm = {
              path = [ pkgs.iproute2 ];
              wantedBy = [ "multi-user.target" ];
              after = [ "strongswan-swanctl.service" ];
              serviceConfig.RemainAfterExit = true;
              script = ''
                ip link add link1 type xfrm dev lo if_id 0x1
                ip link add link2 type xfrm dev lo if_id 0x2
                ip link add link3 type xfrm dev lo if_id 0x3
                ip link set link1 multicast on up
                ip link set link2 multicast on up
                ip link set link3 multicast on up
                ${packages.x86_64-linux.xfirm}/bin/xfirm -config ${mkConfig name}
              '';
            };
          }))
          locals;
      testScript = ''
        start_all()
        node1.wait_for_unit("xfirm.service")
        print(node1.succeed("swanctl --list-conns"))
        print(node1.succeed("ping -c 10 ff02::1%link2"))
        node1.succeed("sleep 10")
      '';
    };
  };
}
