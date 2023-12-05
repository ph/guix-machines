(define-module (hellboy)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages networking)
  #:use-module (gnu packages shells)
  #:use-module (gnu packages wm)
  #:use-module (gnu services dbus)
  #:use-module (gnu services nix)
  #:use-module (gnu services pm)
  #:use-module (gnu system setuid)
  #:use-module (gnu)
  #:use-module (guix channels)
  #:use-module (guix inferior)
  #:use-module (nongnu packages linux)
  #:use-module (nongnu system linux-initrd)
  ;; #:use-module (ph disks)
  #:use-module (srfi srfi-1))

(use-service-modules
 docker
 cups
 desktop
 virtualization
 networking
 linux
 ssh
 mcron
 sddm
 xorg)

(use-package-modules cups)

(okph "ph!")

(define-public (btrfs-maintenance-jobs mount-point)
  (list
   #~(job '(next-hour '(3))
	  (string-append #$btrfs-progs "/bin/btrfs "
			 "scrub " "start " "-c " "idle "
			 #$mount-point))
   #~(job '(next-hour '(5))
	  (string-append #$btrfs-progs "/bin/btrfs "
			 "balance " "start "
			 "-dusage=50,limit=3 "
			 "-musage=50,limit=1 "
			 #$mount-point))))

(define %my-desktop-services
  (modify-services %desktop-services
    (delete gdm-service-type)
    ;; (guix-service-type config =>
    ;;                    (guix-configuration (inherit config)
    ;;                                        (discover? #t)
    ;;                                        (substitute-urls
    ;;                                         (append (list "https://substitutes.nonguix.org") %default-substitute-urls))
    ;;                                        (authorized-keys
    ;;                                         (append (list (local-file "signing-key-nonguix.pub")
    ;;                                                       (local-file "babayaga.pub")) %default-authorized-guix-keys))))
    )
  )

(operating-system
  (kernel linux)
  (initrd microcode-initrd)
  (firmware (list linux-firmware sof-firmware))

  (locale "en_CA.utf8")
  (timezone "America/Toronto")
  (keyboard-layout (keyboard-layout "us"
                                    #:options '("ctrl:nocaps")))
  (host-name "hellboy.local.heyk.org")

  ;; Add the 'realtime' group
  (groups (cons (user-group (system? #t) (name "realtime"))
		%base-groups))

  ;; The list of user accounts ('root' is implicit).
  (users (cons* (user-account
                 (name "ph")
                 (comment "Pier-Hugues Pellerin")
                 (shell (file-append fish "/bin/fish"))
                 (group "users")
                 (home-directory "/home/ph")
                 (supplementary-groups
                  '(
                    "lp"
                    "wheel"
                    "netdev"
                    "docker"
                    "audio"
                    "video"
                    "realtime"
                    )))
		%base-user-accounts))

  (packages (append (list
                     (specification->package "openssh")
                     (specification->package "nss-certs")
                     (specification->package "nix")

                     (specification->package "bluez")
                     (specification->package "bluez-alsa")
                     (specification->package "git")
                     (specification->package "egl-wayland")
                     (specification->package "libdrm")
                     (specification->package "mesa")
                     (specification->package "mesa-utils")
                     (specification->package "intel-vaapi-driver")
                     (specification->package "intel-media-driver") ;; see below for guc
                     ;; https://wiki.archlinux.org/title/intel_graphics

                     ;; display
                     (specification->package "sway")
                     (specification->package "chili-sddm-theme")
                     (specification->package "light")

                     ;; HP printer
                     (specification->package "cups-filters")
		     (specification->package "hplip-plugin"))
                    %base-packages))

  (services
   (append (list

	    (service mcron-service-type
		     (mcron-configuration
		      (jobs (append (btrfs-maintenance-jobs "/")
				    (btrfs-maintenance-jobs "/data")))))

            (service gnome-desktop-service-type)
            (simple-service 'add-extra-hosts
                            hosts-service-type
                            (list (host "192.168.1.152" "panoramix.skunk-salak.ts.net")))
            (service earlyoom-service-type)
            (service zram-device-service-type
                     (zram-device-configuration
                      (size "32G")
                      (compression-algorithm 'zstd)
                      (priority 100)))
            (service openssh-service-type)
            (service cups-service-type
                     (cups-configuration
                      (web-interface? #t)
                      (default-paper-size "A4")
                      (extensions
                       (list cups-filters hplip-minimal))))
            (service tlp-service-type)
            (udev-rules-service 'light light)
            (service thermald-service-type)
            (service nix-service-type)
	    (service qemu-binfmt-service-type
		     (qemu-binfmt-configuration
		      (platforms (lookup-qemu-platforms "aarch64"))))
            (simple-service 'dbus-extras dbus-root-service-type
                            (list blueman))
            (service bluetooth-service-type
                     (bluetooth-configuration
                      (name host-name)
                      (auto-enable? #t)))
	    (service screen-locker-service-type
		     (screen-locker-configuration
		      (name "swaylock")
		      (program (file-append swaylock "/bin/swaylock"))
		      (using-pam? #t)
		      (using-setuid? #t)))
            (service sddm-service-type
                     (sddm-configuration
                      (display-server "wayland")
                      (theme "chili")
                      (xorg-configuration
                       (xorg-configuration
			(keyboard-layout keyboard-layout)))))
            (service docker-service-type)
            (service pam-limits-service-type
                     (list
                      (pam-limits-entry "@realtime" 'both 'rtprio 99)
                      (pam-limits-entry "@realtime" 'both 'memlock 'unlimited)
                      (pam-limits-entry "*" 'both 'nofile 524288))))
           %my-desktop-services))
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
