## load R libs----
suppressPackageStartupMessages({
#library(spaceST) # load this lib first
library(ggplot2)
library(SingleCellExperiment)
library(scater)
library(Seurat)
library(dplyr)
library(png)
library(cowplot)
library(parallel)
library(harmony)
library(cetcolor)
library(gridExtra)
library(plotly)
library(ggridges)
library(jpeg)
library(fields)
library(spatstat)
})


## set_options----
options(max.print=5.5E5) # can visualize huge array
options(scipen = 500) # standard notation vs scientific one!
options(digits = 6) # digits after comma


## load spatial data----
dir_root<-"/10X_data/adult_heart_10xSpatialExample/"
# load using Seurat, make sure the .h5 file has the name "filtered_feature_bc_matrix.h5"
heart_lv<-Load10X_Spatial(dir_root)


## Analysis----
# get Mitochondrial and Ribosomal content
# check
grep(pattern = "^MT-", x = rownames(heart_lv@assays$Spatial@counts), value = T)
grep(pattern = "^RP[SL]", x = rownames(heart_lv@assays$Spatial@counts), value = T)
# add to meta
heart_lv[["percent_mito"]]<-PercentageFeatureSet(heart_lv, pattern = "^MT")
heart_lv[["percent_ribo"]]<-PercentageFeatureSet(heart_lv, pattern = "^RP[SL]")
heart_lv@meta.data %>% str()

# plot QC (raw)----
library(ggridges)
# some examples are here https://cran.r-project.org/web/packages/ggridges/vignettes/introduction.html
# plot advanced QCs for EC data
set.seed(47654)
plot_qc<-lapply(seq(4), function(i) heart_lv@meta.data %>% #sample_frac(1) %>%
ggplot(aes_string(x = c("nCount_Spatial","nFeature_Spatial","percent_mito","percent_ribo")[i], y = c("orig.ident"), fill = c("..x.."))) +
  #geom_density_ridges_gradient(scale = 3e+3,col=alpha("ivory",0)) +
  geom_density_ridges_gradient(scale = c(3e+3,500,7,1.7)[i], aes_string(point_fill = c("..x.."),point_color=c("..x..")),point_size = 0.1,col=alpha("cyan",0),jittered_points = TRUE,position = position_raincloud(height = 0.2)) +
  scale_x_continuous(limits = c(0, max(heart_lv@meta.data[[paste0(c("nCount_Spatial","nFeature_Spatial","percent_mito","percent_ribo")[i])]]))) +
  ggridges::scale_point_color_gradient(low = c("gray14",cet_pal(16, name = "fire")[2:8]),high = cet_pal(16, name = "fire")[9:16],
                                       limits = c(0, max(heart_lv@meta.data[[paste0(c("nCount_Spatial","nFeature_Spatial","percent_mito","percent_ribo")[i])]]))) +
  scale_fill_gradient(name = c("UMIs","Genes","MT (%)", "RB (%)")[i], low = c("gray14",cet_pal(16, name = "fire")[2:8]),high = cet_pal(16, name = "fire")[9:16],limits = c(0, max(heart_lv@meta.data[[paste0(c("nCount_Spatial","nFeature_Spatial","percent_mito","percent_ribo")[i])]]))) +
  ggdark::dark_theme_classic(base_size=25, base_family="Avenir") + theme(legend.text=element_text(size=25),legend.position="right", legend.key.height=grid::unit(2.5,"cm"),
        legend.key.width=grid::unit(0.8,"cm")) + 
  labs(x = c("UMI counts","Gene counts","Mitochondrial content (%)", "Ribosomal content (%)")[i], y = NULL,fill = NA) + coord_flip())
