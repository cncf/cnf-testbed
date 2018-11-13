# Makefile
venv: venv/bin/activate

venv/bin/activate: requirements.txt
	test -d venv || virtualenv -p `which python` venv
	. venv/bin/activate; pip install -r requirements.txt
	touch venv/bin/activate

.PHONY:clean

clean:
	$(RM) -rf venv
	find . -name "*.pyc" -exec $(RM) -rf {} \;
