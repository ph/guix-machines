(define-module (ph disks)
  #:use-module (guix gexp) 
  #:use-module (gnu packages linux) 
  #:use-module (gnu) 
  #:export (btrfs-maintenance-jobs
	    btrfs-maintenance-service))

(use-service-modules mcron)

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

(define (btrfs-maintenance-service mount-points)
  (service mcron-service-type
	   (mcron-configuration
	    (jobs
	     (apply append (map btrfs-maintenance-jobs mount-points))))))
