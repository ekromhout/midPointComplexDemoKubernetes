#!/usr/bin/env bats

load ../common

@test "010 Image is present" {
    docker image inspect tier/midpoint:$tag
}

@test "020 Check basic components" {
    docker run -i $maintainer/$imagename:$tag \
	find \
		/usr/local/bin/startup.sh \
		/opt/midpoint/var/ \
		/etc/shibboleth/ \
		/etc/httpd/
}

@test "100 Cleanup before further tests - demo/simple" {
    docker ps -a
    cd demo/simple ; docker-compose down -v ; true
}

@test "110 Cleanup before further tests - demo/shibboleth" {
    docker ps -a
    cd demo/shibboleth ; docker-compose down -v ; true
}

@test "120 Cleanup before further tests - demo/postgresql" {
    docker ps -a
    cd demo/postgresql ; docker-compose down -v ; true
}

#@test "130 Cleanup before further tests - demo/complex" {
#    docker ps -a
#    cd demo/complex ; docker-compose down -v ; true
#}

# not much more to check here, as we cannot start midpoint container without having a repository
# so continuing with tests in demo/plain directory
