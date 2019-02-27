#!/bin/bash
################环境配置
# 需要安装  svn  git  git-svn
################
# 项目列表list.txt 文件格式必须是unix格式 （即使用unix的换行符）
##########################################################
### 1 git svn等远程路径, 按照实际情况修改 ip端口，用户密码
### 2 首次运行可能需要添加主机到信任列表，请手动提前执行下面的几条命令，相应变量替换为实际内容
###   git clone ${git_url}${name}.git
###   svn mkdir --parents ${svn_url}${name}/test -m "Importing git repo ${git_url}${name}" ${svn_login}
### 3 迁移方式两种，默认git id版本方式，如果该方式不成功，则 执行脚本 ./git2svn.sh rebase 使用git rebase方式,rebase方式可能需要手动处理冲突（1.3 添加 分支和标签参数见后文）
###   更换迁移方式：需要先将本脚本之前下载的相关本地git仓库删除
### 4 可能还需要设置git邮箱 git config --global user.email "email@example.com"  git config --global user.name "Mona Lisa"
################ v 1.3 ######################
###脚本启动参数：3个 分别指定 master（主代码），branch（分支），tag（标签）的迁移方式
# ./git2svn.sh                                              # 默认id方式迁移 
# ./git2svn.sh rebase rebase rebase                         # master，branch，tag 都使用rebase方式迁移
# ./git2svn.sh rebase 1 rebase                              # master tag  使用rebase方式迁移
# ./git2svn.sh rebase                                       # master 使用rebase方式迁移 
#
######################################
#####################配置修改############################
#git 仓库
git_name="admin"
git_psw="psw"
# git服务器的ip和端口,注意结尾不要有/
git_ip="10.100.1.1:3000"

#svn 仓库
svn_name="admin"
svn_psw="psw"
svn_ip="10.100.1.2"
#svn 服务器最后拼接的地址，目录默认/svn/
svn_url="https://${svn_ip}/svn/"

### 当前路径下被读取的项目列表
list_file="list.txt"
# 设置并发的进程数
thread_num=5
#####################配置修改##########################
### 最后使用的url，注意最后拼接的/，git_ip结尾不要有/
git_url="http://${git_name}:${git_psw}@${git_ip}/"
svn_login=" --username ${svn_name} --password ${svn_psw} "
####################主程序############################
echo "----git_url:${git_url}"
echo "----svn_url:${svn_url} ${svn_login}"
echo "----list_file:${list_file}"
# 路径
DIRNAME=$0
if [ "${DIRNAME:0:1}" = "/" ];then
    CUR=`dirname $DIRNAME`
else
    CUR="`pwd`"/"`dirname $DIRNAME`"
fi
echo "----当前路径：" $CUR
# 项目列表
starttime=$(date +%H%M%S)

name_array=()
i=0
echo "*****读取${list_file} 项目列表"
while read line
do
  echo "*项目名：" $line
  name=$line
  name_array[$i]=$name
  let i++
done < ${CUR}/${list_file}
echo "*****循环拉取处理git项目"
#########并发 准备##########
# mkfifo
tempfifo="my_temp_fifo"
mkfifo ${tempfifo}
# 使文件描述符为非阻塞式
exec 6<>${tempfifo}
rm -f ${tempfifo}

