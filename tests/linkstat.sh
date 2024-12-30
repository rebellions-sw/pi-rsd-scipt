#!/bin/bash

LnkSta=($(lspci -D | grep -i accelerators | awk '{print $1}'))
LnkSta_num=${#LnkSta[@]}
for ((num=0 ; num < ${LnkSta_num} ; num++));
 do
        LnkStat=$(lspci -vv -s ${LnkSta[$num]} | grep LnkSta:)
        LnkStat_Speed=$(lspci -vv -s ${LnkSta[$port]} | grep LnkSta: | awk '{print $3}')
        LnkStat_Width=$(lspci -vv -s ${LnkSta[$port]} | grep LnkSta: | awk '{print $6}')

        if  [ $LnkStat_Speed != 16GT/s ] || [ $LnkStat_Width != x16 ]; then
                echo "################################################################################"
                echo "##########                     Link ${num} Error                        #############"
                echo "${LnkStat}"
                echo "################################################################################"

                if [ $num -eq $(($LnkSta_num-1)) ]; then
                        exit 1
                fi
        else
                echo "result ${LnkStat}"
        fi
done

