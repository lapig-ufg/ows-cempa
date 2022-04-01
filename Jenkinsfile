    node {
        
    load "$JENKINS_HOME/.envvars"
    def exists=fileExists "src/server/package-lock.json"
    def application_name= "ows-cempa"

        stage('Checkout') {
            git branch: 'main',
            url: 'https://github.com/lapig-ufg/ows-cempa.git'
        }
        stage('Validate') {
            sh 'git pull origin main'

        }
        stage('SonarQube analysis') {

		def scannerHome = tool 'sonarqube-scanner';
                    withSonarQubeEnv("sonarqube") {
                    sh "${tool("sonarqube-scanner")}/bin/sonar-scanner \
                    -Dsonar.projectKey=ows-cempa\
                    -Dsonar.sources=. \
                    -Dsonar.css.node=. \
                    -Dsonar.host.url=$SonarUrl \
                    -Dsonar.login=$SonarKeyProject"
                    }
        }
        stage('Build') {
                        //INSTALL NVM BINARY AND INSTALL NODE VERSION AND USE NODE VERSION
                        nvm(nvmInstallURL: 'https://raw.githubusercontent.com/creationix/nvm/master/install.sh', 
                        nvmIoJsOrgMirror: 'https://iojs.org/dist',
                        nvmNodeJsOrgMirror: 'https://nodejs.org/dist', 
                        version: NODE_VERSION) {
                        //BUILD APPLICATION 
                        echo "Build main site distribution"
                        sh "npm set progress=false"
                        if (exists) {
                            echo 'Yes'
                            sh "cd src/server && npm ci" 
                        } else {
                            echo 'No'
                            sh "cd src/server && npm install" 
                        }
                
                }
        }
        stage('Building Image') {
            dockerImage = docker.build registryprod + "/$application_name:$BUILD_NUMBER", "--build-arg  --no-cache -f Dockerfile ."
        }
        stage('Push Image to Registry') {
            
            docker.withRegistry( "$Url_Private_Registry", "$registryCredential" ) {
            dockerImage.push("${env.BUILD_NUMBER}")
            dockerImage.push("latest")
                        
                }   
                
            }
        stage('Removing image Locally') {
            sh "docker rmi $registryprod/$application_name:$BUILD_NUMBER"
            sh "docker rmi $registryprod/$application_name:latest"
        }

        stage ('Pull imagem on Dev') {
        sshagent(credentials : ['KEY_FULL']) {
            sh "$SERVER_PROD_SSH 'docker pull $registryprod/$application_name:latest'"
                }
            
        }
        stage('Deploy container on DEV') {
                
                        configFileProvider([configFile(fileId: "$File_Json_Id_OWS_CEMPA_PROD", targetLocation: 'container-ows-cempa-deploy-prod.json')]) {

                            def url = "http://$SERVER_PROD/containers/$application_name?force=true"
                            def response = sh(script: "curl -v -X DELETE $url", returnStdout: true).trim()
                            echo response

                            url = "http://$SERVER_PROD/containers/create?name=$application_name"
                            response = sh(script: "curl -v -X POST -H 'Content-Type: application/json' -d @container-ows-cempa-deploy-prod.json  -s $url", returnStdout: true).trim()
                            echo response
                        }
    
            }            
        stage('Start container on DEV') {

                        final String url = "http://$SERVER_PROD/containers/$application_name/start"
                        final String response = sh(script: "curl -v -X POST -s $url", returnStdout: true).trim()
                        echo response                    
                    
                
            }                      
        stage('Send message to Discord') {
            
                        //SEND DISCORD NOTIFICATION
                        def discordImageSuccess = 'https://www.jenkins.io/images/logos/formal/256.png'
                        def discordImageError = 'https://www.jenkins.io/images/logos/fire/256.png'

                        def discordDesc =
                                "Result: ${currentBuild.currentResult}\n" +
                                        "Project: Nome projeto\n" +
                                        "Commit: Quem fez commit\n" +
                                        "Author: Autor do commit\n" +
                                        "Message: mensagem do changelog ou commit\n" +
                                        "Duration: ${currentBuild.durationString}"

                                        //Variaveis de ambiente do Jenkins - NOME DO JOB E NÚMERO DO JOB
                                        def discordFooter = "${env.JOB_BASE_NAME} (#${BUILD_NUMBER})"
                                        def discordTitle = "${env.JOB_BASE_NAME} (build #${BUILD_NUMBER})"
                                        def urlWebhook = "https://discord.com/api/webhooks/$DiscordKey"

                        discordSend description: discordDesc,
                                footer: discordFooter,
                                link: env.JOB_URL,
                                result: currentBuild.currentResult,
                                title: discordTitle,
                                webhookURL: urlWebhook,
                                successful: currentBuild.resultIsBetterOrEqualTo('SUCCESS'),
                                thumbnail: 'SUCCESS'.equals(currentBuild.currentResult) ? discordImageSuccess : discordImageError              
                    
            }         
        
        
        
        }
