## 一、使用 Conda 安装 Singularity（无 root 权限方案）
    #1. 创建一个专门用于 Singularity 的 conda 环境
    conda create -n singularity
    conda activate singularity

    #2. 从 conda-forge 频道安装 Singularity
    conda install -c conda-forge singularity

    #3.查看singularity 版本
    singularity --version
## 二、创建专属镜像
* 创建dockerfile
* 构建镜像

        docker build -t off_peak-excavator2_tools .
* 进入容器验证安装

        docker run --rm -it off_peak-excavator2_tools
        # 验证 libpng12 是否安装成功
        ldd /opt/tools/EXCAVATOR2/lib/OtherLibrary/bigWigAverageOverBed
        # 测试 bigWigAverageOverBed 是否能正常运行
        /opt/tools/EXCAVATOR2/lib/OtherLibrary/bigWigAverageOverBed
* 保存 Docker 镜像为 tar 文件到指定目录

        docker save off_peak-excavator2_tools -o /data/renweijie/Docker/off_peak-excavator2_tools.tar
## 三、运行OFF-PEAK、EXCAVATOR2
### 1.运行OFF-PEAK
* 使用之前保存的 tar 文件 保存为sandbox模式 可写

        # 进入目标目录
        cd /data/renweijie/Singularity
        singularity build --sandbox off_peak-excavator2_tools_sandbox docker-archive:///data/renweijie/Docker/off_peak-excavator2_tools.tar

* 完全不挂载任何目录进入沙盒

        singularity shell --no-home --containall --writable /data/renweijie/Singularity/off_peak-excavator2_tools_sandbox
* 在沙盒内创建需要的目录结构

        mkdir -p /data/renweijie
        #退出容器
        exit

* 挂载数据并重新进入沙盒
  
        singularity shell --writable \
        -B /data/renweijie:/data/renweijie \
        /data/renweijie/Singularity/off_peak-excavator2_tools_sandbox
* 进入容器内的OFF-PEAK
  
        cd /opt/tools/OFF-PEAK
        bash 01_targets-processing.sh \
        --genome hg19 \
        --targets /data/renweijie/data/TSCP-target-BED.bed \
        --name ICR96_singularity_panel \
        --ref /data/renweijie/data/technology/hg19.fa
  
        bash 02_coverage-count.sh \
        --listBAM /data/renweijie/ICR96/OFF-PEAK-std/step05_bqsr_bams/list_BAM.txt \
        --mosdepth /usr/local/bin/mosdepth \
        --work /data/renweijie/ICR96/OFF-PEAK-singularity/ICR96-OFFPEAK-results/coverage\
        --targetsBED /opt/tools/OFF-PEAK/data/ICR96_singularity_panel.bed

       Rscript 03_OFF-PEAK.R \
       --output /data/renweijie/ICR96/OFF-PEAK-singularity/ICR96-OFFPEAK-results/cnv_results_50k \
       --data /data/renweijie/ICR96/OFF-PEAK-singularity/ICR96-OFFPEAK-results/coverage/ALL.target.tsv \
       --databasefile /opt/tools/OFF-PEAK/data/data-hg19.RData \
       --chromosome-plots \
       --genome-plots \
       --nb-plots 20
### 2.运行EXCAVATOR2
* 创建所需配置文件
  
  * SourceTarget.txt
  * ExperimentalFilePrepare.w20000.txt
  * ExperimentalFileAnalysis.w20K.txt
* 运行TargetPerla.pl
  
        cd /opt/tools/EXCAVATOR2/lib/F77
        # 编译两个Fortran文件
        R CMD SHLIB F4R.f
        R CMD SHLIB FastJointSLMLibraryI.f

        cd /opt/tools/EXCAVATOR2
        #20k
        perl TargetPerla.pl \
        /data/renweijie/1000GP/1KGP_singularity_20k/SourceTarget.txt \
        /data/renweijie/1000GP/1000GP_prosecced/20120518.exome.consensus.processed.bed \
        1KGP_Target_20k \
        20000 \
        hg19
* 运行EXCAVATORDataPrepare.pl

        perl EXCAVATORDataPrepare.pl \
        /data/renweijie/1000GP/1KGP_singularity_20k/ExperimentalFilePrepare.w20000.txt \
        --processors 4 \
        --target 1KGP_Target_20k \
        --assembly hg19

* 运行EXCAVATORDataAnalysis.pl

        perl EXCAVATORDataAnalysis.pl \
        /data/renweijie/1000GP/1KGP_singularity_20k/ExperimentalFileAnalysis.w20K.txt \
        --processors 8 \
        --target 1KGP_Target_20k \
        --assembly hg19 \
        --output /data/renweijie/1000GP/1KGP_singularity_20k/1KGP_CNV_Results_20K \
        --mode pooling
      


