# SPDX-license-identifier: Apache-2.0
##############################################################################
# Copyright (c) 2020
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License, Version 2.0
# which accompanies this distribution, and is available at
# http://www.apache.org/licenses/LICENSE-2.0
##############################################################################

build:
	@docker-compose build --compress --force-rm
	@docker image prune --force
deploy: undeploy
	@docker-compose up --force-recreate --detach --no-build
logs:
	@docker-compose logs --follow
undeploy:
	@docker-compose down --remove-orphans
redeploy: undeploy deploy
