#!/bin/bash
username=''
userService=''
PATH_CONFIG="./config"
PATH_USER="$PATH_CONFIG/user"
PATH_TERMINAL="$PATH_CONFIG/terminal"
terminal=$(tty)
time=$(date +"%Y-%m-%d-%H-%M-%S")
#u用户 pwd密码 m所有机器 t已连接的终端和每个终端登录的机器 d每个终端连接的时间 o已连接的机器 h每台机器的登录时间 a:finger n总共终端数，只有第一行记录
declare -A userIndex=([u]=1 [pwd]=2 [m]=3 [a]=4 [msg]=5)
declare -A terminalIndex=([t]=1 [u]=2 [m]=3 [tt]=4 [mt]=5)

function initAdmin(){
    #初始化文件夹
    [ -d $PATH_CONFIG ] || mkdir $PATH_CONFIG
    #如果存在user文件，则登录；如果不存在，则注册
    #user文件第一行为管理员，不可以移动
    if [ -e $PATH_USER ]; then
        #输入管理员名字
        echo ">Please enter the name of administrator: "
        read -p ">" username
        local userList=$(cut -d":" -f${userIndex[u]} $PATH_USER | tr "\n" ",")
        while [ -z $(echo $userList | grep "\<$username\>") ]; do
            echo "The user $username is not existed !"
            read -p ">" username
        done
        #输入管理员密码
        echo ">Please enter the $username's password:"
        read -p ">" -s passwd
        echo
        local passwdRight=$(grep "^\<$username\>" $PATH_USER | cut -d":" -f${userIndex[pwd]})
        while [ "$passwdRight" != "$passwd" ]; do
            echo "Password is incorrect ! "
            read -p ">" -s passwd
            echo
        done
        #输入登录机器名字
        local machinesList=$(cut -d':' -f${userIndex[m]} $PATH_USER | grep ^[^01])
        echo ">Please enter a machine name: "
        read -p ">" userService
        while [ -z $(echo $machinesList | grep "\<$userService\>") ]; do
            echo "The machine $userService does not exist ! "
            echo "MACHINE LIST : $machinesList"
            read -p ">" userService
        done
        #写入终端文件
        local time=$(date +"%Y-%m-%d-%H-%M-%S")
        ([ -e $PATH_TERMINAL ] || touch $PATH_TERMINAL) && echo $terminal:$username:$userService:$time:$time >> $PATH_TERMINAL
    else
        #创造一个管理员
        echo ">Please enter a root name for initing an administrator:"
        read -p ">" username
        while [ true ]; do
            if [ -z $username ]; then
                echo ">The name cannot be empty:"
                read -p ">" username
            elif [ ! -z $(echo $username | grep ^[^a-zA-Z]) ]; then
                echo ">The name cannot start with a non-alphabetic character:"
                read -p ">" username
            else
                break
            fi
        done
        #设置管理员密码
        local passwdRight
        echo ">Please enter a password for initing an administrator:"
        read -p ">" -s passwd
        echo
        echo ">Please enter the password again to confirm the password:"
        read -p ">" -s passwdRight
        echo
        while [ true ];do
            if [ "$passwd" == "$passwdRight" ];then
                break
            else
                echo ">The password entered again incorrectly ! "
                echo ">Please enter a password for initing an administrator:"
                read -p ">" -s passwd
                echo
                echo ">Please enter the password again to confirm the password:"
                read -p ">" -s passwdRight
                echo
            fi
        done
        #初始化机器
        echo ">Please enter a machine name for initing an administrator:"
        read -p ">" userService
        while [ true ]; do
            if [ -z $userService ]; then
                echo ">The machine name cannot be empty:"
                read -p ">" userService
            elif [ ! -z $(echo $userService | grep ^[^a-zA-Z]) ]; then
                echo ">The machine name cannot start with a non-alphabetic character:"
                read -p ">" userService
            else
                break
            fi
        done
        #写入对应文件
        touch $PATH_USER && echo $username:$passwd:$userService:: > $PATH_USER
        local time=$(date +"%Y-%m-%d-%H-%M-%S")
        touch $PATH_TERMINAL && echo $terminal:$username:$userService:$time:$time > $PATH_TERMINAL
    fi
}

#输入列，单词，文件，获得有该字符串的行
#getLine column word filePath
function getLine(){
    local col=$1
    local word=$2
    local file=$3
    local num=$(cut -d":" -f$col $file | grep -n '\<'$word'\>' | cut -d":" -f1)
    if [ ! -z "$num" ];then
        for i in $num;do
            sed -n ''$i'p' $file
        done
    fi
}

