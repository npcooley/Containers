# this container inherits its entry point from the rocker container

# build for multiple platforms:
# docker buildx build --platform linux/amd64,linux/arm64 -t npcooley/turkuhackathon:x.y.z .

# use: docker run -it --rm npcooley/turkuhackathon:x.y.z bash
# spin it up interactively for testing and things

# very basic server instance setup:
# --name provides the container name, not the user for the server
# docker run -d \
#   -p 8787:8787 \
#   -e PASSWORD=thisisatest \
#   --name testcontainer \
#   npcooley/turkuhackathon:x.y.z

# other args:
# inherit gpu devices from the host:
# --gpus all

# inherit the icd files from the host:
# -v /etc/OpenCL/vendors/:/etc/OpenCL/vendors/

# log in to the instance
# http://localhost:8787

FROM rocker/rstudio:latest

RUN apt-get update && apt-get install -y \
  bash-completion \
  opencl-headers \
  ocl-icd-libopencl1 \
  ocl-icd-opencl-dev \
  clinfo \
  build-essential \
  software-properties-common \
  nano \
  git \
  curl \
  && apt-get -y autoclean \
  && rm -rf /var/lib/apt/lists/*

RUN Rscript -e "install.packages('OpenCL', type = 'source')"

# -p creates intermediate directories if they do not exist
RUN mkdir -p /home/rstudio/.config/rstudio
COPY rstudio-prefs.json /home/rstudio/.config/rstudio/rstudio-prefs.json

