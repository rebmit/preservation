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
          directories = [ "/var/tmp" ];
          files = [
            { file = "/etc/machine-id"; inInitrd = true; }
          ];
        };
      };

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

      actual = machine.succeed("systemctl status systemd-tmpfiles-setup.service")
      print(actual)

      expected = "Duplicate line"
      t.assertNotIn(expected, actual, "duplication lines in systemd tmpfiles")

      machine.shutdown()
    '';
}