# mito
plot_qc_mt<-heart_lv@meta.data %>%
  ggplot() +
  #stat_summary_hex(mapping = aes_string(x = c("nCount_Spatial"), y=c("nFeature_Spatial"), z=c("percent_mito")),bins = 150,fun = function(i) mean(i)) +
  #scale_fill_gradientn(name = "MT %", colours = c("gray14",cet_pal(16, name = "fire")[2:16])) +
  geom_point(aes_string(x = c("nCount_Spatial"), y=c("nFeature_Spatial"), color=c("percent_mito"))) +
  scale_color_gradientn(name = "MT %", colours = c("gray14",cet_pal(16, name = "fire")[2:16])) +
  ggdark::dark_theme_classic(base_size=25, base_family="Avenir") + theme(legend.text=element_text(size=25),legend.position="right", legend.key.height=grid::unit(2.5,"cm"),
        legend.key.width=grid::unit(0.8,"cm")) + 
  labs(title = NULL, subtitle = NULL, x = "UMIs", y = "Genes",fill = NA)
# ribo
plot_qc_rb<-heart_lv@meta.data %>% 
  ggplot() +
  #stat_summary_hex(mapping = aes_string(x = c("nCount_Spatial"), y=c("nFeature_Spatial"), z=c("percent_ribo")),bins = 150,fun = function(i) mean(i)) +
  #scale_fill_gradientn(name = "RB %", colours = c("gray14",cet_pal(16, name = "fire")[2:16])) +
  geom_point(aes_string(x = c("nCount_Spatial"), y=c("nFeature_Spatial"), color=c("percent_ribo"))) +
  scale_color_gradientn(name = "RB %", colours = c("gray14",cet_pal(16, name = "fire")[2:16])) +
  ggdark::dark_theme_classic(base_size=25, base_family="Avenir") + theme(legend.text=element_text(size=25),legend.position="right", legend.key.height=grid::unit(2.5,"cm"),
        legend.key.width=grid::unit(0.8,"cm")) + 
  labs(title = NULL, subtitle = NULL, x = "UMIs", y = "Genes",fill = NA)
# plot them all
plot_qc[[1]]+plot_qc[[2]]+plot_qc[[3]]+plot_qc[[4]] +
  plot_qc_mt +
  scale_x_continuous(label = scales::label_number(accuracy = 1,suffix = "K", scale = 1/1000)) +
  scale_y_continuous(label = scales::label_number(accuracy = 1,suffix = "K", scale = 1/1000)) + 
  plot_qc_rb +
  scale_x_continuous(label = scales::label_number(accuracy = 1,suffix = "K", scale = 1/1000)) +
  scale_y_continuous(label = scales::label_number(accuracy = 1,suffix = "K", scale = 1/1000))


# SCTransform - normaliaze spots expression/couts----
gc()
heart_lv<-SCTransform(heart_lv, assay = "Spatial", do.correct.umi = T, vars.to.regress = c("percent_mito","percent_ribo"), 
                      verbose = T,return.only.var.genes = FALSE,variable.features.n = 5000)
if (!heart_lv@active.assay=="SCT"){heart_lv@active.assay<-"SCT"}

# write filtered_feature_bc_matrix_sct.h5 matrix (SCT corrected counts)----
# convert SCT count matrix to filtered_feature_bc_matrix_sct.h5
library(DropletUtils)
library(rhdf5)
gc()
write10xCounts(path = paste0(dir_root,"filtered_feature_bc_matrix_sct.h5"), type = c("HDF5"), overwrite = T,version = "3",
               x = GetAssayData(heart_lv,slot = "counts",assay = "SCT"), genome = "GRCh38", 
               barcodes = colnames(GetAssayData(heart_lv,slot = "counts",assay = "SCT")), gene.id = rownames(GetAssayData(heart_lv,slot = "counts",assay = "SCT")))
list.files(paste0(dir_root,"filtered_feature_bc_matrix_sct.h5"),pattern = "_sct.h5")
# check original file structure
h5ls(file = paste0(dir_root,"filtered_feature_bc_matrix.h5"))
# check written file structure
h5ls(file = paste0(dir_root,"filtered_feature_bc_matrix_sct.h5"))

