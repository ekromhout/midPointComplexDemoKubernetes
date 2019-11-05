pipeline {
    agent any
    environment { 
        maintainer = "t"
        imagename = 'm'
        tag = 'l'
    }
    stages {
        stage ('Setting build context') {
            steps {
                script {
                    maintainer = maintain()
                    imagename = imagename()
                    if (env.BRANCH_NAME == "master") {
                       tag = "latest"
                    } else {
                       tag = env.BRANCH_NAME
                    }
                    if (!imagename) {
                        echo "You must define imagename in common.bash"
                        currentBuild.result = 'FAILURE'
                    }
                    sh 'mkdir -p bin'
                    sh 'mkdir -p tmp'
                    dir ('tmp') {
                        git([ url: "https://github.internet2.edu/docker/util.git", credentialsId: "jenkins-github-access-token" ])
                        sh 'ls -l'
			sh 'ls -lR ../bin'
			sh 'rm -r ../bin/windows || true'
                        sh 'mv bin/* ../bin/.'
                    }
                    // Build and test scripts expect that 'tag' is present in common.bash. This is necessary for both Jenkins and standalone testing.
                    // We don't care if there are more 'tag' assignments there. The latest one wins.
                    sh "echo >> common.bash ; echo \"tag=\\\"${tag}\\\"\" >> common.bash ; echo common.bash ; cat common.bash"
                }  
            }
        }    
        stage ('Build') {
            steps {
                script {
                    try {
                        // using custom ./build.sh instead of bin/rebuild.sh because the bin/ version does not support building specific tag yet
                        sh './build.sh -r 2>&1 | tee -a debug ; test ${PIPESTATUS[0]} -eq 0'
                    } catch (error) {
                        def error_details = readFile('./debug')
                        def message = "BUILD ERROR: There was a problem building ${imagename}:${tag}. \n\n ${error_details}"
                        sh "rm -f ./debug"
                        handleError(message)
                    }
                }
            }
        }
        stage ('Test') {
            steps {
                script {
                    try {
                        sh 'echo Docker containers before root tests ; docker ps -a'		// temporary
                        sh 'bin/test.sh 2>&1 | tee debug ; test ${PIPESTATUS[0]} -eq 0'
                        sh 'echo Docker containers before compositions tests ; docker ps -a'		// temporary

                        sh '(cd demo/simple ; bats tests ) 2>&1 | tee -a debug ; test ${PIPESTATUS[0]} -eq 0'
                        sh '(cd demo/shibboleth ; bats tests ) 2>&1 | tee -a debug ; test ${PIPESTATUS[0]} -eq 0'
                        sh '(cd demo/postgresql ; bats tests ) 2>&1 | tee -a debug ; test ${PIPESTATUS[0]} -eq 0'
                        //sh '(cd demo/complex ; bats tests ) 2>&1 | tee -a debug ; test ${PIPESTATUS[0]} -eq 0'
                    } catch (error) {
                        def error_details = readFile('./debug')
                        def message = "BUILD ERROR: There was a problem testing ${imagename}:${tag}. \n\n ${error_details}"
                        sh "rm -f ./debug"
                        handleError(message)
                    }
                }
            }
        }
        stage ('Push') {
            steps {
                script {
                    docker.withRegistry('https://registry.hub.docker.com/', "dockerhub-$maintainer") {
                        def baseImg = docker.build("$maintainer/$imagename")
                        baseImg.push("$tag")
                    }
                }
            }
        }
        stage ('Notify') {
            steps {
                echo "$maintainer"
                slackSend color: 'good', message: "$maintainer/$imagename:$tag pushed to DockerHub"
            }
        }
    }
    post { 
        always { 
            echo 'Done Building.'
        }
        failure {
            // slackSend color: 'good', message: "Build failed"
            handleError("BUILD ERROR: There was a problem building ${maintainer}/${imagename}:${tag}.")
        }
    }
}


def maintain() {
    def matcher = readFile('common.bash') =~ 'maintainer="(.+)"'
    matcher ? matcher[0][1] : 'tier'
}

def imagename() {
    def matcher = readFile('common.bash') =~ 'imagename="(.+)"'
    matcher ? matcher[0][1] : null
}

def handleError(String message) {
    echo "${message}"
    currentBuild.setResult("FAILED")
    slackSend color: 'danger', message: "${message}"
    sh 'exit 1'
}
