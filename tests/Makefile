.DEFAULT:
help:
	@echo Usage:
	@echo ' ' make local - Launches server, and run all tests locally.
	@echo ' ' make ci - Launches server, and run all tests in a container.
	@echo ' ' make [moduleName] - Runs a specific test module.
	@echo ' ' make [moduleName]:\'description\' - Runs a specific test module, where the the case matches the description.
	@echo ' ' make runserver - Launches the server.
	@echo ' ' make clean - Stops the server.

local: runserver waitforserver
	$(MAKE) 'test_*'
	$(MAKE) clean

waitforserver:
	sleep 1

runserver:
	docker-compose up --build -d server

ci: runserver
	docker-compose build test
	docker-compose run --rm test bash -c "dart test -j1 tests/test_*.dart"
	$(MAKE) clean

clean:
	docker-compose down -v


target %: argv = $(subst :, , $(MAKECMDGOALS))
target %: module = $(word 1, $(argv))
target %: pattern = $(wordlist 2, 99, $(argv))
%:
	@echo module=$(module)
	@echo pattern=$(pattern)
	cd .. &&\
	dart test -j1 tests/$(module).dart --name '$(pattern)'
