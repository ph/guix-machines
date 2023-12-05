(define-module (ph allpackages)
  #:use-module (gnu packages)
  #:export (%my-packages))

(define %my-packages
  (map specification->package (list
			       "openssh"
			       "nss-certs"
			       "tailscale"
			       "nix"
			       "bluez"
			       "bluez-alsa"
			       "git"
			       "egl-wayland"
			       "libdrm"
			       "mesa"
			       "mesa-utils"
			       "intel-vaapi-driver"
			       "intel-media-driver" 
			       "sway"
			       "chili-sddm-theme"
			       "light"
			       "cups-filters"
			       "hplip-plugin")))
