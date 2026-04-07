# Framework Desktop


## 🔐 Disk Encryption & TPM 2.0 (NixOS)

This machine uses **LUKS** disk encryption on the main NVMe drive (`/dev/nvme0n1p2`), backed by the **TPM 2.0** chip for passwordless booting. 

### NixOS Configuration
The following options must be present in `configuration.nix` to enable the TPM 2.0 stack and systemd-based unlocking during the initrd phase:

```nix
# Required for modern TPM tools
boot.initrd.systemd.enable = true;
boot.initrd.systemd.enableTpm2 = true;
security.tpm2.enable = true;# Framework Desktop
```

### TPM Enrollment & BIOS Updates
The TPM "seals" the encryption key against specific hardware states (PCRs). Updates to the Framework BIOS/Firmware change PCR 0, which will trigger a prompt for the manual LUKS passphrase. To re-enroll the TPM after an update:

1. Boot using your manual passphrase.
2. Wipe the existing (broken) TPM token:
    ```Bash
    sudo systemd-cryptenroll /dev/nvme0n1p2 --wipe-slot=tpm2
    ```
3. Re-enroll the new hardware state (PCR 0 for BIOS, PCR 7 for Secure Boot):
    ```Bash
    sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+7 /dev/nvme0n1p2
    ```

> [!IMPORTANT]
> Always keep your manual LUKS passphrase in a secure password manager. The TPM is a convenience layer, not a replacement for your master key.



## References

[tpm2-boot-still-ask-passphrase]: https://discourse.nixos.org/t/tpm2-boot-still-being-asked-for-a-passphrase/49132 "Tpm2 boot: still being asked for a passphrase"
[TPM - NixOS Wiki]: https://nixos.wiki/wiki/TPM