#参数用户名字，获取用户可以访问的机器
#getUserMachine username
function getUserMachine() {
    if [ "$1" == "$rootName" ]; then
        echo $(cut -d":" -f${userIndex[m]} $PATH_USER | grep ^[^01] | tr "," " ")
    else
        local machineList=$(grep "^$rootName:" $PATH_USER | cut -d":" -f${userIndex[m]})
        local userMachineList=$(grep "^$1:" $PATH_USER | cut -d":" -f${userIndex[m]} |
            awk 'BEGIN{FS=",";j=0;}
            {for(i=1;i<=NF;i++) if($i=="1") arr[j++]=i;}
            END {for(i=0;i<j;i++) print arr[i] }')
        local userMachine
        for i in $userMachineList; do
            userMachine="$userMachine $(echo $machineList | cut -d"," -f$i)"
        done
        echo $userMachine
    fi
}

function getPosOfMachine(){
    local machine=$1
    local path=$2
    awk 'BEGIN{ FS=OFS=":" }{if( $'${userIndex[m]}'!~/^[01]/ ) print $'${userIndex[m]}'}' $path | awk 'BEGIN{ FS=OFS="," }{for(i = 1;i <= NF; i++) if( $i == "'$machine'" ) print(i)}'
}

function getNumOfMachine() {
    local path=$1
    awk 'BEGIN{ FS=OFS=":" }{if( $'${userIndex[m]}'!~/^[01]/ ) print $'${userIndex[m]}'}' $path | awk 'BEGIN{ FS=OFS="," }{print NF}'
}

function user(){
    shift
    local usersList=$(cut -d":" -f${userIndex[u]} $PATH_USER | tr "\n" " ")
    if [ $# -eq 0 ]; then
        echo $usersList
    elif [ $# -ge 2 ]; then
        local arg=$1
        shift
        local us=$*
        # 添加用户
        if [ "$arg" == "-a" ] || [ "$arg" == "--add" ]; then
            for u in ${us[*]}; do
                # 更新用户列表
                usersList=$(cut -d":" -f${userIndex[u]} $PATH_USER | tr "\n" ",")
                if [ ! -z $(echo $u | grep ^[^a-zA-Z]) ]; then
                    echo "The name $u cannot start with a non-alphabetic character:"
                elif [ -z $(echo "$usersList" | grep "\<$u\>") ]; then
                    # 设置密码
                    local passwd
                    echo "${myPrompt}Please set a password($u) : "
                    read -p $myPrompt -s passwd
                    echo
                    local num=$(getNumOfMachine $PATH_USER)
                    local machineAccess=''
                    for ((i = 0; i < $num; i++)); do
                        machineAccess="0,${machineAccess}"
                    done
                    machineAccess=$(echo $machineAccess | sed 's/,$//')
                    # 追加进文件
                    sed -i '$a\'$u':'$passwd':'$machineAccess'::' $PATH_USER
                    echo "User $u created successfully ! "
                else
                    echo "The user $u is existed ! "
                fi
            done
        # 删除用户
        elif [ "$arg" == "-d" ] || [ "$arg" == "--delete" ]; then
            for u in ${us[*]}; do
                if [ ! -z "$(echo "$usersList" | grep "\<$u\>")" ]; then
                    sed -i '/^'$u'.*/d' $PATH_USER
                    echo "User $u deleted successfully ! "
                else
                    echo "The user $u dosen't exist ! "
                fi
            done
        # 删减用户的机器权限
        elif [ "$arg" == "+" ] || [ "$arg" == "-" ]; then
            local machinesList=$(cut -d':' -f${userIndex[m]} $PATH_USER | grep ^[^01])
            if [ $# -ge 2 ]; then
                local u=$1
                shift
                if [ -z "$(echo "$usersList" | grep "\<$u\>")" ]; then
                    echo "The user $u dosen't exist ! "
                else
                    for machine in $*; do
                        if [ ! -z $(echo $machinesList | grep "\<$machine\>") ]; then
                        # 修改机器权限列
                            local pos=$(getPosOfMachine $machine $PATH_USER)
                            local userLine=$(getLine ${userIndex[u]} $u $PATH_USER)
                            local userLinePre=$(echo $userLine | awk 'BEGIN{FS=OFS=":"}{for(i=1;i<'${userIndex[m]}';i++) printf($i":")}')
                            local p
                            local ret=""
                            if [ "$arg" == "+" ]; then
                                p=1
                                ret="The user $u has permission to access the machine $machine ! "
                            elif [ "$arg" == "-" ]; then
                                p=0
                                ret="User $u has been revoked from accessing the machine $machine ! "
                            fi
                            local userLineMid=$(echo $userLine | awk 'BEGIN{FS=":"}{print $'${userIndex[m]}'}' | awk 'BEGIN{FS=OFS=","}{$'$pos'='$p';printf($0":")}')
                            local userLineSuf=$(echo $userLine | awk 'BEGIN{FS=OFS=":"}{for(i=('${userIndex[m]}'+1);i<=NF;i++) if(i!=NF) printf($i":") ; else print $i }')
                            local newUserLine=$userLinePre$userLineMid$userLineSuf
                            sed -i 's/'$userLine'/'$newUserLine'/' $PATH_USER
                            echo $ret
                        else
                            echo "The machine $machine doesn't exist ! "
                        fi
                    done
                fi
            else
                echo "Usage : user ( + | - ) username machine1 [machine2...] "
            fi
        # 修改用户密码
        elif [ "$arg" == "-p" ] || [[ "$arg" == "--password" ]]; then
            if [ $# -eq 2 ]; then
                # 修改密码列
                local u=$1
                local newPassword=$2
                local userLine=$(getLine ${userIndex[u]} $u $PATH_USER)
                local userLinePre=$(echo $userLine | awk 'BEGIN{FS=OFS=":"}{for(i=1;i<'${userIndex[pwd]}';i++) printf($i":")}')
                local userLineMid=$(echo $userLine | awk 'BEGIN{FS=OFS=":"}{$'${userIndex[pwd]}'='$newPassword'; printf($'${userIndex[pwd]}'":")}')
                local userLineSuf=$(echo $userLine | awk 'BEGIN{FS=OFS=":"}{for(i=('${userIndex[pwd]}'+1);i<=NF;i++) if(i!=NF) printf($i":") ; else print $i }')
                local newUserLine=$userLinePre$userLineMid$userLineSuf
                sed -i 's/'$userLine'/'$newUserLine'/' $PATH_USER
                echo "User $u password changed successfully ! "
            else
                echo "Usage : user -p username newPassword "
            fi
        else
            echo "Usage : user arg( -a | -d | + | - ... ) username1 [username2...]"
        fi
    else
        echo "Usage : user arg( -a | -d | + | - ... ) username1 [username2...]"
    fi
}

function host() {
    shift
    local machinesList=$(cut -d':' -f${userIndex[m]} $PATH_USER | grep ^[^01])
    if [ $# -eq 0 ]; then
        echo $machinesList | tr "," " "
    elif [ $# -ge 2 ]; then
        local arg=$1
        shift
        local ms=$*
        local m
        # 增加机器
        if [ "$arg" == "-a" ] || [ "$arg" == "--add" ]; then
            for m in ${ms[*]}; do
                if [ -z $(echo $machinesList | grep "\<$m\>") ]; then
                    if [ ! -z $machinesList ]; then
                        awk 'BEGIN{FS=OFS=":"}{if(/^'$rootName'/) $'${userIndex[m]}'=$'${userIndex[m]}'",'$m'"}
                        {if(/^[^'$username']/) $'${userIndex[m]}'=$'${userIndex[m]}'",0"}{print > "'$PATH_USER'"}' $PATH_USER
                    else
                        awk 'BEGIN{FS=OFS=":"}{if(/^'$rootName'/) $'${userIndex[m]}'="'$m'"}
                        {if(/^[^'$username']/) $'${userIndex[m]}'="0"}{print > "'$PATH_USER'"}' $PATH_USER
                    fi
                    echo "The machine $m created successfully ! "
                else
                    echo "The machine $m is existed ! "
                fi
            done
        # 删除机器
        elif [ "$arg" == "-d" ] || [ "$arg" == "--delete" ]; then
            for m in ${ms[*]}; do
                local machinesList=$(cut -d":" -f${userIndex[m]} $PATH_USER | grep ^[^01])                         
                if [ ! -z $(echo "$machinesList" | grep "\<$m\>") ]; then
                    local pos=$(getPosOfMachine $m $PATH_USER)
                    awk 'BEGIN{FS=OFS=":"}{print $'${userIndex[m]}'}' $PATH_USER | \
                    awk 'BEGIN{FS=OFS=","}{for(i = 1; i <= NF; i++) if( i != "'$pos'" ) printf($i",");printf(":\n")}' | \
                    paste - $PATH_USER | awk 'BEGIN{FS=OFS=":"}{$('${userIndex[m]}'+1)=$1;print $0 > "'$PATH_USER'"}'
                    sed -i -e 's/[^:]*://' -e 's/^\s*//' -e 's/,:/:/' $PATH_USER
                    echo "The machine $m deleted successfully ! "
                else
                    echo "The machine $m doesn't exist ! "
                fi
            done
        else
            echo "Usage : host arg( -a | -d... ) machine1 [machine2...]"
        fi
    
    else
        echo "Usage : host arg( -a | -d... ) machine1 [machine2...]"
    fi
}


function afinger() {
    shift
    if [ $# -ge 2 ]; then
        local userList=$(cut -d":" -f${userIndex[u]} $PATH_USER | tr "\n" ",")
        if [ "$1" == -a ]; then
            shift
            local uName=$1
            shift
            if [ ! -z $(echo $userList | grep "\<$uName\>") ]; then
                local userLine=$(grep "^$uName:" $PATH_USER)
                local userLinePre=$(echo $userLine | awk 'BEGIN{FS=OFS=":"}{for(i=1;i<'${userIndex[a]}';i++) printf($i":")}')
                local userLineMid=$(echo $userLine | awk 'BEGIN{FS=OFS=":"}{$'${userIndex[a]}'=$'${userIndex[a]}'"'$*'"; printf($'${userIndex[a]}'":")}')
                local userLineSuf=$(echo $userLine | awk 'BEGIN{FS=OFS=":"}{for(i=('${userIndex[a]}'+1);i<=NF;i++) if(i!=NF) printf($i":") ; else print $i }')
                local newUserLine=$userLinePre$userLineMid$userLineSuf
                sed -i 's/'$userLine'/'$newUserLine'/' $PATH_USER
                echo "Information added ! "
            else
                echo "The user $uName dosen't exist ! "
                echo "Usage : afinger -a username message "
            fi
        else
            local uName=$1
            shift
            if [ ! -z $(echo $userList | grep "\<$uName\>") ]; then
                local userLine=$(grep "^$uName:" $PATH_USER)
                local userLinePre=$(echo $userLine | awk 'BEGIN{FS=OFS=":"}{for(i=1;i<'${userIndex[a]}';i++) printf($i":")}')
                local userLineMid=$(echo $userLine | awk 'BEGIN{FS=OFS=":"}{$'${userIndex[a]}'="'$*'"; printf($'${userIndex[a]}'":")}')
                local userLineSuf=$(echo $userLine | awk 'BEGIN{FS=OFS=":"}{for(i=('${userIndex[a]}'+1);i<=NF;i++) if(i!=NF) printf($i":") ; else print $i }')
                local newUserLine=$userLinePre$userLineMid$userLineSuf
                sed -i 's/'$userLine'/'$newUserLine'/' $PATH_USER
                echo "Information overlay complete ! "
            else
                echo "The user $uName dosen't exist ! "
                echo "Usage : afinger username message "
            fi
        fi
    else
        echo "Usage : afinger [ -a ] username message "
    fi
}

function wall(){
    shift
    if [ $# -ge 1 ];then
        # 发送给全部的用户
        if [ "$1" == "-n" ];then
            shift
            local message="$*"
            local userList=($(user))
            local userOnlineList=$(cut -d":" -f${terminalIndex[u]} $PATH_TERMINAL )
            local i=0
            # 发送离线用户
            while [ $i -lt ${#userList[*]} ];do
                if [ -z $(echo $userOnlineList | grep '\<'${userList[$i]}'\>') ];then
                    local userMachine=$(getUserMachine "${userList[$i]}")
                    for m in $userMachine;do
                        write wirte "${userList[$i]}@$m" "$message"
                    done
                fi
                ((i++))
            done
            #发送在线用户
            wall wall "$message"
        # 发送给在线的用户
        else
            local message="$*"
            local terminalList=$(cut -d":" -f${terminalIndex[t]} $PATH_TERMINAL| tr "\n" " ")
            for t in $terminalList;do
                echo "$username@$userService>$message" >> $t
            done
        fi
    else
        echo "Usage : wall [ -n ] message"
    fi
}



function who(){
    awk 'BEGIN{FS=":"}{print $'${terminalIndex[u]}'"\t"$'${terminalIndex[t]}'"\t"$'${terminalIndex[tt]}'}' $PATH_TERMINAL | \
    awk 'BEGIN{FS="-"}{print $1"-"$2"-"$3" "$4":"$5}'
}

function rusers(){
    awk 'BEGIN{FS=":"}{print $'${terminalIndex[u]}'"\t"$'${terminalIndex[m]}'"\t"$'${terminalIndex[mt]}'}' $PATH_TERMINAL | \
    awk 'BEGIN{FS="-"}{print $1"-"$2"-"$3" "$4":"$5}'
}

function rhost(){
    declare -a hostArr
    local hostList=$(grep "^\<$adminName\>" $PATH_USER | cut -d":" -f${userIndex[m]} | tr "," "\n")
    local machines=$(cut -d":" -f${terminalIndex[m]} $PATH_TERMINAL | tr "\n" ",")
    i=0
    for h in $hostList;do     
        if [ ! -z $(echo $machines | grep $h) ];then
            echo $h
        fi
    done
}

function rconnect(){
    shift
    local machinesList=$(cut -d':' -f${userIndex[m]} $PATH_USER | grep ^[^01])
    if [ $# -eq 1 ];then
        if [ -z $(echo $machinesList | grep $1) ];then
            echo "The machine $1 doesn't existed!"
        else
            local pos=$(getPosOfMachine $1 $PATH_USER)
            local p=$(grep "^$username" $PATH_USER | awk 'BEGIN{FS=":"}{print $'${userIndex[m]}'}' | awk 'BEGIN{FS=","}{print $'$pos'}')
            if [[ "$username" == "$adminName" || "$p" == "1" ]];then
                local machineEnline=$(grep "$terminal" $PATH_TERMINAL | cut -d":" -f${terminalIndex[m]})
                if [ -z $(echo $machineEnline | grep "$1") ];then
                    userService=$1
                    readMsg $username@$userService
                    local time=$(date +"%Y-%m-%d-%H-%M")
                    local userLine=$(grep "\<$username\>" $PATH_TERMINAL | tr "\n" ",")
                    if [ -z $(echo $userLine | grep "\<$userService\>") ];then
                        awk 'BEGIN{FS=OFS=":"}{if(grep "$terminal" != "") $'${terminalIndex[m]}'=$'${terminalIndex[m]}'",'$userService'"}{print > "'$PATH_TERMINAL'"}' $PATH_TERMINAL
                        awk 'BEGIN{FS=OFS=":"}{if(grep "$terminal" != "") $'${terminalIndex[mt]}'=$'${terminalIndex[mt]}'",'$time'"}{print > "'$PATH_TERMINAL'"}' $PATH_TERMINAL
                    else
                        awk 'BEGIN{FS=OFS=":"}{if(grep "$terminal" != "") $'${terminalIndex[m]}'=$'${terminalIndex[m]}'",'$userService'"}{print > "'$PATH_TERMINAL'"}' $PATH_TERMINAL
                        local machines=$(grep "\<$username\>" $PATH_TERMINAL | head -1 | cut -d":" -f${terminalIndex[m]} | tr "," "\n") 
                        local machineTimes=$(grep "\<$username\>" $PATH_TERMINAL | head -1 | cut -d":" -f${terminalIndex[mt]} | tr "," "\n")
                        declare -a local timeArr
                        local a=0
                        for t in $machineTimes;do
                            timeArr[a]=$t
                            ((a++))
                        done
                        local nbM=0
                        for i in $machines;do
                            if [ "$i" == "$userService" ];then
                            break;
                            fi
                            ((nbM++))
                        done
                        awk 'BEGIN{FS=OFS=":"}{if(grep "$terminal" != "") $'${terminalIndex[mt]}'=$'${terminalIndex[mt]}'",'${timeArr[$nbM]}'"}{print > "'$PATH_TERMINAL'"}' $PATH_TERMINAL
                    fi
                else
                    echo "The machine $1 has already connected!"
                fi
                
            else
                echo "The user $username doesn't have permission to $1"
            fi
        fi    
    else
        echo "Usage : rconnect machinename"
    fi
}

function su(){
    shift
    local userList=$(cut -d":" -f${userIndex[u]} $PATH_USER | tr "\n" ",")
    if [ $# -eq 0 ];then
        echo ">Please enter the $adminName's password:"
        read -p ">" -s passwd
        echo
        local passwdRight=$(grep "^\<$adminName\>" $PATH_USER | cut -d":" -f${userIndex[pwd]})
        if [ "$passwdRight" != "$passwd" ]; then
            echo "Password is incorrect ! "
        else
            username=$adminName
            readMsg $username@$userService
            local time=$(date +"%Y-%m-%d-%H-%M")
            local userList=$(cut -d":" -f${terminalIndex[u]} $PATH_TERMINAL | tr "\n" ",")
            local userLine=$(grep "\<$username\>" $PATH_TERMINAL | head -1)
            if [ -z $(echo $userLine | grep "\<$userService\>") ];then
                awk 'BEGIN{FS=OFS=":"}{if(grep "$terminal" != "") $'${terminalIndex[u]}'="'$username'"}{print > "'$PATH_TERMINAL'"}' $PATH_TERMINAL
                awk 'BEGIN{FS=OFS=":"}{if(grep "$terminal" != "") $'${terminalIndex[m]}'="'$userService'"}{print > "'$PATH_TERMINAL'"}' $PATH_TERMINAL
                awk 'BEGIN{FS=OFS=":"}{if(grep "$terminal" != "") $'${terminalIndex[mt]}'=""}{print > "'$PATH_TERMINAL'"}' $PATH_TERMINAL
                awk 'BEGIN{FS=OFS=":"}{if(grep "$terminal" != "") $'${terminalIndex[mt]}'="'$time'"}{print > "'$PATH_TERMINAL'"}' $PATH_TERMINAL
            else
                awk 'BEGIN{FS=OFS=":"}{if(grep "$terminal" != "") $'${terminalIndex[u]}'="'$username'"}{print > "'$PATH_TERMINAL'"}' $PATH_TERMINAL
                awk 'BEGIN{FS=OFS=":"}{if(grep "$terminal" != "") $'${terminalIndex[m]}'="'$userService'"}{print > "'$PATH_TERMINAL'"}' $PATH_TERMINAL
                awk 'BEGIN{FS=OFS=":"}{if(grep "$terminal" != "") $'${terminalIndex[mt]}'=""}{print > "'$PATH_TERMINAL'"}' $PATH_TERMINAL
                local machines=$(grep "\<$username\>" $PATH_TERMINAL | head -1 | cut -d":" -f${terminalIndex[m]} | tr "," "\n") 
                local machineTimes=$(grep "\<$username\>" $PATH_TERMINAL | head -1 | cut -d":" -f${terminalIndex[mt]} | tr "," "\n")
                declare -a local timeArr
                local a=0
                for t in $machineTimes;do
                    timeArr[a]=$t
                    ((a++))
                done
                local nbM=0
                for i in $machines;do
                    if [ "$i" == "$userService" ];then
                    break;
                    fi
                    ((nbM++))
                done
                awk 'BEGIN{FS=OFS=":"}{if(grep "$terminal" != "") $'${terminalIndex[mt]}'="'${timeArr[$nbM]}'"}{print > "'$PATH_TERMINAL'"}' $PATH_TERMINAL
            fi
        fi
    elif [ $# -eq 1 ];then
        if [ -z $(echo $userList | grep $1) ];then
            echo "The user $1 is not existed"
        else
            local pos=$(getPosOfMachine $userService $PATH_USER)
            local p=$(grep "^$1" $PATH_USER | awk 'BEGIN{FS=":"}{print $'${userIndex[m]}'}' | awk 'BEGIN{FS=","}{print $'$pos'}')
            if [[ "$1" == "$adminName" || "$p" == "1" ]];then
                echo ">Please enter the $1's password:"
                read -p ">" -s passwd
                echo
                local passwdRight=$(grep "^$1" $PATH_USER | cut -d":" -f${userIndex[pwd]})
                if [ "$passwdRight" != "$passwd" ]; then
                    echo "Password is incorrect ! "
                else
                    username=$1
                    readMsg $username@$userService
                    local time=$(date +"%Y-%m-%d-%H-%M")
                    local userList=$(cut -d":" -f${terminalIndex[u]} $PATH_TERMINAL | tr "\n" ",")
                    local userLine=$(grep "\<$username\>" $PATH_TERMINAL | head -1)
                    if [ -z $(echo $userLine | grep "\<$userService\>") ];then
                        awk 'BEGIN{FS=OFS=":"}{if(grep "$terminal" != "") $'${terminalIndex[u]}'="'$username'"}{print > "'$PATH_TERMINAL'"}' $PATH_TERMINAL
                        awk 'BEGIN{FS=OFS=":"}{if(grep "$terminal" != "") $'${terminalIndex[m]}'="'$userService'"}{print > "'$PATH_TERMINAL'"}' $PATH_TERMINAL
                        awk 'BEGIN{FS=OFS=":"}{if(grep "$terminal" != "") $'${terminalIndex[mt]}'=""}{print > "'$PATH_TERMINAL'"}' $PATH_TERMINAL
                        awk 'BEGIN{FS=OFS=":"}{if(grep "$terminal" != "") $'${terminalIndex[mt]}'="'$time'"}{print > "'$PATH_TERMINAL'"}' $PATH_TERMINAL
                    else
                        awk 'BEGIN{FS=OFS=":"}{if(grep "$terminal" != "") $'${terminalIndex[u]}'="'$username'"}{print > "'$PATH_TERMINAL'"}' $PATH_TERMINAL
                        awk 'BEGIN{FS=OFS=":"}{if(grep "$terminal" != "") $'${terminalIndex[m]}'="'$userService'"}{print > "'$PATH_TERMINAL'"}' $PATH_TERMINAL
                        awk 'BEGIN{FS=OFS=":"}{if(grep "$terminal" != "") $'${terminalIndex[mt]}'=""}{print > "'$PATH_TERMINAL'"}' $PATH_TERMINAL
                        local machines=$(grep "\<$username\>" $PATH_TERMINAL | head -1 | cut -d":" -f${terminalIndex[m]} | tr "," "\n") 
                        local machineTimes=$(grep "\<$username\>" $PATH_TERMINAL | head -1 | cut -d":" -f${terminalIndex[mt]} | tr "," "\n")
                        declare -a local timeArr
                        local a=0
                        for t in $machineTimes;do
                            timeArr[a]=$t
                            ((a++))
                        done
                        local nbM=0
                        for i in $machines;do
                            if [ "$i" == "$userService" ];then
                            break;
                            fi
                            ((nbM++))
                        done
                        awk 'BEGIN{FS=OFS=":"}{if(grep "$terminal" != "") $'${terminalIndex[mt]}'="'${timeArr[$nbM]}'"}{print > "'$PATH_TERMINAL'"}' $PATH_TERMINAL
                    fi    
                fi
            else
                echo "The user $1 doesn't have permission to $userService"
            fi
        fi
    fi
   
}

function passwd(){  
    echo ">Old password:"
    read -p ">" -s password
    echo
    local passwdRight=$(grep "^\<$username\>" $PATH_USER | cut -d":" -f${userIndex[pwd]})
    if [ "$passwdRight" != "$password" ]; then
        echo "Password is incorrect ! "
    else
        echo ">New password:"
        read -p ">" -s password1
        echo
        echo "Re-enter new password:"
        read -p ">" -s password2
        echo
        if [ "$password1" == "$password2" ];then
            awk 'BEGIN{FS=OFS=":"}{if(/^'$username'/) $'${userIndex[pwd]}'="'$password1'"}{print > "'$PATH_USER'"}' $PATH_USER
        else
            echo "The two inputs are different!"
        fi
    fi
}

function finger(){
    echo $(grep "^\<$username\>" $PATH_USER | cut -d":" -f${userIndex[a]} )
}

function writeMsg() {
    local sender=$(echo $1 | cut -d"@" -f1)
    local senderMachine=$(echo $1 | cut -d"@" -f2)
    local receiver=$(echo $2 | cut -d"@" -f1)
    local receiverMachine=$(echo $2 | cut -d"@" -f2)
    shift
    shift
    local msg=$*
    local receiverLine=$(getLine ${userIndex[u]} $receiver $PATH_USER)
    if [ ! -z "$receiverLine" ]; then
        # 写入格式 sender@senderMachine@receiverMachine@message|
        local receiverNewLine="$receiverLine$sender@$senderMachine@$receiverMachine@$msg|"
        sed -i 's/'"$receiverLine"'/'"$receiverNewLine"'/g' $PATH_USER
    fi
}

# 读出未及时传输的信息并删除
# readMsg receiver@receiverMachine
function readMsg() {
    local receiver=$(echo $1 | cut -d"@" -f1)
    local receiverMachine=$(echo $1 | cut -d"@" -f2)
    local line=$(getLine ${userIndex[u]} $receiver $PATH_USER)
    # 获得发送给该机器的消息
    local receiverLine=$(echo "$line" | awk 'BEGIN{FS=":"}{print $NF}')
    local nf=$(echo "$receiverLine" |awk 'BEGIN{FS="|"}{print NF-1}')
    local msg=$(echo "$receiverLine" | awk 'BEGIN{RS="|";ORS="\n"}{print $0}')
    local num=($(echo -e "$msg" | cut -d"@" -f3 | grep -n '\<'$receiverMachine'\>'| cut -d":" -f1))
    local newLine=''
    local msgOutput=''
    local i=1
    local j=0
    while [ $i -le $nf ]; do
        if [ $j -lt ${#num[*]} ] && [ $i -eq ${num[j]} ];then
            local tmp=$(echo -e "$msg" | sed -n ''$i'p' | sed 's/@[^@]*@\([^@]*\)$/>\1/')
            msgOutput="$tmp\n$msgOutput"
        else
            local tmp=$(echo -e "$msg" | sed -n ''$i'p')
            newLine=$newLine$tmp"|"
        fi
        ((i++))
        ((j++))
    done
    # 删除不用的信息
    local linePre=$(echo "$line" | sed 's/:[^:]*$/:/')
    newLine="$linePre$newLine"
    sed -i 's/'"$line"'/'"$newLine"'/' $PATH_USER
    echo -e $msgOutput
}

function write() {
    shift
    if [ $# -eq 2 ]; then
        local u=$(echo $1 | cut -d"@" -f1)
        local m=$(echo $1 | cut -d"@" -f2)
        local message=$2
        if [ ! -z "$(getLine ${userIndex[u]} $u $PATH_USER)" ]; then
            if [ ! -z "$(getUserMachine $u | grep '\<'$m'\>')" ]; then
                local userTerminalLine=$(getLine ${terminalIndex[u]} $u $PATH_TERMINAL)
                # 是否在线
                if [ ! -z "$userTerminalLine" ]; then
                    for line in $userTerminalLine; do
                        local machineOnline=$(echo $line | cut -d":" -f${terminalIndex[m]} | awk 'BEGIN{FS=","}{print $NF}')
                        # 该机器是否在线
                        if [ "$machineOnline" == "$m" ]; then
                            local t=$(echo $line | cut -d":" -f1)
                            echo "$username@$userService>$message" >>$t
                        else
                            writeMsg $username"@"$userService $u"@"$m "$message"
                        fi
                    done
                else
                    writeMsg $username"@"$userService $u"@"$m "$message"
                fi
            else
                echo "The user $u doesn't access to machine $m or machine $m doesn't exist ! "
            fi
        else
            echo "The user $u dosen't exist ! "
        fi
    else
        echo "Usage : write username@machine message"
    fi
}

function Exit(){

    nbMachine=$(grep "^$terminal" $PATH_TERMINAL | awk 'BEGIN{FS=OFS=":"}{print $'${terminalIndex[m]}'}' | awk 'BEGIN{FS=","}{print NF}')
    if [ $nbMachine -eq 1 ];then 
       # awk 'BEGIN{FS=OFS=":"}{if(! grep "$terminal" != "") }{print > "'$PATH_TERMINAL'"}' $PATH_TERMINAL       
       local i=1
        while read line;do
            if [ ! -z $(echo $line | grep "^$terminal") ];then
               sed -i ''$i'd' $PATH_TERMINAL
            fi
            ((i++))
        done < $PATH_TERMINAL
            exit
    else
        local machines=$(grep "^$terminal" $PATH_TERMINAL | cut -d":" -f${terminalIndex[m]} | tr "," "\n") 
        local machineTimes=$(grep "^$terminal" $PATH_TERMINAL | cut -d":" -f${terminalIndex[mt]} | tr "," "\n")
        for m in $machines;do
            if [ ! "$m" == "$userService" ];then
                newService=$m
            fi
        done
        for t in $machineTimes;do
            lastMachineTime=$t
        done
        local oldMachines=$(grep "^$terminal" $PATH_TERMINAL | cut -d":" -f${terminalIndex[m]} ) 
        local oldMachineTimes=$(grep "^$terminal" $PATH_TERMINAL | cut -d":" -f${terminalIndex[mt]})
        local newMachines=$(echo ${oldMachines/,$userService/})
        local newMachineTimes=$(echo ${oldMachineTimes%,$lastMachineTime*}${oldMachineTimes##*,$lastMachineTime})
        sed -i -e 's/'$oldMachines'/'$newMachines'/' -e 's/'$oldMachineTimes'/'$newMachineTimes'/' $PATH_TERMINAL
        
        userService=$newService
    
    fi
}


function writeFile(){
    if [ ! -e $PATH_TERMINAL ]; then
        touch $PATH_TERMINAL
    fi
    local terminal=$(tty)
    local time=$(date +"%Y-%m-%d-%H-%M")
    local userList=$(cut -d":" -f${terminalIndex[u]} $PATH_TERMINAL | tr "\n" ",")
    local userLine=$(grep "\<$username\>" $PATH_TERMINAL | head -1)
    if [ -z $(echo $userLine | grep "\<$userService\>") ];then
        echo "$terminal:$username:$userService:$time:$time" >> $PATH_TERMINAL
    else
        local machines=$(grep "\<$username\>" $PATH_TERMINAL | head -1 | cut -d":" -f${terminalIndex[m]} | tr "," "\n") 
        local machineTimes=$(grep "\<$username\>" $PATH_TERMINAL | head -1 | cut -d":" -f${terminalIndex[mt]} | tr "," "\n")
        declare -a local timeArr
        local a=0
        for t in $machineTimes;do
            timeArr[a]=$t
            ((a++))
        done
        local nbM=0
        for i in $machines;do
            if [ "$i" == "$userService" ];then
            break;
            fi
            ((nbM++))
        done
        echo "$terminal:$username:$userService:$time:${timeArr[$nbM]}" >> $PATH_TERMINAL
    fi
    
}

function admin() {
    rootName=$(sed -n '1p' $PATH_USER | cut -d":" -f1)
    myPrompt="$username@$userService>"
    adminName=$(head -n 1 $PATH_USER | cut -d":" -f${userIndex[u]} )
    readMsg $username@$userService
    while [ true ]; do
        read -p "$username@$userService>" -a commande
        while [ ${#commande[@]} == 0 ]; do
            read -p "$username@$userService>" -a commande
        done
        case ${commande[0]} in
        host) host ${commande[*]} ;;
        user) user ${commande[*]} ;;
        wall) wall ${commande[*]} ;;
        afinger) afinger ${commande[*]} ;;
        who) who ${commande[*]} ;;
        rusers) rusers ${commande[*]} ;;
        rhost) rhost ${commande[*]} ;;
        rconnect) rconnect ${commande[*]} ;;
        su) su ${commande[*]} ;;
        passwd) passwd ${commande[*]} ;;
        finger) finger ${commande[*]} ;;
        write) write ${commande[*]} ;;
        exit) Exit ${commande[*]};;
        *) echo "Unkonwn command ! "; echo "Usage : command( host | user | wall | afinger | who | rusers | rconnect | su | passwd | finger | write | exit) arg1 arg2 ...";;
        esac
    done

}

function connect(){
    while [ true ]; do
        read -p "$username@$userService>" -a commande
        while [ ${#commande[@]} == 0 ]; do
            read -p "$username@$userService>" -a commande
        done
        case ${commande[0]} in
	    who) who ${commande[*]} ;;
        rusers) rusers ${commande[*]} ;;
        rhost) rhost ${commande[*]} ;;
        rconnect) rconnect ${commande[*]} ;;
        su) su ${commande[*]} ;;
        passwd) passwd ${commande[*]} ;;
        finger) finger ${commande[*]} ;;
        write) write ${commande[*]} ;;
        exit) Exit ${commande[*]};;
        *) echo "Unkonwn command ! "; echo "Usage : command( who | rusers | rconnect | su | passwd | finger | write | exit) arg1 arg2 ...";;
        esac
    done
}

