# git2svn
git to svn git迁移到svn
当前路径下创建 list.txt 按行存放需要迁移的git项目：组织/库名
# 参考连接：
* https://blog.csdn.net/zhangskd/article/details/43452627
* https://stackoverflow.com/questions/661018/pushing-an-existing-git-repository-to-svn

################环境配置
# 需要安装  svn  git  git-svn
################
# 项目列表list.txt 文件格式必须是unix格式 （即使用unix的换行符）
##########################################################
### git svn等远程路径, 按照时间情况修改 ip端口，用户密码
### 首次运行可能需要添加主机到信任列表，请手动提前执行下面的几条命令，相应变量替换为实际内容
### git clone ${git_url}${name}.git
### svn mkdir --parents ${svn_url}${name}/test -m "Importing git repo ${git_url}${name}" ${svn_login}
### 迁移方式两种，默认git id版本方式，如果该方式不成功，则 执行脚本 ./git2svn.sh rebase 使用git rebase方式,rebase方式可能需要手动处理冲突
### 更换迁移方式：需要先将本脚本之前下载的相关本地git仓库删除
#####################配置修改############################
