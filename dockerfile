FROM ubuntu:20.04
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

# 创建 Singularity 挂载点目录
RUN mkdir -p /data

# 使用阿里云镜像源
RUN sed -i 's/archive.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list && \
   sed -i 's/security.ubuntu.com/mirrors.aliyun.com/g' /etc/apt/sources.list

# 安装系统基础工具、编译工具和生物信息工具
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates wget curl gnupg2 software-properties-common \
    build-essential gcc gfortran make automake cmake \
    zlib1g-dev libcurl4-openssl-dev libssl-dev libxml2-dev libpng-dev \
    python3 python3-pip perl \
    bedtools samtools \
    && rm -rf /var/lib/apt/lists/*

# 添加 R 4.x 官方仓库并安装 R
RUN wget -qO- https://cloud.r-project.org/bin/linux/ubuntu/marutter_pubkey.asc | gpg --dearmor -o /usr/share/keyrings/r-project.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/r-project.gpg] https://cloud.r-project.org/bin/linux/ubuntu focal-cran40/" | tee -a /etc/apt/sources.list.d/r-project.list && \
    apt-get update && apt-get install -y --no-install-recommends \
    r-base r-base-dev r-base-core

# 安装 Python 包
RUN pip3 install numpy scipy

# 安装 mosdepth
RUN wget -q https://ghproxy.net/https://github.com/brentp/mosdepth/releases/download/v0.3.3/mosdepth && \
    chmod +x mosdepth && mv mosdepth /usr/local/bin/

# 设置 R 镜像源
RUN echo "options(repos = c(CRAN = 'https://mirrors.tuna.tsinghua.edu.cn/CRAN/'))" >> /etc/R/Rprofile.site && \
    echo "options(download.file.method = 'libcurl')" >> /etc/R/Rprofile.site && \
    echo "options(timeout=600)" >> /etc/R/Rprofile.site

# 安装 CRAN 包
RUN Rscript -e "install.packages(c('optparse', 'gplots', 'pROC', 'caTools', 'Hmisc', 'BiocManager', 'aod', 'VGAM', 'dplyr', 'magrittr'))"

# 安装 Bioconductor 包
RUN Rscript -e "BiocManager::install(c('Biostrings', 'IRanges', 'Rsamtools', 'GenomicRanges', 'GenomicAlignments'), ask=FALSE)"

# 安装 ExomeDepth
RUN Rscript -e "url <- 'https://cran.r-project.org/src/contrib/Archive/ExomeDepth/ExomeDepth_1.1.16.tar.gz'; pkgFile <- 'ExomeDepth_1.1.16.tar.gz'; download.file(url = url, destfile = pkgFile, mode = 'wb'); install.packages(pkgs=pkgFile, type='source', repos=NULL); unlink(pkgFile)"

# 创建统一的工具目录结构
RUN mkdir -p /opt/tools 
# 设置工作目录
WORKDIR /opt/tools

# 下载并安装 OFF-PEAK
RUN wget https://github.com/mquinodo/OFF-PEAK/archive/refs/heads/main.tar.gz -O off-peak.tar.gz && \
    tar -xzf off-peak.tar.gz && \
    mv OFF-PEAK-main OFF-PEAK && \
    rm off-peak.tar.gz 

# 下载并安装 EXCAVATOR2
RUN wget https://master.dl.sourceforge.net/project/excavator2tool/EXCAVATOR2_Package_v1.1.2.tgz -O excavator2.tgz && \
    tar -xzf excavator2.tgz && \
    mv EXCAVATOR2_Package_v1.1.2 EXCAVATOR2 && \
    rm excavator2.tgz 

# 安装 libpng12 - 最可靠的方法
RUN cd /tmp && \
    wget http://archive.ubuntu.com/ubuntu/pool/main/libp/libpng/libpng12-0_1.2.54-1ubuntu1_amd64.deb && \
    dpkg-deb -x libpng12-0_1.2.54-1ubuntu1_amd64.deb /tmp/libpng12 && \
    cp /tmp/libpng12/lib/x86_64-linux-gnu/libpng12.so.0.54.0 /lib/x86_64-linux-gnu/ && \
    ln -s /lib/x86_64-linux-gnu/libpng12.so.0.54.0 /lib/x86_64-linux-gnu/libpng12.so.0 && \
    ldconfig && \
    rm -rf /tmp/libpng12-0_1.2.54-1ubuntu1_amd64.deb /tmp/libpng12

# 设置工作目录
WORKDIR /workspace

CMD ["/bin/bash"]