function initConnect() {
    userService=$1
    username=$2
    adminName=$(head -n 1 $PATH_USER | cut -d":" -f${userIndex[u]} )
    rootName=$(sed -n '1p' $PATH_USER | cut -d":" -f1)
    myPrompt="$username@$userService>"
    if [ -e $PATH_USER ]; then
        machinesList=$(cut -d':' -f${userIndex[m]} $PATH_USER | grep ^[^01])
        userList=$(cut -d":" -f${userIndex[u]} $PATH_USER | tr "\n" ",")
        if [ -z $(echo $machinesList | grep "\<$userService\>") ];then
            echo "The machine $userService is not existed"
            exit
        fi
        if [ -z $(echo $userList | grep "\<$username\>") ]; then
            echo "The user $username is not existed !"
            exit
        fi
         
        local pos=$(getPosOfMachine $userService $PATH_USER)
        local p=$(grep "^\<$username\>" $PATH_USER | awk 'BEGIN{FS=":"}{print $'${userIndex[m]}'}' | awk 'BEGIN{FS=","}{print $'$pos'}')
        if [[ "$username" == "$adminName" || "$p" == "1" ]];then
            echo ">Please enter the $username's password:"
            read -p ">" -s passwd
            echo
            local passwdRight=$(grep "^\<$username\>" $PATH_USER | cut -d":" -f${userIndex[pwd]})
            while [ "$passwdRight" != "$passwd" ]; do
                echo "Password is incorrect ! "
                read -p ">" -s passwd
                echo
            done

            writeFile
            readMsg $username@$userService
            connect
        else
            echo "The user $username doesn't have permission to $userService"
        fi  
    else
        echo "Pleasee use admin mode to create user then connect"
    fi
}

if [ "$1" == "-admin" ];then
    initAdmin
    admin
elif [ "$1" == "-connect" ];then    
    if [ $# -eq 3 ];then
        initConnect $2 $3
    else
    echo "Usage : rvsh -connect nom_machine nom_utilisateur"
    fi
else
    echo "Usage : rvsh -(admin | connect)"
fi
