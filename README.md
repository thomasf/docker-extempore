# Docker Extempore

This is just a slightly different version of https://github.com/benswift/docker-extempore


**Plans**:

* Have tagged releases @ dockerhub
* Docker compose configuration for quick development
* Some utility to extract/configure the emacs stuff thats inside the image.

## Using docker

**Build**:

```
docker build -t thomasf/extempore .
```

**Run**:

```
docker run --rm -t -i -p 7098:7098 -p 7099:7099 --privileged thomasf/extempore
```

## Using docker-compose

**Build**:

```
docker-compose build
```

**Run**:
```
docker-compose up -d; docker-compose logs
```
