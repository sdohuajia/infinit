#!/bin/bash

# 脚本保存路径
SCRIPT_PATH="$HOME/infinit.sh"

# 显示 Logo
curl -s https://raw.githubusercontent.com/sdohuajia/Hyperlane/refs/heads/main/logo.sh | bash
sleep 3

# 主菜单函数
function main_menu() {
    while true; do
        clear
        echo "脚本由推特 @ferdie_jhovie，免费开源，请勿相信收费"
        echo "================================================================"
        echo "节点社区 Telegram 群组: https://t.me/niuwuriji"
        echo "节点社区 Telegram 频道: https://t.me/niuwuriji"
        echo "节点社区 Discord 社群: https://discord.gg/GbMV5EcNWF"
        echo "退出脚本，请按键盘 ctrl+c 退出即可"
        echo "请选择要执行的操作:"
        echo "1) 部署合约"
        echo "2) 退出"

        read -p "请输入选择: " choice

        case $choice in
            1)
                deploy_contract
                ;;
            2)
                echo "退出脚本..."
                exit 0
                ;;
            *)
                echo "无效选择，请重试"
                ;;
        esac
        read -n 1 -s -r -p "按任意键继续..."
    done
}

# 部署合约
function deploy_contract() {
    # 检查 Node.js 版本
    NODE_VERSION=$(node -v 2>/dev/null)

    if [ $? -ne 0 ] || [ "$(echo -e "$NODE_VERSION\nv22.0.0" | sort -V | head -n1)" != "v22.0.0" ]; then
        echo "Node.js 版本低于 22.0.0，正在安装..."

        # 安装 nvm
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash

        # 加载 nvm
        export NVM_DIR="$HOME/.nvm"
        [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
        [ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

        # 安装 Node.js 22
        nvm install 22
        nvm alias default 22
        nvm use default

        echo "Node.js 安装完成，当前版本: $(node -v)"
    else
        echo "Node.js 已安装，当前版本: $NODE_VERSION"
    fi

    # 检查并安装 unzip
    sudo apt-get install -y unzip

    # 检查并安装 Bun
    if ! command -v bun &> /dev/null; then
        echo "Bun 未安装，正在安装..."
        curl -fsSL https://bun.sh/install | bash
        source /root/.bashrc
        echo "Bun 安装完成"
    else
        echo "Bun 已安装"
    fi

    # 创建项目目录并进入
    mkdir -p infinit
    cd infinit || exit

    # 初始化 Bun 项目
    bun init -y
    bun add @infinit-xyz/cli
    echo
    echo "正在初始化 Infinit CLI 并生成帐户..."
    bunx infinit init
    ACCOUNT_ID=$(bunx infinit account generate)

    # 提示用户输入钱包地址和账户ID
    read -p "你的钱包地址是什么 （输入上一步中的地址）: " WALLET
    echo
    read -p "你的账户ID是什么 （在上一步输入）: " ACCOUNT_ID
    echo

    # 显示私钥提示
    echo "复制这个私钥并保存在某个地方，这是这个钱包的私钥"
    echo
    bunx infinit account export $ACCOUNT_ID

    # 提示用户按任意键继续
    read -n 1 -s -r -p "按任意键继续..."

    echo
    # 移除旧的 deployUniswapV3Action 脚本（如果存在）
    rm -rf src/scripts/deployUniswapV3Action.script.ts

    # 创建新的 deployUniswapV3Action 脚本
cat <<EOF > src/scripts/deployUniswapV3Action.script.ts
import { DeployUniswapV3Action, type actions } from '@infinit-xyz/uniswap-v3/actions'
import type { z } from 'zod'

type Param = z.infer<typeof actions['init']['paramsSchema']>

// TODO: Replace with actual params
const params: Param = {
  // Native currency label (e.g., ETH)
  "nativeCurrencyLabel": 'ETH',

  // Address of the owner of the proxy admin
  "proxyAdminOwner": '$WALLET',

  // Address of the owner of factory
  "factoryOwner": '$WALLET',

  // Address of the wrapped native token (e.g., WETH)
  "wrappedNativeToken": '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2'
}

// Signer configuration
const signer = {
  "deployer": '$ACCOUNT_ID'
}

export default { params, signer, Action: DeployUniswapV3Action }
EOF

    # 执行 UniswapV3 Action 脚本
    echo "正在执行 UniswapV3 Action 脚本..."
    echo
    bunx infinit script execute deployUniswapV3Action.script.ts
    
    # 等待用户按任意键以返回主菜单
    read -p "按任意键返回主菜单..."
}

# 启动主菜单
main_menu
