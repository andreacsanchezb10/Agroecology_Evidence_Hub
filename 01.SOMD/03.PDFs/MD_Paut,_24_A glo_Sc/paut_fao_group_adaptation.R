---
  title: "A global dataset of experimental intercropping and agroforestry studies in horticulture"
Authors: "Paut, Garreau, Ollivier, Sabatier, Tchamitchian"
output: html_document
---
  
  
  # Library
  ```{r library}
rm(list=ls())
library(readxl)
library(tidyverse)
library(ggpubr)

```

# Data
```{r data}
# load data with file paths
fao_groups<- read_excel("crop_traits_database_29022024.xlsx","List of FAO crops in AramburuMe")%>%
  select(crop,GROUP,SCIENTNAME)
fao_groups<-fao_groups[!duplicated(fao_groups), ]

data <-  read_excel("2. Database.xlsx")%>%
  filter(Intercropping_pattern=="AF")
sort(unique(data$Intercropping_pattern  ))
  
data_corresp <- read_excel("6. Classification of F&V.xlsx")%>%
  mutate(Crop_en=tolower(Crop_en))%>%
  left_join(fao_groups,by=c("Latin_name"="SCIENTNAME"))%>%
  left_join(fao_groups,by=c("Crop_en"="crop"))%>%
  mutate(GROUP= if_else(is.na(GROUP.y),GROUP.x,GROUP.y))%>%
  mutate(Crop_en=str_to_sentence(Crop_en))


sort(unique(data_corresp$Latin_name))
```
#install.packages("summarytools")

# Data description
```{r data_description}
library(summarytools)
view(dfSummary(data))

```

Figure 1 was created with QGIS software

# Figure 5 code
```{r partial LERs}
## Figure 5a ###
#crop 1
data_partial_LER_1 <- data %>% select(Id_article,
                                      crop = Crop_1_Common_Name,
                                      partial_LER= LER_crop1,
                                      partial_LER_calc = LER_crop_1_calc) %>%
  mutate(LER_p = case_when(
    !is.na(partial_LER) ~ partial_LER,
    is.na(partial_LER) & !is.na(partial_LER_calc) ~ partial_LER_calc))
#crop 2
data_partial_LER_2 <- data %>% select(Id_article, 
                                      crop = Crop_2_Common_Name,
                                      partial_LER= LER_crop2,
                                      partial_LER_calc = LER_crop_2_calc) %>%
  mutate(LER_p = case_when(
    !is.na(partial_LER) ~ partial_LER,
    is.na(partial_LER) & !is.na(partial_LER_calc) ~ partial_LER_calc))

# bind dataframes
data_partial_LER <- bind_rows(data_partial_LER_1, data_partial_LER_2) %>%
  select(crop, LER_p) %>%
  drop_na()%>%
  #Calculate log-Response-Ratio
  mutate(logLER_p= log(LER_p))
  
# Do not show data < 20 repetitions
select <- as.data.frame(table(data_partial_LER$crop))
select <- select[select$Freq >= 5,]
data_partial_LER <- data_partial_LER[which(data_partial_LER$crop %in% select$Var1),]
data_partial_LER$nb_obs <- select$Freq[match(data_partial_LER$crop,select$Var1)]

# add the nb of articles
data_partial_LER_nb_articles <- bind_rows(data_partial_LER_1, data_partial_LER_2) %>%
  select(crop, LER_p, Id_article) %>%
  drop_na() %>% 
  group_by(crop) %>%
  dplyr::summarise(n_articles = n_distinct(Id_article))

data_partial_LER <- data_partial_LER %>% left_join(data_partial_LER_nb_articles) %>%
  filter(crop=="Apple")
  filter(crop=="Rice")

boxplot_LER <- ggplot(data_partial_LER, aes(x=reorder(crop, logLER_p, FUN=mean), y=logLER_p, 
                                            fill=reorder(crop, logLER_p, FUN=mean)))+
  geom_boxplot(alpha=0.5)+
  geom_text(aes(y = max(logLER_p) + 0.2, label = paste0("n=", nb_obs, " (", n_articles, ")"), 
                colour=reorder(crop, logLER_p, FUN=mean)), size=3)+
  geom_hline(aes(yintercept=0.5), linetype="dashed", size=0.5)+
  stat_summary(
    aes(label=sprintf("%1.2f", ..y..)),
    geom="text", 
    fun.y = function(y) boxplot.stats(y)$stats,
    position=position_nudge(x=0.33), 
    size=3.5)+
  coord_flip()+
  theme_classic()+
  theme(legend.position="none")+
  labs(title = " ", x=" ", y="partial Land Equivalent Ratio")+
  theme(axis.title = element_text(size=12), # légende des axes
        axis.text = element_text(size=10, colour = "black"), # label des ticks
        axis.ticks = element_line(colour = "black")) # ticks
boxplot_LER

## Figure 5b ###
# Table crop - botanical family
data_partial_LER <- bind_rows(data_partial_LER_1, data_partial_LER_2) %>%
  select(crop, LER_p) %>%
  drop_na()%>%
  #Calculate log-Response-Ratio
  mutate(logLER_p= log(LER_p))

#data_partial_LER$fam <- data_corresp$Crop_family[match(data_partial_LER$crop, data_corresp$Crop_en)]
data_partial_LER$faoGroup <- data_corresp$GROUP[match(data_partial_LER$crop, data_corresp$Crop_en)]

# Do not show data < 20 repetitions
select <- as.data.frame(table(data_partial_LER$faoGroup))
select <- select[select$Freq >= 5,]
data_partial_LER_fam <- data_partial_LER %>% filter(is.na(faoGroup) == FALSE)
data_partial_LER_fam <- data_partial_LER_fam[which(data_partial_LER_fam$faoGroup %in% select$Var1),]
data_partial_LER_fam$nb_obs <- select$Freq[match(data_partial_LER_fam$faoGroup, select$Var1)]

# Add the nb of articles
data_partial_LER_fam_nb_articles <- bind_rows(data_partial_LER_1, data_partial_LER_2) %>%
  select(crop, LER_p, Id_article) %>%
  drop_na()

data_partial_LER_fam_nb_articles$faoGroup <- data_corresp$GROUP[match(data_partial_LER_fam_nb_articles$crop, data_corresp$Crop_en)]
data_partial_LER_fam_nb_articles <- data_partial_LER_fam_nb_articles %>% # on supprime les NA
  group_by(faoGroup) %>%
  dplyr::summarise(n_articles = n_distinct(Id_article))

data_partial_LER_fam <- data_partial_LER_fam %>% left_join(data_partial_LER_fam_nb_articles)

# plot
get_box_stats <- function(y, upper_limit = max(data_partial_LER_fam$logLER_p) * 1.15) {
  return(data.frame(
    y = 0.95 * upper_limit,
    label = paste(
      "Count =", length(y), "\n",
      "Mean =", round(mean(y), 2), "\n",
      "Median =", round(median(y), 2), "\n",
      "min =", round(min(y), 2), "\n",
      "max =", round(max(y), 2), "\n"
      )
  ))
}
get_box_stats
boxplot_LER_fam <- ggplot(data_partial_LER_fam, aes(x=reorder(faoGroup, logLER_p, FUN=mean), y=logLER_p,
                                                    fill=reorder(faoGroup, logLER_p, FUN=mean)))+
  geom_boxplot(alpha=0.5)+
  stat_summary(
    aes(label=sprintf("%1.2f", ..y..)),
    geom="text", 
    fun.y = function(y) boxplot.stats(y)$stats,
    position=position_nudge(x=0.33), 
    size=3.5)+
  
  
  geom_text(aes(y = max(logLER_p) + 0.2, label = paste0("n=", nb_obs, " (", n_articles, ")"), 
                colour=reorder(faoGroup, logLER_p, FUN=mean)), size=3)+
  geom_hline(aes(yintercept=0.5), linetype="dashed", size=0.5)+
  coord_flip()+
  theme_classic()+
  theme(legend.position="none")+
  labs(title = " ", x=" ", y="partial Land Equivalent Ratio")+
  stat_summary(fun.data = get_box_stats, geom = "text", hjust = 0.5, vjust = 0.9) +
  
  
  theme(axis.title = element_text(size=12), # axes
        axis.text = element_text(size=9, colour = "black"), # label des ticks
        axis.ticks = element_line(colour = "black")) # ticks
boxplot_LER_fam


myPlots <- list(boxplot_LER, boxplot_LER_fam)
ggarrange(plotlist = myPlots,
          labels = c("(a)", "(b)"),
          ncol = 2, nrow = 1,
          legend="none")

# save the plot
ggsave(filename = "boxplot_LERs.tiff", height = 6 , width = 15, dpi=500)

```



