# This builds an application for the project.
# Please make sure that you input the Quicklisp DISTS directory.
# Also, make sure you have buildapp installed.

DISTS=~/quicklisp/dists
OUTPUT=bin/harmonograph

.PHONY: folders clean

all: folders $(OUTPUT)

folders:
	mkdir -p bin

clean:
	rm -f $(OUTPUT)

$(OUTPUT): harmonograph.asd package.lisp harmonograph.lisp
	buildapp --output $(OUTPUT)         \
			 --compress-core            \
			 --load-system harmonograph \
			 --eval '(defun main (args) (declare (ignore args)) (harmonograph:run-app))' \
			 --entry main               \
			 --asdf-path ./             \
			 --asdf-tree $(DISTS)

