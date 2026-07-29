# Docker 部署指南

## 快速开始

### 1. 拉取镜像

```bash
docker pull ghcr.io/alfons-fhl/cursor-plan2api:latest
```

### 2. 运行容器

```bash
docker run -d \
  --name cursor-plan2api \
  -p 8787:8787 \
  -v ~/.cursor/machine.json:/root/.cursor/machine.json:ro \
  -e CURSOR_PLAN2API_HOST=0.0.0.0 \
  -e CURSOR_PLAN2API_PORT=8787 \
  -e CURSOR_PLAN2API_DEFAULT_MODEL=composer-2.5 \
  -e CURSOR_PLAN2API_AGENT_POOL=1 \
  -e CURSOR_PLAN2API_AGENT_POOL_SIZE=2 \
  -e CURSOR_PLAN2API_WARMUP_ON_START=1 \
  ghcr.io/alfons-fhl/cursor-plan2api:latest
```

### 3. 使用 docker-compose

```bash
docker compose up -d
```

## 认证方式

### 方式一：挂载 `machine.json`（推荐）

容器内 `agent` CLI 需要读取 Cursor 的认证文件。只需挂载 `~/.cursor/machine.json`：

```yaml
volumes:
  - ${HOME}/.cursor/machine.json:/root/.cursor/machine.json:ro
```

> 注意：macOS 用户可能没有 `machine.json`（令牌存在 Keychain 里），请用方式二。

### 方式二：使用 Dashboard API Key

```yaml
environment:
  - CURSOR_API_KEY=your-cursor-dashboard-api-key
```

这种方式不需要挂载任何文件。

## 环境变量

参见 [examples/config.yaml](https://github.com/alfons-fhl/Cursor-Plan2API/blob/master/examples/config.yaml) 和 [src/config.ts](https://github.com/alfons-fhl/Cursor-Plan2API/blob/master/src/config.ts)。

| 变量 | 默认值 | 说明 |
|---|---|---|
| `CURSOR_PLAN2API_HOST` | `127.0.0.1` | 监听地址（容器内用 `0.0.0.0`） |
| `CURSOR_PLAN2API_PORT` | `8787` | 监听端口 |
| `CURSOR_PLAN2API_DEFAULT_MODEL` | `composer-2.5` | 默认模型 |
| `CURSOR_PLAN2API_API_KEY` | — | 本地 API 认证 Key |
| `CURSOR_PLAN2API_AGENT_POOL` | `0` | 启用 Agent 预热池 |
| `CURSOR_PLAN2API_AGENT_POOL_SIZE` | `2` | 预热池大小 |
| `CURSOR_PLAN2API_WARMUP_ON_START` | `0` | 启动时预热 |
| `CURSOR_API_KEY` | — | Cursor Dashboard API Key（免文件挂载） |

## 版本标签

| 标签 | 说明 |
|---|---|
| `latest` | 最新稳定版（main/master 分支） |
| `sha-<短哈希>` | 每个提交的版本 |
| `v*` | 语义化版本标签 |
| `<branch-name>` | 分支名对应标签 |