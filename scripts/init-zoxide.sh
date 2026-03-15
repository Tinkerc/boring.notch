#!/bin/bash
# Zoxide 初始化脚本 - 从 shell history 提取的常用工作目录
# 使用方法: bash scripts/init-zoxide.sh

# 主要工作目录
zoxide add ~/work
zoxide add ~/work/code
zoxide add ~/work/code/learning
zoxide add ~/work/code/learning/github
zoxide add ~/work/code/private
zoxide add ~/work/code/github
zoxide add ~/work/data-process
zoxide add ~/work/solution-desgin

# Baozun/Lululemon 项目
zoxide add ~/work/code/baozun
zoxide add ~/work/code/baozun/lululemon
zoxide add ~/work/code/baozun/kering
zoxide add ~/work/code/baozun/kering/iods

# Kering 项目
zoxide add ~/work/code/baozun/kering/iods/cus-iods-biz-iods-query

# Lululemon 搜索服务
zoxide add ~/work/code/baozun/lululemon/search/text-search-service/text-search-app
zoxide add ~/work/code/baozun/lululemon/search/text-search-service/text-search-auto-testing

# GitHub 学习项目
zoxide add ~/work/code/learning/github/github-schedule
zoxide add ~/work/code/learning/github/vibe-coding
zoxide add ~/work/code/learning/github/vibe-coding-testing
zoxide add ~/work/code/learning/github/claude-control

# Python 脚本项目
zoxide add ~/work/code/private/python/bash-script
zoxide add ~/work/code/private/python/bash-script/wifi-spoof
zoxide add ~/work/code/private/python/lab/shortcut-to-text
zoxide add ~/work/code/private/python/local-skills

# 部署脚本
zoxide add ~/work/deploy/script/elastic-search
zoxide add ~/work/deploy/script/elastic-search/kering-json-process

# 解决方案设计
zoxide add ~/work/solution-desgin/kering/china-iods/sales-facade/script

# Cascade 项目
zoxide add ~/CascadeProjects
zoxide add ~/CascadeProjects/vibe-coding

echo "✅ Zoxide 数据库初始化完成！"
echo "现在可以使用以下命令快速跳转："
echo "  z learning     → ~/work/code/learning"
echo "  z github       → ~/work/code/learning/github"
echo "  z baozun       → ~/work/code/baozun"
echo "  z lululemon    → ~/work/code/baozun/lululemon"
echo "  z kering       → ~/work/code/baozun/kering"
echo "  z vibe         → ~/work/code/learning/github/vibe-coding"
echo "  z boring       → ~/work/code/github/tools/boring.notch (如果已访问)"
