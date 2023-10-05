#!/bin/bash
#定时执行任务
#0 15 * * *
#对于raw.githubusercontent.com无法下载的使用下面加速地址
#https://ghproxy.com/
#------------------------------------------------------------------------------------------------------
get_arch=`arch`
subdz="https://sub.789.st/sub?target=clash"
#设置只提取平均速度大于多少M的节点,例如:10M*1024*1024=10485760,只能设置整数
speed_gt=1
let avg_speed=$speed_gt*1024*1024
#模板文件路径
parm_path=$(cd `dirname $0`; pwd)
date=$(date "+%Y-%m-%d %H:%M:%S")
echo --$date-- "-----------------------开始更新CLASH配置文件----------------------" |tee -a /tmp/clash_run_log.log
#删除排序文件
cd /tmp
rm -rf line.log node_config.yaml config_cl.yaml
rm -rf /mnt/updateClashToGithub/node
cp $parm_path/formwork /tmp/newconfig
date1=$(date "+%Y")
date2=$(date "+%m")
date3=$(date "+%d")
date4=$(date "+%Y%m%d")
#以下列表可插入能直接下载的配置文件网址
urllist=("https://ghproxy.com/https://raw.githubusercontent.com/openrunner/clash-freenode/main/clash.yaml"
"https://ghproxy.com/https://raw.githubusercontent.com/ermaozi/get_subscribe/main/subscribe/clash.yml"
"https://clashnode.com/wp-content/uploads/$date1/$date2/$date4.yaml"
"$subdz&url=https://ghproxy.com/https://raw.githubusercontent.com/Jsnzkpg/Jsnzkpg/Jsnzkpg/Jsnzkpg"
)
for i in ${urllist[@]}
    do
    a=${i#*//}
    b=${a%%.*}
    let c++
    get=`aria2c -d /run -o $b$c.yaml $i -l /tmp/aria2c.log 2>&1`
    echo $get >> /tmp/clash_run_log.log
    if echo "$get" | grep -e "download completed";then
    date=$(date "+%Y-%m-%d %H:%M:%S")
    echo --$date-- "下载完成!" |tee -a /tmp/clash_run_log.log
    else
    echo --$date-- "下载失败!" |tee -a /tmp/clash_run_log.log
    let err++
    if [ $err -eq "${#urllist[@]}" ];then
        echo --$date-- "当前共:""${#urllist[@]}""个订阅地址,并且全部下载出错,无可用信息,巳结束运行!!" |tee -a /tmp/clash_run_log.log
        exit 1
    fi
    fi
    done
echo "------------------------------------------please wait!----------------------------------------------------"
echo "----------------------------------------------------------------------------------------------------------"
echo "----------------------------------------------------------------------------------------------------------"
sleep 3
echo --$date-- "准备获取全部节点列表"|tee -a |tee -a /tmp/line.log
for filename in $(ls /run/*.yaml)
do
  while read line
  do
  if echo $line | grep "{name:" | grep -v "中国";then
     a=${line#*, }
     random=`head /dev/urandom | tr -dc A-Za-z0-9 | head -c 15`
     echo "- {name: 吉祥|"$random"|, "$a >> /mnt/updateClashToGithub/node
  fi
  if echo $line | grep -q "proxy-groups:";then
       break
  fi
  done < $filename
done
rm -rf /run/*.yaml
#-------------------------------------------------------------------------------------------------
echo --$date-- "节点服务器去重"|tee -a /tmp/clash_run_log.log
for filename in $(ls /mnt/updateClashToGithub/node)
do
  while read line
  do
  if echo $line | grep "{name:";then
     a=${line#*, }
     b=${a%%,*} #server:$b
     c=${a#*port:}
     d=${c%%,*} #port:$d
     echo "$b," port:"$d" >>/tmp/samenodeserver
  fi
done < $filename
done
temp1=`sort /tmp/samenodeserver|uniq -d`
if [[ "$temp1" != "" ]];then
echo "$temp1" >>/tmp/same
for filename in $(ls /tmp/same)
do
  while read line
  do
   s=`cat /mnt/updateClashToGithub/node |grep -n "$line"|cut -f1 -d:`
   delnum=($s)
   del=$["${#delnum[@]}" - 1]
   for ((i=0; i<$del; i++));do
       n="${delnum[$i]}"
       #给要删除的行做标记
       sed -i "${n},${n}s/- {name/mark-del/g" /mnt/updateClashToGithub/node
   done
  done < $filename
done
#删除重复节点的数量
for filename in $(ls /mnt/updateClashToGithub/node);do
    while read line;do
        if echo $line | grep "mark-del";then
            let x++
        fi
    done < $filename
done
date=$(date "+%Y-%m-%d %H:%M:%S")
echo --$date-- "需要从可用节点中删除重复服务器节点的数量为:"$x |tee -a /tmp/clash_run_log.log
sed -i -e "/mark-del/d" /mnt/updateClashToGithub/node #删除所有标记的重复行
sed -i -e "/vless,/d"   /mnt/updateClashToGithub/node #删除不可识别的代理类型
echo --$date-- "可用节点服务器完成去重"|tee -a /tmp/clash_run_log.log
rm -rf /tmp/same
else
echo --$date-- "没有重复的节点服务器" |tee -a /tmp/clash_run_log.log
fi
rm -rf /tmp/samenodeserver
#---------------------------------------------------------------------------------------------
#提取代理与模板文件进行合并并生成新的配置文件
for filename in $(ls /mnt/updateClashToGithub/node)
do
  while read line
  do
  if echo $line | grep "{name:" ;then
  sed -i '/以上为代理地址请插入/i\'"  $line"'' /tmp/newconfig
  a=${line#*:}
  b=${a%%,*}
  sed -i '/以上为节点选择组的自动选择代理请插入/i\'"      -$b"'' /tmp/newconfig
  sed -i '/以上为自动选择组下面的代理地址请插入/i\'"      -$b"'' /tmp/newconfig
  sed -i '/以上为负载均衡组下面的代理地址请插入/i\'"      -$b"'' /tmp/newconfig
  sed -i '/以上为故障转移组下面的代理地址请插入/i\'"      -$b"'' /tmp/newconfig
  sed -i '/以上为漏网之鱼组下面的代理地址请插入/i\'"      -$b"'' /tmp/newconfig
  fi
  if echo $line | grep -q "proxy-groups:";then
       break
  fi
  done < $filename
done
date=$(date "+%Y-%m-%d %H:%M:%S")
echo --$date-- "订阅文件合并完成!" |tee -a /tmp/clash_run_log.log
mv /tmp/newconfig /tmp/allnode_config.yaml
#----------------------------------------------------------------------------------------------
date=$(date "+%Y-%m-%d %H:%M:%S")
echo --$date-- "开始测速!" |tee -a /tmp/clash_run_log.log
cd $parm_path
if [[ $get_arch =~ "x86_64" ]];then
    echo "第统类型:x86_64"
    ./lite-linux-amd64 --config ./config.json --test /tmp/allnode_config.yaml
elif [[ $get_arch =~ "armv7l" ]];then
    echo "第统类型:armv7l"
    ./lite-linux-armv7 --config ./config.json --test /tmp/allnode_config.yaml
else
    echo "系统类型不支持!!"
fi
date=$(date "+%Y-%m-%d %H:%M:%S")
echo --$date-- "测速完成!" |tee -a /tmp/clash_run_log.log
#----------------------------------------------------------------------------------------------
for filename in $(ls /tmp/allnode_config.yaml)
do
  while read line
  do
  if echo $line | grep "{name:";then
    echo $line >> /tmp/node_config.yaml
  fi
  if echo $line | grep -q "proxy-groups:";then
       break
  fi
  done < $filename
done
#----------------------------------------------------------------------------------------------
#多线程筛选可用节点部分
linksCount=$(cat $parm_path/output.json | jq -r '.linksCount')
args1=$[$linksCount/4]
chuthree=$[$[$linksCount-$args1]/3]
args2=$[$args1+$chuthree]
chutwo=$[$[$linksCount-$args1-$chuthree]/2]
args3=$[$args1+$chuthree+$chutwo]
args4=$linksCount
start_time=`date +%s`  #定义脚本运行的开始时间
getNode(){
for ((i=$1; i<$2; i++))
do
var=$(cat $parm_path/output.json | jq -r '.nodes['$i'].avg_speed')
if [ $var -lt $avg_speed ];then
    invalid=`cat ./output.json | jq -r '.nodes['$i'].remarks'|sed 's/+/ /g'`
    echo "$invalid" >>/tmp/invalidnode.mp
else
    valid=`cat ./output.json | jq -r '.nodes['$i'].remarks'|sed 's/+/ /g'`
    echo "$valid" >>/tmp/validnode.mp
fi
done
}
getNode 0 $args1 &
getNode $args1 $args2 &
getNode $args2 $args3 &
getNode $args3 $args4 &
wait
stop_time=`date +%s` # 定义脚本运行的结束时间
date=$(date "+%Y-%m-%d %H:%M:%S")
echo --$date-- "多线程查询可用节点用时:`expr $stop_time - $start_time`s" |tee -a /tmp/clash_run_log.log
#----------------------------------------------------------------------------------------------
for filename in $(ls /tmp/invalidnode.mp)
do
  while read line
  do
        remarks_array[$l]=$line
  	let l++
  done < $filename
done
for filename in $(ls /tmp/validnode.mp)
do
  while read line
  do
        normal_num[$y]=$line
  	let y++
  done < $filename
done
rm -rf /tmp/*.mp  #清理线程临时文件
#----------------------------------------------------------------------------------
date=$(date "+%Y-%m-%d %H:%M:%S")
echo --$date-- "正常可用的节点数量:""${#normal_num[*]}"|tee -a /tmp/clash_run_log.log
echo --$date-- "正常可用的节点数量:""${#normal_num[*]}" |tee -a /tmp/line.log
for ((i=0; i<"${#normal_num[*]}";i++))
do
    let o++
    str_num=`echo "${normal_num[$i]}"|awk '{print length($0)}'`
    echo "第:"$o"节点----""${normal_num[$i]}" "字符:"$str_num |tee -a /tmp/line.log
done
date=$(date "+%Y-%m-%d %H:%M:%S")
echo --$date-- "待删除的节点数量:""${#remarks_array[*]}" |tee -a /tmp/clash_run_log.log
echo --$date-- "待删除的节点数量:""${#remarks_array[*]}" |tee -a /tmp/line.log
#----------------------------------------------------------------------------------------------
echo --$date-- "开始排序待删除的:""${#remarks_array[*]}""个节点......"|tee -a /tmp/clash_run_log.log
start_time=`date +%s`  #定义脚本运行的开始时间
MAX=`echo "${remarks_array[0]}" | awk '{print length($0)}'`
for I in ${!remarks_array[@]};do
    MIN=`echo "${remarks_array[$I]}"|awk '{print length($0)}'`
    allnum[$I]=$MIN
    if [[ ${MAX} -le ${MIN} ]];then
        MAX=${MIN}
    fi
done
echo "MAX:" $MAX
for (( l=0; l<=$MAX; l++ ));do
    for (( s=0; s<"${#allnum[@]}"; s++ ));do
    m="${allnum[$s]}"
    if [ $m -eq $l ];then
        jump[$l]=$l
    fi
    done
done
for (( l=0; l<=$MAX; l++ ));do
    if [ "${jump[$l]}" != "" ];then
        jumpnum[$w]=$l
        let w++
    fi
done
for (( s="${#jumpnum[@]}"; s>=0; s-- ))
do
    for (( i=0; i<"${#remarks_array[*]}"; i++ ))
        do
        num2=`echo "${remarks_array[$i]}" | awk '{print length($0)}'`
        num3="${jumpnum[$s]}"
        if [[ $num2 -eq $num3 ]];then
            echo "${remarks_array[$i]}" "字符:" $num2
            echo "${remarks_array[$i]}" >> /tmp/node.ss
        fi
    done
done
unset remarks_array
for filename in $(ls /tmp/node.ss)
do
  while read line
  do
      remarks_array[$r]=$line
      let r++
  done < $filename
done
rm /tmp/node.ss
stop_time=`date +%s` # 定义脚本运行的结束时间
echo --$date-- "排序用时:`expr $stop_time - $start_time`s" |tee -a /tmp/clash_run_log.log
date=$(date "+%Y-%m-%d %H:%M:%S")
echo --$date-- "节点排序完成" |tee -a /tmp/clash_run_log.log
#----------------------------------------------------------------------------------------------
echo --$date-- "准备删除低速节点" |tee -a /tmp/line.log
echo --$date-- "开始清理低速节点"|tee -a /tmp/clash_run_log.log
for ((i=0; i<"${#remarks_array[*]}";i++))
do
let j++
str_num=`echo "${remarks_array[$i]}"|awk '{print length($0)}'`
echo  "删除第"$j"个节点:""${remarks_array[$i]}" "字符:"$str_num |tee -a /tmp/line.log
line=`cat /tmp/node_config.yaml | grep -n "${remarks_array[$i]}" | sed 's/:/d;:/g' |awk -F ":" '{print $1}' | xargs |sed 's/[[:space:]]*//g'`
dellaststr=`echo $line |sed 's/.$//'`
array=(${line//d;/ })
if [ "${#array[*]}" -gt 1 ];then
for ((k=0; k<"${#array[*]}"; k++))
do
str=`sed -n "${array[$k]}"p /tmp/node_config.yaml`
names=`echo ${str#*name:}`
cutnames=`echo ${names%%,*}`
if [ "$cutnames" = "${remarks_array[$i]}" ];then
echo "该行疑似包含其它可用节点,将删除该行" |tee -a /tmp/line.log
echo "截取到该行内容包含:"$cutnames |tee -a /tmp/line.log
sed -i "${array[$k]}"d /tmp/node_config.yaml
echo "${#array[$k]}" |tee -a /tmp/line.log
fi
done
else
sed -i "${dellaststr}" /tmp/node_config.yaml
echo $dellaststr |tee -a /tmp/line.log
fi
done
date=$(date "+%Y-%m-%d %H:%M:%S")
echo --$date-- "低速节点清理完成"|tee -a /tmp/clash_run_log.log
echo --$date-- "低速节点删除完成"|tee -a /tmp/line.log
#----------------------------------------------------------------------------------------------
#开始整理config.yaml配置文件并提取代理合并入文件
echo --$date-- "开始整理配置文件并提取代理" |tee -a /tmp/clash_run_log.log
cp $parm_path/formwork /tmp/newconfig
for filename in $(ls /tmp/node_config.yaml)
do
  while read line
  do
  if echo $line | grep "{name:";then
  sed -i '/以上为代理地址请插入/i\'"  $line"'' /tmp/newconfig
  a=${line#*:}
  b=${a%%,*}
  sed -i '/以上为节点选择组的自动选择代理请插入/i\'"      -$b"'' /tmp/newconfig
  sed -i '/以上为自动选择组下面的代理地址请插入/i\'"      -$b"'' /tmp/newconfig
  sed -i '/以上为负载均衡组下面的代理地址请插入/i\'"      -$b"'' /tmp/newconfig
  sed -i '/以上为故障转移组下面的代理地址请插入/i\'"      -$b"'' /tmp/newconfig
  sed -i '/以上为漏网之鱼组下面的代理地址请插入/i\'"      -$b"'' /tmp/newconfig
  fi
  done < $filename
done
echo --$date-- "代理提取完成并成功生成配置文件" |tee -a /tmp/clash_run_log.log
mv /tmp/newconfig /tmp/config_cl.yaml
echo --$date-- "配置文件以生成到:/tmp/config_cl.yaml,更新完成!" |tee -a /tmp/clash_run_log.log
restart_clash(){
date=$(date "+%Y-%m-%d %H:%M:%S")
echo --$date-- "------------------------重启CLASH-----------------------------" |tee -a /tmp/clash_run_log.log
rm /usr/local/clash/config.yaml
cp /tmp/config_cl.yaml  /usr/local/clash/config.yaml
systemctl restart clash.service
date=$(date "+%Y-%m-%d %H:%M:%S")
echo --$date-- "------------------------重启CLASH完成-------------------------" |tee -a /tmp/clash_run_log.log
}
restart_clash #cp配置文件到clash配置目录并重启clash
date=$(date "+%Y-%m-%d %H:%M:%S")
#执行github同步脚本
$parm_path/Creategithubfile.sh
#清除日志内容
a=$(grep -c "" /tmp/clash_run_log.log)
if [ $a -gt 106 ]; then
    rm /tmp/clash_run_log.log
fi
#附节点订阅地址
#https://github.com/freefq/free    freefq/free, 节点数量: 34
#https://github.com/oslook/clash-freenode    oslook/clash-freenode, 节点数量: 42
#https://github.com/ssrsub/ssr     ssrsub/ssr, 节点数量: 82
#https://github.com/Leon406/SubCrawler    Leon406/SubCrawler, 节点数量: 3272
#https://github.com/iwxf/free-v2ray    iwxf/free-v2ray, 节点数量: 39
#https://github.com/Jsnzkpg/Jsnzkpg    Jsnzkpg/Jsnzkpg, 节点数量: 80
#https://github.com/ermaozi/get_subscribe    ermaozi/get_subscribe, 节点数量: 38
#https://github.com/wrfree/free     wrfree/free, 节点数量: 34
#https://github.com/GreenFishStudio/GreenFish    GreenFishStudio/GreenFish, 节点数量: 56
#https://github.com/anaer/Sub    anaer/Sub, 节点数量: 246
#https://github.com/mhmhone/shadowrocket-free-subscribe    mhmhone/shadowrocket-free-subscribe, 节点数量: 32
#https://github.com/aiboboxx/v2rayfree    aiboboxx/v2rayfree, 节点数量: 46
#https://github.com/moneyfly1/sublist    moneyfly1/sublist, 节点数量: 15
#https://github.com/Pawdroid/Free-servers    Pawdroid/Free-servers, 节点数量: 15
#https://github.com/Fukki-Z/nodefree    Nodefree.org, 节点数量: 50
#https://github.com/snakem982/proxypool
