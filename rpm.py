import pandas as pd

# 读数据
summary = pd.read_csv("summary.txt", sep="\t")
depth = pd.read_csv("/share/home/zhaozhr/2024_China_surface_mangrove/02.2_ncyc/sampleinfo.txt", sep="\t", header=None, names=["Sample", "Total_metagenome"])

# 合并
df = pd.merge(summary, depth, on="Sample")

# 计算 RPM
df["RPM_total"] = df["Total_reads"] / df["Total_metagenome"] * 1e6
df["RPM_I"] = df["Clade_I"] / df["Total_metagenome"] * 1e6
df["RPM_II"] = df["Clade_II"] / df["Total_metagenome"] * 1e6
df["RPM_III"] = df["Clade_III"] / df["Total_metagenome"] * 1e6
# 保存
df.to_csv("RPM_result.txt", sep="\t", index=False)