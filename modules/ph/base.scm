(define-module (ph base)
  :use-module (gnu system shadow)
  :use-module (gnu packages shells)
  :use-module (guix gexp)
  :export (%me))

(define %me
  (user-account
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
      "realtime"))))
