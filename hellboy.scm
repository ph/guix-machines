(use-modules (gnu packages linux)
	     (gnu)
	     (nongnu packages linux)
	     (nongnu system linux-initrd)
	     (ph allpackages)
	     (ph base) 
	     (ph disks)
	     (ph services)
	     (srfi srfi-1))

(use-service-modules
 desktop
 networking
 linux)

(operating-system
 (kernel linux)
 (initrd microcode-initrd)
 (firmware (list linux-firmware sof-firmware))
 (locale "en_CA.utf8")
 (timezone "America/Toronto")
 (keyboard-layout (keyboard-layout "us"
                                   #:options '("ctrl:nocaps")))
 (host-name "hellboy.local.heyk.org")
 (groups (cons (user-group (system? #t) (name "realtime"))
	       %base-groups))
 (users (cons* %me
	       %base-user-accounts))
 (packages (append %my-packages
		   %base-packages))
 (services
  (append (list
	   (service bluetooth-service-type
		    (bluetooth-configuration
		     (name host-name)
		     (auto-enable? #t)))
	   (btrfs-maintenance-service (list "/")))
	  %my-system-services))
 (name-service-switch %mdns-host-lookup-nss)
 (bootloader (bootloader-configuration
              (bootloader grub-efi-bootloader)
              (targets (list "/boot/efi"))
              (keyboard-layout keyboard-layout)))

 (mapped-devices (list (mapped-device
                        (source (uuid
                                 "2a0eb663-b132-4142-bf7d-3651f8c714e9"))
                        (target "cryptroot")
                        (type luks-device-mapping))))

 (file-systems (cons* (file-system
		       (mount-point "/")
		       (device "/dev/mapper/cryptroot")
		       (type "btrfs")
		       (dependencies mapped-devices))
                      (file-system
		       (mount-point "/boot/efi")
		       (device (uuid "3C94-BA21"
                                     'fat32))
		       (type "vfat")) %base-file-systems)))
