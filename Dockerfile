# 前端构建阶段
FROM docker.m.daocloud.io/library/node:20-alpine as frontend-builder
WORKDIR /app
RUN npm install -g pnpm
RUN npm config set registry https://registry.npmmirror.com
# 先复制依赖文件
COPY ui/package.json ui/pnpm-lock.yaml ./
# 安装依赖
RUN pnpm install --frozen-lockfile
# 再复制源代码（排除 node_modules）
COPY ui/ .
# 增加 Node.js 内存限制，避免 esbuild 崩溃（服务器内存4G，设置为1.5G）
ENV NODE_OPTIONS="--max-old-space-size=1536"
# 设置后端 API 地址（容器内部调用）
ENV SERVICE_BASE_URL="http://localhost:8080"
RUN pnpm build

# 后端构建阶段
FROM docker.m.daocloud.io/library/maven:3.8-openjdk-17 as backend-builder
WORKDIR /app
COPY genie-backend/pom.xml .
COPY genie-backend/src ./src
COPY genie-backend/build.sh genie-backend/start.sh ./
# 先转换行结束符（Windows CRLF -> Linux LF），再设置执行权限
# 使用 tr 命令更可靠地移除 \r
RUN tr -d '\r' < build.sh > build.sh.tmp && mv build.sh.tmp build.sh && \
    tr -d '\r' < start.sh > start.sh.tmp && mv start.sh.tmp start.sh && \
    chmod +x build.sh start.sh
RUN ./build.sh

# Python 环境准备阶段
# 使用完整版 python:3.11 而不是 slim，避免依赖冲突
FROM docker.m.daocloud.io/library/python:3.11 as python-base
WORKDIR /app

RUN rm /etc/apt/sources.list.d/* && echo 'deb https://mirrors.aliyun.com/debian/ bookworm main contrib non-free non-free-firmware' \
      > /etc/apt/sources.list && \
    echo 'deb https://mirrors.aliyun.com/debian-security bookworm-security main contrib non-free non-free-firmware' \
      >> /etc/apt/sources.list && \
    echo 'deb https://mirrors.aliyun.com/debian/ bookworm-updates main contrib non-free non-free-firmware' \
      >> /etc/apt/sources.list

RUN apt-get clean && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    netcat-openbsd \
    procps \
    curl \
    gcc \
    g++ \
    make \
    && rm -rf /var/lib/apt/lists/*
# 配置 pip 使用国内镜像并增加超时时间
RUN pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple && \
    pip config set global.timeout 300 && \
    pip install uv

# 最终运行阶段
FROM docker.m.daocloud.io/library/python:3.11-slim

# 安装系统依赖
RUN rm /etc/apt/sources.list.d/* && echo 'deb https://mirrors.aliyun.com/debian/ bookworm main contrib non-free non-free-firmware' \
      > /etc/apt/sources.list && \
    echo 'deb https://mirrors.aliyun.com/debian-security bookworm-security main contrib non-free non-free-firmware' \
      >> /etc/apt/sources.list && \
    echo 'deb https://mirrors.aliyun.com/debian/ bookworm-updates main contrib non-free non-free-firmware' \
      >> /etc/apt/sources.list
RUN apt-get clean && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
    openjdk-17-jre-headless \
    netcat-openbsd \
    procps \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 安装 Node.js（使用 NodeSource 官方源，避免依赖冲突）
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y --no-install-recommends nodejs && \
    rm -rf /var/lib/apt/lists/*

# 配置 npm 镜像并安装 pnpm
RUN npm config set registry https://registry.npmmirror.com && \
    npm install -g pnpm

# 设置工作目录
WORKDIR /app

# 复制前端构建产物
COPY --from=frontend-builder /app/dist /app/ui/dist
COPY --from=frontend-builder /app/package.json /app/ui/package.json
COPY --from=frontend-builder /app/node_modules /app/ui/node_modules

# 复制后端构建产物
COPY --from=backend-builder /app/target /app/backend/target
COPY genie-backend/start.sh /app/backend/
RUN tr -d '\r' < /app/backend/start.sh > /app/backend/start.sh.tmp && \
    mv /app/backend/start.sh.tmp /app/backend/start.sh && \
    chmod +x /app/backend/start.sh

# 复制 Python 工具和依赖
COPY --from=python-base /usr/local/lib/python3.11 /usr/local/lib/python3.11
COPY --from=python-base /usr/local/bin/uv /usr/local/bin/uv

# 复制 genie-client
WORKDIR /app/client
COPY genie-client/pyproject.toml genie-client/uv.lock ./
COPY genie-client/app ./app
COPY genie-client/main.py genie-client/server.py genie-client/start.sh ./
RUN tr -d '\r' < start.sh > start.sh.tmp && mv start.sh.tmp start.sh && \
    chmod +x start.sh && \
    uv venv .venv && \
    . .venv/bin/activate && \
    export UV_DEFAULT_INDEX="https://pypi.tuna.tsinghua.edu.cn/simple" && uv sync

# 复制 genie-tool
WORKDIR /app/tool
COPY genie-tool/pyproject.toml genie-tool/uv.lock ./
COPY genie-tool/genie_tool ./genie_tool
COPY genie-tool/server.py genie-tool/start.sh genie-tool/.env_template ./

# 创建虚拟环境并安装依赖
RUN tr -d '\r' < start.sh > start.sh.tmp && mv start.sh.tmp start.sh && \
    chmod +x start.sh && \
    uv venv .venv && \
    . .venv/bin/activate && \
    export UV_DEFAULT_INDEX="https://pypi.tuna.tsinghua.edu.cn/simple" && uv sync && \
    mkdir -p /data/genie-tool && \
    cp .env_template .env && \
    python -m genie_tool.db.db_engine

# 设置数据卷
VOLUME ["/data/genie-tool"]

# 复制统一启动脚本
WORKDIR /app
COPY start_genie.sh .
RUN tr -d '\r' < start_genie.sh > start_genie.sh.tmp && mv start_genie.sh.tmp start_genie.sh && \
    chmod +x start_genie.sh

# 设置环境变量（前端调用后端 API 地址）
ENV SERVICE_BASE_URL="http://localhost:8080"

EXPOSE 3000 8080 1601

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:3000 || exit 1

# 启动所有服务
CMD ["./start_genie.sh"]