# 为文件描述符创建占位信息
for ((i=1;i<=${thread_num};i++))
do
{
    echo 
}
done >&6 
#######################
for name in ${name_array[@]};
do
{
    read -u6
    {
      echo "----start ${name}" 
      pro_name=${name##*/}
      echo $pro_name
      cd $CUR
      #echo "----$name 当前路径" $PWD
      git clone ${git_url}${name}.git
      cd $CUR/$pro_name
      #echo "----$name 当前路径" $PWD
      svn mkdir --parents ${svn_url}${name}/trunk ${svn_url}${name}/branches ${svn_url}${name}/tags -m "Importing git repo http://${git_name}@${git_ip}/${name}" ${svn_login}
      #git config core.whitespace nowarn
      #git config apply.whitespace nowarn
      git svn init  ${svn_url}${name} -s --prefix=origin/
      git svn fetch
      rm -rf .git/info/grafts
      if [[ -n "$1" && "$1" = "rebase" ]]; then
          ### rebase 方式
          echo "----rebase模式" ${name}
          git rebase origin/trunk --ignore-whitespace
          #git rebase --onto trunk --root
          ### 提交到svn库
          echo "----开始提交" ${name}
          git svn dcommit 
      else
          ### 提交版本历史
          # 获取提交id
          echo "----git version id模式" ${name}
          svn_id=$(git show-ref trunk)
          #echo "----${name} svn_id" ${svn_id%% *}
          git_id=$(git log --pretty=oneline master | tail -n 1)
          #echo "----${name} git_id" ${git_id%% *}
          echo "${git_id%% *} ${svn_id%% *}" > .git/info/grafts
          echo "----开始提交" ${name}
          git svn dcommit
      fi
      ####################################分支提交
      cd $CUR/$pro_name
      branches=$(git branch -r)
      #echo "----branches ${branches}"
      branches=$(echo "${branches}" | awk -vORS=' '  '{ print $1 }' | sed 's/ $//')
      echo "----分支迁移 ${name}"
      for b_name in ${branches[@]};
      do {
        #echo "----分支名：${b_name}"
        b_short_name=${b_name##*/}
        ### 忽略 HEAD master trunk git2svn*
        if [[ "$b_short_name" != "HEAD" && "$b_short_name" != "master" && "$b_short_name" != "trunk" && "$b_short_name" != git2svn* ]]; then
            echo "----开始迁移分支：${b_name}"
            git pull origin ${b_short_name}:${b_short_name}            
            svn cp ${svn_url}${name}/trunk ${svn_url}${name}/branches/git2svn-${b_short_name} -m " import http://${git_name}@${git_ip}/${name}  分支${b_short_name}"
            git svn fetch
            git checkout ${b_short_name}
            rm -rf .git/info/grafts
            if [[ -n "$2" && "$2" = "rebase" ]]; then
                ### rebase 方式
                echo "----rebase模式" ${b_short_name}
                git rebase remotes/origin/git2svn-${b_short_name}
                ### 提交到svn库
                echo "----开始提交branch" ${b_short_name}
                git svn dcommit 
            else
                ### 提交版本历史
                # 获取提交id                
                echo "----git version id模式" ${b_short_name}
                svn_id=$(git show-ref remotes/origin/git2svn-${b_short_name})
                echo "----${b_short_name} svn_id" ${svn_id%% *}
                git_id=$(git log --pretty=oneline ${b_short_name} | tail -n 1)
                echo "----${b_short_name} git_id" ${git_id%% *}
                echo "${git_id%% *} ${svn_id%% *}" > .git/info/grafts
                echo "----开始提交branch" ${b_short_name}
                git svn dcommit
            fi
        fi
      }
      done      
      
      ####################################tag提交
      cd $CUR/$pro_name
      branches=$(git tag -l)
      #echo "----tags ${branches}"
      branches=$(echo "${branches}" | awk -vORS=' '  '{ print $1 }' | sed 's/ $//')
      echo "----tag迁移 ${name}"
      for b_name in ${branches[@]};
      do {
        #echo "----tag名：${b_name}"
        b_short_name=${b_name}
        ### 忽略 HEAD master trunk git2svn*
        if [[ "$b_short_name" != "HEAD" && "$b_short_name" != "master" && "$b_short_name" != "trunk" && "$b_short_name" != git2svn* ]]; then
            echo "----开始迁移tag：${b_name}"
            #git checkout -b gittag-${b_short_name} ${b_short_name}            
            svn cp ${svn_url}${name}/trunk ${svn_url}${name}/tags/git2svn-tag-${b_short_name} -m " import http://${git_name}@${git_ip}/${name}  tag${b_short_name}"
            git svn fetch
            git checkout -b gittag-${b_short_name} ${b_short_name}
            rm -rf .git/info/grafts
            if [[ -n "$2" && "$2" = "rebase" ]]; then
                ### rebase 方式
                echo "----rebase模式" ${b_short_name}
                git rebase remotes/origin/tags/git2svn-tag-${b_short_name}
                ### 提交到svn库
                echo "----开始提交tag" ${b_short_name}
                git svn dcommit 
            else
                ### 提交版本历史
                # 获取提交id                
                echo "----git version id模式" ${b_short_name}
                svn_id=$(git show-ref remotes/origin/tags/git2svn-tag-${b_short_name})
                echo "----${b_short_name} svn_id" ${svn_id%% *}
                git_id=$(git log --pretty=oneline gittag-${b_short_name} | tail -n 1)
                echo "----${b_short_name} git_id" ${git_id%% *}
                echo "${git_id%% *} ${svn_id%% *}" > .git/info/grafts
                echo "----开始提交tag" ${b_short_name}
                git svn dcommit
            fi
        fi
      }
      done      
        
      echo "----end ${name}"
        echo "" >&6
    } & 
} 
done 

wait

# 关闭fd6管道
exec 6>&-

endtime=$(date +%H%M%S)

echo "全部完成"
echo -e "开始时间:\t${starttime}"
echo -e "结束时间:\t${endtime}"