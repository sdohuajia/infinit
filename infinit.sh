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

# 检查并安装命令
function check_install() {
    command -v "$1" &> /dev/null
    if [ $? -ne 0 ]; then
        echo "$1 未安装，正在安装..."
        eval "$2"
    else
        echo "$1 已安装"
    fi
}

# 部署合约
function deploy_contract() {
    export NVM_DIR="$HOME/.nvm"
    
    # 检查并安装 NVM
    if [ -s "$NVM_DIR/nvm.sh" ]; then
        echo "加载 NVM..."
        source "$NVM_DIR/nvm.sh"
    else
        echo "未找到 NVM，正在安装 NVM..."
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.4/install.sh | bash
        source "$NVM_DIR/nvm.sh"
    fi

    # 检查并安装 Node.js
    check_install "node" "nvm install 22 && nvm alias default 22 && nvm use default"

    # 检查并安装 Foundry
    check_install "foundryup" "curl -L https://foundry.paradigm.xyz | bash && export PATH=\"\$HOME/.foundry/bin:\$PATH\" && foundryup"

    # 检查并安装 Bun
    check_install "bun" "curl -fsSL https://bun.sh/install | bash && export PATH=\"\$HOME/.bun/bin:\$PATH\""

    # 设置 Bun 项目
    echo "设置 Bun 项目..."
    mkdir -p infinit && cd infinit || exit
    bun init -y
    bun add @infinit-xyz/cli

    echo "正在初始化 Infinit CLI 并生成帐户..."
    bunx infinit init

    # 生成钱包并保存地址
    ACCOUNT_ID=$(bunx infinit account generate)

    read -p "你的钱包地址是什么（输入上一步中的地址）: " WALLET
    echo
    read -p "你的账户 ID 是什么（在上一步输入）: " ACCOUNT_ID
    echo

    echo "复制这个私钥并保存在某个地方，这是这个钱包的私钥"
    bunx infinit account export "$ACCOUNT_ID"

    sleep 5
    echo
    # 移除旧的 deployUniswapV3Action 脚本（如果存在）
    rm -rf src/scripts/deployUniswapV3Action.script.ts

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
  "deployer": "$ACCOUNT_ID"
}

export default { params, signer, Action: DeployUniswapV3Action }
EOF

    echo "正在执行 UniswapV3 Action 脚本..."
    bunx infinit script execute deployUniswapV3Action.script.ts

    # 等待用户按任意键以返回主菜单
    read -p "按任意键返回主菜单..."
}

# 启动主菜单
main_menu
