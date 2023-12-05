(define-module (ph services)
  #:use-module (gnu services)
  #:use-module (gnu services desktop)
  #:use-module (gnu services xorg)
  #:use-module (guix gexp)
  #:use-module (gnu)
  #:use-module (gnu services pm)
  #:use-module (ph nonguix services tailscale)
  #:use-module (ph nonguix tailscale)
  #:use-module (gnu services linux)
  #:use-module (gnu packages linux)
  #:use-module (gnu packages wm)
  #:use-module (gnu packages networking)
  #:use-module (gnu services base)
  #:use-module (gnu services nix)
  #:use-module (gnu services dbus)
  #:export (%my-desktop-services
	    %my-system-services))

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

(define %my-desktop-services
  (modify-services %desktop-services
		   (delete gdm-service-type)
		   (guix-service-type config =>
				      (guix-configuration (inherit config)
							  (discover? #t)
							  (substitute-urls
							   (append (list "https://substitutes.nonguix.org") %default-substitute-urls))
							  (authorized-keys
							   (append (list (local-file "../../files/signing-key-nonguix.pub")
									 (local-file "../../files/babayaga.pub"))
								   %default-authorized-guix-keys))))))


(define %my-system-services
  (append (list
	   (service gnome-desktop-service-type)
	   (service earlyoom-service-type)
	   (service zram-device-service-type
		    (zram-device-configuration
		     (size "32G")
		     (compression-algorithm 'zstd)
		     (priority 100)))
	   (service openssh-service-type)
	   (service tailscaled-service-type) 
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
		       (keyboard-layout
			(keyboard-layout "us" #:options '("ctrl:nocaps")))))))
	   (service docker-service-type)
	   (service pam-limits-service-type
		    (list
		     (pam-limits-entry "@realtime" 'both 'rtprio 99)
		     (pam-limits-entry "@realtime" 'both 'memlock 'unlimited)
		     (pam-limits-entry "*" 'both 'nofile 524288))))
	  %my-desktop-services))