# plot QCs spots + HE----
#DefaultAssay(heart_lv)<-"Spatial"
DefaultAssay(heart_lv)<-"SCT"
st_qcs<-lapply(length(c("nCount_Spatial","nFeature_Spatial","nCount_SCT","nFeature_SCT","percent_mito","percent_ribo")) %>% seq(), function(i) 
  SpatialPlot(heart_lv, image.alpha = 0.7,alpha = c(0.5,1),features = c("nCount_Spatial","nFeature_Spatial","nCount_SCT","nFeature_SCT","percent_mito","percent_ribo")[i],slot = "data",
                   pt.size.factor = 1.6,interactive = F) + theme(legend.position = "right") + 
  #scale_fill_gradientn(name = c("nCount_Spatial","nFeature_Spatial","nCount_SCT","nFeature_SCT","percent_mito","percent_ribo")[i], colours = c("gray14",cet_pal(16, name = "fire")[2:16])) + 
  #..using inferno color scale
  scale_fill_gradientn(name=NULL, colours = c(viridis::viridis(256, option = "inferno"))) + 
  ggdark::dark_theme_classic(base_size=25, base_family="Avenir") + theme(legend.text=element_text(size=25),legend.position="top", legend.key.height=grid::unit(1.2,"cm"),
        legend.key.width=grid::unit(3.6,"cm")) + 
    labs(title = paste0(c("UMI count","Gene count","UMI SCT count","Gene SCT count","% mito","% ribo")[i]),subtitle = NULL, x = "Spots x", y = "Spots y"))
# plot QCs
st_qcs[[1]] # nCount_Spatial
st_qcs[[3]] # nCount_SCT
st_qcs[[2]] # nFeature_Spatial
st_qcs[[4]] # nFeature_SCT

# plot specific genes + HE ----
genes<-c("ACE2","TMPRSS2","CTSB","CTSL","NRP1")
specific_markers<-c(c("NPR3","SMOC1","PECAM1","VWF","CDH5") # arterial and pan-EC markers
                       ,c("SEMA3G","GJA5") # EC5_art
                      ,c("ACKR1","PLVAP") # EC6_ven
                      ,c("RGS5","ABCC9","KCNJ8") # Pericytes markers
                      )
gene_set<-c(genes,specific_markers)
DefaultAssay(heart_lv)<-"SCT"
st_exp<-lapply(length(gene_set) %>% seq(), function(i) 
  SpatialPlot(heart_lv, image.alpha = 0.7,alpha = c(0.3,1),features =gene_set[i],slot = "data",
                   pt.size.factor = 2,interactive = F)) # get data and plots
st_exp<-lapply(length(gene_set) %>% seq(), function(i) st_exp[[i]] + 
  #scale_fill_gradientn(name = NULL, colours = c("gray14",cet_pal(16, name = "fire")[2:16])) + 
  scale_fill_gradientn(name = NULL, colours = c(viridis::viridis(256, option = "inferno")),round(seq(min(st_exp[[i]]$data[[3]]), max(st_exp[[i]]$data[[3]]),0.4),digits = 1)) +
    ggdark::dark_theme_classic(base_size=25, base_family="Avenir") + theme(legend.text=element_text(size=25),legend.position="top", legend.key.height=grid::unit(1.2,"cm"), legend.key.width=grid::unit(4,"cm")) + 
    labs(title = paste0(gene_set[i]," Expression"),subtitle = NULL, x = "Spots x", y = "Spots y"))
# plot st expression
st_exp[[1]] # ACE2
st_exp[[5]] # NRP1
st_exp[[15]] # RGS5

# image processing to get smoothed hotspots of expression----
gene_set
# use "Spatial" or "SCT" assay for calculations
DefaultAssay(heart_lv)<-"Spatial"
# or 
DefaultAssay(heart_lv)<-"SCT"
mat<-lapply(length(gene_set) %>% seq(), function(i) 
  as.image(FetchData(heart_lv,slot = "data",vars = gene_set)[[i]], x=cbind(GetTissueCoordinates(heart_lv)[[2]], max(GetTissueCoordinates(heart_lv)[[1]]) - GetTissueCoordinates(heart_lv)[[1]] + min(GetTissueCoordinates(heart_lv)[[1]])), nx = max(GetTissueCoordinates(heart_lv)[[1]]), ny = max(GetTissueCoordinates(heart_lv)[[1]])))
