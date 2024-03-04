# Use Nvidia CUDA base image
FROM nvidia/cuda:11.8.0-cudnn8-runtime-ubuntu22.04 as base

# Prevents prompts from packages asking for user input during installation
ENV DEBIAN_FRONTEND=noninteractive
# Prefer binary wheels over source distributions for faster pip installations
ENV PIP_PREFER_BINARY=1
# Ensures output from python is printed immediately to the terminal without buffering
ENV PYTHONUNBUFFERED=1 

# Install Python, git and other necessary tools
RUN apt-get update && apt-get install -y \
    python3.10 \
    python3-pip \
    git \
    wget \
    ffmpeg

# Clean up to reduce image size
RUN apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Clone ComfyUI repository
RUN git clone https://github.com/comfyanonymous/ComfyUI.git /comfyui

RUN git clone https://github.com/ltdrdata/ComfyUI-Impact-Pack.git /comfyui/custom_nodes/ComfyUI-Impact-Pack
RUN git clone https://github.com/ltdrdata/ComfyUI-Inspire-Pack.git /comfyui/custom_nodes//ComfyUI-Inspire-Pack
RUN git clone https://github.com/Fannovel16/ComfyUI-Frame-Interpolation.git /comfyui/custom_nodes/ComfyUI-Frame-Interpolation
RUN git clone https://github.com/jags111/efficiency-nodes-comfyui.git /comfyui/custom_nodes/efficiency-nodes-comfyui
RUN git clone https://github.com/Derfuu/Derfuu_ComfyUI_ModdedNodes.git /comfyui/custom_nodes/Derfuu_ComfyUI_ModdedNodes
RUN git clone https://github.com/paulo-coronado/comfy_clip_blip_node.git /comfyui/custom_nodes/comfy_clip_blip_node
RUN git clone https://github.com/WASasquatch/was-node-suite-comfyui.git /comfyui/custom_nodes/was-node-suite-comfyui
RUN git clone https://github.com/Kosinkadink/ComfyUI-VideoHelperSuite.git /comfyui/custom_nodes/ComfyUI-VideoHelperSuite

# Change working directory to ComfyUI
WORKDIR /comfyui

### Install ComfyUI dependencies
# Install PyTorch, torchvision, and torchaudio
RUN pip3 install torch torchvision torchaudio --no-cache-dir --index-url https://download.pytorch.org/whl/cu121 --default-timeout=10000

# Install xformers
RUN pip3 install xformers==0.0.21 --no-cache-dir --default-timeout=100000

# Install dependencies from requirements.txt
RUN pip3 install -r requirements.txt --default-timeout=100000

WORKDIR /comfyui/custom_nodes

RUN pip3 install -r ComfyUI-Impact-Pack/requirements.txt --default-timeout=100000
RUN pip3 install -r ComfyUI-Impact-Pack/impact_subpack/requirements.txt --default-timeout=100000
RUN pip3 install -r ComfyUI-Inspire-Pack/requirements.txt --default-timeout=100000
RUN pip3 install -r ComfyUI-Frame-Interpolation/requirements-with-cupy.txt --default-timeout=100000
RUN pip3 install -r efficiency-nodes-comfyui/requirements.txt --default-timeout=100000
RUN python3 -m pip install --upgrade pip setuptools wheel
#RUN pip3 install -r comfy_clip_blip_node/requirements.txt --default-timeout=100000
RUN pip3 install -r was-node-suite-comfyui/requirements.txt --default-timeout=100000
RUN pip3 install -r ComfyUI-VideoHelperSuite/requirements.txt --default-timeout=100000


WORKDIR /comfyui

# Install runpod
RUN pip3 install runpod requests azure-storage-blob

# Download checkpoints/vae/LoRA to include in image
RUN wget -O models/checkpoints/dreamshaperXL_turboDpmppSDE.safetensors https://civitai.com/api/download/models/351306
RUN wget -O models/checkpoints/svd_xt_1_1.safetensors https://qdchatbotstorage.blob.core.windows.net/test/svd_xt_1_1.safetensors
RUN wget -O models/vae/sdxl_vae.safetensors https://qdchatbotstorage.blob.core.windows.net/test/sdxl_vae.safetensors
RUN wget -O models/vae/vae-ft-mse-840000-ema-pruned.ckpt https://qdchatbotstorage.blob.core.windows.net/test/vae-ft-mse-840000-ema-pruned.ckpt

#ADD models/checkpoints/dreamshaperXL_turboDpmppSDE.safetensors models/checkpoints/
#ADD models/checkpoints/mistoonAnime_v20.safetensors models/checkpoints/
#ADD models/checkpoints/svd_xt_1_1.safetensors models/checkpoints/
#ADD models/vae/sdxl_vae.safetensors models/vae/
#ADD models/vae/vae-ft-mse-840000-ema-pruned.ckpt models/vae/
#ADD models/clip/open_clip_pytorch_model.bin models/clip/

# Go back to the root
WORKDIR /

# Add the start and the handler
ADD src/start.sh src/rp_handler.py src/azure_handler.py test_input.json ./
RUN chmod +x /start.sh

# Start the container
CMD /start.sh