# Figure 6 code

```{r networks}
library(countrycode)
library(qgraph)

db_net <- data %>% select(Continent, Crop_1 = Crop_1_Common_Name, Crop_2=Crop_2_Common_Name)

db_net$unique_mix <- NA
for (i in 1:nrow(db_net)){
  db_net$unique_mix[i] <- paste(sort(c(db_net$Crop_1[i], db_net$Crop_2[i])), collapse = "-")
}
db_net2 <- db_net %>%
  separate(unique_mix, c("Crop_1", "Crop_2"), "-")

db_net_summary <- db_net2 %>% group_by(Continent, Crop_1, Crop_2) %>% dplyr::summarise(n =n())

continents <- unique(db_net_summary$Continent)
continents <- na.omit(continents)

# Individual graphs for each continent
list_graphs <- list()
for (i in continents){
  db_net_summary_temp <- db_net_summary %>% filter(Continent == paste(i))
  db_net_summary_temp$n <- db_net_summary_temp$n +10
  nameVals <- sort(unique(c(db_net_summary_temp$Crop_1, db_net_summary_temp$Crop_2)))
  myMat <- matrix(0, length(nameVals), length(nameVals), dimnames = list(nameVals, nameVals))
  myMat[as.matrix(db_net_summary_temp[c("Crop_1", "Crop_2")])] <- db_net_summary_temp[["n"]]
  psum <- function(x,y) (x+y)
  myMat[] <- psum(myMat, matrix(myMat, nrow(myMat), byrow=TRUE))
  table_groups <- data.frame(crops = sort(unique(c(db_net_summary_temp$Crop_1, db_net_summary_temp$Crop_2))))
  table_groups$group <- data_corresp$Crop_family[match(table_groups$crops,data_corresp$Crop_en)]
  groups <- table_groups$group
  
  # plot
  list_graphs[[i]] <- qgraph(myMat,
                             title = paste(i),
                             layout = "spring", groups=groups,
                             palette = 'pastel',
                             esize = 20,
                             border.width = 2,
                             edge.color = "black",
                             legend.cex = 0.2,
                             nodeNames=colnames(myMat))
  
  # ## save in .tiff format
  # qgraph(myMat,
  #        title = paste(i),
  #        layout = "spring", groups=groups,
  #        palette = 'pastel',
  #        esize = 20,
  #        border.width = 2,
  #        edge.color = "black",
  #        legend.cex = 0.3,
  #        legend = F,
  #        title.cex = 1.5,
  #        nodeNames=colnames(myMat),
  #        filetype = "tiff", height = 10, width = 10,
  #        filename = paste0(i))
}

```

