:: Build docker image for arm64 (raspberry pi, new macbooks...)

docker buildx build -f production.Dockerfile --platform linux/arm64 -t forecast_checker-arm64 .
docker image tag forecast_checker-arm64:latest 192.168.1.199:5000/deevis/forecast_checker-arm64:latest
docker image push 192.168.1.199:5000/deevis/forecast_checker-arm64:latest
