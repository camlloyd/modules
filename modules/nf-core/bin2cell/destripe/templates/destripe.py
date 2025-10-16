import bin2cell as b2c
import spatialdata_io
import yaml

VERSION = "0.3.3"

adata = spatialdata_io.visium_hd("${h5ad}")
prefix = "${prefix}"

b2c.destripe(adata)
adata.write_h5ad(f"{prefix}.h5ad")

# Versions

versions = {"${task.process}": {"bin2cell": VERSION}}

with open("versions.yml", "w") as f:
    yaml.dump(versions, f)
