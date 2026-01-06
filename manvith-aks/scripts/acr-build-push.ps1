az acr login --name manvithacr

docker build -t manvithacr.azurecr.io/frontend:latest ./test/frontend
docker push manvithacr.azurecr.io/frontend:latest

docker build -t manvithacr.azurecr.io/backend-a:latest ./test/backend-a
docker push manvithacr.azurecr.io/backend-a:latest

docker build -t manvithacr.azurecr.io/backend-b:latest ./test/backend-b
docker push manvithacr.azurecr.io/backend-b:latest
