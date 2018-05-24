# Multiarchitecture Kolibri for docker
Kolibri docker image (Tested on amd64, armv, arm64)
## How to use ?

1. Multiarchitecture Docker image is already present at docker hub at `treehouses/kolibri`. Replace `/data/save/location` with the path where you want to save the database and files. If this path is empty then default database and files will be initialized.

	```
 	docker run -v /data/save/location:/root/.kolibri -p 8080:8080 treehouses/kolibri
 	```

## How to compile image yourself ?

1. Clone this repository and `cd` to the folder.
2. Build a docker image:

	```
 	docker build -t kolibri:v1 .
 	```
 
 3. Create a docker container. Replace `/data/save/location` with the path where you want to save the database and files. If this path is empty then default database and files will be initialized.

 	```
 	docker run -v /data/save/location:/root/.kolibri -p 8080:8080 kolibri:v1
 	```

