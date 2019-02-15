;;;; harmonograph.lisp
;;;; Code for harmonograph project.
;;;; Copyright (c) 2019 Lucas Vieira <lucasvieira@lisp.com.br>
(eval-when (:compile-toplevel)
    (declaim (optimize (space 3)
                       (compilation-speed 0)
                       (debug 0)
                       (safety 0)
                       (speed 3))))

(in-package #:harmonograph)

;; =============

;;; Speeds are actually musical intervals. The points move like
;;; harmonograph patterns:
;; 1/1 => unison
;; 2/1 => octave
;; 3/2 => fifth
;; 4/3 => fourth
;; 5/3 => major sixth
;; 5/4 => major third
;; 6/5 => minor third
;; 8/5 => minor sixth
;; 9/8 => wholetone
;; 3/1 => second overtone

(defparameter *loop-radius* 1/32)
(defparameter *loop-base-speed* 180)
(defparameter *loop-speeds* #(1/1 2/1 3/2 4/3 5/3 5/4 6/5 8/5 9/8 3/1))
(defparameter *loop-angles* #(0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0 0.0))
(defparameter *loop-motion-blur* 50)
(defparameter *motion-blur-factor* 0)

(defstruct vec2 (x 0) (y 0))
(defstruct color (r 1) (g 1) (b 1) (a 1))

(defmacro with-pushed-matrix (&body body)
  `(progn (gl:push-matrix)
	  ,@body
	  (gl:pop-matrix)))

(defun color-from-not-normalized (color-list)
  (make-color :r (/ (car color-list) 256)
	      :g (/ (cadr color-list) 256)
	      :b (/ (caddr color-list) 256)))

(defun loop-color (harmony-speed)
  (color-from-not-normalized
   (case harmony-speed
     (1/1 '(180 72 85))
     (2/1 '(180 108 85))
     (3/2 '(252 252 85))
     (4/3 '(72 180 85))
     (5/3 '(108 180 255))
     (5/4 '(216 108 170))
     (6/5 '(180 144 255))
     (8/5 '(108 180 85))
     (9/8 '(180 108 108))
     (3/1 '(255 255 255)))))

(defun mix-colors (color1 color2)
  (make-color :r (/ (+ (color-r color1) (color-r color2)) 2)
	      :g (/ (+ (color-g color1) (color-g color2)) 2)
	      :b (/ (+ (color-b color1) (color-b color2)) 2)))

(defun colorize (color)
  (gl:color (color-r color) (color-g color) (color-b color)))


(defun draw-loop (position angle-rad color &optional (y-angle-rad angle-rad))
  (with-pushed-matrix
    (colorize color)
    (gl:translate (+ (vec2-x position)
      		     (* *loop-radius*
      			(cos angle-rad)))
      		  (+ (vec2-y position)
      		     (* *loop-radius*
      			(sin y-angle-rad)))
      		  1.0)
    ;; Point
    ;; (gl:begin :points)
    ;; (gl:vertex 0 0)
    ;; (gl:end)

    ;; Dot under aspect ratio (slower)
    (gl:begin :triangle-fan)
    (gl:vertex 0 0)
    (loop for x from 0 to 32
       with step = (/ 360 32)
       do (gl:vertex (* 0.004 (cos (deg->rad (* step x))))
    		     (* 0.004 (sin (deg->rad (* step x))))))
    (gl:end)))

(defun deg->rad (angle)
  (/ (* angle pi) 180.0))


(defun draw ()
  (gl:clear :color-buffer :depth-buffer)
  (gl:accum :return 0.966)
  (gl:clear :accum-buffer)
  (loop for angle across *loop-angles*
     for i from 0
     ;; Draw column
     do (draw-loop (make-vec2 :x -6/8
			      :y (- 5/8 (* 5/32 i)))
		   (deg->rad angle)
		   (loop-color (aref *loop-speeds* i)))
     ;; Draw line
     do (draw-loop (make-vec2 :x (+ -5/8 (* 5/32 i))
			      :y 6/8)
		   (deg->rad angle)
		   (loop-color (aref *loop-speeds* i))))
  ;; Build diagonals
  (loop for y-angle across *loop-angles*
     for j from 0
     do (loop for x-angle across *loop-angles*
	   for i from 0
	   do (draw-loop (make-vec2 :x (+ -5/8 (* 5/32 i))
				    :y (- 5/8 (* 5/32 j)))
			 (deg->rad x-angle)
			 (mix-colors (loop-color (aref *loop-speeds* i))
				     (loop-color (aref *loop-speeds* j)))
			 (deg->rad y-angle))))
  (gl:accum :accum 0.999999))


(let ((last-time 0.0)
      (delta 0.0))
  (defun update ()
    (labels ((update-time ()
	       (let ((current-time (get-time)))
		 (when (> current-time last-time)
		   (psetf last-time current-time
			  delta (- current-time last-time)))))
	     (increase-angle (angle speed)
	       (mod (+ angle (* *loop-base-speed*
				delta
				speed))
		    360)))
      (update-time)
      (loop for i from 0 below (length *loop-angles*)
	 do (setf (aref *loop-angles* i)
		  (increase-angle (aref *loop-angles* i)
      				  (aref *loop-speeds* i)))))))


;; =============

(defparameter *window-size* '(720 720))

(def-key-callback key-callback (window key scancode action mod)
  (declare (ignore window scancode mod))
  (when (and (eq key :escape)
	     (eq action :press))
    (set-window-should-close)))

(defun set-viewport (width height)
  (gl:viewport 0 0 width height)
  (gl:matrix-mode :projection)
  (gl:load-identity)
  (gl:matrix-mode :modelview)
  (gl:load-identity)
  (gl:clear :accum-buffer))

(def-window-size-callback update-viewport (window width height)
  (declare (ignore window))
  (setf *window-size* (list width height))
  (set-viewport width height))


(defun run-app ()
  (with-body-in-main-thread ()
    (with-init-window (:title "Loops"
			      :width (car *window-size*)
			      :height (cadr *window-size*)
			      :resizable nil)
      (setf %gl:*gl-get-proc-address* #'get-proc-address)
      (set-key-callback 'key-callback)
      (set-window-size-callback 'update-viewport)
      (gl:point-size 1)
      (gl:clear-color 0 0 0 0)
      (gl:clear-accum 0 0 0 0)
      (gl:enable :blend)
      (gl:enable :depth-test)
      (gl:depth-func :lequal)
      (gl:blend-func :src-alpha :src1-alpha)
      (loop initially (set-viewport (car *window-size*)
				    (cadr *window-size*))
	 until (window-should-close-p)
	 do (update)
	 do (draw)
	 do (swap-buffers)
	 do (poll-events)))))
