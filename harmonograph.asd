;;;; harmonograph.asd
;;;; Defines the ASDF system for the harmonograph project.
;;;; Copyright (c) 2019 Lucas Vieira <lucasvieira@lisp.com.br>


(asdf:defsystem #:harmonograph
  :description "Shows Lissajous curves like an harmonograph."
  :author "Lucas Vieira <lucasvieira@lisp.com.br>"
  :license  "BSD 2-Clause"
  :version "1.0.0"
  :serial t
  :depends-on (#:cl-glfw3 #:cl-opengl #:trivial-main-thread)
  :components ((:file "package")
               (:file "harmonograph")))
