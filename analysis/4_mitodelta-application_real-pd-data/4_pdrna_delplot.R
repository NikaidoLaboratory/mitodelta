library(tidyverse)
library(ggplot2)
library(dplyr)
library(dunn.test)


# load data
df <- read_tsv("250319_pdrna_ds50_betabinomial.tsv", col_names = TRUE)

# filter (FDR < 0.05)
df <- df %>% filter(q_value < 0.05)


### Compare PD vs control (box plot)
df_count <- df %>%
  count(sample, cluster, name = "count") %>%
  pivot_wider(names_from = cluster, values_from = count, values_fill = 0) 
print(df_count, n=30)
df3 <- df_count %>%
  pivot_longer(cols = -sample, names_to = "cluster", values_to = "count") %>%
  mutate(group = ifelse(grepl("^p", sample), "PD", "Control"))
# plot
p2 <- ggplot(df3, aes(x = cluster, y = count, fill = group)) +
  geom_boxplot(color = "black", linewidth = 0.3, outlier.shape = NA) + 
  labs(x = "Cluster", y = "Deletion Count", title = "Count per Cluster (PD vs Control)") +
  scale_fill_manual(values = c("PD" = "tomato", "Control" = "steelblue")) + 
  theme_minimal() +
  theme(
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    panel.background = element_blank(),
    axis.line = element_line(color = "black"),
    axis.text.x = element_text(angle = 45, hjust = 1)
  )



### Kruskal-Wallis rank sum test
df_count <- df %>%
  count(sample, cluster, name = "count") %>%
  pivot_wider(names_from = cluster, values_from = count, values_fill = 0) %>%
  mutate(group = ifelse(grepl("^p", sample), "PD", "Control"))

# Control
df_long0 <- df_count %>%
  filter(group == "Control") %>%
  select(-group) %>%
  pivot_longer(cols = -sample, names_to = "Cell_Type", values_to = "Count")
# Kruskal-Wallis test
kruskal_result0 <- kruskal.test(Count ~ Cell_Type, data = df_long0)
print(kruskal_result0)

# PD
df_long1 <- df_count %>%
  filter(group == "PD") %>%
  select(-group) %>%
  pivot_longer(cols = -sample, names_to = "Cell_Type", values_to = "Count")
# Kruskal-Wallis test
kruskal_result1 <- kruskal.test(Count ~ Cell_Type, data = df_long1)
print(kruskal_result1)



### 7. Dunn test (PD, 50 cells)
# Dunn test
dunn_result <- dunn.test(df_long1$Count, df_long1$Cell_Type, method = "bh")
print(dunn_result)

# save
dunn_df <- data.frame(
  Comparison = dunn_result$comparisons,
  Z_value = dunn_result$Z,
  P_value = dunn_result$P,
  Adjusted_P_value = dunn_result$P.adjusted
)
write_tsv(dunn_df, "250319_pdrna_50cell_pd_dunn_results.tsv")




### Common deletion
df0 <- df %>% filter(break5 == 8469 & break3 == 13446)




### Figure plot
df <- df %>%
  count(sample, cluster, name = "count") %>%
  pivot_wider(names_from = cluster, values_from = count, values_fill = 0) %>%
  pivot_longer(cols = -sample, names_to = "cluster", values_to = "count") %>%
  mutate(group = ifelse(grepl("^p", sample), "PD", "Control"))
df0 <- df %>% filter(group == "Control") %>% select(-group)
df1 <- df %>% filter(group == "PD") %>% select(-group)

# plot
p0 <- ggplot(df0, aes(x = cluster, y = count)) +
  geom_boxplot(fill = "steelblue", color = "black", linewidth = 0.3, outlier.shape = NA) +
  geom_jitter(width = 0.2, size = 0.5, color = "black") + 
  labs(x = "Cluster", y = "Deletion Count", title = "Control") +
  theme_minimal() +
  theme(
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    panel.background = element_blank(),
    axis.line = element_line(color = "black"),
    axis.text.x = element_text(angle = 45, hjust = 1), 
    plot.title = element_text(hjust = 0.5)
  ) +
  ylim(-0.5, 25)

p1 <- ggplot(df1, aes(x = cluster, y = count)) +
  geom_boxplot(fill = "tomato", color = "black", linewidth = 0.3, outlier.shape = NA) +
  geom_jitter(width = 0.2, size = 0.5, color = "black") + 
  labs(x = "Cluster", y = "Deletion Count", title = "PD") +
  theme_minimal() +
  theme(
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank(),
    panel.background = element_blank(),
    axis.line = element_line(color = "black"),
    axis.text.x = element_text(angle = 45, hjust = 1), 
    plot.title = element_text(hjust = 0.5)
  ) +
  ylim(-0.5, 25)

# save
library(gridExtra)
pdf("250319_boxplot_pdandcontrol.pdf", width = 7, height = 3.5) 
grid.arrange(p0, p1, ncol = 2)
dev.off()
