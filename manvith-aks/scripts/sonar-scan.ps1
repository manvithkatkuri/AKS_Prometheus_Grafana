docker run -d --name sonarqube -p 9000:9000 sonarqube:9.9-community

docker run --rm `
  -e SONAR_HOST_URL=http://host.docker.internal:9000 `
  -e SONAR_TOKEN=$env:SONAR_TOKEN `
  -v ${PWD}/test/frontend:/usr/src `
  sonarsource/sonar-scanner-cli --% `
  -Dsonar.projectKey=image-app-frontend `
  -Dsonar.projectName=manvith-sonar-frontend `
  -Dsonar.sources=.

docker run --rm `
  -e SONAR_HOST_URL=http://host.docker.internal:9000 `
  -e SONAR_TOKEN=$env:SONAR_TOKEN `
  -v ${PWD}/test/backend-a:/usr/src `
  sonarsource/sonar-scanner-cli --% `
  -Dsonar.projectKey=image-app-backend-a `
  -Dsonar.projectName=manvith-sonar-backend-a `
  -Dsonar.sources=.

docker run --rm `
  -e SONAR_HOST_URL=http://host.docker.internal:9000 `
  -e SONAR_TOKEN=$env:SONAR_TOKEN `
  -v ${PWD}/test/backend-b:/usr/src `
  sonarsource/sonar-scanner-cli --% `
  -Dsonar.projectKey=image-app-backend-b `
  -Dsonar.projectName=manvith-sonar-backend-b `
  -Dsonar.sources=.
