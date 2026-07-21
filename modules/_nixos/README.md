# Framework Desktop

## Hardware Specifications

| Component | Detail |
|-----------|--------|
| **Machine** | Framework Desktop |
| **CPU** | AMD Ryzen AI Max+ 395 (32-core, Zen 5) |
| **GPU** | AMD Radeon 8060S (integrated, RDNA 3.5 / Strix Point / gfx1151) |
| **NPU** | AMD XDNA 2 (Ryzen AI NPU) |
| **RAM** | 128 GB |
| **Storage** | Single NVMe SSD |
| **Boot** | UEFI, systemd-boot |
| **Audio** | Onboard (AMD audio controller) |

### GPU Notes

The Radeon 8060S is an integrated GPU on the Strix Point (gfx1151) architecture. It requires:
- **Kernel ≥ 6.14** for full support (current: 6.18.19)
- **ROCm environment overrides**: `HSA_OVERRIDE_GFX_VERSION="11.5.1"`, `HCC_AMDGPU_TARGET="gfx1151"`
- **`btop-rocm`** for monitoring (ROCm-aware btop)

### NPU Notes

The AMD XDNA 2 NPU is configured via the `nix-amd-ai` flake input with lemonade support. See `den.aspects.lemonade` in `modules/den.nix` for details. The NPU is still in early NixOS support — check the [nix-amd-ai repository](https://github.com/noamsto/nix-amd-ai) for updates.

---

## Disk Layout

The system uses a single NVMe drive with LUKS encryption and btrfs subvolumes:

```
/dev/nvme0n1
|-- /dev/nvme0n1p1  (vfat, /boot)      # EFI system partition
|-- /dev/nvme0n1p2  (LUKS encrypted)   # LUKS container
    |-- @          (btrfs, mapped to /)
    |-- @home      (btrfs, mapped to /home)
```

LUKS UUID: `luks-73982fd7-f423-475c-972e-83a2f8de521a`

### btrfs subvolumes

| Subvolume | Mount Point | Options |
|-----------|-------------|---------|
| `@` | `/` | `subvol=@` |
| `@home` | `/home` | `subvol=@home` |

### Creating additional subvolumes (e.g., for snapshots)

```bash
# Mount the LUKS device
sudo cryptsetup open /dev/disk/by-uuid/73982fd7-... luks-73982fd7-...

# Create new subvolume
sudo mount /dev/mapper/luks-73982fd7-... /mnt
sudo btrfs subvolume create /mnt/@snapshots

# Add to hardware-configuration.nix
# fileSystems."/.snapshots" = {
#   device = "/dev/mapper/luks-73982fd7-...";
#   fsType = "btrfs";
#   options = [ "subvol=@snapshots" ];
# };
```

---

## 🔐 Disk Encryption & TPM 2.0

This machine uses **LUKS** disk encryption on the main NVMe drive (`/dev/nvme0n1p2`), backed by the **TPM 2.0** chip for passwordless booting.

### NixOS Configuration

The following options must be present to enable the TPM 2.0 stack and systemd-based unlocking during the initrd phase:

```nix
boot.initrd.systemd.enable = true;
boot.initrd.systemd.enableTpm2 = true;
security.tpm2.enable = true;
```

### TPM Enrollment & BIOS Updates

The TPM "seals" the encryption key against specific hardware states (PCRs). Updates to the Framework BIOS/Firmware change PCR 0, which will trigger a prompt for the manual LUKS passphrase. To re-enroll the TPM after an update:

1. Boot using your manual passphrase.
2. Wipe the existing (broken) TPM token:
    ```bash
    sudo systemd-cryptenroll /dev/nvme0n1p2 --wipe-slot=tpm2
    ```
3. Re-enroll the new hardware state (PCR 0 for BIOS, PCR 7 for Secure Boot):
    ```bash
    sudo systemd-cryptenroll --tpm2-device=auto --tpm2-pcrs=0+7 /dev/nvme0n1p2
    ```

> [!IMPORTANT]
> Always keep your manual LUKS passphrase in a secure password manager. The TPM is a convenience layer, not a replacement for your master key.

---

## References

- [Framework Desktop](https://frame.work/desktop)
- [tpm2-boot-still-ask-passphrase](https://discourse.nixos.org/t/tpm2-boot-still-being-asked-for-a-passphrase/49132)
- [TPM - NixOS Wiki](https://nixos.wiki/wiki/TPM)
- [nix-amd-ai](https://github.com/noamsto/nix-amd-ai) — AMD NPU NixOS support
