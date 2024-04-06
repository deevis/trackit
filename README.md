# Trackit

A Ruby on Rails web application that monitors weather forecasts, Zillow pricing, Best Buy pricing, Nerd Wallet mortgage rates, AAA gas prices, and Gold/Silver premium markups.

## Prerequisites

- Ruby 3.1.2
- Rails 7


## To build/install locally

```
cd myprojects
git clone https://github.com/deevis/trackit.git
cd trackit
bundle install
rails db:create
rails db:migrate
rails s
```

## After adding new models, please annotate

```
 annotate --models
 ```
 
## Deploy docker container

### Powershell - arm64 target  (raspberry pi, new macbooks...)

```
docker buildx build -f production.Dockerfile --platform linux/arm64 -t trackit-arm64 .
docker image tag vidsquid-arm64:latest 192.168.0.43:5000/deevis/trackit-arm64:latest
docker image push 192.168.0.43:5000/deevis/trackit-arm64:latest
```

or for legacy container named `forecast_checker`

```
docker buildx build -f production.Dockerfile --platform linux/arm64 -t forecast_checker-arm64 .
docker image tag forecast_checker-arm64:latest 192.168.1.199:5000/deevis/forecast_checker-arm64:latest
docker image push 192.168.1.199:5000/deevis/forecast_checker-arm64:latest
```

### Branches

- main



