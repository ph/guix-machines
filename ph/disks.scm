(define-module (ph disks)
  #:use-module (guix gexp)
  #:use-module (guix packages linux))

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
