;;;; package.lisp
;;;; Defines packages for harmonograph project.
;;;; Copyright (c) 2019 Lucas Vieira <lucasvieira@lisp.com.br>


(defpackage #:harmonograph
  (:use #:cl #:cl-glfw3 #:trivial-main-thread)
  (:export #:run-app))
