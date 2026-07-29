#!/usr/bin/env bash
set -euo pipefail

# ── Cursor-Plan2API Docker 镜像构建脚本 ─────────────────────────────
# 用法:
#   ./scripts/docker-build.sh           # 构建 latest 标签
#   ./scripts/docker-build.sh v0.4.0    # 构建指定版本标签
#   ./scripts/docker-build.sh --push    # 构建并推送到 ghcr.io
#   ./scripts/docker-build.sh --push v0.4.0
#
# 环境变量:
#   REGISTRY    镜像仓库 (默认: ghcr.io)
#   IMAGE_OWNER  仓库所有者 (默认: 自动从 git remote 提取)
#   DOCKER_PUSH  设为 1 强制推送
# ─────────────────────────────────────────────────────────────────────

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"

# ── 解析仓库所有者 ────────────────────────────────────────────────────
GIT_REMOTE="${IMAGE_OWNER:-}"
if [ -z "$GIT_REMOTE" ]; then
  GIT_REMOTE="$(git remote get-url origin 2>/dev/null || echo "")"
  # 从 git@github.com:user/repo.git 或 https://github.com/user/repo.git 提取 user
  GIT_REMOTE="$(echo "$GIT_REMOTE" | sed -E 's|.*[:/]([^/]+)/[^/]+(\.git)?$|\1|')"
fi
if [ -z "$GIT_REMOTE" ]; then
  echo "❌ 无法确定仓库所有者。请设置 IMAGE_OWNER 环境变量"
  echo "   例如: IMAGE_OWNER=alfons-fhl $0"
  exit 1
fi

REGISTRY="${REGISTRY:-ghcr.io}"
IMAGE_NAME="$REGISTRY/$GIT_REMOTE/cursor-plan2api"
PUSH="${DOCKER_PUSH:-0}"

# ── 解析标签 ─────────────────────────────────────────────────────────
TAG="${1:-latest}"
if [ "$TAG" = "--push" ]; then
  PUSH=1
  TAG="${2:-latest}"
fi

# ── 检查 Docker ──────────────────────────────────────────────────────
if ! command -v docker &>/dev/null; then
  echo "❌ 请先安装 Docker CLI"
  exit 1
fi

# ── 构建 ──────────────────────────────────────────────────────────────
echo "🔨 构建镜像: $IMAGE_NAME:$TAG"
echo "   上下文: $REPO_ROOT"
echo ""

BUILD_ARGS=(
  --tag "$IMAGE_NAME:$TAG"
)

# 如果是 latest 构建，额外加一个短 SHA 标签
if [ "$TAG" = "latest" ]; then
  SHORT_SHA="$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")"
  BUILD_ARGS+=(--tag "$IMAGE_NAME:sha-$SHORT_SHA")
  echo "   额外标签: $IMAGE_NAME:sha-$SHORT_SHA"
fi

docker buildx build \
  "${BUILD_ARGS[@]}" \
  --cache-from type=local,src=/tmp/.buildx-cache \
  --cache-to type=local,dest=/tmp/.buildx-cache,mode=max \
  "$REPO_ROOT"

echo ""
echo "✅ 构建完成: $IMAGE_NAME:$TAG"
docker images "$IMAGE_NAME" --format "table {{.Repository}}:{{.Tag}}\t{{.Size}}\t{{.CreatedAt}}"

# ── 推送 ──────────────────────────────────────────────────────────────
if [ "$PUSH" = "1" ]; then
  echo ""
  echo "📤 推送到 $REGISTRY ..."

  # 检查是否已登录
  if ! docker system info 2>/dev/null | grep -q "$REGISTRY"; then
    echo "⚠️  未检测到 $REGISTRY 登录状态"
    echo "   请先运行: echo \$GITHUB_TOKEN | docker login $REGISTRY -u \$USER --password-stdin"
    echo ""
  fi

  docker push "$IMAGE_NAME:$TAG"

  if [ "$TAG" = "latest" ]; then
    SHORT_SHA="$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")"
    docker push "$IMAGE_NAME:sha-$SHORT_SHA"
  fi

  echo "✅ 推送完成"
fi

echo ""
echo "── 使用方式 ──────────────────────────────────────────────"
echo ""
echo "  docker run -d \\"
echo "    --name cursor-plan2api \\"
echo "    -p 8787:8787 \\"
echo "    -v ~/.cursor/machine.json:/root/.cursor/machine.json:ro \\"
echo "    -e CURSOR_PLAN2API_HOST=0.0.0.0 \\"
echo "    -e CURSOR_PLAN2API_PORT=8787 \\"
echo "    $IMAGE_NAME:$TAG"
echo ""
echo "  或使用 docker-compose:"
echo "  docker run -d --name cursor-plan2api -p 8787:8787 \\"
echo "    -v ~/.cursor/machine.json:/root/.cursor/machine.json:ro \\"
echo "    -e CURSOR_PLAN2API_HOST=0.0.0.0 \\"
echo "    -e CURSOR_PLAN2API_PORT=8787 \\"
echo "    -e CURSOR_PLAN2API_DEFAULT_MODEL=composer-2.5 \\"
echo "    $IMAGE_NAME:$TAG"
echo "──────────────────────────────────────────────────────────"