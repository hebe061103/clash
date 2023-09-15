#!/bin/bash
#开始整理config.yaml配置文件并提取代理
date=$(date "+%Y-%m-%d %H:%M:%S")
echo --$date-- "------------------------同步clash配置到github-------------------------" |tee -a /tmp/clash_run_log.log
parm_path=$(cd `dirname $0`; pwd)
cp $parm_path/formwork.update_to_github /tmp/no_dns_config.yaml
for filename in $(ls /tmp/node_config.yaml)
do
  while read line
  do
  if echo $line | grep "{name:";then
  sed -i '/以上为代理地址请插入/i\'"  $line"'' /tmp/no_dns_config.yaml
  a=${line#*:}
  b=${a%%,*}
  sed -i '/以上为节点选择组的自动选择代理请插入/i\'"      -$b"'' /tmp/no_dns_config.yaml
  sed -i '/以上为自动选择组下面的代理地址请插入/i\'"      -$b"'' /tmp/no_dns_config.yaml
  sed -i '/以上为负载均衡组下面的代理地址请插入/i\'"      -$b"'' /tmp/no_dns_config.yaml
  sed -i '/以上为故障转移组下面的代理地址请插入/i\'"      -$b"'' /tmp/no_dns_config.yaml
  sed -i '/以上为漏网之鱼组下面的代理地址请插入/i\'"      -$b"'' /tmp/no_dns_config.yaml
  fi
  done < $filename
done
cd $parm_path
cp /tmp/no_dns_config.yaml config.yaml
cp /tmp/config_cl.yaml config_dns.yaml
cp /tmp/allnode_config.yaml ./
while true;
do
date=$(date "+%Y-%m-%d %H:%M:%S")
echo "$date 更新!" > README.md
git init
git add ./
git commit -m "$date"
git remote set-url origin https://${GITHUBTOKEN}@github.com/hebe061103/clash.git
result=`git push -u origin master  >> /tmp/pullgithub.log 2>&1`
if echo "$result" | grep -e "set up to track remote branch";then
date=$(date "+%Y-%m-%d %H:%M:%S")
echo --$date-- "------------------------同步到github成功-------------------------" |tee -a /tmp/clash_run_log.log
break
else
date=$(date "+%Y-%m-%d %H:%M:%S")
echo --$date-- "------------------------同步到github失败-------------------------" |tee -a /tmp/clash_run_log.log
break
fi
done
