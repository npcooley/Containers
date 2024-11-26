ESM on the OSG
================
Nicholas P. Cooley, Department of Biomedical Informatics, University of
Pittsburgh
2024-11-26

# This is a work in progress…

ESM3 seems fine, but if you’re like me and an R user and an OSG user,
it’s not the simplest tool to deploy in a distributed manner for testing
and production. This repo contains a dockerfile for running ESM3 on the
grid in an R friendly environment and some simple instructions.

## First things first

Deploying ESM3 on the OSPool relies, to some extent, on a static version
of a model that can be distributed in a manner that gives a user
assurance that the model is not changing behind the scenes as they’re
pulling it from wherever it lives. Currently ESM3 has an open model
maintained on huggingface.

If you want to do this in a docker container, you just need to ensure
you mount a directory to send the model back to your local environment.

``` bash
# pull a model to the docker container and dump it back to a local directory
# step one: spin up your docker container
docker run -it --rm -v <some_local_dir>:<some_container_directory> npcooley/esm:0.0.1
```

Get the model.

``` python
# pull a model to the docker container and dump it back to a local directory
# step two: get the model, this is just directly from the ESM folks' tutorials

from huggingface_hub import login
from esm.models.esm3 import ESM3
from esm.sdk.api import ESM3InferenceClient, ESMProtein, GenerationConfig

# Will instruct you how to get an API key from huggingface hub, make one with "Read" permission.
login()

# This will download the model weights and instantiate the model on your machine.
# all my local work is on a mac, so no CUDA for me :(
model: ESM3InferenceClient = ESM3.from_pretrained("esm3_sm_open_v1").to("cpu") # or "cuda"
```

Create a tarball of the cache, move it to the mounted volume and you
will now be able to distribute the tarball as you would any normal large
file within the OSPool.

``` bash
# pull a model to the docker container and dump it back to a local directory
# step three: as of the creation of this document, the model gets stored in '$HOME/.cache'

# if your environment has a different home directory, find it and replace '/root/'
cd /root/.cache
tar czvf cache.tar.gz huggingface # bog standard
# or if we're really worried about space -- disk is cheap on the OSG, but not costless, time and memory are always your biggest pain points
tar cJvf cache.tar.xz huggingface # takes a lot of time, but a smaller tarball
```

From here, you should just be able to unpack this tarball into your
`.cache` directory, and ESM will find it without too much hassle. It is
good practice to scrub your token from the huggingface directory in
`.cache` before you build this tarball.

# Next: examples

Whenever I have time to do this …