# function for smoothing the spots
smoothImage<-function(i){
# apply 2D smoothing kernel
gaussianKern <- function(x, sigma=2){1/sqrt(2*pi*sigma^2) * exp(-0.5*(x)^2 / sigma^2)} # eg https://github.com/NCAR/fields/blob/master/vignette/smooth.Rmd
mat_kd<-image.smooth(mat[[i]],kernel.function = gaussianKern,theta = 2.4)
#mat_kd<-image.smooth(mat,theta = 8)
#image.plot(mat_kd,col = c("gray14",cet_pal(16, name = "fire")[2:16]))
mat2<-as.matrix(blur(as.im(mat_kd), kernel = "gaussian", bleed = F, normalise = F, sigma = 8))
#image.plot(mat2 %>% t(), col=c("gray14",cet_pal(16, name = "fire")[2:16]), main="smoothed image")
#str(mat2)
mat_kd$z<-mat2 # add expression to z
return(mat_kd)
}
#mat_kd_list<-mclapply(seq(mat), function(i) smoothImage(i),mc.cores = 22)
mat_kd_list<-lapply(seq(mat), function(i) smoothImage(i))
str(mat_kd_list[[2]])

# inferno colors
st_exp.3D_heatmap_fun<-function(i){
  st_exp.3D_heatmap_list<-plot_ly(x=mat_kd_list[[i]]$x, y=mat_kd_list[[i]]$y, z=mat_kd_list[[i]]$z,type = "heatmap",colors=c(viridis::viridis(256, option = "inferno")))
  st_exp.3D_heatmap_list<-st_exp.3D_heatmap_list %>% colorbar(tickfont=list(color="ivory")) %>% layout(legend = list(font = list(family = "Courier New", size = 20,color="ivory")),
                              xaxis = list(title = paste0("Spots x"), backgroundcolor="black", color="ivory", gridcolor="black",showbackground=T,zerolinecolor="black"), 
                              yaxis = list(title = paste0("Spots y"),backgroundcolor="black", color="ivory", gridcolor="black",showbackground=T,zerolinecolor="black"),
                              annotations = list(x = 0.5,y = 1.04,text = paste0(gene_set[i]),size = 2,xref = "paper",yref = "paper",showarrow = F,
                                                font = list(family = "Courier New", size = 25,color="ivory")),
                              paper_bgcolor = "black", plot_bgcolor = "black")
  return(st_exp.3D_heatmap_list)
}

st_exp.3D_heatmap_list<-lapply(seq(mat_kd_list), function(i) st_exp.3D_heatmap_fun(i))
gene_set # check gene names
st_exp.3D_heatmap_list[[8]] # PECAM1

# inferno colors
st_exp.3D_surface_fun<-function(i){
  st_exp.3D_surface_list<-plot_ly(x=mat_kd_list[[i]]$x, y=mat_kd_list[[i]]$y, z=mat_kd_list[[i]]$z,type = "surface",colors=c(viridis::viridis(256, option = "inferno")))
  st_exp.3D_surface_list<-st_exp.3D_surface_list %>% colorbar(tickfont=list(color="ivory")) %>% layout(legend = list(font = list(family = "Courier New", size = 20,color="ivory")),
                              scene = list(xaxis = list(title = paste0("Spots x"),backgroundcolor="black", color="ivory", gridcolor="black",showbackground=T,zerolinecolor="black"), 
                                           yaxis = list(title = paste0("Spots x"),backgroundcolor="black", color="ivory", gridcolor="black",showbackground=T,zerolinecolor="black"), 
                                           zaxis = list(title = paste0("Expression"),backgroundcolor="black", color="ivory", gridcolor="black",showbackground=T,zerolinecolor="black")),
                              annotations = list(x = 0.5,y = 1.04,text = paste0(gene_set[i]),size = 2,xref = "paper",yref = "paper",showarrow = F, 
                                                 font = list(family = "Courier New", size = 25,color="ivory")),
                              paper_bgcolor = "black", plot_bgcolor = "black")
  return(st_exp.3D_surface_list)
}

st_exp.3D_surface_list<-lapply(seq(mat_kd_list), function(i) st_exp.3D_surface_fun(i))
gene_set # check gene names
st_exp.3D_surface_list[[8]] # PECAM1
