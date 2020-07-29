#!/bin/sh

if [ -f "$1" ]; then #如果文件不存在 则退出
    LOG=$1 
else
    echo "文件不存在，请重新输入："
    exit
fi

auth_sum=`grep -r "silfp_algo_auth:" ./$LOG | wc -l` #反引号将命令行赋值给变量
echo "识别总次数：${auth_sum}" #打印找到的总的识别次数
auth_finish=`grep -r "Finger matched (0)" ./$LOG | wc -l` #反引号将命令行赋值给变量
echo "识别成功次数：${auth_finish}" #打印识别成功次数
echo "识别成功统计："

auth_finish_count=`grep -r "Finish identifyImage coverage=100, quality=.., fid=0, score=9." ./$LOG |awk '{print $3}'`
touch ss.txt
echo ${auth_finish_count} > ss.txt  #将找的的六次成功的时间存至TXT文档

time=() #用于存储时间差值
function T_diff() {

    start_time=$1
    end_time=$2
    count=$3  #传入参数
    
    start_s=${start_time%.*} #提取.前面的字符
    start_nanos=${start_time#*.} #提取后缀
    end_s=${end_time%.*}
    end_nanos=${end_time#*.}
    
    time1=$(date +%s -d "${start_s}")
    time2=$(date +%s -d "${end_s}") #转化格式 进行时间戳转化
    
    if [ $start_nanos -lt $end_nanos ] #10 -lt 20: a 小于 b  如果结束时间毫秒小于开始时间 说明要计算秒 不然直接毫秒做差
    then 
        time[$count]=`expr ${end_nanos} - ${start_nanos}` #毫秒计算
    else
        time[$count]=$(( ($time2 - $time1) * 1000 - ($start_nanos - $end_nanos) ))   #计算秒，毫秒
    fi
}

auth_sum=0 #用于计算均值
#-----------动态 while循环-----------#
loop=0
while [ $loop -le `expr $auth_finish - 1` ]
do 
    echo "    ${loop}"
    loop_1=`expr $loop + 1`
    array_E[$loop]=`cat ss.txt | awk '{print $'${loop_1}'}'` #输出第loop+1个域 
    array_S[$loop]=`grep -B 12 "${array_E[$loop]}" ./$LOG| grep 'fp_identifyImage_identify:223'| awk '{print $3}'` 
    #利用识别完成的时间关键字 定位到识别成功那一行 之后读取其前面12行 定位到识别开始的log 再读取开始识别的时间
    T_diff ${array_S[$loop]} ${array_E[$loop]} $loop #将两次时间和第几个log传入函数 进行时间差计算
    echo -e "    ${array_S[$loop]} start"
    echo -e "    ${array_E[$loop]} end\n"
    auth_sum=`expr ${auth_sum} + ${time[$loop]}` #求和
    loop=`expr $loop + 1` 
done

echo -e "识别成功 ${auth_finish} 次耗时:"
for((i=0; i<$auth_finish; i=i+1))
do
    printf "  ${time[$i]}  "
done

auth_sum=$((auth_sum * 100 / $auth_finish)) #求均值
echo -e "\n识别成功平均耗时：$((auth_sum / 100)).$((auth_sum % 100)) us"

rm -rf ss.txt 



