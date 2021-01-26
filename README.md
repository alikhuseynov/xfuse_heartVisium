#### Info
This is an example of using very cool Deep Learning tool - [XFuse](https://github.com/ludvb/xfuse) - to super-resolve Spatial Transcriptomics by fusing H&E image with Spatial data.

#### Overview of ST data analysis approach
##### details are in [R](https://github.com/alikhuseynov/xfuse_heartVisium/blob/main/st_adult_heartLV_git.R) or [Rmd](https://github.com/alikhuseynov/xfuse_heartVisium/blob/main/st_adult_heartLV_git.Rmd) scripts, and [xfuse input file](https://github.com/alikhuseynov/xfuse_heartVisium/blob/main/my-config.toml)
![Spatial approach - overview](https://github.com/alikhuseynov/xfuse_heartVisium/blob/main/visium_sct1.png)

#### XFuse gene-maps on 10X Visium Heart section [publicly available](https://support.10xgenomics.com/spatial-gene-expression/datasets/)
##### instructions to pre-process data are on [xfuse repo](https://github.com/ludvb/xfuse) 
![xfuse on Visium Heart2](https://github.com/alikhuseynov/xfuse_heartVisium/blob/main/visium_sct2.png)

#### XFuse gene-maps on Seurat SCTransformed count data (same heart data)
##### details on SCTransform - [orignal repo](https://github.com/ChristophH/sctransform), [publication](https://genomebiology.biomedcentral.com/articles/10.1186/s13059-019-1874-1), and [Seurat Spatial Vignette](https://satijalab.org/seurat/v3.2/spatial_vignette.html)
![xfuse on Visium Heart3](https://github.com/alikhuseynov/xfuse_heartVisium/blob/main/visium_sct3.png)

#### Other xfuse gene-maps can be found in folders:
[images](https://github.com/alikhuseynov/xfuse_heartVisium/tree/main/images)
and on SCTransformed [images_sct](https://github.com/alikhuseynov/xfuse_heartVisium/tree/main/images_sct)
