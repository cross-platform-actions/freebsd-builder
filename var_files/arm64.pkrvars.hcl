architecture = "arm64"
image_architecture = "arm64-aarch64"
qemu_architecture = "aarch64"
pkg_site_architecture = "aarch64"
machine_type = "virt,highmem=off" // highmem=off if reqiured for enabling hardware acceleration on Apple Silicon
cpu_type = "cortex-a57"
firmware = "edk2-aarch64-code.fd"
memory = 3072 // max memory when hardware acceleration on Apple Silicon is enabled
