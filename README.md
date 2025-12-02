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

* 使用之前保存的 tar 文件 保存为sandbox模式 可写

        # 进入目标目录
        cd /data/renweijie/Singularity
        singularity build --sandbox off_peak-excavator2_tools_sandbox docker-archive:///data/renweijie/Docker/off_peak-excavator2_tools.tar
