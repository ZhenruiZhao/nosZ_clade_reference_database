#!/bin/bash

BASE_DIR=YOURDIR/

echo -e "Sample\tTotal_reads\tClade_I\tClade_II\tClade_III\tStatus" > summary.txt

for sample_dir in ${BASE_DIR}/*; do
    sample=$(basename ${sample_dir})
    
    file=${sample_dir}/${sample}/${sample}_read_tax.tsv
    
    # 检查文件是否存在
    if [ ! -f "$file" ]; then
        echo -e "${sample}\t0\t0\t0\t0\tNO_FILE" >> summary.txt
        continue
    fi
    
    # 检查是否为空
    if [ ! -s "$file" ]; then
        echo -e "${sample}\t0\t0\t0\t0\tEMPTY" >> summary.txt
        continue
    fi
    
 # 统计clade，使用正则匹配整个词
    clade1=$(grep -c -w "cladeI" "$file")
    clade2=$(grep -c -w "cladeII" "$file")
    clade3=$(grep -c -w "cladeIII" "$file")
      # total = cladeI + cladeII + cladeIII
    total=$((clade1 + clade2 + clade3))

    echo -e "${sample}\t${total}\t${clade1}\t${clade2}\t${clade3}\tOK" >> summary.txt

done