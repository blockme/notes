#!/bin/bash
#Stat the number of different file type of target Directory
#author lan
#time 2014-06-20 15:16
#1: function 定义需要使用之前，貌似是脚本语言的通用原则
#2: 变量类型的自动转换。默认会首先尝试转为numberic.若需强制转string==>expr "".具体参考man awk

start=`date +'%s'`
[ -z  "$1" ]&& target="."
target=`cd "$1";pwd -P`
find "$target" -type f|
	awk -F/ '{print $NF}'|
	 	awk -F. '	{sum++;typeArr[$NF]++}
				END{
					printf("%-20s %10d\n","total:",sum)
					for (ftype in typeArr) printf("%-20s %10d %10.2f%% \n",ftype,typeArr[ftype],typeArr[ftype]/sum*100)
				} '|
			sort -nr -k2|less
