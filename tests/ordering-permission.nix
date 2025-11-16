pkgs:
{
  name = "preservation-ordering-permission";

  nodes.machine =
    { pkgs, ... }:
    {
      imports = [ ../module.nix ];

      preservation = {
        enable = true;
        preserveAt."/state" = {
          directories = [
            {
              directory = "/var/lib/test";
              user = "test";
              group = "test";
              mode = "0640";
            }
          ];
          files = [
            { file = "/etc/machine-id"; inInitrd = true; }
          ];
        };
      };

      systemd.services.test-service = {
        script = ''
          expected="0640 test test"
          actual=$(stat -c '0%a %U %G' /var/lib/test)

          echo "expected: $expected"
          echo "actual: $actual"

          if [ "$actual" != "$expected" ]; then
            exit 1
          else
            exit 0
          fi
        '';
        unitConfig = {
          DefaultDependencies = false;
          RequiresMountsFor = "/var/lib/test";
        };
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        wantedBy = [ "multi-user.target" ];
      };

      users.users.test = {
        isSystemUser = true;
        group = "test";
      };

      users.groups.test = { };

      systemd.suppressedSystemUnits = [ "systemd-machine-id-commit.service" ];

      boot.initrd.systemd.enable = true;

      networking.useNetworkd = true;

      virtualisation = {
        memorySize = 2048;
        # separate block device for preserved state
        emptyDiskImages = [ 23 ];
        fileSystems."/state" = {
          device = "/dev/vdb";
          fsType = "ext4";
          neededForBoot = true;
          autoFormat = true;
        };
      };

    };

  testScript =
    { nodes, ... }:
    # python
    ''
      machine.start(allow_reboot=True)
      machine.wait_for_unit("default.target")

      print(machine.succeed("journalctl -xeu test-service.service"))
      machine.require_unit_state("test-service.service", "active")

      machine.shutdown()
    '';
}
